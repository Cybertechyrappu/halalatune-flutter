import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../providers/auth_provider.dart';
import '../services/download_service.dart';
import '../widgets/mini_player.dart';
import '../theme/app_theme.dart';
import 'home_tab.dart';
import 'categories_tab.dart';
import 'library_tab.dart';
import 'account_tab.dart';

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
        backgroundColor: AppTheme.bg,
        // Use IndexedStack to keep tab state alive (no rebuild on tab switch)
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            _AmoledNavBar(
              selectedIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pure AMOLED nav bar (lighter than NavigationBar for perf) ──────────────────
class _AmoledNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _AmoledNavBar({required this.selectedIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined,           Icons.home_rounded,    'Home'),
    (Icons.grid_view_outlined,      Icons.grid_view_rounded,'Browse'),
    (Icons.library_music_outlined,  Icons.library_music_rounded,'Library'),
    (Icons.person_outline_rounded,  Icons.person_rounded,  'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppTheme.bgCard,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_items.length, (i) {
              final (outIcon, selIcon, label) = _items[i];
              final active = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(active ? selIcon : outIcon,
                      color: active ? AppTheme.accent : AppTheme.textDim, size: 22),
                    const SizedBox(height: 2),
                    Text(label, style: TextStyle(
                      fontFamily: 'Outfit', fontSize: 9,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? AppTheme.accent : AppTheme.textDim,
                    )),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
