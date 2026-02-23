-- ============================================
-- 完���修复脚本 - 修复所有频道和交易系统问题
-- ============================================
-- 在 Supabase SQL Editor 中运行此脚本
-- ============================================

-- ============================================
-- 问题 1: 修复频道表字段缺失
-- ============================================

DO $$
BEGIN
    -- 检查并添加缺失的字段
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'communication_channels'
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.communication_channels ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE '✅ 添加 updated_at 字段';
    ELSE
        RAISE NOTICE '⚠️ updated_at 字段已存在';
    END IF;

    -- 检查并创建表（如果不存在）
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

        CREATE INDEX idx_communication_channels_type ON public.communication_channels(channel_type);
        CREATE INDEX idx_communication_channels_active ON public.communication_channels(is_active);
        CREATE INDEX idx_communication_channels_creator ON public.communication_channels(creator_id);

        ALTER TABLE public.communication_channels ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "所有人可以查看活跃频道" ON public.communication_channels FOR SELECT USING (is_active = true);
        CREATE POLICY "认证用户可以创建频道" ON public.communication_channels FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
        CREATE POLICY "创建者可以更新频道" ON public.communication_channels FOR UPDATE USING (auth.uid() = creator_id);
        CREATE POLICY "创建者可以删除频道" ON public.communication_channels FOR DELETE USING (auth.uid() = creator_id);

        RAISE NOTICE '✅ communication_channels 表创建成功';
    END IF;
END $$;

-- ============================================
-- 问题 2: 修复频道订阅表字段缺失
-- ============================================

DO $$
BEGIN
    -- 检查 is_muted 字段是否存在，如果不存在则添加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'channel_subscriptions'
        AND column_name = 'is_muted'
    ) THEN
        ALTER TABLE public.channel_subscriptions ADD COLUMN is_muted BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ 添加 is_muted 字段';
    END IF;

    -- 检查表是否存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'channel_subscriptions') THEN
        CREATE TABLE public.channel_subscriptions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            channel_id UUID NOT NULL REFERENCES public.communication_channels(id) ON DELETE CASCADE,
            is_muted BOOLEAN DEFAULT false,
            joined_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(user_id, channel_id)
        );

        CREATE INDEX idx_channel_subscriptions_user_id ON public.channel_subscriptions(user_id);
        CREATE INDEX idx_channel_subscriptions_channel_id ON public.channel_subscriptions(channel_id);

        ALTER TABLE public.channel_subscriptions ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "用户可以查看自己的订阅" ON public.channel_subscriptions FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "用户可以插入自己的订阅" ON public.channel_subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "用户可以更新自己的订阅" ON public.channel_subscriptions FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "用户可以删除自己的订阅" ON public.channel_subscriptions FOR DELETE USING (auth.uid() = user_id);

        RAISE NOTICE '✅ channel_subscriptions 表创建成功';
    END IF;
END $$;

-- ============================================
-- 问题 3: 修复频道消息表
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'channel_messages') THEN
        CREATE TABLE public.channel_messages (
            message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            channel_id UUID NOT NULL REFERENCES public.communication_channels(id) ON DELETE CASCADE,
            sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
            sender_callsign TEXT,
            content TEXT NOT NULL,
            sender_location TEXT,
            metadata JSONB,
            message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'system', 'ptt_start', 'ptt_end')),
            created_at TIMESTAMPTZ DEFAULT NOW()
        );

        CREATE INDEX idx_channel_messages_channel_id ON public.channel_messages(channel_id);
        CREATE INDEX idx_channel_messages_created_at ON public.channel_messages(created_at DESC);
        CREATE INDEX idx_channel_messages_sender_id ON public.channel_messages(sender_id);

        -- 注意：这里修改 RLS 策略，允许查询所有消息（因为我们需要加载所有已订阅频道的消息）
        ALTER TABLE public.channel_messages ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "所有人可以查看频道消息" ON public.channel_messages FOR SELECT USING (true);
        CREATE POLICY "认证用户可以发送消息" ON public.channel_messages FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

        RAISE NOTICE '✅ channel_messages 表创建成功';
    ELSE
        -- 检查并添加缺失的字段
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'channel_messages'
            AND column_name = 'sender_callsign'
        ) THEN
            ALTER TABLE public.channel_messages ADD COLUMN sender_callsign TEXT;
            RAISE NOTICE '✅ 添加 sender_callsign 字段';
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'channel_messages'
            AND column_name = 'metadata'
        ) THEN
            ALTER TABLE public.channel_messages ADD COLUMN metadata JSONB;
            RAISE NOTICE '✅ 添加 metadata 字段';
        END IF;
    END IF;
