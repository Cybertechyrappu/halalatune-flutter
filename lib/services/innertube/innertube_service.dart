import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'models/innertube_models.dart';
import 'youtube_auth_service.dart';

/// YouTube InnerTube API Service
/// 
/// This service interacts with YouTube Music's internal API (InnerTube) to:
/// - Search for music
/// - Get streaming URLs via the player endpoint
/// - Browse music content
/// 
/// Base URL: https://music.youtube.com/youtubei/v1/
class InnerTubeService {
  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const String _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';

  final http.Client _client;
  final YoutubeAuthService? _authService;

  // Context data
  String? _visitorData;

  final InnerTubeClient _clientInfo = InnerTubeClient();

  InnerTubeService({http.Client? client, YoutubeAuthService? authService}) 
      : _client = client ?? http.Client(),
        _authService = authService;

  // ── Search ─────────────────────────────────────────────────────────────────

  /// Search for music on YouTube Music
  /// [query] - Search query string
  /// [params] - Filter params (EgWKAQIIAWoKEAkQBRAKEAMQBBAJEBU%3D for songs)
  Future<List<YouTubeTrack>> search({
    required String query,
    String? params,
  }) async {
    try {
      final body = {
        'context': _buildContext(),
        'query': query,
        if (params != null) 'params': params,
      };

      final response = await _post('search', body);
      if (response == null) return [];

      final List<YouTubeTrack> results = [];
      
      // Parse search results from response
      final contents = response['contents']?['tabbedSearchResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      
      if (contents != null && contents is List) {
        for (final section in contents) {
          final musicShelf = section['musicShelfRenderer'];
          if (musicShelf == null) continue;
          
          final contents = musicShelf['contents'];
          if (contents is List) {
            for (final item in contents) {
              final musicResponsiveListItem = item['musicResponsiveListItemRenderer'];
              if (musicResponsiveListItem == null) continue;
              
              try {
                final track = _parseMusicResponsiveListItem(musicResponsiveListItem);
                if (track != null) results.add(track);
              } catch (e) {
                debugPrint('Error parsing track: $e');
              }
            }
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint('InnerTube search error: $e');
      return [];
    }
  }

  // ── Player (Get Stream URL) ────────────────────────────────────────────────

  /// Get streaming URLs for a video
  /// [videoId] - YouTube video ID
  Future<PlayerResponse?> getPlayer(String videoId) async {
    try {
      final body = {
        'context': _buildContext(),
        'videoId': videoId,
      };

      final response = await _post('player', body);
      if (response == null) return null;

      // Check for playability errors
      final playabilityStatus = response['playabilityStatus'];
      final status = playabilityStatus?['status'];
      if (status == 'ERROR' || status == 'LOGIN_REQUIRED') {
        debugPrint('Video not playable: ${playabilityStatus?['reason']}');
        return null;
      }

      return PlayerResponse.fromMap(response);
    } catch (e) {
      debugPrint('InnerTube player error: $e');
      return null;
    }
  }

  /// Get just the best audio URL for a video ID (convenience method)
  Future<String?> getAudioUrl(String videoId) async {
    final playerResponse = await getPlayer(videoId);
    return playerResponse?.bestAudioStream?.url;
  }

  // ── Browse ─────────────────────────────────────────────────────────────────

  /// Browse a YouTube page (home, playlists, etc.)
  Future<List<BrowseSection>> browse({
    String? browseId,
    String? params,
  }) async {
    try {
      final body = {
        'context': _buildContext(),
        if (browseId != null) 'browseId': browseId,
        if (params != null) 'params': params,
      };

      final response = await _post('browse', body);
      if (response == null) return [];

      final List<BrowseSection> sections = [];
      
      final contents = response['contents']?['singleColumnBrowseResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

      if (contents != null && contents is List) {
        for (final section in contents) {
          final musicShelf = section['musicShelfRenderer'];
          if (musicShelf == null) continue;

          final title = musicShelf['title']?['runs']?[0]?['text'] ?? 
                        musicShelf['title']?['simpleText'] ?? 'Unknown';
          
          final List<YouTubeTrack> tracks = [];
          final shelfContents = musicShelf['contents'];
          if (shelfContents is List) {
            for (final item in shelfContents) {
              final musicResponsiveListItem = item['musicResponsiveListItemRenderer'];
              if (musicResponsiveListItem != null) {
                final track = _parseMusicResponsiveListItem(musicResponsiveListItem);
                if (track != null) tracks.add(track);
              }
            }
          }

          sections.add(BrowseSection(title: title, tracks: tracks));
        }
      }

      return sections;
    } catch (e) {
      debugPrint('InnerTube browse error: $e');
      return [];
    }
  }

  // ── Next (Get queue/related tracks) ────────────────────────────────────────

  /// Get next/related tracks for a video
  Future<List<YouTubeTrack>> getNext({
    required String videoId,
    String? playlistId,
  }) async {
    try {
      final body = {
        'context': _buildContext(),
        'videoId': videoId,
        if (playlistId != null) 'playlistId': playlistId,
      };

      final response = await _post('next', body);
      if (response == null) return [];

      final List<YouTubeTrack> results = [];
      
      final contents = response['contents']?['singleColumnMusicNextRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

      if (contents != null && contents is List) {
        for (final section in contents) {
          final musicShelf = section['musicShelfRenderer'];
          if (musicShelf == null) continue;

          final shelfContents = musicShelf['contents'];
          if (shelfContents is List) {
            for (final item in shelfContents) {
              final musicResponsiveListItem = item['musicResponsiveListItemRenderer'];
              if (musicResponsiveListItem != null) {
                final track = _parseMusicResponsiveListItem(musicResponsiveListItem);
                if (track != null) results.add(track);
              }
            }
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint('InnerTube next error: $e');
      return [];
    }
  }

  // ── Internal Helpers ───────────────────────────────────────────────────────

  /// Build the InnerTube context payload
  Map<String, dynamic> _buildContext() {
    final context = <String, dynamic>{
      'client': _clientInfo.toJson(),
    };
    if (_visitorData != null) {
      context['visitorData'] = _visitorData;
    }
    return context;
  }

  /// Build headers for InnerTube API requests
  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': _clientInfo.userAgent,
      'X-YouTube-Client-Name': '67',
      'X-YouTube-Client-Version': _clientInfo.clientVersion,
      'Origin': 'https://music.youtube.com',
      'Referer': 'https://music.youtube.com/',
    };

    // Add authorization header if authenticated
    if (_authService != null && _authService!.isAuthenticated) {
      final token = await _authService!.getValidToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('Using authenticated InnerTube request');
      }
    }

    return headers;
  }

  /// POST request to InnerTube endpoint
  Future<Map<String, dynamic>?> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$_baseUrl/$endpoint?key=$_apiKey');
      final headers = await _buildHeaders();

      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Extract visitor data from response if not already set
        _visitorData ??= data['webResponseContext']?['mainAppWebResponseContext']
            ?['datasyncId'];
        
        return data;
      } else {
        debugPrint('InnerTube API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('InnerTube request error: $e');
      return null;
    }
  }

  /// Parse a musicResponsiveListItemRenderer into a YouTubeTrack
  YouTubeTrack? _parseMusicResponsiveListItem(Map<String, dynamic> data) {
    try {
      // Extract video ID from navigation endpoint
      String? videoId;
      final navigationEndpoint = data['navigationEndpoint'];
      if (navigationEndpoint != null) {
        videoId = navigationEndpoint['watchEndpoint']?['videoId'] ??
                  navigationEndpoint['watchPlaylistEndpoint']?['videoId'];
      }
      
      if (videoId == null || videoId.isEmpty) return null;

      // Parse title from first flex column
      String title = 'Unknown';
      String? artist;
      String? album;
      Duration? duration;
      String? thumbnailUrl;

      final flexColumns = data['flexColumns'];
      if (flexColumns != null && flexColumns is List && flexColumns.isNotEmpty) {
        // Title is typically in first column
        final titleColumn = flexColumns[0];
        final titleRuns = titleColumn['musicResponsiveListItemFlexColumnRenderer']
            ?['text']?['runs'];
        if (titleRuns != null && titleRuns is List && titleRuns.isNotEmpty) {
          title = titleRuns.map((r) => r['text'] ?? '').join();
        }

        // Artist/Album in second column
        if (flexColumns.length > 1) {
          final subColumn = flexColumns[1];
          final subRuns = subColumn['musicResponsiveListItemFlexColumnRenderer']
              ?['text']?['runs'];
          if (subRuns != null && subRuns is List && subRuns.isNotEmpty) {
            // First run is usually artist
            if (subRuns.isNotEmpty) {
              artist = subRuns[0]['text'];
            }
            // Look for album separator and album name
            for (int i = 1; i < subRuns.length; i++) {
              final run = subRuns[i];
              if (run['text'] == ' • ' && i + 1 < subRuns.length) {
                album = subRuns[i + 1]['text'];
                break;
              }
            }
          }
        }
      }

      // Parse duration from menu items
      final menuItems = data['menu']?['menuRenderer']?['items'];
      if (menuItems != null && menuItems is List) {
        for (final item in menuItems) {
          final time = item['menuNavigationItemRenderer']
                  ?['subtitle']?['simpleText'] ??
              item['menuServiceItemRenderer']?['text']?['simpleText'];
          if (time != null && time.contains(':')) {
            final parts = time.split(':');
            if (parts.length == 2) {
              final minutes = int.tryParse(parts[0]) ?? 0;
              final seconds = int.tryParse(parts[1]) ?? 0;
              duration = Duration(minutes: minutes, seconds: seconds);
            }
          }
        }
      }

      // Also try overlay for duration
      final overlay = data['overlay']?['musicItemThumbnailOverlayRenderer']
          ?['content']?['musicPlayButtonRenderer']?['text']?['simpleText'];
      if (overlay != null && duration == null && overlay.contains(':')) {
        final parts = overlay.split(':');
        if (parts.length == 2) {
          final minutes = int.tryParse(parts[0]) ?? 0;
          final seconds = int.tryParse(parts[1]) ?? 0;
          duration = Duration(minutes: minutes, seconds: seconds);
        }
      }

      // Parse thumbnail
      final thumbnail = data['thumbnail']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'];
      if (thumbnail != null && thumbnail is List && thumbnail.isNotEmpty) {
        thumbnailUrl = thumbnail.last['url'];
      }

      return YouTubeTrack(
        videoId: videoId,
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      debugPrint('Error parsing list item: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
