import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/track.dart';
import '../theme/app_theme.dart';

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
      color: AppTheme.bgElevated,
      child: Icon(Icons.music_note_rounded, color: AppTheme.textDim, size: size * 0.4),
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

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.langColors[language] ?? AppTheme.langColors['others']!;
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
        fontFamily: 'Outfit', letterSpacing: 0.5,
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: isPlaying
            ? BoxDecoration(
                color: AppTheme.accentFaint,
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: Row(children: [
          // Artwork + playing overlay
          Stack(alignment: Alignment.center, children: [
            TrackArtwork(url: track.coverArt, size: 50, borderRadius: 8),
            if (isPlaying)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50, height: 50,
                  color: Colors.black.withAlpha(110),
                  child: const Icon(Icons.pause_rounded, color: AppTheme.accent, size: 22),
                ),
              ),
          ]),
          const SizedBox(width: 12),
          // Title + artist
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track.title, style: TextStyle(
              fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600,
              color: isPlaying ? AppTheme.accent : AppTheme.textPrimary,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(track.artist, style: const TextStyle(
              fontFamily: 'Outfit', fontSize: 12, color: AppTheme.textSecondary,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 6),
          if (showLangBadge) ...[
            LangBadge(language: track.language),
            const SizedBox(width: 8),
          ],
          // Like button
          GestureDetector(
            onTap: onLike,
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: isLiked ? AppTheme.liked : AppTheme.textDim,
              size: 20,
            ),
          ),
          if (onMore != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onMore,
              child: const Icon(Icons.more_vert_rounded, color: AppTheme.textDim, size: 20),
            ),
          ],
        ]),
      ),
    );
  }
}
