
<h1 align="center">Platr</h1>

<p align="center">
  <strong>Victoria's licence plate social network</strong><br/>
  Search, star, claim and comment on Victorian number plates
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS-blue" alt="Platform" />
  <img src="https://img.shields.io/badge/Expo%20SDK-54-000020?logo=expo" alt="Expo SDK" />
  <img src="https://img.shields.io/badge/React%20Native-0.79-61dafb?logo=react" alt="React Native" />
  <img src="https://img.shields.io/badge/TypeScript-5.8-3178c6?logo=typescript" alt="TypeScript" />
  <img src="https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi" alt="FastAPI" />
  <img src="https://img.shields.io/badge/PostgreSQL-Database-336791?logo=postgresql" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License" />
</p>

---

## Overview

Platr is a mobile social app built for Victorian (Australia) car enthusiasts. Every number plate gets its own profile page — users can look up any VIC plate, see the vehicle's rego status, star plates they love, leave comments, and verify ownership via VicRoads. Plates can be displayed as rendered visuals (VIC Standard, VIC Black, or fully customised) or as real photos uploaded by the owner.

### The Problem

There is no dedicated space online for Victorian car and plate culture. Enthusiasts share plate photos across general forums and Instagram with no structured way to discuss, find, or claim plates. There is no central registry where owners can connect with their plates digitally.

### The Solution

Platr gives every VIC plate its own public profile. Anyone can add a plate, look up its live rego details, and engage with it. Owners verify their ownership by submitting a VicRoads screenshot, unlocking owner controls. The app enforces Australian Privacy Principles and complies with the Age-Restricted Platforms Act (16+).

---

## User Flow

```
                                PLATR — USER FLOW

  ┌──────────┐    ┌──────────────┐    ┌──────────────────────────────────────┐
  │  Splash  │───>│ Auth Screen  │───>│        MAIN APP (Tab Navigator)      │
  │  Screen  │    │ Login/Signup │    │                                      │
  └──────────┘    └──────────────┘    │  ┌──────┐ ┌──────┐ ┌───┐ ┌───────┐  │
                                      │  │ HOME │ │SEARCH│ │ + │ │PROFILE│  │
                                      │  └──┬───┘ └──┬───┘ └─┬─┘ └───┬───┘  │
                                      └─────┼────────┼───────┼───────┼──────┘
                                            │        │       │       │
                                            v        v       v       v
                                       ┌─────────┐ ┌────┐ ┌──────┐ ┌───────┐
                                       │  Plate  │ │Srch│ │ Add  │ │ Edit  │
                                       │  Detail │ │list│ │Plate │ │Profile│
                                       ├─────────┤ └────┘ ├──────┤ ├───────┤
                                       │ ⭐ Star  │        │Visual│ │ Legal │
                                       │ Comment │        │ mode │ ├───────┤
                                       │ Claim   │        ├──────┤ │Delete │
                                       │ Rego ✓  │        │Photo │ │Acct   │
                                       └─────────┘        │+Crop │ └───────┘
                                                          └──────┘
```

