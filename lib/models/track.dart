import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

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
