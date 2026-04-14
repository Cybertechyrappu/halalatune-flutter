import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../providers/auth_provider.dart';
import '../services/download_service.dart';
import '../widgets/mini_player.dart';
import 'home_tab.dart';
import 'categories_tab.dart';
import 'library_tab.dart';
import 'account_tab.dart';
import 'youtube_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _libInit = false;

  // Use const so IndexedStack doesn't recreate widgets
  static const _tabs = [
    HomeTab(),
    CategoriesTab(),
    YouTubeTab(),
    LibraryTab(),
    AccountTab(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final player = context.read<PlayerProvider>();
    if (auth.user != null && !_libInit) {
      _libInit = true;
      lib.init(auth.user!.uid);
      player.setUserId(auth.user!.uid);
      // Initialise download cache
      DownloadService().init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: DownloadService(),
      child: Scaffold(
        backgroundColor: Colors.black, // #000 in css
        extendBody: true, // Allow body to stretch behind the floating nav
        body: Stack(
          children: [
            // Tabs
            IndexedStack(index: _index, children: _tabs),
            
            // MiniPlayer above Nav Bubble
            const Positioned(
              left: 0, right: 0, bottom: 90, // Spaced above the nav bubble
              child: MiniPlayer(),
            ),

            // Floating Nav Bubble
            Positioned(
              bottom: 24, // Roughly 3vh
              left: 0,
              right: 0,
              child: Center(
                child: _AmoledNavBar(
                  selectedIndex: _index,
                  onTap: (i) => setState(() => _index = i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating AMOLED Nav Bubble with Sliding Pill ──────────────────────────────
class _AmoledNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _AmoledNavBar({required this.selectedIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded,    'Home'),
    (Icons.grid_view_rounded, 'Categories'),
    (Icons.play_circle_rounded, 'YouTube'),
    (Icons.library_music_rounded, 'Library'),
    (Icons.person_rounded,  'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    // Media query safe max-width and constraints matching .bn-bubble
    final width = MediaQuery.of(context).size.width * 0.92;
    final maxWidth = width > 400.0 ? 400.0 : width;
    final btnWidth = maxWidth / _items.length;

    return Container(
      width: maxWidth,
      height: 64, // .bn-bubble height
      decoration: BoxDecoration(
        color: const Color(0x99282828), // rgba(40,40,40,0.6)
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)), // border
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Stack(
        children: [
          // Active Pill (Animated)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack, // approx ease: 'back.out(1.2)'
            top: 2, bottom: 2,
            left: (btnWidth * selectedIndex) + 2,
            width: btnWidth - 4, // inset slightly
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
            ),
          ),
          
          // Icons & Text
          Row(
            children: List.generate(_items.length, (i) {
              final (iconData, label) = _items[i];
              final active = i == selectedIndex;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: SizedBox(
                  width: btnWidth,
                  height: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Icon(iconData, color: active ? Colors.black : Colors.white.withValues(alpha: 0.6), size: 22),
                    const SizedBox(height: 3),
                    Text(label, style: TextStyle(
                      fontFamily: 'Roboto', fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? Colors.black : Colors.white.withValues(alpha: 0.6),
                    )),
                  ]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
