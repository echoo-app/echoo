-- 添加邀请码字段
ALTER TABLE users ADD COLUMN invite_code TEXT NOT NULL DEFAULT '';

-- 添加邀请人字段
ALTER TABLE users ADD COLUMN inviter_id INTEGER DEFAULT NULL REFERENCES users(id);

-- 创建邀请码唯一索引
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_invite_code ON users(invite_code) WHERE invite_code != '';
