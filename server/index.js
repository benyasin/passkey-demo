import express from 'express';
import cors from 'cors';
import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import {
  generateRegistrationOptions,
  verifyRegistrationResponse,
  generateAuthenticationOptions,
  verifyAuthenticationResponse,
} from '@simplewebauthn/server';

/** ============ 基本配置（按你的域名改） ============ */
const rpID = 'localhost';            // 认证域的主域（本地开发用 localhost）
const origin = 'http://localhost:3001';  // 完整 origin（本地开发用 HTTP）
const JWT_SECRET = 'dev_only_secret_change_me'; // PoC 用，生产请换安全密钥

/** ============ 内存"数据库"（PoC） ============ */
const db = {
  users: new Map(),         // username -> { id, username, credentials: [...] }
  challenges: new Map(),    // username -> latest challenge
  codes: new Map(),         // code -> { username, expAt }
};

function getUser(username) {
  if (!db.users.has(username)) {
    db.users.set(username, { id: uuidv4(), username, credentials: [] });
  }
  return db.users.get(username);
}

const app = express();
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

// 静态文件服务（为前端页面提供服务）
app.use(express.static('../web'));

/** ============ 注册：生成注册 options ============ */
app.post('/webauthn/registration/options', async (req, res) => {
  const { username, displayName } = req.body;
  if (!username) return res.status(400).json({ error: 'username required' });
  
  console.log(`[注册] 用户: ${username}`);
  const user = getUser(username);

  const options = await generateRegistrationOptions({
    rpName: 'Passkey Demo',
    rpID,
    userID: user.id,
    userName: user.username,
    userDisplayName: displayName || user.username,
    attestationType: 'none',
    authenticatorSelection: {
      residentKey: 'required',
      userVerification: 'required',
      authenticatorAttachment: 'platform', // iOS/Android 平台认证器
    },
    excludeCredentials: user.credentials.map(cred => ({
      id: Buffer.from(cred.credentialID, 'base64url'),
      type: 'public-key',
    })),
  });

  db.challenges.set(username, options.challenge);
  console.log(`[注册] 生成 challenge 给用户: ${username}`);
  res.json(options);
});

/** ============ 注册：验证响应 ============ */
app.post('/webauthn/registration/verify', async (req, res) => {
  const { username, attResp } = req.body;
  const expectedChallenge = db.challenges.get(username);
  if (!expectedChallenge) return res.status(400).json({ error: 'challenge missing' });

  console.log(`[注册验证] 用户: ${username}`);
  try {
    const verification = await verifyRegistrationResponse({
      response: attResp,
      expectedChallenge,
      expectedOrigin: origin,
      expectedRPID: rpID,
    });
    const { verified, registrationInfo } = verification;
    if (!verified || !registrationInfo) {
      console.log(`[注册验证] 失败: ${username}`);
      return res.status(400).json({ verified: false });
    }
    const user = getUser(username);
    const { credentialPublicKey, credentialID, counter } = registrationInfo;

    // 保存凭证
    user.credentials.push({
      credentialID: Buffer.from(credentialID).toString('base64url'),
      publicKey: Buffer.from(credentialPublicKey).toString('base64url'),
      counter,
    });

    db.challenges.delete(username);
    console.log(`[注册验证] 成功: ${username}, 凭证ID: ${Buffer.from(credentialID).toString('base64url').substring(0, 10)}...`);
    res.json({ verified: true });
  } catch (e) {
    console.error('[注册验证] 错误:', e);
    res.status(400).json({ error: 'verify failed' });
  }
});

/** ============ 登录：生成 options ============ */
app.post('/webauthn/authentication/options', async (req, res) => {
  const { username } = req.body;
  const user = getUser(username);
  const allowCreds = user.credentials.map(cred => ({
    id: Buffer.from(cred.credentialID, 'base64url'),
    type: 'public-key',
  }));

  console.log(`[登录] 用户: ${username}, 可用凭证数: ${allowCreds.length}`);
  const options = await generateAuthenticationOptions({
    rpID,
    userVerification: 'required',
    allowCredentials: allowCreds.length ? allowCreds : undefined, // 无则允许发现式认证
  });
  db.challenges.set(username, options.challenge);
  res.json(options);
});

