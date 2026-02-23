-- ============================================================
-- 地球新主 (EarthLord) - 领地徽章系统迁移脚本
-- 版本: 010
-- 创建日期: 2026-02-23
-- 说明: 创建领地徽章系统相关表
-- ============================================================

-- ============================================================
-- 1. territory_emblems 表（领地装备的徽章）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.territory_emblems (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    territory_id TEXT NOT NULL,
    emblem_id TEXT NOT NULL,
    equipped_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT unique_territory_emblem UNIQUE(user_id, territory_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_territory_emblems_user_id ON public.territory_emblems(user_id);
CREATE INDEX IF NOT EXISTS idx_territory_emblems_territory_id ON public.territory_emblems(territory_id);
CREATE INDEX IF NOT EXISTS idx_territory_emblems_emblem_id ON public.territory_emblems(emblem_id);

-- 启用 RLS
ALTER TABLE public.territory_emblems ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户只能查看自己的徽章
CREATE POLICY "查看自己的领地徽章"
    ON public.territory_emblems
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS 策略：用户可以装备徽章
CREATE POLICY "装备领地徽章"
    ON public.territory_emblems
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- RLS 策略：用户可以更新徽章
CREATE POLICY "更新领地徽章"
    ON public.territory_emblems
    FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================================
-- 2. user_emblems 表（用户已解锁的徽章）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_emblems (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    emblem_id TEXT NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT unique_user_emblem UNIQUE(user_id, emblem_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_user_emblems_user_id ON public.user_emblems(user_id);
CREATE INDEX IF NOT EXISTS idx_user_emblems_emblem_id ON public.user_emblems(emblem_id);

-- 启用 RLS
ALTER TABLE public.user_emblems ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户只能查看自己解锁的徽章
CREATE POLICY "查看自己解锁的徽章"
    ON public.user_emblems
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS 策略：系统可以解锁徽章
CREATE POLICY "解锁徽章"
    ON public.user_emblems
    FOR INSERT
    WITH CHECK (true);

-- ============================================================
-- 3. 徽章解锁函数
-- ============================================================

CREATE OR REPLACE FUNCTION public.unlock_emblem(
    p_user_id UUID,
    p_emblem_id TEXT
) RETURNS JSONB AS $$
DECLARE
    v_is_new_unlock BOOLEAN := false;
BEGIN
    -- 检查是否已解锁
    IF EXISTS (
        SELECT 1 FROM public.user_emblems
        WHERE user_id = p_user_id AND emblem_id = p_emblem_id
    ) THEN
        RETURN jsonb_build_object('success', true, 'is_new_unlock', false, 'message', '徽章已解锁');
    END IF;

    -- 解锁徽章
    INSERT INTO public.user_emblems (user_id, emblem_id)
    VALUES (p_user_id, p_emblem_id);

    v_is_new_unlock := true;

    RETURN jsonb_build_object(
        'success', true,
        'is_new_unlock', true,
        'emblem_id', p_emblem_id,
        'message', '徽章解锁成功'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 4. 装备徽章函数
-- ============================================================

CREATE OR REPLACE FUNCTION public.equip_emblem(
    p_user_id UUID,
    p_territory_id TEXT,
    p_emblem_id TEXT
) RETURNS JSONB AS $$
DECLARE
    v_has_emblem BOOLEAN := false;
BEGIN
    -- 检查用户是否已解锁该徽章
    SELECT EXISTS(
        SELECT 1 FROM public.user_emblems
        WHERE user_id = p_user_id AND emblem_id = p_emblem_id
    ) INTO v_has_emblem;

    IF NOT v_has_emblem THEN
        RETURN jsonb_build_object('success', false, 'error', '徽章未解锁');
    END IF;

    -- 检查领地是否属于该用户
    IF NOT EXISTS (
        SELECT 1 FROM public.territories
        WHERE user_id = p_user_id AND id::TEXT = p_territory_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', '领地不存在或无权限');
    END IF;

    -- 使用 UPSERT 装备徽章
    INSERT INTO public.territory_emblems (user_id, territory_id, emblem_id)
    VALUES (p_user_id, p_territory_id, p_emblem_id)
    ON CONFLICT (user_id, territory_id)
    DO UPDATE SET emblem_id = p_emblem_id, equipped_at = NOW();

    RETURN jsonb_build_object(
        'success', true,
        'territory_id', p_territory_id,
        'emblem_id', p_emblem_id,
        'message', '徽章装备成功'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 5. 获取领地徽章加成函数
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_territory_emblem_bonus(
    p_territory_id TEXT
) RETURNS JSONB AS $$
DECLARE
    v_emblem_id TEXT;
    v_bonus JSONB := '{"resource_production": 0, "building_speed": 0, "trade_discount": 0, "exploration": 0}'::jsonb;
BEGIN
    -- 获取领地装备的徽章
    SELECT emblem_id INTO v_emblem_id
    FROM public.territory_emblems
    WHERE territory_id = p_territory_id;

    IF v_emblem_id IS NULL THEN
        RETURN jsonb_build_object('success', true, 'has_emblem', false, 'bonus', v_bonus);
    END IF;

    -- 根据徽章ID返回加成（这里简化处理，实际应该从配置表读取）
    CASE v_emblem_id
        WHEN 'first_build' THEN
            v_bonus := '{"resource_production": 0, "building_speed": 0.05, "trade_discount": 0, "exploration": 0}'::jsonb;
        WHEN 'master_builder' THEN
            v_bonus := '{"resource_production": 0, "building_speed": 0.10, "trade_discount": 0, "exploration": 0}'::jsonb;
        WHEN 'lord' THEN
            v_bonus := '{"resource_production": 0.05, "building_speed": 0, "trade_discount": 0, "exploration": 0}'::jsonb;
        WHEN 'duke' THEN
            v_bonus := '{"resource_production": 0.15, "building_speed": 0, "trade_discount": 0, "exploration": 0}'::jsonb;
        WHEN 'harvest_badge' THEN
            v_bonus := '{"resource_production": 0.10, "building_speed": 0, "trade_discount": 0, "exploration": 0}'::jsonb;
        WHEN 'pioneer' THEN
            v_bonus := '{"resource_production": 0.20, "building_speed": 0.10, "trade_discount": 0.05, "exploration": 0.10}'::jsonb;
    END CASE;

    RETURN jsonb_build_object(
        'success', true,
        'has_emblem', true,
        'emblem_id', v_emblem_id,
        'bonus', v_bonus
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
        '010',
        'Day 50+: 创建领地徽章系统表 territory_emblems, user_emblems'
    )
    ON CONFLICT (version) DO NOTHING;
END $$;

DO $$
BEGIN
    RAISE NOTICE '✅ 迁移 010 执行成功！';
    RAISE NOTICE '🏆 已创建表: territory_emblems, user_emblems';
    RAISE NOTICE '🔧 已创建函数: unlock_emblem, equip_emblem, get_territory_emblem_bonus';
    RAISE NOTICE '🔒 已启用 RLS 安全策略';
END $$;
