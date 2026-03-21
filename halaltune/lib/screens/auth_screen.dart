import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

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
  bool _obscurePass = true;

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
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo
                Image.asset('assets/images/icon.png', width: 80, height: 80),
                const SizedBox(height: 20),
                const Text(
                  'HalalTune',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to save your playlists and\nliked songs across all your devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontFamily: 'Outfit',
                      height: 1.5),
                ),
                const SizedBox(height: 40),

                // Google sign in
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return Column(
                      children: [
                        if (auth.error != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.danger.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppTheme.danger, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(auth.error!,
                                        style: const TextStyle(
                                            color: AppTheme.danger,
                                            fontSize: 13,
                                            fontFamily: 'Outfit'))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Google button
                        _GoogleButton(onTap: () async {
                          auth.clearError();
                          setState(() => _loading = true);
                          await auth.signInWithGoogle();
                          setState(() => _loading = false);
                        }),
                        const SizedBox(height: 20),

                        // Divider
                        const Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: AppTheme.surface, thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('or',
                                  style: TextStyle(
                                      color: AppTheme.textDim,
                                      fontFamily: 'Outfit')),
                            ),
                            Expanded(
                                child: Divider(
                                    color: AppTheme.surface, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Email input
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontFamily: 'Outfit'),
                          decoration: const InputDecoration(
                            hintText: 'Email address',
                            prefixIcon: Icon(Icons.email_outlined,
                                color: AppTheme.textDim, size: 20),
                          ),
                          onChanged: (_) => auth.clearError(),
                        ),
                        const SizedBox(height: 12),

                        // Password input
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontFamily: 'Outfit'),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AppTheme.textDim, size: 20),
                            suffixIcon: GestureDetector(
                              onTap: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                              child: Icon(
                                  _obscurePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppTheme.textDim,
                                  size: 20),
                            ),
                          ),
                          onChanged: (_) => auth.clearError(),
                        ),
                        const SizedBox(height: 20),

                        // Sign in / Sign up button
                        ElevatedButton(
                          onPressed: _loading ? null : () => _submit(auth),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2))
                              : Text(
                                  _isSignUp ? 'Create Account' : 'Sign In',
                                  style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                        ),
                        const SizedBox(height: 12),

                        // Toggle sign up / sign in
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() => _isSignUp = !_isSignUp);
                                auth.clearError();
                              },
                              child: Text(
                                _isSignUp
                                    ? 'Already have an account? Sign In'
                                    : 'New here? Create account',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontFamily: 'Outfit',
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),

                        if (!_isSignUp)
                          TextButton(
                            onPressed: () => _forgotPassword(context, auth),
                            child: const Text('Forgot password?',
                                style: TextStyle(
                                    color: AppTheme.textDim,
                                    fontFamily: 'Outfit',
                                    fontSize: 13)),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    setState(() => _loading = false);
  }

  void _forgotPassword(BuildContext context, AuthProvider auth) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter your email address first.'),
            backgroundColor: AppTheme.bgElevated),
      );
      return;
    }
    final sent = await auth.resetPassword(email);
    if (sent && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password reset email sent!'),
            backgroundColor: AppTheme.bgElevated),
      );
    }
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceHigh),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleIcon(),
            SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
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

    // Simple G approximation using colored arc segments
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335)
    ];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        (i * 90 - 45) * 3.14159 / 180,
        90 * 3.14159 / 180,
        true,
        paint,
      );
    }
    // White center
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, paint);
    // Blue right cutout
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(cx, cy - r * 0.3, r, r * 0.6), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
