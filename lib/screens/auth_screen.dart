import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 350),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/icontrans.png', width: 60, height: 60),
                        const SizedBox(height: 20),
                        const Text(
                          'Welcome',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Sign in to save your playlists and\nliked songs across all your devices.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              height: 1.5),
                        ),
                        const SizedBox(height: 25),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return Column(
                              children: [
                                if (auth.error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(auth.error!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Color(0xFFFF6B6B),
                                            fontSize: 13,
                                            height: 1.4,
                                            fontFamily: 'Roboto')),
                                  ),
                                ElevatedButton.icon(
                                  onPressed: _loading ? null : () async {
                                    auth.clearError();
                                    setState(() => _loading = true);
                                    await auth.signInWithGoogle();
                                    if (mounted) setState(() => _loading = false);
                                  },
                                  icon: const _GoogleIcon(),
                                  label: Text(_loading ? 'Signing in...' : 'Continue with Google',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Roboto', color: Colors.black)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    elevation: 0,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2))),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('or', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, fontFamily: 'Roboto')),
                                    ),
                                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2))),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _AuthInput(controller: _emailCtrl, hint: 'Email address', obscure: false, onChanged: (_) => auth.clearError()),
                                const SizedBox(height: 12),
                                _AuthInput(controller: _passCtrl, hint: 'Password', obscure: true, onChanged: (_) => auth.clearError()),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loading ? null : () => _submit(auth),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 0,
                              ),
                              child: Text(
                                _isSignUp ? 'Creating account...' : 'Sign In',
                                style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Action buttons
                            _AuthLinkBtn(
                              text: _isSignUp ? 'Back to Sign In' : 'Create account',
                              onTap: () {
                                setState(() => _isSignUp = !_isSignUp);
                                auth.clearError();
                              },
                            ),
                            if (!_isSignUp)
                              _AuthLinkBtn(
                                text: 'Forgot password?',
                                onTap: () => _forgotPassword(context, auth),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ), // Column
              ), // Container
            ), // BackdropFilter
          ), // ClipRRect
        ), // SingleChildScrollView
      ), // Center
    ), // FadeTransition
  ), // SafeArea
); // Scaffold
  }

  Future<void> _submit(AuthProvider auth) async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    setState(() => _loading = true);
    if (_isSignUp) {
      await auth.signUpWithEmail(email, pass);
    } else {
      await auth.signInWithEmail(email, pass);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _forgotPassword(BuildContext context, AuthProvider auth) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email address first.')));
      return;
    }
    await auth.resetPassword(email);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent!')));
    }
  }
}

class _AuthInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Function(String) onChanged;

  const _AuthInput({required this.controller, required this.hint, required this.obscure, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Roboto'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF444444)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          isDense: true,
        ),
      ),
    );
  }
}

class _AuthLinkBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _AuthLinkBtn({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Text(text, style: const TextStyle(color: Color(0xFF666666), fontSize: 13, fontFamily: 'Roboto')),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final colors = [const Color(0xFF4285F4), const Color(0xFF34A853), const Color(0xFFFBBC05), const Color(0xFFEA4335)];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), (i * 90 - 45) * 3.14159 / 180, 90 * 3.14159 / 180, true, paint);
    }
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(cx, cy - r * 0.3, r, r * 0.6), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
