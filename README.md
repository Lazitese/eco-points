# 🌿 Eco Points

A Flutter app that rewards eco-friendly behaviour — walking and healthy eating — with verified points on a real-time leaderboard.

---

## Features

| Feature | Details |
|---|---|
| **Auth** | Email/password via Supabase Auth |
| **Dashboard** | Live "Total Verified Points" counter |
| **Walk** | GPS tracking with geolocator, 10 pts/km, auto-approved |
| **Verify Meal** | Camera-only photo capture → Supabase Storage → pending review |
| **Leaderboard** | Real-time stream, top-3 podium, highlights current user |
| **Theme** | Eco-Green + Modern White, high-contrast, Google Fonts Inter |

---

## Quick Start

### 1. Create a Supabase project

Go to [supabase.com](https://supabase.com) → New Project.

### 2. Run the schema

Open **SQL Editor** in your Supabase dashboard and paste the contents of `supabase/schema.sql`. Run it.

### 3. Credentials

Already configured in `lib/core/constants/supabase_constants.dart` for project `qsvpkzvdnubxfdnxwbcm`.

### 4. Install dependencies

```bash
flutter pub get
```

### 5. Run

```bash
flutter run
```

---

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/        # Supabase URL & keys
│   ├── router/           # GoRouter config + auth redirect
│   ├── services/         # SupabaseService (auth, storage, DB)
│   └── theme/            # AppTheme (colours, typography)
└── features/
    ├── auth/             # Login & Register screens
    ├── home/             # Dashboard with points banner + action cards
    ├── walk/             # GPS walk tracker
    ├── meal/             # Camera capture + upload
    └── leaderboard/      # Real-time ranked list
```

---

## Supabase Setup Details

### Tables

**`profiles`**
| Column | Type | Notes |
|---|---|---|
| id | uuid | FK → auth.users |
| display_name | text | |
| total_points | integer | Updated via RPC |
| created_at | timestamptz | |

**`activities`**
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → profiles |
| type | text | `walk` or `meal` |
| points | integer | |
| status | text | `pending`, `approved`, `rejected` |
| distance_km | numeric | Walk only |
| duration_seconds | integer | Walk only |
| photo_url | text | Meal only |
| created_at | timestamptz | |

### Storage

Bucket: **`verification-photos`** (public)  
Path pattern: `{user_id}/{timestamp}.jpg`

### Approving Meal Photos

Meal activities are inserted with `status = 'pending'`. An admin (or future AI moderation) updates the row to `status = 'approved'` and calls `increment_points`. The leaderboard and home screen update instantly via Supabase Realtime.

---

## Android Permissions

Already configured in `AndroidManifest.xml`:
- `CAMERA`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `INTERNET`

## iOS Permissions

Already configured in `Info.plist`:
- `NSCameraUsageDescription`
- `NSLocationWhenInUseUsageDescription`

> **Note:** `NSPhotoLibraryUsageDescription` is intentionally omitted — gallery access is disabled by design.

---

## Dependencies

| Package | Purpose |
|---|---|
| `supabase_flutter` | Auth, Database, Storage, Realtime |
| `go_router` | Declarative routing with auth redirect |
| `camera` | Camera preview & capture (no gallery) |
| `geolocator` | GPS distance tracking |
| `google_fonts` | Inter typeface |
| `flutter_animate` | Entrance animations |
| `permission_handler` | Runtime permissions |
