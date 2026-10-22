import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tv_controller.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TvController>();
    final activeMinutes = controller.activeSleepTimerMinutes;
    final remainingText = controller.formattedSleepTimerRemaining;

    final timerOptions = [
      {'label': 'Turn Off', 'minutes': null},
      {'label': '15 Minutes', 'minutes': 15},
      {'label': '30 Minutes', 'minutes': 30},
      {'label': '45 Minutes', 'minutes': 45},
      {'label': '60 Minutes (1h)', 'minutes': 60},
      {'label': '90 Minutes (1.5h)', 'minutes': 90},
      {'label': '120 Minutes (2h)', 'minutes': 120},
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFF0F1016),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E202C)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
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
                    child: const Icon(Icons.timer_outlined, color: Color(0xFFF43F5E), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sleep Timer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Automatically stop playback',
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

              if (activeMinutes != null && remainingText.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1520),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_on_rounded, color: Color(0xFFF43F5E), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Active: Stopping in $remainingText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(color: Color(0xFF1C1D26), height: 1),
              const SizedBox(height: 10),

              // Options
              ...timerOptions.map((opt) {
                final mins = opt['minutes'] as int?;
                final isSelected = activeMinutes == mins;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: InkWell(
                    onTap: () {
                      controller.setSleepTimer(mins);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF43F5E).withValues(alpha: 0.15)
                            : const Color(0xFF13141E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFF43F5E) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            opt['label'] as String,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFFB7185) : Colors.white,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFF43F5E),
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