/** ============ 登录：验证响应 → 颁发一次性 code ============ */
app.post('/webauthn/authentication/verify', async (req, res) => {
  const { username, authResp } = req.body;
  const expectedChallenge = db.challenges.get(username);
  if (!expectedChallenge) return res.status(400).json({ error: 'challenge missing' });
  const user = getUser(username);

  console.log(`[登录验证] 用户: ${username}`);
  // 取出该 credential
  const cred = user.credentials.find(c => c.credentialID === authResp.id);
  const authenticator = cred
    ? {
        credentialPublicKey: Buffer.from(cred.publicKey, 'base64url'),
        credentialID: Buffer.from(cred.credentialID, 'base64url'),
        counter: cred.counter,
      }
    : undefined;

  try {
    const verification = await verifyAuthenticationResponse({
      response: authResp,
      expectedChallenge,
      expectedOrigin: origin,
      expectedRPID: rpID,
      authenticator,
    });
    const { verified, authenticationInfo } = verification;
    if (!verified) {
      console.log(`[登录验证] 失败: ${username}`);
      return res.status(400).json({ verified: false });
    }

    // 更新计数器
    if (cred) cred.counter = authenticationInfo.newCounter;

    db.challenges.delete(username);

    // 颁发一次性 code（有效 60 秒）
    const code = crypto.randomBytes(16).toString('hex');
    const expAt = Date.now() + 60 * 1000;
    db.codes.set(code, { username, expAt });

    console.log(`[登录验证] 成功: ${username}, 颁发 code: ${code.substring(0, 8)}...`);
    res.json({ verified: true, code });
  } catch (e) {
    console.error('[登录验证] 错误:', e);
    res.status(400).json({ error: 'verify failed' });
  }
});

/** ============ App 用 code 换 token ============ */
app.post('/oauth/token', (req, res) => {
  const { code } = req.body;
  console.log(`[Token交换] 收到 code: ${code ? code.substring(0, 8) + '...' : 'null'}`);
  
  const rec = db.codes.get(code);
  if (!rec) {
    console.log('[Token交换] 无效 code');
    return res.status(400).json({ error: 'invalid code' });
  }
  if (rec.expAt < Date.now()) {
    console.log('[Token交换] code 已过期');
    db.codes.delete(code);
    return res.status(400).json({ error: 'code expired' });
  }
  db.codes.delete(code);

  const access_token = jwt.sign(
    { sub: rec.username, scope: 'basic' },
    JWT_SECRET,
    { expiresIn: '1h' },
  );
  
  console.log(`[Token交换] 成功: ${rec.username}, 颁发 token`);
  res.json({ access_token, token_type: 'Bearer', expires_in: 3600 });
});

/** ============ 健康检查 ============ */
app.get('/health', (_, res) => res.json({ status: 'ok', timestamp: new Date().toISOString() }));

/** ============ 获取用户信息（需要 token） ============ */
app.get('/api/user', (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid authorization header' });
  }
  
  const token = authHeader.substring(7);
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = db.users.get(decoded.sub);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({
      username: user.username,
      id: user.id,
      credentialsCount: user.credentials.length,
      registeredAt: new Date().toISOString() // 简化版，实际应该从数据库获取
    });
  } catch (e) {
    console.error('[用户信息] Token 验证失败:', e.message);
    res.status(401).json({ error: 'Invalid token' });
  }
});

const port = 3001;
app.listen(port, () => {
  console.log(`🚀 Passkey Demo Server 启动成功!`);
  console.log(`📱 后端 API: http://localhost:${port}`);
  console.log(`🌐 前端页面: http://localhost:${port}/index.html`);
  console.log(`🔍 健康检查: http://localhost:${port}/health`);
  console.log(`\n📋 可用接口:`);
  console.log(`   POST /webauthn/registration/options  - 注册选项`);
  console.log(`   POST /webauthn/registration/verify    - 验证注册`);
  console.log(`   POST /webauthn/authentication/options - 登录选项`);
  console.log(`   POST /webauthn/authentication/verify - 验证登录`);
  console.log(`   POST /oauth/token                     - 交换 token`);
  console.log(`   GET  /api/user                        - 获取用户信息`);
});
