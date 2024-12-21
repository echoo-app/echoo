use sqlx::SqlitePool;
use anyhow::{Result, anyhow};
use argon2::{
    password_hash::{
        SaltString,
        PasswordHash, 
        PasswordHasher, 
        PasswordVerifier
    },
    Argon2
};
use rand::{rngs::OsRng, Rng};
use chrono::Utc;

use crate::models::user::{
    User, CreateUserRequest, LoginRequest, 
    VipActivationCode, ActivateVipRequest, GenerateVipCodeResponse,
    UpdateVipCodeRequest
};

const INVITE_CODE_LENGTH: usize = 6;
const INVITE_REWARD: i32 = 30;

pub struct UserService {
    pool: SqlitePool,
}

impl UserService {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }

    async fn generate_unique_invite_code(&self) -> Result<String> {
        for _ in 0..10 {
            let code: String = rand::thread_rng()
                .sample_iter(&rand::distributions::Alphanumeric)
                .take(INVITE_CODE_LENGTH)
                .map(char::from)
                .collect::<String>()
                .to_uppercase();
            
            let exists = sqlx::query_scalar::<_, bool>(
                "SELECT EXISTS(SELECT 1 FROM users WHERE invite_code = ?)"
            )
            .bind(&code)
            .fetch_one(&self.pool)
            .await?;

            if !exists {
                return Ok(code);
            }
        }
        Err(anyhow!("Failed to generate unique invite code"))
    }

    async fn handle_invite_reward(&self, inviter_id: i64, invitee_id: i64) -> Result<()> {
        sqlx::query(
            "UPDATE users SET api_calls = api_calls + ? WHERE id = ?"
        )
        .bind(INVITE_REWARD)
        .bind(inviter_id)
        .execute(&self.pool)
        .await?;

        sqlx::query(
            "UPDATE users SET api_calls = api_calls + ? WHERE id = ?"
        )
        .bind(INVITE_REWARD)
        .bind(invitee_id)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn create_user(&self, req: CreateUserRequest) -> Result<User> {
        if req.password.len() < 6 {
            return Err(anyhow!("Password must be at least 6 characters"));
        }

        let exists = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS(SELECT 1 FROM users WHERE username = ?)"
        )
        .bind(&req.username)
        .fetch_one(&self.pool)
        .await?;

        if exists {
            return Err(anyhow!("Username already exists"));
        }

        let salt = SaltString::generate(&mut OsRng);
        let argon2 = Argon2::default();
        let password_hash = argon2.hash_password(
            req.password.as_bytes(), 
            &salt
        ).map_err(|e| anyhow!("Password hash error: {}", e))?.to_string();

        let invite_code = self.generate_unique_invite_code().await?;
        
        let inviter_id = if let Some(ref code) = req.invite_code {
            let inviter = sqlx::query_scalar::<_, Option<i64>>(
                "SELECT id FROM users WHERE invite_code = ?"
            )
            .bind(code)
            .fetch_one(&self.pool)
            .await?;

            match inviter {
                Some(id) => Some(id),
                None => return Err(anyhow!("Invalid invite code"))
            }
        } else {
            None
        };

        let user = sqlx::query_as::<_, User>(
            "INSERT INTO users (username, password_hash, api_calls, invite_code, inviter_id) 
             VALUES (?, ?, ?, ?, ?) 
             RETURNING *"
        )
        .bind(&req.username)
        .bind(&password_hash)
        .bind(100)
        .bind(&invite_code)
        .bind(inviter_id)
        .fetch_one(&self.pool)
        .await?;

        if let Some(inviter_id) = inviter_id {
            self.handle_invite_reward(inviter_id, user.id).await?;
        }

        Ok(user)
    }

    pub async fn login(&self, req: LoginRequest) -> Result<User> {
        let user = sqlx::query_as::<_, User>(
            "SELECT * FROM users WHERE username = ?"
        )
        .bind(&req.username)
        .fetch_one(&self.pool)
        .await?;

        let parsed_hash = PasswordHash::new(&user.password_hash)
            .map_err(|e| anyhow!("Password hash parse error: {}", e))?;
        let argon2 = Argon2::default();
        argon2.verify_password(req.password.as_bytes(), &parsed_hash)
            .map_err(|e| anyhow!("Password verification error: {}", e))?;

        Ok(user)
    }

    pub async fn get_user_by_id(&self, user_id: i64) -> Result<User> {
        let user = sqlx::query_as::<_, User>(
            "SELECT * FROM users WHERE id = ?"
        )
        .bind(user_id)
        .fetch_one(&self.pool)
        .await?;

        Ok(user)
    }

    pub async fn get_available_vip_payment_url(&self) -> Result<Option<String>> {
        let code = sqlx::query_as::<_, VipActivationCode>(
            "SELECT * FROM vip_activation_codes 
             WHERE enabled = TRUE AND used = FALSE 
             ORDER BY created_at DESC 
             LIMIT 1"
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(code.map(|c| c.payment_url))
    }

    pub async fn get_user_by_username(&self, username: &str) -> Result<User> {
        let user = sqlx::query_as::<_, User>(
            "SELECT * FROM users WHERE username = ?"
        )
        .bind(username)
        .fetch_one(&self.pool)
        .await?;

        Ok(user)
    }

    pub async fn get_all_users(&self) -> Result<Vec<User>> {
        let users = sqlx::query_as::<_, User>(
            "SELECT * FROM users ORDER BY created_at DESC"
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(users)
    }

    pub async fn update_user_api_calls(&self, user_id: i64, new_api_calls: i32) -> Result<User> {
        let is_vip = sqlx::query_scalar::<_, bool>(
            "SELECT is_vip FROM users WHERE id = ?"
        )
        .bind(user_id)
        .fetch_one(&self.pool)
        .await?;

        if is_vip {
            let user = sqlx::query_as::<_, User>(
                "SELECT * FROM users WHERE id = ?"
            )
            .bind(user_id)
            .fetch_one(&self.pool)
            .await?;
            return Ok(user);
        }

        let user = sqlx::query_as::<_, User>(
            "UPDATE users SET api_calls = ? WHERE id = ? RETURNING *"
        )
        .bind(new_api_calls)
        .bind(user_id)
        .fetch_one(&self.pool)
        .await?;

        Ok(user)
    }

    pub async fn generate_vip_code(&self) -> Result<GenerateVipCodeResponse> {
        let code = uuid::Uuid::new_v4().to_string();
        let payment_url = format!("https://echoo.ai/pay/{}", uuid::Uuid::new_v4().to_string());
        let expires_at = Utc::now().naive_utc() + chrono::Duration::days(7);
        
        let activation_code = sqlx::query_as::<_, VipActivationCode>(
            "INSERT INTO vip_activation_codes (code, payment_url, payment_url_expires_at, enabled) 
             VALUES (?, ?, ?, TRUE) 
             RETURNING *"
        )
        .bind(&code)
        .bind(&payment_url)
        .bind(expires_at)
        .fetch_one(&self.pool)
        .await?;

        Ok(GenerateVipCodeResponse { 
            code: activation_code.code,
            payment_url: activation_code.payment_url,
        })
    }

    pub async fn activate_vip(&self, user_id: i64, req: ActivateVipRequest) -> Result<User> {
        let mut tx = self.pool.begin().await?;

        let activation_code = sqlx::query_as::<_, VipActivationCode>(
            "SELECT * FROM vip_activation_codes 
             WHERE code = ? AND enabled = TRUE AND used = FALSE"
        )
        .bind(&req.activation_code)
        .fetch_optional(tx.as_mut())
        .await?
        .ok_or_else(|| anyhow!("Invalid or already used activation code"))?;

        // 标记激活码为已使用
        sqlx::query(
            "UPDATE vip_activation_codes 
             SET used = TRUE, used_by = ?, used_at = CURRENT_TIMESTAMP 
             WHERE id = ?"
        )
        .bind(user_id)
        .bind(activation_code.id)
        .execute(tx.as_mut())
        .await?;

        // 更新用户VIP状态
        let user = sqlx::query_as::<_, User>(
            "UPDATE users SET is_vip = TRUE WHERE id = ? RETURNING *"
        )
        .bind(user_id)
        .fetch_one(tx.as_mut())
        .await?;

        tx.commit().await?;
        Ok(user)
    }


    pub async fn list_vip_codes(&self) -> Result<Vec<VipActivationCode>> {
        let codes = sqlx::query_as::<_, VipActivationCode>(
            "SELECT * FROM vip_activation_codes ORDER BY created_at DESC"
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(codes)
    }

    pub async fn update_vip_code(&self, code_id: i64, req: UpdateVipCodeRequest) -> Result<VipActivationCode> {
        let mut updates = Vec::new();
        let mut binds = Vec::new();

        if let Some(enabled) = req.enabled {
            updates.push("enabled = ?");
            binds.push(enabled.to_string());
        }

        if let Some(payment_url) = req.payment_url {
            updates.push("payment_url = ?");
            binds.push(payment_url);
            // 更新支付URL时重置过期时间
            updates.push("payment_url_expires_at = ?");
            binds.push((Utc::now().naive_utc() + chrono::Duration::days(7)).to_string());
        }

        if updates.is_empty() {
            return Err(anyhow!("No updates provided"));
        }

        let query = format!(
            "UPDATE vip_activation_codes SET {} WHERE id = ? RETURNING *",
            updates.join(", ")
        );

        let mut query_builder = sqlx::query_as::<_, VipActivationCode>(&query);
        
        for bind in binds {
            query_builder = query_builder.bind(bind);
        }
        query_builder = query_builder.bind(code_id);

        let code = query_builder.fetch_one(&self.pool).await?;
        Ok(code)
    }

    pub async fn delete_vip_code(&self, code: &str) -> Result<()> {
        let result = sqlx::query(
            "DELETE FROM vip_activation_codes WHERE code = ?"
        )
        .bind(code)
        .execute(&self.pool)
        .await?;

        if result.rows_affected() == 0 {
            return Err(anyhow!("激活码不存在"));
        }

        Ok(())
    }

    pub async fn delete_user(&self, user_id: i64) -> Result<()> {
        tracing::info!("Executing delete user SQL, user ID: {}", user_id);
        
        let mut tx = self.pool.begin().await?;

        // 删除用户相关的所有数据
        sqlx::query("DELETE FROM chat_history WHERE user_id = ?")
            .bind(user_id)
            .execute(tx.as_mut())
            .await?;

        sqlx::query("UPDATE users SET inviter_id = NULL WHERE inviter_id = ?")
            .bind(user_id)
            .execute(tx.as_mut())
            .await?;

        // 更新激活码表中的用户引用
        sqlx::query("UPDATE vip_activation_codes SET used_by = NULL WHERE used_by = ?")
            .bind(user_id)
            .execute(tx.as_mut())
            .await?;

        let result = sqlx::query("DELETE FROM users WHERE id = ?")
            .bind(user_id)
            .execute(tx.as_mut())
            .await?;

        tx.commit().await?;
            
        tracing::info!("Delete user SQL result: {:?}", result);
        
        if result.rows_affected() == 0 {
            return Err(anyhow!("User not found"));
        }
        Ok(())
    }
}
