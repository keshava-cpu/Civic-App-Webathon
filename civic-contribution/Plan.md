Here is Claude's plan:
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
 Civic Issue Reporting App — Implementation Plan

 Context

 Build a Flutter mobile app (Android) for a hackathon (~48h) that lets citizens report, track, and verify local civic issues. The core principle: report
 any issue in under 60 seconds across 3 screens. The app creates a closed loop: report → classify → assign → resolve → verify → reward → repeat.

 Stack: Flutter + Firebase (Firestore, Storage, FCM) + OpenStreetMap (with abstraction for future Google Maps swap)
 Auth: Mocked (hardcoded users, dropdown to switch)
 Design: Material Design 3
 Target: Android only

 ---
 Project Structure

 lib/
 ├── main.dart
 ├── app.dart
 ├── firebase_options.dart
 ├── config/
 │   ├── theme.dart              # M3 seed color, component themes
 │   ├── constants.dart          # Enums (IssueStatus, Category), point values, default radius
 │   └── routes.dart             # GoRouter definitions
 ├── models/
 │   ├── issue.dart
 │   ├── user_profile.dart
 │   ├── micro_task.dart
 │   ├── verification.dart
 │   └── badge.dart
 ├── services/
 │   ├── firestore_service.dart
 │   ├── storage_service.dart
 │   ├── location_service.dart
 │   ├── notification_service.dart
 │   ├── image_metadata_service.dart
 │   ├── duplicate_service.dart
 │   ├── credits_service.dart
 │   └── mock_auth_service.dart
 ├── providers/
 │   ├── issue_provider.dart
 │   ├── report_flow_provider.dart
 │   ├── user_provider.dart
 │   ├── leaderboard_provider.dart
 │   └── verification_provider.dart
 ├── screens/
 │   ├── home/home_screen.dart
 │   ├── report/
 │   │   ├── camera_screen.dart
 │   │   ├── form_screen.dart
 │   │   └── confirm_screen.dart
 │   ├── issue_detail/issue_detail_screen.dart
 │   ├── verification/verify_screen.dart
 │   ├── leaderboard/leaderboard_screen.dart
 │   └── map/map_screen.dart
 ├── widgets/
 │   ├── issue_card.dart
 │   ├── status_chip.dart
 │   ├── category_picker.dart
 │   ├── micro_task_tile.dart
 │   ├── contributor_popup.dart
 │   ├── badge_icon.dart
 │   ├── trust_indicator.dart
 │   └── map/
 │       ├── map_adapter.dart        # Abstract interface
 │       ├── osm_map_adapter.dart    # OpenStreetMap impl
 │       └── map_widget.dart         # Consumer widget
 └── utils/
     ├── geo_utils.dart
     ├── image_utils.dart
     └── date_utils.dart

 ---
 Firestore Collections

 issues/{issueId}

 - reporterId, category, description, location (GeoPoint), address, photoUrl, photoHash, exifData, status (pending/assigned/inProgress/resolved/verified),
 priorityScore, upvoterIds, mergedIssueIds, assignedTo, createdAt, updatedAt

 issues/{issueId}/microTasks/{taskId}

 - title, assigneeId, completed, completedAt, completedLocation

 issues/{issueId}/verifications/{verificationId}

 - verifierId, photoUrl, isResolved, comment, verifierTrustScore, createdAt

 users/{userId}

 - displayName, avatarUrl, trustScore, civicCredits, badges, issuesReported, verificationsCompleted, tasksCompleted

 ---
 Key Packages

 ┌───────────────────┬──────────────────────────────────────────────────────────────────────┐
 │      Purpose      │                               Package                                │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ State management  │ provider                                                             │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ Routing           │ go_router                                                            │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ Firebase          │ firebase_core, cloud_firestore, firebase_storage, firebase_messaging │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ Camera            │ camera + image_picker (fallback)                                     │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ EXIF              │ exif or native_exif                                                  │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ Image compression │ flutter_image_compress                                               │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ Maps              │ flutter_map + latlong2                                               │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ Location          │ geolocator                                                           │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ Geocoding         │ geocoding                                                            │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ Notifications     │ flutter_local_notifications                                          │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ Permissions       │ permission_handler                                                   │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ IDs               │ uuid                                                                 │
 ├───────────────────┼──────────────────────────────────────────────────────────────────────┤
 │ Time display      │ timeago                                                              │
 └───────────────────┴──────────────────────────────────────────────────────────────────────┘

 ---
 Implementation Order

 Phase 1: Skeleton (Hours 0-6)

 1. flutter create, add all dependencies
 2. FlutterFire CLI setup + Firebase project connection
 3. config/theme.dart — M3 theme with teal seed color
 4. config/constants.dart — all enums and config values
 5. config/routes.dart — GoRouter with stub screens
 6. app.dart + main.dart — wire theme, router, MultiProvider
 7. services/mock_auth_service.dart — 3-4 hardcoded users with dropdown switching
 8. All model files with fromJson/toJson

 Phase 2: 3-Screen Report Flow (Hours 6-16) — CRITICAL PATH

 9. services/location_service.dart — GPS acquisition + permissions
 10. screens/report/camera_screen.dart — full-screen camera, capture button
 11. services/image_metadata_service.dart — EXIF datetime/GPS extraction + md5 hash of resized grayscale
 12. screens/report/form_screen.dart — category picker grid, description, auto-GPS display
 13. screens/report/confirm_screen.dart — photo preview, summary, submit button
 14. services/storage_service.dart — compress + upload photo, return URL
 15. services/firestore_service.dart — createIssue(), getIssuesStream()
 16. providers/report_flow_provider.dart — wizard state across 3 screens
 17. services/duplicate_service.dart — radius check + hash compare → merge as upvote or create new

 Phase 3: Feed + Issue Detail (Hours 16-24)

 18. widgets/issue_card.dart + widgets/status_chip.dart
 19. screens/home/home_screen.dart — StreamBuilder on issues, filter chips, FAB → camera
 20. screens/issue_detail/issue_detail_screen.dart — photo, status timeline, upvote, micro-tasks, contributors
 21. providers/issue_provider.dart — filters, sorting

 Phase 4: Map (Hours 24-28)

 22. widgets/map/map_adapter.dart — abstract interface for map providers
 23. widgets/map/osm_map_adapter.dart — flutter_map implementation
 24. widgets/map/map_widget.dart — consumer widget defaulting to OSM adapter
 25. screens/map/map_screen.dart — markers colored by status, tap → bottom sheet → detail

 Phase 5: Verification + Trust (Hours 28-36)

 26. services/notification_service.dart — FCM init + position stream proximity check → local notification for nearby Resolved issues
 27. screens/verification/verify_screen.dart — capture photo, yes/no survey, weighted by trust score
 28. Auto-transition: if weighted verifications cross threshold → status becomes Verified
 29. widgets/contributor_popup.dart — celebratory dialog with all contributors

 Phase 6: Credits + Leaderboard (Hours 36-42)

 30. services/credits_service.dart — award points (report=10, upvote=2, verify=15, task=5), badge threshold checks
 31. screens/leaderboard/leaderboard_screen.dart — ranked list with badges, top 3 highlighted

 Phase 7: Polish (Hours 42-48)

 32. Micro-task creation UI on issue detail (text field + add button)
 33. Distance display on feed cards
 34. Loading/error/empty states
 35. App icon + splash screen
 36. Demo data seeding function (10-15 sample issues across all statuses)

 ---
 Hackathon Simplifications

 ┌───────────────────────┬──────────────────────────────────────────────────┬─────────────────────────────────────────┐
 │        Feature        │                     Shortcut                     │               Demo impact               │
 ├───────────────────────┼──────────────────────────────────────────────────┼─────────────────────────────────────────┤
 │ Auth                  │ Hardcoded 3 users, dropdown switcher             │ None — shows multi-user without login   │
 ├───────────────────────┼──────────────────────────────────────────────────┼─────────────────────────────────────────┤
 │ EXIF parsing          │ DateTime + GPS only, skip XMP/IPTC               │ Sufficient for duplicate detection demo │
 ├───────────────────────┼──────────────────────────────────────────────────┼─────────────────────────────────────────┤
 │ GPS radius query      │ Client-side Haversine filter (all issues loaded) │ Identical at demo scale (<500 docs)     │
 ├───────────────────────┼──────────────────────────────────────────────────┼─────────────────────────────────────────┤
 │ Trust scores          │ Hardcoded per user (0.9, 0.5, 0.3)               │ Shows weighted verification concept     │
 ├───────────────────────┼──────────────────────────────────────────────────┼─────────────────────────────────────────┤
 │ FCM push              │ Position stream + local notification (no server) │ Same UX                                 │
 ├───────────────────────┼──────────────────────────────────────────────────┼─────────────────────────────────────────┤
 │ Micro-task assignment │ Self-assign via tap, no matching algorithm       │ Shows the workflow                      │
 ├───────────────────────┼──────────────────────────────────────────────────┼─────────────────────────────────────────┤
 │ Leaderboard           │ All-time query labeled "This Week"               │ Looks identical                         │
 ├───────────────────────┼──────────────────────────────────────────────────┼─────────────────────────────────────────┤
 │ Map clustering        │ Simple markers, no clustering                    │ Fine for <50 issues                     │
 └───────────────────────┴──────────────────────────────────────────────────┴─────────────────────────────────────────┘

 ---
 Verification Plan

 1. Report flow: Open app → tap FAB → camera captures photo → form auto-fills GPS → submit → issue appears in feed with "Pending" status
 2. Duplicate detection: Submit same-location same-category issue → merged as upvote, priority score increments, user notified
 3. Status lifecycle: Change issue status through Pending → Assigned → In Progress → Resolved → Verified (via detail screen)
 4. Verification: Switch to high-trust user → navigate near Resolved issue → notification prompts verification → take photo + survey → issue becomes
 Verified
 5. Credits: Check that each action awards correct points → leaderboard reflects rankings → badges appear on profile
 6. Map: All issues visible as colored markers → tap opens detail
 7. Micro-tasks: Create checklist items on issue → self-assign → mark complete → issue resolves when all done
 8. Contributor popup: When issue reaches Verified → celebratory dialog shows all participants