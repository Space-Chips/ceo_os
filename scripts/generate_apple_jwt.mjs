// Generate the Apple "client_secret" JWT for the Supabase Apple OAuth provider.
//
// Apple requires this JWT to be signed with the .p8 private key, valid for at
// most 6 months. Supabase pastes it as the "Secret Key (for OAuth)".
//
// Usage:
//   cd scripts
//   npm install jsonwebtoken
//   APPLE_TEAM_ID=XXXXXXXXXX \
//   APPLE_KEY_ID=YYYYYYYYYY \
//   APPLE_SERVICES_ID=com.wakeapp.ceoos.signin \
//   APPLE_P8_PATH=/absolute/path/to/AuthKey_YYYYYYYYYY.p8 \
//   node generate_apple_jwt.mjs
//
// Output: a single line — the JWT. Copy it (Cmd+C from the terminal) and
// paste it into the Supabase Dashboard → Auth → Providers → Apple → "Secret
// Key (for OAuth)" field. Save.
//
// Reminder: regenerate every ~5 months (set a calendar alarm) — Apple expires
// these secrets after 6 months max.

import fs from 'node:fs';
import jwt from 'jsonwebtoken';

const teamId = process.env.APPLE_TEAM_ID;
const keyId = process.env.APPLE_KEY_ID;
const servicesId = process.env.APPLE_SERVICES_ID;
const p8Path = process.env.APPLE_P8_PATH;

if (!teamId || !keyId || !servicesId || !p8Path) {
  console.error(
    'Missing env. Set APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_SERVICES_ID, APPLE_P8_PATH.'
  );
  process.exit(1);
}

if (!fs.existsSync(p8Path)) {
  console.error(`.p8 file not found at: ${p8Path}`);
  process.exit(1);
}

const privateKey = fs.readFileSync(p8Path, 'utf8');
const now = Math.floor(Date.now() / 1000);
const sixMonthsInSeconds = 180 * 24 * 60 * 60;

const token = jwt.sign(
  {
    iss: teamId,
    iat: now,
    exp: now + sixMonthsInSeconds,
    aud: 'https://appleid.apple.com',
    sub: servicesId,
  },
  privateKey,
  {
    algorithm: 'ES256',
    header: { kid: keyId, alg: 'ES256' },
  }
);

console.log(token);
