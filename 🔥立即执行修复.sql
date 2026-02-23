-- ============================================
-- 复制这 4 行 SQL，在 Supabase SQL Editor 中执行
-- ============================================

-- 第 1 行：添加 updated_at 字段
ALTER TABLE public.communication_channels ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 第 2 行：添加 is_muted 字段
ALTER TABLE public.channel_subscriptions ADD COLUMN IF NOT EXISTS is_muted BOOLEAN DEFAULT false;

-- 第 3 行：添加 sender_callsign 字段
ALTER TABLE public.channel_messages ADD COLUMN IF NOT EXISTS sender_callsign TEXT;

-- 第 4 行：添加 metadata 字段
ALTER TABLE public.channel_messages ADD COLUMN IF NOT EXISTS metadata JSONB;
