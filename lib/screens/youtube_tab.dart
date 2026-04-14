import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../services/innertube/innertube_service.dart';
import '../../services/innertube/youtube_auth_service.dart';
import '../../services/innertube/models/innertube_models.dart' show YouTubeTrack;
import '../../models/track.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import '../../theme/app_theme.dart';
import 'youtube_search_screen.dart';

/// YouTube browse screen - allows browsing YouTube Music with halal filtering
/// 
/// This tab shows trending/popular music from YouTube with halal filtering applied
class YouTubeTab extends StatefulWidget {
  const YouTubeTab({super.key});

  @override
  State<YouTubeTab> createState() => _YouTubeTabState();
}

class _YouTubeTabState extends State<YouTubeTab> with AutomaticKeepAliveClientMixin {
  late InnerTubeService _innertube;
  late YoutubeAuthService _authService;

  bool _isLoading = true;
  List<Track> _browseResults = [];
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _authService = context.read<YoutubeAuthService>();
    _innertube = InnerTubeService(authService: _authService);
    _loadBrowseResults();
  }

  @override
  void dispose() {
    _innertube.dispose();
    // Don't dispose _authService here since it's shared
    super.dispose();
  }

  Future<void> _loadBrowseResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Browse YouTube Music home page (FEMUSIC_HOME)
      final sections = await _innertube.browse(browseId: 'FEmusic_home');

      // Flatten and convert results
      final List<YouTubeTrack> allTracks = [];
      for (final section in sections) {
        allTracks.addAll(section.tracks);
      }

      // Convert to app Track models
      final tracks = allTracks.map((YouTubeTrack yt) => Track.fromYouTubeTrack(yt)).toList();

      if (mounted) {
        setState(() {
          _browseResults = tracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('YouTube browse error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load YouTube content';
          _isLoading = false;
        });
      }
    }
  }

  void _playTrack(Track track, int index, PlayerProvider player) {
    if (track.source == TrackSource.youtube && track.youtubeVideoId != null) {
      _resolveAndPlay(track, index, player);
    } else {
      player.playTrack(newQueue: _browseResults, index: index);
    }
  }

  Future<void> _resolveAndPlay(Track track, int index, PlayerProvider player) async {
    try {
      final audioUrl = await _innertube.getAudioUrl(track.youtubeVideoId!);
      
      if (audioUrl != null && mounted) {
        track.streamUrl = audioUrl;
        player.playTrack(newQueue: _browseResults, index: index);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to resolve stream URL'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Stream resolution error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: _loadBrowseResults,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: const Color(0xFF181818),
              elevation: 0,
              scrolledUnderElevation: 0,
              title: const Text('YouTube Music', style: TextStyle(
                fontFamily: 'Outfit', fontSize: 20,
                fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
              )),
              actions: [
                // Search button
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const YouTubeSearchScreen()),
                    );
                  },
                  splashRadius: 20,
                ),
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                  onPressed: _loadBrowseResults,
                  splashRadius: 20,
                ),
              ],
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 4)),

            // Content
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.accent),
                      SizedBox(height: 16),
                      Text(
                        'Loading YouTube Music...',
                        style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Outfit'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Outfit'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadBrowseResults,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_browseResults.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.music_off_rounded, size: 48, color: AppTheme.textDim),
                      SizedBox(height: 16),
                      Text(
                        'No results available',
                        style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Outfit'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = _browseResults[index];
                    return _YouTubeTrackListItem(
                      track: track,
                      onTap: () => _playTrack(track, index, context.read<PlayerProvider>()),
                    );
                  },
                  childCount: _browseResults.length,
                  addRepaintBoundaries: false,
                  addAutomaticKeepAlives: false,
                ),
              ),

            // Bottom padding for mini player
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

/// YouTube track list item
class _YouTubeTrackListItem extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _YouTubeTrackListItem({
    required this.track,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, LibraryProvider>(
      builder: (context, player, lib, _) {
        final isPlaying = player.currentTrack?.id == track.id && player.isPlaying;
        final isLiked = lib.isLiked(track.id);

        return InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Thumbnail with play overlay
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF1E1E1E),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: track.coverArt != null && track.coverArt!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: track.coverArt!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              memCacheWidth: 120,
                              placeholder: (_, __) => Container(
                                color: const Color(0xFF1E1E1E),
                                child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 28),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 28),
                            ),
                    ),
                    if (isPlaying)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.pause_rounded, color: Colors.white, size: 28),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // Title and artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: TextStyle(
                          color: isPlaying ? AppTheme.accent : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Outfit',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // YouTube badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'YT',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              track.artist,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontFamily: 'Outfit',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Duration
                if (track.duration != null)
                  Text(
                    _formatDuration(track.duration!),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontFamily: 'Outfit',
                    ),
                  ),

                const SizedBox(width: 8),

                // Like button (only for firestore tracks)
                if (track.source == TrackSource.firestore)
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isLiked ? Colors.red : AppTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => lib.toggleLike(track.id),
                    splashRadius: 18,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
