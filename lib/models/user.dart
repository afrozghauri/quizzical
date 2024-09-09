class User {
  final String id;
  final String email;

  User({
    required this.id,
    required this.email,
  });

  // You can add a factory method to create a User object from a Map (e.g., from JSON data)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
    );
  }
}
