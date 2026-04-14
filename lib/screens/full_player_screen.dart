import 'package:flutter/material.dart' hide RepeatMode;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/download_service.dart';
import '../models/track.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen>
    with TickerProviderStateMixin {
  late final PageController _pageCtrl;
  late final AnimationController _artCtrl;
  late final Animation<double> _artScale;

  double _dragY = 0;
  static const double _kDismissThreshold = 150;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _artCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _artScale = Tween<double>(begin: 0.90, end: 1.0)
        .animate(CurvedAnimation(parent: _artCtrl, curve: Curves.easeOutCubic));
    _artCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _artCtrl.dispose();
    super.dispose();
  }

  // ── Lyrics Sheet ─────────────────────────────────────────────────────────────
  void _showLyricsSheet(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LyricsSheet(track: track),
    );
  }

  // ── Up Next Sheet ─────────────────────────────────────────────────────────────
  void _showUpNextSheet(BuildContext context, PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => _QueueSheet(
          player: player,
          scrollCtrl: scrollCtrl,
          title: 'Up Next',
          tracks: _getUpNext(player),
          onTap: (i) {
            final globalIdx = player.currentIndex + 1 + i;
            if (globalIdx < player.queue.length) {
              player.playTrack(newQueue: List.from(player.queue), index: globalIdx);
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  List<Track> _getUpNext(PlayerProvider player) {
    final next = player.currentIndex + 1;
    if (next >= player.queue.length) return [];
    return player.queue.sublist(next, (next + 20).clamp(0, player.queue.length));
  }

  // ── Related Sheet ─────────────────────────────────────────────────────────────
  void _showRelatedSheet(BuildContext context, Track track) {
    final lib = context.read<LibraryProvider>();
    final player = context.read<PlayerProvider>();

    // Same artist first, else random songs
    var related = lib.allTracks.where((t) => t.artist == track.artist && t.id != track.id).toList();
    if (related.isEmpty) {
      related = List.from(lib.allTracks)..shuffle();
      related.removeWhere((t) => t.id == track.id);
      related = related.take(10).toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => _QueueSheet(
          player: player,
          scrollCtrl: scrollCtrl,
          title: 'More Like This',
          tracks: related,
          onTap: (i) {
            final allTracks = lib.allTracks;
            final idx = allTracks.indexWhere((t) => t.id == related[i].id);
            if (idx != -1) {
              player.playTrack(newQueue: List.from(allTracks), index: idx);
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // ── Share ─────────────────────────────────────────────────────────────────────
  void _share(Track track) {
    final text = '🎵 Listen to "${track.title}" by ${track.artist} on HalalTune!\nhttps://halaltune.vercel.app';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Consumer<PlayerProvider>(builder: (ctx, player, _) {
      final track = player.currentTrack;
      if (track == null) return const SizedBox();

      final opacity = (1 - (_dragY / _kDismissThreshold * 0.4)).clamp(0.0, 1.0);
      final dy = _dragY * 0.55;

      return GestureDetector(
        onVerticalDragUpdate: (d) {
          if (d.delta.dy > 0) setState(() => _dragY += d.delta.dy);
        },
        onVerticalDragEnd: (d) {
          if (_dragY > _kDismissThreshold || d.velocity.pixelsPerSecond.dy > 900) {
            Navigator.pop(context);
          } else {
            setState(() => _dragY = 0);
          }
        },
        child: Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(
            opacity: opacity,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Column(children: [
                  _buildHeader(context),
                  // Artwork
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: SizedBox(
                      height: size.height * 0.38,
                      child: _ArtworkCarousel(
                        track: track,
                        player: player,
                        ctrl: _pageCtrl,
                        artScale: _artScale,
                      ),
                    ),
                  ),
                  // Track info + like/dislike
                  _buildTrackInfo(track),
                  const SizedBox(height: 20),
                  // Progress bar
                  _ProgressBar(player: player),
                  const SizedBox(height: 12),
                  // Shuffle | prev | play | next | repeat
                  _buildControls(player),
                  const SizedBox(height: 12),
                  // Download + Share pills
                  _buildActionPills(context, track),
                  const Spacer(),
                  // UP NEXT / LYRICS / RELATED tab bar
                  _buildBottomTabBar(context, player, track),
                ]),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            splashRadius: 24,
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTrackInfo(Track track) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(track.title, style: const TextStyle(
                fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(track.artist, style: const TextStyle(
                fontFamily: 'Roboto', fontSize: 15, color: Color(0xFFAAAAAA),
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Consumer<LibraryProvider>(builder: (_, lib, __) {
            final liked = lib.isLiked(track.id);
            return Row(children: [
              IconButton(
                icon: const Icon(Icons.thumb_down_alt_outlined, color: Colors.white, size: 26),
                onPressed: () {},
                splashRadius: 22,
              ),
              IconButton(
                icon: Icon(
                  liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                  color: Colors.white, size: 26,
                ),
                onPressed: () => lib.toggleLike(track.id),
                splashRadius: 22,
              ),
            ]);
          }),
        ],
      ),
    );
  }

  Widget _buildControls(PlayerProvider player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.shuffle_rounded,
              color: player.isShuffle ? Colors.white : const Color(0xFF666666), size: 24),
            onPressed: player.toggleShuffle,
            splashRadius: 24,
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 44),
            onPressed: player.playPrev,
            splashRadius: 28,
          ),
          GestureDetector(
            onTap: player.togglePlayPause,
            child: Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: player.isLoading
                  ? const Padding(padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                  : Icon(player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.black, size: 44),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 44),
            onPressed: player.playNext,
            splashRadius: 28,
          ),
          IconButton(
            icon: Icon(
              player.repeatMode == RepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              color: player.repeatMode != RepeatMode.none ? Colors.white : const Color(0xFF666666),
              size: 24,
            ),
            onPressed: player.toggleRepeat,
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildActionPills(BuildContext context, Track track) {
    final dl = context.watch<DownloadService>();
    final status = dl.statusOf(track.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Download opaque pill
        _OpaquePillBtn(
          icon: status == DownloadStatus.downloaded ? Icons.check_circle_rounded
              : status == DownloadStatus.error ? Icons.error_outline_rounded
              : Icons.download_rounded,
          label: status == DownloadStatus.downloaded ? 'Downloaded'
              : status == DownloadStatus.downloading ? 'Downloading…'
              : 'Download',
          color: status == DownloadStatus.error ? Colors.red : Colors.white,
          onTap: () {
            if (status == DownloadStatus.downloaded) {
              dl.deleteDownload(track.id);
            } else if (status != DownloadStatus.downloading) {
              dl.download(track);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading "${track.title}"…',
                  style: const TextStyle(fontFamily: 'Roboto'))));
            } else {
              dl.cancel(track.id);
            }
          },
          child: status == DownloadStatus.downloading
              ? SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(value: dl.progressOf(track.id), strokeWidth: 2, color: Colors.white))
              : null,
        ),
        const SizedBox(width: 12),
        // Share opaque pill
        _OpaquePillBtn(
          icon: Icons.share_rounded,
          label: 'Share',
          color: Colors.white,
          onTap: () => _share(track),
        ),
      ]),
    );
  }

  Widget _buildBottomTabBar(BuildContext context, PlayerProvider player, Track track) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(children: [
        Expanded(child: _TabBtn(
          label: 'UP NEXT',
          onTap: () => _showUpNextSheet(context, player),
        )),
        Container(width: 1, height: 20, color: Colors.white12),
        Expanded(child: _TabBtn(
          label: 'LYRICS',
          onTap: () => _showLyricsSheet(context, track),
        )),
        Container(width: 1, height: 20, color: Colors.white12),
        Expanded(child: _TabBtn(
          label: 'RELATED',
          onTap: () => _showRelatedSheet(context, track),
        )),
      ]),
    );
  }
}

// ── Tab Button ────────────────────────────────────────────────────────────────
class _TabBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: Center(
          child: Text(label, style: const TextStyle(
            fontFamily: 'Roboto', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.8,
          )),
        ),
      ),
    );
  }
}

