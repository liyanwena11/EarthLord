-- Migration 006: Purchase Mailbox System
-- 内购邮箱系统 - 物资永不过期

CREATE TABLE IF NOT EXISTS purchase_mailbox (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_id         TEXT NOT NULL,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    rarity          TEXT NOT NULL DEFAULT 'common'
                        CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
    product_id      TEXT NOT NULL,       -- e.g. com.earthlord.supply.survivor
    transaction_id  TEXT,                -- StoreKit transaction ID (for dedup)
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_claimed      BOOLEAN NOT NULL DEFAULT FALSE,
    claimed_at      TIMESTAMPTZ
);

-- Index for fast lookup of pending items per user
CREATE INDEX IF NOT EXISTS idx_mailbox_user_unclaimed
    ON purchase_mailbox (user_id, is_claimed)
    WHERE is_claimed = FALSE;

-- Prevent duplicate delivery for the same StoreKit transaction + item
CREATE UNIQUE INDEX IF NOT EXISTS idx_mailbox_transaction_item
    ON purchase_mailbox (transaction_id, item_id)
    WHERE transaction_id IS NOT NULL;

-- RLS: users can only see and update their own mailbox rows
ALTER TABLE purchase_mailbox ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own mailbox"
    ON purchase_mailbox FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users update own mailbox"
    ON purchase_mailbox FOR UPDATE
    USING (auth.uid() = user_id);

-- Only server-side / service role can INSERT (via Supabase Edge Functions or trusted backend)
-- For direct client insert (MVP without server verification), allow authenticated users:
CREATE POLICY "Authenticated users insert mailbox"
    ON purchase_mailbox FOR INSERT
    WITH CHECK (auth.uid() = user_id);
