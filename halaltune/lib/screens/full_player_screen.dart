import 'dart:ui';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/download_service.dart';
import '../models/track.dart';
import '../theme/app_theme.dart';

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

  // Tabs: 0=Up Next  1=Lyrics  2=Related
  int _tab = 0;

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
              backgroundColor: AppTheme.bg,
              body: Stack(children: [
                // Blurred album art background
                _BlurredBackground(coverArt: track.coverArt),
                // Main content
                SafeArea(
                  child: Column(children: [
                    _Header(track: track),
                    // artwork (main area, 70% of remaining height)
                    SizedBox(
                      height: size.height * 0.40,
                      child: _ArtworkCarousel(
                        track: track,
                        player: player,
                        ctrl: _pageCtrl,
                        artScale: _artScale,
                      ),
                    ),
                    // Track info + like row
                    _TrackInfoRow(track: track, player: player),
                    const SizedBox(height: 4),
                    // Progress bar
                    _ProgressBar(player: player),
                    const SizedBox(height: 8),
                    // Main controls (prev, play, next)
                    _Controls(player: player),
                    const SizedBox(height: 8),
                    // Secondary controls (shuffle, repeat, download, queue)
                    _SecondaryControls(track: track, player: player),
                    const SizedBox(height: 4),
                    // Bottom tabs (Up Next / Lyrics / Related) — takes remaining space
                    Expanded(
                      child: _BottomTabs(
                        tab: _tab,
                        onTap: (t) => setState(() => _tab = t),
                        player: player,
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
    });
  }
}

// ── Blurred Background ──────────────────────────────────────────────────────────
class _BlurredBackground extends StatelessWidget {
  final String? coverArt;
  const _BlurredBackground({this.coverArt});

  @override
  Widget build(BuildContext context) {
    if (coverArt == null || !coverArt!.startsWith('http')) {
      return Container(color: AppTheme.bg);
    }
    return SizedBox.expand(
      child: Stack(fit: StackFit.expand, children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: CachedNetworkImage(
            imageUrl: coverArt!,
            fit: BoxFit.cover,
            memCacheWidth: 150, // Low res is fine for blur
            errorWidget: (_, __, ___) => Container(color: AppTheme.bg),
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withAlpha(180))),
      ]),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Track track;
  const _Header({required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
          splashRadius: 20,
        ),
        Expanded(
          child: Column(children: [
            const Text('NOW PLAYING', style: TextStyle(
              fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.w600,
              color: AppTheme.textDim, letterSpacing: 2,
            )),
            Text(track.artist, style: const TextStyle(
              fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
          onPressed: () {},
          splashRadius: 20,
        ),
      ]),
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
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: ScaleTransition(
        scale: artScale,
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: (track.coverArt != null && track.coverArt!.startsWith('http'))
                ? CachedNetworkImage(
                    imageUrl: track.coverArt!,
                    fit: BoxFit.cover,
                    memCacheWidth: 900, // High res for main artwork
                    placeholder: (_, __) => Container(color: AppTheme.bgElevated),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppTheme.bgElevated,
    child: const Icon(Icons.music_note_rounded, color: AppTheme.textDim, size: 60),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track.title, style: const TextStyle(
              fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(track.artist, style: const TextStyle(
              fontFamily: 'Outfit', fontSize: 13, color: AppTheme.textSecondary,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        Consumer<LibraryProvider>(builder: (_, lib, __) {
          final liked = lib.isLiked(track.id);
          return IconButton(
            icon: Icon(
              liked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: liked ? AppTheme.liked : AppTheme.textSecondary,
              size: 24,
            ),
            onPressed: () => lib.toggleLike(track.id),
            splashRadius: 20,
          );
        }),
      ]),
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
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            trackHeight: 3,
            activeTrackColor: AppTheme.accent,
            inactiveTrackColor: AppTheme.surfaceHigh,
            thumbColor: AppTheme.accent,
            overlayColor: Colors.white12,
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
              fontFamily: 'Outfit', fontSize: 11, color: AppTheme.textDim,
            )),
            Text(_fmt(player.duration), style: const TextStyle(
              fontFamily: 'Outfit', fontSize: 11, color: AppTheme.textDim,
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
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      IconButton(
        icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.textPrimary, size: 40),
        onPressed: player.playPrev,
        splashRadius: 24,
      ),
      // Play / Pause big button
      GestureDetector(
        onTap: player.togglePlayPause,
        child: Container(
          width: 68, height: 68,
          decoration: const BoxDecoration(
            color: AppTheme.accent,
            shape: BoxShape.circle,
          ),
          child: player.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                )
              : Icon(
                  player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black, size: 36,
                ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.skip_next_rounded, color: AppTheme.textPrimary, size: 40),
        onPressed: player.playNext,
        splashRadius: 24,
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        // Shuffle
        IconButton(
          icon: Icon(Icons.shuffle_rounded,
            color: player.isShuffle ? AppTheme.accent : AppTheme.textDim, size: 20),
          onPressed: player.toggleShuffle,
          splashRadius: 18,
        ),
        // Repeat
        IconButton(
          icon: Icon(
            player.repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: player.repeatMode != RepeatMode.none ? AppTheme.accent : AppTheme.textDim,
            size: 20,
          ),
          onPressed: player.toggleRepeat,
          splashRadius: 18,
        ),
        // Download
        _DownloadButton(track: track, dl: dl, status: status),
        // Share (placeholder)
        IconButton(
          icon: const Icon(Icons.share_rounded, color: AppTheme.textDim, size: 20),
          onPressed: () {},
          splashRadius: 18,
        ),
      ]),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final Track track;
  final DownloadService dl;
  final DownloadStatus status;
  const _DownloadButton({required this.track, required this.dl, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DownloadStatus.notDownloaded:
      case DownloadStatus.error:
        return IconButton(
          icon: Icon(Icons.download_rounded,
            color: status == DownloadStatus.error ? AppTheme.danger : AppTheme.textDim,
            size: 20),
          onPressed: () {
            dl.download(track);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Downloading "${track.title}"…',
                style: const TextStyle(fontFamily: 'Outfit'))),
            );
          },
          splashRadius: 18,
        );
      case DownloadStatus.downloading:
        return SizedBox(
          width: 40, height: 40,
          child: Center(
            child: GestureDetector(
              onTap: () => dl.cancel(track.id),
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    value: dl.progressOf(track.id),
                    strokeWidth: 2,
                    color: AppTheme.accent,
                  ),
                ),
                const Icon(Icons.close_rounded, color: AppTheme.accent, size: 12),
              ]),
            ),
          ),
        );
      case DownloadStatus.downloaded:
        return IconButton(
          icon: const Icon(Icons.download_done_rounded, color: AppTheme.accent, size: 20),
          onPressed: () => dl.deleteDownload(track.id),
          splashRadius: 18,
        );
    }
  }
}

