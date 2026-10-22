import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/channel.dart';
import 'live_equalizer.dart';

class ChannelCard extends StatefulWidget {
  final Channel channel;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final channel = widget.channel;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SizedBox(
        height: 60,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            hoverColor: const Color(0xFF181824).withValues(alpha: 0.5),
            splashColor: const Color(0xFFF43F5E).withValues(alpha: 0.15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? const Color(0xFF1B1218)
                    : (_isHovered
                        ? const Color(0xFF14141E)
                        : const Color(0xFF0F1016)),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF43F5E)
                      : (_isHovered
                          ? const Color(0xFFF43F5E).withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.05)),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Channel Number
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${widget.index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFFF43F5E)
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Logo
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFF07070A),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF43F5E).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: channel.logo != null && channel.logo!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: channel.logo!,
                            fit: BoxFit.contain,
                            memCacheWidth: 76,
                            memCacheHeight: 76,
                            maxWidthDiskCache: 120,
                            maxHeightDiskCache: 120,
                            placeholder: (_, _) => const Center(
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Color(0xFFF43F5E),
                                ),
                              ),
                            ),
                            errorWidget: (_, _, _) => const Icon(
                              Icons.live_tv_rounded,
                              size: 18,
                              color: Color(0xFF475569),
                            ),
                          )
                        : const Icon(
                            Icons.live_tv_rounded,
                            size: 18,
                            color: Color(0xFF475569),
                          ),
                  ),

                  const SizedBox(width: 10),

                  // Title & Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          channel.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFFB7185)
                                : (_isHovered ? Colors.white : const Color(0xFFE2E8F0)),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (isSelected) ...[
                              const LiveEqualizer(
                                color: Color(0xFFF43F5E),
                                size: 9,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'PLAYING',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFF43F5E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                channel.category ?? 'General',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? const Color(0xFF94A3B8)
                                      : Colors.white.withValues(alpha: 0.4),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (channel.isGeoBlocked) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_outline_rounded, color: Colors.amber, size: 8),
                                    SizedBox(width: 2),
                                    Text(
                                      'GEO',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (channel.isOffline) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'OFFLINE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white38,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Favorite Button
                  IconButton(
                    icon: Icon(
                      channel.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 17,
                      color: channel.isFavorite
                          ? const Color(0xFFF43F5E)
                          : (_isHovered
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.15)),
                    ),
                    splashRadius: 16,
                    tooltip: channel.isFavorite ? 'Remove Favorite' : 'Add to Favorites',
                    onPressed: widget.onToggleFavorite,
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
