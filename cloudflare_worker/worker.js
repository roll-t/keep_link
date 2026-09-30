/**
 * Cloudflare Worker: FCM Push Notification Service cho KeepLink
 * Hoàn toàn miễn phí 100% (100.000 requests/ngày).
 *
 * Cách hoạt động:
 * 1. Nhận yêu cầu POST từ App KeepLink khi có người gửi link / kết bạn.
 * 2. Lấy FCM Token của người nhận từ Firebase Database hoặc từ payload.
 * 3. Tạo OAuth2 Token từ Service Account của Firebase (sử dụng Web Crypto API thuần).
 * 4. Gửi thông báo đến Google FCM HTTP v1 API.
 */

// Cấu hình Service Account (Điền thông tin từ file service-account.json của Firebase hoặc đặt trong Cloudflare Secrets/Variables)
const FIREBASE_CONFIG = {
  // Project ID chính xác từ Firebase:
  project_id: "linkcapture-13a10",
  // client_email từ file service account JSON:
  client_email: "firebase-adminsdk-fbsvc@linkcapture-13a10.iam.gserviceaccount.com",
  // private_key từ file service account JSON:
  private_key: `-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQCcbnLVo/A3YeYT
yhUd/1BMcjljTLuhkgpUUKvfFPqLrI0LVidMd4b2hMzFNjUBc514vTmfSdAVBAh8
VDvR9mwOvij6E0TlVjXI7RVBM6BuAbyqVTQwVjGIDqN+bgc9s9pfmudhaby2mMQ0
n6WdQfTpVCH7X+DM8Arf/0LSGK3wANBnSOTIw73oggxcsYZACW4SRcaY1oahcIAi
tWY6OBBxzgGzlM7s0PhMxwSIAAfIVG53eFlBqSh3mCT2PK8+B6iEX89IsPccnMez
PI2C21ZeopX2JK98OzUW4hYgp9dGX1ZFEUUlYCPHdgk2b67ED1M9lfeS2oPMXNAR
0DRC5VcbAgMBAAECggEABLIe4CfmkmfUOSlA5Togf6YsIwpCInFlivtmKJeshhw9
ANqdg/xqJwtJSrnViubprFHhB9WQGZlmsc8lG1voCX2ocdbs1tLClMOWw3LLyl5i
x5AwNV7ZAZcPtFnHZBEUKV69usORGfNP0uHGxG44h/dYRjLHs9v+z5ON8djMAkWc
xB7VJOV8Qd0jtfzF7wwr1WDSV3w8zbsp7wco9wReiZdysJMLhUFE7c5e3go3hY0+
/GsZz+3+V3XW2JV/TnDPlWeQnuJ8UhoySUMAmbCnzmYqCrt8DJdCsyJXAKnq+94p
7lm1wZBd1oOZ+7w+N5/Lo/ZBCj/QT2/quSM0xbUDPQKBgQDNChJKBYVN7ozTz4Tj
gS20MKZ113J/OcI6lKDDBwRZKmEfCMPx4kzW/T75nOuqF/7aeoljfXqr0amBG0AQ
pS6ONP9dan/F+dX3llwQ+kq0p6Y8MuXw7z48qDtwfszH0/WcLpabUzS/fzKinzb4
uthzm276XOMs3CWexMhSocs/LwKBgQDDT6DOaBKae5C9Wy5xFg5fzPNtZUavxKXs
Deff4ajc2hgSGIjxTUyHWM9AfY2ftOSYrWAJc18h4I6hj+kaBKS8fG8Aty3Y0d/C
iG3Ir2NFCzie0mN0quCQl1Ldt35F7uZc/iB/Qnd2zUzz047p7BBpllMM0AsSfA9n
m+xfAWlL1QKBgQCql+mVmrhJmeOjyzH2k6DyHdQxkZrazbSTRtvmyCzO/xqlVoao
9q8V5MiDqBLPh31sS62JkHoDAMM1/vUzpCty+BdLovNCRdbHU1uwaH7FhgMibPqx
lmxCzXn+5BD/ZZQhaQW3n+fwOCVp9mwnUFYNAdK5DZWZ2mSWj4VYcvMG0wKBgQCA
Yew7IU/xOf4HalNZxHzIXkk5BJR1X1cNlopvsL62BapC4tvJed0vLqJ1KtKYQ2js
LzLso2jKNPisnJNGJf0/ZK/2kXJSjop+Lf20KA2hyeF7DKKRgu1APigbU81uHL5S
LD2iSUeL0SGfONY9T43uSgDncC2HBgN+QJEcVionzQKBgQDEmXPbtm8ghxKVnYZR
munPwkGnnDoEKnrVRioz2QD1WhXNzt43hBmy3w6Ydy13y9ZuLf52OTBywGhW82Im
PriB62WULC0BxGydF4RyFwo0nuEa/x94lHfCaa1WfIq4wXp1YrI4JzdS3fnG78VJ
v3UojL981b11wW+ZczDTSYjtBQ==
-----END PRIVATE KEY-----`,
  // Firebase Realtime Database URL:
  database_url: "https://linkcapture-13a10-default-rtdb.firebaseio.com",
};

// Secret token để bảo vệ Worker (trùng với apiSecret trong push_notification_config.dart)
const API_SECRET = "keeplink_fcm_secret_2026";

let cachedAccessToken = null;
let tokenExpiresAt = 0;

