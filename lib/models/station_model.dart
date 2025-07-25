class StationModel {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final bool active;
  final String type;
  final String city;
  final String district;
  final String street;
  final String postalCode;
  final bool? isFavorite;

  StationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.active,
    required this.type,
    required this.city,
    required this.district,
    required this.street,
    required this.postalCode,
    this.isFavorite,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id'],
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      active: json['active'],
      type: json['type'],
      city: json['city'],
      district: json['district'],
      street: json['street'],
      postalCode: json['postalCode'],
      isFavorite: json['isFavorite'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'active': active,
      'type': type,
      'city': city,
      'district': district,
      'street': street,
      'postalCode': postalCode,
      if (isFavorite != null) 'isFavorite': isFavorite,
    };
  }
} 