# Employee Management System — Architecture Spec

**Single store · Single DB · Flutter app · Node.js backend**
**QR-based attendance · Auto salary generation · Admin + Employee views**

---

## 1. System overview

One Flutter app with role-based routing (admin vs employee). One Node.js + Express backend. One PostgreSQL database. Admin device sits on the counter showing a daily-rotating QR code. Employees scan it with their phone to mark check-in/check-out.

---

## 2. Tech stack

| Layer | Choice | Why |
|-------|--------|-----|
| Mobile app | **Flutter** | Single codebase, your existing expertise |
| State management | **Riverpod** | Scales cleanly for role-based views |
| Backend | **Node.js + Express** | Fast to build, great ecosystem |
| ORM | **Prisma** | Type-safe, auto-migrations, clean schema |
| Database | **PostgreSQL** | Reliable, free on Supabase/Railway |
| Auth | **JWT (access + refresh)** | Stateless, role claim embedded |
| QR library (Flutter) | `mobile_scanner` | Fast, reliable camera scanning |
| QR library (Backend) | `qrcode` npm | Generates QR as base64 PNG |
| Cron | `node-cron` | In-process scheduled jobs |
| Hosting | **Railway / Render** | Free tier, easy deploy |

---

## 3. Database schema (Prisma)

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum Role {
  ADMIN
  EMPLOYEE
}

enum AttendanceType {
  CHECK_IN
  CHECK_OUT
}

enum SalaryType {
  HOURLY
  MONTHLY
}

enum LeaveType {
  SICK
  CASUAL
  PAID
  UNPAID
}

enum LeaveStatus {
  PENDING
  APPROVED
  REJECTED
}

enum SalarySlipStatus {
  GENERATED
  PAID
  CANCELLED
}

enum PaymentMode {
  CASH
  BANK
  UPI
}

model User {
  id              String       @id @default(uuid())
  name            String
  phone           String       @unique
  email           String?      // optional, for sending salary slips / notifications
  pin             String       // hashed 4-digit PIN
  pinAttempts     Int          @default(0)   // failed PIN attempts (lockout after 5)
  lockedUntil     DateTime?    // account locked until this time after 5 failed attempts
  role            Role         @default(EMPLOYEE)
  isActive        Boolean      @default(true)
  profilePhoto    String?      // URL to stored photo
  designation     String?      // e.g. "Cashier", "Floor Manager", "Delivery"
  dateOfBirth     DateTime?    @db.Date
  dateOfJoining   DateTime     @default(now()) @db.Date  // critical for salary proration
  address         String?
  emergencyName   String?      // emergency contact name
  emergencyPhone  String?      // emergency contact phone
  createdAt       DateTime     @default(now())
  updatedAt       DateTime     @updatedAt

  // ── Salary config (set by admin) ──
  salaryType      SalaryType   @default(MONTHLY)
  monthlySalary   Float?       // ₹ fixed per month (if MONTHLY)
  hourlyRate      Float?       // ₹ per hour (if HOURLY)
  bankAccount     String?      // bank account number
  bankIfsc        String?      // IFSC code
  upiId           String?      // UPI ID for digital payment

  // ── Leave balance (set by admin, deducted on approval) ──
  sickLeaveBalance   Int       @default(12)  // per year
  casualLeaveBalance Int       @default(12)  // per year
  paidLeaveBalance   Int       @default(15)  // per year (earned leave)

  // ── Shift schedule (set by admin per employee) ──
  shiftStart      String       @default("09:00")  // expected login time "HH:mm"
  shiftEnd        String       @default("18:00")  // expected logout time "HH:mm"
  graceMins       Int          @default(15)        // minutes late grace before penalty

  // ── Weekend / off-days (set by admin) ──
  // Stored as JSON array of day numbers: [0,6] = Sun,Sat
  // 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
  weeklyOffDays   Json         @default("[0]")     // default: Sunday off

  attendances     Attendance[]
  salarySlips     SalarySlip[]
  leaves          Leave[]
  refreshTokens   RefreshToken[]
}

