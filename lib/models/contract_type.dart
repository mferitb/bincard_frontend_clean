enum ContractType {
  UYELIK_SOZLESMESI,
  AYDINLATMA_METNI,
  VERI_ISLEME_IZNI,
  GIZLILIK_POLITIKASI,
  KULLANIM_KOSULLARI,
  DIGER
}

extension ContractTypeExtension on ContractType {
  String get value {
    switch (this) {
      case ContractType.UYELIK_SOZLESMESI:
        return 'UYELIK_SOZLESMESI';
      case ContractType.AYDINLATMA_METNI:
        return 'AYDINLATMA_METNI';
      case ContractType.VERI_ISLEME_IZNI:
        return 'VERI_ISLEME_IZNI';
      case ContractType.GIZLILIK_POLITIKASI:
        return 'GIZLILIK_POLITIKASI';
      case ContractType.KULLANIM_KOSULLARI:
        return 'KULLANIM_KOSULLARI';
      case ContractType.DIGER:
        return 'DIGER';
    }
  }

  static ContractType fromString(String value) {
    switch (value) {
      case 'UYELIK_SOZLESMESI':
        return ContractType.UYELIK_SOZLESMESI;
      case 'AYDINLATMA_METNI':
        return ContractType.AYDINLATMA_METNI;
      case 'VERI_ISLEME_IZNI':
        return ContractType.VERI_ISLEME_IZNI;
      case 'GIZLILIK_POLITIKASI':
        return ContractType.GIZLILIK_POLITIKASI;
      case 'KULLANIM_KOSULLARI':
        return ContractType.KULLANIM_KOSULLARI;
      default:
        return ContractType.DIGER;
    }
  }

  String get displayName {
    switch (this) {
      case ContractType.UYELIK_SOZLESMESI:
        return 'Üyelik Sözleşmesi';
      case ContractType.AYDINLATMA_METNI:
        return 'KVKK Aydınlatma Metni';
      case ContractType.VERI_ISLEME_IZNI:
        return 'Veri İşleme İzni';
      case ContractType.GIZLILIK_POLITIKASI:
        return 'Gizlilik Politikası';
      case ContractType.KULLANIM_KOSULLARI:
        return 'Kullanım Koşulları';
      case ContractType.DIGER:
        return 'Diğer';
    }
  }
}
