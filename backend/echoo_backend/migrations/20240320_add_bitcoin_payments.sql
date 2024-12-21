-- 创建比特币支付表
CREATE TABLE IF NOT EXISTS bitcoin_payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    amount_usd REAL NOT NULL,
    amount_btc REAL NOT NULL,
    bitcoin_address TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL CHECK(status IN ('pending', 'completed', 'expired')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_bitcoin_payments_user_id ON bitcoin_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_bitcoin_payments_status ON bitcoin_payments(status);
CREATE INDEX IF NOT EXISTS idx_bitcoin_payments_address ON bitcoin_payments(bitcoin_address);
