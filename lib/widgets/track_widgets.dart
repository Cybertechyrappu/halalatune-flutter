import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/track.dart';

// ── Track Artwork ─────────────────────────────────────────────────────────────
class TrackArtwork extends StatelessWidget {
  final String? url;
  final double size;
  final double borderRadius;

  const TrackArtwork({super.key, this.url, this.size = 52, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty || !url!.startsWith('http')) {
      return _fallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size, height: size,
        memCacheWidth: (size * 3).toInt(),
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Container(
      width: size, height: size,
      color: const Color(0xFF1E1E1E),
      child: Icon(Icons.music_note_rounded, color: const Color(0xFF666666), size: size * 0.4),
    ),
  );
}

// ── Language Badge ────────────────────────────────────────────────────────────
class LangBadge extends StatelessWidget {
  final String language;
  const LangBadge({super.key, required this.language});

  static const _labels = {
    'arabic': 'ARA', 'malayalam': 'MAL', 'english': 'ENG', 'urdu': 'URD', 'others': 'OTH',
  };

  static const _langColors = {
    'arabic': Color(0xFF4DB6AC),
    'malayalam': Color(0xFF9CCC65),
    'english': Color(0xFF64B5F6),
    'urdu': Color(0xFFFFB74D),
    'others': Color(0xFFAAAAAA),
  };

  @override
  Widget build(BuildContext context) {
    final color = _langColors[language] ?? _langColors['others']!;
    final label = _labels[language] ?? language.substring(0, 3).toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(90), width: 0.5),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 9, fontWeight: FontWeight.w700,
        fontFamily: 'Roboto', letterSpacing: 0.5,
      )),
    );
  }
}

// ── Track List Item ───────────────────────────────────────────────────────────
class TrackListItem extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final bool isLiked;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback? onMore;
  final bool showLangBadge;

  const TrackListItem({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.isLiked,
    required this.onTap,
    required this.onLike,
    this.onMore,
    this.showLangBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: isPlaying ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        child: Row(children: [
          // Artwork + playing overlay
          Stack(alignment: Alignment.center, children: [
            TrackArtwork(url: track.coverArt, size: 50, borderRadius: 8),
            if (isPlaying)
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pause_rounded, color: Colors.white, size: 22),
              ),
          ]),
          const SizedBox(width: 14),
          // Title + artist
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track.title, style: TextStyle(
              fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w600,
              color: isPlaying ? Colors.white : Colors.white,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(track.artist, style: const TextStyle(
              fontFamily: 'Roboto', fontSize: 13, color: Color(0xFFAAAAAA),
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 6),
          if (showLangBadge) ...[
            LangBadge(language: track.language),
            const SizedBox(width: 12),
          ],
          // Like button
          GestureDetector(
            onTap: onLike,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                color: isLiked ? Colors.white : const Color(0xFF666666),
                size: 20,
              ),
            ),
          ),
          if (onMore != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onMore,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.more_vert_rounded, color: Color(0xFF666666), size: 20),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
