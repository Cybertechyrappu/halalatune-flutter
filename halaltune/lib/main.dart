import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'providers/auth_provider.dart' as auth_p;
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

late HalalTuneAudioHandler _audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD7bc74wJSIRi1_BhDqFjEMG2mE3noBm4g",
      authDomain: "halaltune-6c908.firebaseapp.com",
      projectId: "halaltune-6c908",
      storageBucket: "halaltune-6c908.firebasestorage.app",
      messagingSenderId: "159242961546",
      appId: "1:159242961546:web:65bdcd9c3fee61c661e373",
    ),
  );

  _audioHandler = await AudioService.init(
    builder: () => HalalTuneAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.halaltune.audio',
      androidNotificationChannelName: 'HalalTune',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: false,
      // Use the transparent notification icon from drawable/
      androidNotificationIcon: 'drawable/notification_icon',
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
      preloadArtwork: true,
    ),
  );

  runApp(HalalTuneApp(audioHandler: _audioHandler));
}

// ── Full AudioHandler – handles ALL media button/notification actions ───────────
class HalalTuneAudioHandler extends BaseAudioHandler with SeekHandler {
  // The player provider registers itself here so we can call back into it
  PlayerProvider? _playerProvider;

  void registerPlayer(PlayerProvider p) {
    _playerProvider = p;
  }

  @override
  Future<void> play() async => _playerProvider?.externalPlay();

  @override
  Future<void> pause() async => _playerProvider?.externalPause();

  @override
  Future<void> skipToNext() async => _playerProvider?.playNext();

  @override
  Future<void> skipToPrevious() async => _playerProvider?.playPrev();

  @override
  Future<void> seek(Duration position) async => _playerProvider?.seekToDuration(position);

  @override
  Future<void> stop() async {
    _playerProvider?.externalPause();
    await super.stop();
  }

  // Called by PlayerProvider to push state to the notification
  void pushMediaItem(MediaItem item) => mediaItem.add(item);

  void pushPlaybackState(PlaybackState state) => playbackState.add(state);
}

// ── App ────────────────────────────────────────────────────────────────────────
class HalalTuneApp extends StatelessWidget {
  final HalalTuneAudioHandler audioHandler;
  const HalalTuneApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth_p.AuthProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider(audioHandler: audioHandler)),
      ],
      child: MaterialApp(
        title: 'HalalTune',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const _RootRouter(),
      ),
    );
  }
}

// ── Root Router ────────────────────────────────────────────────────────────────
class _RootRouter extends StatefulWidget {
  const _RootRouter();
  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _showSplash = false);
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return FadeTransition(opacity: ReverseAnimation(_fade), child: const _SplashScreen());
    }
    return Consumer<auth_p.AuthProvider>(
      builder: (_, auth, __) {
        if (auth.isLoading) return const _SplashScreen();
        if (auth.isSignedIn) return const MainShell();
        return const _IntroScreen();
      },
    );
  }
}

// ── Splash ─────────────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _AppLogo(size: 80),
          SizedBox(height: 20),
          Text('HalalTune', style: TextStyle(
            fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          )),
          SizedBox(height: 40),
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(
            strokeWidth: 1.5, color: AppTheme.accent,
          )),
        ]),
      ),
    );
  }
}

// ── Intro ──────────────────────────────────────────────────────────────────────
class _IntroScreen extends StatefulWidget {
  const _IntroScreen();
  @override
  State<_IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<_IntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  bool _goingToAuth = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_goingToAuth) return const AuthScreen();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const _AppLogo(size: 100),
                const SizedBox(height: 24),
                const Text('HalalTune', style: TextStyle(
                  fontFamily: 'Outfit', fontSize: 30, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary, letterSpacing: -0.5,
                )),
                const SizedBox(height: 10),
                const Text('Pure, distraction-free Islamic audio.\nNasheeds · Recitations · Anasheed',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily:'Outfit', fontSize:14, color:AppTheme.textSecondary, height:1.6),
                ),
                const Spacer(flex: 2),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _chip(Icons.music_note_rounded, 'Nasheeds'),
                  const SizedBox(width: 8),
                  _chip(Icons.favorite_rounded, 'Halal only'),
                  const SizedBox(width: 8),
                  _chip(Icons.offline_bolt_rounded, 'Offline'),
                ]),
                const SizedBox(height: 36),
                FilledButton(
                  onPressed: () => setState(() => _goingToAuth = true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Outfit'),
                  ),
                  child: const Text('Get Started'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppTheme.bgElevated,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.surfaceHigh),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppTheme.textSecondary, size: 13),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontFamily: 'Outfit')),
    ]),
  );
}

class _AppLogo extends StatelessWidget {
  final double size;
  const _AppLogo({required this.size});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset('assets/images/icon.png', width: size, height: size, fit: BoxFit.cover),
    );
  }
}
