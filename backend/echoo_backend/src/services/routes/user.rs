use axum::{
    response::Json,
    extract::{State, Path, Extension},
    http::StatusCode,
};
use sqlx::SqlitePool;
use std::env;
use serde::{Serialize, Deserialize};

use crate::services::user_service::UserService;
use crate::models::user::{LoginRequest, CreateUserRequest, User, ActivateVipRequest, GenerateVipCodeResponse};
use crate::services::auth::create_token;

#[derive(Debug, Serialize, Deserialize)]
pub struct LoginResponse {
    pub message: String,
    pub user: User,
    pub token: String,
    pub vip_payment_url: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RegisterResponse {
    pub message: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AdminCheckResponse {
    pub username: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub error: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateApiCallsRequest {
    pub api_calls: i32,
}

pub async fn get_users_handler(
    State(pool): State<SqlitePool>,
) -> Result<Json<Vec<User>>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool);
    
    match user_service.get_all_users().await {
        Ok(users) => Ok(Json(users)),
        Err(err) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("获取用户列表失败: {}", err),
            }),
        )),
    }
}

pub async fn register_handler(
    State(pool): State<SqlitePool>,
    Json(register_req): Json<CreateUserRequest>,
) -> Result<Json<RegisterResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool);

    match user_service.create_user(register_req).await {
        Ok(_) => Ok(Json(RegisterResponse {
            message: "Register success".to_string(),
        })),
        Err(err) => Err((
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: format!("Registration failed: {}", err),
            }),
        )),
    }
}

pub async fn login_handler(
    State(pool): State<SqlitePool>,
    Json(login_req): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool);

    match user_service.login(login_req).await {
        Ok(user) => {
            // 生成JWT token
            let token = create_token(user.id).map_err(|e| {
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ErrorResponse {
                        error: format!("Token生成失败: {}", e),
                    }),
                )
            })?;

            // 获取可用的VIP支付链接
            let vip_payment_url = user_service.get_available_vip_payment_url().await.map_err(|e| {
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ErrorResponse {
                        error: format!("获取支付链接失败: {}", e),
                    }),
                )
            })?;

            Ok(Json(LoginResponse {
                message: "登录成功".to_string(),
                user: user.clone(),
                token,
                vip_payment_url,
            }))
        },
        Err(err) => Err((
            StatusCode::UNAUTHORIZED, 
            Json(ErrorResponse {
                error: format!("登录失败: {}", err),
            })
        ))
    }
}

pub async fn get_user_info_handler(
    State(pool): State<SqlitePool>,
    Path(username): Path<String>,
) -> Result<Json<User>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool);

    match user_service.get_user_by_username(&username).await {
        Ok(user) => Ok(Json(user)),
        Err(err) => Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: format!("获取用户信息失败: {}", err),
            }),
        )),
    }
}

pub async fn check_auth_handler(
    State(pool): State<SqlitePool>,
    Extension(user_id): Extension<i64>,
) -> Result<StatusCode, StatusCode> {
    let user_service = UserService::new(pool);
    match user_service.get_user_by_id(user_id).await {
        Ok(_) => Ok(StatusCode::OK),
        Err(_) => Err(StatusCode::UNAUTHORIZED),
    }
}

pub async fn check_admin_handler(
    State(pool): State<SqlitePool>,
) -> Result<Json<AdminCheckResponse>, StatusCode> {
    let admin_username = env::var("ADMIN_USERNAME").unwrap_or_else(|_| "bde".to_string());
    let user_service = UserService::new(pool);

    match user_service.get_user_by_username(&admin_username).await {
        Ok(user) => Ok(Json(AdminCheckResponse {
            username: user.username,
        })),
        Err(_) => Err(StatusCode::UNAUTHORIZED)
    }
}

pub async fn update_api_calls_handler(
    State(pool): State<SqlitePool>,
    Path(user_id): Path<i64>,
    Json(req): Json<UpdateApiCallsRequest>,
) -> Result<Json<User>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool);

    match user_service.update_user_api_calls(user_id, req.api_calls).await {
        Ok(user) => Ok(Json(user)),
        Err(err) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("更新调用次数失败: {}", err),
            }),
        )),
    }
}

// 生成VIP激活码 (仅管理员)
pub async fn generate_vip_code_handler(
    State(pool): State<SqlitePool>,
    Extension(user_id): Extension<i64>,
) -> Result<Json<GenerateVipCodeResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool.clone());
    
    // 检查是否是管理员
    let admin_username = env::var("ADMIN_USERNAME").unwrap_or_else(|_| "bde".to_string());
    let user = user_service.get_user_by_id(user_id).await.map_err(|e| {
        (StatusCode::UNAUTHORIZED, Json(ErrorResponse {
            error: format!("获取用户信息失败: {}", e),
        }))
    })?;

    if user.username != admin_username {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ErrorResponse {
                error: "只有管理员可以生成VIP激活码".to_string(),
            }),
        ));
    }

    // 生成VIP激活码
    match user_service.generate_vip_code().await {
        Ok(response) => Ok(Json(response)),
        Err(err) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("生成VIP激活码失败: {}", err),
            }),
        )),
    }
}

// 激活VIP
pub async fn activate_vip_handler(
    State(pool): State<SqlitePool>,
    Extension(user_id): Extension<i64>,
    Json(req): Json<ActivateVipRequest>,
) -> Result<Json<User>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool);

    match user_service.activate_vip(user_id, req).await {
        Ok(user) => Ok(Json(user)),
        Err(err) => Err((
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: format!("激活VIP失败: {}", err),
            }),
        )),
    }
}

pub async fn get_vip_payment_url_handler(
    State(pool): State<SqlitePool>,
) -> Result<Json<serde_json::Value>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool);
    
    match user_service.get_available_vip_payment_url().await {
        Ok(url) => Ok(Json(serde_json::json!({
            "payment_url": url
        }))),
        Err(err) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("获取支付链接失败: {}", err),
            }),
        )),
    }
}

pub async fn delete_user_handler(
    State(pool): State<SqlitePool>,
    Path(user_id): Path<i64>,
) -> Result<StatusCode, (StatusCode, Json<ErrorResponse>)> {
    tracing::info!("开始删除用户，ID: {}", user_id);
    
    let user_service = UserService::new(pool);

    match user_service.delete_user(user_id).await {
        Ok(_) => {
            tracing::info!("用户删除成功，ID: {}", user_id);
            Ok(StatusCode::NO_CONTENT)
        },
        Err(err) => {
            tracing::error!("删除用户失败，ID: {}, 错误: {}", user_id, err);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: format!("删除用户失败: {}", err),
                }),
            ))
        },
    }
}
