import { AuthService } from '../services/auth.service';
import { logger } from '../utils/logger';

async function runSeed() {
  logger.info('[SEED] Initializing default system accounts...');
  const authService = new AuthService();
  await authService.seedDefaultUsers();
  logger.info('[SEED] Completed seeding initial users (ksams, lsmht, halans, jury1, tv).');
  process.exit(0);
}

runSeed().catch((err) => {
  logger.error('[SEED] Error during seeding:', err);
  process.exit(1);
});
