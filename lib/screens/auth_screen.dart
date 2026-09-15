import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;
  String? errorMessage;
  bool showResendButton = false;
  
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      rememberMe = prefs.getBool('remember_me') ?? false;
      if (rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  Future<void> _handleSaveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  void _submit() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEnglish = provider.isEnglish;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = isEnglish ? 'Please fill in all fields.' : 'Lütfen tüm alanları doldurun.';
        showResendButton = false;
      });
      return;
    }

    setState(() {
      errorMessage = null;
      showResendButton = false;
    });

    if (isLogin) {
      await _handleSaveCredentials();
      String? error = await provider.signIn(email, password);
      if (!mounted) return;
      if (error != null) {
        setState(() {
          errorMessage = error;
          if (error.contains('doğrulanmadı') || error.contains('not verified')) {
            showResendButton = true;
          }
        });
      }
    } else {
      String? error = await provider.signUp(email, password);
      if (!mounted) return;
      if (error == null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E2638),
              title: Text(
                isEnglish ? 'Email Verification' : 'E-posta Doğrulaması',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Text(
                isEnglish
                    ? 'A verification link has been sent to $email.\n\nPlease check your inbox (or Spam folder) and sign in after confirming.'
                    : '$email adresine doğrulama bağlantısı gönderildi.\n\nLütfen gelen kutunuzdaki (veya Spam klasörünüzdeki) linke tıklayıp onayladıktan sonra Giriş Yapın.',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      isLogin = true;
                      errorMessage = null;
                    });
                  },
                  child: Text(
                    isEnglish ? 'Got it, Sign In' : 'Anladım, Giriş Yap',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() => errorMessage = error);
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController(text: _emailController.text);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEnglish = provider.isEnglish;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        title: Text(
          isEnglish ? 'Forgot Password' : 'Şifremi Unuttum',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnglish
                  ? 'Enter the email address associated with your account. A password reset link will be sent.'
                  : 'Hesabınıza bağlı e-posta adresinizi girin. Şifre sıfırlama bağlantısı gönderilecektir.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetEmailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: isEnglish ? 'Email Address' : 'E-posta Adresi',
                labelStyle: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEnglish ? 'Cancel' : 'İptal', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                final error = await provider.sendPasswordReset(email);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error == null
                            ? (isEnglish
                                ? 'Password reset link sent to your email!'
                                : 'Şifre sıfırlama bağlantısı e-postanıza gönderildi!')
                            : 'Hata: $error',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(isEnglish ? 'Send' : 'Gönder', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).whenComplete(resetEmailController.dispose);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isEnglish = provider.isEnglish;

    return Scaffold(
      backgroundColor: const Color(0xFF141923),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.language, color: Color(0xFF6C5CE7)),
            label: Text(
              isEnglish ? 'EN' : 'TR',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () => provider.toggleLanguage(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_rounded, size: 64, color: Color(0xFF6C5CE7)),
              const SizedBox(height: 16),
              Text(
                isLogin
                    ? (isEnglish ? 'Welcome Back' : 'Hoş Geldiniz')
                    : (isEnglish ? 'Create Account' : 'Hesap Oluşturun'),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Column(
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      if (showResendButton) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.send_rounded, size: 14, color: Color(0xFF6C5CE7)),
                          label: Text(
                            isEnglish ? 'Resend Verification Link' : 'Doğrulama Linkini Tekrar Gönder',
                            style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 12),
                          ),
                          onPressed: () async {
                            final resendErr = await provider.resendVerificationEmail(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    resendErr == null
                                        ? (isEnglish
                                            ? 'New verification link sent!'
                                            : 'Yeni doğrulama bağlantısı gönderildi!')
                                        : 'Hata: $resendErr',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Email' : 'E-posta',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E2638),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Password' : 'Şifre',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E2638),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              if (isLogin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          activeColor: const Color(0xFF6C5CE7),
                          onChanged: (val) {
                            setState(() {
                              rememberMe = val ?? false;
                            });
                          },
                        ),
                        Text(
                          isEnglish ? 'Remember Me' : 'Beni Hatırla',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => _showForgotPasswordDialog(context),
                      child: Text(
                        isEnglish ? 'Forgot Password?' : 'Şifremi Unuttum?',
                        style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                  child: Text(
                    isLogin
                        ? (isEnglish ? 'Sign In' : 'Giriş Yap')
                        : (isEnglish ? 'Register' : 'Kayıt Ol'),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  isLogin = !isLogin;
                  errorMessage = null;
                  showResendButton = false;
                }),
                child: Text(
                  isLogin
                      ? (isEnglish ? "Don't have an account? Register" : 'Hesabınız yok mu? Kayıt Olun')
                      : (isEnglish ? 'Already have an account? Sign In' : 'Zaten hesabınız var mı? Giriş Yapın'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}