// ── Bottom Tabs (Up Next / Lyrics / Related) ─────────────────────────────────────
class _BottomTabs extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTap;
  final PlayerProvider player;
  const _BottomTabs({required this.tab, required this.onTap, required this.player});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Up next', 'Lyrics', 'Related'];
    return Column(children: [
      SizedBox(
        height: 36,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int i = 0; i < tabs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GestureDetector(
                onTap: () => onTap(i),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(tabs[i], style: TextStyle(
                    fontFamily: 'Outfit', fontSize: 12,
                    fontWeight: i == tab ? FontWeight.w700 : FontWeight.w400,
                    color: i == tab ? AppTheme.accent : AppTheme.textDim,
                  )),
                  const SizedBox(height: 3),
                  // FIX: use only decoration OR color, not both
                  if (i == tab)
                    Container(
                      width: 20, height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ]),
              ),
            ),
        ]),
      ),
      Container(height: 0.5, color: AppTheme.surfaceHigh),
      const SizedBox(height: 4),
      // Tab content — expand to fill remaining space
      Expanded(
        child: tab == 0
            ? _QueueList(player: player)
            : tab == 1
                ? _LyricsPlaceholder()
                : _RelatedPlaceholder(),
      ),
    ]);
  }
}

class _QueueList extends StatelessWidget {
  final PlayerProvider player;
  const _QueueList({required this.player});

  @override
  Widget build(BuildContext context) {
    final queue = player.queue;
    final current = player.currentIndex;
    final upcoming = queue.sublist(current + 1 < queue.length ? current + 1 : queue.length);
    if (upcoming.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: Text('No more tracks in queue',
          style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppTheme.textDim))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      physics: const BouncingScrollPhysics(),
      itemCount: upcoming.length,
      itemBuilder: (_, i) {
        final t = upcoming[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: (t.coverArt != null && t.coverArt!.startsWith('http'))
                  ? CachedNetworkImage(imageUrl: t.coverArt!, width: 36, height: 36, memCacheWidth: 108, fit: BoxFit.cover)
                  : Container(width: 36, height: 36, color: AppTheme.bgElevated,
                      child: const Icon(Icons.music_note_rounded, size: 16, color: AppTheme.textDim)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
                fontWeight: FontWeight.w500, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(t.artist, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
                color: AppTheme.textDim), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        );
      },
    );
  }
}

class _LyricsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(12),
    child: Center(child: Text('Lyrics coming soon',
      style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppTheme.textDim))),
  );
}

class _RelatedPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(12),
    child: Center(child: Text('Related tracks coming soon',
      style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppTheme.textDim))),
  );
}
