/**
 * 首页界面
 */
import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  useColorScheme,
} from 'react-native';

interface HomeScreenProps {
  username: string;
  loginTime: string;
  onLogout: () => void;
}

export default function HomeScreen({ username, loginTime, onLogout }: HomeScreenProps) {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <View style={styles.homeContainer}>
        <Text style={styles.welcomeTitle}>欢迎回来！</Text>
        <Text style={styles.userInfo}>用户：{username}</Text>
        <Text style={styles.loginTime}>登录时间：{loginTime}</Text>
        
        <View style={styles.features}>
          <Text style={styles.featuresTitle}>功能特性</Text>
          <Text style={styles.featureItem}>🔐 Passkey 生物识别认证</Text>
          <Text style={styles.featureItem}>📱 跨平台支持</Text>
          <Text style={styles.featureItem}>🛡️ 企业级安全</Text>
        </View>
        
        <TouchableOpacity style={styles.logoutButton} onPress={onLogout}>
          <Text style={styles.logoutButtonText}>退出登录</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  homeContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  welcomeTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 20,
    textAlign: 'center',
  },
  userInfo: {
    fontSize: 18,
    color: '#666',
    marginBottom: 10,
  },
  loginTime: {
    fontSize: 16,
    color: '#999',
    marginBottom: 40,
  },
  features: {
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 12,
    marginBottom: 40,
    width: '100%',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  featuresTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 15,
    textAlign: 'center',
  },
  featureItem: {
    fontSize: 16,
    color: '#666',
    marginBottom: 10,
    textAlign: 'center',
  },
  logoutButton: {
    backgroundColor: '#FF3B30',
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
    width: '100%',
  },
  logoutButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
});
