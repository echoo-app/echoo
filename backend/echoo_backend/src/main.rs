mod services;
mod models;

use tracing_subscriber;
use reqwest::Client;
use std::env;
use dotenv::dotenv;
use anyhow::Result;
use std::net::SocketAddr;
use sqlx::SqlitePool;

use crate::services::user_service::UserService;
use crate::models::user::CreateUserRequest;

async fn create_admin_user(pool: &SqlitePool) -> Result<()> {
    let user_service = UserService::new(pool.clone());
    
    // 检查管理员用户是否已存在
    let admin_username = env::var("ADMIN_USERNAME").unwrap_or_else(|_| "bde".to_string());
    let admin_password = env::var("ADMIN_PASSWORD").unwrap_or_else(|_| "bde123".to_string());

    // 先检查用户是否存在
    match user_service.get_user_by_username(&admin_username).await {
        Ok(_) => {
            tracing::info!("管理员用户已存在");
            return Ok(());
        }
        Err(_) => {
            // 用户确实不存在，创建管理员用户
            let create_user_req = CreateUserRequest {
                username: admin_username,
                password: admin_password,
                invite_code: None,  // 管理员用户不需要邀请码
            };

            match user_service.create_user(create_user_req).await {
                Ok(_) => {
                    tracing::info!("管理员用户已创建");
                    Ok(())
                }
                Err(e) => {
                    tracing::error!("创建管理员用户失败: {}", e);
                    Err(e)
                }
            }
        }
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    // 加载环境变量
    dotenv().ok();

    // 初始化日志
    tracing_subscriber::fmt::init();

    // 创建数据库连接池
    let pool = SqlitePool::connect(&env::var("DATABASE_URL")?).await?;

    // 创建管理员用户
    create_admin_user(&pool).await?;

    // 创建 HTTP 客户端
    let client = Client::new();

    // 使用新的路由创建函数
    let app = crate::services::routes::create_routes(pool, client);

    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    tracing::info!("服务器正在监听 {}", addr);

    axum::Server::bind(&addr)
        .serve(app.into_make_service_with_connect_info::<SocketAddr>())
        .await?;

    Ok(())
}
