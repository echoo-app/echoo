use reqwest::Client;
use serde::{Deserialize, Serialize};
use anyhow::{Result, Context};
use std::str::FromStr;

mod config {
    pub const API_BASE: &str = "https://openrouter.ai/api/v1";
    pub const SITE_URL: &str = "https://echoo.app";
    pub const SITE_NAME: &str = "Echoo";
    pub const DEFAULT_MODEL: &str = "openai/gpt-3.5-turbo";
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Usage {
    pub prompt_tokens: i32,
    pub completion_tokens: i32,
    pub total_tokens: i32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OpenRouterModel {
    pub id: String,
    pub name: String,
    pub description: String,
    pub pricing: OpenRouterModelPricing,
    pub context_length: i32,
    pub architecture: OpenRouterModelArchitecture,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OpenRouterModelPricing {
    pub prompt: String,
    pub completion: String,
    #[serde(rename = "image")]
    pub image_price: Option<String>,
    pub request: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OpenRouterModelArchitecture {
    pub modality: String,
    pub tokenizer: String,
    #[serde(rename = "instruct_type")]
    pub instruct_type: Option<String>,
}

#[derive(Debug)]
pub struct ChatResult {
    pub content: String,
    #[allow(dead_code)]
    pub cost: f64,
    pub usage: Usage,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(untagged)]
pub enum MessageContent {
    Text(String),
    Array(Vec<serde_json::Value>)
}

impl MessageContent {
    pub fn to_string(&self) -> String {
        match self {
            MessageContent::Text(text) => text.clone(),
            MessageContent::Array(array) => serde_json::to_string(array).unwrap_or_default(),
        }
    }

    pub fn len(&self) -> usize {
        match self {
            MessageContent::Text(text) => text.len(),
            MessageContent::Array(array) => serde_json::to_string(array).unwrap_or_default().len(),
        }
    }
}

impl std::fmt::Display for MessageContent {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.to_string())
    }
}

impl From<String> for MessageContent {
    fn from(text: String) -> Self {
        MessageContent::Text(text)
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Message {
    pub role: String,
    pub content: MessageContent,
}

struct OpenRouterClient {
    client: Client,
    api_key: String,
}

impl OpenRouterClient {
    fn new(client: Client, api_key: String) -> Self {
        Self { client, api_key }
    }

    fn build_headers(&self) -> reqwest::header::HeaderMap {
        let mut headers = reqwest::header::HeaderMap::new();
        headers.insert(
            "Authorization",
            format!("Bearer {}", self.api_key).parse().unwrap()
        );
        headers.insert(
            "HTTP-Referer",
            config::SITE_URL.parse().unwrap()
        );
        headers.insert(
            "X-Title",
            config::SITE_NAME.parse().unwrap()
        );
        headers.insert(
            "Content-Type",
            "application/json".parse().unwrap()
        );
        headers
    }

    async fn make_request<T: Serialize, R: for<'de> Deserialize<'de>>(
        &self,
        endpoint: &str,
        method: reqwest::Method,
        body: Option<&T>,
    ) -> Result<R> {
        let url = format!("{}{}", config::API_BASE, endpoint);
        let mut builder = self.client.request(method, &url);
        builder = builder.headers(self.build_headers());
        
        if let Some(body) = body {
            builder = builder.json(body);
        }

        let response = builder.send().await?;
        let status = response.status();

        if !status.is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!("API error: {} - {}", status, error_text));
        }

        response.json::<R>().await.context("Failed to parse response")
    }
}

pub async fn chat_with_openrouter(
    client: &Client, 
    api_key: &str, 
    message: &str,
    model_id: Option<String>,
    prompt: Option<String>,
    history: Vec<Message>
) -> Result<ChatResult> {
    let api_client = OpenRouterClient::new(client.clone(), api_key.to_string());
    let model = model_id.unwrap_or_else(|| config::DEFAULT_MODEL.to_string());
    
    let mut messages = Vec::new();
    
    // 添加系统提示词
    if let Some(prompt_text) = prompt {
        println!("系统提示词: {}", prompt_text);
        messages.push(Message {
            role: "system".to_string(),
            content: MessageContent::Text(prompt_text),
        });
    }
    
    // 添加历史消息
    messages.extend(history);
    
    // 处理当前消息
    // 处理当前消息
    let content = if message.starts_with("data:image/") {
        // 确保base64格式正确
        if !message.contains(",") {
            return Err(anyhow::anyhow!("Invalid base64 image format"));
        }
        
        // 检查图片格式
        let format = message
            .split(";")
            .next()
            .and_then(|s| s.strip_prefix("data:image/"))
            .ok_or_else(|| anyhow::anyhow!("Invalid image format"))?;
            
        // 验证支持的文件格式
        let supported_formats = [
            // 图片格式
            "jpeg", "jpg", "png", "gif", "webp", "heic", "heif",
            // 文档格式
            "pdf",
            // 视频格式 (部分模型支持)
            "mp4", "webm", "mov",
            // 音频格式 (部分模型支持)
            "mp3", "wav", "ogg", "m4a",
        ];
        
        if !supported_formats.contains(&format) {
            return Err(anyhow::anyhow!("不支持的文件格式: {}。支持的格式有: {}", 
                format, 
                supported_formats.join(", ")
            ));
        }
        
        MessageContent::Array(vec![serde_json::json!({
            "type": "image_url",
            "image_url": {
                "url": message.trim(),
                "detail": "auto"  // OpenRouter 支持的图片细节级别
            }
        })])
    } else if let Ok(value) = serde_json::from_str::<serde_json::Value>(message) {
        if let Some(array) = value.as_array() {
            MessageContent::Text(
                array.iter()
                    .find(|item| item["type"] == "text")
                    .and_then(|item| item["text"].as_str())
                    .unwrap_or(message)
                    .to_string()
            )
        } else {
            MessageContent::Text(message.to_string())
        }
    } else {
        MessageContent::Text(message.to_string())
    };

    // 添加当前用户消息
    messages.push(Message {
        role: "user".to_string(),
        content,
    });

    let request_body = serde_json::json!({
        "model": model,
        "messages": messages,
    });
    println!("发送到OpenRouter的消息: {}", serde_json::to_string_pretty(&request_body).unwrap());

    #[derive(Deserialize)]
    struct ChatResponse {
        choices: Vec<ChatChoice>,
        usage: Usage,
    }

    #[derive(Deserialize)]
    struct ChatChoice {
        message: ChatResponseMessage,
    }

    #[derive(Deserialize)]
    struct ChatResponseMessage {
        content: String,
    }

    let chat_response: ChatResponse = api_client
        .make_request("/chat/completions", reqwest::Method::POST, Some(&request_body))
        .await?;

    // 获取模型价格信息并计算成本
    let models = get_openrouter_models(client, api_key).await?;
    let model_info = models.iter()
        .find(|m| m.id == model)
        .context("找不到模型价格信息")?;

    let cost = calculate_cost(
        &model_info.pricing,
        chat_response.usage.prompt_tokens,
        chat_response.usage.completion_tokens,
    )?;

    Ok(ChatResult {
        content: chat_response.choices.first()
            .map(|choice| choice.message.content.clone())
            .unwrap_or_else(|| "无法获取响应".to_string()),
        cost,
        usage: chat_response.usage,
    })
}

fn calculate_cost(
    pricing: &OpenRouterModelPricing,
    prompt_tokens: i32,
    completion_tokens: i32,
) -> Result<f64> {
    let prompt_price = f64::from_str(pricing.prompt.trim_start_matches('$'))
        .context("无法解析提示词价格")?;
    let completion_price = f64::from_str(pricing.completion.trim_start_matches('$'))
        .context("无法解析补全价格")?;
    
    Ok((prompt_price * prompt_tokens as f64 / 1000.0) +
       (completion_price * completion_tokens as f64 / 1000.0))
}

pub async fn get_openrouter_models(
    client: &Client, 
    api_key: &str
) -> Result<Vec<OpenRouterModel>> {
    let api_client = OpenRouterClient::new(client.clone(), api_key.to_string());
    
    #[derive(Deserialize)]
    struct ModelsResponse {
        data: Vec<OpenRouterModel>,
    }

    let response: ModelsResponse = api_client
        .make_request("/models", reqwest::Method::GET, None::<&()>)
        .await?;

    Ok(response.data)
}
