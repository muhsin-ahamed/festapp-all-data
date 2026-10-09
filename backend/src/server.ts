import app from './app';
import { env } from './config/env';
import { AuthService } from './services/auth.service';
import { logger } from './utils/logger';

const authService = new AuthService();

async function bootstrap() {
  try {
    // Seed default accounts
    await authService.seedDefaultUsers();
    logger.info('Database seed initialization complete.');

    const port = parseInt(env.PORT, 10);
    app.listen(port, () => {
      logger.info(`🚀 AMIA FEST Backend REST API running on http://localhost:${port}`);
      logger.info(`📖 Swagger Docs available at http://localhost:${port}/api/docs`);
    });
  } catch (error: any) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

bootstrap();
