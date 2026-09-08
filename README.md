# AMIA FEST (Askesis)

A full-stack Arts Fest Management System featuring a Flutter client and a high-performance Node.js / Express REST API backend integrated with Supabase PostgreSQL.

## Backend & API Endpoint

- **Production API Base URL**: `https://festapp-all-data.onrender.com/api`
- **Swagger Documentation**: `https://festapp-all-data.onrender.com/api/docs`
- **Live Server**: Hosted on Render (`singapore` region)
- **Database**: Supabase PostgreSQL

## Tech Stack

- **Frontend**: Flutter (Riverpod, GoRouter, Google Fonts, QR Flutter, Mobile Scanner, File Picker, Syncfusion Excel)
- **Backend**: Node.js, Express, TypeScript, Zod, Swagger (OpenAPI 3.0)
- **Database**: Supabase PostgreSQL with custom SQL schema & views

## Environment Variables

### Backend (`backend/.env`)
```env
PORT=10000
NODE_ENV=production
SUPABASE_URL=<supabase_url>
SUPABASE_SERVICE_ROLE_KEY=<service_role_key>
JWT_SECRET=<jwt_secret>
JWT_EXPIRES_IN=7d
CORS_ORIGIN=*
```

### Flutter Client
The Flutter application automatically connects to `https://festapp-all-data.onrender.com/api` by default.
To override for local development:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:10000/api
```
