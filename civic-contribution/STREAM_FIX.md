# Stream Subscription Fix — Real-Time Feed Issues

## Root Cause

The real-time feed was not responding because:

1. **IssueProvider never reinitialize when community changed**
   - User selects a community → UserProvider.communityId updates
   - But IssueProvider kept listening to global issues, not community-scoped issues
   - Workaround: IssueProvider had `reinitialize()` method, but nothing called it

2. **No error handling in stream listeners**
   - If the stream encountered an error (RLS violation, network issue), subscription died silently
   - No `onError` handler → errors weren't logged or recovered from

3. **No proper cleanup on dispose**
   - Stream subscriptions weren't cancelled when provider disposed
   - Could cause memory leaks and zombie subscriptions

4. **No duplicate subscription prevention**
   - If `reinitialize()` was called twice with same communityId, it would unsubscribe and resubscribe unnecessarily

## What Was Fixed

### [lib/application/providers/issue_provider.dart](lib/application/providers/issue_provider.dart)
- ✅ Added `_initializeStream()` method to centralize stream setup
- ✅ Added error handling to `.listen()` calls:
  ```dart
  onError: (e) {
    debugPrint('[IssueProvider] Stream error: $e');
    _loading = false;
    notifyListeners();
  }
  ```
- ✅ Added `dispose()` cleanup to cancel subscriptions
- ✅ Added duplicate check in `reinitialize()` to prevent re-subscribing
- ✅ Added detailed logging with `[IssueProvider]` tags

### [lib/presentation/app.dart](lib/presentation/app.dart)
- ✅ Changed `ChangeNotifierProvider<IssueProvider>` to `ChangeNotifierProxyProvider`
- ✅ Now `IssueProvider` automatically reinitializes when `UserProvider.communityId` changes
- **Key change**:
  ```dart
  ChangeNotifierProxyProvider<UserProvider, IssueProvider>(
    create: (ctx) => IssueProvider(databaseService, creditsService),
    update: (ctx, userProvider, previous) {
      final issueProvider = previous ?? IssueProvider(databaseService, creditsService);
      issueProvider.reinitialize(userProvider.communityId);
      return issueProvider;
    },
  ),
  ```

### [lib/data/services/database_service.dart](lib/data/services/database_service.dart)
- ✅ Added `.handleError()` to `getIssuesByCommunityStream()`
- ✅ Added `.handleError()` to `getUnresolvedIssuesByCommunityStream()`
- ✅ Added detailed logging for all stream operations

## How It Works Now

1. User signs in → OAuth succeeds
2. UserProvider loads user profile → sets communityId
3. **Automatic**: ProxyProvider detects communityId change → calls `IssueProvider.reinitialize()`
4. **Automatic**: IssueProvider cancels old stream, subscribes to community-scoped stream
5. Feed updates with issues from that community (real-time via Supabase stream)
6. User can interact with issues (upvote, filter, etc.) without lag

## Testing

### Basic Test (3 minutes)

1. **Rebuild**:
   ```powershell
   flutter clean && flutter run --debug
   ```

2. **Sign in** and **select a community**

3. **Check Dart console** for logs like:
   ```
   [IssueProvider] Initializing stream for community: <uuid>
   [DB] getIssuesByCommunityStream(<uuid>) returned 5 issues
   [IssueProvider] Received 5 issues
   ```

4. **Test interactions**:
   - Tap a filter chip → feed updates instantly
   - Tap **Report Issue** → newly created issue appears in feed immediately
   - Tap **Upvote** button on an issue → upvoter count increases

### If Still Not Working

Check for these patterns in logs:

| Log Message | Likely Issue | Fix |
|---|---|---|
| `[IssueProvider] Stream error: ...` | RLS or network error | Check [KNOWN_ISSUES.md](KNOWN_ISSUES.md) #1 |
| `[DB] Error in getIssuesByCommunityStream: ...` | RLS or database error | Test SQL: `SELECT * FROM public.issues LIMIT 1;` |
| `Initializing stream` but never `Received ... issues` | Stream hanging | Check RLS policy on `issues` table |
| Issues don't appear after report | RLS SELECT blocking | Temporarily disable RLS to test |

---

## Technical Details

### Why ProxyProvider?

- **Before**: IssueProvider was independent. No way to tell it about communityId changes.
- **After**: `ChangeNotifierProxyProvider` automatically calls `update()` whenever UserProvider notifies.
- This is a clean, reusable pattern in the Provider library.

### Stream Lifecycle

```
App starts
  → IssueProvider constructor calls _initializeStream(null)
    → Subscribes to global issues stream

User selects community
  → UserProvider.communityId changes
    → Triggers ProxyProvider update
      → Calls issueProvider.reinitialize(communityId)
        → Cancels old subscription
        → _initializeStream(communityId) 
          → Subscribes to community stream

User signs out
  → IssueProvider.dispose() cancels subscription
  → UserProvider.communityId becomes null
  → ProxyProvider calls update again
    → issueProvider.reinitialize(null)
      → Back to global stream
```

---

## No Breaking Changes

- All existing methods preserved
- All tests should pass (if you have any)
- No API changes to IssueProvider
- Backward compatible with menu/leaderboard logic

Rebuild and test! The feed should now respond instantly to changes. 🚀
