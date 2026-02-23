-- ============================================================
-- 地球新主 (EarthLord) - 资源生产系统迁移脚本
-- 版本: 008
-- 创建日期: 2026-02-23
-- 说明: 创建资源生产系统相关表
-- ============================================================

-- ============================================================
-- 1. production_jobs 表（生产任务）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.production_jobs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    building_id TEXT NOT NULL,
    territory_id TEXT NOT NULL,
    resource_id TEXT NOT NULL,
    resource_name TEXT NOT NULL,
    amount INTEGER NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    completion_time TIMESTAMP WITH TIME ZONE NOT NULL,
    is_collected BOOLEAN DEFAULT false NOT NULL,
    collected_at TIMESTAMP WITH TIME ZONE,
    building_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT amount_positive CHECK (amount > 0),
    CONSTRAINT completion_after_start CHECK (completion_time > start_time)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_production_jobs_building_id ON public.production_jobs(building_id);
CREATE INDEX IF NOT EXISTS idx_production_jobs_territory_id ON public.production_jobs(territory_id);
CREATE INDEX IF NOT EXISTS idx_production_jobs_is_collected ON public.production_jobs(is_collected);
CREATE INDEX IF NOT EXISTS idx_production_jobs_completion_time ON public.production_jobs(completion_time);
CREATE INDEX IF NOT EXISTS idx_production_jobs_resource_id ON public.production_jobs(resource_id);

-- 组合索引：用于查询未收集的任务
CREATE INDEX IF NOT EXISTS idx_production_jobs_active ON public.production_jobs(is_collected, completion_time);

-- 启用 RLS
ALTER TABLE public.production_jobs ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户可以查看自己领地的生产任务（通过territories表关联）
CREATE POLICY "查看自己领地的生产任务"
    ON public.production_jobs
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.territories
            WHERE territories.id = production_jobs.territory_id
            AND territories.user_id = auth.uid()
        )
    );

-- RLS 策略：用户可以创建生产任务
CREATE POLICY "创建生产任务"
    ON public.production_jobs
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.territories
            WHERE territories.id = production_jobs.territory_id
            AND territories.user_id = auth.uid()
        )
    );

-- RLS 策略：用户可以更新生产任务（收集）
CREATE POLICY "更新生产任务"
    ON public.production_jobs
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.territories
            WHERE territories.id = production_jobs.territory_id
            AND territories.user_id = auth.uid()
        )
    );

-- ============================================================
-- 2. 创建触发器：自动更新 collected_at
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_production_collected_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_collected = true AND OLD.is_collected = false THEN
        NEW.collected_at = TIMEZONE('utc', NOW());
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_production_collected_at
    BEFORE UPDATE ON public.production_jobs
    FOR EACH ROW
    WHEN (NEW.is_collected = true AND OLD.is_collected = false)
    EXECUTE FUNCTION public.update_production_collected_at();

-- ============================================================
-- 3. 完成提示
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
        '008',
        'Day 50+: 创建资源生产系统表 production_jobs，支持建筑生产资源功能'
    )
    ON CONFLICT (version) DO NOTHING;
END $$;

DO $$
BEGIN
    RAISE NOTICE '✅ 迁移 008 执行成功！';
    RAISE NOTICE '🏭 已创建表: production_jobs';
    RAISE NOTICE '🔒 已启用 RLS 安全策略';
END $$;
