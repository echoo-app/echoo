-- 添加 is_vip 字段到 users 表
ALTER TABLE users ADD COLUMN is_vip BOOLEAN NOT NULL DEFAULT FALSE;
