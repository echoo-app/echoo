use axum::{
    response::Json,
    http::StatusCode,
    extract::{State, Extension, Path},
};
use argon2::PasswordHasher;
use serde::{Serialize, Deserialize};
use std::{env, fs, path::Path as StdPath};
use sqlx::SqlitePool;
use crate::services::user_service::UserService;
use crate::models::user::{VipActivationCode, VipCodeListResponse, UpdateVipCodeRequest, GenerateVipCodeResponse};

const ENV_FILE_PATH: &str = ".env";

#[derive(Debug, Serialize, Deserialize)]
pub struct ApiKeyRequest {
    pub api_key: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateAdminRequest {
    pub new_username: Option<String>,
    pub new_password: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct UpdateAdminResponse {
    pub message: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ApiKeyResponse {
    pub message: String,
    pub api_key: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub error: String,
}

// 统一的环境变量处理函数
pub fn handle_env_var(key: &str, value: Option<&str>) -> Option<String> {
    if let Some(val) = value {
        // 读取现有环境文件内容
        let mut env_vars = std::collections::HashMap::new();
        if StdPath::new(ENV_FILE_PATH).exists() {
            if let Ok(content) = fs::read_to_string(ENV_FILE_PATH) {
                for line in content.lines() {
                    if let Some((k, v)) = line.split_once('=') {
                        env_vars.insert(k.trim().to_string(), v.trim().to_string());
                    }
                }
            }
        }

        // 更新或添加新的环境变量
        env_vars.insert(key.to_string(), val.to_string());

        // 读取原始文件内容，保留注释和格式
        let original_content = fs::read_to_string(ENV_FILE_PATH).unwrap_or_default();
        let mut new_content = Vec::new();
        let mut updated_keys = std::collections::HashSet::new();

        // 处理原始文件的每一行
        for line in original_content.lines() {
            if line.trim().starts_with('#') || line.trim().is_empty() {
                // 保留注释和空行
                new_content.push(line.to_string());
            } else if let Some((k, _)) = line.split_once('=') {
                let key = k.trim();
                if let Some(new_value) = env_vars.get(key) {
                    // 更新已存在的环境变量
                    new_content.push(format!("{}={}", key, new_value));
                    updated_keys.insert(key.to_string());
                } else {
                    // 保留未修改的环境变量
                    new_content.push(line.to_string());
                }
            }
        }

        // 添加新的环境变量
        for (k, v) in env_vars.iter() {
            if !updated_keys.contains(k) {
                new_content.push(format!("{}={}", k, v));
            }
        }

        // 写入文件
        if let Err(e) = fs::write(ENV_FILE_PATH, new_content.join("\n") + "\n") {
            eprintln!("无法写入环境文件: {}", e);
            return None;
        }

        // 设置环境变量
        env::set_var(key, val);
        Some(val.to_string())
    } else {
        // 尝试从环境文件读取
        if StdPath::new(ENV_FILE_PATH).exists() {
            if let Ok(content) = fs::read_to_string(ENV_FILE_PATH) {
                for line in content.lines() {
                    if let Some((k, v)) = line.split_once('=') {
                        if k.trim() == key {
                            return Some(v.trim().to_string());
                        }
                    }
                }
            }
        }
        env::var(key).ok()
    }
}

// 简化的API密钥处理函数
async fn handle_api_key(api_key: Option<String>) -> Result<Json<ApiKeyResponse>, (StatusCode, Json<ErrorResponse>)> {
    match api_key {
        Some(key) => {
            // 设置API密钥
            if let Some(_) = handle_env_var("OPENROUTER_API_KEY", Some(&key)) {
                Ok(Json(ApiKeyResponse {
                    message: "API密钥已更新".to_string(),
                    api_key: Some(key),
                }))
            } else {
                Err((
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ErrorResponse {
                        error: "无法保存API密钥".to_string(),
                    }),
                ))
            }
        }
        None => {
            // 获取API密钥
            Ok(Json(ApiKeyResponse {
                message: "获取API密钥成功".to_string(),
                api_key: handle_env_var("OPENROUTER_API_KEY", None),
            }))
        }
    }
}

pub async fn get_api_key_handler() -> Result<Json<ApiKeyResponse>, (StatusCode, Json<ErrorResponse>)> {
    handle_api_key(None).await
}

pub async fn set_api_key_handler(
    Json(request): Json<ApiKeyRequest>,
) -> Result<Json<ApiKeyResponse>, (StatusCode, Json<ErrorResponse>)> {
    handle_api_key(Some(request.api_key)).await
}

// VIP激活码管理
pub async fn list_vip_codes_handler(
    State(pool): State<SqlitePool>,
    Extension(user_id): Extension<i64>,
) -> Result<Json<VipCodeListResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool.clone());
    
