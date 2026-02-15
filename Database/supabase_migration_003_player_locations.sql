-- 启用 PostGIS 扩展
CREATE EXTENSION IF NOT EXISTS postgis;

-- 创建玩家位置表
CREATE TABLE IF NOT EXISTS player_locations (
    player_id TEXT PRIMARY KEY,
    location GEOMETRY(Point, 4326),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_online BOOLEAN DEFAULT TRUE
);

-- 创建空间索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_player_locations_location ON player_locations USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_player_locations_updated_at ON player_locations (updated_at);

-- 创建或更新位置的 RPC 函数
CREATE OR REPLACE FUNCTION upsert_player_location(
    player_id TEXT,
    latitude DOUBLE PRECISION DEFAULT NULL,
    longitude DOUBLE PRECISION DEFAULT NULL,
    is_online BOOLEAN DEFAULT TRUE
) RETURNS VOID AS $$
BEGIN
    IF latitude IS NOT NULL AND longitude IS NOT NULL THEN
        INSERT INTO player_locations (player_id, location, updated_at, is_online)
        VALUES (player_id, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326), NOW(), is_online)
        ON CONFLICT (player_id) DO UPDATE
        SET 
            location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326),
            updated_at = NOW(),
            is_online = is_online;
    ELSE
        -- 仅更新在线状态
        UPDATE player_locations
        SET 
            updated_at = NOW(),
            is_online = is_online
        WHERE player_id = player_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 查询附近玩家数量的 RPC 函数
CREATE OR REPLACE FUNCTION get_nearby_player_count(
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    radius INTEGER DEFAULT 1000,
    player_id TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO count
    FROM player_locations
    WHERE 
        ST_DWithin(
            location,
            ST_SetSRID(ST_MakePoint(longitude, latitude), 4326),
            radius / 111319.9  -- 将米转换为度数
        )
        AND updated_at > NOW() - INTERVAL '5 minutes'
        AND is_online = TRUE
        AND (player_id IS NULL OR player_locations.player_id != player_id);
    
    RETURN count;
END;
$$ LANGUAGE plpgsql;

-- 清理离线玩家的函数（可选）
CREATE OR REPLACE FUNCTION cleanup_offline_players() RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM player_locations
    WHERE updated_at < NOW() - INTERVAL '1 hour'
    AND is_online = FALSE;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;
