class MerchantUser {
  final String id;
  final String restaurantName;
  final String email;
  final String logoUrl;

  MerchantUser({
    required this.id,
    required this.restaurantName,
    required this.email,
    required this.logoUrl,
  });

  factory MerchantUser.fromJson(Map<String, dynamic> json) {
    return MerchantUser(
      id: json['id'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      email: json['email'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantName': restaurantName,
      'email': email,
      'logoUrl': logoUrl,
    };
  }
}
