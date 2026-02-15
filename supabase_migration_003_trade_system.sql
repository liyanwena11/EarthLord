-- ============================================================
-- 地球新主 (EarthLord) - Day 26 交易系统数据表迁移脚本
-- 版本: 003
-- 创建日期: 2026-02-15
-- 说明: 创建交易系统相关表结构和函数
-- ============================================================

-- ============================================================
-- 1. trade_offers 表（交易挂单）
-- 说明：存储用户发布的交易请求
-- ============================================================

CREATE TABLE IF NOT EXISTS public.trade_offers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    owner_username TEXT NOT NULL,
    offering_items JSONB NOT NULL,
    requesting_items JSONB NOT NULL,
    status TEXT DEFAULT 'active' NOT NULL,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    completed_by_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    completed_by_username TEXT,

    -- 约束
    CONSTRAINT status_valid CHECK (status IN ('active', 'completed', 'cancelled', 'expired'))
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_trade_offers_owner_id ON public.trade_offers(owner_id);
CREATE INDEX IF NOT EXISTS idx_trade_offers_status ON public.trade_offers(status);
CREATE INDEX IF NOT EXISTS idx_trade_offers_expires_at ON public.trade_offers(expires_at);
CREATE INDEX IF NOT EXISTS idx_trade_offers_created_at ON public.trade_offers(created_at DESC);

-- 组合索引：用于快速查询活跃且未过期的挂单
CREATE INDEX IF NOT EXISTS idx_trade_offers_active_expires ON public.trade_offers(status, expires_at);

-- 启用 RLS
ALTER TABLE public.trade_offers ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可以查看活跃状态的挂单
CREATE POLICY "所有人可查看活跃挂单" 
    ON public.trade_offers 
    FOR SELECT 
    USING (status = 'active' AND (expires_at IS NULL OR expires_at > NOW()));

-- RLS 策略：发布者可以查看自己的所有挂单
CREATE POLICY "发布者可查看自己的挂单" 
    ON public.trade_offers 
    FOR SELECT 
    USING (owner_id = auth.uid());

-- RLS 策略：发布者可以取消自己的挂单
CREATE POLICY "发布者可取消自己的挂单" 
    ON public.trade_offers 
    FOR UPDATE 
    USING (owner_id = auth.uid() AND status = 'active');

-- ============================================================
-- 2. trade_history 表（交易历史）
-- 说明：存储已完成的交易记录
-- ============================================================

