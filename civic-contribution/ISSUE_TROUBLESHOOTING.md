# Supabase Issue Visibility Troubleshooting Guide

## Quick Summary
If issues are not visible in the feed/map after creation, follow this guide to diagnose the root cause using the new logging added to the app.

---

## Step 1: Rebuild the App with Logging

First, rebuild the app with the enhanced logging:

```powershell
cd D:\Webathon4.0\civic-contribution
flutter clean
flutter pub get
flutter run --debug
```

Wait for the app to fully load on device. The console output will show Dart logs as `[Report]`, `[DB]`, etc.

---

## Step 2: Test Issue Creation with Console Capture

### On Windows (PowerShell):

Open **two PowerShell windows**:

**Window 1 — Start ADB logcat** (capture Android native logs):
```powershell
adb logcat -s "*:V" | Select-String -Pattern "(Report|DB|auth|supabase|error)" -CaseSensitive
```

**Window 2 — Watch Dart console** (in the terminal where `flutter run` is running, watch the output):
- Look for messages starting with `[Report]` and `[DB]`

### On Android Device:

1. Open the app
2. Tap **Continue with Google** to sign in (confirm auth works)
3. Tap **Report Issue** (FAB at bottom right)
4. Capture a photo or skip to test location
5. Fill in category + description
6. Tap **Confirm Report** → **Submit Report**

---

## Step 3: Read the Logs

### Expected Success Flow:

```
[Report] Starting submission: userId=<uuid>, community=<communityId-or-null>
[Report] Uploading photo...
[Report] Photo uploaded: https://joqxrpuavqepuxqemcpo.supabase.co/storage/v1/...
[Report] Running duplicate check at (12.9716, 77.5946)
[Report] Creating new issue...
[Report] Issue data prepared, calling createIssue...
[DB] Creating issue: <uuid> | community: <communityId-or-null>
[DB] Issue created: <issue-uuid>
[Report] Credits awarded
✓ Success banner: "Issue reported! +10 credits"
```

Then:
- Tap **Feed** tab → should see your issue in the list
- Tap **Map** tab → should see your issue marker

---

## Step 4: Diagnose Based on Where It Fails

### Failure: "Photo failed to upload"

**Symptom**: `[Report] Upload/S3 error` or logs stop after `[Report] Uploading photo...`

**Root Cause**: Storage permission or bucket misconfiguration

**Fix**:
1. Verify Supabase buckets exist: Dashboard → Storage
   - Bucket `issues` (public)
   - Bucket `verifications` (public)
2. Check RLS policies on `storage.objects` allow authenticated inserts
3. Confirm IAM permissions on Supabase project

---

### Failure: "Location error"

**Symptom**: `[Report] ERROR during submission: Location is required...`

**Root Cause**: User denied location permission or location couldn't be fetched

**Fix**:
1. Android device: Settings → Apps → Civic Contribution → Permissions → Location → Allow always
2. Rebuild with `flutter clean && flutter run --debug`
3. Retest, confirm location is captured before submitting

---

### Failure: "Duplicate check takes forever"

**Symptom**: Logs show `[Report] Running duplicate check...` but never progress

**Root Cause**: `getAllIssuesOnce()` is blocking or erroring (RLS policy issue)

**Fix**:
1. Check RLS SELECT policy on `issues` table:
   ```sql
   SELECT * FROM auth.authorization_codes; -- Just to test auth
   SELECT * FROM public.issues LIMIT 1; -- Should return rows (or empty, but not error)
   ```
2. Verify `auth.uid()` is set in Supabase (should be automatic after OAuth)
3. If RLS blocks all SELECTs, users can't read issues → nothing displays

---

### Failure: "createIssue fails with PostgreSQL error"

**Symptom**: 
```
[DB] PostgreSQL error: <message> (code: <code>)
```

Common codes:
- `PGRST116`: RLS policy violation (INSERT blocked)
- `23503`: Foreign key constraint failed (reporter_id not valid user)
- `23502`: NOT NULL constraint violated (missing required field)

**Fix**:
1. **If RLS violation**: Check `issues_insert_authenticated` policy:
   ```sql
   create policy issues_insert_authenticated on public.issues
   for insert to authenticated with check (reporter_id = auth.uid());
   ```
   This requires `reporter_id` = the authenticated user's UUID. Verify it's being set correctly.

