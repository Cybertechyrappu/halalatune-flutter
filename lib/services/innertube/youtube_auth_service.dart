import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// YouTube OAuth service for InnerTube API authentication
///
/// This service handles Google Sign-In specifically for YouTube Music API access,
/// obtaining OAuth tokens that can be used with the InnerTube API for:
/// - Higher API rate limits
/// - Access to restricted content
/// - Better stream URL resolution
///
/// OAuth Flow:
/// 1. User logs in via Google OAuth web flow
/// 2. We obtain access_token and refresh_token
/// 3. Tokens are stored securely and used in InnerTube API calls
class YoutubeAuthService extends ChangeNotifier {
  static const String _tokenKey = 'youtube_access_token';
  static const String _refreshTokenKey = 'youtube_refresh_token';
  static const String _expiryKey = 'youtube_token_expiry';
  static const String _userEmailKey = 'youtube_user_email';

  // Google OAuth credentials
  // These should be configured in Google Cloud Console
  static const String _clientId = 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';
  static const String _clientSecret = 'YOUR_GOOGLE_CLIENT_SECRET';
  static const String _redirectUri = 'urn:ietf:wg:oauth:2.0:oob';

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  String? _userEmail;
  bool _isLoading = false;
  String? _error;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userEmail => _userEmail;
  bool get isAuthenticated => _accessToken != null && !_isTokenExpired;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get _isTokenExpired {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  YoutubeAuthService() {
    _loadTokens();
  }

  /// Load saved tokens from SharedPreferences
  Future<void> _loadTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      final expiryStr = prefs.getString(_expiryKey);
      _userEmail = prefs.getString(_userEmailKey);

      if (expiryStr != null) {
        _tokenExpiry = DateTime.parse(expiryStr);
      }

      // If token is expired, try to refresh
      if (_isTokenExpired && _refreshToken != null) {
        await _refreshAccessToken();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tokens: $e');
    }
  }

  /// Save tokens to SharedPreferences
  Future<void> _saveTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString(_tokenKey, _accessToken!);
      }
      if (_refreshToken != null) {
        await prefs.setString(_refreshTokenKey, _refreshToken!);
      }
      if (_tokenExpiry != null) {
        await prefs.setString(_expiryKey, _tokenExpiry!.toIso8601String());
      }
      if (_userEmail != null) {
        await prefs.setString(_userEmailKey, _userEmail!);
      }
    } catch (e) {
      debugPrint('Error saving tokens: $e');
    }
  }

  /// Clear all tokens (logout)
  Future<void> _clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_expiryKey);
      await prefs.remove(_userEmailKey);

      _accessToken = null;
      _refreshToken = null;
      _tokenExpiry = null;
      _userEmail = null;
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
    }
  }

  /// Authenticate with Google OAuth
  /// Returns auth code that can be used to get tokens
  /// The actual token exchange should be done server-side for security
  /// For client-side, we use the authorization code flow
  Future<bool> signInWithGoogle({
    required String authCode,
    String? email,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      // Exchange authorization code for tokens
      final tokenResponse = await _exchangeCodeForTokens(authCode);

      if (tokenResponse != null) {
        _accessToken = tokenResponse['access_token'];
        _refreshToken = tokenResponse['refresh_token'] ?? _refreshToken;
        
        // Calculate expiry time
        final expiresIn = tokenResponse['expires_in'] ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        _userEmail = email;

        await _saveTokens();
        
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _error = 'Failed to authenticate';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Auth error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Exchange OAuth code for tokens
  Future<Map<String, dynamic>?> _exchangeCodeForTokens(String code) async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': _redirectUri,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Token exchange failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error exchanging code: $e');
      return null;
    }
  }

  /// Refresh the access token using the refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'refresh_token': _refreshToken!,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _accessToken = data['access_token'];
        
        final expiresIn = data['expires_in'] ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        await _saveTokens();
        notifyListeners();
        return true;
      } else {
        debugPrint('Token refresh failed: ${response.body}');
        // Clear tokens and force re-authentication
        await _clearTokens();
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  /// Get a valid access token, refreshing if necessary
  Future<String?> getValidToken() async {
    if (_accessToken == null) return null;

    if (_isTokenExpired) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) return null;
    }

    return _accessToken;
  }

  /// Sign out and clear tokens
  Future<void> signOut() async {
    await _clearTokens();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
