import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/models/pdf_document.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import 'providers/library_notifier.dart';

enum LibraryTab { library, favorites, timeline, cloud }

class LibraryScreen extends ConsumerStatefulWidget {
  final LibraryTab initialTab;

  const LibraryScreen({super.key, this.initialTab = LibraryTab.library});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryTabNotifierProvider.notifier).setTab(widget.initialTab);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(libraryTabNotifierProvider);
    final libraryState = ref.watch(libraryNotifierProvider);
    final searchQuery = ref.watch(searchQueryNotifierProvider);

    ref.listen<LibraryState>(libraryNotifierProvider, (previous, next) {
      next.failure?.let((failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Theme.of(context).colorScheme.error,
              onPressed: () {
                ref.read(libraryNotifierProvider.notifier).dismissFailure();
              },
            ),
          ),
        );
      });
    });

    final currentIndex = _tabToIndex(currentTab);
    final pdfs = _getPdfsForTab(currentTab, libraryState);
    final filteredPdfs = _filterPdfs(pdfs, searchQuery);

    return Scaffold(
      body: Column(
        children: [
          // Custom Header with Search
          _buildHeader(context, currentTab),

          // Body Content
          Expanded(child: _buildBody(currentTab, libraryState, filteredPdfs)),
        ],
      ),
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddPdfDialog(context),
              backgroundColor: AppTheme.primary,
              elevation: 8,
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigationBar(currentIndex),
    );
  }

  Widget _buildHeader(BuildContext context, LibraryTab tab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppTheme.backgroundDark
        : AppTheme.backgroundLight;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar with avatar, title, and settings
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // Avatar with person icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Text(
                    _buildTitle(tab),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  // Settings button
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => context.push(AppRoutes.settings),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref
                        .read(searchQueryNotifierProvider.notifier)
                        .setQuery(value);
                  },
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search your PDFs, folders, tags...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune, size: 20),
                      onPressed: () {
                        // Show filter options
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(int currentIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppTheme.backgroundDark
        : AppTheme.backgroundLight;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.folder,
                label: 'Library',
                isSelected: currentIndex == 0,
                onTap: () => ref
                    .read(libraryTabNotifierProvider.notifier)
                    .setTab(LibraryTab.library),
              ),
              _buildNavItem(
                icon: Icons.star_border,
                selectedIcon: Icons.star,
                label: 'Favorites',
                isSelected: currentIndex == 1,
                onTap: () => ref
                    .read(libraryTabNotifierProvider.notifier)
                    .setTab(LibraryTab.favorites),
              ),
              _buildNavItem(
                icon: Icons.history,
                label: 'Timeline',
                isSelected: currentIndex == 2,
                onTap: () => ref
                    .read(libraryTabNotifierProvider.notifier)
                    .setTab(LibraryTab.timeline),
              ),
              _buildNavItem(
                icon: Icons.cloud_outlined,
                selectedIcon: Icons.cloud,
                label: 'Cloud',
                isSelected: currentIndex == 3,
                onTap: () => ref
                    .read(libraryTabNotifierProvider.notifier)
                    .setTab(LibraryTab.cloud),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    IconData? selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? (selectedIcon ?? icon) : icon,
            color: isSelected ? AppTheme.primary : const Color(0xFF94A3B8),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.primary : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  String _buildTitle(LibraryTab tab) {
    return switch (tab) {
      LibraryTab.library => 'My Library',
      LibraryTab.favorites => 'Favorites',
      LibraryTab.timeline => 'Recent',
      LibraryTab.cloud => 'Cloud',
    };
  }

  List<PdfDocument> _getPdfsForTab(LibraryTab tab, LibraryState state) {
    return switch (tab) {
      LibraryTab.library => state.allPdfs,
      LibraryTab.favorites => state.favoritePdfs,
      LibraryTab.timeline => state.recentPdfs,
      LibraryTab.cloud => [], // Cloud not implemented
    };
  }

  List<PdfDocument> _filterPdfs(List<PdfDocument> pdfs, String query) {
    if (query.isEmpty) return pdfs;
    final lowerQuery = query.toLowerCase();
    return pdfs.where((pdf) {
      return pdf.title.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Widget _buildBody(
    LibraryTab tab,
    LibraryState state,
    List<PdfDocument> pdfs,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tab == LibraryTab.cloud) {
      return _buildCloudTab();
    }

    if (pdfs.isEmpty) {
      return _buildEmptyState(tab);
    }

    return CustomScrollView(
      slivers: [
        // Recent Section (only for Library tab)
        if (tab == LibraryTab.library && state.recentPdfs.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSectionHeader('Recent', onSeeAll: () {}),
                const SizedBox(height: 12),
                _buildRecentSection(state.recentPdfs),
                const SizedBox(height: 24),
              ],
            ),
          ),

        // All Documents Section header
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSectionHeader(
                  'All Documents (${state.allPdfs.length})',
                  showViewToggle: true,
                  isGridView: _isGridView,
                  onViewToggle: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Document List/Grid
        _isGridView ? _buildDocumentGrid(pdfs) : _buildDocumentList(pdfs),

        // Load More indicator
        if (state.hasMore && !state.isLoading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: state.isLoadingMore
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () => ref
                            .read(libraryNotifierProvider.notifier)
                            .loadMore(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: AppTheme.primary,
                        ),
                        child: const Text('Load More'),
                      ),
              ),
            ),
          ),

        // Bottom spacing
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title, {
    VoidCallback? onSeeAll,
    bool showViewToggle = false,
    bool isGridView = false,
    VoidCallback? onViewToggle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primary,
                ),
              ),
            ),
          if (showViewToggle) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onViewToggle,
              child: Icon(
                isGridView ? Icons.view_list : Icons.grid_view,
                color: isGridView ? AppTheme.primary : const Color(0xFF64748B),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentSection(List<PdfDocument> recentPdfs) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recentPdfs.length,
        itemBuilder: (context, index) {
          final pdf = recentPdfs[index];
          return _buildRecentCard(pdf);
        },
      ),
    );
  }

  Widget _buildRecentCard(PdfDocument pdf) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayTitle = pdf.title.isEmpty ? 'Untitled PDF' : pdf.title;

    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          GestureDetector(
            onTap: () => _openPdf(pdf),
            child: Container(
              width: 170,
              height: 220,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // PDF thumbnail with fallback to icon
                  if (pdf.thumbnailPath != null &&
                      File(pdf.thumbnailPath!).existsSync())
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(pdf.thumbnailPath!),
                        width: 160,
                        height: 213,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 48,
                        color: AppTheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  // Progress bar at bottom
                  if (pdf.progress != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: pdf.progressPercentage,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title and time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRelativeTime(pdf.lastOpenedAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList(List<PdfDocument> pdfs) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final pdf = pdfs[index];
        return _DocumentListItem(
          pdf: pdf,
          onTap: () => _openPdf(pdf),
          onFavoriteToggle: () => _toggleFavorite(pdf.id),
          onDelete: () => _deletePdf(pdf),
        );
      }, childCount: pdfs.length),
    );
  }

  Widget _buildDocumentGrid(List<PdfDocument> pdfs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final pdf = pdfs[index];
          return _buildRecentCard(pdf);
        }, childCount: pdfs.length),
      ),
    );
  }

  Widget _buildEmptyState(LibraryTab tab) {
    return switch (tab) {
      LibraryTab.library => _buildLibraryEmptyState(),
      LibraryTab.favorites => _buildFavoritesEmptyState(),
      LibraryTab.timeline => _buildTimelineEmptyState(),
      LibraryTab.cloud => _buildCloudTab(),
    };
  }

  Widget _buildLibraryEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            'No PDFs yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first PDF',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border,
            size: 64,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the star icon to add PDFs to favorites',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            'No reading history',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            'Cloud sync not available',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is a local-only PDF reader',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  void _openPdf(PdfDocument pdf) {
    // Navigate immediately for better UX
    context.push('${AppRoutes.reader}?pdfId=${pdf.id}');
    // Update lastOpenedAt in background for timeline
    ref.read(libraryNotifierProvider.notifier).markAsOpened(pdf.id);
  }

  void _toggleFavorite(String id) {
    ref.read(libraryNotifierProvider.notifier).toggleFavorite(id);
  }

  void _deletePdf(PdfDocument pdf) {
    ref.read(libraryNotifierProvider.notifier).deletePdf(pdf.id);
  }

  void _showAddPdfDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const _AddPdfDialog());
  }

  int _tabToIndex(LibraryTab tab) {
    return switch (tab) {
      LibraryTab.library => 0,
      LibraryTab.favorites => 1,
      LibraryTab.timeline => 2,
      LibraryTab.cloud => 3,
    };
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'JUST NOW';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} MINS AGO';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'HOUR' : 'HOURS'} AGO';
    } else if (difference.inDays == 1) {
      return 'YESTERDAY';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} DAYS AGO';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// List item for a PDF document - matches Stitch design
