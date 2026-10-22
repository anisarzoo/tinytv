class Recording {
  final String id;
  final String channelName;
  final String? channelLogo;
  final String filePath;
  final DateTime recordedAt;
  final int durationSeconds;
  final int fileSizeBytes;

  const Recording({
    required this.id,
    required this.channelName,
    this.channelLogo,
    required this.filePath,
    required this.recordedAt,
    required this.durationSeconds,
    required this.fileSizeBytes,
  });

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final isToday = recordedAt.year == now.year &&
        recordedAt.month == now.month &&
        recordedAt.day == now.day;

    final hour = recordedAt.hour.toString().padLeft(2, '0');
    final min = recordedAt.minute.toString().padLeft(2, '0');

    if (isToday) {
      return 'Today at $hour:$min';
    }

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthName = months[recordedAt.month - 1];
    return '$monthName ${recordedAt.day}, ${recordedAt.year} • $hour:$min';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelName': channelName,
      'channelLogo': channelLogo,
      'filePath': filePath,
      'recordedAt': recordedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] as String,
      channelName: json['channelName'] as String,
      channelLogo: json['channelLogo'] as String?,
      filePath: json['filePath'] as String,
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  Recording copyWith({
    String? id,
    String? channelName,
    String? channelLogo,
    String? filePath,
    DateTime? recordedAt,
    int? durationSeconds,
    int? fileSizeBytes,
  }) {
    return Recording(
      id: id ?? this.id,
      channelName: channelName ?? this.channelName,
      channelLogo: channelLogo ?? this.channelLogo,
      filePath: filePath ?? this.filePath,
      recordedAt: recordedAt ?? this.recordedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }
}
