import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/innertube/models/innertube_models.dart';

/// Source type for the track
enum TrackSource {
  firestore,  // From Firebase Firestore (original app data)
  youtube,    // From YouTube InnerTube API
}

class Track {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String? coverArt;
  final String language;
  final int streamCount;
  final int likeCount;
  final int downloadCount;
  final String? lyrics;
  final String? lyricsProvider;
  final String? lyricsProviderUrl;
  final String? lyricsRedirectUrl;
  final DateTime? createdAt;
  
  // YouTube-specific fields
  final TrackSource source;
  final String? youtubeVideoId;     // YouTube video ID (for InnerTube)
  final Duration? duration;          // Track duration
  final bool isExplicit;             // YouTube explicit flag
  final List<String>? categories;    // YouTube categories
  
  // Resolved stream URL (fetched from InnerTube player endpoint)
  /// Stream URL resolved from InnerTube player endpoint.
  String? streamUrl;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.coverArt,
    required this.language,
    this.streamCount = 0,
    this.likeCount = 0,
    this.downloadCount = 0,
    this.lyrics,
    this.lyricsProvider,
    this.lyricsProviderUrl,
    this.lyricsRedirectUrl,
    this.createdAt,
    this.source = TrackSource.firestore,
    this.youtubeVideoId,
    this.duration,
    this.isExplicit = false,
    this.categories,
  });

  /// Get the stream URL to use for playback
  /// For YouTube tracks, this returns the resolved stream URL from InnerTube
  String get playableUrl => streamUrl ?? url;

  /// Create a Track from a YouTube InnerTube result
  factory Track.fromYouTubeTrack(YouTubeTrack ytTrack) {
    // Generate a unique ID for YouTube tracks (prefix with 'yt_' to avoid conflicts)
    final id = 'yt_${ytTrack.videoId}';
    
    // Build thumbnail URL with higher resolution
    String? coverArt = ytTrack.thumbnailUrl;
    if (coverArt != null) {
      // Try to get higher quality thumbnail
      coverArt = coverArt
          .replaceAll('w60-h60', 'w300-h300')
          .replaceAll('w120-h120', 'w300-h300')
          .replaceAll('w226-h226', 'w300-h300');
    }

    return Track(
      id: id,
      title: ytTrack.title,
      artist: ytTrack.artist ?? 'Unknown Artist',
      url: '',  // Will be resolved via InnerTube player endpoint
      coverArt: coverArt,
      language: 'youtube',
      source: TrackSource.youtube,
      youtubeVideoId: ytTrack.videoId,
      duration: ytTrack.duration,
      isExplicit: ytTrack.isExplicit,
      categories: ytTrack.categories,
    );
  }

  factory Track.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String lang = 'others';
    if (data['language'] != null) {
      lang = (data['language'] as String).toLowerCase();
    } else if (data['isMalayalam'] == true) {
      lang = 'malayalam';
    }
    return Track(
      id: doc.id,
      title: data['title'] ?? 'Unknown Title',
      artist: data['artist'] ?? 'Unknown Artist',
      url: data['url'] ?? '',
      coverArt: data['coverArt'],
      language: lang,
      streamCount: (data['streamCount'] ?? 0) as int,
      likeCount: (data['likeCount'] ?? 0) as int,
      downloadCount: (data['downloadCount'] ?? 0) as int,
      lyrics: data['lyrics'],
      lyricsProvider: data['lyricsProvider'],
      lyricsProviderUrl: data['lyricsProviderUrl'],
      lyricsRedirectUrl: data['lyricsRedirectUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      source: TrackSource.firestore,
    );
  }

  factory Track.fromMap(Map<String, dynamic> data) {
    return Track(
      id: data['id'] as String,
      title: data['title'] ?? 'Unknown Title',
      artist: data['artist'] ?? 'Unknown Artist',
      url: data['url'] ?? '',
      coverArt: data['coverArt'],
      language: data['language'] ?? 'others',
      streamCount: (data['streamCount'] ?? 0) as int,
      likeCount: (data['likeCount'] ?? 0) as int,
      downloadCount: (data['downloadCount'] ?? 0) as int,
      lyrics: data['lyrics'],
      lyricsProvider: data['lyricsProvider'],
      lyricsProviderUrl: data['lyricsProviderUrl'],
      lyricsRedirectUrl: data['lyricsRedirectUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'url': url,
        'coverArt': coverArt ?? '',
        'language': language,
        'streamCount': streamCount,
        'likeCount': likeCount,
        'downloadCount': downloadCount,
        'lyrics': lyrics,
        'lyricsProvider': lyricsProvider,
        'lyricsProviderUrl': lyricsProviderUrl,
        'lyricsRedirectUrl': lyricsRedirectUrl,
      };

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
