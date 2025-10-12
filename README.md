# Passkey Demo - 无密码登录演示

这是一个完整的 Passkey 无密码登录演示系统，包含 Web 前端、Node.js 后端和 iOS 原生应用。

## 🚀 功能特性

- **Web 前端**: 支持在 iOS Safari 中使用 Face ID/Touch ID 进行 Passkey 注册和登录
- **iOS 原生应用**: 通过 ASWebAuthenticationSession 集成 Web 认证流程
- **Node.js 后端**: 完整的 WebAuthn 服务器实现，支持注册、认证和令牌管理
- **OAuth 2.0 流程**: 使用授权码换取访问令牌的标准流程

## 📁 项目结构

```
passkey-demo/
├── web/                    # Web 前端
│   └── index.html          # 主页面，支持 Passkey 注册和登录
├── server/                 # Node.js 后端
│   ├── index.js            # 服务器主文件
│   └── package.json        # 依赖配置
└── ios/                    # iOS 原生应用
    ├── ViewController.swift # 主视图控制器
    ├── AuthManager.swift   # 认证管理器
    ├── AppDelegate.swift   # 应用委托
    ├── SceneDelegate.swift # 场景委托
    ├── Info.plist         # 应用配置
    ├── Main.storyboard    # 主界面
    └── PasskeyDemo.xcodeproj/ # Xcode 项目文件
```

## 🛠️ 安装和运行

### 1. 启动后端服务器

```bash
cd server
npm install
npm start
```

服务器将在 `http://localhost:3001` 启动。

### 2. 访问 Web 前端

打开浏览器访问 `http://localhost:3001/index.html`

### 3. 运行 iOS 应用

1. 使用 Xcode 打开 `ios/PasskeyDemo.xcodeproj`
2. 选择目标设备或模拟器
3. 点击运行按钮

## 🔐 使用流程

### Web 端演示

1. 在 iOS Safari 中打开 `http://localhost:3001/index.html`
2. 输入用户名（默认：demo_user）
3. 点击"注册 Passkey"按钮
4. 使用 Face ID/Touch ID 完成注册
5. 点击"登录"按钮进行认证
6. 使用 Face ID/Touch ID 完成登录

### iOS 应用演示

1. 打开 iOS 应用
2. 输入用户名
3. 点击"开始 Passkey 登录"
4. 系统会打开 Safari 进行 Web 认证
5. 在 Safari 中完成 Passkey 认证
6. 自动返回应用并显示登录结果

## 🔧 技术实现

### WebAuthn 流程

1. **注册流程**:
   - 客户端请求注册选项
   - 服务器生成 challenge 和用户信息
   - 客户端调用 WebAuthn API 创建凭证
   - 服务器验证并保存凭证

2. **认证流程**:
   - 客户端请求认证选项
   - 服务器生成 challenge
   - 客户端调用 WebAuthn API 进行认证
   - 服务器验证认证响应并颁发授权码

### iOS 集成

- 使用 `ASWebAuthenticationSession` 打开 Web 认证页面
- 通过 URL Scheme (`passkeydemo://`) 处理回调
- 实现 OAuth 2.0 授权码流程

### 安全特性

- 防重放攻击（state 参数验证）
- 凭证验证和计数器检查
- JWT 令牌管理
- 安全的密钥存储

## 📱 系统要求

- **iOS**: 17.0+ (支持 ASWebAuthenticationSession)
- **浏览器**: 支持 WebAuthn 的现代浏览器
- **Node.js**: 18.0+
- **开发环境**: Xcode 15.0+

## 🔍 调试和测试

### 后端日志

服务器会输出详细的认证日志，包括：
- 注册和认证请求
- WebAuthn 验证结果
- 令牌交换过程

### 前端调试

- 打开浏览器开发者工具查看网络请求
- 检查 WebAuthn API 调用结果
- 查看本地存储的令牌信息

### iOS 调试

- 查看 Xcode 控制台输出
- 检查 ASWebAuthenticationSession 状态
- 验证 URL Scheme 回调

## 🚨 注意事项

1. **HTTPS 要求**: 生产环境必须使用 HTTPS
2. **域名配置**: 需要配置正确的 rpID 和 origin
3. **证书管理**: 生产环境需要有效的 SSL 证书
4. **密钥安全**: 生产环境请更换 JWT 密钥

## 📚 相关资源

- [WebAuthn 规范](https://www.w3.org/TR/webauthn-2/)
- [SimpleWebAuthn 文档](https://simplewebauthn.dev/)
- [iOS ASWebAuthenticationSession 文档](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个演示项目。

## 📄 许可证

MIT License
