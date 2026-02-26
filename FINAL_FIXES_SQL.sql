-- ============================================================
-- EarthLord 最终修复 SQL 脚本 v2.2
-- 创建日期: 2026-02-24
-- 用途: 修复用户报告的所有问题
-- 注意: Supabase SQL Editor 需要使用 SELECT 而非 RAISE NOTICE
-- ============================================================

-- ============================================================
-- 步骤0: 首先创建所有必需的辅助函数
-- ============================================================

-- 创建时间戳更新函数
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 验证函数创建
SELECT '✅ [步骤0] update_timestamp() 函数已创建' as status;

-- ============================================================
-- 修复1: territories.point_count 字段为 NULL 导致采样点显示为0
-- ============================================================

-- 更新所有 point_count 为 NULL 的领地记录
UPDATE public.territories
SET point_count = jsonb_array_length(path::jsonb)
WHERE point_count IS NULL AND path IS NOT NULL;

-- 验证更新结果
SELECT
    COUNT(*) FILTER (WHERE point_count IS NULL) as null_point_count,
    COUNT(*) as total_territories
FROM public.territories;

SELECT '✅ [修复1] territories.point_count 已更新' as status;

-- ============================================================
-- 修复2: 检查 communication_channels 表的 updated_at 字段
-- ============================================================

-- 添加 updated_at 字段（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'communication_channels'
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.communication_channels
        ADD COLUMN updated_at TIMESTAMPTZ DEFAULT now();

        -- 创建触发器自动更新 updated_at
        CREATE TRIGGER update_communication_channels_timestamp
        BEFORE UPDATE ON public.communication_channels
        FOR EACH ROW
        EXECUTE FUNCTION update_timestamp();
    END IF;
END $$;

-- 验证 updated_at 字段
SELECT
    column_name,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'communication_channels' AND column_name = 'updated_at') as exists
FROM information_schema.columns
WHERE table_name = 'communication_channels' AND column_name = 'updated_at';

SELECT '✅ [修复2] communication_channels.updated_at 已检查' as status;

-- ============================================================
-- 修复3: 检查 channel_subscriptions 表的 is_muted 字段
-- ============================================================

-- 添加 is_muted 字段（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'channel_subscriptions'
        AND column_name = 'is_muted'
    ) THEN
        ALTER TABLE public.channel_subscriptions
        ADD COLUMN is_muted BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- 验证 is_muted 字段
SELECT
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_subscriptions' AND column_name = 'is_muted') as exists
FROM information_schema.columns
WHERE table_name = 'channel_subscriptions' AND column_name = 'is_muted';

SELECT '✅ [修复3] channel_subscriptions.is_muted 已检查' as status;

-- ============================================================
-- 修复4: 检查 channel_messages 表的 sender_callsign 和 metadata 字段
-- ============================================================

-- 添加 sender_callsign 字段（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'channel_messages'
        AND column_name = 'sender_callsign'
    ) THEN
        ALTER TABLE public.channel_messages
        ADD COLUMN sender_callsign TEXT;
    END IF;
END $$;

-- 添加 metadata 字段（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'channel_messages'
        AND column_name = 'metadata'
    ) THEN
        ALTER TABLE public.channel_messages
        ADD COLUMN metadata JSONB DEFAULT '{}';
    END IF;
END $$;

-- 验证字段
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'channel_messages'
AND column_name IN ('sender_callsign', 'metadata')
ORDER BY ordinal_position;

SELECT '✅ [修复4] channel_messages 字段已检查' as status;

-- ============================================================
-- 修复5: 确保 trade_offers 表的字段正确
-- ============================================================

-- 验证 trade_offers 字段结构
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'trade_offers'
AND column_name IN ('owner_id', 'user_id', 'status', 'is_active')
ORDER BY ordinal_position;

SELECT '✅ [修复5] trade_offers 表结构已检查' as status;

-- ============================================================
-- 修复6: 检查 inventory_items 表的 name 字段
-- ============================================================

-- 添加 name 字段（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'inventory_items'
        AND column_name = 'name'
    ) THEN
        ALTER TABLE public.inventory_items
        ADD COLUMN name TEXT;
    END IF;
END $$;

