import UIKit

/// 主视图控制器
/// 演示 Passkey 登录功能
class ViewController: UIViewController {
    
    // MARK: - UI Elements
    private var usernameTextField: UITextField!
    private var loginButton: UIButton!
    private var registerButton: UIButton!
    private var logTextView: UITextView!
    private var pageModeSegmentedControl: UISegmentedControl!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Passkey Demo"
        view.backgroundColor = UIColor.systemBackground
        
        // 创建用户名输入框
        usernameTextField = UITextField()
        usernameTextField.placeholder = "输入用户名"
        usernameTextField.text = "demo_user"
        usernameTextField.borderStyle = .roundedRect
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建登录按钮
        loginButton = UIButton(type: .system)
        loginButton.setTitle("🔑 登录", for: .normal)
        loginButton.backgroundColor = UIColor.systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建注册按钮
        registerButton = UIButton(type: .system)
        registerButton.setTitle("📝 注册 Passkey", for: .normal)
        registerButton.backgroundColor = UIColor.systemGreen
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.layer.cornerRadius = 8
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建页面模式选择器
        pageModeSegmentedControl = UISegmentedControl(items: ["透明模式", "品牌模式"])
        pageModeSegmentedControl.selectedSegmentIndex = 1 // 默认选择品牌模式
        pageModeSegmentedControl.backgroundColor = UIColor.systemGray6
        pageModeSegmentedControl.selectedSegmentTintColor = UIColor.systemBlue
        pageModeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        pageModeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建日志视图
        logTextView = UITextView()
        logTextView.backgroundColor = UIColor.systemGray6
        logTextView.layer.cornerRadius = 8
        logTextView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        logTextView.isEditable = false
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加子视图
        view.addSubview(usernameTextField)
        view.addSubview(pageModeSegmentedControl)
        view.addSubview(loginButton)
        view.addSubview(registerButton)
        view.addSubview(logTextView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 用户名输入框
            usernameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            usernameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // 页面模式选择器
            pageModeSegmentedControl.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            pageModeSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            pageModeSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            pageModeSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // 登录按钮
            loginButton.topAnchor.constraint(equalTo: pageModeSegmentedControl.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 注册按钮
            registerButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            registerButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 日志视图
            logTextView.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 30),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        // 添加日志
        addLog("🚀 Passkey Demo 应用启动")
        addLog("🔍 检查当前状态...")
        addLog("📱 当前页面模式: \(AuthManager.shared.getCurrentPageMode() == .branded ? "品牌模式" : "透明模式")")
    }
    