export default {
  async fetch(request, env) {
    // Chỉ cho phép method POST
    if (request.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    try {
      const url = new URL(request.url);
      if (url.pathname !== "/send-notification" && url.pathname !== "/") {
        return new Response(JSON.stringify({ error: "Endpoint not found" }), {
          status: 404,
          headers: { "Content-Type": "application/json" },
        });
      }

      const body = await request.json();

      // Kiểm tra secret token
      const clientSecret = body.secret || request.headers.get("x-secret-key");
      const expectedSecret = env.API_SECRET || API_SECRET;
      if (clientSecret !== expectedSecret) {
        return new Response(JSON.stringify({ error: "Unauthorized: Invalid secret" }), {
          status: 401,
          headers: { "Content-Type": "application/json" },
        });
      }

      const receiverUid = body.receiverUid;
      let targetToken = body.receiverToken;
      const title = body.title || "Linkeep";
      const messageBody = body.body || "Bạn có thông báo mới";
      const data = body.data || {};

      const projectId = env.FIREBASE_PROJECT_ID || FIREBASE_CONFIG.project_id;
      const clientEmail = env.FIREBASE_CLIENT_EMAIL || FIREBASE_CONFIG.client_email;
      const privateKey = env.FIREBASE_PRIVATE_KEY || FIREBASE_CONFIG.private_key;
      const databaseUrl = env.FIREBASE_DATABASE_URL || FIREBASE_CONFIG.database_url;

      // 1. Nếu chưa có FCM Token, lấy từ Firebase Realtime Database
      if (!targetToken && receiverUid) {
        targetToken = await getFcmTokenFromDatabase(databaseUrl, receiverUid, clientEmail, privateKey);
      }

      if (!targetToken) {
        return new Response(
          JSON.stringify({
            success: false,
            message: `Không tìm thấy FCM Token cho user ${receiverUid}. Thiết bị có thể chưa mở app lần nào.`,
          }),
          { status: 200, headers: { "Content-Type": "application/json" } }
        );
      }

      // 2. Lấy Google OAuth2 Access Token
      const accessToken = await getGoogleAccessToken(clientEmail, privateKey);

      // 3. Gửi thông báo qua Google FCM HTTP v1
      const fcmResponse = await sendFcmV1Message(projectId, accessToken, targetToken, title, messageBody, data);

      return new Response(
        JSON.stringify({
          success: true,
          fcmResponse,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    } catch (err) {
      return new Response(
        JSON.stringify({
          success: false,
          error: err.message || String(err),
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }
  },
};

/**
 * Lấy FCM Token của người nhận từ Firebase Database bằng Service Account Token
 */
async function getFcmTokenFromDatabase(databaseUrl, uid, clientEmail, privateKey) {
  try {
    const accessToken = await getGoogleAccessToken(clientEmail, privateKey);
    const cleanUrl = databaseUrl.replace(/\/$/, "");
    const res = await fetch(`${cleanUrl}/users/${uid}/fcmToken.json?access_token=${accessToken}`);
    if (!res.ok) return null;
    const token = await res.json();
    return typeof token === "string" ? token : null;
  } catch (_) {
    return null;
  }
}

/**
 * Gửi thông báo đến Google FCM HTTP v1 API
 */
async function sendFcmV1Message(projectId, accessToken, targetToken, title, body, data) {
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const payload = {
    message: {
      token: targetToken,
      notification: {
        title: title,
        body: body,
      },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: "high",
        notification: {
          channel_id: "keep_link_shared_sfx_v1",
          sound: "sfx_notification",
          default_sound: false,
          notification_priority: "PRIORITY_HIGH",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: "sfx_notification.wav",
            badge: 1,
          },
        },
      },
    },
  };

  const response = await fetch(fcmUrl, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  const resJson = await response.json();
  if (!response.ok) {
    throw new Error(`FCM Error [${response.status}]: ${JSON.stringify(resJson)}`);
  }
  return resJson;
}

/**
 * Tạo Google OAuth2 Access Token từ Service Account bằng Web Crypto API
 */
async function getGoogleAccessToken(clientEmail, privateKeyPem) {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && tokenExpiresAt > now + 300) {
    return cachedAccessToken;
  }

  const header = { alg: "RS256", typ: "JWT" };
  const claimSet = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/firebase.database",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaimSet = base64UrlEncode(JSON.stringify(claimSet));
  const unsignedJwt = `${encodedHeader}.${encodedClaimSet}`;

  const signature = await signRsaSha256(unsignedJwt, privateKeyPem);
  const jwt = `${unsignedJwt}.${signature}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  if (!tokenResponse.ok) {
    throw new Error(`Google Auth Token Error: ${JSON.stringify(tokenData)}`);
  }

  cachedAccessToken = tokenData.access_token;
  tokenExpiresAt = now + (tokenData.expires_in || 3600);
  return cachedAccessToken;
}

function base64UrlEncode(str) {
  const bytes = new TextEncoder().encode(str);
  let binary = "";
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function base64UrlEncodeBytes(bytes) {
  let binary = "";
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

/**
 * Ký số RS256 bằng private key PEM
 */
async function signRsaSha256(data, pemKey) {
  const cleanPem = pemKey
    .replace(/-----BEGIN (RSA )?PRIVATE KEY-----/g, "")
    .replace(/-----END (RSA )?PRIVATE KEY-----/g, "")
    .replace(/\\n/g, "")
    .replace(/\s+/g, "");

  const binaryDer = Uint8Array.from(atob(cleanPem), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    {
      name: "RSASSA-PKPKCS1-v1_5" in crypto.subtle ? "RSASSA-PKCS1-v1_5" : "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  const encoder = new TextEncoder();
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, encoder.encode(data));

  return base64UrlEncodeBytes(new Uint8Array(signature));
}
