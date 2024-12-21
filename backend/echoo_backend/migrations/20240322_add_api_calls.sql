-- 添加api_calls字段
ALTER TABLE users ADD COLUMN api_calls INTEGER NOT NULL DEFAULT 0;

-- 将现有余额转换为调用次数（每$1等于100次调用）
UPDATE users SET api_calls = CAST(balance * 100 AS INTEGER);

-- 删除balance字段
ALTER TABLE users DROP COLUMN balance;
