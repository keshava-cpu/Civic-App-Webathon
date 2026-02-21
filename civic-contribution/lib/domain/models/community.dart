class Community {
  final String id;
  final String name;
  final String createdBy;
  final List<String> adminUids;
  final int memberCount;

  Community({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.adminUids,
    required this.memberCount,
  });

  factory Community.fromMap(String id, Map<String, dynamic> data) {
    return Community(
      id: id,
      name: data['name'] ?? '',
      createdBy: data['created_by'] ?? data['createdBy'] ?? '',
      adminUids: List<String>.from(data['admin_uids'] ?? data['adminUids'] ?? []),
      memberCount: (data['member_count'] ?? data['memberCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'created_by': createdBy,
      'admin_uids': adminUids,
      'member_count': memberCount,
    };
  }

  Community copyWith({
    String? id,
    String? name,
    String? createdBy,
    List<String>? adminUids,
    int? memberCount,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      adminUids: adminUids ?? this.adminUids,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
