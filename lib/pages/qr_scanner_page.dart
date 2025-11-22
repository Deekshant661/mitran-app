import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/qr_scanner_widget.dart';
import '../providers/service_providers.dart';

class QRScannerPage extends ConsumerStatefulWidget {
  const QRScannerPage({super.key});

  @override
  ConsumerState<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends ConsumerState<QRScannerPage> {
  bool _isFlashOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Collar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined),
            tooltip: 'Enter code manually',
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.qr_code_2, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use this to find an existing dog\'s record or register a Mitran-issued collar.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: QRScannerWidget(
              onCodeScanned: (code) {
                debugPrint('QR Code scanned: $code');
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  void _showManualEntryDialog() {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter QR Code'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'QR Code',
            hintText: 'Enter the code from the QR tag',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _processManualCode(code);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _processManualCode(String code) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final qrService = ref.read(qrServiceProvider);
      final result = await qrService.processQRCode(code);

      // Hide loading
      if (mounted) {
        Navigator.pop(context);

        if (result.success && result.dogId != null) {
          // Navigate to dog detail page
          context.push('/directory/${result.dogId}');
        } else {
          final isValid = ref.read(qrServiceProvider).isValidQRCode(code);
          if (isValid) {
          context.push('/add-record', extra: {'qrCodeId': code});
          } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Invalid QR code'),
              backgroundColor: Colors.red,
            ),
          );
          }
        }
      }
    } catch (e) {
      // Hide loading
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}