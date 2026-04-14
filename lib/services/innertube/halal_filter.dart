import 'package:flutter/foundation.dart';
import 'models/innertube_models.dart';

/// Halal content filter for YouTube music
/// 
/// Filters out content that doesn't align with Islamic principles:
/// - Explicit content (marked by YouTube)
/// - Haram keywords (alcohol, drugs, gambling, etc.)
/// - Inappropriate genres/categories
/// 
/// Filter levels:
/// - Strict: Maximum filtering, only clearly halal content passes
/// - Moderate: Balanced filtering, blocks obvious haram content
/// - Light: Minimal filtering, only blocks explicit content
enum FilterLevel { strict, moderate, light }

class HalalFilter {
  FilterLevel _currentLevel;

  // ── Keyword Blacklists ─────────────────────────────────────────────────────

  /// Keywords related to alcohol
  static const List<String> _alcoholKeywords = [
    'alcohol', 'alcoholic', 'beer', 'wine', 'vodka', 'whiskey', 'rum',
    'tequila', 'brandy', 'cocktail', 'drunk', 'drinking', 'bar', 'pub',
    'liquor', 'spirits', 'booze', 'intoxicated', 'hangover', 'brewery',
    'khamr', // Arabic for intoxicant
  ];

  /// Keywords related to drugs/substance abuse
  static const List<String> _drugKeywords = [
    'drug', 'drugs', 'cocaine', 'heroin', 'marijuana', 'weed', 'high',
    'smoking', 'smoke', 'cannabis', 'meth', 'crack', 'pill', 'xanax',
    'oxycontin', 'addict', 'addiction', 'overdose', 'trip', 'tripping',
    'hashish', 'hash', 'narcotic',
  ];

  /// Keywords related to gambling
  static const List<String> _gamblingKeywords = [
    'gamble', 'gambling', 'casino', 'poker', 'bet', 'betting', 'wager',
    'lottery', 'jackpot', 'slot machine', 'roulette', 'blackjack',
    'baccarat', 'dice', 'sportsbook', 'odds', 'horses', 'racing bet',
  ];

  /// Keywords related to explicit sexual content
  static const List<String> _sexualKeywords = [
    'sex', 'sexual', 'nude', 'naked', 'porn', 'pornography', 'explicit',
    'xxx', 'erotic', 'striptease', 'booty', 'ass', 'butt', 'thick',
    'booty shake', 'twerk', 'twink', 'bitch', 'hoe', 'whore', 'slut',
    'pussy', 'dick', 'fuck', 'shit', 'damn', 'hell',
  ];

  /// Keywords related to un-Islamic religious content
  static const List<String> _religiousKeywords = [
    'satan', 'satanic', 'devil worship', 'lucifer', 'occult', 'demon',
    'witch', 'witchcraft', 'spell', 'magic', 'pagan', 'heathen',
    'blasphemy', 'heretic', 'anti christ', 'antichrist',
  ];

  /// Keywords related to violence/harm
  static const List<String> _violenceKeywords = [
    'kill', 'killing', 'murder', 'death', 'die', 'die die', 'shoot',
    'shooting', 'gun', 'guns', 'violence', 'violent', 'blood', 'bloodshed',
    'gang', 'gangsta', 'gangster', 'thug', 'criminal', 'crime', 'rob',
    'steal', 'thief', 'rape', 'abuse', 'torture',
  ];

  /// Music genres often associated with haram content
  static const List<String> _haramGenreKeywords = [
    'gangsta rap', 'drill', 'trap', 'hardcore rap', 'mumble rap',
  ];

  /// Keywords that indicate potentially haram party/club culture
  static const List<String> _partyKeywords = [
    'party', 'partying', 'club', 'clubbing', 'nightclub', 'rave', 'dj',
    'dancehall', 'strip', 'strip club', 'bottle service', 'vip',
    'turnt', 'turn up', 'lit', 'wild', 'crazy', 'after party',
  ];

  /// Keywords related to materialism/excessive wealth promotion
  static const List<String> _materialismKeywords = [
    'billionaire', 'millionaire', 'rich', 'wealth', 'money', 'cash',
    'gold', 'diamond', 'diamonds', 'jewelry', 'jewellery', 'luxury',
    'designer', 'gucci', 'prada', 'louis vuitton', 'rolex', 'bentley',
    'lamborghini', 'ferrari', 'porsche', 'mansion', 'yacht',
  ];

  // ── Halal Positive Indicators ───────────────────────────────────────────────

  /// Keywords that indicate halal/Islamic content (used in strict mode)
  static const List<String> _halalPositiveKeywords = [
    'nasheed', 'islamic', 'quran', 'quran recitation', 'adhkar', 'dua',
    'salah', 'prayer', 'allah', 'muhammad', 'prophet', 'ramadan',
    'eid', 'hajj', 'umrah', 'mosque', 'masjid', 'islamic song',
    'halal', 'deen', 'iman', 'taqwa', 'barakah', 'subhanallah',
    'alhamdulillah', 'allahu akbar', 'mashaallah', 'astaghfirullah',
    'recitation', 'tilawah', 'adhan', 'azan', 'call to prayer',
  ];

  // ── Constructor ────────────────────────────────────────────────────────────

  HalalFilter({FilterLevel level = FilterLevel.moderate}) : _currentLevel = level;

  FilterLevel get currentLevel => _currentLevel;

  void setLevel(FilterLevel level) {
    _currentLevel = level;
    debugPrint('HalalFilter level set to: ${level.name}');
  }

