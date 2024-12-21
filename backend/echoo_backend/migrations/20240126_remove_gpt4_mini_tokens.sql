-- 删除 gpt4_mini_tokens 字段的迁移脚本

-- 创建一个新的临时表，不包含 gpt4_mini_tokens
CREATE TABLE users_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    balance REAL NOT NULL DEFAULT 0.0,
    invite_code TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 将数据从旧表复制到新表
INSERT INTO users_new (id, username, password_hash, balance, invite_code, created_at)
SELECT id, username, password_hash, balance, invite_code, created_at
FROM users;

-- 删除旧表
DROP TABLE users;

-- 重命名新表为 users
ALTER TABLE users_new RENAME TO users;