class _DocumentListItem extends StatelessWidget {
  const _DocumentListItem({
    required this.pdf,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onDelete,
  });

  final PdfDocument pdf;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  if (pdf.thumbnailPath != null &&
                      File(pdf.thumbnailPath!).existsSync())
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(pdf.thumbnailPath!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 28,
                        color: AppTheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  if (pdf.progress != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(7),
                            bottomRight: Radius.circular(7),
                          ),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: pdf.progressPercentage,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(7),
                                bottomRight: Radius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pdf.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pdf.formattedFileSize} • ${_formatDate(pdf.lastOpenedAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Menu button
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'favorite':
                    onFavoriteToggle();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Icon(
                        pdf.isFavorite ? Icons.star_border : Icons.star,
                        size: 18,
                        color: pdf.isFavorite ? null : Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        pdf.isFavorite
                            ? 'Remove from Favorites'
                            : 'Add to Favorites',
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Dialog for adding a new PDF
class _AddPdfDialog extends ConsumerWidget {
  const _AddPdfDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final libraryState = ref.watch(libraryNotifierProvider);

    return AlertDialog(
      title: Text(
        'Add PDF',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Import from device option
          _buildImportOption(
            context: context,
            isDark: isDark,
            icon: Icons.folder_open,
            title: 'Browse Files',
            subtitle: 'Select PDF from your device',
            onTap: () {
              Navigator.of(context).pop();
              ref.read(libraryNotifierProvider.notifier).importPdf();
            },
          ),
          const SizedBox(height: 12),
          // Info text
          Text(
            'Supported format: .pdf',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: libraryState.isLoading
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildImportOption({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension for letting nullable values
extension LetExtension<T> on T? {
  R? let<R>(R Function(T) callback) {
    final value = this;
    if (value != null) {
      return callback(value);
    }
    return null;
  }
}
