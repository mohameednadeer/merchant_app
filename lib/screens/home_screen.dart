import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/coupon.dart';
import '../services/merchant_api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  final MerchantApiService _apiService = MerchantApiService();
  
  bool _isProcessingScan = false;
  late AnimationController _scannerLineAnimationController;

  @override
  void initState() {
    super.initState();
    // Animation for scanner line overlay
    _scannerLineAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _manualCodeController.dispose();
    _scannerLineAnimationController.dispose();
    super.dispose();
  }

  // Handle Logout
  Future<void> _handleLogout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Process code (scanned or manually typed)
  void _onCodeSubmitted(String code) {
    if (_isProcessingScan || code.trim().isEmpty) return;

    setState(() {
      _isProcessingScan = true;
    });

    _manualCodeController.clear();
    _showCouponVerificationSheet(code);
  }

  // Modal Bottom Sheet to Verify and Redeem Coupon
  void _showCouponVerificationSheet(String code) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Force actions to resolve or close via custom button
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _CouponActionSheet(
            code: code,
            apiService: _apiService,
            onClosed: () {
              setState(() {
                _isProcessingScan = false;
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final cameraContainerSize = size.width * 0.75;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu_rounded, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('MERCHANT PORTAL'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scanner instructions
              const Text(
                'Scan QR Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Position the customer coupon QR code inside the frame.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
              const SizedBox(height: 28),

              // Camera View Finder Container
              Center(
                child: Container(
                  width: cameraContainerSize,
                  height: cameraContainerSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(102),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // Mobile Scanner Widget
                        MobileScanner(
                          controller: _cameraController,
                          onDetect: (capture) {
                            if (_isProcessingScan) return;
                            final barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty) {
                              final scannedValue = barcodes.first.rawValue;
                              if (scannedValue != null) {
                                _onCodeSubmitted(scannedValue);
                              }
                            }
                          },
                          errorBuilder: (context, error) {
                            return Container(
                              color: Colors.black87,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Camera Access Error',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Please check camera permissions in your settings.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Premium UI Overlay: Target Frame Corners
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ScannerOverlayPainter(
                              borderColor: theme.colorScheme.primary,
                            ),
                          ),
                        ),

                        // Animated Laser Line
                        AnimatedBuilder(
                          animation: _scannerLineAnimationController,
                          builder: (context, child) {
                            final double topOffset = _scannerLineAnimationController.value * (cameraContainerSize - 4);
                            return Positioned(
                              top: topOffset,
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withAlpha(204),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Camera action tools (Torch & Switch Camera)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _cameraController,
                      builder: (context, state, child) {
                        switch (state.torchState) {
                          case TorchState.on:
                            return Icon(Icons.flash_on_rounded, color: theme.colorScheme.primary);
                          case TorchState.off:
                          default:
                            return const Icon(Icons.flash_off_rounded, color: Colors.white70);
                        }
                      },
                    ),
                    onPressed: () => _cameraController.toggleTorch(),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70),
                    onPressed: () => _cameraController.switchCamera(),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Divider "OR"
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR ENTER MANUALLY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withAlpha(102),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              // Manual Code Input Area (for phone orders or fallback)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _manualCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'e.g. SUMMER50, SAVE10',
                        prefixIcon: Icon(Icons.qr_code_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final code = _manualCodeController.text.trim();
                      if (code.isNotEmpty) {
                        _onCodeSubmitted(code);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a coupon code')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_rounded, size: 20),
                        SizedBox(width: 6),
                        Text('Verify'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for scanner corner guides
class _ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  _ScannerOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const cornerLength = 24.0;

    // Top Left Corner
    canvas.drawLine(const Offset(8, 8), const Offset(8 + cornerLength, 8), paint);
    canvas.drawLine(const Offset(8, 8), const Offset(8, 8 + cornerLength), paint);

    // Top Right Corner
    canvas.drawLine(Offset(size.width - 8, 8), Offset(size.width - 8 - cornerLength, 8), paint);
    canvas.drawLine(Offset(size.width - 8, 8), Offset(size.width - 8, 8 + cornerLength), paint);

    // Bottom Left Corner
    canvas.drawLine(Offset(8, size.height - 8), Offset(8 + cornerLength, size.height - 8), paint);
    canvas.drawLine(Offset(8, size.height - 8), Offset(8, size.height - 8 - cornerLength), paint);

    // Bottom Right Corner
    canvas.drawLine(Offset(size.width - 8, size.height - 8), Offset(size.width - 8 - cornerLength, size.height - 8), paint);
    canvas.drawLine(Offset(size.width - 8, size.height - 8), Offset(size.width - 8, size.height - 8 - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Coupon Actions Verification Sheet Widget
class _CouponActionSheet extends StatefulWidget {
  final String code;
  final MerchantApiService apiService;
  final VoidCallback onClosed;

  const _CouponActionSheet({
    required this.code,
    required this.apiService,
    required this.onClosed,
  });

  @override
  State<_CouponActionSheet> createState() => _CouponActionSheetState();
}

class _CouponActionSheetState extends State<_CouponActionSheet> {
  bool _isLoading = true;
  bool _isRedeeming = false;
  String? _errorMessage;
  MerchantCoupon? _coupon;
  Map<String, dynamic>? _redemptionResult;

  @override
  void initState() {
    super.initState();
    _verifyCoupon();
  }

  // Load and verify coupon
  Future<void> _verifyCoupon() async {
    try {
      final couponResult = await widget.apiService.verifyCoupon(widget.code);
      setState(() {
        _coupon = couponResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('DioException: ', '');
        _isLoading = false;
      });
    }
  }

  // Redeem the verified coupon
  Future<void> _redeemCoupon() async {
    if (_coupon == null) return;
    setState(() {
      _isRedeeming = true;
    });

    try {
      final result = await widget.apiService.redeemCoupon(_coupon!.code);
      setState(() {
        _redemptionResult = result;
        _isRedeeming = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('DioException: ', '');
        _isRedeeming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Loading View
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
            const SizedBox(height: 24),
            Text(
              'Verifying Code "${widget.code}"...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Checking coupon validity with server database.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // 2. Error View
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withAlpha(38),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verification Failed',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onClosed();
              },
              child: const Text('DISMISS'),
            ),
          ],
        ),
      );
    }

    // 3. Redemption Success View
    if (_redemptionResult != null) {
      return Container(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(38),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 48),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Redeemed Successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 16),
            Text(
              _redemptionResult!['message'] ?? 'Offer applied successfully.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Coupon Code', _redemptionResult!['code'] ?? '', theme),
                  const Divider(color: Colors.white10),
                  _buildDetailRow('Transaction ID', _redemptionResult!['transactionId'] ?? '', theme),
                  const Divider(color: Colors.white10),
                  _buildDetailRow(
                    'Time',
                    DateTime.parse(_redemptionResult!['redeemedAt'] ?? DateTime.now().toIso8601String())
                        .toLocal()
                        .toString()
                        .split('.')
                        .first,
                    theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onClosed();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('DONE'),
            ),
          ],
        ),
      );
    }

    // 4. Coupon Details & Confirmation View
    final isCouponValid = _coupon?.isValid ?? false;
    
    return Container(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Coupon offer badge header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _coupon!.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${_coupon!.code}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Validity Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCouponValid 
                      ? Colors.green.withAlpha(38) 
                      : theme.colorScheme.error.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCouponValid ? Colors.green : theme.colorScheme.error, 
                    width: 1,
                  ),
                ),
                child: Text(
                  isCouponValid ? 'VALID OFFER' : 'EXPIRED/INVALID',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCouponValid ? Colors.green : theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Description box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              _coupon!.description,
              style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 20),

          // Offer metadata checklist
          Column(
            children: [
              _buildDetailRow(
                'Min. Purchase Requirement', 
                _coupon!.minSpend > 0 ? '\$${_coupon!.minSpend.toStringAsFixed(2)}' : 'No Minimum',
                theme
              ),
              const Divider(color: Colors.white10),
              _buildDetailRow(
                'Discount Value', 
                _coupon!.discountType == 'percentage' 
                    ? '${_coupon!.discountValue.toStringAsFixed(0)}%' 
                    : '\$${_coupon!.discountValue.toStringAsFixed(2)}',
                theme
              ),
              const Divider(color: Colors.white10),
              _buildDetailRow(
                'Expiry Date', 
                '${_coupon!.expiryDate.day}/${_coupon!.expiryDate.month}/${_coupon!.expiryDate.year}', 
                theme
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action Buttons
          if (isCouponValid) ...[
            ElevatedButton(
              onPressed: _isRedeeming ? null : _redeemCoupon,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: _isRedeeming
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'REDEEM OFFER',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton(
            onPressed: _isRedeeming ? null : () {
              Navigator.pop(context);
              widget.onClosed();
            },
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white38),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
