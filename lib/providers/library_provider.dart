import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/track.dart';
import '../services/firestore_service.dart';

class LibraryProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();

  List<Track> _allTracks = [];
  Set<String> _likedIds = {};
  List<String> _historyIds = [];
  bool _tracksLoaded = false;

  StreamSubscription<List<Track>>? _tracksSub;
  StreamSubscription<Set<String>>? _likesSub;

  List<Track> get allTracks => _allTracks;
  Set<String> get likedIds => _likedIds;
  List<String> get historyIds => _historyIds;
  bool get tracksLoaded => _tracksLoaded;

  List<Track> get likedTracks =>
      _allTracks.where((t) => _likedIds.contains(t.id)).toList();

  List<Track> get recentTracks {
    final ids = _historyIds.take(8).toList();
    return ids
        .map((id) => _allTracks.firstWhere((t) => t.id == id, orElse: () => Track(id: '', title: '', artist: '', url: '', language: '')))
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  List<Track> get historyTracks {
    return _historyIds
        .map((id) => _allTracks.firstWhere((t) => t.id == id, orElse: () => Track(id: '', title: '', artist: '', url: '', language: '')))
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  List<Track> getByLanguage(String lang) =>
      _allTracks.where((t) => t.language == lang).toList();

  bool isLiked(String trackId) => _likedIds.contains(trackId);

  void init(String uid) {
    // Start tracks listener
    _tracksSub = _db.tracksStream().listen((tracks) {
      _allTracks = tracks;
      _tracksLoaded = true;
      notifyListeners();
    });

    // Start likes listener
    _likesSub = _db.likedIdsStream(uid).listen((liked) {
      _likedIds = liked;
      notifyListeners();
    });

    // Load history once
    _db.loadHistory(uid).then((ids) {
      _historyIds = ids;
      notifyListeners();
    });
  }

  void clear() {
    _tracksSub?.cancel();
    _likesSub?.cancel();
    _allTracks = [];
    _likedIds = {};
    _historyIds = [];
    _tracksLoaded = false;
    notifyListeners();
  }

  Future<void> toggleLike(String trackId) async {
    final wasLiked = _likedIds.contains(trackId);
    // Optimistic update
    if (wasLiked) {
      _likedIds.remove(trackId);
    } else {
      _likedIds.add(trackId);
    }
    notifyListeners();
    try {
      await _db.toggleLike(trackId, wasLiked);
    } catch (_) {
      // Rollback
      if (wasLiked) {
        _likedIds.add(trackId);
      } else {
        _likedIds.remove(trackId);
      }
      notifyListeners();
    }
  }

  void addToHistory(String uid, String trackId) {
    _historyIds.removeWhere((id) => id == trackId);
    _historyIds.insert(0, trackId);
    if (_historyIds.length > 50) {
      _historyIds = _historyIds.sublist(0, 50);
    }
    notifyListeners();
    _db.addToHistory(uid, trackId).catchError((_) {});
  }

  Future<void> clearHistory(String uid) async {
    _historyIds = [];
    notifyListeners();
    await _db.clearHistory(uid);
  }

  List<Track> searchTracks(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return _allTracks.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.artist.toLowerCase().contains(q) ||
        t.language.toLowerCase().contains(q)).toList();
  }

  List<Track> getSpeedDial() {
    var pool = _allTracks.where((t) => t.coverArt != null).toList();
    if (pool.length < 3) pool = [..._allTracks];
    if (pool.isEmpty) return [];
    final maxStreams = pool.map((t) => t.streamCount).fold(0, (a, b) => a > b ? a : b);
    pool.sort((a, b) {
      final scoreA = 0.6 + (maxStreams > 0 ? a.streamCount / maxStreams * 0.4 : 0);
      final scoreB = 0.6 + (maxStreams > 0 ? b.streamCount / maxStreams * 0.4 : 0);
      return scoreB.compareTo(scoreA);
    });
    pool.shuffle();
    return pool.take(9).toList();
  }

  @override
  void dispose() {
    _tracksSub?.cancel();
    _likesSub?.cancel();
    super.dispose();
  }
}
