// Platform type enum for filtering news by platform
enum PlatformType {
  MOBILE,
  WEB,
  ALL
}

// Helper extension to convert string to enum
extension PlatformTypeExtension on PlatformType {
  String get name {
    switch (this) {
      case PlatformType.MOBILE:
        return 'Mobil';
      case PlatformType.WEB:
        return 'Web';
      case PlatformType.ALL:
        return 'Tümü';
      default:
        return 'Tümü';
    }
  }
  
  static PlatformType fromString(String value) {
    return PlatformType.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => PlatformType.ALL,
    );
  }
}