    // MARK: - Actions
    @objc private func loginButtonTapped() {
        guard let username = usernameTextField.text, !username.isEmpty else {
            showAlert(title: "错误", message: "请输入用户名")
            return
        }
        
        // 更新页面模式
        let selectedMode = pageModeSegmentedControl.selectedSegmentIndex == 0 ? AuthManager.PageMode.transparent : AuthManager.PageMode.branded
        AuthManager.shared.setPageMode(selectedMode)
        
        addLog("🚀 开始 Passkey 登录流程...")
        addLog("👤 用户名: \(username)")
        addLog("📱 页面模式: \(selectedMode == .branded ? "品牌模式" : "透明模式")")
        
        // 禁用按钮防止重复点击
        loginButton.isEnabled = false
        loginButton.setTitle("🔄 登录中...", for: .normal)
        
        AuthManager.shared.startLogin(username: username) { [weak self] result in
            DispatchQueue.main.async {
                self?.loginButton.isEnabled = true
                self?.loginButton.setTitle("🔑 登录", for: .normal)
                
                switch result {
                case .success(let authResult):
                    self?.addLog("✅ 登录成功!")
                    self?.addLog("🎫 Access Token: \(authResult.accessToken.prefix(20))...")
                    self?.addLog("⏰ 过期时间: \(authResult.expiresIn) 秒")
                    
                    // 保存用户信息
                    UserDefaults.standard.set(authResult.accessToken, forKey: "userToken")
                    UserDefaults.standard.set(username, forKey: "username")
                    
                    // 跳转到首页
                    self?.navigateToHome(username: username)
                    
                case .failure(let error):
                    self?.addLog("❌ 登录失败: \(error.localizedDescription)")
                    self?.showAlert(title: "登录失败", message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func registerButtonTapped() {
        guard let username = usernameTextField.text, !username.isEmpty else {
            showAlert(title: "错误", message: "请输入用户名")
            return
        }
        
        // 更新页面模式
        let selectedMode = pageModeSegmentedControl.selectedSegmentIndex == 0 ? AuthManager.PageMode.transparent : AuthManager.PageMode.branded
        AuthManager.shared.setPageMode(selectedMode)
        
        addLog("📝 开始 Passkey 注册流程...")
        addLog("👤 用户名: \(username)")
        addLog("📱 页面模式: \(selectedMode == .branded ? "品牌模式" : "透明模式")")
        
        // 禁用按钮防止重复点击
        registerButton.isEnabled = false
        registerButton.setTitle("🔄 注册中...", for: .normal)
        
        AuthManager.shared.startRegistration(username: username) { [weak self] result in
            DispatchQueue.main.async {
                self?.registerButton.isEnabled = true
                self?.registerButton.setTitle("📝 注册 Passkey", for: .normal)
                
                switch result {
                case .success:
                    self?.addLog("✅ 注册成功!")
                    self?.addLog("🔐 Passkey 已保存到设备")
                    self?.showAlert(title: "注册成功", message: "Passkey 注册完成！")
                    
                case .failure(let error):
                    self?.addLog("❌ 注册失败: \(error.localizedDescription)")
                    self?.showAlert(title: "注册失败", message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)\n"
        
        DispatchQueue.main.async {
            self.logTextView.text += logMessage
            self.logTextView.scrollRangeToVisible(NSRange(location: self.logTextView.text.count - 1, length: 1))
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func navigateToHome(username: String) {
        // 显示登录成功后的首页界面
        showHomeInterface(username: username)
    }
    
    private func showHomeInterface(username: String) {
        // 隐藏登录注册按钮
        loginButton.isHidden = true
        registerButton.isHidden = true
        usernameTextField.isHidden = true
        pageModeSegmentedControl.isHidden = true
        
        // 显示首页内容
        showHomeContent(username: username)
    }
    
    private func showHomeContent(username: String) {
        // 清除日志
        logTextView.text = ""
        
        // 添加首页内容
        addLog("🏠 欢迎使用 Passkey Demo")
        addLog("👤 用户: \(username)")
        addLog("✅ 已通过生物识别认证")
        addLog("")
        addLog("🔐 安全状态: 已认证")
        addLog("⏰ 登录时间: \(DateFormatter.logFormatter.string(from: Date()))")
        addLog("")
        addLog("🎉 登录成功！您现在可以安全地使用应用")
        
        // 创建首页布局
        setupHomeLayout(username: username)
    }
    
    private func setupHomeLayout(username: String) {
        // 创建欢迎标题
        let welcomeLabel = UILabel()
        welcomeLabel.text = "欢迎回来！"
        welcomeLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        welcomeLabel.textColor = .label
        welcomeLabel.textAlignment = .center
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建用户信息标签
        let userLabel = UILabel()
        userLabel.text = "👤 \(username)"
        userLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        userLabel.textColor = .secondaryLabel
        userLabel.textAlignment = .center
        userLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建状态标签
        let statusLabel = UILabel()
        statusLabel.text = "✅ 已通过生物识别认证"
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = .systemGreen
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建登出按钮
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("🚪 登出", for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        logoutButton.backgroundColor = UIColor.systemRed
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.layer.cornerRadius = 12
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        
        // 添加子视图
        view.addSubview(welcomeLabel)
        view.addSubview(userLabel)
        view.addSubview(statusLabel)
        view.addSubview(logoutButton)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 欢迎标题
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            welcomeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            welcomeLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // 用户信息
            userLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            userLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 20),
            userLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            userLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // 状态标签
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: userLabel.bottomAnchor, constant: 30),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // 登出按钮
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 60),
            logoutButton.widthAnchor.constraint(equalToConstant: 200),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 日志视图调整
            logTextView.topAnchor.constraint(equalTo: logoutButton.bottomAnchor, constant: 40),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func logoutButtonTapped() {
        let alert = UIAlertController(
            title: "确认登出",
            message: "您确定要登出吗？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "登出", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        
        present(alert, animated: true)
    }
    
    private func performLogout() {
        // 清除用户数据
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "username")
        
        // 恢复登录界面
        loginButton.isHidden = false
        registerButton.isHidden = false
        usernameTextField.isHidden = false
        pageModeSegmentedControl.isHidden = false
        
        // 移除首页UI元素
        view.subviews.forEach { subview in
            if let button = subview as? UIButton, button.titleLabel?.text?.contains("登出") == true {
                button.removeFromSuperview()
            } else if let label = subview as? UILabel, 
                      label.text?.contains("欢迎回来") == true || 
                      label.text?.contains("👤") == true || 
                      label.text?.contains("已通过生物识别认证") == true {
                label.removeFromSuperview()
            }
        }
        
        // 清除日志并显示欢迎信息
        logTextView.text = ""
        addLog("🚀 Passkey Demo 应用启动")
        addLog("🔍 检查当前状态...")
        addLog("📱 当前页面模式: \(AuthManager.shared.getCurrentPageMode() == .branded ? "品牌模式" : "透明模式")")
        
        // 显示登出成功提示
        let alert = UIAlertController(
            title: "登出成功",
            message: "您已成功登出",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}