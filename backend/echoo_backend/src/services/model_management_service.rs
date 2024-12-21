use sqlx::SqlitePool;

#[derive(Debug, serde::Serialize, serde::Deserialize, Clone)]
pub struct ModelManagement {
    pub id: Option<i64>,
    pub name: String,
    pub description: Option<String>,
    pub prompt_price: Option<String>,
    pub completion_price: Option<String>,
    pub image_price: Option<String>,
}

pub struct ModelManagementService {
    pool: SqlitePool,
}

impl ModelManagementService {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }

    pub async fn get_model_management(&self) -> Result<Vec<ModelManagement>, sqlx::Error> {
        let models = sqlx::query_as!(
            ModelManagement,
            r#"
            SELECT id, name, description, prompt_price, completion_price, image_price
            FROM model_management
            ORDER BY name
            "#
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(models)
    }

    pub async fn update_model_management(&self, model: &ModelManagement) -> Result<ModelManagement, sqlx::Error> {
        // 使用COALESCE保留现有值（如果新值为NULL）
        let updated_model = sqlx::query_as!(
            ModelManagement,
            r#"
            INSERT INTO model_management (name, description, prompt_price, completion_price, image_price)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(name) DO UPDATE SET
            description = COALESCE(excluded.description, model_management.description),
            prompt_price = COALESCE(excluded.prompt_price, model_management.prompt_price),
            completion_price = COALESCE(excluded.completion_price, model_management.completion_price),
            image_price = COALESCE(excluded.image_price, model_management.image_price)
            RETURNING id, name, description, prompt_price, completion_price, image_price
            "#,
            model.name,
            model.description,
            model.prompt_price,
            model.completion_price,
            model.image_price
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(updated_model)
    }

    pub async fn delete_all_models(&self) -> Result<(), sqlx::Error> {
        sqlx::query!(
            r#"
            DELETE FROM model_management
            "#
        )
        .execute(&self.pool)
        .await?;

        Ok(())
    }
}