-- 验证 name 字段
SELECT
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'name') as exists
FROM information_schema.columns
WHERE table_name = 'inventory_items' AND column_name = 'name';

SELECT '✅ [修复6] inventory_items.name 已检查' as status;

-- ============================================================
-- 修复7: 检查 purchase_mailbox 表
-- ============================================================

-- 创建表（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'purchase_mailbox'
    ) THEN
        CREATE TABLE purchase_mailbox (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            item_id TEXT NOT NULL,
            quantity INTEGER NOT NULL CHECK (quantity > 0),
            rarity TEXT NOT NULL DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
            product_id TEXT NOT NULL,
            transaction_id TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            is_claimed BOOLEAN NOT NULL DEFAULT FALSE,
            claimed_at TIMESTAMPTZ
        );

        -- 创建索引
        CREATE INDEX IF NOT EXISTS idx_mailbox_user_unclaimed
        ON purchase_mailbox (user_id, is_claimed)
        WHERE is_claimed = FALSE;

        CREATE UNIQUE INDEX IF NOT EXISTS idx_mailbox_transaction_item
        ON purchase_mailbox (transaction_id, item_id)
        WHERE transaction_id IS NOT NULL;

        -- 启用 RLS
        ALTER TABLE purchase_mailbox ENABLE ROW LEVEL SECURITY;

        CREATE POLICY "Users read own mailbox"
        ON purchase_mailbox FOR SELECT
        USING (auth.uid() = user_id);

        CREATE POLICY "Users update own mailbox"
        ON purchase_mailbox FOR UPDATE
        USING (auth.uid() = user_id);

        CREATE POLICY "Authenticated users insert mailbox"
        ON purchase_mailbox FOR INSERT
        WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- 验证表
SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'purchase_mailbox') as exists;

SELECT '✅ [修复7] purchase_mailbox 表已检查' as status;

-- ============================================================
-- 修复8: 频道成员数回写逻辑（防止重复订阅导致 member_count 偏差）
-- ============================================================

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
    SET member_count = (
            SELECT COUNT(*)
            FROM public.channel_subscriptions
            WHERE channel_id = p_channel_id
        ),
        updated_at = now()
    WHERE id = p_channel_id;
END;
$$;

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
    SET member_count = (
            SELECT COUNT(*)
            FROM public.channel_subscriptions
            WHERE channel_id = p_channel_id
        ),
        updated_at = now()
    WHERE id = p_channel_id;
END;
$$;

-- 同步历史 member_count 偏差
UPDATE public.communication_channels c
SET member_count = (
        SELECT COUNT(*)
        FROM public.channel_subscriptions s
        WHERE s.channel_id = c.id
    ),
    updated_at = now();

SELECT '✅ [修复8] subscribe/unsubscribe 与 member_count 已修复' as status;

-- ============================================================
-- 修复9: 添加索引优化查询性能
-- ============================================================

-- territories 表索引
CREATE INDEX IF NOT EXISTS idx_territories_user_active
ON public.territories(user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_territories_point_count
ON public.territories(point_count);

-- communication_channels 表索引
CREATE INDEX IF NOT EXISTS idx_channels_updated_at
ON public.communication_channels(updated_at DESC);

-- 验证索引创建
SELECT '✅ [修复9] 索引已优化' as status;

-- ============================================================
-- 修复完成总结
-- ============================================================

-- 显示所有状态汇总
SELECT '✅ [步骤0] update_timestamp() 函数已创建' as status
UNION ALL
SELECT '✅ [修复1] territories.point_count 已更新' as status
UNION ALL
SELECT '✅ [修复2] communication_channels.updated_at 已检查' as status
UNION ALL
SELECT '✅ [修复3] channel_subscriptions.is_muted 已检查' as status
UNION ALL
SELECT '✅ [修复4] channel_messages 字段已检查' as status
UNION ALL
SELECT '✅ [修复5] trade_offers 表结构已检查' as status
UNION ALL
SELECT '✅ [修复6] inventory_items.name 已检查' as status
UNION ALL
SELECT '✅ [修复7] purchase_mailbox 表已检查' as status
UNION ALL
SELECT '✅ [修复8] subscribe/unsubscribe 与 member_count 已修复' as status
UNION ALL
SELECT '✅ [修复9] 索引已优化' as status;
