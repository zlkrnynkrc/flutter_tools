// Base entity with metadata
abstract class BaseEntity {
  int? id;
  DateTime? createdAt;
  DateTime? updatedAt;

  Map<String, dynamic> toMap();
  void fromMap(Map<String, dynamic> map);

  // Add metadata to map
  Map<String, dynamic> toMapWithMetadata() {
    final map = toMap();
    map['created_at'] = createdAt?.toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();
    return map;
  }

  // Extract metadata from map
  void fromMapWithMetadata(Map<String, dynamic> map) {
    fromMap(map);
    createdAt =
        map['created_at'] != null ? DateTime.parse(map['created_at']) : null;
    updatedAt =
        map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null;
  }
}
