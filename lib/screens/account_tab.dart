import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import 'history_screen.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (_, auth, __) {
      final user = auth.user;
      return Scaffold(
        backgroundColor: Colors.black, // #000
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: _ProfileHeader(user: user),
                stretchModes: const [StretchMode.zoomBackground],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SectionLabel('Your Activity'),
                  _MenuItem(
                    icon: Icons.history_rounded,
                    label: 'Listening History',
                    onTap: () => _openHistory(context),
                  ),
                  const SizedBox(height: 16),
                  const _SectionLabel('Support'),
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & FAQ',
                    onTap: () async {
                      final url = Uri.parse('https://halaltune.vercel.app');
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {}
                    },
                  ),
                  _MenuItem(
                    icon: Icons.policy_rounded,
                    label: 'Privacy Policy',
                    onTap: () => _openPage(context, 'Privacy Policy', _privacyContent),
                  ),
                  _MenuItem(
                    icon: Icons.gavel_rounded,
                    label: 'Terms of Service',
                    onTap: () => _openPage(context, 'Terms of Service', _termsContent),
                  ),
                  const SizedBox(height: 24),
                  // Sign out button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      textStyle: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1E1E),
                          title: const Text('Sign Out?', style: TextStyle(fontFamily: 'Roboto', color: Colors.white)),
                          content: const Text('You will need to sign in again to access your data.', style: TextStyle(fontFamily: 'Roboto', color: Color(0xFFAAAAAA))),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), style: TextButton.styleFrom(foregroundColor: Colors.white), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black), child: const Text('Sign Out')),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await auth.signOut();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('HalalTune v1.0.0  ·  © 2026',
                      style: TextStyle(color: Color(0xFF666666), fontSize: 11, fontFamily: 'Roboto')),
                  ),
                ]),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _openHistory(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  void _openPage(BuildContext context, String title, String content) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _TextPage(title: title, content: content)));
  }
}

// ── Profile header ──────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatar = user?.photoURL;
    final name = user?.displayName ?? 'Guest';
    final email = user?.email ?? '';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: SafeArea(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF1E1E1E),
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? const Icon(Icons.person_rounded, color: Colors.white, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Roboto')),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, fontFamily: 'Roboto')),
          ]
        ]),
      ),
    );
  }
}

// ── Section label ───────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(label.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: 'Roboto')),
    );
  }
}

// ── Menu item ───────────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(label, style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500, color: Colors.white, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF666666), size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// history screen is in history_screen.dart
// (removed duplicate _HistoryScreen class)

// ── Generic text page (Privacy / Terms) ─────────────────────────────────────────
class _TextPage extends StatelessWidget {
  final String title;
  final String content;
  const _TextPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: _MarkdownText(content: content),
      ),
    );
  }
}

class _MarkdownText extends StatelessWidget {
  final String content;
  const _MarkdownText({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Text(line.substring(3), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Roboto')),
          );
        }
        if (line.startsWith('• ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('• ', style: TextStyle(color: Colors.white, fontFamily: 'Roboto')),
              Expanded(child: Text(line.substring(2), style: const TextStyle(color: Color(0xFFAAAAAA), fontFamily: 'Roboto', height: 1.6, fontSize: 14))),
            ]),
          );
        }
        if (line.trim().isEmpty) return const SizedBox(height: 6);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(line, style: const TextStyle(color: Color(0xFFAAAAAA), fontFamily: 'Roboto', height: 1.7, fontSize: 14)),
        );
      }).toList(),
    );
  }
}

// ── Privacy Policy content ─────────────────────────────────────────────────────
const String _privacyContent = '''
HalalTune is committed to protecting your privacy. This policy explains what information we collect, how we use it, and your rights as a user.

Last updated: March 2026

## 1. Information We Collect

HalalTune collects only the minimum information necessary to provide its service:

• Google Account (optional): If you sign in with Google, we receive your name, email, and profile picture. This is used solely to identify your account.
• Playback activity: Songs you play may be stored to support history and saved tracks, associated with your account if signed in.
• Device information: Basic technical data (e.g. Android version, device model) may be collected for crash reporting and stability purposes.

## 2. Information We Do Not Collect

• We do not collect your precise location.
• We do not collect your contacts, SMS, or call logs.
• We do not record your microphone or camera.
• We do not sell, rent, or trade your personal data to third parties.
• We do not display targeted advertisements.

## 3. How We Use Your Information

• To authenticate your account and save your preferences.
• To provide and improve the HalalTune streaming experience.
• To diagnose technical issues and improve app stability.

## 4. Third-Party Services

HalalTune uses the following third-party services, each with their own privacy policy:

• Google Sign-In – for optional account authentication. (policies.google.com/privacy)
• Firebase – for backend services and authentication. (firebase.google.com/support/privacy)

## 5. Data Storage & Security

Your data is stored securely using Firebase infrastructure. We implement reasonable technical and organisational measures to protect your information from unauthorised access, loss, or misuse.

## 6. Children's Privacy

HalalTune is not directed at children under the age of 13. We do not knowingly collect personal data from children. If you believe a child has provided us with personal data, please contact us and we will delete it promptly.

## 7. Your Rights

• Access the personal data we hold about you.
• Request deletion of your account and associated data.
• Withdraw consent for Google sign-in at any time by signing out.

To exercise these rights, please contact: support@halaltune.app

## 8. Changes to This Policy

We may update this Privacy Policy from time to time. We will notify users of significant changes through an in-app notice. Continued use after changes constitutes acceptance.

## 9. Contact Us

📧 support@halaltune.app

© 2026 HalalTune. All rights reserved.
''';

// ── Terms of Service content ───────────────────────────────────────────────────
const String _termsContent = '''
Please read these Terms of Service carefully before using the HalalTune application.

Last updated: March 2026

## 1. Acceptance of Terms

By accessing or using HalalTune, you agree to be bound by these Terms of Service. If you disagree with any part of the terms, please do not use our application.

## 2. Use of the Application

• HalalTune is provided for personal, non-commercial use only.
• You must not use the app in any way that is unlawful, harmful, or that violates these terms.
• You are responsible for maintaining the confidentiality of your account credentials.

## 3. Content

• All audio content provided through HalalTune is the property of its respective rights holders.
• HalalTune does not claim ownership of any audio content streamed through the application.
• You may not copy, distribute, or create derivative works from the content without permission.

## 4. Prohibited Activities

You agree not to:

• Attempt to reverse-engineer or hack the application.
• Use the application to distribute spam or malicious content.
• Circumvent any content protection mechanisms.
• Access the service using automated means without prior permission.

## 5. Disclaimer of Warranties

HalalTune is provided "as is" without warranties of any kind, either express or implied. We do not guarantee that the service will be uninterrupted, secure, or error-free.

## 6. Limitation of Liability

To the fullest extent permitted by law, HalalTune shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the application.

## 7. Changes to Terms

We reserve the right to modify these Terms of Service at any time. Continued use of the application after any changes constitutes your acceptance of the new Terms.

## 8. Governing Law

These Terms shall be governed by and construed in accordance with applicable law, without regard to conflict of law principles.

## 9. Contact Us

For any questions about these Terms of Service, please contact us:

📧 support@halaltune.app

© 2026 HalalTune. All rights reserved.
''';