---

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| **Framework** | React Native (Expo SDK 54) | iOS from a single TypeScript codebase |
| **Language** | TypeScript 5.8 | Type safety across frontend + API layer |
| **Backend** | FastAPI + SQLAlchemy (async) | High-performance async Python REST API |
| **Database** | PostgreSQL | Relational data with async ORM |
| **Auth** | JWT (access + refresh tokens) | Stored securely in iOS Keychain via expo-secure-store |
| **State** | Zustand | Lightweight, no boilerplate |
| **Navigation** | React Navigation 7 | Stack + Bottom Tabs |
| **AI Moderation** | Claude (Anthropic) | Reviews user-reported comments only |
| **Email** | Gmail SMTP (aiosmtplib) | Admin alerts for moderation events |
| **Rego Checks** | VicRoads async scrape | Background task with rate limiting |
| **UI** | Custom design system | Dark / light mode, Blab-inspired aesthetic |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│                                                                   │
│  ┌──────────┐  ┌────────────┐  ┌──────────┐  ┌───────────┐      │
│  │ Screens  │  │ Components │  │Navigation│  │   Hooks   │      │
│  │  (11)    │  │   (5)      │  │  Stack + │  │ useTheme  │      │
│  └────┬─────┘  └─────┬──────┘  │   Tabs   │  └───────────┘      │
├───────┴───────────────┴──────────────────────────────────────────┤
│                        BUSINESS LOGIC LAYER                        │
│                                                                    │
│  ┌──────────┐  ┌────────────┐  ┌────────────┐  ┌─────────────┐   │
│  │  Stores  │  │  api.ts    │  │  types/    │  │  constants/ │   │
│  │ (Zustand)│  │ (20+ fns)  │  │  index.ts  │  │   theme.ts  │   │
│  └──────────┘  └─────┬──────┘  └────────────┘  └─────────────┘   │
├───────────────────────┴────────────────────────────────────────────┤
│                        BACKEND LAYER (FastAPI)                      │
│                                                                     │
│  ┌────────┐ ┌────────┐ ┌──────────┐ ┌───────┐ ┌───────────────┐  │
│  │  auth  │ │ plates │ │ comments │ │ stars │ │ownership/admin│  │
│  └────────┘ └────────┘ └──────────┘ └───────┘ └───────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      PostgreSQL Database                      │  │
│  │     users · plates · comments · plate_starring · vehicles    │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
platr/
├── assets/                          # App icon, splash screen
│
├── src/
│   ├── components/                  # 5 Reusable UI Components
│   │   ├── Button.tsx               # Primary / secondary / outline / danger variants
│   │   ├── Input.tsx                # Text input with icon, label, error states
│   │   ├── PlateRenderer.tsx        # Renders VIC_STANDARD / VIC_BLACK / VIC_CUSTOM
│   │   ├── PlateCropModal.tsx       # Full-screen pinch-zoom crop tool for plate photos
│   │   └── Toast.tsx                # Global imperative toast notifications
│   │
│   ├── screens/                     # 11 Screens
│   │   ├── auth/
│   │   │   ├── SplashScreen.tsx     # Animated launch screen
│   │   │   ├── LoginScreen.tsx      # Email / Google / Apple sign-in
│   │   │   └── RegisterScreen.tsx   # Account creation (16+ age check)
│   │   ├── home/
│   │   │   └── HomeScreen.tsx       # Plate feed with inline search
│   │   ├── plate/
│   │   │   ├── AddPlateScreen.tsx   # Visual renderer or real photo upload + crop
│   │   │   └── PlateDetailScreen.tsx # Rego, stars, comments, ownership claim
│   │   ├── search/
│   │   │   └── SearchScreen.tsx     # Full-page plate search with rendered previews
│   │   ├── groups/
│   │   │   └── GroupsScreen.tsx     # Coming soon — car communities
│   │   ├── profile/
│   │   │   ├── ProfileScreen.tsx    # My plates, stats, settings
│   │   │   └── EditProfileScreen.tsx # Display name + bio editing
│   │   └── legal/
│   │       └── LegalScreen.tsx      # Privacy Policy, Terms of Service, Contact
│   │
│   ├── navigation/
│   │   ├── RootNavigator.tsx        # Auth / Main routing
│   │   └── MainTabNavigator.tsx     # 5-tab bottom bar
│   │
│   ├── services/api.ts              # All API calls (20+ functions)
│   ├── store/                       # authStore + themeStore (Zustand)
│   ├── hooks/useTheme.ts
│   ├── types/index.ts               # All interfaces & types
│   └── constants/theme.ts           # Colours, spacing, fonts, border radii
│
├── backend/
│   ├── routers/                     # 9 FastAPI routers
│   │   ├── auth.py                  # Register, login, refresh, profile, delete account
│   │   ├── plates.py                # CRUD, search, photo upload, rego recheck
│   │   ├── comments.py              # Post, report, keyword moderation
│   │   ├── stars.py                 # Star / unstar / status (idempotent)
│   │   ├── ownership.py             # VicRoads screenshot claim flow
│   │   ├── admin.py                 # Approve/reject claims, ban users
│   │   ├── feed.py                  # Unified activity feed
│   │   └── users.py                 # User lookup
│   │
│   ├── models/                      # SQLAlchemy ORM (user, plate, comment, star)
│   ├── schemas/                     # Pydantic request / response schemas
│   ├── services/
│   │   ├── email.py                 # Gmail SMTP admin alerts
│   │   ├── moderation.py            # Keyword filter + Claude AI review
│   │   └── rego_check.py            # Async VicRoads rego lookup
│   ├── migrations/                  # 8 SQL migration files
│   ├── auth.py                      # JWT, bcrypt, token helpers
│   ├── config.py                    # Pydantic Settings (env-driven)
│   └── requirements.txt
│
├── .env.example
├── backend/.env.example
├── app.json
└── package.json
```

---

## Features

### Plates
| Feature | Description |
|---------|------------|
| **Three plate styles** | VIC Standard (white/blue), VIC Black (chrome border), VIC Custom (fully configurable) |
| **Custom plate builder** | Background colour, text colour, border style, VIC badge, state text, separator character |
| **Photo mode** | Upload or photograph your real plate; pinch-zoom crop for precision framing |
| **Duplicate detection** | HTTP 409 with deep-link to existing plate if already in database |
| **Victoria only** | All plates hardcoded to VIC state code |

### Rego & Vehicle Data
| Feature | Description |
|---------|------------|
| **Live rego lookup** | Async background check on plate creation |
| **Manual recheck** | "Recheck Rego" button on every plate detail page |
| **Vehicle details** | Year, make, model, colour, expiry date |
| **Status badges** | Current / Expired / Cancelled / Checking… / Unknown — colour-coded |

### Social
| Feature | Description |
|---------|------------|
| **Star system** | Star / unstar any plate; idempotent, live count |
| **Comments** | Open / closed per plate, 500-char limit |
| **Keyword moderation** | Sync filter on every submit — flags and hides automatically |
| **AI review** | Claude reviews user-reported comments only (cost-efficient) |
| **Admin email alerts** | Notification on keyword hit or user report |
| **Report & block** | Report comments (5 reports = auto-hide), block users |

### Ownership
| Feature | Description |
|---------|------------|
| **VicRoads claim** | Upload a VicRoads screenshot; admin verifies within 48h |
| **Ownership badge** | Green "You own this plate" badge on verified plates |
| **Owner controls** | Toggle comments open / closed from the plate detail screen |
| **Dispute flow** | If plate already claimed, raises dispute flag for admin |

### Profile & Account
| Feature | Description |
|---------|------------|
| **Edit profile** | Display name and bio editable at any time |
| **My plates** | All submitted plates with rego badges |
| **Account deletion** | Permanent, App Store compliant |
| **Dark / light mode** | Persisted in Zustand store |

### Safety & Privacy
| Feature | Description |
|---------|------------|
| **Age gate** | Must be 16+ — Australian Social Media Law, backend-enforced |
| **Keyword filter** | Profanity and hate-speech list on every comment submit |
| **Secure token storage** | JWT in iOS Keychain via expo-secure-store |
| **bcrypt hashing** | All passwords hashed before storage |
| **Cryptographic OTP** | `secrets.randbelow()` — not `random.randint()` |
| **No hardcoded secrets** | All keys in `.env` (gitignored) |
| **Legal screen** | Privacy Policy + Terms of Service in-app |

---

## Database Schema

```
┌──────────────┐       ┌──────────────────────┐       ┌──────────────────┐
│    users     │       │        plates         │       │    comments       │
├──────────────┤       ├──────────────────────┤       ├──────────────────┤
│ id (uuid)    │──────>│ id (uuid)             │──────>│ id (uuid)        │
│ username     │       │ state_code = 'VIC'    │       │ plate_id (FK)    │
│ email        │       │ plate_text            │       │ author_user_id   │
│ hashed_pass  │       │ plate_style           │       │ body             │
│ display_name │       │ custom_config (JSON)  │       │ is_hidden        │
│ bio          │       │ plate_photo_path       │       │ deleted_at       │
│ is_verified  │       │ owner_user_id (FK)    │       │ reported_by []   │
│ is_banned    │       │ submitted_by (FK)     │       │ created_at       │
│ created_at   │       │ ownership_verified    │       └──────────────────┘
└──────────────┘       │ star_count            │
                       │ view_count            │       ┌──────────────────┐
                       │ is_comments_open      │       │  plate_starring   │
                       │ rego_status           │       ├──────────────────┤
                       │ rego_expiry_date      │       │ plate_id (FK)    │
                       │ vehicle_year / make / │       │ user_id (FK)     │
                       │   model / color       │       │ created_at       │
                       │ created_at            │       │ UNIQUE(plate,usr)│
                       └──────────────────────┘       └──────────────────┘
