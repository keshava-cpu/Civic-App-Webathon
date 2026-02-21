# Known Issues & Likely Causes

## Issue: "Reported issue not visible in feed/map"

### Most Likely Causes (Most → Least Likely)

1. **RLS SELECT Policy on `issues` Table Is Blocking**
   - **Why**: Firebase → Supabase migration forgot that RLS defaults to DENY
   - **Symptom**: Logs show `[DB] Issue created: <uuid>` but `[DB] getIssuesStream returned 0 issues`
   - **Fix**: Verify RLS policy exists:
     ```sql
     SELECT policy_name FROM pg_policies WHERE tablename = 'issues';
     -- Should show: issues_select_authenticated
     
     -- Test if you can read:
     SELECT * FROM public.issues LIMIT 1;
     ```

2. **Community ID Filtering Logic**
   - **Why**: If `communityId` is NULL when creating, app's feed might filter it out thinking it's a stale record
   - **Symptom**: User hasn't selected a community → `userProvider.communityId` is NULL → issue created with `community_id = NULL` → filtered from feed
   - **Fix**: Check [lib/application/providers/issue_provider.dart](lib/application/providers/issue_provider.dart) line 35-36:
     ```dart
     // Current logic: if communityId provided, scope to community; else global
     final stream = communityId != null
         ? _firestoreService.getIssuesByCommunityStream(communityId)
         : _firestoreService.getIssuesStream();
     ```
     Should be correct. But **verify the feed filters don't block `NULL` community issues**.

3. **User Profile Not Created in `public.users`**
   - **Why**: OAuth creates `auth` user but not `public.users` profile automatically
   - **Symptom**: RLS INSERT policy checks `reporter_id = auth.uid()`, but user doesn't exist in table
   - **Expected flow**: 
     - OAuth login succeeds → `AuthService.currentUser` returns user
     - `UserProvider` catches auth state → calls `_loadOrCreateProfile()`
     - Should `upsert` user into `public.users`
   - **Fix**: Check [lib/application/providers/user_provider.dart](lib/application/providers/user_provider.dart) line 38-42 runs after oauth

4. **Storage Upload Silently Falls Back to Local Path**
   - **Why**: `StorageService._upload()` catches all exceptions and returns local file path
   - **Symptom**: Photo URL is something like `/data/user/0/com.hackathon.civic_contribution/...` instead of `https://...`
   - **Impact**: Feed/map can't load image, might look broken
   - **Fix**: Check [lib/data/services/storage_service.dart](lib/data/services/storage_service.dart) line 32 error handling — enable detailed logging

5. **Stream Error in `getIssuesStream()`**
   - **Why**: RLS violation or connection error in the stream (not caught visibly)
   - **Symptom**: Feed spinner loops forever, no issues load
   - **Fix**: New logging added will show `[DB] Error in getIssuesStream: <error>`

---

## Issue: "Photo upload fails"

### Likely Causes

1. **Storage Bucket Doesn't Exist**
   - **Fix**: Supabase Dashboard → Storage → Confirm buckets `issues` and `verifications` exist

2. **RLS Policy on `storage.objects` Blocks INSERT**
   - **Fix**: Policy should allow authenticated users to insert into their own folder paths:
     ```sql
     SELECT * FROM storage.policies WHERE name LIKE 'storage_auth%';
     ```

3. **File Path Format Issue**
   - **Code**: [storage_service.dart](lib/data/services/storage_service.dart) line 30:
     ```dart
     final fileName = '$userId/${_uuid.v4()}.jpg';
     await _client.storage.from(bucket).upload(fileName, File(compressed.path));
     ```
   - This should work with Supabase, but confirm the path pattern is allowed by RLS

---

## Issue: "Duplicate check hangs"

### Likely Causes

1. **`getAllIssuesOnce()` Blocks on RLS Violation**
   - **Code**: [duplicate_service.dart](lib/data/services/duplicate_service.dart) line 51
   - **Fix**: Same as #1 above — RLS SELECT policy needed

2. **Large Issue Dataset**
   - **Why**: If there are thousands of issues, pHash comparison is O(n)
   - **Fix**: Implement filtering before comparison (e.g., category + date range)

---

## Issue: "Credits not awarded"

### Likely Causes

1. **RPC Function Not Found or Returns Error**
   - **Functions**: `increment_user_credits`, `increment_user_stat`, `add_user_badge`
   - **Fix**: Test directly:
     ```sql
     SELECT public.increment_user_credits('<user-id>'::uuid, 10);
     ```

2. **User Profile Missing in `public.users`**
   - **See**: Same fix as #3 under "Issue not visible" above

---

## Quick Verification Checklist

Run these SQL queries in Supabase SQL Console to verify migration:

```sql
-- 1. Check tables exist
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
-- Should include: users, issues, communities, micro_tasks, verifications

-- 2. Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename IN ('users', 'issues', 'communities', 'micro_tasks', 'verifications');
-- All should show rowsecurity = true

-- 3. Check RLS policies exist
SELECT schemaname, tablename, policyname FROM pg_policies WHERE tablename IN ('issues', 'users', 'communities');
-- Should show: users_select_authenticated, users_insert_own, issues_select_authenticated, issues_insert_authenticated, etc.

-- 4. Check storage buckets
SELECT id, name, public FROM storage.buckets;
-- Should show: issues (public), verifications (public)

-- 5. Check RPC functions
SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public';
-- Should include: increment_user_credits, upvote_issue, merge_issue, add_user_badge, etc.

-- 6. Test RLS as authenticated user (if you run this logged in as a user)
SELECT COUNT(*) FROM public.issues;
-- Should return 0 or N (not an error)
```

If any of these queries fail, the migration wasn't fully applied or has errors.

---

## Next Steps for Debugging

1. **Run the app with logging** (already added):
   ```bash
   flutter clean
   flutter run --debug
   ```

2. **Follow [ISSUE_TROUBLESHOOTING.md](ISSUE_TROUBLESHOOTING.md)** to capture logs

3. **Share the exact error message** from the logs (if any)

4. **If everything logs as "success" but issues don't appear**, the problem is RLS — disable it temporarily to confirm, then fix the policies
