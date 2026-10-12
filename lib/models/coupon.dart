class MerchantCoupon {
  final String code;
  final String title;
  final String description;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double minSpend;
  final DateTime expiryDate;
  final bool isValid;

  MerchantCoupon({
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minSpend,
    required this.expiryDate,
    required this.isValid,
  });

  factory MerchantCoupon.fromJson(Map<String, dynamic> json) {
    return MerchantCoupon(
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'percentage',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      minSpend: (json['minSpend'] as num?)?.toDouble() ?? 0.0,
      expiryDate: DateTime.parse(json['expiryDate'] ?? DateTime.now().toIso8601String()),
      isValid: json['isValid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'minSpend': minSpend,
      'expiryDate': expiryDate.toIso8601String(),
      'isValid': isValid,
    };
  }
}
