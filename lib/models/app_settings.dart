class AppSettings {
  final bool isServiceEnabled;
  final int blockedCallsCount;

  AppSettings({
    this.isServiceEnabled = false,
    this.blockedCallsCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'isServiceEnabled': isServiceEnabled,
      'blockedCallsCount': blockedCallsCount,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isServiceEnabled: json['isServiceEnabled'] as bool? ?? false,
      blockedCallsCount: json['blockedCallsCount'] as int? ?? 0,
    );
  }

  AppSettings copyWith({
    bool? isServiceEnabled,
    int? blockedCallsCount,
  }) {
    return AppSettings(
      isServiceEnabled: isServiceEnabled ?? this.isServiceEnabled,
      blockedCallsCount: blockedCallsCount ?? this.blockedCallsCount,
    );
  }
}
