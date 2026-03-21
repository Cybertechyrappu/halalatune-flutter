import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
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
                  color: AppTheme.accent, strokeWidth: 2));
        }

        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: false,
              backgroundColor: AppTheme.bg,
              title: Text('Categories',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Outfit')),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ..._buildSections(lib, player),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.langColors[key] ?? AppTheme.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Outfit')),
              const Spacer(),
              if (tracks.length > 5)
                GestureDetector(
                  onTap: () => setState(() => _expanded[key] = !isExpanded),
                  child: Text(
                    isExpanded ? 'Show less' : 'See all',
                    style: TextStyle(
                        color: AppTheme.langColors[key] ?? AppTheme.accent,
                        fontSize: 13,
                        fontFamily: 'Outfit'),
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
                if (auth.user != null)
                  lib.addToHistory(auth.user!.uid, track.id);
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
