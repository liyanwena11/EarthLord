-- ============================================================
-- 地球新主 (EarthLord) - 领地等级系统迁移脚本
-- 版本: 007
-- 创建日期: 2026-02-23
-- 说明: 添加领地等级系统相关字段
-- ============================================================

-- ============================================================
-- 1. 为 territories 表添加等级系统字段
-- ============================================================

DO $$
BEGIN
    -- 添加 level 字段（领地等级，默认1）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'territories' AND column_name = 'level'
    ) THEN
        ALTER TABLE territories ADD COLUMN level INTEGER DEFAULT 1;
        ALTER TABLE territories ALTER COLUMN level SET NOT NULL;
        RAISE NOTICE '✅ 添加 territories.level 字段';
    END IF;

    -- 添加 experience 字段（经验值）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'territories' AND column_name = 'experience'
    ) THEN
        ALTER TABLE territories ADD COLUMN experience INTEGER DEFAULT 0;
        RAISE NOTICE '✅ 添加 territories.experience 字段';
    END IF;

    -- 添加 prosperity 字段（繁荣度 0-100）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'territories' AND column_name = 'prosperity'
    ) THEN
        ALTER TABLE territories ADD COLUMN prosperity DOUBLE PRECISION DEFAULT 0;
        RAISE NOTICE '✅ 添加 territories.prosperity 字段';
    END IF;

    -- 添加 point_count 字段（如果不存在）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'territories' AND column_name = 'point_count'
    ) THEN
        ALTER TABLE territories ADD COLUMN point_count INTEGER;
        RAISE NOTICE '✅ 添加 territories.point_count 字段';
    END IF;

    -- 为现有的 null 记录设置默认值
    UPDATE territories SET level = 1 WHERE level IS NULL;
    UPDATE territories SET experience = 0 WHERE experience IS NULL;
    UPDATE territories SET prosperity = 0 WHERE prosperity IS NULL;

    -- 为现有的 point_count 为 null 的记录计算值
    UPDATE territories t
    SET point_count = jsonb_array_length(path)
    WHERE point_count IS NULL;

    RAISE NOTICE '✅ 更新现有记录的默认值';

END $$;

-- ============================================================
-- 2. 添加检查约束
-- ============================================================

DO $$
BEGIN
    -- level 范围约束 (1-5)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'territories_level_range'
    ) THEN
        ALTER TABLE territories
        ADD CONSTRAINT territories_level_range
        CHECK (level >= 1 AND level <= 5);
        RAISE NOTICE '✅ 添加 territories.level 范围约束';
    END IF;

    -- prosperity 范围约束 (0-100)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'territories_prosperity_range'
    ) THEN
        ALTER TABLE territories
        ADD CONSTRAINT territories_prosperity_range
        CHECK (prosperity >= 0 AND prosperity <= 100);
        RAISE NOTICE '✅ 添加 territories.prosperity 范围约束';
    END IF;

    -- experience 非负约束
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'territories_experience_nonnegative'
    ) THEN
        ALTER TABLE territories
        ADD CONSTRAINT territories_experience_nonnegative
        CHECK (experience >= 0);
        RAISE NOTICE '✅ 添加 territories.experience 非负约束';
    END IF;

END $$;

-- ============================================================
-- 3. 创建索引
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_territories_level ON territories(level);
CREATE INDEX IF NOT EXISTS idx_territories_experience ON territories(experience DESC);
CREATE INDEX IF NOT EXISTS idx_territories_prosperity ON territories(prosperity DESC);

-- ============================================================
-- 4. 创建领地等级升级函数
-- ============================================================

CREATE OR REPLACE FUNCTION public.calculate_territory_level(
    p_experience INTEGER,
    p_current_level INTEGER DEFAULT 1
) RETURNS INTEGER AS $$
DECLARE
    v_new_level INTEGER := p_current_level;
BEGIN
    -- 简单的等级计算公式
    -- Lv1->Lv2: 500 exp
    -- Lv2->Lv3: 1000 exp
    -- Lv3->Lv4: 1500 exp
    -- Lv4->Lv5: 2000 exp
    IF p_experience >= 2000 AND p_current_level < 5 THEN
        v_new_level := 5;
    ELSIF p_experience >= 1500 AND p_current_level < 4 THEN
        v_new_level := 4;
    ELSIF p_experience >= 1000 AND p_current_level < 3 THEN
        v_new_level := 3;
    ELSIF p_experience >= 500 AND p_current_level < 2 THEN
        v_new_level := 2;
    END IF;

    RETURN v_new_level;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================
-- 5. 添加经验值增加函数
-- ============================================================

CREATE OR REPLACE FUNCTION public.add_territory_experience(
    p_territory_id UUID,
    p_experience_amount INTEGER
) RETURNS JSONB AS $$
DECLARE
    v_territory RECORD;
    v_new_level INTEGER;
BEGIN
    -- 获取当前领地数据
    SELECT * INTO v_territory
    FROM territories
    WHERE id = p_territory_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', '领地不存在');
    END IF;

    -- 更新经验值
    UPDATE territories
    SET experience = experience + p_experience_amount
    WHERE id = p_territory_id;

    -- 计算新等级
    v_new_level := calculate_territory_level(
        v_territory.experience + p_experience_amount,
        v_territory.level
    );

    -- 如果等级提升，更新等级
    IF v_new_level > v_territory.level THEN
        UPDATE territories
        SET level = v_new_level
        WHERE id = p_territory_id;

        RETURN jsonb_build_object(
            'success', true,
            'experience_added', p_experience_amount,
            'new_experience', v_territory.experience + p_experience_amount,
            'level_up', true,
            'new_level', v_new_level,
            'previous_level', v_territory.level
        );
    ELSE
        RETURN jsonb_build_object(
            'success', true,
            'experience_added', p_experience_amount,
            'new_experience', v_territory.experience + p_experience_amount,
            'level_up', false,
            'current_level', v_territory.level
        );
    END IF;
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
        '007',
        'Day 50+: 添加领地等级系统，包括 level、experience、prosperity 字段及相关函数'
    )
    ON CONFLICT (version) DO NOTHING;
END $$;

DO $$
BEGIN
    RAISE NOTICE '✅ 迁移 007 执行成功！';
    RAISE NOTICE '🏰 已添加字段: level, experience, prosperity, point_count';
    RAISE NOTICE '🔧 已创建函数: calculate_territory_level, add_territory_experience';
    RAISE NOTICE '📊 已创建索引: level, experience, prosperity';
END $$;