model Attendance {
  id         String         @id @default(uuid())
  userId     String
  type       AttendanceType
  timestamp  DateTime       @default(now())
  qrTokenId  String?        // which QR was scanned (null for manual entries)
  deviceId   String?        // employee's device fingerprint
  isManual   Boolean        @default(false)  // true if admin added manually
  addedBy    String?        // admin userId who added manual entry
  note       String?        // reason for manual entry / correction

  user       User           @relation(fields: [userId], references: [id])
  qrToken    QrToken?       @relation(fields: [qrTokenId], references: [id])

  @@index([userId, timestamp])
}

model QrToken {
  id        String     @id @default(uuid())
  token     String     @unique   // random string, rotated daily
  date      DateTime   @db.Date  // which day this token is for
  expiresAt DateTime             // end of day
  createdAt DateTime   @default(now())

  attendances Attendance[]

  @@index([date])
}

model SalarySlip {
  id              String           @id @default(uuid())
  userId          String
  month           Int              // 1-12
  year            Int
  totalDays       Int              // days worked
  totalHours      Float            // hours worked
  overtimeHours   Float            @default(0)  // hours beyond shift end
  daysAbsent      Int              @default(0)
  daysLate        Int              @default(0)
  leaveDays       Int              @default(0)  // approved leave days
  grossAmount     Float
  // ── Deduction breakdown (JSON for transparency) ──
  // e.g. {"late_penalty": 500, "absent_deduction": 1200, "advance_recovery": 2000}
  deductionBreakdown Json          @default("{}")
  deductions      Float            @default(0)  // total deductions
  bonus           Float            @default(0)  // ad-hoc bonus (festival, performance)
  advanceDeduction Float           @default(0)  // salary advance recovery
  netAmount       Float
  status          SalarySlipStatus @default(GENERATED)
  paymentMode     PaymentMode?     // how it was paid
  paidAt          DateTime?        // when it was actually paid
  generatedAt     DateTime         @default(now())

  user            User             @relation(fields: [userId], references: [id])

  @@unique([userId, month, year])
}

model Leave {
  id          String      @id @default(uuid())
  userId      String
  leaveType   LeaveType
  startDate   DateTime    @db.Date
  endDate     DateTime    @db.Date
  totalDays   Int         // number of leave days (excluding off-days)
  reason      String
  status      LeaveStatus @default(PENDING)
  reviewedBy  String?     // admin userId who approved/rejected
  reviewedAt  DateTime?
  reviewNote  String?     // admin's note on approval/rejection
  createdAt   DateTime    @default(now())

  user        User        @relation(fields: [userId], references: [id])

  @@index([userId, startDate])
}

model Holiday {
  id          String   @id @default(uuid())
  name        String   // e.g. "Diwali", "Independence Day"
  date        DateTime @db.Date
  isOptional  Boolean  @default(false) // optional holidays vs mandatory
  createdAt   DateTime @default(now())

  @@unique([date])
}

model RefreshToken {
  id          String   @id @default(uuid())
  userId      String
  token       String   @unique
  expiresAt   DateTime
  createdAt   DateTime @default(now())
  revokedAt   DateTime? // null = active, set = revoked

  user        User     @relation(fields: [userId], references: [id])

  @@index([userId])
}

model AuditLog {
  id          String   @id @default(uuid())
  userId      String   // who performed the action
  action      String   // e.g. "EMPLOYEE_CREATED", "SALARY_REGENERATED", "MANUAL_ATTENDANCE"
  entityType  String   // e.g. "User", "Attendance", "SalarySlip"
  entityId    String   // ID of affected record
  details     Json?    // before/after snapshot or extra context
  createdAt   DateTime @default(now())

  @@index([userId, createdAt])
  @@index([entityType, entityId])
}

