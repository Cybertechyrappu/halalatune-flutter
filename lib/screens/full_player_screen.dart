import 'dart:ui';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
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
  // Page controller for artwork swipe
  late final PageController _pageCtrl;
  late final AnimationController _artCtrl;
  late final Animation<double> _artScale;

  // Swipe down to dismiss
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

  void _showLyricsSheet(BuildContext context, [String title = 'Lyrics']) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF666666), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontFamily: 'Roboto', fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  Text('$title are currently unavailable for this track.\n\n\n\n\n\n(Feature coming soon)',
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, height: 2.0, color: Color(0xFFAAAAAA)),
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          ]),
        ),
      ),
    );
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
                  _Header(track: track),
                  // artwork
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
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
                  // Track info + like row
                  _TrackInfoRow(track: track, player: player),
                  const SizedBox(height: 24),
                  // Progress bar
                  _ProgressBar(player: player),
                  const SizedBox(height: 16),
                  // Main controls (prev, play, next, shuffle, repeat)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.shuffle_rounded, color: player.isShuffle ? Colors.white : const Color(0xFF666666), size: 24),
                          onPressed: player.toggleShuffle,
                          splashRadius: 24,
                        ),
                        _Controls(player: player),
                        IconButton(
                          icon: Icon(
                            player.repeatMode == RepeatMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: player.repeatMode != RepeatMode.none ? Colors.white : const Color(0xFF666666),
                            size: 24,
                          ),
                          onPressed: player.toggleRepeat,
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Download button
                  _SecondaryControls(track: track, player: player),
                  const Spacer(),
                  // Bottom segmented sliding panel triggers
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Row(
                          children: [
                            Expanded(child: GestureDetector(
                              onTap: () => _showLyricsSheet(context, 'Up Next'),
                              child: Container(color: Colors.transparent, alignment: Alignment.center, child: const Text('UP NEXT', style: TextStyle(fontFamily: 'Roboto', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600))),
                            )),
                            Expanded(child: GestureDetector(
                              onTap: () => _showLyricsSheet(context, 'Lyrics'),
                              child: Container(color: Colors.transparent, alignment: Alignment.center, child: const Text('LYRICS', style: TextStyle(fontFamily: 'Roboto', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600))),
                            )),
                            Expanded(child: GestureDetector(
                              onTap: () => _showLyricsSheet(context, 'Related'),
                              child: Container(color: Colors.transparent, alignment: Alignment.center, child: const Text('RELATED', style: TextStyle(fontFamily: 'Roboto', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600))),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ── Header ──────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Track track;
  const _Header({required this.track});

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(width: 48), // Balancing space from missing dots
        ]
      ),
    );
  }
}

// ── Artwork Carousel ─────────────────────────────────────────────────────────────
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

// ── Track Info + Like ────────────────────────────────────────────────────────────
class _TrackInfoRow extends StatelessWidget {
  final Track track;
  final PlayerProvider player;
  const _TrackInfoRow({required this.track, required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(track.title, style: const TextStyle(
                fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w800,
                color: Colors.white,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(track.artist, style: const TextStyle(
                fontFamily: 'Roboto', fontSize: 16, color: Color(0xFFAAAAAA),
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Consumer<LibraryProvider>(builder: (_, lib, __) {
            final liked = lib.isLiked(track.id);
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_down_alt_outlined, color: Colors.white, size: 28),
                  onPressed: () {},
                  splashRadius: 24,
                ),
                IconButton(
                  icon: Icon(
                    liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => lib.toggleLike(track.id),
                  splashRadius: 24,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Progress Bar ─────────────────────────────────────────────────────────────────
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
          child: Slider(
            value: player.progress.clamp(0.0, 1.0),
            onChanged: player.seekTo,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_fmt(player.position), style: const TextStyle(
              fontFamily: 'Roboto', fontSize: 12, color: Color(0xFFAAAAAA),
            )),
            Text(_fmt(player.duration), style: const TextStyle(
              fontFamily: 'Roboto', fontSize: 12, color: Color(0xFFAAAAAA),
            )),
          ]),
        ),
      ]),
    );
  }
}

// ── Main Controls ────────────────────────────────────────────────────────────────
class _Controls extends StatelessWidget {
  final PlayerProvider player;
  const _Controls({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 48),
        onPressed: player.playPrev,
        splashRadius: 32,
      ),
      const SizedBox(width: 16),
      // Play / Pause big button
      GestureDetector(
        onTap: player.togglePlayPause,
        child: Container(
          width: 76, height: 76,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: player.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(22),
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                )
              : Icon(
                  player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black, size: 48,
                ),
        ),
      ),
      const SizedBox(width: 16),
      IconButton(
        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 48),
        onPressed: player.playNext,
        splashRadius: 32,
      ),
    ]);
  }
}

// ── Secondary Controls ───────────────────────────────────────────────────────────
class _SecondaryControls extends StatelessWidget {
  final Track track;
  final PlayerProvider player;
  const _SecondaryControls({required this.track, required this.player});

  @override
  Widget build(BuildContext context) {
    final dl = context.watch<DownloadService>();
    final status = dl.statusOf(track.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Download Glass Pill
        _GlassPillBtn(
          icon: status == DownloadStatus.downloaded ? Icons.check_circle_rounded
               : status == DownloadStatus.error ? Icons.error_outline_rounded : Icons.download_rounded,
          label: status == DownloadStatus.downloading ? 'Downloading' : 'Download',
          color: status == DownloadStatus.error ? Colors.red : Colors.white,
          onTap: () {
            if (status == DownloadStatus.downloaded) {
              dl.deleteDownload(track.id);
            } else if (status != DownloadStatus.downloading) {
              dl.download(track);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading "${track.title}"…', style: const TextStyle(fontFamily: 'Roboto'))));
            } else {
              dl.cancel(track.id);
            }
          },
          child: status == DownloadStatus.downloading
             ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(value: dl.progressOf(track.id), strokeWidth: 2, color: Colors.white))
             : null,
        ),
        const SizedBox(width: 16),
        // Share Glass Pill
        _GlassPillBtn(
          icon: Icons.share_rounded,
          label: 'Share',
          color: Colors.white,
          onTap: () {},
        ),
      ]),
    );
  }
}

class _GlassPillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Widget? child;
  const _GlassPillBtn({required this.icon, required this.label, required this.color, required this.onTap, this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                child ?? Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── EOF ────────────────────────────────────────────────────────────────────────
