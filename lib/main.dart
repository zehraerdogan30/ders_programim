import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAJSjUYU9035krNWkT-7RTztRxF_1vOEw0",
        authDomain: "dersprogramim-e60e0.firebaseapp.com",
        projectId: "dersprogramim-e60e0",
        storageBucket: "dersprogramim-e60e0.firebasestorage.app",
        messagingSenderId: "573371350378",
        appId: "1:573371350378:web:8e603967f347649720b913",
        measurementId: "G-SBT2PWQ0BS",
      ),
    );
  } else {
    await Firebase.initializeApp();
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

    // 1. Oturum açılmamışsa Giriş Ekranına git
    if (provider.user == null) {
      return const AuthScreen();
    }

    // 2. E-posta henüz doğrulanmamışsa ikaz/onay ekranını göster
    if (!provider.user!.emailVerified) {
      return Scaffold(
        backgroundColor: const Color(0xFF141923),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_unread_rounded, size: 72, color: Colors.orangeAccent),
                const SizedBox(height: 16),
                const Text(
                  'E-posta Adresinizi Doğrulayın',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${provider.user!.email} adresine doğrulama bağlantısı gönderildi. Lütfen e-postanızı onaylayın.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Doğruladım, Kontrol Et', style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    await provider.user!.reload();
                    if (provider.user!.emailVerified) {
                      provider.fetchCourses();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('E-posta henüz doğrulanmamış! Spam klasörünü de kontrol edin.')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                // LINKI TEKRAR GÖNDERME BUTONU
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF6C5CE7), size: 18),
                  label: const Text('Doğrulama Linkini Tekrar Gönder', style: TextStyle(color: Color(0xFF6C5CE7))),
                  onPressed: () async {
                    final error = await provider.resendVerificationEmail();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error == null
                                ? 'Yeni doğrulama bağlantısı e-posta adresinize gönderildi!'
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
                  child: const Text('Farklı Hesapla Giriş Yap', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Yalnızca e-postası doğrulanmış kullanıcılar ana ekrana geçebilir
    return const HomeScreen();
  }
}