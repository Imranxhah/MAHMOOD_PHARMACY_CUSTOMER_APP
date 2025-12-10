class User {
  final String email;
  final String firstName;
  final String lastName;
  final String mobile;

  User({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      mobile: json['mobile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'mobile': mobile,
    };
  }
}
