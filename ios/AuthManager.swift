import Foundation
import AuthenticationServices
import UIKit

/// Passkey 认证管理器
/// 使用 ASWebAuthenticationSession 打开认证页面，完成 Passkey 登录流程
final class AuthManager: NSObject {
    static let shared = AuthManager()
    private override init() {}

    private var session: ASWebAuthenticationSession?
    private var pendingState: String?
    private var completionHandler: ((Result<AuthResult, AuthError>) -> Void)?

    // 配置
    private let authBase = "http://localhost:3001"  // 认证服务地址
    private let tokenAPI = "http://localhost:3001/oauth/token"  // Token 交换接口
    private let callbackScheme = "passkeydemo"  // URL Scheme，需要在 Info.plist 中配置

    /// 认证结果
    struct AuthResult {
        let accessToken: String
        let tokenType: String
        let expiresIn: Int
        let username: String
    }

    /// 认证错误
    enum AuthError: Error, LocalizedError {
        case userCancelled
        case invalidCallback
        case tokenExchangeFailed(String)
        case networkError(Error)
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .userCancelled:
                return "用户取消登录"
            case .invalidCallback:
                return "无效的回调 URL"
            case .tokenExchangeFailed(let message):
                return "令牌交换失败: \(message)"
            case .networkError(let error):
                return "网络错误: \(error.localizedDescription)"
            case .invalidResponse:
                return "无效的响应数据"
            }
        }
    }

    /// 开始 Passkey 登录流程
    /// - Parameters:
    ///   - username: 用户名
    ///   - completion: 完成回调
    func startLogin(username: String, completion: @escaping (Result<AuthResult, AuthError>) -> Void) {
        // 生成防重放攻击的 state 参数
        let state = UUID().uuidString
        pendingState = state
        completionHandler = completion
        
        // 构建认证 URL，包含用户名和 state 参数
        let urlStr = "\(authBase)/index.html?username=\(username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username)&state=\(state)"
        guard let url = URL(string: urlStr) else {
            completion(.failure(.invalidCallback))
            return
        }

        print("🔐 开始 Passkey 登录流程")
        print("�� 用户名: \(username)")
        print("🌐 认证 URL: \(urlStr)")

        // 创建 ASWebAuthenticationSession
        let authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackScheme
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ ASWebAuthenticationSession 错误: \(error.localizedDescription)")
                if let nsError = error as NSError?, nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    self.completionHandler?(.failure(.userCancelled))
                } else {
                    self.completionHandler?(.failure(.networkError(error)))
                }
                return
            }
            
            guard let callbackURL = callbackURL else {
                print("❌ 没有收到回调 URL")
                self.completionHandler?(.failure(.invalidCallback))
                return
            }
            
            print("✅ 收到回调 URL: \(callbackURL.absoluteString)")
            self.handleCallback(callbackURL)
        }
        
        // 配置会话
        authSession.presentationContextProvider = self
        authSession.prefersEphemeralWebBrowserSession = true  // 使用无痕模式
        
        // 开始认证会话
        authSession.start()
        self.session = authSession
    }

    /// 处理认证回调
    private func handleCallback(_ callbackURL: URL) {
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            print("❌ 无法解析回调 URL")
            completionHandler?(.failure(.invalidCallback))
            return
        }
        
        // 提取授权码和 state
        let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        let returnedState = components.queryItems?.first(where: { $0.name == "state" })?.value
        
        print("🔍 回调参数解析:")
        print("   Code: \(code?.prefix(8) ?? "nil")...")
        print("   State: \(returnedState ?? "nil")")
        
        // 验证 state 防止重放攻击
        if let pendingState = self.pendingState, let returnedState = returnedState {
            if pendingState != returnedState {
                print("❌ State 不匹配，可能存在重放攻击")
                completionHandler?(.failure(.invalidCallback))
                return
            }
        }
        
        self.pendingState = nil
        
        guard let code = code else {
            print("❌ 没有找到授权码")
            completionHandler?(.failure(.invalidCallback))
            return
        }
        
        // 用授权码换取访问令牌
        exchangeCodeForToken(code: code)
    }

    /// 用授权码换取访问令牌
    private func exchangeCodeForToken(code: String) {
        print("🔄 开始令牌交换...")
        
        guard let url = URL(string: tokenAPI) else {
            print("❌ 无效的令牌交换 URL")
            completionHandler?(.failure(.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 构建请求体
        let requestBody = ["code": code]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ 无法序列化请求体: \(error)")
            completionHandler?(.failure(.networkError(error)))
            return
        }
        
        print("📤 发送令牌交换请求...")
        
        // 发送请求
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 网络请求失败: \(error.localizedDescription)")
                self.completionHandler?(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 无效的 HTTP 响应")
                self.completionHandler?(.failure(.invalidResponse))
                return
            }
            
            print("📥 收到响应: HTTP \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "未知错误"
                print("❌ 令牌交换失败: \(errorMessage)")
                self.completionHandler?(.failure(.tokenExchangeFailed(errorMessage)))
                return
            }
            
            guard let data = data else {
                print("❌ 没有响应数据")
                self.completionHandler?(.failure(.invalidResponse))
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ 无法解析 JSON 响应")
                    self.completionHandler?(.failure(.invalidResponse))
                    return
                }
                
                print("✅ 令牌交换成功")
                print("📋 响应数据: \(json)")
                
                guard let accessToken = json["access_token"] as? String,
                      let tokenType = json["token_type"] as? String,
                      let expiresIn = json["expires_in"] as? Int else {
                    print("❌ 响应数据缺少必要字段")
                    self.completionHandler?(.failure(.invalidResponse))
                    return
                }
                
                // 保存令牌到 Keychain（生产环境推荐）
                self.saveTokenToKeychain(accessToken: accessToken, tokenType: tokenType, expiresIn: expiresIn)
                
                // 创建认证结果
                let authResult = AuthResult(
                    accessToken: accessToken,
                    tokenType: tokenType,
                    expiresIn: expiresIn,
                    username: "demo_user"  // 实际应该从响应中获取
                )
                
                print("🎉 认证成功完成!")
                self.completionHandler?(.success(authResult))
                
            } catch {
                print("❌ JSON 解析失败: \(error)")
                self.completionHandler?(.failure(.networkError(error)))
            }
        }.resume()
    }
    
    /// 保存令牌到 Keychain
    private func saveTokenToKeychain(accessToken: String, tokenType: String, expiresIn: Int) {
        // 这里简化处理，实际生产环境应该使用 Keychain Services
        UserDefaults.standard.set(accessToken, forKey: "access_token")
        UserDefaults.standard.set(tokenType, forKey: "token_type")
        UserDefaults.standard.set(expiresIn, forKey: "expires_in")
        UserDefaults.standard.set(Date().timeIntervalSince1970 + Double(expiresIn), forKey: "token_expires_at")
        
        print("💾 令牌已保存到本地存储")
    }
    
    /// 获取当前保存的访问令牌
    func getCurrentAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }
    
    /// 检查令牌是否有效
    func isTokenValid() -> Bool {
        guard let _ = getCurrentAccessToken() else { return false }
        
        let expiresAt = UserDefaults.standard.double(forKey: "token_expires_at")
        return Date().timeIntervalSince1970 < expiresAt
    }
    
    /// 清除保存的令牌
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "token_type")
        UserDefaults.standard.removeObject(forKey: "expires_in")
        UserDefaults.standard.removeObject(forKey: "token_expires_at")
        print("🗑️ 已清除保存的令牌")
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // 返回当前应用的主窗口
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        return ASPresentationAnchor()
    }
}
