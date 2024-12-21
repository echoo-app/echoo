use axum::{
    http::{Request, StatusCode},
    middleware::Next,
    response::Response,
    extract::State,
};
use jsonwebtoken::{decode, DecodingKey, Validation, Algorithm};
use crate::services::auth::Claims;
use crate::services::user_service::UserService;

pub async fn auth<B>(
    State(pool): State<sqlx::SqlitePool>,
    mut request: Request<B>,
    next: Next<B>,
) -> Result<Response, StatusCode> {
    let auth_header = request
        .headers()
        .get("Authorization")
        .and_then(|value| value.to_str().ok())
        .and_then(|value| value.strip_prefix("Bearer "));

    let token = match auth_header {
        Some(token) => token,
        None => return Err(StatusCode::UNAUTHORIZED),
    };

    let jwt_secret = crate::services::auth::get_jwt_secret();

    let token_data = match decode::<Claims>(
        token,
        &DecodingKey::from_secret(&jwt_secret),
        &Validation::new(Algorithm::HS256),
    ) {
        Ok(data) => data,
        Err(_) => return Err(StatusCode::UNAUTHORIZED),
    };

    // 检查用户是否存在
    let user_service = UserService::new(pool);
    match user_service.get_user_by_id(token_data.claims.sub).await {
        Ok(_) => {
            // 用户存在，将用户ID添加到请求扩展中
            request.extensions_mut().insert(token_data.claims.sub);
            Ok(next.run(request).await)
        },
        Err(_) => {
            // 用户不存在，返回401
            Err(StatusCode::UNAUTHORIZED)
        }
    }
}
