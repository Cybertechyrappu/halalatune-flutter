import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/track_widgets.dart';

const _kCategories = [
  {'key': 'arabic', 'label': 'Arabic'},
  {'key': 'malayalam', 'label': 'Malayalam'},
  {'key': 'english', 'label': 'English'},
  {'key': 'urdu', 'label': 'Urdu'},
  {'key': 'others', 'label': 'Others'},
];

class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  final Map<String, bool> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Consumer2<LibraryProvider, PlayerProvider>(
      builder: (context, lib, player, _) {
        if (!lib.tracksLoaded) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2));
        }

        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: false,
              backgroundColor: Colors.black,
              title: Text('Categories',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      fontFamily: 'Roboto')),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ..._buildSections(lib, player),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }

  List<Widget> _buildSections(LibraryProvider lib, PlayerProvider player) {
    final result = <Widget>[];
    for (final cat in _kCategories) {
      final key = cat['key']!;
      final label = cat['label']!;
      final tracks = lib.getByLanguage(key);
      if (tracks.isEmpty) continue;

      final isExpanded = _expanded[key] ?? false;
      final visible = isExpanded ? tracks : tracks.take(5).toList();

      result.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      fontFamily: 'Roboto')),
              const Spacer(),
              if (tracks.length > 5)
                GestureDetector(
                  onTap: () => setState(() => _expanded[key] = !isExpanded),
                  child: Text(
                    isExpanded ? 'Show less' : 'Show all',
                    style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        fontFamily: 'Roboto'),
                  ),
                ),
            ],
          ),
        ),
      ));

      result.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) {
            final track = visible[i];
            return TrackListItem(
              track: track,
              isPlaying:
                  player.currentTrack?.id == track.id && player.isPlaying,
              isLiked: lib.isLiked(track.id),
              onTap: () {
                final auth = context.read<AuthProvider>();
                player.setUserId(auth.user?.uid);
                player.playTrack(
                    newQueue: List.from(tracks), index: tracks.indexOf(track));
                if (auth.user != null) {
                  lib.addToHistory(auth.user!.uid, track.id);
                }
              },
              onLike: () => lib.toggleLike(track.id),
            );
          },
          childCount: visible.length,
        ),
      ));

      result.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));
    }
    return result;
  }
}
