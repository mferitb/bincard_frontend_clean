import 'dart:convert';

class PaymentPoint {
  final int id;
  final String name;
  final Location location;
  final Address address;
  final String contactNumber;
  final String workingHours;
  final List<String> paymentMethods;
  final String description;
  final bool active;
  final List<dynamic> photos;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final double? distance;

  PaymentPoint({
    required this.id,
    required this.name,
    required this.location,
    required this.address,
    required this.contactNumber,
    required this.workingHours,
    required this.paymentMethods,
    required this.description,
    required this.active,
    required this.photos,
    required this.createdAt,
    required this.lastUpdated,
    this.distance,
  });

  factory PaymentPoint.fromJson(Map<String, dynamic> json) {
    return PaymentPoint(
      id: json['id'],
      name: json['name'],
      location: Location.fromJson(json['location']),
      address: Address.fromJson(json['address']),
      contactNumber: json['contactNumber'],
      workingHours: json['workingHours'],
      paymentMethods: List<String>.from(json['paymentMethods'] ?? []),
      description: json['description'],
      active: json['active'],
      photos: json['photos'] ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
    );
  }
}

class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class Address {
  final String street;
  final String district;
  final String city;
  final String postalCode;

  Address({
    required this.street,
    required this.district,
    required this.city,
    required this.postalCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      district: json['district'],
      city: json['city'],
      postalCode: json['postalCode'],
    );
  }
} 