```

---

## Moderation System

```
Comment Submitted
       │
       ▼
┌──────────────────┐
│  Tier 1: Keyword │  ← Sync, free, instant
│  Filter          │     Blocks profanity, slurs, hate speech
└────────┬─────────┘
         │ Passes
         ▼
   Comment Posted
         │
         │ User reports it
         ▼
┌──────────────────┐
│  Tier 2: Claude  │  ← Async, AI, only on reports
│  AI Review       │     Decide: keep / hide → email admin
└──────────────────┘

5 reports on one comment → auto-hide regardless of AI decision
```

---

## Getting Started

### Prerequisites

- Node.js 18+, npm
- Expo Go app on iPhone
- Python 3.11+, PostgreSQL 15+

### Frontend

```bash
git clone https://github.com/sedat4ras/platr.git
cd platr
npm install
cp .env.example .env
# Set EXPO_PUBLIC_API_URL to your backend IP
npx expo start --clear
```

### Backend

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Fill in DATABASE_URL, SECRET_KEY, ANTHROPIC_API_KEY, GMAIL_*

createdb platr
psql "postgresql://platr:password@localhost:5432/platr" \
  -f migrations/plate_system_overhaul.sql \
  -f migrations/star_system_overhaul.sql \
  -f migrations/custom_plate_system.sql

uvicorn backend.main:app --host 0.0.0.0 --port 8001 --reload
```

