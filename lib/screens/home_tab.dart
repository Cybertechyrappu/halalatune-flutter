import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/track_widgets.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<dynamic>? _sdPicks;

  @override
  Widget build(BuildContext context) {
    return Consumer2<LibraryProvider, PlayerProvider>(
      builder: (context, lib, player, _) {
        if (!lib.tracksLoaded) {
          return const Scaffold(
            backgroundColor: AppTheme.bg,
            body: Center(child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 1.5)),
          );
        }
        _sdPicks ??= lib.getSpeedDial();

        return Scaffold(
          backgroundColor: AppTheme.bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: AppTheme.bg,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(13),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset('assets/images/icon.png', width: 28, height: 28),
                  ),
                ),
                title: const Text('HalalTune', style: TextStyle(
                  fontFamily: 'Outfit', fontSize: 20,
                  fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
                )),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                    onPressed: () => showSearch(context: context,
                      delegate: _TrackSearchDelegate(lib, player, context)),
                    splashRadius: 20,
                  ),
                ],
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 4)),

              // ── Recents ───────────────────────────────────────────────────
              if (lib.recentTracks.isNotEmpty) ...[
                _sectionHeader('Recents', onShowAll: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
                SliverToBoxAdapter(child: _RecentsStrip(
                  tracks: lib.recentTracks, player: player, lib: lib, ctx: context)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],

              // ── Speed Dial ────────────────────────────────────────────────
              if (_sdPicks!.isNotEmpty) ...[
                _sectionHeader('Speed Dial', icon: Icons.bolt_rounded),
                SliverToBoxAdapter(child: _SpeedDialGrid(
                  picks: _sdPicks!, player: player, lib: lib, ctx: context)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],

              // ── All Songs ─────────────────────────────────────────────────
              if (lib.allTracks.isNotEmpty) ...[
                _sectionHeader('All Songs'),
                SliverList(delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final t = lib.allTracks[i];
                    final auth = context.read<AuthProvider>();
                    return TrackListItem(
                      track: t,
                      isPlaying: player.currentTrack?.id == t.id && player.isPlaying,
                      isLiked: lib.isLiked(t.id),
                      showLangBadge: true,
                      onTap: () {
                        player.setUserId(auth.user?.uid);
                        player.playTrack(newQueue: List.from(lib.allTracks), index: i);
                        if (auth.user != null) lib.addToHistory(auth.user!.uid, t.id);
                      },
                      onLike: () => lib.toggleLike(t.id),
                    );
                  },
                  childCount: lib.allTracks.length,
                  addRepaintBoundaries: false,
                  addAutomaticKeepAlives: false,
                )),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _sectionHeader(String title, {VoidCallback? onShowAll, IconData? icon}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, color: AppTheme.accent, size: 18),
              const SizedBox(width: 6),
            ] else ...[
              Container(width: 3, height: 16,
                decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
            ],
            Text(title, style: const TextStyle(
              fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
            )),
          ]),
          if (onShowAll != null)
            TextButton(
              onPressed: onShowAll,
              style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary,
                padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Show all', style: TextStyle(fontFamily: 'Outfit', fontSize: 12)),
            ),
        ]),
      ),
    );
  }
}

