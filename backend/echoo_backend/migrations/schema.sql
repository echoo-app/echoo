-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    api_calls INTEGER NOT NULL DEFAULT 0,
    invite_code TEXT NOT NULL DEFAULT '',
    inviter_id INTEGER DEFAULT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_vip BOOLEAN NOT NULL DEFAULT FALSE
);

-- VIP激活码表
CREATE TABLE IF NOT EXISTS vip_activation_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建邀请码唯一索引
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_invite_code ON users(invite_code) WHERE invite_code != '';

-- 模型管理表
CREATE TABLE IF NOT EXISTS model_management (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    prompt_price TEXT,
    completion_price TEXT,
    image_price TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 聊天历史表
CREATE TABLE IF NOT EXISTS chat_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    role TEXT NOT NULL,
    session_id TEXT,
    topic TEXT,
    importance INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_chat_history_user_id ON chat_history(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_history_session_id ON chat_history(session_id);
