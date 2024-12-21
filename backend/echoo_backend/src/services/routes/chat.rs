use axum::{
    response::Json,
    http::StatusCode,
    extract::{State, Extension},
    headers::{authorization::Bearer, Authorization},
    TypedHeader,
};
use reqwest::Client;
use serde::{Serialize, Deserialize};
use sqlx::SqlitePool;
use tracing::{info, error};
use uuid::Uuid;
use chrono::{Utc, TimeZone};
use crate::services::openrouter::{chat_with_openrouter, MessageContent};
use crate::services::user_service::UserService;
use crate::services::auth::{Claims, get_jwt_secret};
use crate::services::model_management_service::ModelManagementService;
use super::settings::handle_env_var;
use jsonwebtoken::{decode, DecodingKey, Validation};

use crate::services::openrouter::Message as OpenRouterMessage;

#[derive(Debug, Serialize, Deserialize)]
pub struct ClearHistoryRequest {
    pub user_id: i64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Message {
    pub content: String,
    pub model_id: Option<String>,
    pub prompt: Option<String>,
    pub history: Option<Vec<OpenRouterMessage>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ChatResponse {
    pub content: String,
    pub model_id: Option<String>,
    pub prompt: Option<String>,
    pub cost_calls: i32,
    pub actual_cost_calls: i32,
    pub remaining_calls: i32,
    pub prompt_tokens: i32,
    pub completion_tokens: i32,
    pub total_tokens: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub error: String,
}

pub async fn clear_history_handler(
    State(pool): State<SqlitePool>,
    Json(req): Json<ClearHistoryRequest>,
) -> Result<StatusCode, (StatusCode, Json<ErrorResponse>)> {
    info!("清理用户聊天历史记录，用户ID: {}", req.user_id);
    
    sqlx::query!(
        "DELETE FROM chat_history WHERE user_id = ?",
        req.user_id
    )
    .execute(&pool)
    .await
    .map_err(|e| {
        error!("清理历史记录失败: {:?}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "清理历史记录失败".to_string(),
            })
        )
    })?;

    Ok(StatusCode::NO_CONTENT)
}

