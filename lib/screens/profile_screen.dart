import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _background = Color(0xFF141923);
  static const _card = Color(0xFF1E2638);
  static const _primary = Color(0xFF6C5CE7);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.user;
    final isEn = provider.isEnglish;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: SizedBox.shrink(),
      );
    }

    final displayName = (user.displayName ?? '').trim();
    final shownName = displayName.isEmpty
        ? (isEn ? 'Student' : 'Öğrenci')
        : displayName;
    final createdAt = user.metadata.creationTime;

    return Scaffold(
      backgroundColor: _background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _ProfileHeader(
            name: shownName,
            email: user.email ?? '-',
            onEdit: () => _showEditNameDialog(context, displayName),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.menu_book_rounded,
                  value: provider.courses.length.toString(),
                  label: isEn ? 'Courses' : 'Ders',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_outline_rounded,
                  value: provider.todos.length.toString(),
                  label: isEn ? 'Tasks' : 'Görev',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.sticky_note_2_outlined,
                  value: provider.notes.length.toString(),
                  label: isEn ? 'Notes' : 'Not',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle(text: isEn ? 'Account' : 'Hesap'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.email_outlined,
                title: isEn ? 'Email' : 'E-posta',
                value: user.email ?? '-',
              ),
              _divider(),
              _InfoTile(
                icon: user.emailVerified
                    ? Icons.verified_rounded
                    : Icons.error_outline_rounded,
                title: isEn ? 'Email status' : 'E-posta durumu',
                value: user.emailVerified
                    ? (isEn ? 'Verified' : 'Doğrulandı')
                    : (isEn ? 'Not verified' : 'Doğrulanmadı'),
                valueColor: user.emailVerified
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
              ),
              if (createdAt != null) ...[
                _divider(),
                _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  title: isEn ? 'Member since' : 'Üyelik tarihi',
                  value: _formatDate(createdAt),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle(text: isEn ? 'Settings' : 'Ayarlar'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                secondary: const Icon(Icons.language_rounded, color: _primary),
                title: Text(
                  isEn ? 'English interface' : 'İngilizce arayüz',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isEn ? 'Language: English' : 'Dil: Türkçe',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                value: provider.isEnglish,
                activeThumbColor: _primary,
                onChanged: (_) => provider.toggleLanguage(),
              ),
              _divider(),
              _ActionTile(
                icon: Icons.sync_rounded,
                title: isEn ? 'Refresh my data' : 'Verilerimi yenile',
                subtitle: isEn
                    ? 'Refresh courses, tasks and notes'
                    : 'Ders, görev ve notları yeniden yükle',
                onTap: () {
                  provider.refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEn ? 'Your data is being refreshed.' : 'Verileriniz yenileniyor.',
                      ),
                    ),
                  );
                },
              ),
              _divider(),
              _ActionTile(
                icon: Icons.lock_reset_rounded,
                title: isEn ? 'Reset password' : 'Şifremi sıfırla',
                subtitle: isEn
                    ? 'Send a password reset email'
                    : 'E-postanıza şifre sıfırlama bağlantısı gönderin',
                onTap: () => _sendPasswordReset(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle(text: isEn ? 'Session' : 'Oturum'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _ActionTile(
                icon: Icons.logout_rounded,
                iconColor: Colors.redAccent,
                title: isEn ? 'Sign out' : 'Çıkış yap',
                titleColor: Colors.redAccent,
                subtitle: isEn
                    ? 'Sign out of this account'
                    : 'Bu hesaptaki oturumu kapat',
                onTap: () => _confirmSignOut(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        indent: 54,
        color: Color(0xFF2A3347),
      );

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  Future<void> _showEditNameDialog(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEn = provider.isEnglish;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        title: Text(
          isEn ? 'Edit profile' : 'Profili düzenle',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: isEn ? 'Name' : 'Ad',
            labelStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.person_outline, color: _primary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isEn ? 'Cancel' : 'İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            onPressed: () async {
              final error = await provider.updateDisplayName(controller.text);
              if (!dialogContext.mounted) return;
              if (error == null) {
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEn ? 'Profile updated.' : 'Profil güncellendi.'),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
            child: Text(
              isEn ? 'Save' : 'Kaydet',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _sendPasswordReset(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEn = provider.isEnglish;
    final email = provider.user?.email;
    if (email == null || email.isEmpty) return;

    final error = await provider.sendPasswordReset(email);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (isEn
                  ? 'Password reset email sent.'
                  : 'Şifre sıfırlama bağlantısı e-postanıza gönderildi.'),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEn = provider.isEnglish;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        title: Text(
          isEn ? 'Sign out?' : 'Çıkış yapılsın mı?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isEn
              ? 'You will need to sign in again to access your account.'
              : 'Hesabınıza tekrar erişmek için yeniden giriş yapmanız gerekecek.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isEn ? 'Cancel' : 'İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              isEn ? 'Sign out' : 'Çıkış yap',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.signOut();
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProfileScreen._card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: ProfileScreen._primary.withValues(alpha: 0.18),
            child: Text(
              initial,
              style: const TextStyle(
                color: ProfileScreen._primary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: ProfileScreen._primary),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: ProfileScreen._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: ProfileScreen._primary, size: 20),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProfileScreen._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: ProfileScreen._primary),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: valueColor ?? Colors.grey, fontSize: 12),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? ProfileScreen._primary),
      title: Text(
        title,
        style: TextStyle(color: titleColor ?? Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }
}
