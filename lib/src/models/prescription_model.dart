import '../constants/api_constants.dart';

class PrescriptionModel {
  final int id;
  final String status;
  final String imageUrl;
  final DateTime createdAt;
  final String? notes; // For upload
  final String? adminFeedback; // For list response

  PrescriptionModel({
    required this.id,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
    this.notes,
    this.adminFeedback,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['image'];
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      if (imageUrl.startsWith('/')) {
        imageUrl = '${ApiConstants.mediaBaseUrl}$imageUrl';
      } else {
        imageUrl = '${ApiConstants.mediaBaseUrl}/$imageUrl';
      }
    }

    return PrescriptionModel(
      id: json['id'],
      status: json['status'],
      imageUrl: imageUrl ?? '',
      createdAt: DateTime.parse(json['created_at']),
      notes: json['notes'],
      adminFeedback: json['admin_feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'image': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'admin_feedback': adminFeedback,
    };
  }
}