model StoreConfig {
  id          String  @id @default("default")
  storeName   String
  timezone    String  @default("Asia/Kolkata")  // IANA timezone for correct day boundaries
  qrRotation  String  @default("daily") // "daily" | "hourly"

  // ── Default shift (used as template when creating new employees) ──
  defaultShiftStart  String  @default("09:00")
  defaultShiftEnd    String  @default("18:00")
  defaultGraceMins   Int     @default(15)
  defaultWeeklyOff   Json    @default("[0]")  // Sunday

  // ── Auto-checkout config ──
  autoCheckoutEnabled Boolean @default(true)
  autoCheckoutTime    String  @default("23:59")  // if employee forgets to check out

  // ── Default leave balances (template for new employees) ──
  defaultSickLeave   Int     @default(12)
  defaultCasualLeave Int     @default(12)
  defaultPaidLeave   Int     @default(15)
}
```

---

## 4. QR attendance flow

### How it works

1. **Cron job runs at midnight** (or store opening time) → generates a new `QrToken` with a random UUID, stores it in DB, marks previous token expired.
2. **Admin device** (a tablet/old phone on the counter) stays logged in as admin, shows a screen that polls `GET /api/qr/today` every 30 seconds and renders the QR code.
3. **Employee opens app** → taps "Check In" → camera opens → scans QR.
4. **App sends** `POST /api/attendance/mark` with `{ qrToken, type: "CHECK_IN" }`.
5. **Backend validates**:
   - Token exists and hasn't expired
   - Token date matches today
   - User hasn't already checked in without checking out
   - (Optional) Device fingerprint matches registered device
6. **Records attendance** in DB with timestamp.
7. **Check-out** follows the same flow with `type: "CHECK_OUT"`.

### Anti-cheat measures

- QR contains a **cryptographically random token**, not a static string — can't be shared via screenshot (rotates daily)
- Optional: **hourly rotation** for higher security (configurable in `StoreConfig`)
- Optional: **device binding** — first scan registers device ID, subsequent scans must match
- Backend validates token freshness server-side, app cannot fake timestamps

### Edge case: Forgotten checkout

A cron job runs at `StoreConfig.autoCheckoutTime` (default 23:59):
1. Find all employees who have a CHECK_IN today but no CHECK_OUT
2. Auto-insert a CHECK_OUT with `timestamp = shiftEnd`, `isManual = true`, `note = "Auto-checkout: employee forgot to check out"`
3. This ensures salary calculation is never broken by missing checkout

### Edge case: Manual attendance correction

Admin can add/edit attendance via `POST /api/attendance/manual` when:
- Employee's phone is dead or camera broken
- QR scanner failed
- Retroactive correction needed
- These entries have `isManual = true` and `addedBy = adminUserId`

### Edge case: QR offline fallback

If the admin device can't fetch the new QR (network down):
- The app caches the last fetched QR locally
- If the cached QR's date matches today, it continues displaying
- If it's a new day and network is down, the screen shows "No QR available — use manual attendance"

### QR payload format

```json
{
  "store": "default",
  "token": "a1b2c3d4-e5f6-...",
  "date": "2026-03-22"
}
```

---

## 5. Salary auto-generation

### Logic

Cron runs on the **1st of every month at 2 AM** for the previous month:

```
For each active employee:
  1. Get employee's weeklyOffDays, shiftStart, shiftEnd, graceMins, dateOfJoining
  2. Fetch all Holidays for the month
  3. Calculate workingDaysInMonth = total days minus employee's off-days minus holidays
  4. If employee joined mid-month: prorate workingDaysInMonth from dateOfJoining
  5. Fetch all approved Leaves for this employee in the month
  6. Query all CHECK_IN / CHECK_OUT pairs for the month
  7. For each working day (that is not a holiday or approved leave):
     - Pair CHECK_IN + CHECK_OUT to get hours worked
     - If CHECK_IN > shiftStart + graceMins → mark as LATE
     - If no attendance on a working day and no approved leave → mark as ABSENT
     - If hours worked > shiftHours → record overtime hours
  8. Calculate:
     - If salaryType == HOURLY:
         grossAmount = totalHours × hourlyRate
     - If salaryType == MONTHLY:
         perDayRate = monthlySalary / workingDaysInMonth
         grossAmount = (daysPresent + paidLeaveDays) × perDayRate
  9. Build deductionBreakdown:
     - late_penalty: calculated per late day (see below)
     - absent_deduction: absentDays × perDayRate
     - advance_recovery: any pending advance to recover
     - unpaid_leave: unpaidLeaveDays × perDayRate
  10. totalDeductions = sum of all deduction items
  11. netAmount = grossAmount + bonus - totalDeductions
  12. Insert SalarySlip record with full breakdown