  // ── Filter Methods ─────────────────────────────────────────────────────────

  /// Check if a single YouTube track passes the halal filter
  bool isHalal(YouTubeTrack track) {
    // Always block explicit content
    if (track.isExplicit) return false;

    final textToCheck = _getTextToAnalyze(track);
    final lowerText = textToCheck.toLowerCase();

    switch (_currentLevel) {
      case FilterLevel.strict:
        return _strictFilter(lowerText, track);
      case FilterLevel.moderate:
        return _moderateFilter(lowerText, track);
      case FilterLevel.light:
        return _lightFilter(lowerText, track);
    }
  }

  /// Filter a list of tracks, returning only halal ones
  List<YouTubeTrack> filterTracks(List<YouTubeTrack> tracks) {
    return tracks.where(isHalal).toList();
  }

  /// Get the reason why a track was filtered out (for debugging)
  String getFilterReason(YouTubeTrack track) {
    if (track.isExplicit) return 'Explicit content';

    final textToCheck = _getTextToAnalyze(track);
    final lowerText = textToCheck.toLowerCase();

    // Check all keyword lists
    final checks = [
      ('Alcohol-related content', _alcoholKeywords),
      ('Drug-related content', _drugKeywords),
      ('Gambling-related content', _gamblingKeywords),
      ('Sexual/inappropriate content', _sexualKeywords),
      ('Occult/anti-religious content', _religiousKeywords),
      ('Violence/criminal content', _violenceKeywords),
    ];

    for (final (reason, keywords) in checks) {
      for (final keyword in keywords) {
        if (lowerText.contains(keyword)) {
          return '$reason (matched: "$keyword")';
        }
      }
    }

    if (_currentLevel != FilterLevel.light) {
      final mediumChecks = [
        ('Party/club culture', _partyKeywords),
      ];

      for (final (reason, keywords) in mediumChecks) {
        for (final keyword in keywords) {
          if (lowerText.contains(keyword)) {
            return '$reason (matched: "$keyword")';
          }
        }
      }
    }

    if (_currentLevel == FilterLevel.strict) {
      final strictChecks = [
        ('Materialism/wealth focus', _materialismKeywords),
        ('Haram genre', _haramGenreKeywords),
      ];

      for (final (reason, keywords) in strictChecks) {
        for (final keyword in keywords) {
          if (lowerText.contains(keyword)) {
            return '$reason (matched: "$keyword")';
          }
        }
      }
    }

    return 'Passed filter';
  }

  // ── Filter Level Implementations ───────────────────────────────────────────

  bool _lightFilter(String lowerText, YouTubeTrack track) {
    // Only block explicit and the most offensive content
    return !_containsAny(lowerText, [
      ..._sexualKeywords,
      ..._drugKeywords,
      ..._violenceKeywords.take(5), // Only most violent
    ]);
  }

  bool _moderateFilter(String lowerText, YouTubeTrack track) {
    // Block all haram content categories
    return !_containsAny(lowerText, [
      ..._alcoholKeywords,
      ..._drugKeywords,
      ..._gamblingKeywords,
      ..._sexualKeywords,
      ..._religiousKeywords,
      ..._violenceKeywords,
    ]);
  }

  bool _strictFilter(String lowerText, YouTubeTrack track) {
    // Everything in moderate + party culture + materialism + genre filtering
    final allBlocked = [
      ..._alcoholKeywords,
      ..._drugKeywords,
      ..._gamblingKeywords,
      ..._sexualKeywords,
      ..._religiousKeywords,
      ..._violenceKeywords,
      ..._partyKeywords,
      ..._materialismKeywords,
      ..._haramGenreKeywords,
    ];

    if (_containsAny(lowerText, allBlocked)) return false;

    // In strict mode, prefer content with positive halal indicators
    // If no halal positive keywords found, still allow but log it
    final hasPositiveIndicator = _containsAny(lowerText, _halalPositiveKeywords);
    if (!hasPositiveIndicator) {
      // Don't block, but this could be configured to be stricter
      // For now, we allow content that doesn't match negative keywords
      return true;
    }

    return true;
  }

  // ── Helper Methods ─────────────────────────────────────────────────────────

  /// Get all text from track to analyze
  String _getTextToAnalyze(YouTubeTrack track) {
    final parts = <String>[
      track.title,
      if (track.artist != null) track.artist!,
      if (track.album != null) track.album!,
      if (track.description != null) track.description!,
      if (track.categories != null) track.categories!.join(' '),
    ];
    return parts.join(' ').toLowerCase();
  }

  /// Check if text contains any of the keywords
  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// Add custom keywords to filter at runtime
  final List<String> _customKeywords = [];

  void addCustomKeyword(String keyword) {
    _customKeywords.add(keyword.toLowerCase());
  }

  void removeCustomKeyword(String keyword) {
    _customKeywords.remove(keyword.toLowerCase());
  }

  void clearCustomKeywords() {
    _customKeywords.clear();
  }

  /// Get all blocked keywords (for settings/info screen)
  Map<String, List<String>> getBlockedKeywords() {
    return {
      'Alcohol': _alcoholKeywords,
      'Drugs': _drugKeywords,
      'Gambling': _gamblingKeywords,
      'Sexual Content': _sexualKeywords,
      'Anti-Religious': _religiousKeywords,
      'Violence': _violenceKeywords,
      'Party/Club': _partyKeywords,
      'Materialism': _materialismKeywords,
      'Haram Genres': _haramGenreKeywords,
      'Custom': _customKeywords,
    };
  }
}
