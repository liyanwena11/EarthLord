-- ============================================================
-- 修复现有领地的 point_count 字段
-- 问题：旧数据 point_count 为 NULL，导致显示采样点为0
-- 修复：从 path JSONB 数组中计算实际采样点数
-- ============================================================

-- 更新所有 point_count 为 NULL 的领地记录
UPDATE public.territories
SET point_count = jsonb_array_length(path::jsonb)
WHERE point_count IS NULL AND path IS NOT NULL;

-- 验证更新结果
SELECT
    COUNT(*) FILTER (WHERE point_count IS NULL) as null_point_count,
    COUNT(*) as total_territories
FROM public.territories;

-- 返回状态
SELECT '✅ territories.point_count 已更新' as status;
