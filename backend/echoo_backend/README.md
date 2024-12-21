# Echoo 后端服务

## 技术栈
- Rust
- Axum Web 框架
- Tokio 异步运行时

## 运行项目

### 开发模式
```bash
cargo run
```

### 构建
```bash
cargo build --release
```

### 端点
- GET `/health`: 健康检查
- POST `/chat`: 聊天接口（目前为回显消息）

## 依赖
- Rust 1.75 或更高版本
- Cargo
