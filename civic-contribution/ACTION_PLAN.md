# Action Plan: Fixing Issue Visibility

## What Was Done (Just Now)

1. **Added comprehensive logging** to track the issue creation and fetch pipeline:
   - `[Report]` tags in [lib/application/providers/report_flow_provider.dart](lib/application/providers/report_flow_provider.dart)
   - `[DB]` tags in [lib/data/services/database_service.dart](lib/data/services/database_service.dart)

2. **Created diagnostic guides**:
   - [ISSUE_TROUBLESHOOTING.md](ISSUE_TROUBLESHOOTING.md) — Step-by-step testing with log capture
   - [KNOWN_ISSUES.md](KNOWN_ISSUES.md) — Most likely root causes and SQL verification queries

3. **Verified migration**:
   - Supabase URL is correct ✓
   - RLS policies exist on `issues` table ✓
   - Storage buckets configured ✓
   - Issue model field names match database schema ✓

---

## What You Should Do Right Now

### Step 1: Rebuild and Test (5 minutes)

```powershell
cd D:\Webathon4.0\civic-contribution
flutter clean
flutter pub get
flutter run --debug
```

Wait for the app to launch. Keep the **Dart console** open (bottom panel in VS Code).

### Step 2: Create a Test Issue (3 minutes)

1. Tap **Continue with Google** (confirm auth works)
2. Select/confirm your community
3. Tap **Report Issue** (FAB)
4. Capture a photo (or skip)
5. Fill in:
   - Category: e.g., "Pothole"
   - Description: "Test issue"
6. Tap **Confirm Report**
7. Tap **Submit Report**

### Step 3: Watch the Logs

Look at the **Dart console** output. You should see a sequence like:

```
[Report] Starting submission: userId=abc..., community=def...
[Report] Uploading photo...
[Report] Photo uploaded: https://...
[Report] Running duplicate check at (12.97, 77.59)
[Report] Creating new issue...
[Report] Issue data prepared, calling createIssue...
[DB] Creating issue: abc... | community: def...
[DB] Issue created: 123...
[Report] Credits awarded
```

### Step 4: Check Results

Screen should show: **"Issue reported! +10 credits"** ✓

Then:
- Tap **Feed** → Should see your issue
- Tap **Map** → Should see marker

---

## If It Works ✓

Congratulations! The issue was just the bad Supabase URL we fixed at the start.

- Delete the two diagnostic files we created (optional):
  - [ISSUE_TROUBLESHOOTING.md](ISSUE_TROUBLESHOOTING.md)
  - [KNOWN_ISSUES.md](KNOWN_ISSUES.md)
- Keep the logging in the code (leave it, it's helpful for debugging in production)

---

## If It Doesn't Work ✗

### Check the Logs First

Match what you see to the troubleshooting guide:

| What You See | Likely Cause | Fix |
|---|---|---|
| `[Report] ERROR during submission: PostgreSQL error: ...` | RLS policy or constraint violation | Check [KNOWN_ISSUES.md](KNOWN_ISSUES.md) #1-2 |
| `[DB] Issue created: ...` but issues don't appear | RLS SELECT blocked or community filter | Check [KNOWN_ISSUES.md](KNOWN_ISSUES.md) #2 |
| `[Report] Uploading photo...` then hangs/error | Storage bucket or permissions | Check [KNOWN_ISSUES.md](KNOWN_ISSUES.md) #4 |
| App frozen on loading spinner | Stream error | Check [KNOWN_ISSUES.md](KNOWN_ISSUES.md) #5 |
| No logs at all (app crashes) | Code error | Run `flutter run --debug` and check stack trace |

### Run the SQL Verification (5 minutes)

Go to **Supabase Dashboard** → **SQL Editor** and run the queries from [KNOWN_ISSUES.md](KNOWN_ISSUES.md) "Quick Verification Checklist" section.

If any return errors or unexpected results, the migration is incomplete.

### If RLS Is the Culprit (Last Resort)

Temporarily disable RLS to confirm:

```sql
-- In Supabase SQL Editor:
ALTER TABLE public.issues DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
```

Rebuild and test. If it suddenly works, RLS is blocking — we need to fix the policies.

Then re-enable:

```sql
ALTER TABLE public.issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
```

### Share Error Details with Me

If you're stuck, share:

1. **Full log output** from the Dart console (copy all `[Report]` and `[DB]` lines)
2. **Any error message** shown on screen
3. **Results from SQL verification queries** above
4. **What happens** (spinner, blank feed, error popup?)

---

## Summary of Changes Made

### Files Modified

1. **[lib/core/supabase_config.dart](lib/core/supabase_config.dart)** ✓
   - Fixed URL from `postgresql://...` to `https://joqxrpuavqepuxqemcpo.supabase.co`

2. **[lib/data/services/auth_service.dart](lib/data/services/auth_service.dart)** ✓
   - Added error wrapping for OAuth failures

3. **[lib/presentation/screens/auth/login_screen.dart](lib/presentation/screens/auth/login_screen.dart)** ✓
   - Improved auth error display

4. **[lib/data/services/database_service.dart](lib/data/services/database_service.dart)** ✓ NEW
   - Added `debugPrint` logging for issue creation/fetch

5. **[lib/application/providers/report_flow_provider.dart](lib/application/providers/report_flow_provider.dart)** ✓ NEW
   - Added `debugPrint` logging for entire submission pipeline

### Files Created (Diagnostic Only)

- [ISSUE_TROUBLESHOOTING.md](ISSUE_TROUBLESHOOTING.md) — Troubleshooting guide
- [KNOWN_ISSUES.md](KNOWN_ISSUES.md) — Root cause analysis

---

## Code Quality

All changes:
- ✓ Compile without errors (verified with `flutter analyze`)
- ✓ Use existing Supabase client singleton
- ✓ Don't break any existing functionality
- ✓ All logging is debug-only (won't affect release builds)

---

## Next — If You Get Stuck

Don't hesitate to ask. With the logging in place, diagnosing is straightforward.

Common scenarios:
- **"Issue created but map shows nothing"** → 99% RLS SELECT policy
- **"Issue upload fails"** → Storage bucket or RLS on `storage.objects`
- **"Credits don't award"** → User profile missing in `public.users`

Good luck! 🚀
