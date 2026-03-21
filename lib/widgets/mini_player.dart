import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../services/download_service.dart';
import '../screens/full_player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  static void openFullPlayer(BuildContext context) {
    final dl = context.read<DownloadService>();
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => ChangeNotifierProvider<DownloadService>.value(
        value: dl,
        child: const FullPlayerScreen(),
      ),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 320),
      fullscreenDialog: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(builder: (_, player, __) {
      final track = player.currentTrack;
      if (track == null) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => openFullPlayer(context),
        onVerticalDragEnd: (d) {
          if (d.primaryVelocity != null && d.primaryVelocity! < -250) {
            openFullPlayer(context);
          }
        },
        child: Container(
          height: 64,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          decoration: BoxDecoration(
            color: AppTheme.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.surfaceHigh, width: 0.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // progress strip
            LayoutBuilder(builder: (_, c) => Stack(children: [
              Container(height: 2, color: AppTheme.surfaceHigh),
              Container(
                height: 2,
                width: c.maxWidth * player.progress.clamp(0.0, 1.0),
                color: AppTheme.accent,
              ),
            ])),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(children: [
                  // artwork
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (track.coverArt != null && track.coverArt!.startsWith('http'))
                        ? CachedNetworkImage(imageUrl: track.coverArt!, width: 40, height: 40, memCacheWidth: 120, fit: BoxFit.cover)
                        : Container(width: 40, height: 40, color: AppTheme.bgCard,
                            child: const Icon(Icons.music_note_rounded, color: AppTheme.textDim, size: 18)),
                  ),
                  const SizedBox(width: 10),
                  // title + artist
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(track.title, style: const TextStyle(
                        fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(track.artist, style: const TextStyle(
                        fontFamily: 'Outfit', fontSize: 11, color: AppTheme.textSecondary,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  // prev
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.textSecondary, size: 22),
                    onPressed: player.playPrev,
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  // play/pause
                  IconButton(
                    icon: player.isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 1.5))
                        : Icon(
                            player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: AppTheme.textPrimary, size: 26),
                    onPressed: player.togglePlayPause,
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  // next
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: AppTheme.textSecondary, size: 22),
                    onPressed: player.playNext,
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
    });
  }
}
