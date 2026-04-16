# Halalatune

### Halal YouTube Music Client for Android

<br/>

[![License](https://img.shields.io/github/license/Halalatune/halalatune?style=for-the-badge&labelColor=0d1117)](https://github.com/Halalatune/halalatune/blob/main/LICENSE)

<br/>

Halalatune is a 3rd party YouTube Music client for Android with built-in halal content filtering. It allows users to enjoy YouTube Music while filtering out content that doesn't align with Islamic principles.

## Features

- **Halal Content Filtering** - Filter YouTube Music content based on Islamic principles with three filter levels (Strict, Moderate, Light)
- **YouTube Music Integration** - Full access to YouTube Music library, search, and streaming
- **Material 3 Design** - Beautiful, modern UI following Material Design 3 guidelines
- **Background Playback** - Stream music in the background with full playback controls
- **Offline Downloads** - Download songs for offline listening
- **Lyrics Support** - Synchronized lyrics from multiple providers

## Halal Filter

The halal filter is unique to Halalatune and filters content based on:

- Explicit content (marked by YouTube)
- Alcohol and drug references
- Gambling themes
- Inappropriate/sexual content
- Violence and harmful themes
- Party/club culture references

Filter levels:
- **Strict**: Maximum filtering - only clearly halal content passes
- **Moderate**: Balanced filtering - blocks obvious haram content
- **Light**: Minimal filtering - only blocks explicit content

## Building

The project uses Gradle. Build using:

```bash
./gradlew :app:assembleFossDebug
```

APK will be generated at `app/build/outputs/apk/foss/debug/`

## License

This project is licensed under the GPL-3.0 License.

## Disclaimer

This project is **not affiliated with, funded, authorized, endorsed by, or associated** with YouTube, Google LLC, or any of their affiliates and subsidiaries.

All trademarks, service marks, and intellectual property rights referenced in this project belong to their respective owners.