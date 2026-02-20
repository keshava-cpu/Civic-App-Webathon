import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/domain/models/micro_task.dart';
import 'package:civic_contribution/domain/models/user_profile.dart';
import 'package:civic_contribution/domain/models/verification.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Issues ──────────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _issues =>
      _db.collection('issues');

  Stream<List<Issue>> getIssuesStream() {
    return _issues
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Issue.fromFirestore(d)).toList());
  }

  Future<String> createIssue(Issue issue) async {
    final docRef = await _issues.add(issue.toFirestore());
    return docRef.id;
  }

  Future<void> updateIssueStatus(String issueId, String status) async {
    await _issues.doc(issueId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> upvoteIssue(String issueId, String userId) async {
    await _issues.doc(issueId).update({
      'upvoterIds': FieldValue.arrayUnion([userId]),
      'priorityScore': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> mergeIssue(String targetId, String duplicateId) async {
    await _issues.doc(targetId).update({
      'mergedIssueIds': FieldValue.arrayUnion([duplicateId]),
      'priorityScore': FieldValue.increment(2),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Issue>> getAllIssuesOnce() async {
    final snap = await _issues.get();
    return snap.docs.map((d) => Issue.fromFirestore(d)).toList();
  }

  Future<Issue?> getIssue(String issueId) async {
    final doc = await _issues.doc(issueId).get();
    if (!doc.exists) return null;
    return Issue.fromFirestore(doc);
  }

  // ── MicroTasks ───────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> _microTasks(String issueId) =>
      _issues.doc(issueId).collection('microTasks');

  Stream<List<MicroTask>> getMicroTasksStream(String issueId) {
    return _microTasks(issueId).snapshots().map(
          (snap) => snap.docs
              .map((d) => MicroTask.fromFirestore(d, issueId))
              .toList(),
        );
  }

  Future<void> addMicroTask(String issueId, MicroTask task) async {
    await _microTasks(issueId).add(task.toFirestore());
  }

  Future<void> assignMicroTask(
      String issueId, String taskId, String userId) async {
    await _microTasks(issueId).doc(taskId).update({'assigneeId': userId});
  }

  Future<void> completeMicroTask(String issueId, String taskId) async {
    await _microTasks(issueId).doc(taskId).update({
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Verifications ────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> _verifications(String issueId) =>
      _issues.doc(issueId).collection('verifications');

  Stream<List<Verification>> getVerificationsStream(String issueId) {
    return _verifications(issueId).snapshots().map(
          (snap) => snap.docs
              .map((d) => Verification.fromFirestore(d, issueId))
              .toList(),
        );
  }

  Future<void> addVerification(
      String issueId, Verification verification) async {
    await _verifications(issueId).add(verification.toFirestore());
  }

  // ── Users ────────────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<UserProfile?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<void> upsertUser(UserProfile user) async {
    await _users.doc(user.id).set(user.toFirestore(), SetOptions(merge: true));
  }

  Future<void> incrementUserCredits(String userId, int points) async {
    await _users.doc(userId).set({
      'civicCredits': FieldValue.increment(points),
    }, SetOptions(merge: true));
  }

  Future<void> incrementUserStat(String userId, String field) async {
    await _users.doc(userId).set({
      field: FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> addBadge(String userId, Map<String, dynamic> badge) async {
    await _users.doc(userId).update({
      'badges': FieldValue.arrayUnion([badge]),
    });
  }

  Stream<List<UserProfile>> getLeaderboardStream() {
    return _users
        .orderBy('civicCredits', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserProfile.fromFirestore(d)).toList());
  }

  // ── F4 — Verification reversal ────────────────────────────────────────

  Future<Verification?> getUserVerification(String issueId, String userId) async {
    final snap = await _verifications(issueId)
        .where('verifierId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Verification.fromFirestore(snap.docs.first, issueId);
  }

  Future<void> updateVerification(
      String issueId, String verificationId, Map<String, dynamic> data) async {
    await _verifications(issueId).doc(verificationId).update(data);
  }

  // ── F1 — Community-scoped streams ─────────────────────────────────────

  Stream<List<Issue>> getIssuesByCommunityStream(String communityId) {
    return _issues
        .where('communityId', isEqualTo: communityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Issue.fromFirestore(d)).toList());
  }

  Stream<List<UserProfile>> getLeaderboardByCommunityStream(String communityId) {
    return _users
        .where('communityId', isEqualTo: communityId)
        .where('isAdmin', isEqualTo: false)
        .orderBy('civicCredits', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserProfile.fromFirestore(d)).toList());
  }

  Future<List<Issue>> getIssuesByCommunityOnce(String communityId) async {
    final snap = await _issues
        .where('communityId', isEqualTo: communityId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Issue.fromFirestore(d)).toList();
  }

  // ── F2 — Direct admin flag ─────────────────────────────────────────

  Future<void> setUserAsAdmin(String userId) async {
    await _users.doc(userId).update({'isAdmin': true});
  }

  // ── F1 — Community ID update on profile ───────────────────────────────

  Future<void> updateUserCommunity(String userId, String communityId) async {
    await _users.doc(userId).update({'communityId': communityId});
  }

  // ── Seeding ──────────────────────────────────────────────────────────────
  Future<void> seedDemoData() async {
    final existing = await _issues.limit(1).get();
    if (existing.docs.isNotEmpty) return; // Already seeded

    final now = DateTime.now();
    final demoIssues = [
      {
        'reporterId': 'user_alice',
        'category': 'pothole',
        'description': 'Large pothole on main street causing damage to vehicles',
        'location': const GeoPoint(12.9716, 77.5946),
        'address': '12 Main Street, Downtown',
        'photoUrl': null,
        'photoHash': null,
        'exifData': null,
        'status': 'verified',
        'priorityScore': 8,
        'upvoterIds': ['user_bob', 'user_carol', 'user_david'],
        'mergedIssueIds': [],
        'assignedTo': 'user_david',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      },
      {
        'reporterId': 'user_bob',
        'category': 'streetlight',
        'description': 'Street light not working near park entrance',
        'location': const GeoPoint(12.9720, 77.5950),
        'address': 'Park Entrance, Oak Avenue',
        'photoUrl': null,
        'status': 'inProgress',
        'priorityScore': 5,
        'upvoterIds': ['user_alice'],
        'mergedIssueIds': [],
        'assignedTo': 'user_david',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 10))),
      },
      {
        'reporterId': 'user_carol',
        'category': 'garbage',
        'description': 'Overflowing garbage bins not collected for a week',
        'location': const GeoPoint(12.9710, 77.5940),
        'address': '5 Garden Road',
        'photoUrl': null,
        'status': 'pending',
        'priorityScore': 3,
        'upvoterIds': [],
        'mergedIssueIds': [],
        'assignedTo': null,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      },
      {
        'reporterId': 'user_alice',
        'category': 'flooding',
        'description': 'Water logging after rain, road impassable',
        'location': const GeoPoint(12.9725, 77.5955),
        'address': 'Junction of 2nd Cross and MG Road',
        'photoUrl': null,
        'status': 'resolved',
        'priorityScore': 10,
        'upvoterIds': ['user_bob', 'user_carol'],
        'mergedIssueIds': [],
        'assignedTo': 'user_david',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'reporterId': 'user_david',
        'category': 'graffiti',
        'description': 'Graffiti on public library wall',
        'location': const GeoPoint(12.9700, 77.5930),
        'address': 'Public Library, Station Road',
        'photoUrl': null,
        'status': 'assigned',
        'priorityScore': 2,
        'upvoterIds': [],
        'mergedIssueIds': [],
        'assignedTo': 'user_bob',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 12))),
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
      },
    ];

    final batch = _db.batch();
    for (final issue in demoIssues) {
      final ref = _issues.doc();
      batch.set(ref, issue);
    }

    // Seed user profiles
    final users = [
      {
        'displayName': 'Alice (High Trust)',
        'trustScore': 0.9,
        'civicCredits': 320,
        'badges': [
          {
            'id': 'gold',
            'label': 'Gold Civic',
            'emoji': '🥇',
            'earnedAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
          }
        ],
        'issuesReported': 12,
        'verificationsCompleted': 8,
        'tasksCompleted': 5,
      },
      {
        'displayName': 'Bob (Medium Trust)',
        'trustScore': 0.5,
        'civicCredits': 95,
        'badges': [
          {
            'id': 'bronze',
            'label': 'Bronze Civic',
            'emoji': '🥉',
            'earnedAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
          }
        ],
        'issuesReported': 5,
        'verificationsCompleted': 3,
        'tasksCompleted': 2,
      },
      {
        'displayName': 'Carol (New User)',
        'trustScore': 0.3,
        'civicCredits': 20,
        'badges': [],
        'issuesReported': 1,
        'verificationsCompleted': 0,
        'tasksCompleted': 0,
      },
      {
        'displayName': 'David (Official)',
        'trustScore': 1.0,
        'civicCredits': 580,
        'badges': [
          {
            'id': 'gold',
            'label': 'Gold Civic',
            'emoji': '🥇',
            'earnedAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
          },
          {
            'id': 'official',
            'label': 'Official',
            'emoji': '✅',
            'earnedAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
          }
        ],
        'issuesReported': 20,
        'verificationsCompleted': 25,
        'tasksCompleted': 15,
      },
    ];

    final userIds = ['user_alice', 'user_bob', 'user_carol', 'user_david'];
    for (var i = 0; i < users.length; i++) {
      final ref = _users.doc(userIds[i]);
      batch.set(ref, users[i], SetOptions(merge: true));
    }

    await batch.commit();
  }
}

