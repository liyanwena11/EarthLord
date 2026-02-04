-- ============================================================
-- 地球新主 (EarthLord) - Day 21 + Day 22 数据表迁移脚本
-- 版本: 002
-- 创建日期: 2026-01-21
-- 说明: 创建行走奖励、背包物品、探索会话表，并扩展 POI 表
-- ============================================================

-- ============================================================
-- 1. inventory_items 表（背包物品）
-- 说明：修复代码与 SQL 不一致问题，该表在代码中使用但 SQL 未定义
-- ============================================================

CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    item_id TEXT NOT NULL,
    quantity INTEGER DEFAULT 1 NOT NULL,
    acquired_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT quantity_positive CHECK (quantity > 0),
    CONSTRAINT unique_user_item UNIQUE (user_id, item_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_inventory_user_id ON public.inventory_items(user_id);
CREATE INDEX IF NOT EXISTS idx_inventory_item_id ON public.inventory_items(item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_updated_at ON public.inventory_items(updated_at DESC);

-- 启用 RLS
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户查看自己的背包
CREATE POLICY "用户查看自己的背包"
    ON public.inventory_items
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS 策略：用户更新自己的背包（包含 INSERT、UPDATE、DELETE）
CREATE POLICY "用户更新自己的背包"
    ON public.inventory_items
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 创建自动更新 updated_at 的触发器
CREATE OR REPLACE FUNCTION update_inventory_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_inventory_updated_at
    BEFORE UPDATE ON public.inventory_items
    FOR EACH ROW
    EXECUTE FUNCTION update_inventory_updated_at();

-- ============================================================
-- 2. walking_rewards 表（行走奖励记录）
-- 说明：记录用户解锁的行走奖励历史
-- ============================================================

CREATE TABLE IF NOT EXISTS public.walking_rewards (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    tier INTEGER NOT NULL,
    distance_meters DOUBLE PRECISION NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    items_received JSONB NOT NULL,

    -- 约束
    CONSTRAINT tier_valid CHECK (tier >= 1 AND tier <= 5),
    CONSTRAINT distance_positive CHECK (distance_meters > 0)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_walking_rewards_user_id ON public.walking_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_walking_rewards_unlocked_at ON public.walking_rewards(unlocked_at DESC);
CREATE INDEX IF NOT EXISTS idx_walking_rewards_tier ON public.walking_rewards(tier);

-- 组合索引：用于查询今日解锁等级
CREATE INDEX IF NOT EXISTS idx_walking_rewards_user_date ON public.walking_rewards(user_id, unlocked_at DESC);

-- 启用 RLS
ALTER TABLE public.walking_rewards ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户查看自己的奖励记录
CREATE POLICY "用户查看自己的奖励记录"
    ON public.walking_rewards
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS 策略：用户插入自己的奖励记录
CREATE POLICY "用户插入自己的奖励记录"
    ON public.walking_rewards
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 防止用户修改或删除已有记录（仅允许插入和查看）
-- 不创建 UPDATE 和 DELETE 策略

-- ============================================================
-- 3. exploration_sessions 表（探索会话历史）
-- 说明：记录用户在 POI 的探索行为
-- ============================================================

CREATE TABLE IF NOT EXISTS public.exploration_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    poi_id TEXT REFERENCES public.pois(id) ON DELETE SET NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    items_looted JSONB,
    duration_seconds INTEGER,

    -- 约束
    CONSTRAINT duration_positive CHECK (duration_seconds IS NULL OR duration_seconds >= 0)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_exploration_sessions_user_id ON public.exploration_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_exploration_sessions_poi_id ON public.exploration_sessions(poi_id);
CREATE INDEX IF NOT EXISTS idx_exploration_sessions_started_at ON public.exploration_sessions(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_exploration_sessions_completed_at ON public.exploration_sessions(completed_at DESC);

-- 组合索引：用于查询用户在特定 POI 的探索历史
CREATE INDEX IF NOT EXISTS idx_exploration_user_poi ON public.exploration_sessions(user_id, poi_id, started_at DESC);

-- 启用 RLS
ALTER TABLE public.exploration_sessions ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户查看自己的探索记录
CREATE POLICY "用户查看自己的探索记录"
    ON public.exploration_sessions
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS 策略：用户插入自己的探索记录
CREATE POLICY "用户插入自己的探索记录"
    ON public.exploration_sessions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- RLS 策略：用户更新自己的探索记录（例如设置 completed_at）
CREATE POLICY "用户更新自己的探索记录"
    ON public.exploration_sessions
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 4. 扩展 pois 表（添加冷却机制字段）
-- 说明：为 POI 添加 24 小时搜刮冷却时间
-- ============================================================

-- 添加冷却字段（如果不存在）
ALTER TABLE public.pois
ADD COLUMN IF NOT EXISTS cooldown_until TIMESTAMP WITH TIME ZONE;

-- 创建索引（用于快速查询冷却状态）
CREATE INDEX IF NOT EXISTS idx_pois_cooldown ON public.pois(cooldown_until);

-- 组合索引：查询特定 POI 的冷却状态
CREATE INDEX IF NOT EXISTS idx_pois_id_cooldown ON public.pois(id, cooldown_until);

-- ============================================================
-- 5. 数据完整性视图（可选，用于调试和监控）
-- ============================================================

-- 创建视图：用户背包统计
CREATE OR REPLACE VIEW user_inventory_stats AS
SELECT
    user_id,
    COUNT(*) AS total_items,
    SUM(quantity) AS total_quantity,
    MAX(updated_at) AS last_updated
FROM public.inventory_items
GROUP BY user_id;

-- 创建视图：用户行走奖励统计
CREATE OR REPLACE VIEW user_walking_stats AS
SELECT
    user_id,
    COUNT(*) AS total_rewards_unlocked,
    MAX(tier) AS highest_tier,
    MAX(distance_meters) AS max_distance,
    MAX(unlocked_at) AS last_unlock_time
FROM public.walking_rewards
GROUP BY user_id;

-- 创建视图：POI 探索热度统计
CREATE OR REPLACE VIEW poi_exploration_stats AS
SELECT
    poi_id,
    COUNT(*) AS total_explorations,
    COUNT(DISTINCT user_id) AS unique_explorers,
    AVG(duration_seconds) AS avg_duration_seconds,
    MAX(completed_at) AS last_explored
FROM public.exploration_sessions
WHERE completed_at IS NOT NULL
GROUP BY poi_id;

-- ============================================================
-- 6. 数据验证和初始化
-- ============================================================

-- 验证物品类型的有效性（可选，用于数据质量保证）
COMMENT ON COLUMN public.inventory_items.item_id IS '物品 ID，应与客户端定义的 itemId 一致（如 water_001, food_001 等）';
COMMENT ON COLUMN public.walking_rewards.tier IS '奖励等级，范围 1-5（200m/500m/1000m/2000m/3000m）';
COMMENT ON COLUMN public.exploration_sessions.duration_seconds IS '探索持续时间（秒），NULL 表示未完成';
COMMENT ON COLUMN public.pois.cooldown_until IS 'POI 搜刮冷却截止时间，NULL 表示可以搜刮';

-- ============================================================
-- 7. 迁移完成
-- ============================================================

-- 记录迁移版本（可选，用于追踪迁移历史）
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
        '002',
        'Day 21 + Day 22: 创建 inventory_items、walking_rewards、exploration_sessions 表，扩展 pois 表'
    )
    ON CONFLICT (version) DO NOTHING;
END $$;

-- 输出迁移成功信息
DO $$
BEGIN
    RAISE NOTICE '✅ 迁移 002 执行成功！';
    RAISE NOTICE '📦 已创建表：inventory_items, walking_rewards, exploration_sessions';
    RAISE NOTICE '🔧 已扩展 pois 表：添加 cooldown_until 字段';
    RAISE NOTICE '📊 已创建视图：user_inventory_stats, user_walking_stats, poi_exploration_stats';
    RAISE NOTICE '🔒 已启用 RLS 安全策略';
END $$;