### Environment Variables

**Frontend (`.env`)**
```env
EXPO_PUBLIC_API_URL=http://YOUR_LOCAL_IP:8001/api/v1
EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID=your-google-ios-client-id
EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID=your-google-web-client-id
```

**Backend (`backend/.env`)**
```env
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/platr
DEBUG=false
SECRET_KEY=your-64-char-hex-secret
ANTHROPIC_API_KEY=your-anthropic-key
GMAIL_USER=your@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
GOOGLE_IOS_CLIENT_ID=your-google-ios-client-id
```

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/auth/register` | Create account (16+ age check) |
| `POST` | `/auth/login` | Email / password login |
| `POST` | `/auth/google` | Google OAuth token exchange |
| `PATCH` | `/auth/me` | Update display name / bio |
| `DELETE` | `/auth/me` | Permanently delete account |
| `GET` | `/plates` | List plates (paginated) |
| `POST` | `/plates` | Add plate (409 on duplicate) |
| `GET` | `/plates/search` | Search by plate text |
| `GET` | `/plates/{id}` | Plate detail (increments view count) |
| `POST` | `/plates/{id}/photo` | Upload real plate photo |
| `POST` | `/plates/{id}/recheck` | Re-trigger rego check |
| `POST` | `/plates/{id}/star` | Star a plate |
| `DELETE` | `/plates/{id}/star` | Unstar a plate |
| `POST` | `/plates/{id}/comments` | Post comment (with moderation) |
| `POST` | `/plates/{id}/claim/vicroads` | Submit VicRoads ownership claim |
| `PATCH` | `/plates/{id}/comments/toggle` | Owner: open / close comments |
| `POST` | `/comments/{id}/report` | Report a comment |

---

## Codebase Statistics

| Metric | Count |
|--------|-------|
| **Frontend Source Files** | 24 |
| **Lines of Code (frontend)** | ~5,000 |
| **Screens** | 11 |
| **Reusable Components** | 5 |
| **Backend Routers** | 9 |
| **DB Migrations** | 8 |
| **API Endpoints** | 20+ |
| **TypeScript Errors** | 0 |

---

## Development Stages

| Stage | Description | Status |
|-------|------------|--------|
| 1 | Project Setup & Architecture | ✅ Done |
| 2 | Auth — Email / Google / Apple | ✅ Done |
| 3 | Plate CRUD + Duplicate Detection | ✅ Done |
| 4 | VicRoads Rego Check (async) | ✅ Done |
| 5 | Plate Renderer — 3 styles + Custom | ✅ Done |
| 6 | Photo Upload + Crop Tool | ✅ Done |
| 7 | Star System | ✅ Done |
| 8 | Comments + Two-Tier Moderation | ✅ Done |
| 9 | Ownership Claim (VicRoads flow) | ✅ Done |
| 10 | Profile Edit + Account Deletion | ✅ Done |
| 11 | Legal Screen (App Store compliance) | ✅ Done |
| 12 | Groups / Car Communities | 🔜 Roadmap |

---

## Roadmap

- [ ] Push notifications (plate starred / comment received)
- [ ] Car communities / Groups feature
- [ ] Infinite scroll + pagination UI
- [ ] Plate of the Week (editor picks)
- [ ] Share plate as image card
- [ ] Web admin dashboard (claim queue, moderation)
- [ ] Android support
- [ ] App Store release (iOS)

---

## Security

- **bcrypt** password hashing
- **JWT** tokens in iOS Keychain via `expo-secure-store`
- **Cryptographic OTP** — `secrets.randbelow()`, not `random.randint()`
- **Two-tier moderation** — keyword filter + Claude AI (reports only)
- **Age verification** — 16+ enforced server-side (Australian law)
- **No hardcoded secrets** — all credentials in `.env` (gitignored)
- **Account deletion** — full data removal, App Store compliant
- **DEBUG=false** in production — no SQL echo, no stack traces

---

## License

This project is proprietary software. All rights reserved.

---

<p align="center">
  <strong>Built with React Native + FastAPI + Claude AI</strong><br/>
  <sub>Melbourne, Victoria, Australia</sub>
</p>
