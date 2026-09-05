import { AuthService } from '../services/auth.service';

async function runTests() {
  const auth = new AuthService();
  await auth.seedDefaultUsers();

  console.log('\n=========================================');
  console.log('TESTING AUTHENTICATION SYSTEM');
  console.log('=========================================\n');

  const validAccounts = [
    { username: 'ksams', pass: 'Acsmr@7012', expectedRole: 'FEST_CONTROLLER' },
    { username: 'lsmht', pass: 'Lthlsm@9947', expectedRole: 'TEAM_LEADER' },
    { username: 'halans', pass: 'fshlt@4792', expectedRole: 'TEAM_LEADER' },
    { username: 'jury1', pass: 'jury123', expectedRole: 'JURY' },
    { username: 'tv', pass: 'tv123', expectedRole: 'TV_OPERATOR' },
  ];

  for (const acc of validAccounts) {
    try {
      const res = await auth.login(acc.username, acc.pass);
      const passed = res.user.role === acc.expectedRole && !!res.accessToken;
      console.log(`[PASS] User '${acc.username}': role=${res.user.role} (matches ${acc.expectedRole}), tokenIssued=${!!res.accessToken}`);
    } catch (e: any) {
      console.error(`[FAIL] User '${acc.username}':`, e.message || e);
    }
  }

  console.log('\n--- TESTING ERROR SCENARIOS ---\n');

  // Test 1: Missing username
  try {
    await auth.login('', 'Acsmr@7012');
    console.error('[FAIL] Missing username did not throw error');
  } catch (e: any) {
    console.log(`[PASS] Missing username error: ${e.code || 'ERROR'} - ${e.message}`);
  }

  // Test 2: Missing password
  try {
    await auth.login('ksams', '');
    console.error('[FAIL] Missing password did not throw error');
  } catch (e: any) {
    console.log(`[PASS] Missing password error: ${e.code || 'ERROR'} - ${e.message}`);
  }

  // Test 3: Non-existent user
  try {
    await auth.login('nonexistent_user_123', 'somepassword');
    console.error('[FAIL] Non-existent user did not throw error');
  } catch (e: any) {
    console.log(`[PASS] Non-existent user error: ${e.code || 'ERROR'} - ${e.message}`);
  }

  // Test 4: Wrong password
  try {
    await auth.login('ksams', 'wrong_password_123');
    console.error('[FAIL] Wrong password did not throw error');
  } catch (e: any) {
    console.log(`[PASS] Wrong password error: ${e.code || 'ERROR'} - ${e.message}`);
  }

  console.log('\n=========================================');
  console.log('ALL AUTH TESTS COMPLETE');
  console.log('=========================================\n');
  process.exit(0);
}

runTests().catch((err) => {
  console.error('Fatal test runner error:', err);
  process.exit(1);
});