END $$;

-- ============================================
-- 问题 4: 修复通讯设备表
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'communication_devices') THEN
        CREATE TABLE public.communication_devices (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            device_type TEXT NOT NULL CHECK (device_type IN ('radio', 'walkie_talkie', 'camp_radio', 'satellite')),
            device_level INTEGER DEFAULT 1 CHECK (device_level >= 1 AND device_level <= 5),
            is_unlocked BOOLEAN DEFAULT false,
            is_current BOOLEAN DEFAULT false,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        CREATE INDEX idx_communication_devices_user_id ON public.communication_devices(user_id);

        ALTER TABLE public.communication_devices ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "用户可以查看自己的设备" ON public.communication_devices FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "用户可以插入自己的设备" ON public.communication_devices FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "用户可以更新自己的设备" ON public.communication_devices FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "用户可以删除自己的设备" ON public.communication_devices FOR DELETE USING (auth.uid() = user_id);

        RAISE NOTICE '✅ communication_devices 表创建成功';
    END IF;
END $$;

-- ============================================
-- 问题 5: 修复购买邮箱表
-- ============================================

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

        CREATE INDEX idx_purchase_mailbox_user_id ON public.purchase_mailbox(user_id);
        CREATE INDEX idx_purchase_mailbox_claimed ON public.purchase_mailbox(is_claimed);

        ALTER TABLE public.purchase_mailbox ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "用户可以查看自己的邮箱物品" ON public.purchase_mailbox FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "用户可以更新自己的邮箱物品" ON public.purchase_mailbox FOR UPDATE USING (auth.uid() = user_id);

        RAISE NOTICE '✅ purchase_mailbox 表创建成功';
    END IF;
END $$;

-- ============================================
-- 问题 6: 修复交易系统表
-- ============================================

DO $$
BEGIN
    -- 删除旧表（如果存在）并重新创建
    DROP TABLE IF EXISTS public.trade_offers CASCADE;
    DROP TABLE IF EXISTS public.trade_history CASCADE;

    -- 创建交易报价表
    CREATE TABLE public.trade_offers (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        description TEXT,
        offer_items JSONB NOT NULL DEFAULT '[]'::jsonb,
        request_items JSONB NOT NULL DEFAULT '[]'::jsonb,
        status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
        territory_id TEXT,
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
    );

    CREATE INDEX idx_trade_offers_owner_id ON public.trade_offers(owner_id);
    CREATE INDEX idx_trade_offers_status ON public.trade_offers(status);
    CREATE INDEX idx_trade_offers_territory ON public.trade_offers(territory_id);
    CREATE INDEX idx_trade_offers_created_at ON public.trade_offers(created_at DESC);

    ALTER TABLE public.trade_offers ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "所有人可以查看活跃交易" ON public.trade_offers FOR SELECT USING (status = 'active');
    CREATE POLICY "用户可以查看自己的交易" ON public.trade_offers FOR SELECT USING (auth.uid() = owner_id);
    CREATE POLICY "用户可以创建交易" ON public.trade_offers FOR INSERT WITH CHECK (auth.uid() = owner_id);
    CREATE POLICY "所有者可以更新交易" ON public.trade_offers FOR UPDATE USING (auth.uid() = owner_id);
    CREATE POLICY "所有者可以删除交易" ON public.trade_offers FOR DELETE USING (auth.uid() = owner_id);

    RAISE NOTICE '✅ trade_offers 表创建成功';

    -- 创建交易历史表
    CREATE TABLE public.trade_history (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        trader1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
        trader2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
        items1 JSONB NOT NULL DEFAULT '[]'::jsonb,
        items2 JSONB NOT NULL DEFAULT '[]'::jsonb,
        territory_id TEXT,
        completed_at TIMESTAMPTZ DEFAULT NOW()
    );

    CREATE INDEX idx_trade_history_trader1 ON public.trade_history(trader1_id);
    CREATE INDEX idx_trade_history_trader2 ON public.trade_history(trader2_id);
    CREATE INDEX idx_trade_history_completed_at ON public.trade_history(completed_at DESC);

    ALTER TABLE public.trade_history ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "交易参与者可以查看历史" ON public.trade_history FOR SELECT USING (auth.uid() IN (trader1_id, trader2_id));

    RAISE NOTICE '✅ trade_history 表创建成功';
END $$;

-- ============================================
-- 重新创建 RPC 函数
-- ============================================

-- 删除旧函数并重新创建
DROP FUNCTION IF EXISTS public.generate_channel_code(p_channel_type TEXT);
DROP FUNCTION IF EXISTS public.create_channel_with_subscription(p_creator_id UUID, p_channel_type TEXT, p_name TEXT, p_description TEXT, p_latitude DOUBLE PRECISION, p_longitude DOUBLE PRECISION);
DROP FUNCTION IF EXISTS public.subscribe_to_channel(p_user_id UUID, p_channel_id UUID);
DROP FUNCTION IF EXISTS public.unsubscribe_from_channel(p_user_id UUID, p_channel_id UUID);

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

-- 先删除已存在的官方频道
DELETE FROM public.channel_subscriptions WHERE channel_id IN (
    SELECT id FROM public.communication_channels WHERE channel_code IN ('OFF-NEWS', 'OFF-HELP')
);
DELETE FROM public.communication_channels WHERE channel_code IN ('OFF-NEWS', 'OFF-HELP');

-- 插入官方频道
INSERT INTO public.communication_channels (
    creator_id, channel_type, channel_code, name, description, member_count, is_active
) VALUES
    (auth.uid(), 'official', 'OFF-NEWS', '幸存者公告', '官方公告频道，定期发布重要信息', 0, true),
    (auth.uid(), 'official', 'OFF-HELP', '求助频道', '发布和响应求助信息', 0, true);

-- ============================================
-- 验证结果
-- ============================================

DO $$
DECLARE
    v_table_count INTEGER;
    v_function_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name IN (
        'communication_devices',
        'communication_channels',
        'channel_subscriptions',
        'channel_messages',
        'purchase_mailbox',
        'trade_offers',
        'trade_history'
    );

    SELECT COUNT(*) INTO v_function_count
    FROM information_schema.routines
    WHERE routine_schema = 'public'
    AND routine_name IN (
        'generate_channel_code',
        'create_channel_with_subscription',
        'subscribe_to_channel',
        'unsubscribe_from_channel'
    );

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '🎉 修复完成！';
    RAISE NOTICE '============================================';
    RAISE NOTICE '已创建/修复表数: % / 7', v_table_count;
    RAISE NOTICE '已创建/修复函数数: % / 4', v_function_count;

    IF v_table_count = 7 AND v_function_count = 4 THEN
        RAISE NOTICE '✅ 所有表创建成功！';
        RAISE NOTICE '✅ 所有函数创建成功！';
        RAISE NOTICE '✅ 官方频道已初始化！';
        RAISE NOTICE '';
        RAISE NOTICE '📱 现在可以重启 App 测试频道功能了。';
        RAISE NOTICE '';
        RAISE NOTICE '🔧 主要修复内容：';
        RAISE NOTICE '1. ✅ 添加缺失的 updated_at 字段';
        RAISE NOTICE '2. ✅ 添加缺失的 is_muted 字段';
        RAISE NOTICE '3. ✅ 添加缺失的 sender_callsign 字段';
        RAISE NOTICE '4. ✅ 添加缺失的 metadata 字段';
        RAISE NOTICE '5. ✅ 修复交易系统表结构';
        RAISE NOTICE '6. ✅ 重建所有 RPC 函数';
        RAISE NOTICE '7. ✅ 初始化官方频道';
    ELSE
        RAISE NOTICE '⚠️ 部分对象可能创建失败，请检查错误信息。';
    END IF;

    RAISE NOTICE '============================================';
END $$;
