import 'package:cloud_firestore/cloud_firestore.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String ownerName;
  final String visibility; // 'public' | 'private'
  final List<String> tracks;
  final int trackCount;
  final String? coverArt;
  final DateTime? createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.ownerName,
    required this.visibility,
    required this.tracks,
    required this.trackCount,
    this.coverArt,
    this.createdAt,
  });

  factory Playlist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Playlist(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Playlist',
      description: data['description'],
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Unknown',
      visibility: data['visibility'] ?? 'public',
      tracks: List<String>.from(data['tracks'] ?? []),
      trackCount: (data['trackCount'] ?? 0) as int,
      coverArt: data['coverArt'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isPrivate => visibility == 'private';
}
