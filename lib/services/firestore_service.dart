import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/track.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Tracks ──────────────────────────────────────────────────────
  Stream<List<Track>> tracksStream() {
    return _db
        .collection('songs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Track.fromFirestore(d)).toList());
  }

  // ── Likes ────────────────────────────────────────────────────────
  Stream<Set<String>> likedIdsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('likes')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Future<void> toggleLike(String trackId, bool isCurrentlyLiked) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final likeRef = _db.collection('users').doc(user.uid).collection('likes').doc(trackId);
    final songRef = _db.collection('songs').doc(trackId);

    if (isCurrentlyLiked) {
      await likeRef.delete();
      await songRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'addedAt': FieldValue.serverTimestamp()});
      await songRef.update({'likeCount': FieldValue.increment(1)});
    }
  }

  // ── History ──────────────────────────────────────────────────────
  Future<List<String>> loadHistory(String uid, {int limit = 50}) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('history')
          .orderBy('playedAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => d.data()['trackId'] as String? ?? d.id).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addToHistory(String uid, String trackId) async {
    _db
        .collection('users')
        .doc(uid)
        .collection('history')
        .doc(trackId)
        .set({
          'trackId': trackId,
          'playedAt': FieldValue.serverTimestamp(),
        })
        .catchError((_) {});
  }

  Future<void> clearHistory(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('history')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Stream count ─────────────────────────────────────────────────
  Future<void> incrementStream(String trackId, String userId) async {
    await _db.collection('songs').doc(trackId).update({
      'streamCount': FieldValue.increment(1),
      'listeners': FieldValue.arrayUnion([userId]),
    });
  }

  // ── User record ──────────────────────────────────────────────────
  Future<void> updateLastLogin(String uid) async {
    _db
        .collection('users')
        .doc(uid)
        .set({'lastLogin': FieldValue.serverTimestamp()}, SetOptions(merge: true))
        .catchError((_) {});
  }

  // ── Playlists ────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> loadUserPlaylists(String uid) async {
    try {
      final snap = await _db
          .collection('playlists')
          .where('ownerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadPublicPlaylists(String? uid) async {
    try {
      final snap = await _db
          .collection('playlists')
          .where('visibility', isEqualTo: 'public')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .where((p) => uid == null || p['ownerId'] != uid)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> createPlaylist({
    required String name,
    required String description,
    required String visibility,
    required String ownerId,
    required String ownerName,
  }) async {
    try {
      final ref = await _db.collection('playlists').add({
        'name': name,
        'description': description,
        'visibility': visibility,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'tracks': [],
        'trackCount': 0,
        'coverArt': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  Future<bool> addTrackToPlaylist(String playlistId, String trackId, String? coverArt) async {
    try {
      final doc = await _db.collection('playlists').doc(playlistId).get();
      final data = doc.data() as Map<String, dynamic>;
      final List<String> tracks = List<String>.from(data['tracks'] ?? []);
      if (tracks.contains(trackId)) return false;
      tracks.add(trackId);
      final existingCover = data['coverArt'] ?? '';
      await _db.collection('playlists').doc(playlistId).update({
        'tracks': tracks,
        'trackCount': tracks.length,
        'coverArt': existingCover.isEmpty ? (coverArt ?? '') : existingCover,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _db.collection('playlists').doc(playlistId).delete();
  }

  Future<void> incrementDownload(String trackId) async {
    _db
        .collection('songs')
        .doc(trackId)
        .update({'downloadCount': FieldValue.increment(1)})
        .catchError((_) {});
  }
}
