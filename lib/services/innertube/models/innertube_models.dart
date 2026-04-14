/// Models for YouTube InnerTube API responses.
/// 
/// Contains data classes for tracks, playlists, streams, and API context.
library;

class InnerTubeContext {
  final InnerTubeClient client;
  final String? visitorData;
  final Map<String, dynamic>? additionalContext;

  InnerTubeContext({
    required this.client,
    this.visitorData,
    this.additionalContext,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'client': client.toJson()};
    if (visitorData != null) map['visitorData'] = visitorData;
    if (additionalContext != null) map.addAll(additionalContext!);
    return map;
  }
}

class InnerTubeClient {
  final String clientName;
  final String clientVersion;
  final String hl;
  final String gl;
  final String userAgent;

  InnerTubeClient({
    this.clientName = 'WEB_REMIX',
    this.clientVersion = '1.20240403.01.00',
    this.hl = 'en',
    this.gl = 'US',
    this.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
  });

  Map<String, dynamic> toJson() => {
        'clientName': clientName,
        'clientVersion': clientVersion,
        'hl': hl,
        'gl': gl,
        'userAgent': userAgent,
      };
}

// ── Search Results ─────────────────────────────────────────────────────────────

class YouTubeTrack {
  final String videoId;
  final String title;
  final String? artist;
  final String? album;
  final Duration? duration;
  final String? thumbnailUrl;
  final int? viewCount;
  final String? playlistId;
  final bool isExplicit;
  final List<String>? categories;
  final String? description;

  YouTubeTrack({
    required this.videoId,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.thumbnailUrl,
    this.viewCount,
    this.playlistId,
    this.isExplicit = false,
    this.categories,
    this.description,
  });

  factory YouTubeTrack.fromSearchResult(Map<String, dynamic> data) {
    final videoRenderer = data['videoResult'] ?? data['videoRenderer'] ?? {};
    final titleRuns = videoRenderer['title'];
    final title = _parseRuns(titleRuns) ?? _parseText(titleRuns) ?? 'Unknown';

    // Parse artist from artists array
    String? artist;
    final artists = videoRenderer['artists'];
    if (artists != null && artists is List && artists.isNotEmpty) {
      artist = _parseRuns(artists[0]) ?? _parseText(artists[0]);
    }

    // Parse album
    String? album;
    final albumData = videoRenderer['album'];
    if (albumData != null) {
      album = _parseRuns(albumData) ?? _parseText(albumData);
    }

    // Parse duration
    Duration? duration;
    final durationMs = videoRenderer['durationMs'];
    if (durationMs != null) {
      duration = Duration(milliseconds: int.parse(durationMs.toString()));
    } else if (videoRenderer['lengthSeconds'] != null) {
      duration = Duration(seconds: int.parse(videoRenderer['lengthSeconds'].toString()));
    }

    // Parse thumbnail
    String? thumbnailUrl;
    final thumbnails = videoRenderer['thumbnail'];
    if (thumbnails != null) {
      final thumbList = thumbnails['thumbnails'] ?? thumbnails;
      if (thumbList is List && thumbList.isNotEmpty) {
        // Get highest resolution thumbnail
        thumbnailUrl = thumbList.last['url'];
      }
    }

    // Parse view count
    int? viewCount;
    final viewCountText = videoRenderer['viewCountText'];
    if (viewCountText != null) {
      final views = _parseText(viewCountText);
      if (views != null) {
        viewCount = int.tryParse(views.replaceAll(RegExp(r'[^0-9]'), ''));
      }
    }

    // Check explicit badge
    bool isExplicit = false;
    final badges = videoRenderer['badges'];
    if (badges != null && badges is List) {
      for (final badge in badges) {
        final badgeText = _parseRuns(badge) ?? _parseText(badge);
        if (badgeText != null && badgeText.toLowerCase().contains('explicit')) {
          isExplicit = true;
        }
      }
    }

    return YouTubeTrack(
      videoId: videoRenderer['videoId'] ?? '',
      title: title.toString(),
      artist: artist,
      album: album,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
      viewCount: viewCount,
      isExplicit: isExplicit,
    );
  }

  static String? _parseRuns(dynamic data) {
    if (data == null) return null;
    final runs = data['runs'];
    if (runs is List && runs.isNotEmpty) {
      return runs.map((r) => r['text'] ?? '').join();
    }
    return null;
  }

  static String? _parseText(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    return data['simpleText'] ?? data['text'];
  }

  @override
  String toString() => 'YouTubeTrack($title - $artist)';
}

