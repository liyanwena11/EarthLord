-- ============================================
-- 快速迁移脚本 - 修复频道功能
-- ============================================
-- 在 Supabase SQL Editor 中运行此脚本
-- ============================================

-- 检查并创建通讯设备表
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'communication_devices') THEN
        CREATE TABLE public.communication_devices (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            device_type TEXT NOT NULL CHECK (device_type IN ('walkie_talkie', 'satellite_phone', 'radio_tower')),
            device_level INTEGER DEFAULT 1 CHECK (device_level >= 1 AND device_level <= 5),
            is_unlocked BOOLEAN DEFAULT false,
            is_current BOOLEAN DEFAULT false,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- 创建索引
        CREATE INDEX idx_communication_devices_user_id ON public.communication_devices(user_id);

        -- 启用 RLS
        ALTER TABLE public.communication_devices ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "用户可以查看自己的设备" ON public.communication_devices FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "用户可以插入自己的设备" ON public.communication_devices FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "用户可以更新自己的设备" ON public.communication_devices FOR UPDATE USING (auth.uid() = user_id);

        RAISE NOTICE '✅ communication_devices 表创建成功';
    ELSE
        RAISE NOTICE '⚠️ communication_devices 表已存在';
    END IF;
END $$;

-- 检查并创建频道表
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'communication_channels') THEN
        CREATE TABLE public.communication_channels (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            channel_type TEXT NOT NULL CHECK (channel_type IN ('official', 'public', 'private', 'territory', 'global')),
            channel_code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            latitude DOUBLE PRECISION,
            longitude DOUBLE PRECISION,
            member_count INTEGER DEFAULT 0,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- 创建索引
        CREATE INDEX idx_communication_channels_type ON public.communication_channels(channel_type);
        CREATE INDEX idx_communication_channels_active ON public.communication_channels(is_active);

        -- 启用 RLS
        ALTER TABLE public.communication_channels ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "所有人可以查看活跃频道" ON public.communication_channels FOR SELECT USING (is_active = true);

        RAISE NOTICE '✅ communication_channels 表创建成功';
    ELSE
        RAISE NOTICE '⚠️ communication_channels 表已存在';
    END IF;
END $$;

-- 检查并创建频道订阅表
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'channel_subscriptions') THEN
        CREATE TABLE public.channel_subscriptions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            channel_id UUID NOT NULL REFERENCES public.communication_channels(id) ON DELETE CASCADE,
            joined_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(user_id, channel_id)
        );

        -- 创建索引
        CREATE INDEX idx_channel_subscriptions_user_id ON public.channel_subscriptions(user_id);
        CREATE INDEX idx_channel_subscriptions_channel_id ON public.channel_subscriptions(channel_id);

        -- 启用 RLS
        ALTER TABLE public.channel_subscriptions ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "用户可以查看自己的订阅" ON public.channel_subscriptions FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "用户可以插入自己的订阅" ON public.channel_subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "用户可以删除自己的订阅" ON public.channel_subscriptions FOR DELETE USING (auth.uid() = user_id);

        RAISE NOTICE '✅ channel_subscriptions 表创建成功';
    ELSE
        RAISE NOTICE '⚠️ channel_subscriptions 表已存在';
    END IF;
END $$;

-- 检查并创建频道消息表
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'channel_messages') THEN
        CREATE TABLE public.channel_messages (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            channel_id UUID NOT NULL REFERENCES public.communication_channels(id) ON DELETE CASCADE,
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            content TEXT NOT NULL,
            message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'system', 'ptt_start', 'ptt_end')),
            created_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- 创建索引
        CREATE INDEX idx_channel_messages_channel_id ON public.channel_messages(channel_id);
        CREATE INDEX idx_channel_messages_created_at ON public.channel_messages(created_at);

        -- 启用 RLS
        ALTER TABLE public.channel_messages ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "用户可以查看已订阅频道的消息" ON public.channel_messages FOR SELECT
        USING (EXISTS (SELECT 1 FROM public.channel_subscriptions WHERE channel_id = public.channel_messages.channel_id AND user_id = auth.uid()));
        CREATE POLICY "用户可以发送消息到已订阅频道" ON public.channel_messages FOR INSERT
        WITH CHECK (EXISTS (SELECT 1 FROM public.channel_subscriptions WHERE channel_id = public.channel_messages.channel_id AND user_id = auth.uid()));

        RAISE NOTICE '✅ channel_messages 表创建成功';
    ELSE
        RAISE NOTICE '⚠️ channel_messages 表已存在';
    END IF;
END $$;

