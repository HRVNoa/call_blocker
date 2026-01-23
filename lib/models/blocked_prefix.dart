class BlockedPrefix {
  final String prefix;
  final String description;
  final bool isEnabled;

  BlockedPrefix({
    required this.prefix,
    required this.description,
    this.isEnabled = true,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'prefix': prefix,
      'description': description,
      'isEnabled': isEnabled,
    };
  }

  // Create from JSON
  factory BlockedPrefix.fromJson(Map<String, dynamic> json) {
    return BlockedPrefix(
      prefix: json['prefix'] as String,
      description: json['description'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  BlockedPrefix copyWith({
    String? prefix,
    String? description,
    bool? isEnabled,
  }) {
    return BlockedPrefix(
      prefix: prefix ?? this.prefix,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