// ── Recents Strip ────────────────────────────────────────────────────────────────
class _RecentsStrip extends StatelessWidget {
  final List tracks;
  final PlayerProvider player;
  final LibraryProvider lib;
  final BuildContext ctx;
  const _RecentsStrip({required this.tracks, required this.player, required this.lib, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: tracks.length,
        itemBuilder: (_, i) {
          final t = tracks[i];
          final playing = player.currentTrack?.id == t.id && player.isPlaying;
          return GestureDetector(
            onTap: () {
              final auth = ctx.read<AuthProvider>();
              player.setUserId(auth.user?.uid);
              player.playTrack(newQueue: List.from(tracks), index: i);
              if (auth.user != null) lib.addToHistory(auth.user!.uid, t.id);
            },
            child: SizedBox(
              width: 78, 
              child: Column(children: [
                Stack(alignment: Alignment.center, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (t.coverArt != null && t.coverArt!.startsWith('http'))
                        ? CachedNetworkImage(imageUrl: t.coverArt!, width: 70, height: 70, memCacheWidth: 210, fit: BoxFit.cover)
                        : Container(width: 70, height: 70, color: AppTheme.bgElevated,
                            child: const Icon(Icons.music_note_rounded, color: AppTheme.textDim, size: 28)),
                  ),
                  if (playing)
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.pause_rounded, color: AppTheme.accent, size: 26),
                    ),
                ]),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(t.title,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, color: AppTheme.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ── Speed Dial Grid ───────────────────────────────────────────────────────────────
class _SpeedDialGrid extends StatelessWidget {
  final List picks;
  final PlayerProvider player;
  final LibraryProvider lib;
  final BuildContext ctx;
  const _SpeedDialGrid({required this.picks, required this.player, required this.lib, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85,
        ),
        itemCount: picks.length,
        itemBuilder: (_, i) {
          final t = picks[i];
          final playing = player.currentTrack?.id == t.id && player.isPlaying;
          return GestureDetector(
            onTap: () {
              final auth = ctx.read<AuthProvider>();
              player.setUserId(auth.user?.uid);
              player.playTrack(newQueue: List.from(picks), index: i);
              if (auth.user != null) lib.addToHistory(auth.user!.uid, t.id);
            },
            child: Column(children: [
              Expanded(child: Stack(alignment: Alignment.center, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (t.coverArt != null && t.coverArt!.startsWith('http'))
                      ? CachedNetworkImage(imageUrl: t.coverArt!, width: double.infinity, height: double.infinity, memCacheWidth: 450, fit: BoxFit.cover)
                      : Container(color: AppTheme.bgElevated,
                          child: const Icon(Icons.music_note_rounded, color: AppTheme.textDim, size: 32)),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(playing ? 130 : 80),
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: playing ? AppTheme.accent : Colors.white, size: 30),
                ),
              ])),
              const SizedBox(height: 5),
              Text(t.title,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, color: AppTheme.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ]),
          );
        },
      ),
    );
  }
}

// ── Search ────────────────────────────────────────────────────────────────────────
class _TrackSearchDelegate extends SearchDelegate {
  final LibraryProvider lib;
  final PlayerProvider player;
  final BuildContext parentCtx;
  _TrackSearchDelegate(this.lib, this.player, this.parentCtx);

  @override
  String get searchFieldLabel => 'Search songs, artists…';

  @override
  ThemeData appBarTheme(BuildContext context) => AppTheme.dark.copyWith(
    scaffoldBackgroundColor: AppTheme.bg,
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppTheme.textDim, fontFamily: 'Outfit'),
    ),
  );

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
        onPressed: () => query = '', splashRadius: 18),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textSecondary),
    onPressed: () => close(context, null), splashRadius: 18,
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search for songs or artists',
        style: TextStyle(color: AppTheme.textDim, fontFamily: 'Outfit')));
    }
    final results = lib.searchTracks(query);
    if (results.isEmpty) {
      return const Center(child: Text('No results found',
        style: TextStyle(color: AppTheme.textDim, fontFamily: 'Outfit')));
    }
    final auth = parentCtx.read<AuthProvider>();
    return ListView.builder(
      itemCount: results.length,
      physics: const BouncingScrollPhysics(),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (_, i) {
        final t = results[i];
        return TrackListItem(
          track: t,
          isPlaying: player.currentTrack?.id == t.id && player.isPlaying,
          isLiked: lib.isLiked(t.id),
          showLangBadge: true,
          onTap: () {
            player.setUserId(auth.user?.uid);
            player.playTrack(newQueue: results, index: i);
            if (auth.user != null) lib.addToHistory(auth.user!.uid, t.id);
            close(context, null);
          },
          onLike: () => lib.toggleLike(t.id),
        );
      },
    );
  }
}
