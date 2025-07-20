// News priority levels enum
enum NewsPriority {
  COK_DUSUK,    // VERY_LOW
  DUSUK,        // LOW
  NORMAL,       // NORMAL
  ORTA_YUKSEK,  // MEDIUM_HIGH
  YUKSEK,       // HIGH
  COK_YUKSEK,   // VERY_HIGH
  KRITIK        // CRITICAL
}

// Helper extension to convert string to enum
extension NewsPriorityExtension on NewsPriority {
  String get name {
    switch (this) {
      case NewsPriority.COK_DUSUK:
        return 'ÇOK DÜŞÜK';
      case NewsPriority.DUSUK:
        return 'DÜŞÜK';
      case NewsPriority.NORMAL:
        return 'NORMAL';
      case NewsPriority.ORTA_YUKSEK:
        return 'ORTA YÜKSEK';
      case NewsPriority.YUKSEK:
        return 'YÜKSEK';
      case NewsPriority.COK_YUKSEK:
        return 'ÇOK YÜKSEK';
      case NewsPriority.KRITIK:
        return 'KRİTİK';
      default:
        return 'NORMAL';
    }
  }
  
  static NewsPriority fromString(String value) {
    return NewsPriority.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => NewsPriority.NORMAL,
    );
  }
}
