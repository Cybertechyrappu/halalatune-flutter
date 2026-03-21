import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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

  try {
    if (kIsWeb) {
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
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  _audioHandler = await AudioService.init(
    builder: () => HalalTuneAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.halaltune.audio',
      androidNotificationChannelName: 'HalalTune',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: false,
      // Use the transparent notification icon from drawable/
      androidNotificationIcon: 'drawable/icontrans',
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
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // #000 in CSS
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulse animation for logo
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
                child: const _AppLogo(size: 72, radius: 16),
              ),
            ),
            const SizedBox(height: 28),
            // Custom CSS Spinner
            SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.7)),
                backgroundColor: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
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
  late Animation<Offset> _slide;
  bool _goingToAuth = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, -0.05)).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _goToAuth() {
    _ctrl.reverse().then((_) {
      if (mounted) setState(() => _goingToAuth = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_goingToAuth) {
      // Replicate GSAP y: 50 -> 0 slide-up auth transition
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, val, child) {
          return Opacity(
            opacity: val,
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - val)),
              child: const AuthScreen(),
            ),
          );
        },
      );
    }
    return Scaffold(
      backgroundColor: Colors.black, // #000 in css
      body: SafeArea(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _AppLogo(size: 100, radius: 22),
                  const SizedBox(height: 20),
                  const Text('HalalTune', style: TextStyle(
                    fontFamily: 'Roboto', fontSize: 40, fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary, letterSpacing: -0.5,
                  )),
                  const SizedBox(height: 10),
                  const Text('Pure, distraction-free Islamic audio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily:'Roboto', fontSize:16, color:AppTheme.textSecondary, height:1.5),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => _goToAuth(),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Get Started', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Roboto'
                    )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  final double size;
  final double radius;
  const _AppLogo({required this.size, required this.radius});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset('assets/images/icon.png', width: size, height: size, fit: BoxFit.cover),
    );
  }
}
