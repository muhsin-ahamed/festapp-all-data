import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

export const env = {
  PORT: process.env.PORT || '3000',
  SUPABASE_URL: process.env.SUPABASE_URL || '',
  SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  JWT_SECRET: process.env.JWT_SECRET || 'amia_fest_default_secret_key_2026',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '7d',
  CORS_ORIGIN: process.env.CORS_ORIGIN || '*',

  // Seed configuration
  CONTROLLER_USERNAME: process.env.CONTROLLER_USERNAME || 'ksams',
  CONTROLLER_PASSWORD: process.env.CONTROLLER_PASSWORD || 'Acsmr@7012',

  TEAM1_USERNAME: process.env.TEAM1_USERNAME || 'lsmht',
  TEAM1_PASSWORD: process.env.TEAM1_PASSWORD || 'Lthlsm@9947',
  TEAM1_NAME: process.env.TEAM1_NAME || 'Apex',
  TEAM1_CODE: process.env.TEAM1_CODE || 'T-APEX',

  TEAM2_USERNAME: process.env.TEAM2_USERNAME || 'halans',
  TEAM2_PASSWORD: process.env.TEAM2_PASSWORD || 'fshlt@4792',
  TEAM2_NAME: process.env.TEAM2_NAME || 'Telos',
  TEAM2_CODE: process.env.TEAM2_CODE || 'T-TELOS',

  JURY_USERNAME: process.env.JURY_USERNAME || 'jury1',
  JURY_PASSWORD: process.env.JURY_PASSWORD || 'jury123',

  TV_USERNAME: process.env.TV_USERNAME || 'tv',
  TV_PASSWORD: process.env.TV_PASSWORD || 'tv123',
};
