/// Model representing a PDF document in the library
class PdfDocument {
  final String id;
  final String title;
  final String filePath;
  final int fileSize;
  final DateTime createdAt;
  final DateTime lastOpenedAt;
  final int totalPages;
  String? thumbnailPath;
  bool isFavorite;
  ReadingProgress? progress;

  PdfDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileSize,
    required this.createdAt,
    required this.lastOpenedAt,
    required this.totalPages,
    this.thumbnailPath,
    this.isFavorite = false,
    this.progress,
  });

  /// Create from file
  factory PdfDocument.fromFile({
    required String id,
    required String title,
    required String filePath,
    required int fileSize,
    required int totalPages,
  }) {
    final now = DateTime.now();
    return PdfDocument(
      id: id,
      title: title,
      filePath: filePath,
      fileSize: fileSize,
      createdAt: now,
      lastOpenedAt: now,
      totalPages: totalPages,
    );
  }

  /// Calculate reading progress percentage
  double get progressPercentage {
    if (totalPages == 0 || progress == null) return 0.0;
    return progress!.currentPage / totalPages;
  }

  /// Format file size for display
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// From JSON
  factory PdfDocument.fromJson(Map<String, dynamic> json) {
    return PdfDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastOpenedAt: DateTime.parse(json['lastOpenedAt'] as String),
      totalPages: json['totalPages'] as int,
      thumbnailPath: json['thumbnailPath'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      progress: json['progress'] != null
          ? ReadingProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : null,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt.toIso8601String(),
      'totalPages': totalPages,
      'thumbnailPath': thumbnailPath,
      'isFavorite': isFavorite,
      'progress': progress?.toJson(),
    };
  }

  PdfDocument copyWith({
    String? id,
    String? title,
    String? filePath,
    int? fileSize,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
    int? totalPages,
    String? thumbnailPath,
    bool? isFavorite,
    ReadingProgress? progress,
  }) {
    return PdfDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      totalPages: totalPages ?? this.totalPages,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isFavorite: isFavorite ?? this.isFavorite,
      progress: progress ?? this.progress,
    );
  }
}

/// Reading progress for a PDF document
class ReadingProgress {
  final String documentId;
  final int currentPage;
  final DateTime lastReadAt;
  final int scrollOffset;

  ReadingProgress({
    required this.documentId,
    required this.currentPage,
    required this.lastReadAt,
    this.scrollOffset = 0,
  });

  /// From JSON
  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      documentId: json['documentId'] as String,
      currentPage: json['currentPage'] as int,
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
      scrollOffset: json['scrollOffset'] as int? ?? 0,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'currentPage': currentPage,
      'lastReadAt': lastReadAt.toIso8601String(),
      'scrollOffset': scrollOffset,
    };
  }

  ReadingProgress copyWith({
    String? documentId,
    int? currentPage,
    DateTime? lastReadAt,
    int? scrollOffset,
  }) {
    return ReadingProgress(
      documentId: documentId ?? this.documentId,
      currentPage: currentPage ?? this.currentPage,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      scrollOffset: scrollOffset ?? this.scrollOffset,
    );
  }
}