2. **If FK error**: Ensure the authenticated user exists in `public.users` table:
   ```sql
   SELECT id, email FROM public.users WHERE id = '<your-user-uuid>';
   ```
   If not, the user profile wasn't created during signup.

3. **If NULL constraint**: Verify all required Issue fields are populated (reporter_id, category, description, latitude, longitude, created_at, etc.)

---

### Failure: "Issue created but not visible in feed"

**Symptom**:
```
[DB] Issue created: <uuid>
✓ Success banner shown
But feed is empty, map shows nothing
```

**Root Cause**: 
- RLS SELECT policy blocks reading issues
- `communityId` is NULL and app is filtering out community-scoped issues
- Stream subscription error (silent)

**Fix**:
1. **Check RLS SELECT policy**:
   ```sql
   -- This should return the issue you just created
   SELECT * FROM public.issues WHERE id = '<issue-uuid>';
   ```

2. **Check communityId logic**: 
   - If you haven't selected a community in the app, `communityId` is NULL
   - Verify the app doesn't filter out NULL community issues:
     - HomeScreen → Feed should show all issues (community-scoped or not)
     - Check `IssueProvider.reinitialize()` logic

3. **Check Stream subscription error**:
   - Look for `[DB] Error in getIssuesStream:` messages in logs
   - If present, it's likely RLS or connection issue

---

### Failure: "Auth error during credits award"

**Symptom**:
```
[DB] PostgreSQL error during incrementUserCredits / addBadge
```

**Root Cause**: User profile missing or RLS blocks UPDATE

**Fix**:
1. Verify user was auto-created in `public.users` after OAuth login:
   ```sql
   SELECT id, display_name, email FROM public.users WHERE id = auth.uid();
   ```
2. If missing, it's a LoginScreen → UserProvider flow issue (separate from this guide)

---

## Step 5: Advanced: Direct Supabase SQL Test

If logs show success but issues still don't appear, test directly in Supabase:

### SQL Console (Supabase Dashboard → SQL Editor):

```sql
-- Check if issue table has data
SELECT COUNT(*) FROM public.issues;

-- Check the last issue created
SELECT id, reporter_id, category, description, community_id, created_at
FROM public.issues
ORDER BY created_at DESC
LIMIT 1;

-- Check if current user can READ it (requires you to be logged in as that user)
SELECT id, category
FROM public.issues
WHERE reporter_id = auth.uid()
LIMIT 1;

-- Check RLS policy is not blocking
SELECT 1 FROM public.issues LIMIT 1;  -- Should return 1 row (even if table is empty, this tests RLS)
```

---

## Step 6: Last Resort — Disable RLS to Test

If you suspect RLS is silently breaking everything:

```sql
-- TEMPORARILY disable RLS (dev only!)
ALTER TABLE public.issues DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Rebuild and test
-- Logs should now show data

-- Re-enable when done
ALTER TABLE public.issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
```

---

## When Reporting the Issue

If you can't resolve it, share:

1. **Full `[Report]` and `[DB]` log output** from the app (Dart console)
2. **Any PostgreSQL error codes** (from `[DB] PostgreSQL error:` lines)
3. **Whether auth works** (confirm you can log in)
4. **SQL query results** from Step 5 above
5. **What you see** (empty feed, loading spinner, error message?)

---

## Common Fixes Checklist

- [ ] Auth works (can log in)
- [ ] Supabase URL is `https://joqxrpuavqepuxqemcpo.supabase.co` (not PostgreSQL string)
- [ ] Storage buckets `issues` and `verifications` exist
- [ ] Community-scoped filtering logic doesn't hide NULL community issues
- [ ] RLS policies allow authenticated INSERT/SELECT
- [ ] User profile created in `public.users` after login
- [ ] App rebuilt with `flutter clean && flutter run --debug`
- [ ] Logs show full submission flow without errors
- [ ] Feed tab refreshed (pull down or navigate away/back)

---

## Questions?

Check [GOOGLE_OAUTH_SETUP.md](GOOGLE_OAUTH_SETUP.md) for OAuth/auth-specific troubleshooting.
