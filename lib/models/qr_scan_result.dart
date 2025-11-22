import 'dog_model.dart';

class QRScanResult {
  final String qrCodeId;
  final bool isValid;
  final DogModel? existingDog;
  final DateTime scannedAt;

  QRScanResult({
    required this.qrCodeId,
    required this.isValid,
    this.existingDog,
    required this.scannedAt,
  });
}