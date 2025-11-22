import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dog_model.dart';

class QRCodeResult {
  final bool success;
  final String? dogId;
  final String? message;

  QRCodeResult({required this.success, this.dogId, this.message});
}

class QRService {
  // Check if QR code exists in database
  Future<DogModel?> getDogByQRCode(String qrCodeId) async {
    try {
      final query = await FirebaseFirestore.instance
        .collection('dogs')
        .where('qrCodeId', isEqualTo: qrCodeId)
        .limit(1)
        .get();
      
      if (query.docs.isEmpty) return null;
      
      return DogModel.fromFirestore(query.docs.first);
    } catch (e) {
      throw Exception('Failed to fetch dog: $e');
    }
  }
  
  // Validate QR code format
  bool isValidQRCode(String qrCode) {
    final regex = RegExp(r'^MITRAN-\d{7}$');
    return regex.hasMatch(qrCode);
  }

  Future<QRCodeResult> processQRCode(String qrCode) async {
    if (!isValidQRCode(qrCode)) {
      return QRCodeResult(
        success: false,
        message: 'Not a valid ID. Scan a MITRAN unique ID to add or fetch details',
      );
    }
    final dog = await getDogByQRCode(qrCode);
    if (dog == null) {
      return QRCodeResult(success: false, message: 'No dog found for this code');
    }
    return QRCodeResult(success: true, dogId: dog.dogId);
  }
}