    // 验证是否是管理员
    let admin_username = env::var("ADMIN_USERNAME").unwrap_or_else(|_| "bde".to_string());
    let current_user = user_service.get_user_by_id(user_id).await.map_err(|e| (
        StatusCode::UNAUTHORIZED,
        Json(ErrorResponse {
            error: format!("认证失败: {}", e),
        }),
    ))?;

    if current_user.username != admin_username {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ErrorResponse {
                error: "只有管理员可以查看激活码列表".to_string(),
            }),
        ));
    }

    // 获取所有激活码
    tracing::info!("开始获取激活码列表");
    let codes = user_service.list_vip_codes().await.map_err(|e| {
        tracing::error!("获取激活码列表失败: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("获取激活码列表失败: {}", e),
            }),
        )
    })?;
    tracing::info!("成功获取到 {} 个激活码", codes.len());

    Ok(Json(VipCodeListResponse { codes }))
}

pub async fn generate_vip_code_handler(
    State(pool): State<SqlitePool>,
    Extension(user_id): Extension<i64>,
) -> Result<Json<GenerateVipCodeResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool.clone());
    
    // 验证是否是管理员
    let admin_username = env::var("ADMIN_USERNAME").unwrap_or_else(|_| "bde".to_string());
    let current_user = user_service.get_user_by_id(user_id).await.map_err(|e| (
        StatusCode::UNAUTHORIZED,
        Json(ErrorResponse {
            error: format!("认证失败: {}", e),
        }),
    ))?;

    if current_user.username != admin_username {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ErrorResponse {
                error: "只有管理员可以生成激活码".to_string(),
            }),
        ));
    }

    // 生成新的激活码
    tracing::info!("生成新的VIP激活码...");
    let response = user_service.generate_vip_code().await.map_err(|e| {
        tracing::error!("生成激活码失败: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("生成激活码失败: {}", e),
            }),
        )
    })?;

    tracing::info!("成功生成VIP激活码: {}", response.code);
    Ok(Json(response))
}

pub async fn update_vip_code_handler(
    State(pool): State<SqlitePool>,
    Extension(user_id): Extension<i64>,
    Path(code): Path<String>,
    Json(req): Json<UpdateVipCodeRequest>,
) -> Result<Json<VipActivationCode>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool.clone());
    
    // 验证是否是管理员
    let admin_username = env::var("ADMIN_USERNAME").unwrap_or_else(|_| "bde".to_string());
    let current_user = user_service.get_user_by_id(user_id).await.map_err(|e| (
        StatusCode::UNAUTHORIZED,
        Json(ErrorResponse {
            error: format!("认证失败: {}", e),
        }),
    ))?;

    if current_user.username != admin_username {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ErrorResponse {
                error: "只有管理员可以更新激活码".to_string(),
            }),
        ));
    }

    // 获取激活码ID
    let code_id = sqlx::query_scalar::<_, i64>(
        "SELECT id FROM vip_activation_codes WHERE code = ?"
    )
    .bind(&code)
    .fetch_one(&pool)
    .await
    .map_err(|e| (
        StatusCode::NOT_FOUND,
        Json(ErrorResponse {
            error: format!("激活码不存在: {}", e),
        }),
    ))?;

    // 更新激活码
    let updated_code = user_service.update_vip_code(code_id, req).await.map_err(|e| (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ErrorResponse {
            error: format!("更新激活码失败: {}", e),
        }),
    ))?;

    Ok(Json(updated_code))
}

