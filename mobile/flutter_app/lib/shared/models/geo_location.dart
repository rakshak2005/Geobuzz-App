import 'package:equatable/equatable.dart';

class GeoLocation extends Equatable {
  final String name;
  final double latitude;
  final double longitude;
  final String? address;

  const GeoLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory GeoLocation.fromMap(Map<String, dynamic> map) {
    return GeoLocation(
      name: map['name'] as String? ?? 'Custom Location',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String?,
    );
  }

  GeoLocation copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return GeoLocation(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [name, latitude, longitude, address];
}
