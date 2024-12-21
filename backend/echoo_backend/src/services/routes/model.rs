use axum::{
    response::Json,
    extract::State,
    http::StatusCode,
};
use sqlx::SqlitePool;
use reqwest::Client;
use serde::{Serialize, Deserialize};

use crate::services::model_management_service::{ModelManagementService, ModelManagement};
use crate::services::openrouter::{get_openrouter_models, OpenRouterModel};
use super::settings::handle_env_var;

#[derive(Debug, Serialize, Deserialize)]
pub struct SavedModelRequest {
    pub model_ids: Vec<String>,
    pub models: Vec<OpenRouterModel>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SavedModelResponse {
    pub message: String,
    pub model_ids: Option<Vec<String>>,
    pub models: Option<Vec<ModelManagement>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub error: String,
}

pub async fn get_saved_models_handler(
    State(pool): State<SqlitePool>
) -> Result<Json<SavedModelResponse>, (StatusCode, Json<ErrorResponse>)> {
    let model_service = ModelManagementService::new(pool);
    
    match model_service.get_model_management().await {
        Ok(models) => {
            let model_ids = models.iter().map(|m| m.name.clone()).collect();
            Ok(Json(SavedModelResponse {
                message: "获取保存的模型成功".to_string(),
                model_ids: Some(model_ids),
                models: Some(models),
            }))
        }
        Err(err) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("获取保存的模型失败: {}", err),
            }),
        )),
    }
}

pub async fn set_saved_models_handler(
    State(pool): State<SqlitePool>,
    Json(request): Json<SavedModelRequest>,
) -> Result<Json<SavedModelResponse>, (StatusCode, Json<ErrorResponse>)> {
    tracing::info!("收到保存模型请求: model_ids={:?}", request.model_ids);

    // 确保只选择了一个模型
    if request.model_ids.len() > 1 {
        tracing::error!("尝试保存多个模型: {:?}", request.model_ids);
        return Err((
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: "只能选择一个模型".to_string(),
            }),
        ));
    }

    let model_service = ModelManagementService::new(pool);
    let mut saved_models = Vec::new();

    // 先删除所有现有的模型
    tracing::info!("删除所有现有模型");
    if let Err(err) = model_service.delete_all_models().await {
        tracing::error!("删除现有模型失败: {}", err);
        return Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("删除现有模型失败: {}", err),
            }),
        ));
    }

    // 如果有选择的模型，则保存它
    if let Some(model_id) = request.model_ids.first() {
        tracing::info!("尝试保存模型: {}", model_id);
        if let Some(model) = request.models.iter().find(|m| &m.id == model_id) {
            tracing::info!("找到模型信息: name={}, description={:?}", model.id, model.description);
            let model_management = ModelManagement {
                id: None,
                name: model.id.clone(),
                description: Some(model.description.clone()),
                prompt_price: Some(model.pricing.prompt.clone()),
                completion_price: Some(model.pricing.completion.clone()),
                image_price: model.pricing.image_price.clone(),
            };

            match model_service.update_model_management(&model_management).await {
                Ok(saved_model) => {
                    tracing::info!("模型保存成功: {:?}", saved_model);
                    saved_models.push(saved_model)
                },
                Err(err) => {
                    tracing::error!("保存模型失败: {}", err);
                    return Err((
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(ErrorResponse {
                            error: format!("保存模型失败: {}", err),
                        }),
                    ));
                }
            }
        }
    }

    Ok(Json(SavedModelResponse {
        message: "模型已更新".to_string(),
        model_ids: Some(request.model_ids),
        models: Some(saved_models),
    }))
}

pub async fn models_handler(
    axum::Extension(client): axum::Extension<Client>,
) -> Result<Json<Vec<OpenRouterModel>>, (StatusCode, Json<ErrorResponse>)> {
    let openrouter_api_key = handle_env_var("OPENROUTER_API_KEY", None);
    if openrouter_api_key.is_none() {
        return Ok(Json(vec![]));
    }

    match get_openrouter_models(&client, &openrouter_api_key.unwrap()).await {
        Ok(models) => Ok(Json(models)),
        Err(err) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: format!("获取模型列表失败: {}", err),
            }),
        )),
    }
}
