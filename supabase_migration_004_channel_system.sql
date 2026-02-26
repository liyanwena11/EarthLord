-- ============================================================
-- Day 33: 频道系统迁移
-- 包含: communication_channels 表, channel_subscriptions 表,
--       RLS 策略, RPC 函数
-- ============================================================

-- 1. 创建 communication_channels 表
CREATE TABLE IF NOT EXISTS public.communication_channels (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    creator_id UUID NOT NULL REFERENCES auth.users(id),
    channel_type TEXT NOT NULL,
    channel_code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    member_count INT DEFAULT 1,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_channels_creator ON public.communication_channels(creator_id);
CREATE INDEX IF NOT EXISTS idx_channels_type ON public.communication_channels(channel_type);
CREATE INDEX IF NOT EXISTS idx_channels_active ON public.communication_channels(is_active);

-- 2. 创建 channel_subscriptions 表
CREATE TABLE IF NOT EXISTS public.channel_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    channel_id UUID NOT NULL REFERENCES public.communication_channels(id) ON DELETE CASCADE,
    is_muted BOOLEAN DEFAULT false,
    joined_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, channel_id)
);

CREATE INDEX IF NOT EXISTS idx_subs_user ON public.channel_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subs_channel ON public.channel_subscriptions(channel_id);

-- 3. RLS 策略 - communication_channels
ALTER TABLE public.communication_channels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "任何认证用户可查看活跃频道"
ON public.communication_channels FOR SELECT TO authenticated
USING (is_active = true);

CREATE POLICY "用户可创建频道"
ON public.communication_channels FOR INSERT TO authenticated
WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "创建者可更新自己的频道"
ON public.communication_channels FOR UPDATE TO authenticated
USING (auth.uid() = creator_id)
WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "创建者可删除自己的频道"
ON public.communication_channels FOR DELETE TO authenticated
USING (auth.uid() = creator_id);

-- 4. RLS 策略 - channel_subscriptions
ALTER TABLE public.channel_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "用户可查看自己的订阅"
ON public.channel_subscriptions FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "用户可订阅频道"
ON public.channel_subscriptions FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户可管理自己的订阅"
ON public.channel_subscriptions FOR UPDATE TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户可取消订阅"
ON public.channel_subscriptions FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- 5. RPC 函数: 生成频道码
CREATE OR REPLACE FUNCTION public.generate_channel_code(p_channel_type TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_code TEXT;
    v_exists BOOLEAN;
    v_chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    v_random TEXT;
    i INT;
BEGIN
    LOOP
        v_random := '';
        FOR i IN 1..6 LOOP
            v_random := v_random || substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1);
        END LOOP;

        CASE p_channel_type
            WHEN 'public' THEN v_code := 'PUB-' || v_random;
            WHEN 'walkie' THEN v_code := '438.' || lpad((floor(random() * 900 + 100))::text, 3, '0') || ' MHz';
            WHEN 'camp' THEN v_code := 'CAMP-' || v_random;
            WHEN 'satellite' THEN v_code := 'SAT-' || v_random;
            WHEN 'official' THEN v_code := 'OFF-' || v_random;
            ELSE v_code := 'CH-' || v_random;
        END CASE;

        SELECT EXISTS(
            SELECT 1 FROM public.communication_channels WHERE channel_code = v_code
        ) INTO v_exists;

        IF NOT v_exists THEN
            RETURN v_code;
        END IF;
    END LOOP;
END;
$$;

-- 6. RPC 函数: 创建频道并自动订阅
CREATE OR REPLACE FUNCTION public.create_channel_with_subscription(
    p_creator_id UUID,
    p_channel_type TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT NULL,
    p_latitude DOUBLE PRECISION DEFAULT NULL,
    p_longitude DOUBLE PRECISION DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_channel_id UUID;
    v_channel_code TEXT;
BEGIN
    -- 生成频道码
    v_channel_code := public.generate_channel_code(p_channel_type);

    -- 插入频道
    INSERT INTO public.communication_channels (
        creator_id, channel_type, channel_code, name, description,
        is_active, member_count, latitude, longitude
    ) VALUES (
        p_creator_id, p_channel_type, v_channel_code, p_name, p_description,
        true, 1, p_latitude, p_longitude
    )
    RETURNING id INTO v_channel_id;

    -- 创建者自动订阅
    INSERT INTO public.channel_subscriptions (user_id, channel_id)
    VALUES (p_creator_id, v_channel_id);

    RETURN v_channel_id;
END;
$$;

-- 7. RPC 函数: 订阅频道
CREATE OR REPLACE FUNCTION public.subscribe_to_channel(
    p_user_id UUID,
    p_channel_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- 插入订阅记录
    INSERT INTO public.channel_subscriptions (user_id, channel_id)
    VALUES (p_user_id, p_channel_id)
    ON CONFLICT (user_id, channel_id) DO NOTHING;

    -- 更新成员数（按真实订阅数回写，避免重复调用造成累加偏差）
    UPDATE public.communication_channels
    SET member_count = (
            SELECT COUNT(*)
            FROM public.channel_subscriptions
            WHERE channel_id = p_channel_id
        ),
        updated_at = now()
    WHERE id = p_channel_id;
END;
$$;

-- 8. RPC 函数: 取消订阅
CREATE OR REPLACE FUNCTION public.unsubscribe_from_channel(
    p_user_id UUID,
    p_channel_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- 删除订阅记录
    DELETE FROM public.channel_subscriptions
    WHERE user_id = p_user_id AND channel_id = p_channel_id;

    -- 更新成员数（按真实订阅数回写）
    UPDATE public.communication_channels
    SET member_count = (
            SELECT COUNT(*)
            FROM public.channel_subscriptions
            WHERE channel_id = p_channel_id
        ),
        updated_at = now()
    WHERE id = p_channel_id;
END;
$$;
