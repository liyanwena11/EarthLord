-- ============================================================
-- 地球新主 (EarthLord) - 任务与成就系统迁移脚本
-- 版本: 009
-- 创建日期: 2026-02-23
-- 说明: 创建每日任务和成就系统相关表
-- ============================================================

-- ============================================================
-- 1. daily_tasks 表（每日任务）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.daily_tasks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    target INTEGER NOT NULL,
    current INTEGER DEFAULT 0 NOT NULL,
    reward JSONB NOT NULL,
    is_completed BOOLEAN DEFAULT false NOT NULL,
    is_claimed BOOLEAN DEFAULT false NOT NULL,
    claimed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT type_valid CHECK (type IN ('production', 'building', 'upgrade', 'collection', 'exploration', 'trade')),
    CONSTRAINT target_positive CHECK (target > 0),
    CONSTRAINT current_nonnegative CHECK (current >= 0),
    CONSTRAINT current_not_exceed_target CHECK (current <= target),
    CONSTRAINT expires_after_created CHECK (expires_at > created_at)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_daily_tasks_user_id ON public.daily_tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_type ON public.daily_tasks(type);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_is_completed ON public.daily_tasks(is_completed);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_is_claimed ON public.daily_tasks(is_claimed);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_expires_at ON public.daily_tasks(expires_at);

-- 组合索引：用于查询用户的活跃任务
CREATE INDEX IF NOT EXISTS idx_daily_tasks_user_active ON public.daily_tasks(user_id, is_claimed, expires_at);

-- 启用 RLS
ALTER TABLE public.daily_tasks ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户只能查看自己的任务
CREATE POLICY "查看自己的每日任务"
    ON public.daily_tasks
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS 策略：系统可以创建任务
CREATE POLICY "系统创建每日任务"
    ON public.daily_tasks
    FOR INSERT
    WITH CHECK (true);

-- RLS 策略：用户可以更新任务进度
CREATE POLICY "更新自己的每日任务"
    ON public.daily_tasks
    FOR UPDATE
    USING (auth.uid() = user_id);

