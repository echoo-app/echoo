-- 添加新字段到vip_activation_codes表
ALTER TABLE vip_activation_codes ADD COLUMN used BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE vip_activation_codes ADD COLUMN used_by INTEGER REFERENCES users(id);
ALTER TABLE vip_activation_codes ADD COLUMN used_at TIMESTAMP;
ALTER TABLE vip_activation_codes ADD COLUMN payment_url TEXT NOT NULL DEFAULT '';
ALTER TABLE vip_activation_codes ADD COLUMN payment_url_expires_at TIMESTAMP;

-- 重命名is_active为enabled以更好地表达其含义（是否启用/禁用）
ALTER TABLE vip_activation_codes RENAME COLUMN is_active TO enabled;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_vip_codes_used ON vip_activation_codes(used);
CREATE INDEX IF NOT EXISTS idx_vip_codes_used_by ON vip_activation_codes(used_by);
CREATE INDEX IF NOT EXISTS idx_vip_codes_payment_url ON vip_activation_codes(payment_url);
