-- ============================================
-- 简化修复脚本 - 只添加缺失的字段
-- ============================================
-- 在 Supabase SQL Editor 中逐个执行以下语句
-- ============================================

-- 步骤 1: 修复 communication_channels 表
ALTER TABLE public.communication_channels ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 步骤 2: 修复 channel_subscriptions 表
ALTER TABLE public.channel_subscriptions ADD COLUMN IF NOT EXISTS is_muted BOOLEAN DEFAULT false;

-- 步骤 3: 修复 channel_messages 表
ALTER TABLE public.channel_messages ADD COLUMN IF NOT EXISTS sender_callsign TEXT;
ALTER TABLE public.channel_messages ADD COLUMN IF NOT EXISTS metadata JSONB;

-- 步骤 4: 验证字段是否添加成功
SELECT
    'communication_channels.updated_at' as field_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'communication_channels'
        AND column_name = 'updated_at'
    ) THEN '✅ 已添加' ELSE '❌ 缺失' END as status

UNION ALL

SELECT
    'channel_subscriptions.is_muted',
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'channel_subscriptions'
        AND column_name = 'is_muted'
    ) THEN '✅ 已添加' ELSE '❌ 缺失' END

UNION ALL

SELECT
    'channel_messages.sender_callsign',
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'channel_messages'
        AND column_name = 'sender_callsign'
    ) THEN '✅ 已添加' ELSE '❌ 缺失' END

UNION ALL

SELECT
    'channel_messages.metadata',
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'channel_messages'
        AND column_name = 'metadata'
    ) THEN '✅ 已添加' ELSE '❌ 缺失' END;
