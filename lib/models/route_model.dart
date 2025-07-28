import 'station_model.dart';

class RouteModel {
  final int id;
  final String name;
  final String code;
  final String? description;
  final String routeType;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isDeleted;
  final StationModel startStation;
  final StationModel endStation;
  final int estimatedDurationMinutes;
  final double totalDistanceKm;
  final RouteSchedule schedule;
  final List<DirectionModel> directions;

  RouteModel({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.routeType,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isDeleted,
    required this.startStation,
    required this.endStation,
    required this.estimatedDurationMinutes,
    required this.totalDistanceKm,
    required this.schedule,
    required this.directions,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      routeType: json['routeType'],
      color: json['color'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'],
      isDeleted: json['isDeleted'],
      startStation: StationModel.fromJson(json['startStation']),
      endStation: StationModel.fromJson(json['endStation']),
      estimatedDurationMinutes: json['estimatedDurationMinutes'],
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      schedule: RouteSchedule.fromJson(json['schedule']),
      directions: (json['directions'] as List?)?.map((e) => DirectionModel.fromJson(e)).toList() ?? [],
    );
  }
}

// New model for search API response
class RouteSearchModel {
  final int id;
  final String name;
  final String code;
  final String routeType;
  final String color;
  final String startStationName;
  final String endStationName;
  final int estimatedDurationMinutes;
  final double totalDistanceKm;
  final RouteSearchSchedule routeSchedule;
  final bool hasOutgoingDirection;
  final bool hasReturnDirection;

  RouteSearchModel({
    required this.id,
    required this.name,
    required this.code,
    required this.routeType,
    required this.color,
    required this.startStationName,
    required this.endStationName,
    required this.estimatedDurationMinutes,
    required this.totalDistanceKm,
    required this.routeSchedule,
    required this.hasOutgoingDirection,
    required this.hasReturnDirection,
  });

  factory RouteSearchModel.fromJson(Map<String, dynamic> json) {
    return RouteSearchModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      routeType: json['routeType'],
      color: json['color'],
      startStationName: json['startStationName'],
      endStationName: json['endStationName'],
      estimatedDurationMinutes: json['estimatedDurationMinutes'],
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      routeSchedule: RouteSearchSchedule.fromJson(json['routeSchedule']),
      hasOutgoingDirection: json['hasOutgoingDirection'],
      hasReturnDirection: json['hasReturnDirection'],
    );
  }
}

class RouteSearchSchedule {
  final List<String> weekdayHours;
  final List<String> weekendHours;

  RouteSearchSchedule({required this.weekdayHours, required this.weekendHours});

  factory RouteSearchSchedule.fromJson(Map<String, dynamic> json) {
    return RouteSearchSchedule(
      weekdayHours: List<String>.from(json['weekdayHours'] ?? []),
      weekendHours: List<String>.from(json['weekendHours'] ?? []),
    );
  }
}

class RouteSchedule {
  final List<String> weekdayHours;
  final List<String> weekendHours;

  RouteSchedule({required this.weekdayHours, required this.weekendHours});

  factory RouteSchedule.fromJson(Map<String, dynamic> json) {
    return RouteSchedule(
      weekdayHours: List<String>.from(json['weekdayHours'] ?? []),
      weekendHours: List<String>.from(json['weekendHours'] ?? []),
    );
  }
}

class DirectionModel {
  final int id;
  final String name;
  final String type;
  final StationModel startStation;
  final StationModel endStation;
  final int estimatedDurationMinutes;
  final double totalDistanceKm;
  final bool isActive;
  final List<StationNodeModel> stationNodes;

  DirectionModel({
    required this.id,
    required this.name,
    required this.type,
    required this.startStation,
    required this.endStation,
    required this.estimatedDurationMinutes,
    required this.totalDistanceKm,
    required this.isActive,
    required this.stationNodes,
  });

  factory DirectionModel.fromJson(Map<String, dynamic> json) {
    return DirectionModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      startStation: StationModel.fromJson(json['startStation']),
      endStation: StationModel.fromJson(json['endStation']),
      estimatedDurationMinutes: json['estimatedDurationMinutes'],
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      isActive: json['isActive'],
      stationNodes: (json['stationNodes'] as List?)?.map((e) => StationNodeModel.fromJson(e)).toList() ?? [],
    );
  }
}

class StationNodeModel {
  final int id;
  final StationModel fromStation;
  final StationModel toStation;
  final int sequenceOrder;
  final int estimatedTravelTimeMinutes;
  final double distanceKm;
  final bool isActive;
  final String? notes;

  StationNodeModel({
    required this.id,
    required this.fromStation,
    required this.toStation,
    required this.sequenceOrder,
    required this.estimatedTravelTimeMinutes,
    required this.distanceKm,
    required this.isActive,
    this.notes,
  });

  factory StationNodeModel.fromJson(Map<String, dynamic> json) {
    return StationNodeModel(
      id: json['id'],
      fromStation: StationModel.fromJson(json['fromStation']),
      toStation: StationModel.fromJson(json['toStation']),
      sequenceOrder: json['sequenceOrder'],
      estimatedTravelTimeMinutes: json['estimatedTravelTimeMinutes'],
      distanceKm: (json['distanceKm'] as num).toDouble(),
      isActive: json['isActive'],
      notes: json['notes'],
    );
  }
} 