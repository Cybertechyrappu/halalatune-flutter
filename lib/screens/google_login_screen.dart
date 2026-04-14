import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../services/innertube/youtube_auth_service.dart';
import '../theme/app_theme.dart';

/// Google Sign-In webview screen for YouTube Music API authentication
///
/// This screen presents a webview for users to sign in with their Google account
/// to obtain OAuth tokens for the YouTube Music InnerTube API.
class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  String? _error;

  // Google OAuth authorization URL
  static const String _authUrl =
      'https://accounts.google.com/o/oauth2/v2/auth'
      '?client_id=YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com'
      '&redirect_uri=urn:ietf:wg:oauth:2.0:oob'
      '&response_type=code'
      '&scope=https://www.googleapis.com/auth/youtube.readonly'
      '&access_type=offline'
      '&prompt=consent';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _error = null;
            });
            _checkForAuthCode(url);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            _checkForAuthCode(request.url);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_authUrl));
  }

  /// Check if the URL contains an authorization code
  void _checkForAuthCode(String url) {
    // Look for the authorization code in the URL
    if (url.contains('code=') || url.contains('title="Success"')) {
      _extractAuthCode(url);
    }
  }

  /// Extract authorization code from URL or page content
  Future<void> _extractAuthCode(String url) async {
    try {
      // Try to extract code from URL
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];

      if (code != null && code.isNotEmpty) {
        await _handleAuthCode(code);
      } else {
        // Try to get code from page content if not in URL
        final pageContent = await _webViewController.runJavaScriptReturningResult(
          'document.body.innerText',
        );
        
        if (pageContent is String && pageContent.contains('code=')) {
          final codeMatch = RegExp(r'code=([a-zA-Z0-9_-]+)').firstMatch(pageContent);
          if (codeMatch != null) {
            await _handleAuthCode(codeMatch.group(1)!);
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting auth code: $e');
      setState(() => _error = 'Failed to extract authentication code');
    }
  }

  /// Handle the received authorization code
  Future<void> _handleAuthCode(String code) async {
    final authService = context.read<YoutubeAuthService>();
    final success = await authService.signInWithGoogle(authCode: code);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else if (mounted) {
      setState(() {
        _error = authService.error ?? 'Authentication failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        elevation: 0,
        title: const Text(
          'Sign in to YouTube Music',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
          splashRadius: 20,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.accent),
                    SizedBox(height: 16),
                    Text(
                      'Loading Google Sign-In...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontFamily: 'Outfit',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Error message
          if (_error != null)
            Container(
              color: Colors.black.withValues(alpha: 0.9),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Authentication Error',
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontFamily: 'Outfit',
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _error = null);
                          _initializeWebView();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
