-- ============================================================
-- 地球新主 (EarthLord) - 核心数据表迁移脚本
-- 版本: 001
-- 创建日期: 2025-12-30
-- ============================================================

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================
-- 1. profiles 表（用户资料）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 20),
    CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]+$')
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at DESC);

-- 启用 RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户可以查看所有资料
CREATE POLICY "公开查看用户资料"
    ON public.profiles
    FOR SELECT
    USING (true);

-- RLS 策略：用户只能插入自己的资料
CREATE POLICY "用户创建自己的资料"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- RLS 策略：用户只能更新自己的资料
CREATE POLICY "用户更新自己的资料"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 创建触发器：自动更新 updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 创建触发器：新用户注册时自动创建 profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 8)),
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 2. territories 表（领地）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.territories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    path JSONB NOT NULL,
    area DOUBLE PRECISION NOT NULL,
    geometry GEOMETRY(Polygon, 4326),
    allow_trade BOOLEAN DEFAULT true NOT NULL,
    status TEXT DEFAULT 'active' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,

    -- 约束
    CONSTRAINT name_length CHECK (char_length(name) >= 1 AND char_length(name) <= 50),
    CONSTRAINT area_positive CHECK (area > 0),
    CONSTRAINT area_range CHECK (area >= 100 AND area <= 100000),
    CONSTRAINT status_valid CHECK (status IN ('active', 'pending', 'expired'))
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_territories_user_id ON public.territories(user_id);
CREATE INDEX IF NOT EXISTS idx_territories_created_at ON public.territories(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_territories_area ON public.territories(area);
CREATE INDEX IF NOT EXISTS idx_territories_status ON public.territories(status);

-- 创建空间索引
CREATE INDEX IF NOT EXISTS idx_territories_geometry ON public.territories USING GIST(geometry);

-- 启用 RLS
ALTER TABLE public.territories ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可以查看激活状态的领地
CREATE POLICY "公开查看激活领地"
    ON public.territories
    FOR SELECT
    USING (status = 'active');

-- RLS 策略：用户可以创建自己的领地
CREATE POLICY "用户创建自己的领地"
    ON public.territories
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- RLS 策略：用户可以更新自己的领地
CREATE POLICY "用户更新自己的领地"
    ON public.territories
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- RLS 策略：用户可以删除自己的领地
CREATE POLICY "用户删除自己的领地"
    ON public.territories
    FOR DELETE
    USING (auth.uid() = user_id);

-- 创建触发器：自动更新 updated_at
CREATE TRIGGER set_territories_updated_at
    BEFORE UPDATE ON public.territories
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 创建触发器：从 path JSONB 自动生成 geometry
CREATE OR REPLACE FUNCTION public.update_territory_geometry()
RETURNS TRIGGER AS $$
DECLARE
    points TEXT;
    first_point TEXT;
BEGIN
    -- 从 JSONB path 提取坐标点并构建 WKT
    SELECT string_agg(
        (point->>'longitude')::text || ' ' || (point->>'latitude')::text,
        ','
    ) INTO points
    FROM jsonb_array_elements(NEW.path) AS point;

    -- 获取第一个点（用于闭合多边形）
    SELECT (NEW.path->0->>'longitude')::text || ' ' || (NEW.path->0->>'latitude')::text
    INTO first_point;

    -- 生成 POLYGON geometry
    NEW.geometry = ST_GeomFromText(
        'POLYGON((' || points || ',' || first_point || '))',
        4326
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_territory_geometry
    BEFORE INSERT OR UPDATE ON public.territories
    FOR EACH ROW
    EXECUTE FUNCTION public.update_territory_geometry();

-- ============================================================
-- 3. pois 表（兴趣点）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.pois (
    id TEXT PRIMARY KEY,
    poi_type TEXT NOT NULL,
    name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOGRAPHY(Point, 4326),
    discovered_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    discovered_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    last_looted_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    last_looted_at TIMESTAMP WITH TIME ZONE,
    loot_count INTEGER DEFAULT 0 NOT NULL,

    -- 约束
    CONSTRAINT latitude_valid CHECK (latitude >= -90 AND latitude <= 90),
    CONSTRAINT longitude_valid CHECK (longitude >= -180 AND longitude <= 180),
    CONSTRAINT poi_type_valid CHECK (poi_type IN (
        'hospital', 'pharmacy', 'supermarket', 'restaurant',
        'factory', 'construction', 'park', 'forest',
        'bank', 'jewelry', 'other'
    ))
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_pois_poi_type ON public.pois(poi_type);
CREATE INDEX IF NOT EXISTS idx_pois_discovered_by ON public.pois(discovered_by);
CREATE INDEX IF NOT EXISTS idx_pois_discovered_at ON public.pois(discovered_at DESC);
CREATE INDEX IF NOT EXISTS idx_pois_last_looted_at ON public.pois(last_looted_at DESC);

-- 创建空间索引
CREATE INDEX IF NOT EXISTS idx_pois_location ON public.pois USING GIST(location);

-- 启用 RLS
ALTER TABLE public.pois ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有认证用户可以查看 POI
CREATE POLICY "认证用户查看POI"
    ON public.pois
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- RLS 策略：认证用户可以创建 POI（发现新的）
CREATE POLICY "认证用户创建POI"
    ON public.pois
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- RLS 策略：认证用户可以更新 POI（记录搜刮）
CREATE POLICY "认证用户更新POI"
    ON public.pois
    FOR UPDATE
    USING (auth.role() = 'authenticated');

-- 创建触发器：自动从经纬度生成 location
CREATE OR REPLACE FUNCTION public.update_poi_location()
RETURNS TRIGGER AS $$
BEGIN
    NEW.location = ST_Point(NEW.longitude, NEW.latitude)::geography;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_poi_location
    BEFORE INSERT OR UPDATE ON public.pois
    FOR EACH ROW
    EXECUTE FUNCTION public.update_poi_location();

-- ============================================================
-- 辅助函数：查找附近的 POI
-- ============================================================

CREATE OR REPLACE FUNCTION public.find_nearby_pois(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 50
)
RETURNS TABLE (
    id TEXT,
    poi_type TEXT,
    name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    distance_meters DOUBLE PRECISION,
    can_loot BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.poi_type,
        p.name,
        p.latitude,
        p.longitude,
        ST_Distance(
            p.location,
            ST_Point(user_lng, user_lat)::geography
        ) AS distance_meters,
        (
            p.last_looted_at IS NULL OR
            p.last_looted_at < NOW() - INTERVAL '24 hours'
        ) AS can_loot
    FROM public.pois p
    WHERE ST_DWithin(
        p.location,
        ST_Point(user_lng, user_lat)::geography,
        radius_meters
    )
    ORDER BY distance_meters ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 辅助函数：检查领地重叠
-- ============================================================

CREATE OR REPLACE FUNCTION public.check_territory_overlap(
    new_geometry GEOMETRY
)
RETURNS BOOLEAN AS $$
DECLARE
    overlap_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO overlap_count
    FROM public.territories
    WHERE status = 'active'
    AND ST_Intersects(geometry, new_geometry);

    RETURN overlap_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 完成提示
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '✅ 地球新主核心数据表创建完成！';
    RAISE NOTICE '';
    RAISE NOTICE '已创建的表：';
    RAISE NOTICE '  1. profiles - 用户资料表';
    RAISE NOTICE '  2. territories - 领地表';
    RAISE NOTICE '  3. pois - 兴趣点表';
    RAISE NOTICE '';
    RAISE NOTICE '已创建的功能：';
    RAISE NOTICE '  ✓ RLS 安全策略';
    RAISE NOTICE '  ✓ 自动触发器';
    RAISE NOTICE '  ✓ 空间索引';
    RAISE NOTICE '  ✓ 辅助函数';
    RAISE NOTICE '';
    RAISE NOTICE '下一步：在 Supabase Dashboard 验证表结构';
END $$;
