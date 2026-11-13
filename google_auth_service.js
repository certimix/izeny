const http = require('http');
const crypto = require('crypto');

const PB_URL = 'http://127.0.0.1:8090';
const SUPERUSER_IDENTITY = 'certimixx@gmail.com';
const SUPERUSER_PASSWORD = 'mix@mix2023';
const PORT = 8095;

async function getSuperuserToken() {
  const resp = await fetch(`${PB_URL}/api/collections/_superusers/auth-with-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identity: SUPERUSER_IDENTITY, password: SUPERUSER_PASSWORD })
  });
  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Failed superuser login: ${errText}`);
  }
  const data = await resp.json();
  return data.token;
}

const server = http.createServer(async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // 1. Google OAuth
  if (req.method === 'POST' && (req.url === '/api/auth/google' || req.url === '/api/auth/google/')) {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', async () => {
      try {
        const payload = JSON.parse(body || '{}');
        const credential = (payload.credential || payload.token || '').trim();

        if (!credential) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Token de credencial não informado' }));
          return;
        }

        let gUser = null;
        if (credential.startsWith('ya29.')) {
          // Access token flow
          const gResp = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
            headers: { 'Authorization': `Bearer ${credential}` }
          });
          if (!gResp.ok) {
            res.writeHead(401, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: 'Token de acesso do Google inválido ou expirado' }));
            return;
          }
          gUser = await gResp.json();
        } else {
          // ID token (JWT) flow
          const gResp = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(credential)}`);
          if (!gResp.ok) {
            // Try access_token fallback
            const fallbackResp = await fetch(`https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(credential)}`);
            if (!fallbackResp.ok) {
              res.writeHead(401, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ error: 'Token do Google inválido ou expirado' }));
              return;
            }
            gUser = await fallbackResp.json();
          } else {
            gUser = await gResp.json();
          }
        }

        const email = (gUser.email || '').trim().toLowerCase();
        if (!email) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'E-mail não encontrado no perfil do Google' }));
          return;
        }

        console.log(`[Google Auth] Valid token for: ${email}`);

        const suToken = await getSuperuserToken();

        // Search user in PocketBase
        const searchResp = await fetch(`${PB_URL}/api/collections/users/records?filter=(email='${encodeURIComponent(email)}')`, {
          headers: { 'Authorization': suToken }
        });
        const searchData = await searchResp.json();
        let userRecord = (searchData.items && searchData.items.length > 0) ? searchData.items[0] : null;

        if (!userRecord) {
          console.log(`[Google Auth] Creating new user for: ${email}`);
          const randomPass = crypto.randomBytes(24).toString('hex');
          const baseName = (gUser.name || gUser.given_name || email.split('@')[0]).trim();
          const username = (email.split('@')[0].replace(/[^a-zA-Z0-9_]/g, '_') + '_' + Math.floor(Math.random() * 900 + 100)).substring(0, 30);

          const createResp = await fetch(`${PB_URL}/api/collections/users/records`, {
            method: 'POST',
            headers: {
              'Authorization': suToken,
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              email: email,
              emailVisibility: false,
              name: baseName,
              username: username,
              verified: true,
              password: randomPass,
              passwordConfirm: randomPass,
              bio: 'Membro da Comunidade ZenyDesk via Google'
            })
          });

          if (!createResp.ok) {
            const createErr = await createResp.text();
            throw new Error(`Falha ao registrar usuário: ${createErr}`);
          }
          userRecord = await createResp.json();
        }

        // Generate authentic user session token via impersonate
        const impResp = await fetch(`${PB_URL}/api/collections/users/impersonate/${userRecord.id}`, {
          method: 'POST',
          headers: { 'Authorization': suToken }
        });

        if (!impResp.ok) {
          const impErr = await impResp.text();
          throw new Error(`Falha de autenticação interna: ${impErr}`);
        }

        const impData = await impResp.json();
        console.log(`[Google Auth] SUCESSO: ${email} (ID: ${userRecord.id})`);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          token: impData.token,
          record: impData.record || userRecord
        }));
      } catch (err) {
        console.error('[Google Auth Error]', err);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // 2. Direct Password Reset
  if (req.method === 'POST' && (req.url === '/api/auth/reset-password' || req.url === '/api/auth/reset-password/')) {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', async () => {
      try {
        const payload = JSON.parse(body || '{}');
        const email = (payload.email || '').trim().toLowerCase();
        const newPassword = (payload.newPassword || '').trim();
        const newPasswordConfirm = (payload.newPasswordConfirm || '').trim();

        if (!email || !newPassword) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'E-mail e nova senha são obrigatórios.' }));
          return;
        }

        if (newPassword.length < 6) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'A nova senha deve ter no mínimo 6 caracteres.' }));
          return;
        }

        if (newPassword !== newPasswordConfirm) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'A confirmação de senha não confere.' }));
          return;
        }

        const suToken = await getSuperuserToken();

        // Search user in PocketBase
        const searchResp = await fetch(`${PB_URL}/api/collections/users/records?filter=(email='${encodeURIComponent(email)}')`, {
          headers: { 'Authorization': suToken }
        });
        const searchData = await searchResp.json();
        const user = (searchData.items && searchData.items.length > 0) ? searchData.items[0] : null;

        if (!user) {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Nenhum usuário cadastrado com este e-mail.' }));
          return;
        }

        // Update password in PocketBase
        const patchResp = await fetch(`${PB_URL}/api/collections/users/records/${user.id}`, {
          method: 'PATCH',
          headers: {
            'Authorization': suToken,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            password: newPassword,
            passwordConfirm: newPasswordConfirm
          })
        });

        if (!patchResp.ok) {
          const errText = await patchResp.text();
          throw new Error(`Erro ao atualizar senha no banco: ${errText}`);
        }

        console.log(`[Reset Password] Senha redefinida com sucesso para: ${email}`);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          message: 'Senha redefinida com sucesso! Você já pode acessar.'
        }));
      } catch (err) {
        console.error('[Reset Password Error]', err);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // Health check
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', service: 'izeny-google-auth' }));
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not found' }));
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`[izeny-google-auth] Listening on http://127.0.0.1:${PORT}`);
});
