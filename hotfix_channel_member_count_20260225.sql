-- ============================================================
-- EarthLord 通讯系统热修复：频道 member_count 精准回写
-- 日期: 2026-02-25
-- 用途:
-- 1) 修复 subscribe/unsubscribe 的成员数更新逻辑
-- 2) 立即纠正历史累加误差
-- ============================================================

-- 订阅频道：按真实订阅数回写
CREATE OR REPLACE FUNCTION public.subscribe_to_channel(
    p_user_id UUID,
    p_channel_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.channel_subscriptions (user_id, channel_id)
    VALUES (p_user_id, p_channel_id)
    ON CONFLICT (user_id, channel_id) DO NOTHING;

    UPDATE public.communication_channels
    SET member_count = (
            SELECT COUNT(*)
            FROM public.channel_subscriptions
            WHERE channel_id = p_channel_id
        ),
        updated_at = NOW()
    WHERE id = p_channel_id;
END;
$$;

-- 取消订阅：按真实订阅数回写
CREATE OR REPLACE FUNCTION public.unsubscribe_from_channel(
    p_user_id UUID,
    p_channel_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.channel_subscriptions
    WHERE user_id = p_user_id AND channel_id = p_channel_id;

    UPDATE public.communication_channels
    SET member_count = (
            SELECT COUNT(*)
            FROM public.channel_subscriptions
            WHERE channel_id = p_channel_id
        ),
        updated_at = NOW()
    WHERE id = p_channel_id;
END;
$$;

-- 一次性修正所有频道历史 member_count 偏差
UPDATE public.communication_channels c
SET member_count = (
        SELECT COUNT(*)
        FROM public.channel_subscriptions s
        WHERE s.channel_id = c.id
    ),
    updated_at = NOW();

-- 校验结果：应该返回 0 行
SELECT
    c.id,
    c.name,
    c.member_count,
    COALESCE(s.real_count, 0) AS real_count
FROM public.communication_channels c
LEFT JOIN (
    SELECT channel_id, COUNT(*) AS real_count
    FROM public.channel_subscriptions
    GROUP BY channel_id
) s ON s.channel_id = c.id
WHERE c.member_count <> COALESCE(s.real_count, 0);
