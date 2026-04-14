import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import '../models/track.dart';
import '../services/firestore_service.dart';
import '../services/innertube/innertube_service.dart';
import '../main.dart' show HalalTuneAudioHandler;

enum RepeatMode { none, one, all }

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final FirestoreService _db = FirestoreService();
  final HalalTuneAudioHandler _handler;
  final InnerTubeService _innertube = InnerTubeService();

  List<Track> _queue = [];
  int _currentIndex = -1;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _currentUserId;
  Timer? _streamTimer;

  // Getters
  List<Track> get queue => _queue;
  int get currentIndex => _currentIndex;
  Track? get currentTrack =>
      _currentIndex >= 0 && _currentIndex < _queue.length ? _queue[_currentIndex] : null;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;
  bool get isPlaying => _player.playing;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress =>
      _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;

  PlayerProvider({required HalalTuneAudioHandler audioHandler}) : _handler = audioHandler {
    // Register self with the handler so media button events reach us
    _handler.registerPlayer(this);
    _initAudioSession();

    _player.playerStateStream.listen(_onPlayerState);
    _player.positionStream.listen((pos) {
      _position = pos;
      // Do not pushPlaybackState here! AudioService creates its own interpolated position.
      // Spamming it here will break Android lock screen seekbars.
      notifyListeners();
    });
    _player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _onTrackEnded();
    });
  }

  void setUserId(String? uid) => _currentUserId = uid;

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (_player.playing) _player.pause();
      }
    });
  }

  void _onPlayerState(PlayerState state) {
    _isLoading = state.processingState == ProcessingState.loading ||
        state.processingState == ProcessingState.buffering;
    _pushPlaybackState();
    notifyListeners();
  }

  void _onTrackEnded() {
    switch (_repeatMode) {
      case RepeatMode.one:
        _player.seek(Duration.zero);
        _player.play();
      case RepeatMode.all:
      case RepeatMode.none:
        playNext();
    }
  }

  /// Push current state to the notification / lock screen
  void _pushPlaybackState() {
    _handler.pushPlaybackState(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.skipToPrevious,
        MediaAction.skipToNext,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _isLoading
          ? AudioProcessingState.loading
          : AudioProcessingState.ready,
      playing: _player.playing,
      updatePosition: _position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  void _pushMediaItem() {
    final track = currentTrack;
    if (track == null) return;
    _handler.pushMediaItem(MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      artUri: (track.coverArt != null && track.coverArt!.startsWith('http'))
          ? Uri.parse(track.coverArt!)
          : null,
      duration: _duration,
    ));
  }

  // ── Playback control ──────────────────────────────────────────────────────

  Future<void> playTrack({required List<Track> newQueue, required int index}) async {
    _queue = List.from(newQueue);
    _currentIndex = index;
    await _loadAndPlay();
    notifyListeners();
  }

  Future<void> _loadAndPlay() async {
    final track = currentTrack;
    if (track == null) return;

    _isLoading = true;
    notifyListeners();
    _pushMediaItem();

    try {
      // For YouTube tracks, resolve stream URL if not already resolved
      String playUrl = track.playableUrl;
      if (track.source == TrackSource.youtube && 
          track.youtubeVideoId != null && 
          (playUrl.isEmpty || track.streamUrl == null)) {
        
        debugPrint('Resolving YouTube stream URL for: ${track.title}');
        final audioUrl = await _innertube.getAudioUrl(track.youtubeVideoId!);
        
        if (audioUrl != null) {
          track.streamUrl = audioUrl;
          playUrl = audioUrl;
        } else {
          debugPrint('Failed to resolve YouTube stream URL');
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      await _player.setUrl(playUrl);
      await _player.play();
      _pushMediaItem(); // re-push with duration once known
    } catch (e) {
      debugPrint('PlayerProvider: error loading: $e');
    }
    _isLoading = false;
    notifyListeners();

    // Firestore stream count after 10 s (only for firestore tracks)
    if (track.source == TrackSource.firestore) {
      _streamTimer?.cancel();
      final tid = track.id;
      _streamTimer = Timer(const Duration(seconds: 10), () {
        if (currentTrack?.id == tid && _currentUserId != null) {
          _db.incrementStream(tid, _currentUserId!).catchError((_) {});
        }
      });
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (currentTrack != null) await _player.play();
    }
    notifyListeners();
  }

  /// Called by the AudioHandler (media button / notification)
  Future<void> externalPlay() async {
    if (currentTrack != null && !_player.playing) {
      await _player.play();
      notifyListeners();
    }
  }

  Future<void> externalPause() async {
    if (_player.playing) {
      await _player.pause();
      notifyListeners();
    }
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    _currentIndex = _isShuffle
        ? _randomIndex()
        : (_currentIndex + 1) % _queue.length;
    await _loadAndPlay();
    notifyListeners();
  }

  Future<void> playPrev() async {
    if (_queue.isEmpty) return;
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    _currentIndex = _isShuffle
        ? _randomIndex()
        : (_currentIndex - 1 + _queue.length) % _queue.length;
    await _loadAndPlay();
    notifyListeners();
  }

  int _randomIndex() {
    if (_queue.length <= 1) return 0;
    int idx;
    do { idx = math.Random().nextInt(_queue.length); } while (idx == _currentIndex);
    return idx;
  }

  Future<void> seekTo(double progress) async {
    if (_duration == Duration.zero) return;
    await _player.seek(Duration(milliseconds: (progress * _duration.inMilliseconds).toInt()));
    notifyListeners();
  }

  /// Called by AudioHandler seek
  Future<void> seekToDuration(Duration pos) async {
    await _player.seek(pos);
    notifyListeners();
  }

  void toggleShuffle() { _isShuffle = !_isShuffle; notifyListeners(); }

  void toggleRepeat() {
    _repeatMode = switch (_repeatMode) {
      RepeatMode.none => RepeatMode.all,
      RepeatMode.all  => RepeatMode.one,
      RepeatMode.one  => RepeatMode.none,
    };
    notifyListeners();
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _innertube.dispose();
    _player.dispose();
    super.dispose();
  }
}
