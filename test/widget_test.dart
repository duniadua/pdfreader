import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_reader_app/main.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PdfReaderApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
