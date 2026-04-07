// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../providers/settings_provider.dart';
import '../../providers/gps_provider.dart';
import '../../providers/track_recorder_provider.dart';
import '../timer/timer_screen.dart';
import '../startline/startline_screen.dart';
import '../data_panel/data_panel_screen.dart';
import '../settings/settings_screen.dart';
import '../../logic/timer_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _applyWakelock();
    _requestGpsPermission();
  }

  void _applyWakelock() {
    final settings = ref.read(settingsProvider).valueOrNull;
    WakelockPlus.toggle(enable: settings?.keepScreenOn ?? true);
  }

  Future<void> _requestGpsPermission() async {
    final granted = await ref.read(gpsServiceProvider).requestPermission();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS toegang geweigerd — locatiefuncties werken niet.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (_, next) {
      WakelockPlus.toggle(enable: next.valueOrNull?.keepScreenOn ?? true);
    });

    // Auto-navigate to configured panel when countdown reaches zero
    ref.listen(timerNotifierProvider, (prev, next) {
      if (prev == null) return;
      final wasCountingDown = prev.remaining > Duration.zero;
      final nowElapsed = next.remaining == Duration.zero;
      if (wasCountingDown && nowElapsed) {
        final target =
            ref.read(settingsProvider).valueOrNull?.afterTimerPanel;
        if (target == 1) {
          _pageController.animateToPage(
            2,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        } else if (target == 2) {
          _pageController.animateToPage(
            3,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    final recorder = ref.watch(trackRecorderProvider);

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: const [
              TimerScreen(),
              StartlineScreen(),
              DataPanelScreen(panelIndex: 1),
              DataPanelScreen(panelIndex: 2),
            ],
          ),
          // Page indicators
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _PageIndicators(current: _currentPage, total: 4),
          ),
          // Top-right overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Row(
              children: [
                if (recorder.isRecording)
                  GestureDetector(
                    onTap: () async => await recorder.stop(),
                    child: Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 24),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  final int current;
  final int total;
  const _PageIndicators({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        );
      }),
    );
  }
}
