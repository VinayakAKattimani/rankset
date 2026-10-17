// Grant or revoke admin access. Run by the project owner from a trusted machine.
//   node scripts/set-admin.js grant  you@example.com  --project=my-project-id
//   node scripts/set-admin.js revoke you@example.com  --project=my-project-id
//   node scripts/set-admin.js list                    --project=my-project-id
// The admin must have signed in once (so the Auth user exists) and have a VERIFIED email.
import { getAuth } from 'firebase-admin/auth';
import { initAdmin, parseArgs } from './lib/admin-init.js';

const { flags, positional } = parseArgs(process.argv.slice(2));
const [action, email] = positional;
initAdmin(flags.project);
const auth = getAuth();

async function main() {
  if (action === 'list') {
    let token;
    do {
      const page = await auth.listUsers(1000, token);
      for (const u of page.users) if (u.customClaims?.admin === true) console.log(`${u.email}  (uid ${u.uid})`);
      token = page.pageToken;
    } while (token);
    return;
  }
  if (!['grant', 'revoke'].includes(action) || !email) {
    console.error('Usage: node scripts/set-admin.js <grant|revoke|list> <email> --project=<id>');
    process.exit(1);
  }
  const user = await auth.getUserByEmail(email);
  if (action === 'grant') {
    if (!user.emailVerified) {
      console.error(`Refusing: ${email} has not verified their email. Rules require email_verified for admins.`);
      process.exit(1);
    }
    await auth.setCustomUserClaims(user.uid, { ...(user.customClaims ?? {}), admin: true });
    console.log(`Granted admin to ${email}. They must sign out and sign in again (or wait up to 1 hour).`);
  } else {
    const { admin, ...rest } = user.customClaims ?? {};
    await auth.setCustomUserClaims(user.uid, rest);
    await auth.revokeRefreshTokens(user.uid);
    console.log(`Revoked admin from ${email} and signed them out everywhere. Existing tokens may work for up to 1 hour.`);
  }
}

main().catch((e) => { console.error(e.message); process.exit(1); });