-- 触发器：自动更新 updated_at
CREATE TRIGGER set_daily_tasks_updated_at
    BEFORE UPDATE ON public.daily_tasks
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 2. achievements 表（成就定义）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.achievements (
    id TEXT PRIMARY KEY,
    category TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT NOT NULL,
    requirement JSONB NOT NULL,
    reward JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT category_valid CHECK (category IN ('building', 'resource', 'territory', 'exploration', 'trade', 'social'))
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_achievements_category ON public.achievements(category);
CREATE INDEX IF NOT EXISTS idx_achievements_is_active ON public.achievements(is_active);

-- 启用 RLS
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可以查看活跃成就
CREATE POLICY "所有人可查看成就"
    ON public.achievements
    FOR SELECT
    USING (is_active = true);

-- ============================================================
-- 3. user_achievements 表（用户成就进度）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_achievements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    achievement_id TEXT REFERENCES public.achievements(id) ON DELETE CASCADE NOT NULL,
    progress DOUBLE PRECISION DEFAULT 0 NOT NULL,
    is_unlocked BOOLEAN DEFAULT false NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE,
    current_value INTEGER DEFAULT 0 NOT NULL,
    target_value INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT progress_range CHECK (progress >= 0 AND progress <= 1),
    CONSTRAINT current_nonnegative CHECK (current_value >= 0),
    CONSTRAINT unique_user_achievement UNIQUE(user_id, achievement_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON public.user_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_is_unlocked ON public.user_achievements(is_unlocked);

-- 启用 RLS
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户只能查看自己的成就进度
CREATE POLICY "查看自己的成就进度"
    ON public.user_achievements
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS 策略：系统可以创建/更新成就进度
CREATE POLICY "系统管理成就进度"
    ON public.user_achievements
    FOR ALL
    USING (true);

-- 触发器：自动更新 updated_at
CREATE TRIGGER set_user_achievements_updated_at
    BEFORE UPDATE ON public.user_achievements
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 4. 每日任务生成函数
-- ============================================================

CREATE OR REPLACE FUNCTION public.generate_daily_tasks(
    p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_created_count INTEGER := 0;
BEGIN
    -- 删除旧的未完成任务
    DELETE FROM public.daily_tasks
    WHERE user_id = p_user_id
    AND expires_at < NOW();

    -- 检查今天是否已有任务
    IF EXISTS (
        SELECT 1 FROM public.daily_tasks
        WHERE user_id = p_user_id
        AND DATE(expires_at) = CURRENT_DATE + INTERVAL '1 day'
    ) THEN
        RETURN jsonb_build_object('success', true, 'message', '今日任务已存在', 'created_count', 0);
    END IF;

    -- 生成生产任务
    INSERT INTO public.daily_tasks (user_id, type, title, description, target, current, reward, expires_at)
    VALUES (
        p_user_id,
        'production',
        '生产专家',
        '生产100单位食物',
        100,
        0,
        '{"experience": 100, "resources": {"food": 50}, "items": []}'::jsonb,
        CURRENT_DATE + INTERVAL '1 day'
    );
    v_created_count := v_created_count + 1;

    -- 生成建造任务
    INSERT INTO public.daily_tasks (user_id, type, title, description, target, current, reward, expires_at)
    VALUES (
        p_user_id,
        'building',
        '建筑大师',
        '建造2个建筑',
        2,
        0,
        '{"experience": 200, "resources": {"wood": 100, "metal": 50}, "items": []}'::jsonb,
        CURRENT_DATE + INTERVAL '1 day'
    );
    v_created_count := v_created_count + 1;

    -- 生成升级任务
    INSERT INTO public.daily_tasks (user_id, type, title, description, target, current, reward, expires_at)
    VALUES (
        p_user_id,
        'upgrade',
        '升级达人',
        '升级1个建筑',
        1,
        0,
        '{"experience": 150, "resources": {"metal": 50}, "items": []}'::jsonb,
        CURRENT_DATE + INTERVAL '1 day'
    );
    v_created_count := v_created_count + 1;

    RETURN jsonb_build_object('success', true, 'message', '每日任务生成成功', 'created_count', v_created_count);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 5. 成就进度更新函数
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_achievement_progress(
    p_user_id UUID,
    p_achievement_id TEXT,
    p_current_value INTEGER
) RETURNS JSONB AS $$
DECLARE
    v_achievement RECORD;
    v_user_achievement RECORD;
    v_new_progress DOUBLE PRECISION;
    v_is_new_unlock BOOLEAN := false;
BEGIN
    -- 获取成就定义
    SELECT * INTO v_achievement
    FROM public.achievements
    WHERE id = p_achievement_id AND is_active = true;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', '成就不存在或未激活');
    END IF;

    -- 获取或创建用户成就进度
    SELECT * INTO v_user_achievement
    FROM public.user_achievements
    WHERE user_id = p_user_id AND achievement_id = p_achievement_id;

    IF NOT FOUND THEN
        -- 创建新进度记录
        INSERT INTO public.user_achievements (user_id, achievement_id, current_value, target_value)
        VALUES (p_user_id, p_achievement_id, p_current_value, v_achievement.requirement->>'target'::INTEGER)
        RETURNING * INTO v_user_achievement;
    ELSE
        -- 更新进度
        UPDATE public.user_achievements
        SET current_value = p_current_value
        WHERE id = v_user_achievement.id
        RETURNING * INTO v_user_achievement;
    END IF;

    -- 计算进度
    v_new_progress := LEAST(CAST(p_current_value AS DOUBLE PRECISION) / CAST(v_user_achievement.target_value AS DOUBLE PRECISION), 1.0);

    -- 更新进度
    UPDATE public.user_achievements
    SET progress = v_new_progress
    WHERE id = v_user_achievement.id;

    -- 检查是否解锁
    IF v_new_progress >= 1.0 AND v_user_achievement.is_unlocked = false THEN
        UPDATE public.user_achievements
        SET
            is_unlocked = true,
            unlocked_at = NOW()
        WHERE id = v_user_achievement.id;
        v_is_new_unlock := true;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'progress', v_new_progress,
        'is_unlocked', v_user_achievement.is_unlocked,
        'is_new_unlock', v_is_new_unlock
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 6. 完成提示
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'migration_history'
    ) THEN
        CREATE TABLE public.migration_history (
            version TEXT PRIMARY KEY,
            applied_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
            description TEXT
        );
    END IF;

    INSERT INTO public.migration_history (version, description)
    VALUES (
        '009',
        'Day 50+: 创建任务与成就系统表 daily_tasks, achievements, user_achievements'
    )
    ON CONFLICT (version) DO NOTHING;
END $$;

DO $$
BEGIN
    RAISE NOTICE '✅ 迁移 009 执行成功！';
    RAISE NOTICE '📋 已创建表: daily_tasks, achievements, user_achievements';
    RAISE NOTICE '🔧 已创建函数: generate_daily_tasks, update_achievement_progress';
    RAISE NOTICE '🔒 已启用 RLS 安全策略';
END $$;
