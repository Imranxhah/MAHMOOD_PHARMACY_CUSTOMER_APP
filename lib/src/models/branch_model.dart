class BranchModel {
  final int id;
  final String name;
  final double? distanceKm;
  final double latitude;
  final double longitude;
  final String timing;
  final String? googleMapsUrl;

  BranchModel({
    required this.id,
    required this.name,
    this.distanceKm,
    required this.latitude,
    required this.longitude,
    required this.timing,
    this.googleMapsUrl,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'],
      name: json['name'],
      distanceKm: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timing: json['timing'] ?? 'N/A',
      googleMapsUrl: json['google_maps_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'distance_km': distanceKm,
      'latitude': latitude,
      'longitude': longitude,
      'timing': timing,
      'google_maps_url': googleMapsUrl,
    };
  }
}
