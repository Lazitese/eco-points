# ✅ Setup Checklist

## Status: Ready to Run

All code is written and configured. Follow these steps to run the app:

---

## 1. Install Flutter ⏳ (You're doing this now)

Download and install Flutter SDK from:
👉 https://docs.flutter.dev/get-started/install/windows/mobile

Then add `C:\flutter\bin` to your PATH.

---

## 2. Run Supabase Schema ⏸️ (Do this next)

Open your Supabase SQL Editor:
👉 https://supabase.com/dashboard/project/qsvpkzvdnubxfdnxwbcm/sql

Copy and paste the entire contents of `supabase/schema.sql` and click **Run**.

This creates:
- ✅ `profiles` table
- ✅ `activities` table  
- ✅ `increment_points` RPC function
- ✅ Auto-profile trigger on signup
- ✅ `verification-photos` storage bucket
- ✅ Realtime enabled

---

## 3. Run the App ⏸️ (After steps 1 & 2)

Open a terminal in the `eco_points` folder and run:

```bash
flutter pub get
flutter run
```

---

## What's Already Done ✅

| Item | Status |
|---|---|
| Flutter project structure | ✅ Complete |
| Supabase credentials | ✅ Configured |
| Auth screens (Login/Register) | ✅ Complete |
| Home dashboard | ✅ Complete |
| Walk tracker with GPS | ✅ Complete |
| Camera meal verification | ✅ Complete |
| Real-time leaderboard | ✅ Complete |
| Eco-Green theme | ✅ Complete |
| Android permissions | ✅ Configured |
| iOS permissions | ✅ Configured |
| Storage bucket setup SQL | ✅ Ready |
| Database schema SQL | ✅ Ready |

---

## Common First-Run Issues

| Error | Fix |
|---|---|
| `flutter: command not found` | Add `C:\flutter\bin` to PATH and restart terminal |
| Camera permission crash | Grant permission when app prompts |
| Supabase 401 error | Run the schema SQL in Supabase dashboard |
| `minSdkVersion` error | Already fixed — set to 21 in `build.gradle` |

---

## Next Steps After Running

1. **Sign up** — create an account in the app
2. **Walk** — tap Walk, grant location permission, start walking
3. **Verify meal** — tap Verify Meal, grant camera permission, take a photo
4. **Check leaderboard** — see your points update in real-time

---

## Need Help?

Come back to this chat and say "done" once Flutter is installed, and I'll take over from there.