```

### Salary proration (mid-month joining)

```
If employee.dateOfJoining falls within the salary month:
  effectiveStartDate = dateOfJoining (not 1st of month)
  workingDaysInMonth = count only from effectiveStartDate to end of month
  (excluding off-days and holidays)
```

### Overtime tracking

```
For each CHECK_OUT on a working day:
  expectedEnd = employee.shiftEnd
  If CHECK_OUT time > expectedEnd:
    overtimeMinutes += (CHECK_OUT - expectedEnd)

  // Overtime is recorded on the SalarySlip for visibility
  // Whether overtime is PAID depends on admin config (future enhancement)
  // For now, overtime is tracked but not auto-compensated
```

### Late penalty logic (uses per-employee shift config)

```
For each CHECK_IN on a working day:
  employeeShiftStart = employee.shiftStart  // e.g. "09:00"
  graceDeadline = shiftStart + employee.graceMins
  
  If CHECK_IN time > graceDeadline:
    lateMinutes = CHECK_IN - shiftStart
    If salaryType == HOURLY:
      penalty = (lateMinutes / 60) × hourlyRate × 0.5
    If salaryType == MONTHLY:
      penalty = (lateMinutes / 60) × (monthlySalary / workingDaysInMonth / shiftHours) × 0.5
```

### Weekend / off-day handling

Off-days are **per employee** — some staff might work Sundays but get Tuesdays off. The `weeklyOffDays` field stores a JSON array like `[0, 6]` (Sunday + Saturday off). The salary engine skips these days entirely — no attendance expected, no absent marking, no salary deduction.

### Admin can also trigger salary generation manually via:
`POST /api/salary/generate?month=3&year=2026`

---

## 6. API endpoints

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
| POST | `/api/employees` | Admin | Add employee (with salary, shift, off-days) |
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

### Holidays (Admin only)
| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| GET | `/api/holidays` | Any | List holidays for the year |
| POST | `/api/holidays` | Admin | Add a holiday |
| DELETE | `/api/holidays/:id` | Admin | Remove a holiday |

### Audit Log (Admin only)
| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| GET | `/api/audit-log` | Admin | View audit trail (with filters) |

---

## 7. Flutter app structure

```
lib/
├── main.dart
├── app/
│   ├── router.dart              // GoRouter with role-based guards
│   └── theme.dart               // Dark glassmorphic theme
├── core/
│   ├── api/
│   │   ├── dio_client.dart      // Dio + interceptors
│   │   └── endpoints.dart
│   ├── auth/
│   │   ├── auth_provider.dart   // Riverpod — JWT + role state
│   │   └── auth_guard.dart
│   └── models/
│       ├── user.dart
│       ├── attendance.dart
│       ├── salary_slip.dart
│       ├── leave.dart
│       ├── holiday.dart
│       └── qr_token.dart
├── features/
│   ├── auth/
│   │   └── login_screen.dart    // Phone + PIN entry
│   ├── admin/
│   │   ├── dashboard_screen.dart            // Today's stats + pending leaves badge
│   │   ├── qr_display_screen.dart           // Counter QR screen (fullscreen)
│   │   ├── employee_list_screen.dart
│   │   ├── employee_form_screen.dart        // Now includes leave balance config
│   │   ├── attendance_board_screen.dart      // Live who's in/out
│   │   ├── manual_attendance_screen.dart     // Add/correct attendance manually
│   │   ├── salary_management_screen.dart     // Now includes pay/bonus actions
│   │   ├── leave_management_screen.dart      // Approve/reject leave requests
│   │   ├── holiday_management_screen.dart    // Add/remove holidays
│   │   └── audit_log_screen.dart            // View system activity
│   └── employee/
│       ├── home_screen.dart            // Status + quick actions + leave balance
│       ├── scan_qr_screen.dart         // Camera → scan → mark
│       ├── my_attendance_screen.dart   // Calendar view
│       ├── my_salary_screen.dart       // List of salary slips
│       ├── apply_leave_screen.dart     // Leave application form
│       ├── my_leaves_screen.dart       // Leave history + balances
│       └── profile_screen.dart
└── shared/
    ├── widgets/
    │   ├── stat_card.dart
    │   ├── attendance_tile.dart
    │   ├── salary_slip_card.dart
    │   └── leave_status_badge.dart
    └── utils/
        └── date_helpers.dart
