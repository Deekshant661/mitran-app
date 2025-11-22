import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/qr_service.dart';
import '../services/permission_service.dart';
import '../services/session_manager.dart';
import '../services/chatbot_api.dart';
import '../services/disease_api.dart';

// Service Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final qrServiceProvider = Provider<QRService>((ref) => QRService());
final permissionServiceProvider = Provider<PermissionService>((ref) => PermissionService());
final sessionManagerProvider = Provider<SessionManager>((ref) => SessionManager());
final chatbotServiceProvider = Provider<ChatbotApi>((ref) => ChatbotApi());
final diseaseDetectionServiceProvider = Provider<DiseaseApi>((ref) => DiseaseApi());