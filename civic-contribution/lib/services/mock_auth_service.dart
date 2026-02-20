import '../models/user_profile.dart';

class MockUser {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final double trustScore;

  const MockUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.trustScore,
  });
}

class MockAuthService {
  static const List<MockUser> mockUsers = [
    MockUser(
      id: 'user_alice',
      displayName: 'Alice (High Trust)',
      trustScore: 0.9,
    ),
    MockUser(
      id: 'user_bob',
      displayName: 'Bob (Medium Trust)',
      trustScore: 0.5,
    ),
    MockUser(
      id: 'user_carol',
      displayName: 'Carol (New User)',
      trustScore: 0.3,
    ),
    MockUser(
      id: 'user_david',
      displayName: 'David (Official)',
      trustScore: 1.0,
    ),
  ];

  String _currentUserId = mockUsers[0].id;

  String get currentUserId => _currentUserId;

  MockUser get currentUser =>
      mockUsers.firstWhere((u) => u.id == _currentUserId);

  void switchUser(String userId) {
    assert(mockUsers.any((u) => u.id == userId));
    _currentUserId = userId;
  }

  UserProfile currentUserProfile({
    int civicCredits = 0,
    int issuesReported = 0,
    int verificationsCompleted = 0,
    int tasksCompleted = 0,
    List<Badge> badges = const [],
  }) {
    final u = currentUser;
    return UserProfile(
      id: u.id,
      displayName: u.displayName,
      avatarUrl: u.avatarUrl,
      trustScore: u.trustScore,
      civicCredits: civicCredits,
      badges: badges,
      issuesReported: issuesReported,
      verificationsCompleted: verificationsCompleted,
      tasksCompleted: tasksCompleted,
    );
  }
}
