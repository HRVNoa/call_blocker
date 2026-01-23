class BlockedCall {
  final String phoneNumber;
  final DateTime timestamp;
  final String matchedPrefix;

  BlockedCall({
    required this.phoneNumber,
    required this.timestamp,
    required this.matchedPrefix,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'timestamp': timestamp.toIso8601String(),
      'matchedPrefix': matchedPrefix,
    };
  }

  factory BlockedCall.fromJson(Map<String, dynamic> json) {
    return BlockedCall(
      phoneNumber: json['phoneNumber'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      matchedPrefix: json['matchedPrefix'] as String,
    );
  }

  // Format for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String get formattedDateTime {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} à ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