// ── Opaque Pill Button ────────────────────────────────────────────────────────
class _OpaquePillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Widget? child;
  const _OpaquePillBtn({required this.icon, required this.label, required this.color, required this.onTap, this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          child ?? Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── Artwork Carousel ─────────────────────────────────────────────────────────
class _ArtworkCarousel extends StatelessWidget {
  final Track track;
  final PlayerProvider player;
  final PageController ctrl;
  final Animation<double> artScale;
  const _ArtworkCarousel({required this.track, required this.player, required this.ctrl, required this.artScale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ScaleTransition(
        scale: artScale,
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (track.coverArt != null && track.coverArt!.startsWith('http'))
                ? CachedNetworkImage(
                    imageUrl: track.coverArt!,
                    fit: BoxFit.cover,
                    memCacheWidth: 900,
                    placeholder: (_, __) => Container(color: const Color(0xFF1E1E1E)),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF1E1E1E),
    child: const Icon(Icons.music_note_rounded, color: Color(0xFF666666), size: 60),
  );
}

// ── Progress Bar ─────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final PlayerProvider player;
  const _ProgressBar({required this.player});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        SliderTheme(
          data: SliderThemeData(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackHeight: 2,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.1),
          ),
          child: Slider(value: player.progress.clamp(0.0, 1.0), onChanged: player.seekTo),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_fmt(player.position), style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFFAAAAAA))),
            Text(_fmt(player.duration), style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFFAAAAAA))),
          ]),
        ),
      ]),
    );
  }
}

