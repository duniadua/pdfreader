import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_reader_app/core/data/models/pdf_document.dart';
import 'package:pdf_reader_app/core/data/repositories/pdf_repository.dart';
import 'package:pdf_reader_app/core/data/providers/repository_providers.dart';
import 'package:pdf_reader_app/features/library/presentation/providers/library_notifier.dart';

@GenerateMocks([PdfRepository])
import 'library_notifier_test.mocks.dart';

void main() {
  late MockPdfRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockPdfRepository();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesPdfRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LibraryNotifier', () {
    test('should return initial state with loading true', () async {
      when(mockRepository.getAllPdfs()).thenAnswer(
        (_) async => Result.success([]),
      );
      when(mockRepository.getRecentPdfs(limit: 10)).thenAnswer(
        (_) async => Result.success([]),
      );
      when(mockRepository.getFavoritePdfs()).thenAnswer(
        (_) async => Result.success([]),
      );

      container.read(libraryNotifierProvider.notifier);
      await container.pump();

      final state = container.read(libraryNotifierProvider);
      expect(state.isLoading, false);
      expect(state.allPdfs, isEmpty);
    });

    test('should load PDFs from repository on init', () async {
      final testPdfs = [
        PdfDocument(
          id: '1',
          title: 'Test PDF',
          filePath: '/path/to/test.pdf',
          fileSize: 1024 * 1024,
          createdAt: DateTime(2024, 1, 15),
          lastOpenedAt: DateTime(2024, 1, 15),
          totalPages: 100,
        ),
      ];

      when(mockRepository.getAllPdfs()).thenAnswer(
        (_) async => Result.success(testPdfs),
      );
      when(mockRepository.getRecentPdfs(limit: 10)).thenAnswer(
        (_) async => Result.success(testPdfs),
      );
      when(mockRepository.getFavoritePdfs()).thenAnswer(
        (_) async => Result.success([]),
      );

      container.read(libraryNotifierProvider.notifier);
      await container.pump();

      final state = container.read(libraryNotifierProvider);
      expect(state.isLoading, false);
      expect(state.allPdfs.length, 1);
      verify(mockRepository.getAllPdfs()).called(1);
    });

    test('should set failure state when repository fails', () async {
      when(mockRepository.getAllPdfs()).thenAnswer(
        (_) async => Result.failure(Exception('Failed to load')),
      );

      container.read(libraryNotifierProvider.notifier);
      await container.pump();

      final state = container.read(libraryNotifierProvider);
      expect(state.isLoading, false);
      expect(state.failure, isNotNull);
      expect(state.failure!.message, contains('Failed to load'));
    });
  });

  group('LibraryNotifier.toggleFavorite', () {
    test('should call repository toggleFavorite', () async {
      when(mockRepository.getAllPdfs()).thenAnswer(
        (_) async => Result.success([]),
      );
      when(mockRepository.getRecentPdfs(limit: 10)).thenAnswer(
        (_) async => Result.success([]),
      );
      when(mockRepository.getFavoritePdfs()).thenAnswer(
        (_) async => Result.success([]),
      );
      when(mockRepository.toggleFavorite(any())).thenAnswer(
        (_) async => Result.success(
          PdfDocument(
            id: '1',
            title: 'Test',
            filePath: '/path/test.pdf',
            fileSize: 1024,
            createdAt: DateTime.now(),
            lastOpenedAt: DateTime.now(),
            totalPages: 10,
            isFavorite: true,
          ),
        ),
      );

      container.read(libraryNotifierProvider.notifier);
      await container.pump();
      await container.read(libraryNotifierProvider.notifier).toggleFavorite('test-id');
      await container.pump();

      verify(mockRepository.toggleFavorite('test-id')).called(1);
    });
  });

  group('LibraryNotifier.deletePdf', () {
    test('should call repository deletePdf', () async {
      when(mockRepository.getAllPdfs()).thenAnswer(
        (_) async => Result.success([]),
      );
      when(mockRepository.getRecentPdfs(limit: 10)).thenAnswer(
        (_) async => Result.success([]),
      );
      when(mockRepository.getFavoritePdfs()).thenAnswer(
        (_) async => Result.success([]),
      );
      when(mockRepository.deletePdf(any())).thenAnswer(
        (_) async => Result.success(null),
      );

      container.read(libraryNotifierProvider.notifier);
      await container.pump();
      await container.read(libraryNotifierProvider.notifier).deletePdf('test-id');
      await container.pump();

      verify(mockRepository.deletePdf('test-id')).called(1);
    });
  });

  group('LibraryNotifier.dismissFailure', () {
    test('should dismiss failure state', () async {
      when(mockRepository.getAllPdfs()).thenAnswer(
        (_) async => Result.success([]),
      );

      final notifier = container.read(libraryNotifierProvider.notifier);
      notifier.dismissFailure();

      final state = container.read(libraryNotifierProvider);
      expect(state.failure, isNull);
    });
  });
}
