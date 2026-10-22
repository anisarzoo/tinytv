import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../controllers/tv_controller.dart';
import 'live_equalizer.dart';
import 'recordings_dialog.dart';
import 'sleep_timer_dialog.dart';
import 'stream_info_dialog.dart';

class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({super.key});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _onUserInteraction() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }
    _startHideTimer();
  }

  Future<void> _handleStartRecording(BuildContext context, TvController controller) async {
    final success = await controller.startRecording();
    if (context.mounted) {
      if (success) {
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to start recording. Ensure a channel is currently playing.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Color(0xFF181926),
          ),
        );
      }
    }
  }

  Future<void> _handleStopRecording(BuildContext context, TvController controller) async {
    final saved = await controller.stopRecording();
    if (context.mounted && saved != null) {
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
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const RecordingsDialog(),
              );
            },
          ),
          backgroundColor: const Color(0xFF181926),
        ),
      );
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _showMobileOptionsMenu(BuildContext context, TvController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1017),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFF1E202C)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.aspect_ratio_rounded, color: Color(0xFFFB7185)),
                  title: const Text('Aspect Ratio / Fit', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(controller.videoFitLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.cycleVideoFit();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alarm_on_rounded, color: Color(0xFFFB7185)),
                  title: const Text('Sleep Timer', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    controller.activeSleepTimerMinutes != null
                        ? 'Remaining: ${controller.formattedSleepTimerRemaining}'
                        : 'Turn off playback automatically',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(context: context, builder: (_) => const SleepTimerDialog());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Color(0xFFFB7185)),
                  title: const Text('Stream Diagnostics', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text('${controller.streamResolutionLabel} • Audio & Bitrate info', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(context: context, builder: (_) => const StreamInfoDialog());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library_rounded, color: Color(0xFFFB7185)),
                  title: const Text('Recordings Library', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text('${controller.recordings.length} captured broadcasts', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(context: context, builder: (_) => const RecordingsDialog());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TvController>();
    final current = controller.currentChannel;

    return MouseRegion(
      onHover: (_) => _onUserInteraction(),
      child: GestureDetector(
        onTap: _onUserInteraction,
        onDoubleTap: () => controller.toggleFullScreen(),
        child: Container(
          color: Colors.black,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 650;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // MediaKit Video Surface
                  Center(
                    child: Video(
                      controller: controller.videoController,
                      controls: NoVideoControls,
                      fit: controller.videoFit,
                    ),
                  ),

                  // Buffering state (docked subtle center indicator)
                  if (controller.isBuffering && !controller.hasError)
                    Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 38,
                              height: 38,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF43F5E)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              current != null ? current.name : 'Loading Stream...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Error State Overlay (Docked Studio Alert)
                  if (controller.hasError)
                    Container(
                      color: const Color(0xFF07080C).withValues(alpha: 0.95),
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101017),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (current?.isGeoBlocked == true
                                          ? Colors.amber
                                          : const Color(0xFFF43F5E))
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  current?.isGeoBlocked == true
                                      ? Icons.vpn_lock_rounded
                                      : Icons.portable_wifi_off_rounded,
                                  color: current?.isGeoBlocked == true
                                      ? Colors.amber
                                      : const Color(0xFFF43F5E),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                current?.isGeoBlocked == true
                                    ? 'Geo-Blocked Broadcast'
                                    : 'Stream Offline',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                current?.isGeoBlocked == true
                                    ? '${current?.name ?? "This channel"} is restricted by the broadcaster to viewers inside their licensed region (requires a VPN in the broadcaster\'s country).'
                                    : (controller.errorMessage ??
                                        '${current?.name ?? "This channel"} is currently unreachable at source.'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      if (current != null) controller.playChannel(current);
                                    },
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Retry'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () => controller.playNext(),
                                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                                    label: const Text('Next Channel'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF43F5E),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (current?.isGeoBlocked == true && !controller.hideGeoBlocked) ...[
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () {
                                    controller.toggleHideGeoBlocked();
                                    controller.playNext();
                                  },
                                  icon: const Icon(Icons.filter_alt_off_rounded, size: 14),
                                  label: const Text(
                                    'Filter out all Geo-blocked channels',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.amber.shade200,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Docked Flush Overlay Bars
                  AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: Stack(
                        children: [
                          // TOP DOCKED BAR
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 10 : 16,
                                vertical: isCompact ? 6 : 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.9),
                                    Colors.black.withValues(alpha: 0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Sidebar Toggle Button ONLY on desktop / wide screen
                                  if (!isCompact && !controller.isFullScreen)
                                    IconButton(
                                      icon: Icon(
                                        controller.showSidebar
                                            ? Icons.view_sidebar_rounded
                                            : Icons.view_sidebar_outlined,
                                        color: controller.showSidebar
                                            ? const Color(0xFFF43F5E)
                                        : Colors.white70,
                                        size: 20,
                                      ),
                                      tooltip: controller.showSidebar ? 'Hide Channels (S)' : 'Show Channels (S)',
                                      splashRadius: 18,
                                      onPressed: () => controller.toggleSidebar(),
                                    ),

                                  if (!isCompact && !controller.isFullScreen)
                                    const SizedBox(width: 4),

                                  // Live Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF43F5E),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        LiveEqualizer(
                                          color: Colors.white,
                                          size: 8,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Active Recording Badge in Top Bar
                                  if (controller.isRecording) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => _handleStopRecording(context, controller),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE11D48),
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFE11D48).withValues(alpha: 0.5),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'REC ${controller.recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(controller.recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Active Sleep Timer Badge (Desktop only)
                                  if (!isCompact && controller.activeSleepTimerMinutes != null) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => showDialog(
                                        context: context,
                                        builder: (_) => const SleepTimerDialog(),
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1528),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.alarm_on_rounded,
                                              color: Color(0xFFFB7185),
                                              size: 11,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              controller.formattedSleepTimerRemaining,
                                              style: const TextStyle(
                                                color: Color(0xFFFB7185),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(width: 8),

                                  // Channel Number and Name
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          'CH ${controller.currentChannelNumber}',
                                          style: TextStyle(
                                            color: const Color(0xFFFB7185),
                                            fontSize: isCompact ? 11 : 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            current?.name ?? 'TinyTV',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isCompact ? 12.5 : 14,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (!isCompact) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              current?.category ?? 'General',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.6),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E1E2C),
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: Colors.white12),
                                            ),
                                            child: Text(
                                              controller.streamResolutionLabel,
                                              style: const TextStyle(
                                                color: Color(0xFFFB7185),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Desktop: Aspect ratio button
                                  if (!isCompact) ...[
                                    OutlinedButton.icon(
                                      onPressed: () => controller.cycleVideoFit(),
                                      icon: const Icon(Icons.aspect_ratio_rounded, size: 13),
                                      label: Text(
                                        controller.videoFitLabel,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white70,
                                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],

                                  // Favorite Button
                                  if (current != null)
                                    IconButton(
                                      icon: Icon(
                                        current.isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: current.isFavorite
                                            ? const Color(0xFFF43F5E)
                                            : Colors.white70,
                                        size: isCompact ? 18 : 20,
                                      ),
                                      tooltip: current.isFavorite ? 'Remove Favorite' : 'Add to Favorites',
                                      splashRadius: 18,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => controller.toggleFavorite(current),
                                    ),

                                  // Mobile: Options Bottom Sheet trigger
                                  if (isCompact)
                                    IconButton(
                                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 18),
                                      tooltip: 'Stream Options',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => _showMobileOptionsMenu(context, controller),
                                    ),

                                  // Fullscreen Button
                                  IconButton(
                                    icon: Icon(
                                      controller.isFullScreen
                                          ? Icons.fullscreen_exit_rounded
                                          : Icons.fullscreen_rounded,
                                      color: Colors.white,
                                      size: isCompact ? 20 : 22,
                                    ),
                                    tooltip: controller.isFullScreen ? 'Exit Fullscreen (F)' : 'Fullscreen (F)',
                                    splashRadius: 18,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: () => controller.toggleFullScreen(),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // BOTTOM DOCKED BAR
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 10 : 16,
                                vertical: isCompact ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.95),
                                    Colors.black.withValues(alpha: 0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Previous channel
                                  IconButton(
                                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 20),
                                    tooltip: 'Previous Channel (←)',
                                    splashRadius: 18,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: () => controller.playPrevious(),
                                  ),

                                  // Play / Pause
                                  IconButton(
                                    icon: Icon(
                                      controller.isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: const Color(0xFFF43F5E),
                                      size: isCompact ? 28 : 32,
                                    ),
                                    tooltip: controller.isPlaying ? 'Pause (Space)' : 'Play (Space)',
                                    splashRadius: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    onPressed: () => controller.togglePlayPause(),
                                  ),

                                  // Next channel
                                  IconButton(
                                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 20),
                                    tooltip: 'Next Channel (→)',
                                    splashRadius: 18,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: () => controller.playNext(),
                                  ),

                                  // Quick Recall
                                  IconButton(
                                    icon: Icon(
                                      Icons.replay_rounded,
                                      color: controller.canRecall ? Colors.white70 : Colors.white24,
                                      size: 18,
                                    ),
                                    tooltip: controller.canRecall
                                        ? 'Recall: ${controller.previousChannel?.name} (Q)'
                                        : 'Recall Previous Channel (Q)',
                                    splashRadius: 18,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: controller.canRecall
                                        ? () => controller.recallPreviousChannel()
                                        : null,
                                  ),

                                  // Desktop volume controls
                                  if (!isCompact) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        controller.isMuted
                                            ? Icons.volume_off_rounded
                                            : (controller.volume > 50
                                                ? Icons.volume_up_rounded
                                                : Icons.volume_down_rounded),
                                        color: controller.isMuted
                                            ? const Color(0xFFF43F5E)
                                            : Colors.white70,
                                        size: 19,
                                      ),
                                      tooltip: controller.isMuted ? 'Unmute (M)' : 'Mute (M)',
                                      splashRadius: 16,
                                      onPressed: () => controller.toggleMute(),
                                    ),
                                    SizedBox(
                                      width: 75,
                                      child: SliderTheme(
                                        data: SliderThemeData(
                                          trackHeight: 2.5,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                                          activeTrackColor: const Color(0xFFF43F5E),
                                          inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                                          thumbColor: Colors.white,
                                        ),
                                        child: Slider(
                                          value: controller.volume,
                                          min: 0.0,
                                          max: 100.0,
                                          onChanged: (val) => controller.setVolume(val),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${controller.volume.round()}%',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.45),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],

                                  const Spacer(),

                                  // Mobile tap-to-mute button
                                  if (isCompact)
                                    IconButton(
                                      icon: Icon(
                                        controller.isMuted
                                            ? Icons.volume_off_rounded
                                            : Icons.volume_up_rounded,
                                        color: controller.isMuted
                                            ? const Color(0xFFF43F5E)
                                            : Colors.white70,
                                        size: 18,
                                      ),
                                      tooltip: controller.isMuted ? 'Unmute' : 'Mute',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => controller.toggleMute(),
                                    ),

                                  // Live DVR Recording Button (🔴 REC)
                                  if (controller.isRecording)
                                    ElevatedButton.icon(
                                      onPressed: () => _handleStopRecording(context, controller),
                                      icon: const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 14),
                                      label: Text(
                                        'REC ${controller.recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(controller.recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE11D48),
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 10, vertical: 5),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    )
                                  else
                                    OutlinedButton.icon(
                                      onPressed: () => _handleStartRecording(context, controller),
                                      icon: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF43F5E),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      label: const Text('REC', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.6)),
                                        padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 9, vertical: 5),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),

                                  // Desktop: Sleep timer & Stream info
                                  if (!isCompact) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: Icon(
                                        controller.activeSleepTimerMinutes != null
                                            ? Icons.alarm_on_rounded
                                            : Icons.timer_outlined,
                                        color: controller.activeSleepTimerMinutes != null
                                            ? const Color(0xFFF43F5E)
                                            : Colors.white70,
                                        size: 19,
                                      ),
                                      tooltip: controller.activeSleepTimerMinutes != null
                                          ? 'Sleep Timer: ${controller.formattedSleepTimerRemaining}'
                                          : 'Sleep Timer (T)',
                                      splashRadius: 16,
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) => const SleepTimerDialog(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 19),
                                      tooltip: 'Stream Diagnostics (I)',
                                      splashRadius: 16,
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) => const StreamInfoDialog(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
