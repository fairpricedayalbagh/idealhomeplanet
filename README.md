# Ideal Home Planet — Employee Management System

**Single store · Single DB · Flutter app · Node.js backend**
**QR-based attendance · Auto salary generation · Leave management · Admin + Employee views**

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Mobile App | Flutter (Riverpod + GoRouter) |
| Backend | Node.js + Express + TypeScript |
| ORM | Prisma |
| Database | PostgreSQL |
| Auth | JWT (access + refresh tokens stored in DB) |
| QR (Flutter) | `mobile_scanner` |
| QR (Backend) | `qrcode` npm |
| Cron | `node-cron` (standalone) / Vercel Cron (serverless) |
| Landing Page | Vite (static HTML/CSS) |
| Hosting | Vercel (API + Web as single project) |

---

## Monorepo Structure

```
IdealHomePlanet/
├── package.json                ← pnpm workspace root
├── pnpm-workspace.yaml         ← declares apps/* and packages/*
├── vercel.json                 ← routes /api/* → serverless, rest → static web
├── .gitignore
├── .nvmrc                      ← Node 20
│
├── packages/
│   └── shared/                 ← @ihp/shared — shared types, validators, constants
│       └── src/
│           ├── types/          ← auth, attendance, employee, salary, leave, api-response
│           ├── constants/      ← roles, error codes
│           └── validators/     ← Zod schemas shared between API and clients
│
├── apps/
│   ├── api/                    ← @ihp/api — Node.js + Express + Prisma
│   │   ├── api/index.ts        ← Vercel serverless entry (exports Express app)
│   │   ├── src/
│   │   │   ├── app.ts          ← Express app (no listen — works on Vercel + standalone)
│   │   │   ├── server.ts       ← Standalone entry (listen on port + cron jobs)
│   │   │   ├── config/env.ts   ← Environment variable config
│   │   │   ├── middleware/     ← JWT auth, rate limiter, error handler
│   │   │   ├── routes/         ← auth, qr, attendance, employee, salary, leave, holiday, audit
│   │   │   ├── services/       ← Business logic per domain
│   │   │   ├── jobs/           ← Cron jobs (QR rotation, auto-checkout, salary generation)
│   │   │   └── utils/          ← Prisma singleton, JWT helpers, PIN hashing
│   │   └── prisma/
│   │       ├── schema.prisma   ← Full database schema
│   │       └── seed.ts         ← Seeds admin user + store config
│   │
│   ├── web/                    ← @ihp/web — Vite static landing page
│   │   ├── index.html          ← APK download page (dark theme)
│   │   ├── vite.config.ts      ← Dev server with API proxy
│   │   └── src/
│   │       ├── style.css
│   │       └── main.ts
│   │
│   └── mobile/                 ← Flutter app (ideal_home_planet)
│       ├── pubspec.yaml
│       └── lib/
│           ├── main.dart
│           ├── app/            ← router, theme
│           ├── core/           ← api client, auth provider, models
│           ├── features/       ← auth, admin, employee screens
│           └── shared/         ← reusable widgets, utils
```

---

## Getting Started

### Prerequisites

- **Node.js** >= 20
- **pnpm** >= 9 (`npm install -g pnpm`)
- **PostgreSQL** running locally or a hosted instance
- **Flutter** >= 3.x (for mobile development)

### 1. Install Dependencies

```bash
pnpm install
```

### 2. Set Up the Database

Copy the example env file and fill in your PostgreSQL connection string:

```bash
cp apps/api/.env.example apps/api/.env
```

Edit `apps/api/.env`:

```env
DATABASE_URL=postgresql://user:pass@localhost:5432/employee_mgmt
JWT_SECRET=your-random-256-bit-secret
JWT_REFRESH_SECRET=another-random-secret
```

Run migrations and seed:

```bash
pnpm db:generate
pnpm db:migrate
pnpm db:seed
```

The seed creates:
- **Store config**: "Ideal Home Planet" with default settings
- **Admin user**: phone `9999999999`, PIN `1234`

### 3. Run Locally

Run API and web dev servers (in separate terminals):

