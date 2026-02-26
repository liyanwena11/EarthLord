-- 新手引导系统
-- 添加用户引导状态字段

-- 添加 has_seen_onboarding 字段到 profiles 表
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS has_seen_onboarding BOOLEAN DEFAULT FALSE;

-- 添加注释
COMMENT ON COLUMN profiles.has_seen_onboarding IS '用户是否已完成新手引导';
