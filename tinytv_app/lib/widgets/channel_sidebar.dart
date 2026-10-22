import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tv_controller.dart';
import 'channel_card.dart';
import 'recordings_dialog.dart';
import 'source_selector_dialog.dart';

class ChannelSidebar extends StatefulWidget {
  const ChannelSidebar({super.key});

  @override
  State<ChannelSidebar> createState() => _ChannelSidebarState();
}

class _ChannelSidebarState extends State<ChannelSidebar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat == 'all') return Icons.grid_view_rounded;
    if (cat.contains('movie') || cat.contains('cinema')) return Icons.movie_filter_rounded;
    if (cat.contains('news')) return Icons.newspaper_rounded;
    if (cat.contains('sport')) return Icons.sports_soccer_rounded;
    if (cat.contains('music')) return Icons.music_note_rounded;
    if (cat.contains('kid') || cat.contains('anim')) return Icons.child_care_rounded;
    if (cat.contains('comedy')) return Icons.sentiment_very_satisfied_rounded;
    if (cat.contains('doc')) return Icons.menu_book_rounded;
    if (cat.contains('entertain') || cat.contains('series')) return Icons.live_tv_rounded;
    return Icons.label_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TvController>();

    return Container(
      color: const Color(0xFF0A0A0E),
      child: Column(
        children: [
          // Header: Brand & Action Icons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                // App Logo Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.tv_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 9),

                // Title
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TinyTV',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Live Television',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Favorites count badge
                if (controller.favoriteCount > 0)
                  InkWell(
                    onTap: () => controller.toggleFavoritesOnly(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: controller.favoritesOnly
                            ? const Color(0xFFF43F5E)
                            : const Color(0xFFF43F5E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 11,
                            color: controller.favoritesOnly ? Colors.white : const Color(0xFFF43F5E),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${controller.favoriteCount}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: controller.favoritesOnly ? Colors.white : const Color(0xFFF43F5E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Recordings Library button
                IconButton(
                  icon: Badge(
                    isLabelVisible: controller.recordings.isNotEmpty,
                    label: Text(
                      '${controller.recordings.length}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFFF43F5E),
                    child: const Icon(Icons.video_library_rounded, color: Colors.white70, size: 19),
                  ),
                  tooltip: 'Recordings Library',
                  splashRadius: 16,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const RecordingsDialog(),
                    );
                  },
                ),

                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white60, size: 19),
                  tooltip: 'Reload Playlist',
                  splashRadius: 16,
                  onPressed: () => controller.loadChannels(forceRefresh: true),
                ),

                // Source Settings button
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Color(0xFFF43F5E), size: 19),
                  tooltip: 'Change Source / Country',
                  splashRadius: 16,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SourceSelectorDialog(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Provider selector bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const SourceSelectorDialog(),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          controller.currentSource.badge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFB7185),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.currentSource.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.swap_vert_rounded,
                        color: Color(0xFFF43F5E),
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF13131B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => controller.setSearchQuery(val),
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search channels...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13,
                    height: 1.2,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white38,
                    size: 17,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  suffixIcon: controller.searchQuery.isNotEmpty
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          icon: const Icon(Icons.clear_rounded, size: 15, color: Colors.white60),
                          splashRadius: 14,
                          onPressed: () {
                            _searchController.clear();
                            controller.setSearchQuery('');
                          },
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Category Pills Horizontal List
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: controller.categories.length + 2,
              separatorBuilder: (_, _) => const SizedBox(width: 5),
              itemBuilder: (context, index) {
                // Favorites Pill
                if (index == 0) {
                  final isFavActive = controller.favoritesOnly;
                  return InkWell(
                    onTap: () => controller.toggleFavoritesOnly(),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isFavActive
                            ? const Color(0xFFF43F5E)
                            : const Color(0xFF13131B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isFavActive
                              ? const Color(0xFFF43F5E)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 12,
                            color: isFavActive ? Colors.white : const Color(0xFFF43F5E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Favorites',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isFavActive ? FontWeight.bold : FontWeight.w500,
                              color: isFavActive ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Geo-blocked Filter Pill
                if (index == 1) {
                  final isHidden = controller.hideGeoBlocked;
                  return InkWell(
                    onTap: () => controller.toggleHideGeoBlocked(),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isHidden
                            ? Colors.amber.withValues(alpha: 0.2)
                            : const Color(0xFF13131B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isHidden
                              ? Colors.amber.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHidden ? Icons.vpn_lock_rounded : Icons.lock_open_rounded,
                            size: 11,
                            color: isHidden ? Colors.amber : Colors.white60,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isHidden ? 'Geo: Hidden' : 'Geo: Show All',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isHidden ? FontWeight.bold : FontWeight.w500,
                              color: isHidden ? Colors.amber : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final cat = controller.categories[index - 2];
                final isSelected = !controller.favoritesOnly && controller.selectedCategory == cat;
                final icon = _getCategoryIcon(cat);

                return InkWell(
                  onTap: () {
                    if (controller.favoritesOnly) {
                      controller.toggleFavoritesOnly();
                    }
                    controller.setCategory(cat);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF13131B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF43F5E)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 12,
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Count & Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: Row(
              children: [
                Text(
                  controller.favoritesOnly
                      ? 'FAVORITES (${controller.filteredChannels.length})'
                      : '${controller.selectedCategory.toUpperCase()} (${controller.filteredChannels.length})',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.35),
                    letterSpacing: 0.8,
                  ),
                ),
                if (controller.isLoadingChannels) ...[
                  const Spacer(),
                  const SizedBox(
                    width: 9,
                    height: 9,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF43F5E)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Syncing...',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF1C1D26)),

          // Virtualized Channel List
          Expanded(
            child: controller.isLoadingChannels && controller.allChannels.isEmpty
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFF43F5E),
                      ),
                    ),
                  )
                : controller.filteredChannels.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 38,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'No channels found',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        itemCount: controller.filteredChannels.length,
                        itemExtent: 66.0,
                        itemBuilder: (context, index) {
                          final channel = controller.filteredChannels[index];
                          final isSelected = controller.currentChannel?.url == channel.url;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ChannelCard(
                              channel: channel,
                              index: index,
                              isSelected: isSelected,
                              onTap: () => controller.playChannel(channel),
                              onToggleFavorite: () => controller.toggleFavorite(channel),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
