# HalalTune Flutter - Project Context

## Overview
HalalTune is a premium halal audio streaming app built with Flutter. It combines Firebase-backed curated content with YouTube Music streaming via the InnerTube API, all filtered through a configurable halal content filter.

## Architecture

### State Management
- **Provider** - All state managed via ChangeNotifierProviders
- Key providers: `AuthProvider`, `LibraryProvider`, `PlayerProvider`

### Core Services
- **FirestoreService** - Firebase Firestore for tracks, likes, history, playlists
- **InnerTubeService** - YouTube InnerTube API client (search, browse, player, next endpoints)
- **HalalFilter** - Configurable halal content filtering (light/moderate/strict levels)
- **DownloadService** - Audio download management
- **HalalTuneAudioHandler** - Background audio service via audio_service

### Data Models
- **Track** - Unified model supporting both Firestore and YouTube sources (`TrackSource` enum)
- **YouTubeTrack** - InnerTube API response model
- **Playlist** - User-created playlists

### Key Screens
- **HomeTab** - Main screen with recents, speed dial, all songs
- **CategoriesTab** - Browse by language/category
- **YouTubeTab** - YouTube Music browse with halal filtering
- **YouTubeSearchScreen** - Search YouTube Music with real-time halal filtering
- **LibraryTab** - Liked tracks, playlists
- **AccountTab** - User account settings
- **FullPlayerScreen** - Full-screen audio player
- **MiniPlayer** - Persistent bottom mini player
- **AuthScreen** - Firebase authentication (Google Sign-In)

### Navigation
- **MainShell** - IndexedStack with 5 tabs: Home, Categories, YouTube, Library, Account
- Floating AMOLED nav bubble with sliding pill animation

## InnerTube API Integration

### Endpoints Used
- `POST /youtubei/v1/search` - Search YouTube Music
- `POST /youtubei/v1/player` - Get streaming URLs for a video
- `POST /youtubei/v1/browse` - Browse YouTube Music home/playlists
- `POST /youtubei/v1/next` - Get related/queue tracks

### API Key
- InnerTube API key: `AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30`
- Client: `WEB_REMIX` (YouTube Music web client)

### Playback Flow for YouTube Tracks
1. User searches/browses → InnerTube returns `YouTubeTrack` objects
2. HalalFilter filters out haram content
3. Converted to `Track` with `Track.fromYouTubeTrack()`
4. On play, `PlayerProvider` calls `getAudioUrl(videoId)` to resolve stream URL
5. Audio plays via just_audio using the resolved URL

## Halal Filter

### Filter Levels
- **Light** - Only blocks explicit content and most offensive terms
- **Moderate** (default) - Blocks all haram content categories
- **Strict** - Everything + party/club culture, materialism, haram genres

### Blocked Categories
- Alcohol (beer, wine, vodka, etc.)
- Drugs (cocaine, marijuana, etc.)
- Gambling (casino, poker, betting, etc.)
- Sexual content (explicit, nude, etc.)
- Anti-religious (satanic, occult, etc.)
- Violence (kill, murder, gang, etc.)
- Party/Club culture (club, rave, DJ, etc.)
- Materialism (luxury brands, wealth focus)
- Haram genres (gangsta rap, drill, etc.)

## Build Commands
```bash
flutter pub get
flutter analyze
flutter build apk --release
```

## Firebase Config
- Project: halaltune-6c908
- Web config embedded in main.dart
- Android: google-services.json in android/app/
- iOS: GoogleService-Info.plist in ios/Runner/

## Dependencies
- Audio: just_audio, audio_service, audio_session
- Firebase: firebase_core, firebase_auth, cloud_firestore
- State: provider
- Network: http, dio
- UI: cached_network_image, shimmer, flutter_svg
- Storage: path_provider, shared_preferences
- Auth: google_sign_in
- Misc: intl, url_launcher, share_plus, permission_handler
