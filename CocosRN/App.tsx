/**
 * CocosRN - Passkey 生物识别认证应用
 * 主应用入口，管理页面切换
 */

import React, { useState } from 'react';
import LoginScreen from './LoginScreen';
import HomeScreen from './HomeScreen';

function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [username, setUsername] = useState('');
  const [loginTime, setLoginTime] = useState('');

  const handleLoginSuccess = (user: string, time: string) => {
    console.log('登录成功，设置状态:', { user, time });
    setUsername(user);
    setLoginTime(time);
    setIsLoggedIn(true);
  };

  const handleLogout = () => {
    console.log('用户退出登录');
    setIsLoggedIn(false);
    setUsername('');
    setLoginTime('');
  };

  console.log('App 渲染状态:', { isLoggedIn, username, loginTime });

  if (isLoggedIn) {
    return (
      <HomeScreen
        username={username}
        loginTime={loginTime}
        onLogout={handleLogout}
      />
    );
  }

  return (
    <LoginScreen onLoginSuccess={handleLoginSuccess} />
  );
}

export default App;