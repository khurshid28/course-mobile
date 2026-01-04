import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../data/models/test_model.dart';
import '../../data/repositories/test_repository.dart';

class TestSessionScreen extends StatefulWidget {
  final TestSessionModel session;
  final TestRepository repository;

  const TestSessionScreen({
    Key? key,
    required this.session,
    required this.repository,
  }) : super(key: key);

  @override
  State<TestSessionScreen> createState() => _TestSessionScreenState();
}

class _TestSessionScreenState extends State<TestSessionScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _timerAnimationController;
  Map<int, int> _answers = {};
  int _currentPage = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isSubmitting = false;
  bool _canPopScope = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _answers = Map.from(widget.session.currentAnswers);
    
    // Timer animation controller
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    _startTimer();
    _setSecureScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageController.dispose();
    _timerAnimationController.dispose();
    _removeSecureScreen();
    super.dispose();
  }

  // Screenshot va screen recording blocker
  void _setSecureScreen() {
    // Android FLAG_SECURE
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _removeSecureScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  // Lifecycle observer - app background'ga ketsa timer davom etadi
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App background'da - timer davom etadi
      print('App paused - timer continues in background');
    } else if (state == AppLifecycleState.resumed) {
      // App qaytdi - session statusni yangilaymiz
      _refreshSessionStatus();
    }
  }

  void _startTimer() {
    final expiresAt = widget.session.expiresAt;
    _remainingSeconds = expiresAt.difference(DateTime.now()).inSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _onTimeExpired();
        }
      });
    });
  }

  Future<void> _refreshSessionStatus() async {
    try {
      final status = await widget.repository.getSessionStatus(
        widget.session.sessionId,
      );
      setState(() {
        _remainingSeconds = status['remainingTimeSeconds'] ?? 0;
        if (status['isExpired'] == true) {
          _onTimeExpired();
        }
      });
    } catch (e) {
      print('Error refreshing status: $e');
    }
  }

  void _onTimeExpired() {
    _timer?.cancel();
    _showTimeExpiredDialog();
  }

  void _showTimeExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Vaqt tugadi!'),
        content: const Text(
          'Test uchun ajratilgan vaqt tugadi. Test avtomatik tugallanadi.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _canPopScope = true;
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAnswer(int questionId, int selectedAnswer) async {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    setState(() {
      _answers[questionId] = selectedAnswer;
    });

    try {
      await widget.repository.submitAnswer(
        sessionId: widget.session.sessionId,
        questionId: questionId,
        selectedAnswer: selectedAnswer,
      );
      // Success feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Error submitting answer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Xatolik: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _completeTest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test\'ni tugatish'),
        content: const Text(
          'Test\'ni tugatmoqchimisiz? Tugatlangandan keyin javoblarni o\'zgartira olmaysiz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tugatish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await widget.repository.completeTest(
        widget.session.sessionId,
      );
      _canPopScope = true;

      if (!mounted) return;

      Navigator.of(context).pop();
      _showResultDialog(result);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final isPassed = result['isPassed'] as bool;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPassed ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              ),
              child: Icon(
                isPassed ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: isPassed ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPassed ? '🎉 Tabriklaymiz!' : '😔 Afsuski',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isPassed ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: result['score'] / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPassed ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${result['score']}%',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${result['correctAnswers']}/${result['totalQuestions']}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (result['receivedCertificate'] == true) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[600]!, Colors.amber[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium, size: 32, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sertifikat olish huquqiga ega bo\'ldingiz!',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
                size: 48,
                color: Colors.amber,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sertifikat olish huquqiga ega bo\'ldingiz!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.session.test.questions
      ..sort((a, b) => a.order.compareTo(b.order));

    return PopScope(
      canPop: _canPopScope,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Test\'dan chiqish'),
            content: const Text(
              'Test davom etmoqda. Chiqsangiz test avtomatik tugallanmaydi va vaqt o\'tishda davom etadi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Davom etish'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Chiqish'),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.session.test.title),
          actions: [
            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds < 300
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: _remainingSeconds < 300 ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _remainingSeconds < 300 ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / questions.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            // Progress text
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Savol ${_currentPage + 1} / ${questions.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            // Questions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return _buildQuestionPage(question);
                },
              ),
            ),
            // Navigation buttons
            _buildNavigationButtons(questions.length),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPage(TestQuestionModel question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Text(
            question.question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Options
          ...List.generate(
            question.options.length,
            (index) =>
                _buildOption(question.id, index, question.options[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int questionId, int optionIndex, String optionText) {
    final isSelected = _answers[questionId] == optionIndex;

    return GestureDetector(
      onTap: () => _submitAnswer(questionId, optionIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.blue : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(int totalQuestions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Oldingi'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          // Next / Finish button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (_currentPage < totalQuestions - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeTest();
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _currentPage < totalQuestions - 1
                          ? 'Keyingi'
                          : 'Tugatish',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
