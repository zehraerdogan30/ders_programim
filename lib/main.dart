import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/notification_service.dart';

FirebaseOptions _firebaseOptionsForCurrentPlatform() {
  const webOptions = FirebaseOptions(
    apiKey: "AIzaSyAJSjUYU9035krNWkT-7RTztRxF_1vOEw0",
    authDomain: "dersprogramim-e60e0.firebaseapp.com",
    projectId: "dersprogramim-e60e0",
    storageBucket: "dersprogramim-e60e0.firebasestorage.app",
    messagingSenderId: "573371350378",
    appId: "1:573371350378:web:8e603967f347649720b913",
    measurementId: "G-SBT2PWQ0BS",
  );

  const androidOptions = FirebaseOptions(
    apiKey: "AIzaSyAV6rlqca68Mi4WuRNRSHez3opVxrnoTRk",
    projectId: "dersprogramim-e60e0",
    storageBucket: "dersprogramim-e60e0.firebasestorage.app",
    messagingSenderId: "573371350378",
    appId: "1:573371350378:android:ff3153717b72397820b913",
  );

  if (kIsWeb) {
    return webOptions;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return androidOptions;
  }

  return webOptions;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: _firebaseOptionsForCurrentPlatform(),
  );

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final fcmToken = await NotificationService.initialize();
    debugPrint('FCM TOKEN: $fcmToken');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        title: 'Üniversite Ders Programı',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isEn = provider.isEnglish;

    if (provider.user == null) {
      return const AuthScreen();
    }

    if (!provider.user!.emailVerified) {
      return Scaffold(
        backgroundColor: const Color(0xFF141923),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton.icon(
              icon: const Icon(
                Icons.language,
                color: Color(0xFF6C5CE7),
              ),
              label: Text(
                isEn ? 'EN' : 'TR',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => provider.toggleLanguage(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_unread_rounded,
                  size: 72,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  isEn
                      ? 'Verify Your Email Address'
                      : 'E-posta Adresinizi Doğrulayın',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEn
                      ? 'A verification link was sent to ${provider.user!.email}. Please confirm your email.'
                      : '${provider.user!.email} adresine doğrulama bağlantısı gönderildi. Lütfen e-postanızı onaylayın.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  label: Text(
                    isEn
                        ? 'I Verified, Check Now'
                        : 'Doğruladım, Kontrol Et',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    await provider.user!.reload();

                    if (provider.user!.emailVerified) {
                      provider.fetchCourses();
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEn
                                  ? 'Email not verified yet! Please check your spam folder.'
                                  : 'E-posta henüz doğrulanmamış! Spam klasörünü de kontrol edin.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF6C5CE7),
                    ),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF6C5CE7),
                    size: 18,
                  ),
                  label: Text(
                    isEn
                        ? 'Resend Verification Link'
                        : 'Doğrulama Linkini Tekrar Gönder',
                    style: const TextStyle(
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                  onPressed: () async {
                    final error =
                        await provider.resendVerificationEmail();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error == null
                                ? (isEn
                                    ? 'New verification link sent to your email!'
                                    : 'Yeni doğrulama bağlantısı e-posta adresinize gönderildi!')
                                : 'Hata: $error',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => provider.signOut(),
                  child: Text(
                    isEn
                        ? 'Sign In with Different Account'
                        : 'Farklı Hesapla Giriş Yap',
                    style: const TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const HomeScreen();
  }
}