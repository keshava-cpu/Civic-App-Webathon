import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:civic_contribution/core/supabase_config.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/domain/models/micro_task.dart';
import 'package:civic_contribution/domain/models/user_profile.dart';
import 'package:civic_contribution/domain/models/verification.dart';

/// Single responsibility: all database I/O for issues, users, verifications,
/// and micro-tasks using Supabase PostgreSQL.
class DatabaseService {
  SupabaseClient get _db => SupabaseConfig.client;

  // ── Issues ──────────────────────────────────────────────────────────────

  Stream<List<Issue>> getIssuesStream() {
    return _db
        .from('issues')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .handleError((e) {
          debugPrint('[DB] Error in getIssuesStream: $e');
        })
        .map((rows) {
          debugPrint('[DB] getIssuesStream returned ${rows.length} issues');
          return rows.map((r) => Issue.fromMap(r['id'] as String, r)).toList();
        });
  }

  Future<String> createIssue(Issue issue) async {
    try {
      debugPrint('[DB] Creating issue: ${issue.reporterId} | community: ${issue.communityId}');
      final res = await _db
          .from('issues')
          .insert(issue.toMap())
          .select('id')
          .single();
      final id = res['id'] as String;
      debugPrint('[DB] Issue created: $id');
      return id;
    } on PostgrestException catch (e) {
      debugPrint('[DB] PostgreSQL error: ${e.message} (code: ${e.code})');
      rethrow;
    } catch (e) {
      debugPrint('[DB] Unexpected error: $e');
      rethrow;
    }
  }

  Future<void> updateIssueStatus(String issueId, String status) async {
    await _db.from('issues').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', issueId);
  }

  Future<void> upvoteIssue(String issueId, String userId) async {
    await _db.rpc('upvote_issue', params: {
      'issue_id': issueId,
      'user_id': userId,
    });
  }

  Future<void> mergeIssue(String targetId, String duplicateId) async {
    await _db.rpc('merge_issue', params: {
      'target_id': targetId,
      'duplicate_id': duplicateId,
    });
  }

  Future<List<Issue>> getAllIssuesOnce() async {
    final rows = await _db
        .from('issues')
        .select()
        .order('created_at', ascending: false);
    return rows.map((r) => Issue.fromMap(r['id'] as String, r)).toList();
  }

  Future<List<Issue>> getAllIssuesByCommunityOnce(String communityId) async {
    final rows = await _db
        .from('issues')
        .select()
        .eq('community_id', communityId)
        .order('created_at', ascending: false);
    return rows.map((r) => Issue.fromMap(r['id'] as String, r)).toList();
  }

  Future<Issue?> getIssue(String issueId) async {
    final rows = await _db.from('issues').select().eq('id', issueId).limit(1);
    if (rows.isEmpty) return null;
    return Issue.fromMap(rows.first['id'] as String, rows.first);
  }

  // ── MicroTasks ───────────────────────────────────────────────────────────

  Stream<List<MicroTask>> getMicroTasksStream(String issueId) {
    return _db
        .from('micro_tasks')
        .stream(primaryKey: ['id'])
        .eq('issue_id', issueId)
        .map((rows) =>
            rows.map((r) => MicroTask.fromMap(r['id'] as String, r)).toList());
  }

  Future<void> addMicroTask(String issueId, MicroTask task) async {
    await _db.from('micro_tasks').insert(task.toMap());
  }

  Future<void> assignMicroTask(
      String issueId, String taskId, String userId) async {
    await _db
        .from('micro_tasks')
        .update({'assignee_id': userId})
        .eq('id', taskId);
  }

