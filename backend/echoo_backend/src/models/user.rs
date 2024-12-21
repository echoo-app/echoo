use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use chrono::NaiveDateTime;

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct User {
    pub id: i64,
    pub username: String,
    #[serde(skip_serializing)]
    pub password_hash: String,
    pub api_calls: i32,
    pub invite_code: String,
    pub inviter_id: Option<i64>,
    pub created_at: NaiveDateTime,
    pub is_vip: bool,
}

#[derive(Debug, Serialize, FromRow)]
pub struct VipActivationCode {
    pub id: i64,
    pub code: String,
    pub enabled: bool,
    pub used: bool,
    pub used_by: Option<i64>,
    pub used_at: Option<NaiveDateTime>,
    pub payment_url: String,
    pub payment_url_expires_at: Option<NaiveDateTime>,
    pub created_at: NaiveDateTime,
}

#[derive(Debug, Deserialize)]
pub struct ActivateVipRequest {
    pub activation_code: String,
}

#[derive(Debug, Serialize)]
pub struct GenerateVipCodeResponse {
    pub code: String,
    pub payment_url: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateVipCodeRequest {
    pub enabled: Option<bool>,
    pub payment_url: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct VipCodeListResponse {
    pub codes: Vec<VipActivationCode>,
}

#[derive(Debug, Serialize)]
pub struct VipCodeDetailResponse {
    pub code: VipActivationCode,
    pub user: Option<User>,
}

#[derive(Debug, Deserialize)]
pub struct CreateUserRequest {
    pub username: String,
    pub password: String,
    pub invite_code: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub username: String,
    pub password: String,
}
