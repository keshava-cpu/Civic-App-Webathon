import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:civic_contribution/core/supabase_config.dart';
import 'package:civic_contribution/domain/models/community.dart';

/// Single responsibility: all database I/O for communities table.
class CommunityService {
  SupabaseClient get _db => SupabaseConfig.client;

  /// Case-insensitive prefix search on name field.
  Future<List<Community>> searchCommunities(String query) async {
    if (query.isEmpty) return [];
    final rows = await _db
        .from('communities')
        .select()
        .ilike('name', '$query%');
    return rows.map((r) => Community.fromMap(r['id'] as String, r)).toList();
  }

  Future<Community?> getCommunity(String id) async {
    final rows =
        await _db.from('communities').select().eq('id', id).limit(1);
    if (rows.isEmpty) return null;
    return Community.fromMap(rows.first['id'] as String, rows.first);
  }

  Future<String> createCommunity(String name, String createdBy) async {
    final res = await _db.from('communities').insert({
      'name': name,
      'created_by': createdBy,
      'admin_uids': <String>[],
      'member_count': 1,
    }).select('id').single();
    return res['id'] as String;
  }

  Future<void> joinCommunity(String communityId) async {
    await _db.rpc('increment_community_members',
        params: {'community_id': communityId, 'delta': 1});
  }

  /// Adds a user to the community's admin_uids array.
  Future<void> addAdminToCommunity(String communityId, String userId) async {
    await _db.rpc('add_community_admin',
        params: {'community_id': communityId, 'user_id': userId});
  }

  /// Decrements member_count and removes userId from admin_uids.
  Future<void> leaveCommunity(String communityId, String userId) async {
    await _db.rpc('leave_community',
        params: {'community_id': communityId, 'user_id': userId});
  }

  /// Removes a user from the community's admin_uids array.
  Future<void> removeAdminFromCommunity(
      String communityId, String userId) async {
    await _db.rpc('remove_community_admin',
        params: {'community_id': communityId, 'user_id': userId});
  }

  /// Deletes the community row.
  Future<void> deleteCommunity(String communityId) async {
    await _db.from('communities').delete().eq('id', communityId);
  }

  /// All communities stream.
  Stream<List<Community>> getCommunitiesStream() {
    return _db
        .from('communities')
        .stream(primaryKey: ['id'])
        .map((rows) =>
            rows.map((r) => Community.fromMap(r['id'] as String, r)).toList());
  }
}
