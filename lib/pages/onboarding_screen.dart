import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import '../services/session_manager.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final SessionManager _sessionManager = SessionManager();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  void _showSignInOptions() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Guardian Login'),
          content: const Text('Join the Network to become a Mitran Guardian.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _onIntroEnd();
              },
              icon: const Icon(Icons.login),
              label: const Text('Sign Up with Google'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onIntroEnd() async {
    try {
      final cred = await _authService.signInWithGoogle();
      final user = cred.user;
      if (user != null) {
        await _sessionManager.markOnboardingAsSeen();
        final hasProfile = await _firestoreService.getUserProfile(user.uid) != null;
        if (mounted) context.go(hasProfile ? '/home' : '/create-profile');
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in was cancelled')), 
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to sign in';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'popup-closed-by-user':
            case 'canceled':
              msg = 'Google sign-in was cancelled';
              break;
            case 'account-exists-with-different-credential':
              msg = 'Account exists with different credential';
              break;
            default:
              msg = e.message ?? msg;
          }
        } else {
          msg = 'Failed to sign in: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IntroductionScreen(
          pages: [
            PageViewModel(
              title: "Become a Friend, Be a Guardian",
              body: "\"Mitran\" means friend. Join compassionate Guardians working to give our stray friends a safer, healthier life.",
              image: Center(
                child: Icon(
                  Icons.pets,
                  size: 120,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              decoration: PageDecoration(
                titleTextStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                bodyTextStyle: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            PageViewModel(
              title: "See, Scan, & Save",
              body: "Use this app to scan Mitran QR collars or create new digital records. A simple scan tracks health, vaccinations, and sterilization, making every dog visible.",
              image: Center(
                child: Icon(
                  Icons.people,
                  size: 120,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              decoration: PageDecoration(
                titleTextStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                bodyTextStyle: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            PageViewModel(
              title: "Connect, Learn, & Act",
              body: "Share updates with Guardians, get AI-powered health advice, and help find loving homes. Let's make a difference, together.",
              image: Center(
                child: Icon(
                  Icons.favorite,
                  size: 120,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              decoration: PageDecoration(
                titleTextStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                bodyTextStyle: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
          onDone: _showSignInOptions,
          showSkipButton: true,
          skip: const Text("Skip"),
          next: const Text("Next"),
          done: const Text("Get Started", style: TextStyle(fontWeight: FontWeight.w600)),
          dotsDecorator: DotsDecorator(
            size: const Size.square(10.0),
            activeSize: const Size(20.0, 10.0),
            activeColor: Theme.of(context).colorScheme.primary,
            color: Colors.black26,
            spacing: const EdgeInsets.symmetric(horizontal: 3.0),
            activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        ),
      ),
    );
  }
}