mod health;
mod user;
mod chat;
mod model;
mod settings;

use axum::{
    Router, 
    routing::{get, post, delete, patch},
    Extension,
    extract::FromRef,
    middleware,
};
use sqlx::SqlitePool;
use reqwest::Client;

mod routes {
    pub mod api {
        pub const HEALTH: &str = "/health";
        
        pub mod auth {
            pub const REGISTER: &str = "/api/register";
            pub const LOGIN: &str = "/api/login";
            pub const CHECK_ADMIN: &str = "/api/check-admin";
            pub const CHECK_AUTH: &str = "/api/check-auth";
        }
        
        pub mod users {
            pub const LIST: &str = "/api/users";
            pub const GET_BY_USERNAME: &str = "/api/user/:username";
            pub const UPDATE_API_CALLS: &str = "/api/users/:user_id/api-calls";
            pub const DELETE: &str = "/api/users/:user_id";
            pub const GENERATE_VIP_CODE: &str = "/api/users/vip/generate";
            pub const ACTIVATE_VIP: &str = "/api/users/vip/activate";
            pub const VIP_PAYMENT_URL: &str = "/api/vip/payment-url";
        }
        
        pub mod chat {
            pub const CHAT: &str = "/api/chat";
            pub const CLEAR_HISTORY: &str = "/api/chat/clear";
        }
        
        pub mod models {
            pub const LIST: &str = "/api/models";
            pub const SAVED: &str = "/api/settings/saved-models";
        }
        
        pub mod settings {
            pub const API_KEY: &str = "/api/settings/openrouter-key";
            pub const ADMIN: &str = "/api/settings/admin";
            pub const VIP_CODES: &str = "/api/settings/vip-codes";
            pub const VIP_CODE: &str = "/api/settings/vip-codes/:code";
        }
    }
}

#[derive(Clone)]
pub struct AppState {
    pub pool: SqlitePool,
}

impl FromRef<AppState> for SqlitePool {
    fn from_ref(state: &AppState) -> Self {
        state.pool.clone()
    }
}

fn create_public_routes() -> Router<AppState> {
    Router::new()
        .route(routes::api::HEALTH, get(health::health_check))
        // 认证路由
        .route(routes::api::auth::REGISTER, post(user::register_handler))
        .route(routes::api::auth::LOGIN, post(user::login_handler))
        // 用户信息
        .route(routes::api::users::GET_BY_USERNAME, get(user::get_user_info_handler))
}

fn create_protected_routes() -> Router<AppState> {
    Router::new()
        // 认证检查
        .route(routes::api::auth::CHECK_AUTH, get(user::check_auth_handler))
        .route(routes::api::auth::CHECK_ADMIN, get(user::check_admin_handler))
        // 模型管理
        .route(routes::api::models::LIST, get(model::models_handler))
        .route(routes::api::models::SAVED, get(model::get_saved_models_handler))
        .route(routes::api::models::SAVED, post(model::set_saved_models_handler))
        // 用户管理
        .route(routes::api::users::LIST, get(user::get_users_handler))
        .route(routes::api::users::UPDATE_API_CALLS, post(user::update_api_calls_handler))
        .route(routes::api::users::DELETE, delete(user::delete_user_handler))
        .route(routes::api::users::GENERATE_VIP_CODE, post(user::generate_vip_code_handler))
        .route(routes::api::users::ACTIVATE_VIP, post(user::activate_vip_handler))
        .route(routes::api::users::VIP_PAYMENT_URL, get(user::get_vip_payment_url_handler))
        // 聊天
        .route(routes::api::chat::CHAT, post(chat::chat_handler))
        .route(routes::api::chat::CLEAR_HISTORY, post(chat::clear_history_handler))
        // 设置
        .route(routes::api::settings::API_KEY, get(settings::get_api_key_handler))
        .route(routes::api::settings::API_KEY, post(settings::set_api_key_handler))
        .route(routes::api::settings::ADMIN, post(settings::update_admin_handler))
        .route(routes::api::settings::VIP_CODES, get(settings::list_vip_codes_handler))
        .route(routes::api::settings::VIP_CODES, post(settings::generate_vip_code_handler))
        .route(routes::api::settings::VIP_CODE, patch(settings::update_vip_code_handler))
        .route(routes::api::settings::VIP_CODE, delete(settings::delete_vip_code_handler))
}

pub fn create_routes(pool: SqlitePool, client: Client) -> Router {
    // 确保加载环境变量
    settings::handle_env_var("OPENROUTER_API_KEY", None);

    let state = AppState { pool };
    
    Router::new()
        .merge(create_public_routes())
        .merge(
            create_protected_routes()
                .layer(middleware::from_fn_with_state(
                    state.clone(),
                    crate::services::middleware::auth,
                ))
                .layer(Extension(client.clone()))
        )
        .layer(Extension(client))
        .with_state(state)
}