```bash
pnpm dev:api    # Express on http://localhost:3000
pnpm dev:web    # Vite on http://localhost:5173 (proxies /api to :3000)
```

For the Flutter app:

```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## Available Scripts

| Command | Description |
|---------|-------------|
| `pnpm dev:api` | Start API dev server with hot reload |
| `pnpm dev:web` | Start landing page dev server |
| `pnpm build` | Build all packages |
| `pnpm build:api` | Build API only |
| `pnpm build:web` | Build landing page only |
| `pnpm db:generate` | Generate Prisma client |
| `pnpm db:migrate` | Run database migrations |
| `pnpm db:seed` | Seed database with admin user |
| `pnpm db:studio` | Open Prisma Studio (DB browser) |
| `pnpm lint` | Lint all packages |
| `pnpm clean` | Remove all dist/ and node_modules/ |

---

## Vercel Deployment

Both the API and landing page deploy as a **single Vercel project**.

### How It Works

- `vercel.json` at the repo root configures everything
- `/api/*` requests are routed to `apps/api/api/index.ts` (serverless function)
- All other requests serve static files from `apps/web/dist/`
- Cron jobs are configured via Vercel Cron (since `node-cron` doesn't work in serverless)

### Vercel Cron Jobs

| Schedule | Endpoint | Purpose |
|----------|----------|---------|
| Every day at midnight | `/api/cron/rotate-qr` | Generate new daily QR token |
| Every day at 23:59 | `/api/cron/auto-checkout` | Auto-checkout forgotten checkouts |
| 1st of month at 2 AM | `/api/cron/generate-salary` | Generate salary slips for previous month |

### Deploy Steps

1. Connect the repo to Vercel
2. Set environment variables in Vercel dashboard (`DATABASE_URL`, `JWT_SECRET`, etc.)
3. Deploy — Vercel auto-detects the monorepo config

---

## API Endpoints

### Auth
| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/login` | Public | Phone + PIN → JWT (locks after 5 failed attempts) |
| POST | `/api/auth/refresh` | Any | Refresh token (validated against DB) |
| POST | `/api/auth/logout` | Any | Revoke refresh token |

### QR (Admin only)
| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| GET | `/api/qr/today` | Admin | Get today's QR as base64 PNG |
| POST | `/api/qr/rotate` | Admin | Force-rotate QR now |

### Attendance
| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| POST | `/api/attendance/mark` | Employee | Scan QR → mark check-in/out |
| POST | `/api/attendance/manual` | Admin | Add/correct attendance manually |
| GET | `/api/attendance/my` | Employee | My attendance history |
| GET | `/api/attendance/all` | Admin | All employees' attendance (with date range filter) |
| GET | `/api/attendance/today` | Admin | Today's live attendance board |
| GET | `/api/attendance/report` | Admin | Monthly attendance summary report |

### Employees (Admin only)
| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| GET | `/api/employees` | Admin | List all employees |
| POST | `/api/employees` | Admin | Add employee (with salary, shift, off-days, leave balance) |
| PUT | `/api/employees/:id` | Admin | Edit employee config |
| PUT | `/api/employees/:id/shift` | Admin | Update shift times only |
| PUT | `/api/employees/:id/salary` | Admin | Update salary config only |
| PUT | `/api/employees/:id/offdays` | Admin | Update weekly off-days only |
| PUT | `/api/employees/:id/reset-pin` | Admin | Reset employee PIN |
| DELETE | `/api/employees/:id` | Admin | Deactivate employee |

### Salary
| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| GET | `/api/salary/my` | Employee | My salary slips |
| GET | `/api/salary/all` | Admin | All salary slips (with filters) |
| POST | `/api/salary/generate` | Admin | Trigger salary generation |
| PUT | `/api/salary/:id/pay` | Admin | Mark slip as paid (with payment mode) |
| PUT | `/api/salary/:id/bonus` | Admin | Add ad-hoc bonus to a slip |
| GET | `/api/salary/:id/pdf` | Any | Download salary slip as PDF |

### Leave
| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| POST | `/api/leave/apply` | Employee | Apply for leave |
| GET | `/api/leave/my` | Employee | My leave history + balances |
| GET | `/api/leave/all` | Admin | All leave requests (with status filter) |
| GET | `/api/leave/pending` | Admin | Pending leave requests |
| PUT | `/api/leave/:id/approve` | Admin | Approve leave request |
| PUT | `/api/leave/:id/reject` | Admin | Reject leave request (with reason) |

### Holidays
| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| GET | `/api/holidays` | Any | List holidays for the year |
| POST | `/api/holidays` | Admin | Add a holiday |
| DELETE | `/api/holidays/:id` | Admin | Remove a holiday |

### Audit Log
| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| GET | `/api/audit-log` | Admin | View audit trail (with filters) |

---

## Database Schema

The full Prisma schema is at `apps/api/prisma/schema.prisma`. Key models:

| Model | Purpose |
|-------|---------|
| **User** | Employees + admins with salary config, shift schedule, leave balances, payment info |
| **Attendance** | Check-in/out records (QR-scanned or manual) |
| **QrToken** | Daily/hourly rotating QR tokens |
| **SalarySlip** | Monthly salary with deduction breakdown, bonus, payment status |
| **Leave** | Leave requests with approval flow |
| **Holiday** | Store-wide holidays |
| **RefreshToken** | JWT refresh tokens stored in DB for revocation |
| **AuditLog** | Admin action trail |
| **StoreConfig** | Store-level defaults (shift, leave, timezone, auto-checkout) |

---

## QR Attendance Flow

1. Cron job generates a new `QrToken` daily (or hourly) with a random UUID
2. Admin device displays the QR code on a counter screen (fullscreen, stays awake)
3. Employee opens app → taps "Check In" → scans QR
4. Backend validates: token exists, not expired, date matches, no duplicate check-in
5. Records attendance with timestamp
6. Check-out follows the same flow

### Edge Cases Handled

- **Forgotten checkout**: Auto-checkout cron runs at 23:59, inserts CHECK_OUT at shift end
- **Manual correction**: Admin can add/correct attendance when QR scan fails
- **QR offline**: Admin device caches last QR locally, shows fallback if network is down
- **Anti-cheat**: Cryptographically random tokens, optional device binding, server-side timestamp validation

---

## Salary Calculation

Auto-generated on the 1st of each month (or manually triggered):

1. Calculate working days (excluding off-days + holidays)
2. Prorate for mid-month joining
3. Account for approved leaves
4. Pair CHECK_IN/CHECK_OUT to get hours worked
5. Track late arrivals and overtime
6. Calculate gross based on salary type (monthly fixed or hourly)
7. Build deduction breakdown (late penalty, absent, advance recovery, unpaid leave)
8. Net = gross + bonus - deductions
9. Generate slip with full transparency

---

## Environment Variables

```env
DATABASE_URL=postgresql://user:pass@localhost:5432/employee_mgmt
JWT_SECRET=your-256-bit-secret
JWT_REFRESH_SECRET=another-secret
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d
PORT=3000
TZ=Asia/Kolkata
PIN_MAX_ATTEMPTS=5
PIN_LOCKOUT_MINS=30
CRON_SECRET=vercel-cron-auth-secret
```

---

## Build Order

### Sprint 1 — Foundation (Week 1-2)
- Prisma schema + migrations
- Auth endpoints (login with lockout, refresh with DB, logout)
- Flutter auth screens + Riverpod auth state
- Role-based routing shell
- Employee CRUD (admin) with full form
- Holiday CRUD

### Sprint 2 — QR + Attendance (Week 3-4)
- QR generation + cron rotation
- Admin QR display screen with offline caching
- Employee QR scan screen
- Attendance marking with validation
- Manual attendance (admin)
- Auto-checkout cron
- Attendance board + calendar

### Sprint 3 — Leave + Salary (Week 5-6)
- Leave application + approval flow
- Employee leave screens
- Admin leave management
- Salary calculation with leave/holiday/proration/breakdown
- Salary management screens
- PDF generation

### Sprint 4 — Security + Polish (Week 7)
- PIN brute-force lockout
- Refresh token revocation
- Audit logging
- Late penalty logic
- Push notifications
- CSV export
- Error handling, loading states
- Testing + deploy

---

## License

Private — Ideal Home Planet