pub async fn delete_vip_code_handler(
    State(pool): State<SqlitePool>,
    Extension(user_id): Extension<i64>,
    Path(code): Path<String>,
) -> Result<StatusCode, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool.clone());
    
    // 验证是否是管理员
    let admin_username = env::var("ADMIN_USERNAME").unwrap_or_else(|_| "bde".to_string());
    let current_user = user_service.get_user_by_id(user_id).await.map_err(|e| (
        StatusCode::UNAUTHORIZED,
        Json(ErrorResponse {
            error: format!("认证失败: {}", e),
        }),
    ))?;

    if current_user.username != admin_username {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ErrorResponse {
                error: "只有管理员可以删除激活码".to_string(),
            }),
        ));
    }

    // 删除激活码
    user_service.delete_vip_code(&code).await.map_err(|e| {
        if e.to_string().contains("不存在") {
            (
                StatusCode::NOT_FOUND,
                Json(ErrorResponse {
                    error: e.to_string(),
                }),
            )
        } else {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: format!("删除激活码失败: {}", e),
                }),
            )
        }
    })?;

    Ok(StatusCode::NO_CONTENT)
}

pub async fn update_admin_handler(
    State(pool): State<SqlitePool>,
    Extension(user_id): Extension<i64>,
    Json(req): Json<UpdateAdminRequest>,
) -> Result<Json<UpdateAdminResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_service = UserService::new(pool.clone());
    
    // 验证是否是管理员
    let admin_username = env::var("ADMIN_USERNAME").unwrap_or_else(|_| "bde".to_string());
    let current_user = user_service.get_user_by_id(user_id).await.map_err(|e| (
        StatusCode::UNAUTHORIZED,
        Json(ErrorResponse {
            error: format!("认证失败: {}", e),
        }),
    ))?;

    if current_user.username != admin_username {
        return Err((
            StatusCode::UNAUTHORIZED,
            Json(ErrorResponse {
                error: "只有管理员可以执行此操作".to_string(),
            }),
        ));
    }

    // 更新管理员信息
    if let Some(ref new_username) = req.new_username {
        // 检查新用户名是否已存在
        if let Ok(_) = user_service.get_user_by_username(new_username).await {
            return Err((
                StatusCode::BAD_REQUEST,
                Json(ErrorResponse {
                    error: "用户名已存在".to_string(),
                }),
            ));
        }
    }

    // 开始事务
    let mut transaction = pool.begin().await.map_err(|e| (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ErrorResponse {
            error: format!("数据库错误: {}", e),
        }),
    ))?;

    // 先更新环境变量
    if let Some(ref new_password) = req.new_password {
        if handle_env_var("ADMIN_PASSWORD", Some(new_password)).is_none() {
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "更新管理员密码环境变量失败".to_string(),
                }),
            ));
        }
    }

    if let Some(ref new_username) = req.new_username {
        if handle_env_var("ADMIN_USERNAME", Some(new_username)).is_none() {
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "更新管理员用户名环境变量失败".to_string(),
                }),
            ));
        }
    }

    // 然后更新数据库
    if let Some(new_password) = req.new_password {
        // 生成新的密码哈希
        let salt = argon2::password_hash::SaltString::generate(&mut rand::thread_rng());
        let argon2 = argon2::Argon2::default();
        let password_hash = argon2.hash_password(
            new_password.as_bytes(), 
            &salt
        ).map_err(|e| (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("密码哈希错误: {}", e),
            }),
        ))?.to_string();

        // 更新数据库中的密码
        sqlx::query!(
            "UPDATE users SET password_hash = ? WHERE username = ?",
            password_hash,
            admin_username
        )
        .execute(&mut *transaction)
        .await.map_err(|e| (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("更新密码失败: {}", e),
            }),
        ))?;
    }

    // 更新用户名
    if let Some(new_username) = req.new_username {
        // 更新数据库中的用户名
        sqlx::query!(
            "UPDATE users SET username = ? WHERE username = ?",
            new_username,
            admin_username
        )
        .execute(&mut *transaction)
        .await.map_err(|e| (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("更新用户名失败: {}", e),
            }),
        ))?;
    }

    // 提交事务
    transaction.commit().await.map_err(|e| (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ErrorResponse {
            error: format!("提交事务失败: {}", e),
        }),
    ))?;

    Ok(Json(UpdateAdminResponse {
        message: "管理员信息更新成功".to_string(),
    }))
}
