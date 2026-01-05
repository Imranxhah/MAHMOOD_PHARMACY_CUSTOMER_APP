import '../constants/api_constants.dart';

class PrescriptionModel {
  final int id;
  final String status;
  final String imageUrl;
  final DateTime createdAt;
  final String address; // For upload
  final String? adminFeedback; // For list response
  final int branch; // Added branch ID
  final String contactNumber; // Added contact number

  PrescriptionModel({
    required this.id,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
    required this.address,
    this.adminFeedback,
    required this.branch,
    required this.contactNumber,
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
      address: json['address'] ?? '',
      adminFeedback: json['admin_feedback'],
      branch: json['branch'],
      contactNumber: json['contact_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'image': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'address': address,
      'admin_feedback': adminFeedback,
      'branch': branch,
      'contact_number': contactNumber,
    };
  }
}
