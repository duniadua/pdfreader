import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;
import 'package:screen_brightness/screen_brightness.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf_reader_app/features/auth/presentation/providers/auth_notifier.dart'
    as auth;

import '../../../../core/data/models/pdf_document.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';
import 'providers/pdf_reader_notifier.dart';
import 'providers/pdf_chat_notifier.dart';
import 'widgets/pdf_chat_panel.dart';

/// PDF Reader Screen - displays PDF documents with full functionality
class PdfReaderScreen extends ConsumerStatefulWidget {
  final String pdfId;

  const PdfReaderScreen({super.key, required this.pdfId});

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  // Feature states
  int _rotationCount = 0; // 0, 1, 2, 3 (x90 degrees)
  double _brightness = 0.5;
  List<_PdfBookmark> _bookmarks = [];
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    // Load bookmarks after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookmarks();
      // Track screen view
      AnalyticsService.instance.trackScreenView(
        screenName: 'PdfReaderScreen',
        screenClass: 'PdfReaderScreen',
      );
    });
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pdfReaderNotifierProvider(widget.pdfId));

    return Scaffold(
      appBar: _buildAppBar(state),
      body: _buildBody(state),
      bottomNavigationBar: _buildToolbar(state),
    );
  }

  /// Build app bar based on PDF reader state
  PreferredSizeWidget _buildAppBar(PdfReaderState state) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: state.when(
        loading: () => const Text('Loading...'),
        loaded: (pdf) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pdf.title,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Read Only',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        notFound: () => const Text('PDF Not Found'),
        fileNotFound: (_) => const Text('File Not Found'),
        error: (_) => const Text('Error'),
      ),
      actions: state.maybeWhen(
        loaded: (pdf) => [
          IconButton(
            icon: Icon(
              pdf.isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: pdf.isFavorite ? AppTheme.primary : null,
            ),
            onPressed: () {
              ref
                  .read(pdfReaderNotifierProvider(widget.pdfId).notifier)
                  .toggleFavorite();
            },
            tooltip: 'Bookmark',
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, size: 20),
            onPressed: () => _showChatPanel(pdf),
            tooltip: 'AI Assistant',
          ),
          _buildMoreButton(pdf),
        ],
        orElse: () => [],
      ),
    );
  }

  /// Build more options menu
  Widget _buildMoreButton(PdfDocument pdf) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz),
      onSelected: (value) {
        switch (value) {
          case 'info':
            _showPdfInfo(pdf);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'info',
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 12),
              Text('PDF Info'),
            ],
          ),
        ),
      ],
    );
  }

  /// Build body based on PDF reader state
  Widget _buildBody(PdfReaderState state) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      loaded: (pdf) {
        // Initialize page tracking from PDF
        _totalPages = pdf.totalPages;
        _currentPage = pdf.progress?.currentPage ?? 1;

        return Stack(
          children: [
            // PDF Viewer with rotation support
            Transform.rotate(
              angle: _rotationCount * 90 * 3.14159 / 180,
              child: SfPdfViewer.file(
                File(pdf.filePath),
                key: _pdfViewerKey,
                controller: _pdfViewerController,
                onPageChanged: (pageDetails) {
                  ref
                      .read(pdfReaderNotifierProvider(widget.pdfId).notifier)
                      .onPageChanged(pageDetails.newPageNumber);
                  // Update local state for page indicator
                  if (mounted) {
                    setState(() {
                      _currentPage = pageDetails.newPageNumber;
                      _totalPages = _pdfViewerController.pageCount;
                    });
                  }
                },
                canShowScrollHead: true,
                canShowScrollStatus: true,
                pageSpacing: 4,
                initialPageNumber: pdf.progress?.currentPage ?? 1,
              ),
            ),
            // Page indicator overlay
            Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              child: Center(child: _buildPageIndicator(pdf)),
            ),
          ],
        ); // End Stack
      }, // End loaded callback
      notFound: () => _buildErrorView(
        icon: Icons.search_off,
        title: 'PDF Not Found',
        message: 'The PDF document you are looking for does not exist.',
        actionLabel: 'Go Back',
        onAction: () => Navigator.of(context).pop(),
      ),
      fileNotFound: (path) => _buildErrorView(
        icon: Icons.folder_open,
        title: 'File Not Found',
        message: 'The PDF file was moved or deleted from:\n$path',
        actionLabel: 'Go Back',
        onAction: () => Navigator.of(context).pop(),
      ),
      error: (message) => _buildErrorView(
        icon: Icons.error_outline,
        title: 'Error Loading PDF',
        message: message,
        actionLabel: 'Retry',
        onAction: () {
          ref.read(pdfReaderNotifierProvider(widget.pdfId).notifier).retry();
        },
      ),
    );
  }

  /// Build page indicator overlay
  Widget _buildPageIndicator(PdfDocument pdf) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        '$_currentPage of $_totalPages',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Build error view
  Widget _buildErrorView({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }

  /// Build bottom toolbar
  Widget? _buildToolbar(PdfReaderState state) {
    return state.maybeWhen(
      loaded: (pdf) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page scrubber
              _buildPageScrubber(pdf),
              // Toolbar buttons
              _buildToolbarButtons(),
            ],
          ),
        ),
      ),
      orElse: () => null,
    );
  }

  /// Build page scrubber slider
  Widget _buildPageScrubber(PdfDocument pdf) {
    // Use (_totalPages - 1) so last page maps to slider value 1.0
    final scrollPosition = _totalPages > 1
        ? (_currentPage - 1) / (_totalPages - 1)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Text('$_currentPage', style: const TextStyle(fontSize: 10)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: scrollPosition,
                onChanged: (value) {
                  final newPage = (value * (_totalPages - 1)).round() + 1;
                  // Update _currentPage immediately for responsive indicator
                  setState(() {
                    _currentPage = newPage.clamp(1, _totalPages);
                  });
                  _pdfViewerController.jumpToPage(newPage);
                },
              ),
            ),
          ),
          Text('$_totalPages', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// Build toolbar buttons
  Widget _buildToolbarButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolbarItem(Icons.view_list, 'Contents', () {
            final state = ref.read(pdfReaderNotifierProvider(widget.pdfId));
            state.maybeWhen(
              loaded: (pdf) => _showTableOfContents(pdf),
              orElse: () {},
            );
          }),
          _buildToolbarItem(Icons.brightness_6, 'Brightness', () {
            _showBrightnessDialog();
          }),
          _buildToolbarItem(Icons.crop_rotate, 'Rotate', () {
            _rotatePage();
          }),
          _buildToolbarItem(Icons.zoom_in, 'Zoom', () {
            _showZoomDialog();
          }),
          _buildToolbarItem(Icons.share, 'Share', () {
            final state = ref.read(pdfReaderNotifierProvider(widget.pdfId));
            state.maybeWhen(loaded: (pdf) => _sharePdf(pdf), orElse: () {});
          }),
        ],
      ),
    );
  }

  /// Build toolbar item
  Widget _buildToolbarItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show table of contents with PDF bookmarks
  Future<void> _showTableOfContents(PdfDocument pdf) async {
    if (_bookmarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This PDF has no table of contents')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Table of Contents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Bookmark list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) => _BookmarkItem(
                    bookmark: _bookmarks[index],
                    onTap: (page) {
                      _pdfViewerController.jumpToPage(page + 1);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Load PDF bookmarks from document
  Future<void> _loadBookmarks() async {
    final state = ref.read(pdfReaderNotifierProvider(widget.pdfId));
    state.maybeWhen(
      loaded: (pdf) async {
        try {
          final File file = File(pdf.filePath);
          final bytes = await file.readAsBytes();
          // Use the factory constructor correctly
          final sync_pdf.PdfDocument document = sync_pdf.PdfDocument(
            inputBytes: bytes,
          );
          final sync_pdf.PdfBookmarkBase bookmark = document.bookmarks;
          final bookmarks = _parseBookmarks(bookmark, document);
          if (mounted) {
            setState(() => _bookmarks = bookmarks);
          }
          document.dispose();
        } catch (e) {
          // PDF doesn't have bookmarks or failed to parse
          if (mounted) {
            setState(() => _bookmarks = []);
          }
        }
      },
      orElse: () {},
    );
  }

  /// Parse PDF bookmarks recursively
  List<_PdfBookmark> _parseBookmarks(
    sync_pdf.PdfBookmarkBase bookmark,
    sync_pdf.PdfDocument document,
  ) {
    final List<_PdfBookmark> result = [];
    for (int i = 0; i < bookmark.count; i++) {
      final item = bookmark[i];
      int pageNumber = 1; // Default to first page

      // Try to get page number from destination
      try {
        final destination = item.destination;
        if (destination != null) {
          // Store destination for later navigation
          // For now, just use a placeholder - actual navigation
          // would require more complex handling
          pageNumber = 1;
        }
      } catch (_) {
        pageNumber = 1;
      }

      result.add(
        _PdfBookmark(
          title: item.title,
          pageNumber: pageNumber,
          children: item.count > 0 ? _parseBookmarks(item, document) : [],
        ),
      );
    }
    return result;
  }

  /// Show brightness control dialog
  Future<void> _showBrightnessDialog() async {
    try {
      final initialBrightness = await ScreenBrightness.instance.application;
      setState(() => _brightness = initialBrightness);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Brightness'),
          content: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.brightness_6, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                  ),
                  child: Slider(
                    value: _brightness,
                    onChanged: (value) async {
                      setDialogState(() => _brightness = value);
                      await ScreenBrightness.instance
                          .setApplicationScreenBrightness(value);
                      // Track brightness change
                      final level = value < 0.2
                          ? 'min'
                          : value < 0.4
                          ? 'low'
                          : value < 0.6
                          ? 'medium'
                          : value < 0.8
                          ? 'high'
                          : 'max';
                      AnalyticsService.instance.trackBrightnessChange(
                        level: level,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_brightness * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await ScreenBrightness.instance
                    .resetApplicationScreenBrightness();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to adjust brightness: $e')),
      );
    }
  }

  /// Rotate PDF viewer 90 degrees clockwise
  void _rotatePage() {
    setState(() => _rotationCount = (_rotationCount + 1) % 4);
    // Track rotation change
    final degrees = _rotationCount * 90;
    AnalyticsService.instance.trackRotationChange(degrees: degrees);
  }

  /// Show zoom dialog
  void _showZoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zoom Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('50%'),
              onTap: () {
                _pdfViewerController.zoomLevel = 0.5;
                AnalyticsService.instance.trackZoomChange(zoomLevel: 0.5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('100%'),
              onTap: () {
                _pdfViewerController.zoomLevel = 1.0;
                AnalyticsService.instance.trackZoomChange(zoomLevel: 1.0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('150%'),
              onTap: () {
                _pdfViewerController.zoomLevel = 1.5;
                AnalyticsService.instance.trackZoomChange(zoomLevel: 1.5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('200%'),
              onTap: () {
                _pdfViewerController.zoomLevel = 2.0;
                AnalyticsService.instance.trackZoomChange(zoomLevel: 2.0);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show PDF info dialog
  void _showPdfInfo(PdfDocument pdf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Title', pdf.title),
            const SizedBox(height: 8),
            _infoRow('File Size', pdf.formattedFileSize),
            const SizedBox(height: 8),
            _infoRow('Total Pages', '${pdf.totalPages}'),
            const SizedBox(height: 8),
            _infoRow('Created', _formatDate(pdf.createdAt)),
            const SizedBox(height: 8),
            _infoRow('Last Opened', _formatDate(pdf.lastOpenedAt)),
            const SizedBox(height: 8),
            _infoRow('File Path', pdf.filePath, maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Share PDF file
  Future<void> _sharePdf(PdfDocument pdf) async {
    final file = File(pdf.filePath);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File not found')));
      return;
    }

    try {
      // Use the non-deprecated Share.shareXFiles
      await Share.shareXFiles([
        XFile(file.path, name: pdf.title, mimeType: 'application/pdf'),
      ], subject: pdf.title);
      // Track share
      AnalyticsService.instance.trackPdfShare(
        pdfId: pdf.id,
        method: 'share_intent',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
    }
  }

  /// Show AI chat panel for PDF interaction
  Future<void> _showChatPanel(PdfDocument pdf) async {
    AppLogger.i('=== _showChatPanel called ===');
    AppLogger.i('PDF title: ${pdf.title}');
    AppLogger.i('widget.pdfId: ${widget.pdfId}');
    AppLogger.i('pdf.id: ${pdf.id}');
    AppLogger.i('pdf.filePath: ${pdf.filePath}');
    AppLogger.i('IDs match: ${widget.pdfId == pdf.id}');
    AppLogger.i('Provider ID: pdfChatNotifierProvider(${widget.pdfId})');

    // Check if user is authenticated
    final authState = ref.read(auth.authNotifierProvider);
    final isAuthenticated = authState.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );

    if (!isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in with Google to use AI features'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Initialize with PDF FIRST (before opening panel)
    AppLogger.i('Calling initializeWithPdf()...');
    await ref
        .read(pdfChatNotifierProvider(widget.pdfId).notifier)
        .initializeWithPdf(pdf);
    AppLogger.i('✅ initializeWithPdf completed');

    // Open the chat panel state AFTER PDF is initialized
    AppLogger.i('Calling openPanel()...');
    ref.read(pdfChatNotifierProvider(widget.pdfId).notifier).openPanel();
    AppLogger.i('✅ openPanel completed');

    if (!mounted) return;

    AppLogger.i('Showing modal bottom sheet...');
    // Show the modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.98,
        expand: false,
        builder: (context, scrollController) => PdfChatPanel(
          pdfId: widget.pdfId,
          pdfPath: pdf.filePath,
          pdfTitle: pdf.title,
        ),
      ),
    );

    // Track AI chat open (optional - analytics would be tracked in production)
    AppLogger.i('AI chat opened for PDF: ${widget.pdfId}');
  }
}

/// PDF Bookmark data class
class _PdfBookmark {
  final String title;
  final int pageNumber;
  final List<_PdfBookmark> children;

  _PdfBookmark({
    required this.title,
    required this.pageNumber,
    this.children = const [],
  });
}

/// Bookmark item widget for table of contents
class _BookmarkItem extends StatelessWidget {
  final _PdfBookmark bookmark;
  final Function(int) onTap;
  final int depth;

  const _BookmarkItem({
    required this.bookmark,
    required this.onTap,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            bookmark.title,
            style: TextStyle(
              fontSize: (14 - depth.clamp(0, 2)).toDouble(),
              fontWeight: depth == 0 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          leading: depth == 0
              ? const Icon(Icons.bookmark_border, size: 20)
              : null,
          contentPadding: EdgeInsets.only(
            left: 16.0 + (depth * 20.0),
            right: 16.0,
          ),
          onTap: () => onTap(bookmark.pageNumber),
        ),
        if (bookmark.children.isNotEmpty)
          ...bookmark.children.map(
            (child) =>
                _BookmarkItem(bookmark: child, onTap: onTap, depth: depth + 1),
          ),
      ],
    );
  }
}
