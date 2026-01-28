import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../providers/gate_access_check_in_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'gate_access_scan_result_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _hasScanned = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GateAccessCheckInProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final value = barcode.rawValue;

    if (value == null || value.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
    });

    // Process QR code with new provider
    final provider = context.read<GateAccessCheckInProvider>();
    final success = await provider.processQRScan(value);

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      if (success) {
        // Navigate to result screen
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const GateAccessScanResultScreen(),
          ),
        );

        if (mounted) {
          if (result == true) {
            // Successfully checked in/out, go back
            Navigator.pop(context);
          } else {
            // Reset to scan again
            setState(() {
              _hasScanned = false;
            });
            provider.clearScanData();
          }
        }
      } else {
        // Show error overlay
        _showErrorOverlay(provider.errorMessage ?? 'Lỗi không xác định');
      }
    }
  }

  void _showErrorOverlay(String message) {
    setState(() {
      _errorMessage = message;
      _hasScanned = true;
    });

    // Auto-hide after 4 seconds and allow scanning again
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
          _hasScanned = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
        actions: [
          // Flash toggle
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, _) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off);
                }
              },
            ),
          ),
          // Camera switch
          IconButton(
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Scan frame
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _errorMessage != null ? Colors.red : AppColors.guardPrimary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Đưa mã QR vào khung để quét',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hỗ trợ quét mã QR đăng ký ra/vào',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.guardPrimary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đang xử lý...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error overlay
          if (_errorMessage != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _errorMessage != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Không hợp lệ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Tự động quét lại sau 4 giây',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                                _hasScanned = false;
                              });
                            },
                            child: const Text(
                              'Quét lại ngay',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    const scanAreaSize = 280.0;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw overlay with hole
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner markers
    final markerPaint = Paint()
      ..color = AppColors.guardPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const markerLength = 30.0;
    const radius = 16.0;

    // Top left
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top + markerLength),
      Offset(scanRect.left, scanRect.top + radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left + markerLength, scanRect.top),
      Offset(scanRect.left + radius, scanRect.top),
      markerPaint,
    );

    // Top right
    canvas.drawLine(
      Offset(scanRect.right, scanRect.top + markerLength),
      Offset(scanRect.right, scanRect.top + radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right - markerLength, scanRect.top),
      Offset(scanRect.right - radius, scanRect.top),
      markerPaint,
    );

    // Bottom left
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom - markerLength),
      Offset(scanRect.left, scanRect.bottom - radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left + markerLength, scanRect.bottom),
      Offset(scanRect.left + radius, scanRect.bottom),
      markerPaint,
    );

    // Bottom right
    canvas.drawLine(
      Offset(scanRect.right, scanRect.bottom - markerLength),
      Offset(scanRect.right, scanRect.bottom - radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right - markerLength, scanRect.bottom),
      Offset(scanRect.right - radius, scanRect.bottom),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
