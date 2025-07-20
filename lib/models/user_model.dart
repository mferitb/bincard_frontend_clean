class UserProfile {
  final String? name;
  final String? surname;
  final String? profileUrl;
  final bool? active;
  final bool? phoneVerified;
  final String? birthday;
  final String? identityNumber;
  final String? email;
  final String? userNumber;
  final bool? emailVerified;
  final bool? walletActivated;
  final List<String>? roles;

  UserProfile({
    this.name,
    this.surname,
    this.profileUrl,
    this.active,
    this.phoneVerified,
    this.birthday,
    this.identityNumber,
    this.email,
    this.userNumber,
    this.emailVerified,
    this.walletActivated,
    this.roles,
  });

  // API yanıtından model oluştur
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      surname: json['surname'],
      profileUrl: json['profilePicture'],
      active: json['active'],
      phoneVerified: json['phoneVerified'],
      birthday: json['birthDate'],
      identityNumber: json['nationalId'],
      email: json['email'],
      userNumber: json['userNumber'],
      emailVerified: json['emailVerified'],
      walletActivated: json['walletActivated'],
      roles: json['roles'] != null ? List<String>.from(json['roles']) : null,
    );
  }

  // Modeli JSON'a dönüştür (API'ye gönderilecek)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surname': surname,
      'email': email,
    };
  }

  // Tam ad döndürme yardımcı metodu
  String get fullName => '$name $surname'.trim();

  // Doğum tarihini formatla
  String get formattedBirthday {
    if (birthday == null) return '';
    try {
      final date = DateTime.parse(birthday!);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return '';
    }
  }
  
  // For backward compatibility with existing screens
  String get formattedCreatedAt => 'Bilgi Yok';
  String get formattedUpdatedAt => 'Bilgi Yok';

  // Boş profil oluştur
  factory UserProfile.empty() {
    return UserProfile(
      name: '',
      surname: '',
      email: '',
      active: true,
      phoneVerified: false,
      emailVerified: false,
      walletActivated: false,
    );
  }
}