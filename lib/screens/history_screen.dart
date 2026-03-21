import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/track_widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer2<LibraryProvider, PlayerProvider>(builder: (_, lib, player, __) {
      final history = lib.historyTracks;
      return Scaffold(
        appBar: AppBar(title: const Text('Listening History')),
        backgroundColor: cs.surface,
        body: history.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.history_rounded, color: cs.onSurfaceVariant, size: 64),
                const SizedBox(height: 16),
                Text('No listening history yet.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontFamily: 'Outfit', fontSize: 16)),
              ]))
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: history.length,
                itemBuilder: (_, i) {
                  final t = history[i];
                  return TrackListItem(
                    track: t,
                    isPlaying: player.currentTrack?.id == t.id && player.isPlaying,
                    isLiked: lib.isLiked(t.id),
                    onTap: () => player.playTrack(newQueue: List.from(history), index: i),
                    onLike: () => lib.toggleLike(t.id),
                  );
                },
              ),
      );
    });
  }
}