class YouTubePlaylist {
  final String playlistId;
  final String title;
  final String? author;
  final int? videoCount;
  final String? thumbnailUrl;

  YouTubePlaylist({
    required this.playlistId,
    required this.title,
    this.author,
    this.videoCount,
    this.thumbnailUrl,
  });
}

// ── Player Response ────────────────────────────────────────────────────────────

class StreamInfo {
  final String url;
  final String? mimeType;
  final int? bitrate;
  final int? contentLength;
  final int? width;
  final int? height;
  final String? quality;
  final String? fps;
  final bool isAudio;

  StreamInfo({
    required this.url,
    this.mimeType,
    this.bitrate,
    this.contentLength,
    this.width,
    this.height,
    this.quality,
    this.fps,
    this.isAudio = true,
  });

  bool get isVideo => !isAudio;
}

class PlayerResponse {
  final String videoId;
  final String title;
  final String? artist;
  final Duration? duration;
  final String? thumbnailUrl;
  final List<StreamInfo> streamInfos;
  final String? captionsUrl;

  PlayerResponse({
    required this.videoId,
    required this.title,
    this.artist,
    this.duration,
    this.thumbnailUrl,
    required this.streamInfos,
    this.captionsUrl,
  });

  StreamInfo? get bestAudioStream {
    // Prefer audio-only streams (m4a, webm audio)
    for (final stream in streamInfos) {
      if (stream.isAudio && stream.mimeType != null && 
          (stream.mimeType!.contains('audio/mp4') || stream.mimeType!.contains('audio/webm'))) {
        if (stream.quality == 'tiny' || stream.height == null) {
          return stream;
        }
      }
    }
    // Fallback to first audio stream
    return streamInfos.where((s) => s.isAudio).firstOrNull;
  }

  factory PlayerResponse.fromMap(Map<String, dynamic> data) {
    final videoDetails = data['videoDetails'] ?? {};
    final streamingData = data['streamingData'] ?? {};

    final List<StreamInfo> streams = [];

    // Parse adaptiveFormats (preferred for audio)
    final adaptiveFormats = streamingData['adaptiveFormats'] ?? [];
    for (final format in adaptiveFormats) {
      final mimeType = format['mimeType'] as String? ?? '';
      final isAudio = mimeType.startsWith('audio/');
      final url = format['url'] ?? format['signatureCipher'];
      
      if (url != null) {
        streams.add(StreamInfo(
          url: url is String ? url : url.toString(),
          mimeType: mimeType,
          bitrate: format['bitrate'],
          contentLength: int.tryParse(format['contentLength']?.toString() ?? '0'),
          width: format['width'],
          height: format['height'],
          quality: format['quality'],
          fps: format['fps']?.toString(),
          isAudio: isAudio,
        ));
      }
    }

    // Parse formats array as fallback
    final formats = streamingData['formats'] ?? [];
    for (final format in formats) {
      final mimeType = format['mimeType'] as String? ?? '';
      final isAudio = mimeType.startsWith('audio/');
      final url = format['url'];
      
      if (url != null && streams.where((s) => s.url == url).isEmpty) {
        streams.add(StreamInfo(
          url: url.toString(),
          mimeType: mimeType,
          bitrate: format['bitrate'],
          contentLength: int.tryParse(format['contentLength']?.toString() ?? '0'),
          width: format['width'],
          height: format['height'],
          quality: format['quality'],
          fps: format['fps']?.toString(),
          isAudio: isAudio,
        ));
      }
    }

    // Sort audio streams by bitrate (highest first)
    streams.sort((a, b) {
      if (a.isAudio != b.isAudio) return b.isAudio ? 1 : -1;
      return (b.bitrate ?? 0).compareTo(a.bitrate ?? 0);
    });

    return PlayerResponse(
      videoId: videoDetails['videoId'] ?? '',
      title: videoDetails['title'] ?? 'Unknown',
      artist: videoDetails['author'],
      duration: videoDetails['lengthSeconds'] != null
          ? Duration(seconds: int.parse(videoDetails['lengthSeconds'].toString()))
          : null,
      thumbnailUrl: videoDetails['thumbnail']?['thumbnails']?.last?['url'],
      streamInfos: streams,
    );
  }
}

// ── Browse Response ────────────────────────────────────────────────────────────

class BrowseSection {
  final String title;
  final List<YouTubeTrack> tracks;
  final List<YouTubePlaylist> playlists;

  BrowseSection({
    required this.title,
    this.tracks = const [],
    this.playlists = const [],
  });
}
