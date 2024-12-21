# Echoo - Cross-platform Ollama Client

> A secure, privacy-focused Ollama client built with Flutter. Runs seamlessly on iOS, Android, Windows, and macOS. All data stays local - no accounts, no tracking, just pure AI interaction with your Ollama models. Ideal for anyone who wants to use AI while keeping their data private.

> 基于Flutter开发的安全、注重隐私的Ollama客户端，支持iOS、Android、Windows和macOS。所有数据本地存储，无需账号，不进行追踪。为重视数据隐私且想要使用AI的用户提供理想选择。

## ⬇️ Download
[![Android APK](https://img.shields.io/badge/Download-Android%20APK-brightgreen?style=for-the-badge&logo=android)](https://github.com/echoo-app/echoo/releases/latest/download/app-release.apk)

Echoo is a stateless Ollama client built with Flutter, enabling secure access to Ollama on iOS, Android, Windows, and macOS. With a strong focus on privacy, it requires no user identification and performs no data analytics or user tracking. Chat history is encrypted locally, no registration required, and no user data collection. As a pure Ollama client, it provides secure and convenient access to all Ollama-supported models on any device.

[中文文档](#echoo---跨平台ollama客户端)

## Key Features

- 🔒 Privacy-Focused
  - No user identification required
  - No data analytics or tracking
  - Locally encrypted chat history
  
- 💻 Cross-Platform Support
  - iOS & Android mobile apps
  - Windows & macOS desktop apps
  
- 🤖 Complete Ollama Integration
  - Support for all Ollama models
  - Smart context management
  - Automatic long conversation summarization

- ⚡ Efficient Features
  - No registration needed
  - Clean user interface
  - Fast local deployment

## System Requirements

- iOS 11.0 or later
- Android 5.0 (API 21) or later
- Windows 10 or later
- macOS 10.14 or later
- Ollama service installed and running

## Getting Started

1. Ensure Ollama service is installed and running on your system
2. Download and install the Echoo client for your platform
3. Launch the app and connect to your local Ollama service
4. Start chatting with your preferred AI models

## App Store Deployment

### Android Deployment
1. 在Android Studio中打开项目
2. 更新 `android/app/build.gradle` 中的版本号
3. 生成签名密钥：
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
4. 配置签名信息到 `android/key.properties`
5. 构建发布版本：
   ```bash
   flutter build appbundle
   ```
6. 生成的 AAB 文件位于 `build/app/outputs/bundle/release/app-release.aab`
7. 在 Google Play Console 上传 AAB 文件

### iOS Deployment
1. 在Xcode中打开 `ios/Runner.xcworkspace`
2. 更新版本号和构建号
3. 配置开发者账号和证书：
   - 在Xcode中选择合适的Team
   - 确保Provisioning Profile正确配置
4. 构建发布版本：
   ```bash
   flutter build ipa
   ```
5. 生成的IPA文件位于 `build/ios/ipa`
6. 使用App Store Connect上传IPA文件：
   ```bash
   xcrun altool --upload-app --file build/ios/ipa/Echoo.ipa --type ios
   ```

## Privacy Commitment

Echoo is committed to protecting user privacy:
- No user data collection
- No registration required
- All data stored locally
- Fully open source

## License

MIT License

---

# Echoo - 跨平台Ollama客户端

Echoo是一个基于Flutter开发的无状态Ollama客户端，让您在iOS、Android、Windows和macOS上都能安全地使用Ollama。注重隐私保护，完全无需用户标识，不进行任何数据分析和用户追踪。聊天记录采用本地加密存储，无需注册账号，不收集任何用户数据。作为一个纯粹的Ollama客户端，让您在任何设备上都能既安全又便捷地使用Ollama支持的所有模型。

[English Version](#echoo---cross-platform-ollama-client)

## ⬇️ 下载
[![Android APK](https://img.shields.io/badge/下载-Android%20APK-brightgreen?style=for-the-badge&logo=android)](https://github.com/echoo-app/echoo/releases/latest/download/app-release.apk)

## 主要特点

- 🔒 注重隐私保护
  - 完全无需用户标识
  - 不进行任何数据分析和用户追踪
  - 聊天记录采用本地加密存储
  
- 💻 跨平台支持
  - iOS & Android移动应用
  - Windows & macOS桌面应用
  
- 🤖 完整的Ollama集成
  - 支持所有Ollama模型
  - 智能上下文管理
  - 自动长对话总结

- ⚡ 高效特性
  - 无需注册账号
  - 简洁的用户界面
  - 快速响应的本地部署

## 系统要求

- iOS 11.0 或更高版本
- Android 5.0 (API 21) 或更高版本
- Windows 10 或更高版本
- macOS 10.14 或更高版本
- 已安装并运行的Ollama服务

## 开始使用

1. 确保您的系统已安装并运行Ollama服务
2. 下载并安装适合您平台的Echoo客户端
3. 启动应用并连接到本地Ollama服务
4. 开始与您喜欢的AI模型对话

## 应用商店部署

### Android部署
1. 在Android Studio中打开项目
2. 更新 `android/app/build.gradle` 中的版本号
3. 生成签名密钥：
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
4. 配置签名信息到 `android/key.properties`
5. 构建发布版本：
   ```bash
   flutter build appbundle
   ```
6. 生成的AAB文件位于 `build/app/outputs/bundle/release/app-release.aab`
7. 在Google Play Console上传AAB文件

### iOS部署
1. 在Xcode中打开 `ios/Runner.xcworkspace`
2. 更新版本号和构建号
3. 配置开发者账号和证书：
   - 在Xcode中选择合适的Team
   - 确保Provisioning Profile正确配置
4. 构建发布版本：
   ```bash
   flutter build ipa
   ```
5. 生成的IPA文件位于 `build/ios/ipa`
6. 使用App Store Connect上传IPA文件：
   ```bash
   xcrun altool --upload-app --file build/ios/ipa/Echoo.ipa --type ios
   ```

## 隐私承诺

Echoo致力于保护用户隐私，我们：
- 不收集任何用户数据
- 不需要注册账号
- 所有数据都存储在本地
- 完全开源透明

## 开源协议

MIT License
