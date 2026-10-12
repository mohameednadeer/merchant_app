import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coupon.dart';
import '../models/merchant_user.dart';

class MerchantApiService {
  final Dio _dio;
  static const String _tokenKey = 'merchant_auth_token';
  static const String _userKey = 'merchant_user_info';

  MerchantApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.example.com/merchant', // Replace with your production API Base URL
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    // Inject auth token dynamically into every outgoing request if available
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // ==========================================
  // SHARED PREFERENCES / SESSION HELPERS
  // ==========================================

  Future<bool> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_tokenKey, token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_tokenKey);
  }

  Future<bool> saveUserInfo(MerchantUser user) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<MerchantUser?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      return MerchantUser.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ==========================================
  // REST API SERVICES (MOCKED WITH DIO SKELETON)
  // ==========================================

  /// Authenticate the restaurant merchant
  Future<MerchantUser> login(String email, String password) async {
    // Simulate real network request timing
    await Future.delayed(const Duration(seconds: 1));

    // Request validation
    if (email.trim().isEmpty || password.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '/login'),
        error: 'Email and password are required.',
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 400,
          data: {'message': 'Email and password are required.'},
        ),
      );
    }

    if (password.length < 6) {
      throw DioException(
        requestOptions: RequestOptions(path: '/login'),
        error: 'Password must be at least 6 characters.',
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 400,
          data: {'message': 'Password must be at least 6 characters.'},
        ),
      );
    }

    // --- MOCKING SUCCESSFUL AUTHENTICATION ---
    final dummyToken = 'mock_jwt_token_restaurant_xyz_98765';
    final user = MerchantUser(
      id: 'rest_7739',
      restaurantName: 'Gourmet Bistro & Grill',
      email: email.trim(),
      logoUrl: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?q=80&w=200&auto=format&fit=crop',
    );

    // Save session credentials
    await saveAuthToken(dummyToken);
    await saveUserInfo(user);

    return user;
  }

  /// Verify coupon code viability (from QR or manual entry)
  Future<MerchantCoupon> verifyCoupon(String code) async {
    // Simulate API request timing
    await Future.delayed(const Duration(milliseconds: 800));

    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '/coupons/verify'),
        error: 'Coupon code cannot be empty.',
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/coupons/verify'),
          statusCode: 400,
          data: {'message': 'Coupon code cannot be empty.'},
        ),
      );
    }

    // --- MOCKING EXPIRED OR INVALID CODES ---
    final upperCode = cleanCode.toUpperCase();
    if (upperCode == 'EXPIRED' || upperCode == 'INVALID' || upperCode == 'TEST_ERR') {
      return MerchantCoupon(
        code: upperCode,
        title: 'Expired or Invalid Coupon',
        description: 'This coupon code is expired, fully claimed, or does not exist.',
        discountType: 'percentage',
        discountValue: 0.0,
        minSpend: 0.0,
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        isValid: false,
      );
    }

    // --- MOCKING SUCCESSFUL OFFERS ---
    String title = 'Free Dessert';
    String description = 'Receive one free gourmet lava cake or signature ice cream with any main course.';
    String discountType = 'percentage';
    double discountValue = 100.0;
    double minSpend = 15.0;

    if (upperCode.contains('50') || upperCode.contains('HALF')) {
      title = '50% OFF Entire Order';
      description = 'Save 50% on your final dinner bill (excludes alcoholic beverages). Dine-in only.';
      discountValue = 50.0;
      minSpend = 20.0;
    } else if (upperCode.contains('10') || upperCode.contains('SAVE')) {
      title = '\$10.00 Off Discount';
      description = 'Get a flat \$10 discount on orders totaling \$30.00 or more.';
      discountType = 'fixed';
      discountValue = 10.0;
      minSpend = 30.0;
    } else if (upperCode.contains('FREE') || upperCode.contains('DRINK')) {
      title = 'Complimentary Craft Beverage';
      description = 'Receive a free artisanal soft drink, coffee, or draft beer with your meal.';
      discountType = 'percentage';
      discountValue = 100.0;
      minSpend = 8.0;
    }

    return MerchantCoupon(
      code: upperCode,
      title: title,
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      minSpend: minSpend,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      isValid: true,
    );
  }

  /// Perform redemption of coupon
  Future<Map<String, dynamic>> redeemCoupon(String code) async {
    // Simulate real database write latency
    await Future.delayed(const Duration(seconds: 1));

    final upperCode = code.trim().toUpperCase();
    if (upperCode == 'EXPIRED' || upperCode == 'INVALID' || upperCode == 'TEST_ERR') {
      throw DioException(
        requestOptions: RequestOptions(path: '/coupons/redeem'),
        error: 'Failed to redeem coupon: Code is invalid or has expired.',
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/coupons/redeem'),
          statusCode: 400,
          data: {'message': 'This coupon is no longer eligible for redemption.'},
        ),
      );
    }

    // --- MOCKING SUCCESSFUL REDEMPTION ---
    return {
      'success': true,
      'code': upperCode,
      'redeemedAt': DateTime.now().toIso8601String(),
      'message': 'Coupon $upperCode successfully applied & recorded.',
      'transactionId': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
    };
  }
}
