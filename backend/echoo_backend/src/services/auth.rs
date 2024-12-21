use jsonwebtoken::{encode, EncodingKey, Header};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};
use std::env;
use tracing::info;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: i64,  // user_id
    pub exp: usize,  // 过期时间
}

pub fn get_jwt_secret() -> Vec<u8> {
    env::var("JWT_SECRET")
        .unwrap_or_else(|_| "default_secret_key_please_change_in_production".to_string())
        .into_bytes()
}

pub fn create_token(user_id: i64) -> Result<String, jsonwebtoken::errors::Error> {
    info!("开始创建token，用户ID: {}", user_id);

    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs() as usize;

    let claims = Claims {
        sub: user_id,
        exp: now + 24 * 3600,  // 24小时后过期
    };

    let jwt_secret = get_jwt_secret();
    info!("获取到JWT密钥");

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(&jwt_secret),
    )?;

    info!("Token创建成功");
    Ok(token)
}
