import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_providers.dart';
import 'package:flutter/services.dart';

class QRScannerWidget extends ConsumerStatefulWidget {
  final Function(String)? onCodeScanned;
  final bool showOverlay;

  const QRScannerWidget({
    super.key,
    this.onCodeScanned,
    this.showOverlay = true,
  });

  @override
  ConsumerState<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends ConsumerState<QRScannerWidget> {
  MobileScannerController? _scannerController;
  bool _isScanning = true;
  bool _hasPermission = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    final permissionService = ref.read(permissionServiceProvider);
    final statuses = await permissionService.checkAllPermissions();
    bool allowed = statuses['camera'] == true;
    if (!allowed) {
      allowed = await permissionService.requestCameraPermission();
    }
    if (allowed) {
      setState(() {
        _hasPermission = true;
        _scannerController ??= MobileScannerController(
          facing: CameraFacing.back,
          torchEnabled: false,
        );
      });
    } else {
      setState(() {
        _hasPermission = false;
        _scannerController = null;
      });
    }
  }

  Future<void> _restartScanner() async {
    try {
      await _scannerController?.stop();
    } catch (_) {}
    _scannerController?.dispose();
    setState(() {
      _scannerController = null;
      _isScanning = true;
      _lastScannedCode = null;
    });
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() {
      _scannerController = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    });
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code != _lastScannedCode) {
        _lastScannedCode = code;
        _handleScannedCode(code);
        break;
      }
    }
  }

  void _handleScannedCode(String code) async {
    setState(() {
      _isScanning = false;
    });

    // Vibrate to give feedback
    HapticFeedback.mediumImpact();

    // Process the QR code
    final qrService = ref.read(qrServiceProvider);
    final trimmed = code.trim();
    final result = await qrService.processQRCode(trimmed);

    if (mounted) {
      if (result.success && result.dogId != null) {
        // Navigate to dog detail page (GoRouter)
        context.push('/directory/${result.dogId}');
      } else {
        // If valid QR format but no dog found, open registration form
        final isValid = qrService.isValidQRCode(trimmed);
        if (isValid) {
          context.push('/add-record', extra: {'qrCodeId': trimmed});
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Not a valid ID. Scan a MITRAN unique ID to add or fetch details'),
              backgroundColor: Colors.red,
            ),
          );
        }
        // Resume scanning
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _isScanning = true;
              _lastScannedCode = null;
            });
          }
        });
      }
    }

    // Call the callback if provided
    widget.onCodeScanned?.call(code);
  }

  void _toggleTorch() {
    if (_scannerController != null) {
      _scannerController!.toggleTorch();
    }
  }

  void _switchCamera() {
    if (_scannerController != null) {
      _scannerController!.switchCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return _buildPermissionDeniedView();
    }

    if (_scannerController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Scanner
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Camera error: ${error.errorCode.name}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _restartScanner,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
        ),

        // Overlay
        if (widget.showOverlay)
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Theme.of(context).colorScheme.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 8,
                cutOutSize: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
          ),

        // Controls
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'torch',
                mini: true,
                onPressed: _toggleTorch,
                child: const Icon(Icons.flash_on),
              ),
              FloatingActionButton(
                heroTag: 'camera',
                mini: true,
                onPressed: _switchCamera,
                child: const Icon(Icons.flip_camera_ios),
              ),
            ],
          ),
        ),

        // Status indicator
        if (!_isScanning)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Processing QR code...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Camera Permission Required',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This app needs camera permission to scan QR codes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initializeScanner,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 8,
    this.borderRadius = 10,
    this.borderLength = 30,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    // removed unused local variable
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final cutSize = cutOutSize != 250 ? cutOutSize : width * 0.7;
    final cutOutRect = Rect.fromLTWH(
      width / 2 - cutSize / 2 + borderOffset,
      height / 2 - cutSize / 2 + borderOffset,
      cutSize - borderOffset * 2,
      cutSize - borderOffset * 2,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutPath = Path.combine(
      PathOperation.difference,
      Path()..addRRect(
        RRect.fromLTRBR(
          rect.left,
          rect.top,
          rect.right,
          rect.bottom,
          Radius.circular(borderRadius),
        ),
      ),
      Path()..addRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      ),
    );

    canvas
      ..drawPath(cutOutPath, backgroundPaint)
      ..drawPath(cutOutPath, boxPaint);

    _drawBorderLines(canvas, cutOutRect, borderPaint);
  }

  void _drawBorderLines(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()
      ..moveTo(rect.left + borderLength, rect.top)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.top + borderLength)
      ..moveTo(rect.right - borderLength, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + borderLength)
      ..moveTo(rect.left + borderLength, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.bottom - borderLength)
      ..moveTo(rect.right - borderLength, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.bottom - borderLength);

    canvas.drawPath(path, paint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      borderLength: borderLength,
      cutOutSize: cutOutSize,
    );
  }
}
