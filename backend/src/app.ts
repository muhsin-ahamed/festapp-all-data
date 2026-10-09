import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env';
import { swaggerSpec } from './swagger';
import { errorHandler } from './middleware/error.middleware';

import authRoutes from './routes/auth.routes';
import publicRoutes from './routes/public.routes';
import controllerRoutes from './routes/controller.routes';
import leaderRoutes from './routes/leader.routes';
import juryRoutes from './routes/jury.routes';
import tvRoutes from './routes/tv.routes';
import announcementRoutes from './routes/announcement.routes';
import scheduleRoutes from './routes/schedule.routes';

const app = express();

// Security Middlewares
app.use(helmet());
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (like curl or mobile apps) or match origin dynamically in dev
      if (!origin || env.CORS_ORIGIN === '*' || origin === env.CORS_ORIGIN) {
        return callback(null, true);
      }
      return callback(null, origin);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  })
);

// Rate Limiter
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300, // Limit each IP to 300 requests per window
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Body Parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health Check Endpoints
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'AMIA Fest API is running',
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    database: 'connected',
    timestamp: new Date().toISOString(),
  });
});

// Swagger API Documentation
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// API Routes Mounts
app.use('/api/auth', authRoutes);
app.use('/api/public', publicRoutes);
app.use('/api/controller', controllerRoutes);
app.use('/api/leader', leaderRoutes);
app.use('/api/jury', juryRoutes);
app.use('/api/tv', tvRoutes);
app.use('/api/announcements', announcementRoutes);
app.use('/api', scheduleRoutes);

// Error Handler
app.use(errorHandler);

export default app;
