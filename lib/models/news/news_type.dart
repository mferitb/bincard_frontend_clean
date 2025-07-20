// News types enum
enum NewsType {
  DUYURU,          // Genel bilgilendirmeler
  KAMPANYA,        // İndirim veya promosyon duyuruları
  BAKIM,           // Sistem bakım bildirimleri
  BILGILENDIRME,   // Kullanıcıya yönelik genel bilgiler
  GUNCELLEME,      // Yazılım veya sistem güncellemeleri
  UYARI,           // Acil veya önemli durum bildirimleri
  ETKINLIK,        // Etkinlik duyuruları
  BASIN_BULTENI,   // Medyaya yönelik açıklamalarß
  GUVENLIK,        // Güvenlik ile ilgili duyurular
  OZELLIK,         // Yeni özellik tanıtımlarıß
  HATIRLATMA,      // Son tarih veya yapılacak işlem bildirimi
  KESINTI          // Hizmet kesintisi duyuruları
}

// Helper extension to convert string to enum and get user-friendly names
extension NewsTypeExtension on NewsType {
  String get name {
    switch (this) {
      case NewsType.DUYURU:
        return 'Duyuru';
      case NewsType.KAMPANYA:
        return 'Kampanya';
      case NewsType.BAKIM:
        return 'Bakım';
      case NewsType.BILGILENDIRME:
        return 'Bilgilendirme';
      case NewsType.GUNCELLEME:
        return 'Güncelleme';
      case NewsType.UYARI:
        return 'Uyarı';
      case NewsType.ETKINLIK:
        return 'Etkinlik';
      case NewsType.BASIN_BULTENI:
        return 'Basın Bülteni';
      case NewsType.GUVENLIK:
        return 'Güvenlik';
      case NewsType.OZELLIK:
        return 'Özellik';
      case NewsType.HATIRLATMA:
        return 'Hatırlatma';
      case NewsType.KESINTI:
        return 'Kesinti';
      default:
        return 'Duyuru';
    }
  }
  
  static NewsType fromString(String value) {
    return NewsType.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => NewsType.DUYURU,
    );
  }
}
