-- ============================================================
-- 地球新主 (EarthLord) - 成就排行榜系统迁移脚本
-- 版本: 010
-- 创建日期: 2026-02-26
-- 说明: 创建成就排行榜相关表和函数
-- ============================================================

-- ============================================================
-- 1. 修改 achievements 表 - 添加难度等级
-- ============================================================

ALTER TABLE public.achievements
ADD COLUMN IF NOT EXISTS difficulty TEXT DEFAULT 'common',
ADD COLUMN IF NOT EXISTS points INTEGER DEFAULT 10;

-- 添加约束
ALTER TABLE public.achievements
DROP CONSTRAINT IF EXISTS achievements_difficulty_check;

ALTER TABLE public.achievements
ADD CONSTRAINT achievements_difficulty_check
CHECK (difficulty IN ('common', 'rare', 'epic', 'legendary'));

-- 更新现有成就的积分
UPDATE public.achievements
SET points = CASE difficulty
    WHEN 'common' THEN 10
    WHEN 'rare' THEN 30
    WHEN 'epic' THEN 50
    WHEN 'legendary' THEN 100
    ELSE 10
END;

-- ============================================================
-- 2. achievement_leaderboard 表（成就排行榜）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.achievement_leaderboard (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    total_points INTEGER DEFAULT 0 NOT NULL,
    total_achievements INTEGER DEFAULT 0 NOT NULL,
    completion_rate DOUBLE PRECISION DEFAULT 0 NOT NULL,
    ranking_position INTEGER,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT total_points_nonnegative CHECK (total_points >= 0),
    CONSTRAINT total_achievements_nonnegative CHECK (total_achievements >= 0),
    CONSTRAINT completion_rate_range CHECK (completion_rate >= 0 AND completion_rate <= 1),
    CONSTRAINT unique_user_leaderboard UNIQUE(user_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_achievement_leaderboard_user_id ON public.achievement_leaderboard(user_id);
CREATE INDEX IF NOT EXISTS idx_achievement_leaderboard_total_points ON public.achievement_leaderboard(total_points DESC);
CREATE INDEX IF NOT EXISTS idx_achievement_leaderboard_total_achievements ON public.achievement_leaderboard(total_achievements DESC);
CREATE INDEX IF NOT EXISTS idx_achievement_leaderboard_completion_rate ON public.achievement_leaderboard(completion_rate DESC);
CREATE INDEX IF NOT EXISTS idx_achievement_leaderboard_ranking ON public.achievement_leaderboard(ranking_position);

-- 启用 RLS
ALTER TABLE public.achievement_leaderboard ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可以查看排行榜
CREATE POLICY "所有人可查看成就排行榜"
    ON public.achievement_leaderboard
    FOR SELECT
    USING (true);

-- RLS 策略：系统可以更新排行榜
CREATE POLICY "系统可更新成就排行榜"
    ON public.achievement_leaderboard
    FOR ALL
    USING (true);

-- ============================================================
-- 3. category_leaderboard 表（分类成就排行榜）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.category_leaderboard (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    category TEXT NOT NULL,
    category_points INTEGER DEFAULT 0 NOT NULL,
    category_achievements INTEGER DEFAULT 0 NOT NULL,
    ranking_position INTEGER,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT category_valid CHECK (category IN ('building', 'resource', 'territory', 'exploration', 'trade', 'social')),
    CONSTRAINT category_points_nonnegative CHECK (category_points >= 0),
    CONSTRAINT category_achievements_nonnegative CHECK (category_achievements >= 0),
    CONSTRAINT unique_user_category UNIQUE(user_id, category)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_category_leaderboard_user_id ON public.category_leaderboard(user_id);
CREATE INDEX IF NOT EXISTS idx_category_leaderboard_category ON public.category_leaderboard(category);
CREATE INDEX IF NOT EXISTS idx_category_leaderboard_category_points ON public.category_leaderboard(category, category_points DESC);
CREATE INDEX IF NOT EXISTS idx_category_leaderboard_ranking ON public.category_leaderboard(ranking_position);

-- 启用 RLS
ALTER TABLE public.category_leaderboard ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可以查看分类排行榜
CREATE POLICY "所有人可查看分类排行榜"
    ON public.category_leaderboard
    FOR SELECT
    USING (true);

-- RLS 策略：系统可以更新分类排行榜
CREATE POLICY "系统可更新分类排行榜"
    ON public.category_leaderboard
    FOR ALL
    USING (true);

-- ============================================================
-- 4. achievement_speed_records 表（成就速度记录）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.achievement_speed_records (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    milestone_type TEXT NOT NULL,
    days_taken INTEGER NOT NULL,
    achieved_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT milestone_type_valid CHECK (milestone_type IN ('first_10', 'first_50', 'first_100', 'all_achievements')),
    CONSTRAINT days_taken_positive CHECK (days_taken > 0),
    CONSTRAINT unique_user_milestone UNIQUE(user_id, milestone_type)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_speed_records_user_id ON public.achievement_speed_records(user_id);
CREATE INDEX IF NOT EXISTS idx_speed_records_milestone_type ON public.achievement_speed_records(milestone_type);
CREATE INDEX IF NOT EXISTS idx_speed_records_days_taken ON public.achievement_speed_records(milestone_type, days_taken ASC);

-- 启用 RLS
ALTER TABLE public.achievement_speed_records ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可以查看速度记录
CREATE POLICY "所有人可查看速度记录"
    ON public.achievement_speed_records
    FOR SELECT
    USING (true);

-- RLS 策略：系统可以插入速度记录
CREATE POLICY "系统可插入速度记录"
    ON public.achievement_speed_records
    FOR INSERT
    WITH CHECK (true);

-- ============================================================
-- 5. leaderboard_rewards 表（排行榜奖励）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.leaderboard_rewards (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    rank_min INTEGER NOT NULL,
    rank_max INTEGER NOT NULL,
    reward_type TEXT NOT NULL,
    reward_data JSONB NOT NULL,
    season_id TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT rank_range_valid CHECK (rank_min <= rank_max),
    CONSTRAINT rank_positive CHECK (rank_min > 0 AND rank_max > 0),
    CONSTRAINT reward_type_valid CHECK (reward_type IN ('resources', 'items', 'emblem', 'title', 'bonus'))

    -- 排名范围不能重叠（同一season内）
    -- EXCLUDE 约束需要 btree_gist 扩展
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_leaderboard_rewards_rank_range ON public.leaderboard_rewards(rank_min, rank_max);
CREATE INDEX IF NOT EXISTS idx_leaderboard_rewards_season ON public.leaderboard_rewards(season_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_rewards_is_active ON public.leaderboard_rewards(is_active);

-- 启用 RLS
ALTER TABLE public.leaderboard_rewards ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可以查看活跃奖励
CREATE POLICY "所有人可查看排行榜奖励"
    ON public.leaderboard_rewards
    FOR SELECT
    USING (is_active = true);

-- ============================================================
-- 6. leaderboard_seasons 表（排行榜赛季）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.leaderboard_seasons (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT end_date_after_start CHECK (end_date > start_date)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_leaderboard_seasons_dates ON public.leaderboard_seasons(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_leaderboard_seasons_is_active ON public.leaderboard_seasons(is_active);

-- 启用 RLS
ALTER TABLE public.leaderboard_seasons ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可以查看赛季信息
CREATE POLICY "所有人可查看赛季信息"
    ON public.leaderboard_seasons
    FOR SELECT
    USING (true);

-- ============================================================
-- 7. 函数：更新用户成就排行榜数据
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_user_achievement_leaderboard(
    p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_total_points INTEGER := 0;
    v_total_achievements INTEGER := 0;
    v_completion_rate DOUBLE PRECISION := 0;
    v_total_possible INTEGER := 0;
    v_existing_ranking INTEGER;
BEGIN
    -- 计算用户总积分和总成就数
    SELECT
        COALESCE(SUM(a.points), 0),
        COUNT(*) FILTER (WHERE ua.is_unlocked = true)
    INTO v_total_points, v_total_achievements
    FROM public.user_achievements ua
    INNER JOIN public.achievements a ON ua.achievement_id = a.id
    WHERE ua.user_id = p_user_id;

    -- 计算完成度
    SELECT COUNT(*) INTO v_total_possible
    FROM public.achievements
    WHERE is_active = true;

    IF v_total_possible > 0 THEN
        v_completion_rate := CAST(v_total_achievements AS DOUBLE PRECISION) / CAST(v_total_possible AS DOUBLE PRECISION);
    END IF;

    -- 获取现有排名
    SELECT ranking_position INTO v_existing_ranking
    FROM public.achievement_leaderboard
    WHERE user_id = p_user_id;

    -- 更新或插入排行榜数据
    INSERT INTO public.achievement_leaderboard (
        user_id,
        total_points,
        total_achievements,
        completion_rate,
        ranking_position,
        last_updated_at
    ) VALUES (
        p_user_id,
        v_total_points,
        v_total_achievements,
        v_completion_rate,
        v_existing_ranking,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        total_points = EXCLUDED.total_points,
        total_achievements = EXCLUDED.total_achievements,
        completion_rate = EXCLUDED.completion_rate,
        last_updated_at = EXCLUDED.last_updated_at;

    RETURN jsonb_build_object(
        'success', true,
        'total_points', v_total_points,
        'total_achievements', v_total_achievements,
        'completion_rate', v_completion_rate
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 8. 函数：更新用户分类排行榜数据
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_user_category_leaderboard(
    p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_category RECORD;
    v_category_points INTEGER;
    v_category_achievements INTEGER;
    v_existing_position INTEGER;
BEGIN
    -- 遍历每个成就分类
    FOR v_category IN
        SELECT DISTINCT category FROM public.achievements WHERE is_active = true
    LOOP
        -- 计算该分类下的积分和成就数
        SELECT
            COALESCE(SUM(a.points), 0),
            COUNT(*) FILTER (WHERE ua.is_unlocked = true)
        INTO v_category_points, v_category_achievements
        FROM public.user_achievements ua
        INNER JOIN public.achievements a ON ua.achievement_id = a.id
        WHERE ua.user_id = p_user_id
        AND a.category = v_category.category;

        -- 获取现有排名
        SELECT ranking_position INTO v_existing_position
        FROM public.category_leaderboard
        WHERE user_id = p_user_id AND category = v_category.category;

        -- 更新或插入分类排行榜数据
        INSERT INTO public.category_leaderboard (
            user_id,
            category,
            category_points,
            category_achievements,
            ranking_position,
            last_updated_at
        ) VALUES (
            p_user_id,
            v_category.category,
            v_category_points,
            v_category_achievements,
            v_existing_position,
            NOW()
        )
        ON CONFLICT (user_id, category) DO UPDATE SET
            category_points = EXCLUDED.category_points,
            category_achievements = EXCLUDED.category_achievements,
            last_updated_at = EXCLUDED.last_updated_at;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'message', '分类排行榜更新完成');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 9. 函数：重新计算排行榜排名
-- ============================================================

CREATE OR REPLACE FUNCTION public.recalculate_leaderboard_rankings()
) RETURNS JSONB AS $$
BEGIN
    -- 更新总榜排名
    WITH ranked_users AS (
        SELECT
            user_id,
            ROW_NUMBER() OVER (ORDER BY total_points DESC, created_at ASC) as new_rank
        FROM public.achievement_leaderboard
    )
    UPDATE public.achievement_leaderboard al
    SET ranking_position = ru.new_rank
    FROM ranked_users ru
    WHERE al.user_id = ru.user_id;

    -- 更新分类榜排名
    UPDATE public.category_leaderboard cl
    SET ranking_position = subq.new_rank
    FROM (
        SELECT
            user_id,
            category,
            ROW_NUMBER() OVER (PARTITION BY category ORDER BY category_points DESC, created_at ASC) as new_rank
        FROM public.category_leaderboard
    ) subq
    WHERE cl.user_id = subq.user_id AND cl.category = subq.category;

    RETURN jsonb_build_object('success', true, 'message', '排行榜排名更新完成');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 10. 函数：记录成就速度里程碑
-- ============================================================

CREATE OR REPLACE FUNCTION public.check_achievement_milestone(
    p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_user_creation_date TIMESTAMP WITH TIME ZONE;
    v_current_days INTEGER;
    v_unlocked_count INTEGER;
    v_message TEXT := '';
BEGIN
    -- 获取用户注册时间
    SELECT created_at INTO v_user_creation_date
    FROM public.profiles
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', '用户不存在');
    END IF;

    -- 计算已游玩天数
    v_current_days := EXTRACT(DAY FROM (NOW() - v_user_creation_date));

    -- 获取已解锁成就数
    SELECT COUNT(*) INTO v_unlocked_count
    FROM public.user_achievements
    WHERE user_id = p_user_id AND is_unlocked = true;

    -- 检查里程碑
    -- 10成就里程碑
    IF v_unlocked_count >= 10 THEN
        INSERT INTO public.achievement_speed_records (user_id, milestone_type, days_taken)
        VALUES (p_user_id, 'first_10', v_current_days)
        ON CONFLICT (user_id, milestone_type) DO NOTHING;

        IF FOUND THEN
            v_message := v_message || ' 达成10成就里程碑; ';
        END IF;
    END IF;

    -- 50成就里程碑
    IF v_unlocked_count >= 50 THEN
        INSERT INTO public.achievement_speed_records (user_id, milestone_type, days_taken)
        VALUES (p_user_id, 'first_50', v_current_days)
        ON CONFLICT (user_id, milestone_type) DO NOTHING;

        IF FOUND THEN
            v_message := v_message || ' 达成50成就里程碑; ';
        END IF;
    END IF;

    -- 100成就里程碑
    IF v_unlocked_count >= 100 THEN
        INSERT INTO public.achievement_speed_records (user_id, milestone_type, days_taken)
        VALUES (p_user_id, 'first_100', v_current_days)
        ON CONFLICT (user_id, milestone_type) DO NOTHING;

        IF FOUND THEN
            v_message := v_message || ' 达成100成就里程碑; ';
        END IF;
    END IF;

    -- 全部成就里程碑
    DECLARE
        v_total_possible INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_total_possible
        FROM public.achievements
        WHERE is_active = true;

        IF v_unlocked_count >= v_total_possible AND v_total_possible > 0 THEN
            INSERT INTO public.achievement_speed_records (user_id, milestone_type, days_taken)
            VALUES (p_user_id, 'all_achievements', v_current_days)
            ON CONFLICT (user_id, milestone_type) DO NOTHING;

            IF FOUND THEN
                v_message := v_message || ' 达成全成就里程碑!; ';
            END IF;
        END IF;
    END;

    RETURN jsonb_build_object(
        'success', true,
        'unlocked_count', v_unlocked_count,
        'days_played', v_current_days,
        'message', v_message
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 11. 触发器：成就解锁时自动更新排行榜
-- ============================================================

CREATE OR REPLACE FUNCTION public.on_achievement_unlock()
RETURNS TRIGGER AS $$
BEGIN
    -- 如果刚解锁了成就
    IF (NEW.is_unlocked = true AND OLD.is_unlocked = false) OR (TG_OP = 'INSERT') THEN
        -- 更新用户排行榜数据
        PERFORM public.update_user_achievement_leaderboard(NEW.user_id);
        PERFORM public.update_user_category_leaderboard(NEW.user_id);

        -- 检查里程碑
        PERFORM public.check_achievement_milestone(NEW.user_id);

        -- 异步重新计算排名（避免阻塞）
        -- 注意：需要在应用层或通过 pg_cron 调用 recalculate_leaderboard_rankings()
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_achievement_unlock_update_leaderboard
    AFTER INSERT OR UPDATE ON public.user_achievements
    FOR EACH ROW
    WHEN (NEW.is_unlocked = true)
    EXECUTE FUNCTION public.on_achievement_unlock();

-- ============================================================
-- 12. 视图：排行榜查询视图
-- ============================================================

CREATE OR REPLACE VIEW public.v_leaderboard_with_user AS
SELECT
    al.id,
    al.user_id,
    p.username,
    p.avatar_url,
    p.display_name,
    al.total_points,
    al.total_achievements,
    al.completion_rate,
    al.ranking_position,
    al.last_updated_at
FROM public.achievement_leaderboard al
INNER JOIN public.profiles p ON al.user_id = p.id
ORDER BY al.total_points DESC;

-- 分类排行榜视图
CREATE OR REPLACE VIEW public.v_category_leaderboard_with_user AS
SELECT
    cl.id,
    cl.user_id,
    p.username,
    p.avatar_url,
    p.display_name,
    cl.category,
    cl.category_points,
    cl.category_achievements,
    cl.ranking_position,
    cl.last_updated_at
FROM public.category_leaderboard cl
INNER JOIN public.profiles p ON cl.user_id = p.id
ORDER BY cl.category, cl.category_points DESC;

-- 速度记录视图
CREATE OR REPLACE VIEW public.v_speed_leaderboard AS
SELECT
    sr.id,
    sr.user_id,
    p.username,
    p.avatar_url,
    p.display_name,
    sr.milestone_type,
    sr.days_taken,
    sr.achieved_at,
    ROW_NUMBER() OVER (PARTITION BY sr.milestone_type ORDER BY sr.days_taken ASC) as ranking
FROM public.achievement_speed_records sr
INNER JOIN public.profiles p ON sr.user_id = p.id
ORDER BY sr.milestone_type, sr.days_taken ASC;

-- ============================================================
-- 13. 初始化默认赛季
-- ============================================================

INSERT INTO public.leaderboard_seasons (id, name, description, start_date, end_date)
VALUES (
    'season_1',
    '第一季：荒原开拓',
    'EarthLord首个成就竞赛赛季，探索荒原，解锁成就！',
    '2026-02-01 00:00:00+00',
    '2026-04-30 23:59:59+00'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 14. 初始化默认排行榜奖励
-- ============================================================

INSERT INTO public.leaderboard_rewards (rank_min, rank_max, reward_type, reward_data, season_id)
VALUES
    -- 第1名奖励
    (1, 1, 'emblem', '{"id": "champion_emblem", "name": "成就王者", "description": "赛季第1名专属徽章"}', 'season_1'),
    (1, 1, 'title', '{"id": "champion_title", "text": "荒原传奇"}', 'season_1'),
    (1, 1, 'resources', '{"food": 5000, "water": 5000, "wood": 5000, "metal": 5000}', 'season_1'),

    -- 第2-3名奖励
    (2, 3, 'emblem', '{"id": "runner_up_emblem", "name": "成就精英", "description": "赛季2-3名专属徽章"}', 'season_1'),
    (2, 3, 'resources', '{"food": 3000, "water": 3000, "wood": 3000, "metal": 3000}', 'season_1'),

    -- 第4-10名奖励
    (4, 10, 'emblem', '{"id": "top10_emblem", "name": "成就高手", "description": "赛季前10名专属徽章"}', 'season_1'),
    (4, 10, 'resources', '{"food": 1000, "water": 1000, "wood": 1000, "metal": 1000}', 'season_1'),

    -- 第11-50名奖励
    (11, 50, 'resources', '{"food": 500, "water": 500, "wood": 500, "metal": 500}', 'season_1'),

    -- 第51-100名奖励
    (51, 100, 'resources', '{"food": 200, "water": 200, "wood": 200, "metal": 200}', 'season_1')
ON CONFLICT DO NOTHING;

-- ============================================================
-- 15. 完成提示
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
        '010',
        'Day 60+: 创建成就排行榜系统 achievement_leaderboard, category_leaderboard, achievement_speed_records, leaderboard_rewards'
    )
    ON CONFLICT (version) DO NOTHING;
END $$;

DO $$
BEGIN
    RAISE NOTICE '✅ 迁移 010 执行成功！';
    RAISE NOTICE '📋 已创建表: achievement_leaderboard, category_leaderboard, achievement_speed_records, leaderboard_rewards, leaderboard_seasons';
    RAISE NOTICE '🔧 已创建函数: update_user_achievement_leaderboard, update_user_category_leaderboard, recalculate_leaderboard_rankings, check_achievement_milestone';
    RAISE NOTICE '🎯 已创建视图: v_leaderboard_with_user, v_category_leaderboard_with_user, v_speed_leaderboard';
    RAISE NOTICE '🏆 已初始化赛季和奖励数据';
END $$;
