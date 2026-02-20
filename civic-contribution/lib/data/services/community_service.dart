import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_contribution/domain/models/community.dart';

/// Single responsibility: all Firestore I/O for communities collection.
class CommunityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _communities =>
      _db.collection('communities');

  /// Prefix range query on name field.
  Future<List<Community>> searchCommunities(String query) async {
    if (query.isEmpty) return [];
    final snap = await _communities
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    return snap.docs
        .map((d) => Community.fromMap(d.id, d.data()))
        .toList();
  }

  Future<Community?> getCommunity(String id) async {
    final doc = await _communities.doc(id).get();
    if (!doc.exists) return null;
    return Community.fromMap(doc.id, doc.data()!);
  }

  Future<String> createCommunity(String name, String createdBy) async {
    final docRef = await _communities.add({
      'name': name,
      'createdBy': createdBy,
      'adminUids': <String>[],
      'memberCount': 1,
    });
    return docRef.id;
  }

  Future<void> joinCommunity(String communityId) async {
    await _communities.doc(communityId).update({
      'memberCount': FieldValue.increment(1),
    });
  }

  /// Adds a user to the community's adminUids array.
  Future<void> addAdminToCommunity(String communityId, String userId) async {
    await _communities.doc(communityId).update({
      'adminUids': FieldValue.arrayUnion([userId]),
    });
  }

  /// Decrements memberCount and removes userId from adminUids.
  Future<void> leaveCommunity(String communityId, String userId) async {
    await _communities.doc(communityId).update({
      'memberCount': FieldValue.increment(-1),
      'adminUids': FieldValue.arrayRemove([userId]),
    });
  }

  /// Removes a user from the community's adminUids array.
  Future<void> removeAdminFromCommunity(
      String communityId, String userId) async {
    await _communities.doc(communityId).update({
      'adminUids': FieldValue.arrayRemove([userId]),
    });
  }

  /// Deletes the community document.
  Future<void> deleteCommunity(String communityId) async {
    await _communities.doc(communityId).delete();
  }

  /// All communities stream (for optional browsing).
  Stream<List<Community>> getCommunitiesStream() {
    return _communities.snapshots().map((snap) =>
        snap.docs.map((d) => Community.fromMap(d.id, d.data())).toList());
  }
}
