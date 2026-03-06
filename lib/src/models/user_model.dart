class User {
  final String email;
  final String firstName;
  final String lastName;
  final String mobile;
  final int loyaltyPoints;

  User({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    this.loyaltyPoints = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      mobile: json['mobile'],
      loyaltyPoints: json['loyalty_points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'mobile': mobile,
      'loyalty_points': loyaltyPoints,
    };
  }
}
