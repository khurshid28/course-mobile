import 'package:flutter/material.dart';
import '../../data/models/test_model.dart';
import '../../data/repositories/test_repository.dart';
import '../screens/test_session_screen.dart';
import '../../../../core/widgets/screenshot_blocker.dart';

class TestListScreen extends StatefulWidget {
  final int courseId;
  final TestRepository repository;

  const TestListScreen({
    Key? key,
    required this.courseId,
    required this.repository,
  }) : super(key: key);

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  List<TestModel>? _tests;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tests = await widget.repository.getCourseTests(widget.courseId);
      setState(() {
        _tests = tests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startTest(TestModel test) async {
    // Availability check
    if (!test.isAvailable) {
      _showAvailabilityDialog(test);
      return;
    }

    // Last attempt check
    if (test.lastAttempt != null) {
      final shouldRetake = await _showRetakeDialog(test.lastAttempt!);
      if (!shouldRetake) return;
    }

    // Start test
    try {
      final session = await widget.repository.startTest(test.id);

      if (!mounted) return;

      // Navigate to test session with screenshot blocker
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenshotBlocker(
            blockScreenshots: true,
            blockScreenRecording: true,
            child: TestSessionScreen(
              session: session,
              repository: widget.repository,
            ),
          ),
        ),
      ).then((_) => _loadTests()); // Refresh after test
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
    }
  }

  void _showAvailabilityDialog(TestModel test) {
    String message = 'Bu test hozircha mavjud emas.';

    switch (test.availabilityType) {
      case 'DAILY':
        message = 'Bu test kunlik mavjud. Keyingi urinish uchun kuting.';
        break;
      case 'WEEKLY':
        message = 'Bu test haftalik mavjud. Keyingi urinish uchun kuting.';
        break;
      case 'MONTHLY':
        message = 'Bu test oylik mavjud. Keyingi urinish uchun kuting.';
        break;
      case 'EVERY_3_DAYS':
        message = 'Bu test har 3 kunda mavjud. Keyingi urinish uchun kuting.';
        break;
      default:
        message = 'Bu test hozircha mavjud emas.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test mavjud emas'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showRetakeDialog(TestResultModel lastAttempt) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Qayta urinib ko\'rish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Siz bu testni avval topshirgansiz:'),
            const SizedBox(height: 12),
            Text(
              'Natija: ${lastAttempt.score}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'To\'g\'ri javoblar: ${lastAttempt.correctAnswers}/${lastAttempt.totalQuestions}',
            ),
            const SizedBox(height: 12),
            const Text('Qayta urinib ko\'rmoqchimisiz?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yo\'q'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ha'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Testlar')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTests,
                    child: const Text('Qayta urinish'),
                  ),
                ],
              ),
            )
          : _tests == null || _tests!.isEmpty
          ? const Center(child: Text('Testlar topilmadi'))
          : RefreshIndicator(
              onRefresh: _loadTests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tests!.length,
                itemBuilder: (context, index) {
                  final test = _tests![index];
                  return _buildTestCard(test);
                },
              ),
            ),
    );
  }

  Widget _buildTestCard(TestModel test) {
    final bool isPassed = test.lastAttempt?.isPassed ?? false;
    final bool hasAttempted = test.lastAttempt != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _startTest(test),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      test.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!test.isAvailable)
                    const Icon(Icons.lock, color: Colors.grey)
                  else if (isPassed)
                    const Icon(Icons.check_circle, color: Colors.green)
                  else if (hasAttempted)
                    const Icon(Icons.refresh, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 12),

              // Test info
              Row(
                children: [
                  const Icon(Icons.quiz, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${test.questions.length} ta savol',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${test.maxDuration} daqiqa',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Passing score
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    'O\'tish bali: ${test.passingScore}%',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.workspace_premium,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sertifikat: ${test.minCorrectAnswers}+ to\'g\'ri',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              // Last attempt info
              if (hasAttempted) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isPassed ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: isPassed ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Oxirgi natija: ${test.lastAttempt!.score}% (${test.lastAttempt!.correctAnswers}/${test.lastAttempt!.totalQuestions})',
                      style: TextStyle(
                        color: isPassed ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              // Availability status
              if (!test.isAvailable) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getAvailabilityText(test.availabilityType),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getAvailabilityText(String? type) {
    switch (type) {
      case 'DAILY':
        return 'Kunlik';
      case 'WEEKLY':
        return 'Haftalik';
      case 'MONTHLY':
        return 'Oylik';
      case 'EVERY_3_DAYS':
        return 'Har 3 kunda';
      case 'YEARLY':
        return 'Yillik';
      default:
        return 'Hozircha mavjud emas';
    }
  }
}
