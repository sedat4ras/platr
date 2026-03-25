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
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

---

## Overview

Platr is a mobile social app built for Victorian (Australia) car enthusiasts. Every number plate gets its own profile page — users can star plates they love, leave comments, and verify ownership via VicRoads. Plates can be displayed as rendered visuals or as real photos uploaded by the owner.

### The Problem

There is no dedicated space online for Victorian car and plate culture. Enthusiasts share plate photos across general forums and Instagram with no structured way to discuss, find, or claim plates.

### The Solution

Platr gives every VIC plate its own public profile. Anyone can add a plate, engage with it, and claim ownership. Owners verify by submitting a VicRoads screenshot, unlocking owner controls. The app complies with Australian Privacy Principles and the Age-Restricted Platforms Act (16+).

---

## Features

### Plates
| Feature | Description |
|---------|------------|
| **Three plate styles** | VIC Standard, VIC Black, and fully configurable VIC Custom |
| **Custom plate builder** | Background colour, text colour, border style, VIC badge, state text, separator |
| **Photo mode** | Upload or photograph your real plate with an in-app pinch-zoom crop tool |
| **Duplicate detection** | Alerts if a plate already exists with a link to the existing entry |

### Social
| Feature | Description |
|---------|------------|
| **Star system** | Star / unstar any plate with a live count |
| **Comments** | Open / closed per plate, owner-controlled |
| **Two-tier moderation** | Keyword filter on every submit + AI review on reported comments |
| **Report & block** | Report comments, block users; 5 reports auto-hides a comment |

### Ownership
| Feature | Description |
|---------|------------|
| **VicRoads claim** | Upload a VicRoads screenshot — admin verifies within 48 hours |
| **Ownership badge** | Verified owners get a "You own this plate" badge |
| **Owner controls** | Toggle comments open / closed from the plate page |

### Profile & Account
| Feature | Description |
|---------|------------|
| **Edit profile** | Display name and bio |
| **My plates** | All submitted plates |
| **Account deletion** | Permanent, App Store compliant |
| **Dark / light mode** | Persisted across sessions |

---

## Getting Started

### Prerequisites

- Node.js 18+, npm
- Expo Go app on iPhone
- Python 3.11+

### Setup

```bash
git clone https://github.com/sedat4ras/platr.git
cd platr
npm install
cp .env.example .env        # fill in your values
cp backend/.env.example backend/.env   # fill in your values
```

### Run

```bash
# Backend
cd backend && uvicorn backend.main:app --host 0.0.0.0 --port 8001 --reload

# Frontend (separate terminal)
npx expo start --clear
```

---

## Security

- Passwords hashed with bcrypt
- Tokens stored in iOS Keychain
- Cryptographically secure OTP generation
- All credentials loaded from environment variables — never hardcoded
- Age verification enforced server-side (Australian Social Media Law, 16+)
- Two-tier comment moderation (keyword filter + AI)
- Full account deletion available in-app

---

## Development Stages

| Stage | Description | Status |
|-------|------------|--------|
| 1 | Auth — Email / Google / Apple | ✅ Done |
| 2 | Plate CRUD + Duplicate Detection | ✅ Done |
| 3 | Plate Renderer — 3 styles + Custom | ✅ Done |
| 5 | Photo Upload + Crop Tool | ✅ Done |
| 6 | Star System | ✅ Done |
| 7 | Comments + Two-Tier Moderation | ✅ Done |
| 8 | Ownership Claim (VicRoads flow) | ✅ Done |
| 9 | Profile Edit + Account Deletion | ✅ Done |
| 10 | Legal Screen (App Store compliance) | ✅ Done |
| 11 | Groups / Car Communities | 🔜 Roadmap |

---

## Roadmap

- [ ] Push notifications
- [ ] Car communities / Groups
- [ ] Plate of the Week
- [ ] Share plate as image card
- [ ] Admin dashboard
- [ ] Android support
- [ ] App Store release

---

## License

This project is licensed under the MIT License. Copyright (c) 2025 Sedat Aras.

---

<p align="center">
  <strong>Made in Melbourne, Victoria 🇦🇺</strong>
</p>
