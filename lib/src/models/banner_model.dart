class BannerModel {
  final int id;
  final String title;
  final String image;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.title,
    required this.image,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'is_active': isActive,
    };
  }
}
