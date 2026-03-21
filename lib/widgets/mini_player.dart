import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
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

      final width = MediaQuery.of(context).size.width * 0.92;
      final maxWidth = width > 400.0 ? 400.0 : width;

      return Align(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => openFullPlayer(context),
          onVerticalDragEnd: (d) {
            if (d.primaryVelocity != null && d.primaryVelocity! < -250) {
              openFullPlayer(context);
            }
          },
          child: Container(
            width: maxWidth,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xD9282828), // rgba(40,40,40,0.85)
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Stack(
              children: [
                // Inner Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      // Artwork
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: (track.coverArt != null && track.coverArt!.startsWith('http'))
                            ? CachedNetworkImage(imageUrl: track.coverArt!, width: 44, height: 44, memCacheWidth: 132, fit: BoxFit.cover)
                            : Container(width: 44, height: 44, color: const Color(0xFF1E1E1E),
                                child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 20)),
                      ),
                      const SizedBox(width: 12),
                      
                      // Title + Artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(track.title, 
                              style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(track.artist, 
                              style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, color: Color(0xFFAAAAAA)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      
                      // Play/Pause
                      IconButton(
                        icon: player.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5))
                            : Icon(player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
                        onPressed: player.togglePlayPause,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      
                      // Next
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 26),
                        onPressed: player.playNext,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ],
                  ),
                ),
                
                // Progress Strip at absolute bottom inside the card
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    child: LayoutBuilder(
                      builder: (_, c) => Stack(
                        children: [
                          Container(height: 2, color: Colors.white.withValues(alpha: 0.1)),
                          Container(
                            height: 2,
                            width: c.maxWidth * player.progress.clamp(0.0, 1.0),
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
