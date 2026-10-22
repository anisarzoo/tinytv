import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/tv_controller.dart';
import '../widgets/channel_sidebar.dart';
import '../widgets/recordings_dialog.dart';
import '../widgets/sleep_timer_dialog.dart';
import '../widgets/stream_info_dialog.dart';
import '../widgets/video_player_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // CRITICAL BUG FIX: If user is typing in a search bar or any text field,
    // DO NOT intercept letters, space, or shortcuts!
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus.context != null) {
      final isTextField = primaryFocus.context!.findAncestorWidgetOfExactType<EditableText>() != null;
      if (isTextField) {
        // If Escape pressed while searching, unfocus the search bar
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          primaryFocus.unfocus();
        }
        return; // Allow typing in search without triggering shortcuts!
      }
    }

    final controller = context.read<TvController>();

    if (event.logicalKey == LogicalKeyboardKey.space) {
      controller.togglePlayPause();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      controller.playNext();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      controller.playPrevious();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      controller.setVolume(controller.volume + 5);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      controller.setVolume(controller.volume - 5);
    } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
      controller.toggleMute();
    } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
      controller.toggleFullScreen();
    } else if (event.logicalKey == LogicalKeyboardKey.escape && controller.isFullScreen) {
      controller.toggleFullScreen();
    } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
      controller.toggleSidebar();
    } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _toggleRecording(controller);
    } else if (event.logicalKey == LogicalKeyboardKey.keyQ) {
      controller.recallPreviousChannel();
    } else if (event.logicalKey == LogicalKeyboardKey.keyI) {
      showDialog(context: context, builder: (_) => const StreamInfoDialog());
    } else if (event.logicalKey == LogicalKeyboardKey.keyT) {
      showDialog(context: context, builder: (_) => const SleepTimerDialog());
    } else if (event.logicalKey == LogicalKeyboardKey.slash || event.logicalKey == LogicalKeyboardKey.question) {
      _showShortcutsDialog(context);
    }
  }

  void _toggleRecording(TvController controller) {
    if (controller.isRecording) {
      controller.stopRecording().then((saved) {
        if (mounted && saved != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saved "${saved.channelName}" (${saved.formattedFileSize})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'View',
                textColor: const Color(0xFFFB7185),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const RecordingsDialog(),
                ),
              ),
              backgroundColor: const Color(0xFF181926),
            ),
          );
        }
      });
    } else {
      controller.startRecording().then((ok) {
        if (mounted && ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF43F5E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recording started: ${controller.currentChannel?.name ?? "Stream"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: const Color(0xFF181926),
            ),
          );
        }
      });
    }
  }

  void _showShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F1016),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.keyboard_rounded, color: Color(0xFFF43F5E), size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'Keyboard Shortcuts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                _buildShortcutRow('Space', 'Play / Pause Video'),
                _buildShortcutRow('Right Arrow (→)', 'Next Channel'),
                _buildShortcutRow('Left Arrow (←)', 'Previous Channel'),
                _buildShortcutRow('Q', 'Quick Recall (Last Channel)'),
                _buildShortcutRow('Up Arrow (↑)', 'Volume Up (+5%)'),
                _buildShortcutRow('Down Arrow (↓)', 'Volume Down (-5%)'),
                _buildShortcutRow('M', 'Mute / Unmute'),
                _buildShortcutRow('F', 'Toggle Fullscreen Mode'),
                _buildShortcutRow('S', 'Show / Hide Channels Sidebar'),
                _buildShortcutRow('R', 'Start / Stop Stream Recording (DVR)'),
                _buildShortcutRow('I', 'Stream Diagnostics & Technical Info'),
                _buildShortcutRow('T', 'Sleep Timer Countdown'),
                _buildShortcutRow('Esc', 'Exit Fullscreen / Clear Search'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutRow(String keyName, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF181822),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              keyName,
              style: const TextStyle(
                color: Color(0xFFFB7185),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TvController>();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF050507),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 800;

            // Fullscreen Mode
            if (controller.isFullScreen) {
              return const VideoPlayerView();
            }

            // Desktop / Wide Studio Layout (Flush & Connected)
            if (isWideScreen) {
              return Row(
                children: [
                  // Animated Connected Sidebar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    width: controller.showSidebar ? 350 : 0,
                    child: controller.showSidebar ? const ChannelSidebar() : const SizedBox.shrink(),
                  ),

                  // 1px Studio Divider
                  if (controller.showSidebar)
                    Container(
                      width: 1,
                      color: const Color(0xFF1C1D26),
                    ),

                  // Docked Video Player Area (No overlapping floating layers!)
                  const Expanded(
                    child: VideoPlayerView(),
                  ),
                ],
              );
            }

            // Mobile / Portrait Layout
            return const SafeArea(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: VideoPlayerView(),
                  ),
                  Expanded(
                    child: ChannelSidebar(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
