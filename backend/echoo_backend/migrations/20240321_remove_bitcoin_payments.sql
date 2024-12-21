-- 删除索引
DROP INDEX IF EXISTS idx_bitcoin_payments_user_id;
DROP INDEX IF EXISTS idx_bitcoin_payments_status;
DROP INDEX IF EXISTS idx_bitcoin_payments_address;

-- 删除表
DROP TABLE IF EXISTS bitcoin_payments;
