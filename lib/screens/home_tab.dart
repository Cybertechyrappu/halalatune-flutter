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

  SliverToBoxAdapter _sectionHeader(String title, {VoidCallback? onShowAll, IconData? icon, bool isHero = false}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 12, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Row(children: [
              if (icon != null) ...[
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 14),
                ),
                const SizedBox(width: 8),
              ],
              Text(title, style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: isHero ? 24 : 16,
                fontWeight: isHero ? FontWeight.w800 : FontWeight.w700,
                color: Colors.white,
                letterSpacing: isHero ? -0.3 : 0.3,
              )),
            ]),
            if (onShowAll != null)
              TextButton(
                onPressed: onShowAll,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFAAAAAA),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Show all', style: TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ),
          ],
        ),
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
    // Media query to check width for responsive card size (130 desktop, 116 mobile)
    final isMobile = MediaQuery.of(context).size.width <= 480;
    final cardSize = isMobile ? 116.0 : 130.0;

    return SizedBox(
      height: cardSize + 45, // height of art + space for text
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
            child: Container(
              width: cardSize,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Stack(alignment: Alignment.center, children: [
                  Container(
                    width: cardSize, height: cardSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black45, offset: Offset(0, 4))],
                      color: const Color(0xFF1E1E1E),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (t.coverArt != null && t.coverArt!.startsWith('http'))
                        ? CachedNetworkImage(imageUrl: t.coverArt!, width: cardSize, height: cardSize, memCacheWidth: (cardSize*3).toInt(), fit: BoxFit.cover)
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            ),
                            child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 40)),
                  ),
                  if (playing)
                    Container(
                      width: cardSize, height: cardSize,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(10)),
                      child: Container(
                        width: 42, height: 42,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 14, color: Colors.black54, offset: Offset(0, 4))]),
                        child: const Icon(Icons.pause_rounded, color: Colors.black, size: 20),
                      ),
                    ),
                ]),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(t.title,
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(t.artist,
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 11.5, color: Color(0xFFAAAAAA)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
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
          // 3-column grid, 1:1 aspect ratio
          crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.0,
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF1a1a1a),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Artwork
                  if (t.coverArt != null && t.coverArt!.startsWith('http'))
                    CachedNetworkImage(imageUrl: t.coverArt!, memCacheWidth: 300, fit: BoxFit.cover)
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: const Center(child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 36)),
                    ),
                  
                  // Play ring (only visible if playing. On web it shows on hover too, but mobile has no hover)
                  if (playing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(color: Color(0xEBFFFFFF), shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black45, offset: Offset(0, 4))]),
                        child: const Icon(Icons.pause_rounded, color: Colors.black, size: 20),
                      ),
                    ),

                  // Title Bar overlay at bottom
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                          stops: [0.0, 1.0],
                        ),
                      ),
                      child: Text(t.title,
                        style: const TextStyle(
                          fontFamily: 'Roboto', fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black87, offset: Offset(0, 1))]
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
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