// ── Queue Sheet (Up Next / Related) ──────────────────────────────────────────
class _QueueSheet extends StatelessWidget {
  final PlayerProvider player;
  final ScrollController scrollCtrl;
  final String title;
  final List<Track> tracks;
  final void Function(int index) onTap;
  const _QueueSheet({required this.player, required this.scrollCtrl, required this.title, required this.tracks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF666666), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontFamily: 'Roboto', fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: tracks.isEmpty
              ? const Center(child: Text('Nothing here.', style: TextStyle(color: Color(0xFFAAAAAA), fontFamily: 'Roboto')))
              : ListView.builder(
                  controller: scrollCtrl,
                  itemCount: tracks.length,
                  itemBuilder: (_, i) {
                    final t = tracks[i];
                    final isPlaying = player.currentTrack?.id == t.id;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: (t.coverArt != null && t.coverArt!.startsWith('http'))
                            ? CachedNetworkImage(imageUrl: t.coverArt!, width: 48, height: 48, fit: BoxFit.cover)
                            : Container(width: 48, height: 48, color: const Color(0xFF1E1E1E),
                                child: const Icon(Icons.music_note_rounded, color: Color(0xFF666666))),
                      ),
                      title: Text(t.title, style: TextStyle(
                        fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w600,
                        color: isPlaying ? Colors.white : Colors.white,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(t.artist, style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFFAAAAAA)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: isPlaying
                          ? const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20)
                          : null,
                      onTap: () => onTap(i),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ── Lyrics Sheet ─────────────────────────────────────────────────────────────
class _LyricsSheet extends StatelessWidget {
  final Track track;
  const _LyricsSheet({required this.track});

  bool get _isMalayalam => track.language.toLowerCase() == 'malayalam';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF666666), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Lyrics', style: TextStyle(fontFamily: 'Roboto', fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                if (_isMalayalam) _buildThirunabiChip() else _buildLyricsContent(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildThirunabiChip() {
    final hasUrl = track.lyricsRedirectUrl != null && track.lyricsRedirectUrl!.isNotEmpty;
    return Builder(builder: (ctx) => GestureDetector(
      onTap: hasUrl
          ? () async {
              final url = Uri.parse(track.lyricsRedirectUrl!);
              if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Thirunabi Madh', style: TextStyle(
                fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                hasUrl ? 'Tap to open lyrics in Thirunabi Madh' : 'Lyrics available on Thirunabi Madh app',
                style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, color: Color(0xFFAAAAAA)),
              ),
            ])),
            if (hasUrl)
              const Icon(Icons.open_in_new_rounded, color: Color(0xFFAAAAAA), size: 18),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFAAAAAA), size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Malayalam lyrics are provided by our partner app',
                style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFFAAAAAA)))),
            ]),
          ),
        ]),
      ),
    ));
  }

  Widget _buildLyricsContent() {
    if (track.lyrics != null && track.lyrics!.trim().isNotEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (track.lyricsProvider != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.music_note_rounded, color: Color(0xFFAAAAAA), size: 14),
              const SizedBox(width: 6),
              Text('Lyrics by ${track.lyricsProvider!}',
                style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFFAAAAAA))),
            ]),
          ),
        ],
        Text(track.lyrics!,
          style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, height: 1.8, color: Colors.white)),
      ]);
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 60),
        child: Text('Lyrics not available for this track.',
          style: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: Color(0xFFAAAAAA)),
          textAlign: TextAlign.center),
      ),
    );
  }
}
