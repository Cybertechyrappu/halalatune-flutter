import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/track_widgets.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: AppBar(
            backgroundColor: AppTheme.bg,
            title: const Text('Library', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textDim,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: AppTheme.accent, width: 2),
              ),
              labelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
              tabs: const [
                Tab(text: 'Downloads'),
                Tab(text: 'Playlists'),
                Tab(text: 'Liked'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _DownloadsView(),
              _PlaylistsView(uid: auth.user?.uid ?? ''),
              _LikedView(),
            ],
          ),
        );
      },
    );
  }
}

// ── Downloads ─────────────────────────────────────────────────────────────────
class _DownloadsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_rounded, color: AppTheme.textDim, size: 60),
          SizedBox(height: 16),
          Text('No downloaded songs yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontFamily: 'Outfit')),
          SizedBox(height: 8),
          Text('Tap ⋮ on any song to save it for offline.', style: TextStyle(color: AppTheme.textDim, fontSize: 13, fontFamily: 'Outfit')),
        ],
      ),
    );
  }
}

// ── Playlists ─────────────────────────────────────────────────────────────────
class _PlaylistsView extends StatefulWidget {
  final String uid;
  const _PlaylistsView({required this.uid});

  @override
  State<_PlaylistsView> createState() => _PlaylistsViewState();
}

class _PlaylistsViewState extends State<_PlaylistsView> {
  final FirestoreService _db = FirestoreService();
  List<Map<String, dynamic>> _mine = [];
  List<Map<String, dynamic>> _public = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.uid.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final results = await Future.wait([
      _db.loadUserPlaylists(widget.uid),
      _db.loadPublicPlaylists(widget.uid),
    ]);
    setState(() {
      _mine = results[0];
      _public = results[1];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Playlist'),
            onPressed: () => _showCreatePlaylist(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: (_mine.isEmpty && _public.isEmpty)
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.queue_music_rounded, color: AppTheme.textDim, size: 60),
                      SizedBox(height: 16),
                      Text('No playlists yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontFamily: 'Outfit')),
                      SizedBox(height: 8),
                      Text('Create your first playlist above.', style: TextStyle(color: AppTheme.textDim, fontSize: 13, fontFamily: 'Outfit')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    if (_mine.isNotEmpty) ...[
                      _sectionLabel('My Playlists'),
                      ..._mine.map((pl) => _PlaylistCard(pl: pl, onTap: () {})),
                    ],
                    if (_public.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _sectionLabel('Public Playlists'),
                      ..._public.map((pl) => _PlaylistCard(pl: pl, onTap: () {})),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
    child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
  );

  void _showCreatePlaylist(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String visibility = 'public';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('New Playlist', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textDim), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Outfit'),
                decoration: const InputDecoration(hintText: 'Playlist name'),
                maxLength: 60,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Outfit'),
                decoration: const InputDecoration(hintText: 'Description (optional)'),
                maxLines: 2,
                maxLength: 200,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Visibility:', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Outfit')),
                  const SizedBox(width: 12),
                  _visButton(ctx, setModalState, 'Public', 'public', visibility, (v) { visibility = v; }),
                  const SizedBox(width: 8),
                  _visButton(ctx, setModalState, 'Private', 'private', visibility, (v) { visibility = v; }),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final auth = context.read<AuthProvider>();
                  if (auth.user == null) return;
                  Navigator.pop(ctx);
                  await _db.createPlaylist(
                    name: name,
                    description: descCtrl.text.trim(),
                    visibility: visibility,
                    ownerId: auth.user!.uid,
                    ownerName: auth.user!.displayName ?? 'User',
                  );
                  _load();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create Playlist', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _visButton(BuildContext ctx, StateSetter setModalState, String label, String value, String current, Function(String) onSelect) {
    final isActive = current == value;
    return GestureDetector(
      onTap: () => setModalState(() => onSelect(value)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent.withOpacity(0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.accent : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: isActive ? AppTheme.accent : AppTheme.textSecondary, fontSize: 13, fontFamily: 'Outfit')),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Map<String, dynamic> pl;
  final VoidCallback onTap;
  const _PlaylistCard({required this.pl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final coverArt = pl['coverArt'] ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (coverArt.isNotEmpty && coverArt.startsWith('http'))
                  ? CachedNetworkImage(imageUrl: coverArt, width: 52, height: 52, memCacheWidth: 156, fit: BoxFit.cover)
                  : Container(width: 52, height: 52, color: AppTheme.surface, child: const Icon(Icons.music_note_rounded, color: AppTheme.textDim)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(pl['name'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Outfit'), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (pl['visibility'] == 'private')
                        const Icon(Icons.lock_rounded, color: AppTheme.textDim, size: 14),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${pl['trackCount'] ?? 0} songs', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Outfit')),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textDim),
          ],
        ),
      ),
    );
  }
}

// ── Liked songs ───────────────────────────────────────────────────────────────
class _LikedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<LibraryProvider, PlayerProvider>(
      builder: (context, lib, player, _) {
        final tracks = lib.likedTracks;
        if (tracks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_outline_rounded, color: AppTheme.liked, size: 60),
                SizedBox(height: 16),
                Text('No liked songs yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontFamily: 'Outfit')),
                SizedBox(height: 8),
                Text('Tap the heart on any song to save it here.', style: TextStyle(color: AppTheme.textDim, fontSize: 13, fontFamily: 'Outfit')),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: tracks.length,
          itemBuilder: (_, i) {
            final t = tracks[i];
            return TrackListItem(
              track: t,
              isPlaying: player.currentTrack?.id == t.id && player.isPlaying,
              isLiked: true,
              onTap: () {
                final auth = context.read<AuthProvider>();
                player.setUserId(auth.user?.uid);
                player.playTrack(newQueue: List.from(tracks), index: i);
              },
              onLike: () => lib.toggleLike(t.id),
            );
          },
        );
      },
    );
  }
}