  Future<void> completeMicroTask(String issueId, String taskId) async {
    await _db.from('micro_tasks').update({
      'completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);
  }

  // ── Verifications ────────────────────────────────────────────────────────

  Stream<List<Verification>> getVerificationsStream(String issueId) {
    return _db
        .from('verifications')
        .stream(primaryKey: ['id'])
        .eq('issue_id', issueId)
        .map((rows) => rows
            .map((r) => Verification.fromMap(r['id'] as String, r))
            .toList());
  }

  Future<void> addVerification(
      String issueId, Verification verification) async {
    await _db.from('verifications').insert(verification.toMap());
  }

  Future<Verification?> getUserVerification(
      String issueId, String userId) async {
    final rows = await _db
        .from('verifications')
        .select()
        .eq('issue_id', issueId)
        .eq('verifier_id', userId)
        .limit(1);
    if (rows.isEmpty) return null;
    return Verification.fromMap(rows.first['id'] as String, rows.first);
  }

  Future<void> updateVerification(
      String issueId, String verificationId, Map<String, dynamic> data) async {
    await _db.from('verifications').update(data).eq('id', verificationId);
  }

  // ── Users ────────────────────────────────────────────────────────────────

  Future<UserProfile?> getUser(String userId) async {
    final rows =
        await _db.from('users').select().eq('id', userId).limit(1);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first['id'] as String, rows.first);
  }

  Future<void> upsertUser(UserProfile user) async {
    await _db.from('users').upsert({
      'id': user.id,
      ...user.toMap(),
    });
  }

  Future<void> incrementUserCredits(String userId, int points) async {
    await _db.rpc('increment_user_credits', params: {
      'user_id': userId,
      'points': points,
    });
  }

  Future<void> incrementUserStat(String userId, String field) async {
    await _db.rpc('increment_user_stat', params: {
      'user_id': userId,
      'field_name': field,
    });
  }

  Future<void> addBadge(String userId, Map<String, dynamic> badge) async {
    await _db.rpc('add_user_badge', params: {
      'user_id': userId,
      'badge': badge,
    });
  }

  Stream<List<UserProfile>> getLeaderboardStream() {
    return _db
        .from('users')
        .stream(primaryKey: ['id'])
        .order('civic_credits', ascending: false)
        .limit(50)
        .handleError((e) {
          debugPrint('[DB] Error in getLeaderboardStream: $e');
        })
        .map((rows) {
          final users = rows
              .where((r) => r['is_admin'] == false)
              .map((r) => UserProfile.fromMap(r['id'] as String, r))
              .toList();
          debugPrint('[DB] getLeaderboardStream returned ${users.length} users (top 50, non-admin)');
          return users;
        });
  }

  // ── Community-scoped streams ──────────────────────────────────────────────

  Stream<List<Issue>> getIssuesByCommunityStream(String communityId) {
    return _db
        .from('issues')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .order('created_at', ascending: false)
        .handleError((e) {
          debugPrint('[DB] Error in getIssuesByCommunityStream($communityId): $e');
        })
        .map((rows) {
          debugPrint('[DB] getIssuesByCommunityStream($communityId) returned ${rows.length} issues');
          return rows.map((r) => Issue.fromMap(r['id'] as String, r)).toList();
        });
  }

  Stream<List<Issue>> getUnresolvedIssuesByCommunityStream(
      String communityId) {
    return _db
        .from('issues')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .order('created_at', ascending: false)
        .handleError((e) {
          debugPrint('[DB] Error in getUnresolvedIssuesByCommunityStream($communityId): $e');
        })
        .map((rows) {
          final filtered = rows
              .where((r) => ['pending', 'assigned', 'inProgress']
                  .contains(r['status']))
              .map((r) => Issue.fromMap(r['id'] as String, r))
              .toList();
          debugPrint('[DB] getUnresolvedIssuesByCommunityStream($communityId) returned ${filtered.length} unresolved issues');
          return filtered;
        });
  }

  Stream<List<UserProfile>> getLeaderboardByCommunityStream(
      String communityId) {
    return _db
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .order('civic_credits', ascending: false)
        .limit(50)
        .handleError((e) {
          debugPrint('[DB] Error in getLeaderboardByCommunityStream($communityId): $e');
        })
        .map((rows) {
          final users = rows
              .where((r) => r['is_admin'] == false)
              .map((r) => UserProfile.fromMap(r['id'] as String, r))
              .toList();
          debugPrint('[DB] getLeaderboardByCommunityStream($communityId) returned ${users.length} users (top 50, non-admin)');
          return users;
        });
  }

  Future<List<Issue>> getIssuesByCommunityOnce(String communityId) async {
    final rows = await _db
        .from('issues')
        .select()
        .eq('community_id', communityId)
        .order('created_at', ascending: false);
    return rows.map((r) => Issue.fromMap(r['id'] as String, r)).toList();
  }

  // ── Admin operations ─────────────────────────────────────────────────────

  Future<void> setUserAsAdmin(String userId) async {
    await _db.from('users').update({'is_admin': true}).eq('id', userId);
  }

  Future<void> updateUserCommunity(String userId, String communityId) async {
    await _db
        .from('users')
        .update({'community_id': communityId})
        .eq('id', userId);
  }

  Future<void> clearUserCommunity(String userId) async {
    await _db.from('users').update({
      'community_id': null,
      'is_admin': false,
    }).eq('id', userId);
  }

  Future<void> deleteUser(String userId) async {
    await _db.from('users').delete().eq('id', userId);
  }

  Future<void> resetCommunityUsers(String communityId) async {
    await _db.rpc('reset_community_users', params: {
      'p_community_id': communityId,
    });
  }
}