pub async fn chat_handler(
    State(pool): State<SqlitePool>,
    Extension(client): Extension<Client>,
    TypedHeader(Authorization(bearer)): TypedHeader<Authorization<Bearer>>,
    Json(message): Json<Message>,
) -> Result<Json<ChatResponse>, (StatusCode, Json<ErrorResponse>)> {
    info!("开始处理聊天请求");

    let mut validation = Validation::default();
    validation.validate_exp = true;
    validation.leeway = 0;

    let jwt_secret = get_jwt_secret();
    let token_data = decode::<Claims>(
        bearer.token(),
        &DecodingKey::from_secret(&jwt_secret),
        &validation,
    ).map_err(|e| {
        error!("Token验证失败: {:?}", e);
        (
            StatusCode::UNAUTHORIZED,
            Json(ErrorResponse {
                error: format!("Invalid token: {}", e),
            }),
        )
    })?;

    let user_service = UserService::new(pool.clone());
    let current_user = user_service.get_user_by_id(token_data.claims.sub)
        .await
        .map_err(|e| {
            error!("获取用户信息失败: {:?}", e);
            (
                StatusCode::UNAUTHORIZED,
                Json(ErrorResponse {
                    error: "User not found".to_string(),
                }),
            )
        })?;

    let openrouter_api_key = handle_env_var("OPENROUTER_API_KEY", None).ok_or_else(|| {
        error!("未找到OpenRouter API密钥");
        (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: "未设置OpenRouter API密钥".to_string(),
            }),
        )
    })?;

    let model_service = ModelManagementService::new(pool.clone());
    let models = model_service.get_model_management().await.map_err(|e| {
        error!("获取模型列表失败: {:?}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "获取模型列表失败".to_string(),
            }),
        )
    })?;

    let model_id = if let Some(first_model) = models.first() {
        Some(first_model.name.clone())
    } else {
        error!("数据库中没有可用的模型");
        return Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "没有可用的模型".to_string(),
            }),
        ));
    };
    
    let final_prompt = match message.prompt {
        Some(user_prompt) if !user_prompt.is_empty() => {
            format!("{}\n\n在严格遵循上述规则的前提下：\n{}", crate::services::constants::BASE_PROMPT, user_prompt)
        },
        _ => crate::services::constants::BASE_PROMPT.to_string()
    };

    info!("调用OpenRouter API，模型ID: {:?}", model_id);

    if let Some(frontend_history) = message.history {
        for msg in frontend_history {
            let content_str = msg.content.to_string();
            sqlx::query!(
                "INSERT INTO chat_history (user_id, content, role, created_at) VALUES (?, ?, ?, datetime('now'))",
                current_user.id,
                content_str,
                msg.role
            )
            .execute(&pool)
            .await
            .map_err(|e| {
                error!("保存历史消息失败: {:?}", e);
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ErrorResponse {
                        error: "保存聊天历史失败".to_string(),
                    })
                )
            })?;
        }
    }

    // 分析当前消息，识别主题
    let current_topic = match chat_with_openrouter(
        &client,
        &openrouter_api_key,
        &format!(
            "请分析以下消息的主题，用一个简短的词语概括（不超过5个字）：\n{}",
            message.content
        ),
        None,
        None,
        vec![],
    ).await {
        Ok(topic_analysis) => topic_analysis.content.trim().to_string(),
        Err(err) => {
            error!("主题分析失败: {}", err);
            "聊天".to_string() // 使用默认主题
        }
    };
    
    // 获取或创建会话ID
    let session_id = if let Some(last_message) = sqlx::query!(
        r#"
        SELECT session_id, topic, created_at
        FROM chat_history 
        WHERE user_id = ? 
        ORDER BY id DESC 
        LIMIT 1
        "#,
        current_user.id
    )
    .fetch_optional(&pool)
    .await
    .map_err(|e| {
        error!("获取最后一条消息失败: {:?}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "获取会话ID失败".to_string(),
            })
        )
    })? {
        if let Some(sid) = last_message.session_id {
            // 如果最后一条消息的主题相似，且在15分钟内，使用相同的会话ID
            let last_time = last_message.created_at
                .map(|ts| {
                    let dt_utc = Utc.from_utc_datetime(&ts);
                    Utc::now().signed_duration_since(dt_utc).num_minutes()
                })
                .unwrap_or(16);
            
            if last_message.topic.unwrap_or_default() == current_topic && last_time <= 15 {
                sid
            } else {
                Uuid::new_v4().to_string()
            }
        } else {
            Uuid::new_v4().to_string()
        }
    } else {
        Uuid::new_v4().to_string()
    };

    // 获取相关的历史消息
    let history_messages = sqlx::query!(
        r#"
        WITH RECURSIVE conversation_chain AS (
            -- 获取当前会话的消息
            SELECT id, content, role, topic, importance, created_at
            FROM chat_history
            WHERE user_id = ? AND session_id = ?
            
            UNION ALL
            
            -- 获取相关主题的历史消息
            SELECT h.id, h.content, h.role, h.topic, h.importance, h.created_at
            FROM chat_history h
            WHERE h.user_id = ?
            AND h.topic = ?
            AND h.session_id != ?
            AND h.importance >= 2
            ORDER BY h.created_at DESC
            LIMIT 10
        )
        SELECT content, role, importance
        FROM conversation_chain
        ORDER BY created_at ASC
        "#,
        current_user.id,
        session_id,
        current_user.id,
        current_topic,
        session_id
    )
    .fetch_all(&pool)
    .await
    .map_err(|e| {
        error!("获取历史消息失败: {:?}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "获取历史消息失败".to_string(),
            })
        )
    })?;

    let mut history: Vec<OpenRouterMessage> = history_messages
        .into_iter()
        .map(|msg| OpenRouterMessage {
            role: msg.role,
            content: MessageContent::Text(msg.content),
        })
        .collect();

    history.push(OpenRouterMessage {
        role: "user".to_string(),
        content: MessageContent::Text(message.content.clone()),
    });

    const MAX_CHARS: usize = 30000;
    let total_chars: usize = history.iter().map(|msg| msg.content.len()).sum();
    
    if total_chars > MAX_CHARS {
        info!("历史消息超出字数限制，开始智能总结处理");
        
        // 保留最近的消息
        let mut summarized_history: Vec<OpenRouterMessage> = history
            .iter()
            .skip(history.len().saturating_sub(5))
            .cloned()
            .collect();
        
        // 对较早的消息进行分块总结
        let old_messages: Vec<_> = history
            .iter()
            .take(history.len().saturating_sub(5))
            .collect();
            
        for chunk in old_messages.chunks(5) {
            let summary_prompt = format!(
                "请分析并总结以下对话片段，保持关键信息和上下文的连贯性。
                重点关注：
                1. 对话的主题和目的
                2. 关键的问题和回答
                3. 重要的数字和事实信息
                4. 上下文相关的细节
                
                对话内容：\n{}",
                chunk.iter()
                    .map(|msg| format!("{}: {}", msg.role, msg.content))
                    .collect::<Vec<_>>()
                    .join("\n")
            );

            let summary_result = chat_with_openrouter(
                &client,
                &openrouter_api_key,
                &summary_prompt,
                None,
                None,
                vec![],
            ).await.map_err(|err| {
                error!("总结历史消息失败: {}", err);
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ErrorResponse {
                        error: format!("总结历史消息失败: {}", err),
                    }),
                )
            })?;

            summarized_history.push(OpenRouterMessage {
                role: "system".to_string(),
                content: MessageContent::Text(summary_result.content),
            });
        }

        history = summarized_history;
        info!("历史消息总结完成，当前字数：{}", 
            history.iter().map(|msg| msg.content.len()).sum::<usize>());
    }
    
    let chat_result = chat_with_openrouter(
        &client, 
        &openrouter_api_key, 
        &message.content, 
        model_id.clone(), 
        Some(final_prompt.clone()),
        history,
    ).await.map_err(|err| {
        error!("聊天请求失败: {}", err);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("聊天请求失败: {}", err),
            }),
        )
    })?;

    info!("OpenRouter API调用成功");
    
    let base_cost_calls = 1;
    let actual_cost_calls = 1;
    
    info!("用户剩余调用次数: {}, 需要扣除: {}", current_user.api_calls, actual_cost_calls);

    if current_user.api_calls < 1 || current_user.api_calls < actual_cost_calls {
        error!("调用次数不足");
        return Err((
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: "调用次数不足，请充值后继续使用".to_string(),
            }),
        ));
    }

    let new_api_calls = current_user.api_calls - actual_cost_calls;
    info!("更新用户调用次数，剩余次数: {}", new_api_calls);

    let updated_user = user_service.update_user_api_calls(current_user.id, new_api_calls).await.map_err(|err| {
        error!("更新用户调用次数失败: {}", err);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("更新用户调用次数失败: {}", err),
            }),
        )
    })?;

    info!("用户余额更新成功");

    sqlx::query!(
        "INSERT INTO chat_history (user_id, content, role, created_at, session_id, topic, importance) VALUES (?, ?, ?, datetime('now'), ?, ?, ?)",
        current_user.id,
        message.content,
        "user",
        session_id,
        current_topic,
        1  // 默认重要性为1
    )
    .execute(&pool)
    .await
    .map_err(|e| {
        error!("保存用户消息失败: {:?}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "保存聊天历史失败".to_string(),
            })
        )
    })?;

    // 计算回复的重要性
    let importance = if chat_result.content.len() > 100 { 2 } else { 1 };

    sqlx::query!(
        "INSERT INTO chat_history (user_id, content, role, created_at, session_id, topic, importance) VALUES (?, ?, ?, datetime('now'), ?, ?, ?)",
        current_user.id,
        chat_result.content,
        "assistant",
        session_id,
        current_topic,
        importance
    )
    .execute(&pool)
    .await
    .map_err(|e| {
        error!("保存助手回复失败: {:?}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "保存聊天历史失败".to_string(),
            })
        )
    })?;

    Ok(Json(ChatResponse { 
        content: chat_result.content,
        model_id,
        prompt: Some(final_prompt.clone()),
        cost_calls: base_cost_calls,
        actual_cost_calls,
        remaining_calls: updated_user.api_calls,
        prompt_tokens: chat_result.usage.prompt_tokens,
        completion_tokens: chat_result.usage.completion_tokens,
        total_tokens: chat_result.usage.total_tokens,
    }))
}
