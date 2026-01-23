enum BlockMode {
  directBlock,      // Blocage direct sans répondre
  voiceMessage,     // Répondre avec message vocal puis raccrocher
}

class AppSettings {
  final BlockMode blockMode;
  final String? audioFilePath;
  final bool isServiceEnabled;
  final int blockedCallsCount;

  AppSettings({
    this.blockMode = BlockMode.directBlock,
    this.audioFilePath,
    this.isServiceEnabled = false,
    this.blockedCallsCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'blockMode': blockMode.index,
      'audioFilePath': audioFilePath,
      'isServiceEnabled': isServiceEnabled,
      'blockedCallsCount': blockedCallsCount,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      blockMode: BlockMode.values[json['blockMode'] as int? ?? 0],
      audioFilePath: json['audioFilePath'] as String?,
      isServiceEnabled: json['isServiceEnabled'] as bool? ?? false,
      blockedCallsCount: json['blockedCallsCount'] as int? ?? 0,
    );
  }

  AppSettings copyWith({
    BlockMode? blockMode,
    String? audioFilePath,
    bool? isServiceEnabled,
    int? blockedCallsCount,
  }) {
    return AppSettings(
      blockMode: blockMode ?? this.blockMode,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      isServiceEnabled: isServiceEnabled ?? this.isServiceEnabled,
      blockedCallsCount: blockedCallsCount ?? this.blockedCallsCount,
    );
  }
}
