import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../data/auth/apple_sign_in_service.dart';
import '../../core/utils/auth_failure_message.dart';
import '../../data/providers/repository_providers.dart';

/// Sign-in screen supporting the V1 Google and Apple options.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web: use signInWithPopup (no google_sign_in package needed)
        final provider = GoogleAuthProvider();
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // Android / iOS: use google_sign_in package
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => _isLoading = false);
          return;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      // Create Firestore profile if first sign-in
      final repo = ref.read(userRepositoryProvider);
      final existing =
          await repo.fetchProfile(userCredential.user!.uid);
      if (existing == null) {
        await repo.createProfileFromFirebaseUser(userCredential.user!);
      }

      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in Firebase error (${e.code}): ${e.message}');
      setState(() => _errorMessage = authenticationFailureMessage('Google'));
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      setState(() => _errorMessage = authenticationFailureMessage('Google'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userCredential = await ref
          .read(appleSignInServiceProvider)
          .signIn();
      if (userCredential == null) return;

      final repo = ref.read(userRepositoryProvider);
      final existing = await repo.fetchProfile(userCredential.user!.uid);
      if (existing == null) {
        await repo.createProfileFromFirebaseUser(userCredential.user!);
      }

      if (mounted) context.go('/');
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = appleAuthenticationFailureMessage(error.code),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = authenticationFailureMessage('Apple'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configured = ref.watch(appleSignInConfiguredProvider);
    final isAndroid = !kIsWeb && theme.platform == TargetPlatform.android;
    final isIos = !kIsWeb && theme.platform == TargetPlatform.iOS;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo / title
              Icon(
                Icons.sports,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'スポーツカレンダー',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '好きなチームの試合日程をカレンダーに同期',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Google sign-in
                OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Googleでサインイン'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (!isAndroid && (configured || !isIos))
                  const SizedBox(height: 12),
                if (isIos && configured)
                  SignInWithAppleButton(
                    onPressed: _signInWithApple,
                    text: 'Appleでサインイン',
                    style: theme.brightness == Brightness.dark
                        ? SignInWithAppleButtonStyle.white
                        : SignInWithAppleButtonStyle.black,
                  )
                else if (!isAndroid && !isIos && configured)
                  OutlinedButton.icon(
                    onPressed: _signInWithApple,
                    icon: const Icon(Icons.apple, size: 24),
                    label: const Text('Appleでサインイン'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                else if (!isAndroid && !isIos)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apple, size: 24),
                        SizedBox(width: 8),
                        Text('Appleでサインイン（準備中）'),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