-- 检查并创建购买邮箱表
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'purchase_mailbox') THEN
        CREATE TABLE public.purchase_mailbox (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            item_id TEXT NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            rarity TEXT NOT NULL DEFAULT 'common',
            product_id TEXT NOT NULL,
            transaction_id TEXT,
            is_claimed BOOLEAN DEFAULT false,
            claimed_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- 创建索引
        CREATE INDEX idx_purchase_mailbox_user_id ON public.purchase_mailbox(user_id);
        CREATE INDEX idx_purchase_mailbox_claimed ON public.purchase_mailbox(is_claimed);

        -- 启用 RLS
        ALTER TABLE public.purchase_mailbox ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "用户可以查看自己的邮箱物品" ON public.purchase_mailbox FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "用户可以更新自己的邮箱物品" ON public.purchase_mailbox FOR UPDATE USING (auth.uid() = user_id);

        RAISE NOTICE '✅ purchase_mailbox 表创建成功';
    ELSE
        RAISE NOTICE '⚠️ purchase_mailbox 表已存在';
    END IF;
END $$;

-- ============================================
-- 创建或替换 RPC 函数
-- ============================================

-- 生成频道码函数
CREATE OR REPLACE FUNCTION public.generate_channel_code(p_channel_type TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_prefix TEXT;
    v_random_chars TEXT;
BEGIN
    CASE p_channel_type
        WHEN 'official' THEN v_prefix := 'OFF';
        WHEN 'public' THEN v_prefix := 'PUB';
        WHEN 'private' THEN v_prefix := 'PRV';
        WHEN 'territory' THEN v_prefix := 'TER';
        WHEN 'global' THEN v_prefix := 'GLB';
        ELSE v_prefix := 'CH';
    END CASE;
    v_random_chars := substring(md5(random()::text), 1, 4);
    RETURN v_prefix || '-' || v_random_chars;
END;
$$;

-- 创建频道并自动订阅
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
    v_channel_code := public.generate_channel_code(p_channel_type);

    INSERT INTO public.communication_channels (
        creator_id, channel_type, channel_code, name, description, latitude, longitude
    ) VALUES (
        p_creator_id, p_channel_type, v_channel_code, p_name, p_description, p_latitude, p_longitude
    ) RETURNING id INTO v_channel_id;

    INSERT INTO public.channel_subscriptions (user_id, channel_id)
    VALUES (p_creator_id, v_channel_id);

    UPDATE public.communication_channels
    SET member_count = 1
    WHERE id = v_channel_id;

    RETURN v_channel_id;
END;
$$;

-- 订阅频道
CREATE OR REPLACE FUNCTION public.subscribe_to_channel(
    p_user_id UUID,
    p_channel_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.channel_subscriptions (user_id, channel_id)
    VALUES (p_user_id, p_channel_id)
    ON CONFLICT (user_id, channel_id) DO NOTHING;

    UPDATE public.communication_channels
    SET member_count = (SELECT COUNT(*) FROM public.channel_subscriptions WHERE channel_id = p_channel_id)
    WHERE id = p_channel_id;
END;
$$;

-- 取消订阅频道
CREATE OR REPLACE FUNCTION public.unsubscribe_from_channel(
    p_user_id UUID,
    p_channel_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.channel_subscriptions
    WHERE user_id = p_user_id AND channel_id = p_channel_id;

    UPDATE public.communication_channels
    SET member_count = (SELECT COUNT(*) FROM public.channel_subscriptions WHERE channel_id = p_channel_id)
    WHERE id = p_channel_id;
END;
$$;

-- ============================================
-- 初始化官方频道
-- ============================================

INSERT INTO public.communication_channels (
    creator_id, channel_type, channel_code, name, description, member_count
) VALUES
    ('00000000-0000-0000-0000-000000000000'::uuid, 'official', 'OFF-NEWS', '幸存者公告', '官方公告频道，定期发布重要信息', 0),
    ('00000000-0000-0000-0000-000000000000'::uuid, 'official', 'OFF-HELP', '求助频道', '发布和响应求助信息', 0)
ON CONFLICT (channel_code) DO NOTHING;

-- ============================================
-- 验证结果
-- ============================================

DO $$
DECLARE
    v_table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name IN (
        'communication_devices',
        'communication_channels',
        'channel_subscriptions',
        'channel_messages',
        'purchase_mailbox'
    );

    RAISE NOTICE '';
    RAISE NOTICE '=============================================';
    RAISE NOTICE '🎉 迁移完成！';
    RAISE NOTICE '=============================================';
    RAISE NOTICE '已创建表数: % / 5', v_table_count;

    IF v_table_count = 5 THEN
        RAISE NOTICE '✅ 所有表创建成功！';
        RAISE NOTICE '✅ 所有函数创建成功！';
        RAISE NOTICE '✅ 官方频道已初始化！';
        RAISE NOTICE '';
        RAISE NOTICE '📱 现在可以重启 App 测试频道功能了。';
    ELSE
        RAISE NOTICE '⚠️ 部分表可能创建失败，请检查错误信息。';
    END IF;

    RAISE NOTICE '=============================================';
END $$;
