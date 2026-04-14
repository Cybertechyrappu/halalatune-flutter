import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../services/innertube/innertube_service.dart';
import '../../services/innertube/youtube_auth_service.dart';
import '../../services/innertube/models/innertube_models.dart' show YouTubeTrack;
import '../../models/track.dart';
import '../../providers/player_provider.dart';
import '../../theme/app_theme.dart';

/// YouTube search screen with halal filtering
/// 
/// Allows users to search YouTube Music and plays filtered results
class YouTubeSearchScreen extends StatefulWidget {
  const YouTubeSearchScreen({super.key});

  @override
  State<YouTubeSearchScreen> createState() => _YouTubeSearchScreenState();
}

class _YouTubeSearchScreenState extends State<YouTubeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late InnerTubeService _innertube;
  late YoutubeAuthService _authService;

  List<Track> _results = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _authService = context.read<YoutubeAuthService>();
    _innertube = InnerTubeService(authService: _authService);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _innertube.dispose();
    // Don't dispose _authService since it's shared
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchQuery = query;
      _results = [];
    });

    try {
      // Search YouTube Music
      final List<YouTubeTrack> ytTracks = await _innertube.search(query: query);

      // Convert to app Track models
      final tracks = ytTracks.map((YouTubeTrack yt) => Track.fromYouTubeTrack(yt)).toList();

      if (mounted) {
        setState(() {
          _results = tracks;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('YouTube search error: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _playTrack(Track track, int index, PlayerProvider player) {
    // For YouTube tracks, resolve the stream URL first
    if (track.source == TrackSource.youtube && track.youtubeVideoId != null) {
      _resolveAndPlay(track, index, player);
    } else {
      player.playTrack(newQueue: _results, index: index);
    }
  }

  Future<void> _resolveAndPlay(Track track, int index, PlayerProvider player) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Resolving stream URL...'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      // Get streaming URL from InnerTube
      final audioUrl = await _innertube.getAudioUrl(track.youtubeVideoId!);
      
      if (audioUrl != null && mounted) {
        // Set the resolved URL on the track
        track.streamUrl = audioUrl;
        player.playTrack(newQueue: _results, index: index);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'Outfit'),
          decoration: const InputDecoration(
            hintText: 'Search YouTube Music...',
            hintStyle: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Outfit'),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
          ),
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 20,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.accent),
            SizedBox(height: 16),
            Text(
              'Searching YouTube Music...',
              style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Outfit'),
            ),
          ],
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text(
              'Search YouTube Music',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontFamily: 'Outfit',
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find your favorite Islamic songs and nasheeds',
              style: TextStyle(
                color: AppTheme.textDim,
                fontFamily: 'Outfit',
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontFamily: 'Outfit',
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Results list
    return ListView.builder(
      itemCount: _results.length,
      physics: const BouncingScrollPhysics(),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) {
        final track = _results[index];
        return _YouTubeTrackTile(
          track: track,
          index: index,
          onPlay: () => _playTrack(track, index, Provider.of<PlayerProvider>(context, listen: false)),
        );
      },
    );
  }
}

/// Track tile for YouTube search results
class _YouTubeTrackTile extends StatelessWidget {
  final Track track;
  final int index;
  final VoidCallback onPlay;

  const _YouTubeTrackTile({
    required this.track,
    required this.index,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final isYouTube = track.source == TrackSource.youtube;

    return InkWell(
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Index number
            SizedBox(
              width: 24,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontFamily: 'Outfit',
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Thumbnail
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFF1E1E1E),
              ),
              clipBehavior: Clip.antiAlias,
              child: track.coverArt != null && track.coverArt!.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: track.coverArt!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF1E1E1E),
                        child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 24),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 24),
                    ),
            ),

            const SizedBox(width: 12),

            // Title and artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      color: Colors.white,
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
                      if (isYouTube)
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
                      if (isYouTube) const SizedBox(width: 6),
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

            // Play button
            const Icon(Icons.play_arrow_rounded, color: AppTheme.textSecondary, size: 24),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