```

### Role-based routing

```dart
// router.dart — simplified
GoRouter(
  redirect: (context, state) {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return '/login';
    if (auth.role == Role.admin && state.uri.path.startsWith('/employee')) {
      return '/admin/dashboard';
    }
    if (auth.role == Role.employee && state.uri.path.startsWith('/admin')) {
      return '/employee/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    // Admin routes
    GoRoute(path: '/admin/dashboard', builder: ...),
    GoRoute(path: '/admin/qr', builder: ...),
    GoRoute(path: '/admin/employees', builder: ...),
    GoRoute(path: '/admin/attendance', builder: ...),
    GoRoute(path: '/admin/salary', builder: ...),
    GoRoute(path: '/admin/leaves', builder: ...),
    GoRoute(path: '/admin/holidays', builder: ...),
    GoRoute(path: '/admin/manual-attendance', builder: ...),
    GoRoute(path: '/admin/audit-log', builder: ...),
    // Employee routes
    GoRoute(path: '/employee/home', builder: ...),
    GoRoute(path: '/employee/scan', builder: ...),
    GoRoute(path: '/employee/attendance', builder: ...),
    GoRoute(path: '/employee/salary', builder: ...),
    GoRoute(path: '/employee/leaves', builder: ...),
    GoRoute(path: '/employee/apply-leave', builder: ...),
    GoRoute(path: '/employee/profile', builder: ...),
  ],
)
```

---

## 8. Screen-by-screen breakdown

### Admin screens

**1. Dashboard** — Today's snapshot
- Total employees count
- Present / absent / late counts
- Recent check-ins (live feed)
- Pending leave requests badge (with count)
- Quick action buttons: "Generate QR", "View Salary", "Add Employee"
- Upcoming holidays this month

**2. QR display (counter mode)** — Fullscreen, meant for counter device
- Large QR code centered
- Today's date
- Auto-refreshes when token rotates
- Stays awake (WakelockPlus)
- Minimal UI — just the QR and store name

**3. Employee list** — CRUD
- Search bar
- List with name, phone, role, status (active/inactive)
- Tap to edit, swipe to deactivate
- FAB to add new employee

**4. Employee form** — Add / Edit (the key admin config screen)
- **Basic info**: Name, phone, email (optional), PIN, designation, date of joining, active/inactive toggle
- **Profile photo**: Camera / gallery upload
- **Personal details**: Date of birth, address, emergency contact (name + phone)
- **Payment info**: Bank account + IFSC or UPI ID
- **Salary section**:
  - Toggle: Monthly fixed vs Hourly rate
  - If monthly → input field for ₹ amount
  - If hourly → input field for ₹/hr rate
- **Shift schedule section**:
  - Login time picker (e.g. 09:00 AM)
  - Logout time picker (e.g. 06:00 PM)
  - Grace period slider (5-30 mins, default 15)
- **Off-days section**:
  - 7-day toggle row: S M T W T F S
  - Tap to toggle each day on/off (highlighted = off-day)
  - Default: Sunday highlighted
- **Leave balance section**:
  - Sick leave: number input (default from StoreConfig)
  - Casual leave: number input
  - Paid leave: number input
- Save button validates all fields

**5. Attendance board** — Live view
- Date picker (defaults to today)
- List of employees with check-in/out times
- Color indicators: green (present), red (absent), amber (late)
- Export to CSV button

**6. Salary management**
- Month/year picker
- List of salary slips with net amount and status (Generated / Paid)
- "Generate salaries" button (for current/past month)
- Tap slip → detailed breakdown (with deduction breakdown: late penalty, absent, advance, etc.)
- "Mark as Paid" button with payment mode selector (Cash / Bank / UPI)
- "Add Bonus" button for ad-hoc bonuses

**7. Leave management**
- Tabs: Pending | Approved | Rejected | All
- Each card shows: employee name, leave type, dates, reason
- Approve / Reject buttons with optional note
- Leave balance summary per employee

**8. Holiday management**
- Calendar year view with holidays marked
- Add holiday: name + date + optional/mandatory toggle
- Delete holiday
- Holidays are visible to all employees

**9. Manual attendance**
- Employee selector (dropdown)
- Date picker
- Check-in / Check-out time pickers
- Reason text field (required)
- Submit creates attendance with `isManual = true`

**10. Audit log**
- Filterable list of all admin actions
- Shows: who, what action, which entity, when
- Filter by action type, date range, admin user

### Employee screens

**1. Home** — Personal dashboard
- Greeting with name
- Today's status: "Checked in at 9:12 AM" or "Not checked in"
- This month summary: days worked, hours, estimated salary
- Leave balance summary (sick / casual / paid remaining)
- Big "Scan QR" button
- Quick "Apply Leave" button

**2. Scan QR** — Camera screen
- Opens camera immediately
- Scans QR → auto-submits
- Success/error feedback with haptic
- Toggle between check-in and check-out

**3. My attendance** — Calendar view
- Monthly calendar with colored dots (present/absent/late/half-day/holiday/leave)
- Tap day to see check-in/out times
- Monthly summary at bottom
- Holidays marked distinctly on calendar

**4. My salary** — Slip list
- Month-wise list of salary slips with status badge (Generated / Paid)
- Tap → detailed breakdown (hours, rate, deductions breakdown, bonus, net)
- Download as PDF option

**5. My leaves**
- Leave balance cards: Sick (X remaining), Casual (X remaining), Paid (X remaining)
- Leave history with status badges (Pending / Approved / Rejected)
- "Apply Leave" button → opens leave form

**6. Apply leave**
- Leave type selector (Sick / Casual / Paid / Unpaid)
- Date range picker (start date, end date)
- Auto-calculates total days (excluding off-days)
- Reason text field (required)
- Shows remaining balance for selected type
- Submit button

**7. Profile**
- View name, phone, designation, date of joining
- Change PIN
- View payment info (bank/UPI)
- Upcoming holidays list

---

## 9. Backend project structure

```
server/
├── package.json
├── prisma/
│   └── schema.prisma
├── src/
│   ├── index.ts
│   ├── config/
│   │   └── env.ts
│   ├── middleware/
│   │   ├── auth.ts          // JWT verify + role check
│   │   ├── rateLimiter.ts
│   │   └── errorHandler.ts
│   ├── routes/
│   │   ├── auth.routes.ts
│   │   ├── qr.routes.ts
│   │   ├── attendance.routes.ts
│   │   ├── employee.routes.ts
│   │   ├── salary.routes.ts
│   │   ├── leave.routes.ts
│   │   ├── holiday.routes.ts
│   │   └── audit.routes.ts
│   ├── services/
│   │   ├── auth.service.ts
│   │   ├── qr.service.ts
│   │   ├── attendance.service.ts
│   │   ├── salary.service.ts
│   │   ├── leave.service.ts
│   │   ├── holiday.service.ts
│   │   └── audit.service.ts
│   ├── jobs/
│   │   ├── rotateQr.job.ts           // Daily QR rotation
│   │   ├── generateSalary.job.ts     // Monthly salary calc
│   │   └── autoCheckout.job.ts       // Forgotten checkout handler
│   └── utils/
│       ├── jwt.ts
│       └── hash.ts
└── tsconfig.json
```

---

## 10. Environment variables

```env
DATABASE_URL=postgresql://user:pass@host:5432/employee_mgmt
JWT_SECRET=your-256-bit-secret
JWT_REFRESH_SECRET=another-secret
JWT_ACCESS_EXPIRY=15m          # access token TTL
JWT_REFRESH_EXPIRY=7d          # refresh token TTL
PORT=3000
TZ=Asia/Kolkata                # server timezone (must match StoreConfig.timezone)
QR_ROTATION=daily              # "daily" | "hourly"
STORE_NAME=My Store
SALARY_CALC_DAY=1              # Day of month to auto-generate
PIN_MAX_ATTEMPTS=5             # lock account after N failed PIN attempts
PIN_LOCKOUT_MINS=30            # lockout duration in minutes
AUTO_CHECKOUT_TIME=23:59       # fallback checkout for forgotten checkouts
# Note: shift times, grace period, off-days, and leave balances are per-employee
# Defaults are configured in StoreConfig and used as templates
```

---

## 11. Build order (4 sprints)

### Sprint 1 — Foundation (Week 1-2)
- [ ] Prisma schema + migrations (all models including Leave, Holiday, AuditLog, RefreshToken)
- [ ] Auth endpoints (login with lockout, refresh with DB validation, logout)
- [ ] Flutter auth screens + Riverpod auth state
- [ ] Role-based routing shell
- [ ] Basic employee CRUD (admin) — full form with all new fields
- [ ] Holiday CRUD (admin)

### Sprint 2 — QR + Attendance (Week 3-4)
- [ ] QR generation endpoint + cron rotation
- [ ] Admin QR display screen (counter mode) with offline caching
- [ ] Employee QR scan screen (mobile_scanner)
- [ ] Attendance marking endpoint with validation
- [ ] Manual attendance endpoint (admin)
- [ ] Auto-checkout cron job
- [ ] Admin attendance board
- [ ] Employee attendance calendar (with holidays + leaves shown)

### Sprint 3 — Leave + Salary (Week 5-6)
- [ ] Leave application + approval flow (backend)
- [ ] Employee leave screens (apply, history, balances)
- [ ] Admin leave management screen
- [ ] Salary calculation service (with leave/holiday/proration/deduction breakdown)
- [ ] Monthly salary cron job
- [ ] Admin salary management screen (with pay/bonus actions)
- [ ] Employee salary slips screen (with status + breakdown)
- [ ] PDF generation for slips (with deduction breakdown)

### Sprint 4 — Security + Polish (Week 7)
- [ ] PIN brute-force lockout (5 attempts → 30 min lock)
- [ ] Refresh token DB storage + revocation
- [ ] Audit logging (all admin actions)
- [ ] Admin audit log screen
- [ ] Late penalty logic
- [ ] Device binding (optional)
- [ ] Push notifications (check-in reminder, leave status update)
- [ ] CSV export for attendance + salary
- [ ] Error handling, loading states, empty states
- [ ] Testing + deploy

---

## 12. Key decisions and trade-offs

**Why phone + PIN instead of email/password?**
Store employees typically don't have work emails. Phone + 4-digit PIN is fast for daily use. Admin sets the PIN when creating the employee.

**Why daily QR rotation instead of per-scan?**
Per-scan would require the admin device to be online and responsive for every scan. Daily rotation means the QR can be displayed on a device with intermittent connectivity — it just needs to fetch once per day.

**Why not geofencing instead of QR?**
QR is simpler, doesn't need GPS permissions, works inside buildings with poor GPS, and the physical act of scanning at the counter ensures presence. Can always add geofencing later as an additional layer.

**Why a single Flutter app with role-based views instead of two apps?**
Simpler to maintain, deploy, and update. The role check happens at the router level — admin never sees employee routes and vice versa.

**Why store refresh tokens in DB instead of stateless?**
Stateless refresh tokens can't be revoked. If an employee's phone is lost or they're terminated, admin needs to invalidate all their sessions immediately. DB-stored tokens allow instant revocation.

**Why per-employee leave balances instead of a global policy?**
Different employees may have different leave entitlements based on tenure, role, or agreement. Store-level defaults in `StoreConfig` serve as templates, but individual balances can be overridden.

**Why auto-checkout instead of requiring manual checkout?**
In practice, employees forget to check out. Without auto-checkout, their hours calculation breaks (infinite shift), salary engine fails, and admin has to manually fix every missed checkout. Auto-checkout at `shiftEnd` is a safe default.

**Why audit logging?**
When salary disputes arise ("I was marked absent but I was there"), admin needs a trail of who changed what and when. Manual attendance edits, salary regeneration, and leave approvals all need accountability.
