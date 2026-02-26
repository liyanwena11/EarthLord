-- ============================================================
-- 测试脚本 - 验证所有修复
-- 执行此脚本前，先执行 fix_point_count_migration.sql 和 FINAL_FIXES_SQL.sql
-- ============================================================

-- 测试1: 检查 territories.point_count 是否还有 NULL
SELECT
    COUNT(*) FILTER (WHERE point_count IS NULL) as null_point_count_count,
    COUNT(*) as total_territories
FROM public.territories;

-- 测试2: 检查 communication_channels 字段
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'communication_channels'
ORDER BY ordinal_position;

-- 测试3: 检查 channel_subscriptions.is_muted
SELECT
    EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'channel_subscriptions'
        AND column_name = 'is_muted'
    ) as has_is_muted;

-- 测试4: 检查 channel_messages 字段
SELECT
    column_name
FROM information_schema.columns
WHERE table_name = 'channel_messages'
AND column_name IN ('sender_callsign', 'metadata')
ORDER BY ordinal_position;

-- 测试5: 检查 trade_offers 字段
SELECT
    column_name
FROM information_schema.columns
WHERE table_name = 'trade_offers'
AND column_name IN ('owner_id', 'user_id', 'status', 'is_active')
ORDER BY ordinal_position;

-- 测试6: 检查 inventory_items.name 字段
SELECT
    EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'inventory_items'
        AND column_name = 'name'
    ) as has_name_column;

-- 测试7: 检查 purchase_mailbox 表
SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'purchase_mailbox'
) as table_exists;
