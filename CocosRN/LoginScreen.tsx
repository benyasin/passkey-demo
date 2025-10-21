/**
 * 登录/注册界面
 */
import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  SafeAreaView,
  StatusBar,
  useColorScheme,
} from 'react-native';
import InAppBrowser from 'react-native-inappbrowser-reborn';
import { Linking } from 'react-native';

interface LoginScreenProps {
  onLoginSuccess: (username: string, loginTime: string) => void;
}

export default function LoginScreen({ onLoginSuccess }: LoginScreenProps) {
  const isDarkMode = useColorScheme() === 'dark';
  const [username, setUsername] = useState('');
  const [displayName, setDisplayName] = useState('');

  const handleLogin = async () => {
    if (!username.trim()) {
      Alert.alert('错误', '请输入用户名');
      return;
    }

    try {
      const callbackUrl = 'passkeydemo://auth';
      const state = `login_${Date.now()}`;
      const authUrl = `http://localhost:3001/index.html?username=${encodeURIComponent(username)}&action=login&callback=${encodeURIComponent(callbackUrl)}&state=${encodeURIComponent(state)}`;
      
      if (await InAppBrowser.isAvailable()) {
        const result = await InAppBrowser.openAuth(authUrl, callbackUrl, {
          ephemeralWebSession: false,
          prefersEphemeralWebBrowserSession: false,
          showTitle: true,
          enableUrlBarHiding: true,
          enableDefaultShare: false,
          showInRecents: false,
        });
        
        if (result.type === 'success' && result.url) {
          console.log('认证成功，回调URL:', result.url);
          handleAuthCallback(result.url);
        } else if (result.type === 'cancel') {
          console.log('用户取消了认证');
          Alert.alert('取消', '用户取消了认证');
        } else {
          console.log('认证过程中发生错误:', result);
          Alert.alert('错误', '认证过程中发生错误');
        }
      } else {
        // Fallback to Linking.openURL
        await Linking.openURL(authUrl);
        Alert.alert('提示', '请在浏览器中完成认证，完成后返回应用');
      }
    } catch (error) {
      console.error('Login error:', error);
      Alert.alert('错误', '登录失败，请重试');
    }
  };

  const handleRegister = async () => {
    if (!username.trim()) {
      Alert.alert('错误', '请输入用户名');
      return;
    }

    try {
      const callbackUrl = 'passkeydemo://auth';
      const state = `register_${Date.now()}`;
      const authUrl = `http://localhost:3001/index.html?username=${encodeURIComponent(username)}&displayName=${encodeURIComponent(displayName)}&action=register&callback=${encodeURIComponent(callbackUrl)}&state=${encodeURIComponent(state)}`;
      
      if (await InAppBrowser.isAvailable()) {
        const result = await InAppBrowser.openAuth(authUrl, callbackUrl, {
          ephemeralWebSession: false,
          prefersEphemeralWebBrowserSession: false,
          showTitle: true,
          enableUrlBarHiding: true,
          enableDefaultShare: false,
          showInRecents: false,
        });
        
        if (result.type === 'success' && result.url) {
          console.log('注册成功，回调URL:', result.url);
          handleAuthCallback(result.url);
        } else if (result.type === 'cancel') {
          console.log('用户取消了注册');
          Alert.alert('取消', '用户取消了注册');
        } else {
          console.log('注册过程中发生错误:', result);
          Alert.alert('错误', '注册过程中发生错误');
        }
      } else {
        // Fallback to Linking.openURL
        await Linking.openURL(authUrl);
        Alert.alert('提示', '请在浏览器中完成注册，完成后返回应用');
      }
    } catch (error) {
      console.error('Register error:', error);
      Alert.alert('错误', '注册失败，请重试');
    }
  };

  const handleAuthCallback = (url: string) => {
    console.log('收到回调URL:', url);
    try {
      const urlObj = new URL(url);
      const params = new URLSearchParams(urlObj.search);
      
      console.log('URL解析:', {
        protocol: urlObj.protocol,
        hostname: urlObj.hostname,
        pathname: urlObj.pathname,
        search: urlObj.search
      });
      
      // 检查 URL 是否包含 auth 相关的路径或参数
      const hasAuthPath = urlObj.pathname === '/auth' || urlObj.hostname === 'auth' || urlObj.pathname.includes('auth');
      const hasAuthParams = params.get('code') || params.get('success');
      
      console.log('URL检查:', { hasAuthPath, hasAuthParams, pathname: urlObj.pathname, hostname: urlObj.hostname });
      
      if (hasAuthPath || hasAuthParams) {
        const success = params.get('success');
        const code = params.get('code');
        const state = params.get('state');
        
        console.log('回调参数:', { success, code, state });
        
        // 处理登录成功（有 code 参数）
        if (code) {
          console.log('登录成功，获得授权码:', code);
          onLoginSuccess(username, new Date().toLocaleString());
          //Alert.alert('成功', '登录成功！');
        }
        // 处理注册成功（有 success=true 参数）
        else if (success === 'true') {
          console.log('注册成功');
          onLoginSuccess(username, new Date().toLocaleString());
          //Alert.alert('成功', '注册成功！');
        } else {
          console.log('认证失败');
          Alert.alert('失败', '认证失败');
        }
      } else {
        console.log('URL不匹配，hostname:', urlObj.hostname);
      }
    } catch (error) {
      console.error('Callback error:', error);
      Alert.alert('错误', '处理认证结果时发生错误');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <View style={styles.authContainer}>
        <Text style={styles.title}>CocosRN Passkey 认证</Text>
        <Text style={styles.subtitle}>使用生物识别技术进行安全认证</Text>
        
        <View style={styles.inputContainer}>
          <TextInput
            style={styles.input}
            placeholder="用户名"
            value={username}
            onChangeText={setUsername}
            autoCapitalize="none"
            autoCorrect={false}
          />
          
          <TextInput
            style={styles.input}
            placeholder="显示名称 (注册时使用)"
            value={displayName}
            onChangeText={setDisplayName}
            autoCapitalize="none"
            autoCorrect={false}
          />
        </View>
        
        <View style={styles.buttonContainer}>
          <TouchableOpacity style={styles.loginButton} onPress={handleLogin}>
            <Text style={styles.buttonText}>登录</Text>
          </TouchableOpacity>
          
          <TouchableOpacity style={styles.registerButton} onPress={handleRegister}>
            <Text style={styles.buttonText}>注册</Text>
          </TouchableOpacity>
        </View>
        
        <Text style={styles.note}>
          点击登录或注册后，将打开应用内浏览器进行生物识别认证
        </Text>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  authContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 10,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 40,
    textAlign: 'center',
  },
  inputContainer: {
    width: '100%',
    marginBottom: 30,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 15,
    marginBottom: 15,
    fontSize: 16,
    backgroundColor: '#fff',
  },
  buttonContainer: {
    width: '100%',
    marginBottom: 20,
  },
  loginButton: {
    backgroundColor: '#007AFF',
    padding: 15,
    borderRadius: 8,
    marginBottom: 15,
    alignItems: 'center',
  },
  registerButton: {
    backgroundColor: '#34C759',
    padding: 15,
    borderRadius: 8,
    marginBottom: 15,
    alignItems: 'center',
  },
  testButton: {
    backgroundColor: '#FF9500',
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  note: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    lineHeight: 20,
  },
});