CREATE TABLE IF NOT EXISTS public.trade_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    offer_id UUID REFERENCES public.trade_offers(id) ON DELETE SET NULL,
    seller_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    seller_username TEXT NOT NULL,
    buyer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    buyer_username TEXT NOT NULL,
    items_exchanged JSONB NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    seller_rating INTEGER,
    buyer_rating INTEGER,
    seller_comment TEXT,
    buyer_comment TEXT,

    -- 约束
    CONSTRAINT rating_valid CHECK (
        (seller_rating IS NULL OR (seller_rating >= 1 AND seller_rating <= 5)) AND
        (buyer_rating IS NULL OR (buyer_rating >= 1 AND buyer_rating <= 5))
    )
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_trade_history_seller_id ON public.trade_history(seller_id);
CREATE INDEX IF NOT EXISTS idx_trade_history_buyer_id ON public.trade_history(buyer_id);
CREATE INDEX IF NOT EXISTS idx_trade_history_completed_at ON public.trade_history(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_trade_history_offer_id ON public.trade_history(offer_id);

-- 组合索引：用于快速查询用户参与的交易
CREATE INDEX IF NOT EXISTS idx_trade_history_user ON public.trade_history(
    CASE WHEN seller_id = auth.uid() THEN seller_id ELSE buyer_id END
);

-- 启用 RLS
ALTER TABLE public.trade_history ENABLE ROW LEVEL SECURITY;

-- RLS 策略：只能查看自己参与的交易
CREATE POLICY "只能查看自己参与的交易" 
    ON public.trade_history 
    FOR SELECT 
    USING (seller_id = auth.uid() OR buyer_id = auth.uid());

-- RLS 策略：只能更新自己角色的评分
CREATE POLICY "只能更新自己角色的评分" 
    ON public.trade_history 
    FOR UPDATE 
    USING (
        (seller_id = auth.uid() AND seller_rating IS NULL) OR
        (buyer_id = auth.uid() AND buyer_rating IS NULL)
    )
    WITH CHECK (
        (seller_id = auth.uid() AND buyer_rating IS NOT DISTINCT FROM OLD.buyer_rating AND buyer_comment IS NOT DISTINCT FROM OLD.buyer_comment) OR
        (buyer_id = auth.uid() AND seller_rating IS NOT DISTINCT FROM OLD.seller_rating AND seller_comment IS NOT DISTINCT FROM OLD.seller_comment)
    );

-- ============================================================
-- 3. 数据库函数：创建交易挂单
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_trade_offer(
    p_owner_id UUID,
    p_owner_username TEXT,
    p_offering_items JSONB,
    p_requesting_items JSONB,
    p_message TEXT,
    p_expires_in_hours INTEGER
) RETURNS JSONB AS $$
DECLARE
    v_offer_id UUID;
    v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- 验证用户权限
    IF auth.uid() <> p_owner_id THEN
        RETURN jsonb_build_object('success', false, 'error', '权限不足');
    END IF;

    -- 计算过期时间
    IF p_expires_in_hours IS NOT NULL THEN
        v_expires_at := TIMEZONE('utc', NOW()) + (p_expires_in_hours || ' hours')::interval;
    END IF;

    -- 创建挂单记录
    INSERT INTO public.trade_offers (
        owner_id,
        owner_username,
        offering_items,
        requesting_items,
        message,
        expires_at
    ) VALUES (
        p_owner_id,
        p_owner_username,
        p_offering_items,
        p_requesting_items,
        p_message,
        v_expires_at
    ) RETURNING id INTO v_offer_id;

    RETURN jsonb_build_object('success', true, 'offer_id', v_offer_id);

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 4. 数据库函数：接受交易挂单
-- ============================================================

CREATE OR REPLACE FUNCTION public.accept_trade_offer(
    p_offer_id UUID,
    p_buyer_id UUID,
    p_buyer_username TEXT
) RETURNS JSONB AS $$
DECLARE
    v_offer RECORD;
    v_history_id UUID;
    v_exchange_info JSONB;
BEGIN
    -- 使用行级锁锁定挂单
    SELECT * INTO v_offer FROM public.trade_offers 
    WHERE id = p_offer_id 
    FOR UPDATE;

    -- 验证挂单存在
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', '挂单不存在');
    END IF;

    -- 验证挂单状态
    IF v_offer.status <> 'active' THEN
        RETURN jsonb_build_object('success', false, 'error', '挂单已失效');
    END IF;

    -- 验证挂单未过期
    IF v_offer.expires_at IS NOT NULL AND v_offer.expires_at <= NOW() THEN
        -- 更新状态为过期
        UPDATE public.trade_offers 
        SET status = 'expired' 
        WHERE id = p_offer_id;
        RETURN jsonb_build_object('success', false, 'error', '挂单已过期');
    END IF;

    -- 验证不能接受自己的挂单
    IF v_offer.owner_id = p_buyer_id THEN
        RETURN jsonb_build_object('success', false, 'error', '不能接受自己的挂单');
    END IF;

    -- 构建交换信息
    v_exchange_info := jsonb_build_object(
        'seller_gave', v_offer.offering_items,
        'buyer_gave', v_offer.requesting_items
    );

    -- 开始事务
    BEGIN
        -- 更新挂单状态
        UPDATE public.trade_offers 
        SET 
            status = 'completed',
            completed_at = TIMEZONE('utc', NOW()),
            completed_by_user_id = p_buyer_id,
            completed_by_username = p_buyer_username
        WHERE id = p_offer_id;

        -- 创建交易历史记录
        INSERT INTO public.trade_history (
            offer_id,
            seller_id,
            seller_username,
            buyer_id,
            buyer_username,
            items_exchanged
        ) VALUES (
            p_offer_id,
            v_offer.owner_id,
            v_offer.owner_username,
            p_buyer_id,
            p_buyer_username,
            v_exchange_info
        ) RETURNING id INTO v_history_id;

        RETURN jsonb_build_object('success', true, 'history_id', v_history_id);

    EXCEPTION
        WHEN OTHERS THEN
            -- 回滚事务
            ROLLBACK;
            RETURN jsonb_build_object('success', false, 'error', SQLERRM);
    END;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 5. 数据库函数：取消交易挂单
-- ============================================================

CREATE OR REPLACE FUNCTION public.cancel_trade_offer(
    p_offer_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_offer RECORD;
BEGIN
    -- 验证挂单存在且状态为活跃
    SELECT * INTO v_offer FROM public.trade_offers 
    WHERE id = p_offer_id 
    AND status = 'active';

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', '挂单不存在或已失效');
    END IF;

    -- 验证用户权限
    IF auth.uid() <> v_offer.owner_id THEN
        RETURN jsonb_build_object('success', false, 'error', '权限不足');
    END IF;

    -- 更新挂单状态
    UPDATE public.trade_offers 
    SET status = 'cancelled' 
    WHERE id = p_offer_id;

    RETURN jsonb_build_object('success', true);

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 6. 数据库函数：处理过期挂单
-- ============================================================

CREATE OR REPLACE FUNCTION public.process_expired_trade_offers() RETURNS JSONB AS $$
DECLARE
    v_processed_count INTEGER := 0;
BEGIN
    -- 更新过期的活跃挂单
    UPDATE public.trade_offers 
    SET status = 'expired' 
    WHERE status = 'active' 
    AND expires_at IS NOT NULL 
    AND expires_at <= NOW();

    v_processed_count := FOUND;

    RETURN jsonb_build_object('success', true, 'processed_count', v_processed_count);

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 7. 数据完整性视图（用于调试和监控）
-- ============================================================

-- 创建视图：交易挂单统计
CREATE OR REPLACE VIEW trade_offer_stats AS
SELECT
    status,
    COUNT(*) AS total_offers,
    COUNT(*) FILTER (WHERE expires_at IS NOT NULL) AS offers_with_expiry,
    COUNT(*) FILTER (WHERE expires_at IS NOT NULL AND expires_at <= NOW()) AS expired_offers,
    MAX(created_at) AS last_created
FROM public.trade_offers
GROUP BY status;

-- 创建视图：交易历史统计
CREATE OR REPLACE VIEW trade_history_stats AS
SELECT
    COUNT(*) AS total_trades,
    COUNT(*) FILTER (WHERE seller_rating IS NOT NULL) AS rated_by_seller,
    COUNT(*) FILTER (WHERE buyer_rating IS NOT NULL) AS rated_by_buyer,
    AVG(seller_rating) AS avg_seller_rating,
    AVG(buyer_rating) AS avg_buyer_rating,
    MAX(completed_at) AS last_trade
FROM public.trade_history;

-- 创建视图：用户交易统计
CREATE OR REPLACE VIEW user_trade_stats AS
SELECT
    user_id,
    COUNT(*) FILTER (WHERE role = 'seller') AS total_sold,
    COUNT(*) FILTER (WHERE role = 'buyer') AS total_bought,
    COUNT(*) AS total_trades,
    MAX(completed_at) AS last_trade
FROM (
    SELECT
        seller_id AS user_id,
        'seller' AS role,
        completed_at
    FROM public.trade_history
    UNION ALL
    SELECT
        buyer_id AS user_id,
        'buyer' AS role,
        completed_at
    FROM public.trade_history
) AS user_roles
GROUP BY user_id;

-- ============================================================
-- 8. 迁移完成
-- ============================================================

-- 记录迁移版本
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
        '003',
        'Day 26: 创建交易系统相关表结构和函数，包括 trade_offers、trade_history 表和相关数据库函数'
    )
    ON CONFLICT (version) DO NOTHING;
END $$;

-- 输出迁移成功信息
DO $$
BEGIN
    RAISE NOTICE '✅ 迁移 003 执行成功！';
    RAISE NOTICE '💰 已创建表：trade_offers, trade_history';
    RAISE NOTICE '🔧 已创建函数：create_trade_offer, accept_trade_offer, cancel_trade_offer, process_expired_trade_offers';
    RAISE NOTICE '📊 已创建视图：trade_offer_stats, trade_history_stats, user_trade_stats';
    RAISE NOTICE '🔒 已启用 RLS 安全策略';
END $$;