import 'package:demo_roketota_app/core/models/media_type.dart';

class MediaRecord {
  const MediaRecord({
    this.id,
    required this.type,
    required this.capturedAt,
    required this.filterStampPath,
    required this.originalStampPath,
    this.persistedOriginalPath,
    this.savedAt,
    required this.createdAt,
  });

  final int? id;
  final MediaType type;
  final DateTime capturedAt;
  final String filterStampPath;
  final String originalStampPath;
  final String? persistedOriginalPath;
  final DateTime? savedAt;
  final DateTime createdAt;

  bool get isSaved => savedAt != null;

  MediaRecord copyWith({
    int? id,
    MediaType? type,
    DateTime? capturedAt,
    String? filterStampPath,
    String? originalStampPath,
    String? persistedOriginalPath,
    DateTime? savedAt,
    bool clearSavedAt = false,
    DateTime? createdAt,
  }) {
    return MediaRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      capturedAt: capturedAt ?? this.capturedAt,
      filterStampPath: filterStampPath ?? this.filterStampPath,
      originalStampPath: originalStampPath ?? this.originalStampPath,
      persistedOriginalPath:
          persistedOriginalPath ?? this.persistedOriginalPath,
      savedAt: clearSavedAt ? null : (savedAt ?? this.savedAt),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'type': type.value,
      'captured_at': capturedAt.toIso8601String(),
      'filter_stamp_path': filterStampPath,
      'original_stamp_path': originalStampPath,
      'persisted_original_path': persistedOriginalPath,
      'saved_at': savedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MediaRecord.fromMap(Map<String, Object?> map) {
    return MediaRecord(
      id: map['id'] as int?,
      type: MediaType.fromValue(map['type'] as String),
      capturedAt: DateTime.parse(map['captured_at'] as String),
      filterStampPath: map['filter_stamp_path'] as String,
      originalStampPath: map['original_stamp_path'] as String,
      persistedOriginalPath: map['persisted_original_path'] as String?,
      savedAt: map['saved_at'] == null
          ? null
          : DateTime.parse(map['saved_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
