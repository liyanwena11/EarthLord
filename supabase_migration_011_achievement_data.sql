-- ============================================================
-- EarthLord - 成就数据初始化脚本
-- 版本: 011
-- 创建日期: 2026-02-26
-- 说明: 初始化成就定义数据
-- ============================================================

-- ============================================================
-- 1. 插入建筑成就
-- ============================================================

INSERT INTO public.achievements (id, category, title, description, icon, requirement, reward_emblem_id, reward_resources, reward_title, reward_experience, difficulty, points, is_active)
VALUES
    ('build_first', 'building', '第一块砖', '建造你的第一个建筑', 'house.fill', 'build_count:any:1', 'first_build', '{}', '建筑师学徒', 50, 'common', 10, true),
    ('build_10', 'building', '建造者', '建造10个建筑', 'building.2.fill', 'build_count:any:10', 'builder', '{"wood": 100, "metal": 50}', nil, 100, 'common', 10, true),
    ('build_50', 'building', '建筑大师', '建造50个建筑', 'building.columns.fill', 'build_count:any:50', 'master_builder', '{"wood": 500, "metal": 300}', '建筑大师', 500, 'rare', 30, true),
    ('build_100', 'building', '建筑宗师', '建造100个建筑', 'crown.fill', 'build_count:any:100', 'arch_grandmaster', '{"wood": 1000, "metal": 500}', '建筑宗师', 1000, 'epic', 50, true),
    ('build_all_types', 'building', '全能建造者', '建造所有类型的建筑', 'square.grid.3x3.fill', 'build_count:all_types:1', 'versatile_builder', '{"food": 500, "water": 500, "wood": 500, "metal": 500}', '全能建造者', 800, 'epic', 50, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 2. 插入资源成就
-- ============================================================

INSERT INTO public.achievements (id, category, title, description, icon, requirement, reward_emblem_id, reward_resources, reward_title, reward_experience, difficulty, points, is_active)
VALUES
    ('resource_1000', 'resource', '初探资源', '收集1000单位资源', 'cube.fill', 'resource_collected:any:1000', 'resource_collector_1', '{}', nil, 30, 'common', 10, true),
    ('resource_10000', 'resource', '资源大亨', '收集10000单位资源', 'cube.box.fill', 'resource_collected:any:10000', 'resource_tycoon', '{"food": 200, "water": 200}', nil, 100, 'common', 10, true),
    ('resource_100000', 'resource', '资源霸主', '收集100000单位资源', 'building.fill', 'resource_collected:any:100000', 'resource_master', '{"food": 1000, "water": 1000, "wood": 1000, "metal": 1000}', '资源霸主', 500, 'rare', 30, true),
    ('resource_1000000', 'resource', '资源王者', '收集1000000单位资源', 'crown.fill', 'resource_collected:any:1000000', 'resource_king', '{"food": 5000, "water": 5000, "wood": 5000, "metal": 5000}', '资源王者', 2000, 'legendary', 100, true),
    ('food_specialist', 'resource', '食物专家', '收集50000单位食物', 'leaf.fill', 'resource_collected:food:50000', 'food_specialist', '{"food": 1000}', nil, 200, 'rare', 30, true),
    ('water_specialist', 'resource', '水源守护者', '收集50000单位水', 'drop.fill', 'resource_collected:water:50000', 'water_guardian', '{"water": 1000}', nil, 200, 'rare', 30, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 3. 插入领地成就
-- ============================================================

INSERT INTO public.achievements (id, category, title, description, icon, requirement, reward_emblem_id, reward_resources, reward_title, reward_experience, difficulty, points, is_active)
VALUES
    ('territory_first', 'territory', '领主', '拥有你的第一个领地', 'flag.fill', 'territory_count:1', 'lord', '{}', '领主', 100, 'common', 10, true),
    ('territory_5', 'territory', '城主', '拥有5个领地', 'building.columns.fill', 'territory_count:5', 'city_lord', '{"food": 300, "water": 300}', '城主', 200, 'common', 10, true),
    ('territory_10', 'territory', '封疆大吏', '拥有10个领地', 'crown.fill', 'territory_count:10', 'territory_master', '{"food": 500, "water": 500, "wood": 500, "metal": 500}', '封疆大吏', 500, 'rare', 30, true),
    ('territory_50', 'territory', '帝国缔造者', '拥有50个领地', 'star.fill', 'territory_count:50', 'empire_builder', '{"food": 2000, "water": 2000, "wood": 2000, "metal": 2000}', '帝国缔造者', 2000, 'epic', 50, true),
    ('territory_level_10', 'territory', '繁荣领地', '将领地升级到10级', 'chart.line.uptrend.xyaxis', 'territory_level:10', 'prosperous_territory', '{"wood": 1000, "metal": 1000}', nil, 300, 'rare', 30, true),
    ('territory_level_50', 'territory', '超级领地', '将领地升级到50级', 'star.circle.fill', 'territory_level:50', 'super_territory', '{"food": 2000, "water": 2000, "wood": 2000, "metal": 2000}', '超级领地', 1000, 'epic', 50, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 4. 插入探索成就
-- ============================================================

INSERT INTO public.achievements (id, category, title, description, icon, requirement, reward_emblem_id, reward_resources, reward_title, reward_experience, difficulty, points, is_active)
VALUES
    ('explore_first', 'exploration', '探险家', '完成首次探索', 'safari.fill', 'poi_scavenged:1', 'explorer', '{}', '��险家', 50, 'common', 10, true),
    ('explore_10', 'exploration', '荒原探索者', '探索10个POI', 'map.fill', 'poi_scavenged:10', 'wasteland_explorer', '{"food": 200, "water": 200}', nil, 100, 'common', 10, true),
    ('explore_50', 'exploration', '荒原猎人', '探索50个POI', 'scope', 'poi_scavenged:50', 'wasteland_hunter', '{"food": 500, "water": 500, "wood": 300}', '荒原猎人', 300, 'rare', 30, true),
    ('explore_100', 'exploration', '荒原之王', '探索100个POI', 'crown.fill', 'poi_scavenged:100', 'wasteland_king', '{"food": 1000, "water": 1000, "wood": 1000, "metal": 500}', '荒原之王', 1000, 'epic', 50, true),
    ('explore_500', 'exploration', '地图制作者', '探索500个POI', 'map', 'poi_scavenged:500', 'cartographer', '{"food": 5000, "water": 5000, "wood": 5000, "metal": 5000}', '地图制作者', 5000, 'legendary', 100, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 5. 插入交易成就
-- ============================================================

INSERT INTO public.achievements (id, category, title, description, icon, requirement, reward_emblem_id, reward_resources, reward_title, reward_experience, difficulty, points, is_active)
VALUES
    ('trade_first', 'trade', '交易新手', '完成首次交易', 'arrow.left.arrow.right', 'trade_completed:1', 'trader', '{}', nil, 50, 'common', 10, true),
    ('trade_10', 'trade', '商人', '完成10次交易', 'banknote.fill', 'trade_completed:10', 'merchant', '{"food": 300, "water": 300}', '商人', 100, 'common', 10, true),
    ('trade_50', 'trade', '贸易专家', '完成50次交易', 'yensign.sign.circle', 'trade_completed:50', 'trade_expert', '{"food": 800, "water": 800, "wood": 500}', '贸易专家', 300, 'rare', 30, true),
    ('trade_100', 'trade', '贸易大师', '完成100次交易', 'crown.fill', 'trade_completed:100', 'trade_master', '{"food": 2000, "water": 2000, "wood": 2000, "metal": 1000}', '贸易大师', 1000, 'epic', 50, true),
    ('trade_1000', 'trade', '商业巨子', '完成1000次交易', 'star.fill', 'trade_completed:1000', 'trade_tycoon', '{"food": 10000, "water": 10000, "wood": 10000, "metal": 10000}', '商业巨子', 10000, 'legendary', 100, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 6. 插入社交成就
-- ============================================================

INSERT INTO public.achievements (id, category, title, description, icon, requirement, reward_emblem_id, reward_resources, reward_title, reward_experience, difficulty, points, is_active)
VALUES
    ('social_first_friend', 'social', '交友', '添加第一个好友', 'person.badge.plus', 'custom:social_friend:1', 'friendly', '{}', nil, 50, 'common', 10, true),
    ('social_10_friends', 'social', '人脉', '拥有10个好友', 'person.2.fill', 'custom:social_friend:10', 'connected', '{"food": 200, "water": 200}', '人脉达人', 100, 'common', 10, true),
    ('social_help_10', 'social', '乐于助人', '帮助好友10次', 'heart.fill', 'custom:social_help:10', 'helper', '{"food": 500, "water": 500}', '乐于助人', 200, 'rare', 30, true),
    ('social_guild', 'social', '公会成员', '加入公会', 'person.3.fill', 'custom:social_guild:1', 'guild_member', '{"food": 300, "water": 300}', '公会成员', 150, 'common', 10, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 7. 完成提示
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
        '011',
        '初始化成就定义数据 - 建筑成就、资源成就、领地成就、探索成就、交易成就、社交成就'
    )
    ON CONFLICT (version) DO NOTHING;
END $$;

DO $$
DECLARE
    achievement_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO achievement_count FROM public.achievements;

    RAISE NOTICE '✅ 迁移 011 执行成功！';
    RAISE NOTICE '📊 已插入 % 个成就定义', achievement_count;
    RAISE NOTICE '🏆 成就分类:';
    RAISE NOTICE '   - 建筑成就: 5个';
    RAISE NOTICE '   - 资源成就: 6个';
    RAISE NOTICE '   - 领地成就: 6个';
    RAISE NOTICE '   - 探索成就: 5个';
    RAISE NOTICE '   - 交易成就: 5个';
    RAISE NOTICE '   - 社交成就: 4个';
END $$;