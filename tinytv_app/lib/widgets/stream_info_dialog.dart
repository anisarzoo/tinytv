import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/tv_controller.dart';

class StreamInfoDialog extends StatelessWidget {
  const StreamInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TvController>();
    final current = controller.currentChannel;
    final state = controller.player.state;

    final width = controller.videoWidth ?? state.width;
    final height = controller.videoHeight ?? state.height;
    final resText = (width != null && height != null && width > 0)
        ? '${width}x$height (${controller.streamResolutionLabel})'
        : 'Auto / Unknown';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFF0F1016),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E202C)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: Color(0xFFF43F5E), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stream Diagnostics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Technical feed & player parameters',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                    splashRadius: 16,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFF1C1D26), height: 1),
              const SizedBox(height: 14),

              _buildInfoRow('Channel Name', current?.name ?? 'None'),
              _buildInfoRow('Category', current?.category ?? 'General'),
              _buildInfoRow('Video Resolution', resText),
              _buildInfoRow('Aspect Mode', controller.videoFitLabel),
              _buildInfoRow('Buffering', '${state.bufferingPercentage.round()}%'),
              _buildInfoRow(
                'Audio Info',
                state.audioParams.channels != null
                    ? '${state.audioParams.channels} channels • ${state.audioParams.sampleRate ?? "Auto"} Hz'
                    : 'Default Stereo',
              ),

              const SizedBox(height: 12),

              // Stream URL with copy button
              const Text(
                'Stream URL',
                style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF13141E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        current?.url ?? 'No URL',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFFFB7185)),
                      tooltip: 'Copy URL',
                      splashRadius: 14,
                      onPressed: () {
                        if (current != null) {
                          Clipboard.setData(ClipboardData(text: current.url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Stream URL copied to clipboard',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF181926),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
