import 'package:go_router/go_router.dart';
import '../pages/splash_screen.dart';
import '../pages/onboarding_screen.dart';
import '../pages/create_profile_page.dart';
import '../pages/home_page.dart';
import '../pages/directory_page.dart';
import '../pages/dog_detail_page.dart';
import '../pages/add_record_page.dart';
import '../pages/ai_care_page.dart';
import '../pages/ai_chatbot_page.dart';
import '../pages/disease_detection_page.dart';
import '../pages/profile_page.dart';
import '../pages/qr_scanner_page.dart';
import '../pages/my_dogs_page.dart';
import '../pages/my_posts_page.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/create-profile',
      builder: (context, state) => const CreateProfilePage(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/directory',
      builder: (context, state) => const DirectoryPage(),
    ),
    GoRoute(
      path: '/directory/:dogId',
      builder: (context, state) {
        final dogId = state.pathParameters['dogId']!;
        return DogDetailPage(dogId: dogId);
      },
    ),
    GoRoute(
      path: '/add-record',
      builder: (context, state) {
        final extra = state.extra;
        String? qr;
        if (extra is Map && extra['qrCodeId'] is String) {
          qr = extra['qrCodeId'] as String;
        }
        return AddRecordPage(qrCodeId: qr);
      },
    ),
    GoRoute(
      path: '/qr-scanner',
      builder: (context, state) => const QRScannerPage(),
    ),
    GoRoute(path: '/ai-care', builder: (context, state) => const AICarePage()),
    GoRoute(
      path: '/ai-care/chatbot',
      builder: (context, state) => const AIChatbotPage(),
    ),
    GoRoute(
      path: '/ai-care/disease-scan',
      builder: (context, state) => const DiseaseDetectionPage(),
    ),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(path: '/my-dogs', builder: (context, state) => const MyDogsPage()),
    GoRoute(path: '/my-posts', builder: (context, state) => const MyPostsPage()),
  ],
);
