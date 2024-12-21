-- 创建临时表
CREATE TABLE users_temp (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    balance REAL NOT NULL DEFAULT 0,
    gpt4_mini_tokens INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 复制数据到临时表
INSERT INTO users_temp (id, username, password_hash, balance, gpt4_mini_tokens, created_at)
SELECT id, username, password_hash, balance, gpt4_mini_tokens, created_at
FROM users;

-- 删除原表
DROP TABLE users;

-- 重命名临时表
ALTER TABLE users_temp RENAME TO users;
