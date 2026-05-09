import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Test screen for Firebase Functions
///
/// This screen allows testing all deployed Firebase callable functions:
/// - healthCheck
/// - summarizeFlow
/// - chatFlow
/// - extractFlow
class FirebaseTestScreen extends ConsumerStatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  ConsumerState<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends ConsumerState<FirebaseTestScreen> {
  final _logs = <String>[];
  final _pdfTextController = TextEditingController(
    text: 'This is a sample PDF text for testing purposes. '
        'It contains multiple sentences to simulate actual content.',
  );
  final _questionController = TextEditingController(
    text: 'What is this text about?',
  );
  final _promptController = TextEditingController(
    text: 'Extract the main topic from this text.',
  );

  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $message');
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _testHealthCheck() async {
    _addLog('🔍 Testing healthCheck...');
    setState(() => _isLoading = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('healthCheck');
      final result = await callable();

      final data = result.data as Map<String, dynamic>;
      _addLog('✅ healthCheck SUCCESS:');
      _addLog('  Status: ${data['status']}');
      _addLog('  Version: ${data['version']}');
      _addLog('  Model: ${data['model']}');
      _addLog('  Region: ${data['region']}');
      _addLog('  Features: ${data['features']}');
    } catch (e) {
      _addLog('❌ healthCheck FAILED: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSummarizeFlow() async {
    _addLog('🔍 Testing summarizeFlow...');
    setState(() => _isLoading = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('summarizeFlow');
      final result = await callable.call(<String, dynamic>{
        'pdfText': _pdfTextController.text,
      });

      final data = result.data as Map<String, dynamic>;
      _addLog('✅ summarizeFlow SUCCESS:');
      _addLog('  Model: ${data['model']}');
      _addLog('  Truncated: ${data['truncated'] ?? false}');
      _addLog('  Summary: ${data['summary']}');
    } catch (e) {
      _addLog('❌ summarizeFlow FAILED: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testChatFlow() async {
    _addLog('🔍 Testing chatFlow...');
    setState(() => _isLoading = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('chatFlow');
      final result = await callable.call(<String, dynamic>{
        'pdfText': _pdfTextController.text,
        'question': _questionController.text,
        'history': [],
      });

      final data = result.data as Map<String, dynamic>;
      _addLog('✅ chatFlow SUCCESS:');
      _addLog('  Model: ${data['model']}');
      _addLog('  Response: ${data['response']}');
    } catch (e) {
      _addLog('❌ chatFlow FAILED: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testExtractFlow() async {
    _addLog('🔍 Testing extractFlow...');
    setState(() => _isLoading = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('extractFlow');
      final result = await callable.call(<String, dynamic>{
        'pdfText': _pdfTextController.text,
        'prompt': _promptController.text,
      });

      final data = result.data as Map<String, dynamic>;
      _addLog('✅ extractFlow SUCCESS:');
      _addLog('  Model: ${data['model']}');
      _addLog('  Data: ${data['data']}');
    } catch (e) {
      _addLog('❌ extractFlow FAILED: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runAllTests() async {
    _clearLogs();
    _addLog('🚀 Starting all tests...');

    await _testHealthCheck();
    await Future.delayed(const Duration(seconds: 1));

    await _testSummarizeFlow();
    await Future.delayed(const Duration(seconds: 1));

    await _testChatFlow();
    await Future.delayed(const Duration(seconds: 1));

    await _testExtractFlow();

    _addLog('🏁 All tests completed!');
  }

  @override
  void dispose() {
    _pdfTextController.dispose();
    _questionController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Functions Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _logs.isEmpty ? null : _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Test buttons
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Function Tests',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testHealthCheck,
                          icon: const Icon(Icons.health_and_safety),
                          label: const Text('Test healthCheck'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testSummarizeFlow,
                          icon: const Icon(Icons.summarize),
                          label: const Text('Test summarizeFlow'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testChatFlow,
                          icon: const Icon(Icons.chat),
                          label: const Text('Test chatFlow'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testExtractFlow,
                          icon: const Icon(Icons.code),
                          label: const Text('Test extractFlow'),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _runAllTests,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Run All Tests'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Test data inputs
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Data',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _pdfTextController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'PDF Text',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _questionController,
                          decoration: const InputDecoration(
                            labelText: 'Question (for chatFlow)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _promptController,
                          decoration: const InputDecoration(
                            labelText: 'Prompt (for extractFlow)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Logs
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Logs (${_logs.length})',
                              style: theme.textTheme.titleMedium,
                            ),
                            if (_logs.isNotEmpty)
                              TextButton.icon(
                                onPressed: _clearLogs,
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Clear'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_logs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'No logs yet. Run a test to see results.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            constraints: const BoxConstraints(maxHeight: 400),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                final isError = log.contains('❌') || log.contains('FAILED');
                                final isSuccess = log.contains('✅') || log.contains('SUCCESS');

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    log,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: isError
                                          ? theme.colorScheme.error
                                          : isSuccess
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
