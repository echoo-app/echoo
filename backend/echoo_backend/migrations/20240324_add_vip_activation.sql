-- 删除旧表（如果存在）
DROP TABLE IF EXISTS vip_activation_codes;

-- 创建VIP激活码表
CREATE TABLE vip_activation_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
