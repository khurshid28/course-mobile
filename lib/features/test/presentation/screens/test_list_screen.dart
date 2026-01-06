import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/test_model.dart';
import '../../data/repositories/test_repository.dart';
import '../screens/test_session_screen.dart';
import '../../../../core/widgets/screenshot_blocker.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/theme/app_colors.dart';

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

      // Debug: Print test data
      print('📊 Loaded ${tests.length} tests:');
      for (var test in tests) {
        print('  - ${test.title}:');
        print('    isAvailable: ${test.isAvailable}');
        print('    availabilityType: ${test.availabilityType}');
        print('    availableAfterDays: ${test.availableAfterDays}');
      }

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
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(8.w),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
              iconSize: 18.sp,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Test sinovlari',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: 3,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: ListItemShimmer(),
              ),
            )
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
          ? _buildEmptyState()
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
    final bool isLocked = !test.isAvailable;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: isLocked
            ? LinearGradient(
                colors: [Colors.grey.shade100, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : isPassed
            ? LinearGradient(
                colors: [Colors.green.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: isPassed
                ? Colors.green.withOpacity(0.2)
                : Colors.blue.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 8,
            offset: Offset(-4, -4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: isLocked
              ? Colors.grey.shade300
              : isPassed
              ? Colors.green.shade200
              : Colors.blue.shade200,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : () => _startTest(test),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        test.title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isLocked
                              ? Colors.grey.shade600
                              : Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    _buildStatusBadge(isLocked, isPassed, hasAttempted),
                  ],
                ),
                SizedBox(height: 16.h),

                // Test info with better design
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildInfoItem(
                            Icons.quiz_outlined,
                            '${test.questions.length} savol',
                            Colors.blue,
                          ),
                          SizedBox(width: 20.w),
                          _buildInfoItem(
                            Icons.timer_outlined,
                            '${test.maxDuration} daq',
                            Colors.orange,
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          _buildInfoItem(
                            Icons.star_outline,
                            'O\'tish: ${test.passingScore}%',
                            Colors.amber,
                          ),
                          SizedBox(width: 20.w),
                          _buildInfoItem(
                            Icons.workspace_premium_outlined,
                            'Sertifikat: ${test.minCorrectAnswers}+',
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Last attempt info with beautiful design
                if (hasAttempted) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPassed
                            ? [Colors.green.shade50, Colors.green.shade100]
                            : [Colors.red.shade50, Colors.red.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isPassed
                            ? Colors.green.shade300
                            : Colors.red.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: isPassed ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isPassed ? Colors.green : Colors.red)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isPassed ? Icons.check_circle : Icons.cancel,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Oxirgi natija',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${test.lastAttempt!.score}% (${test.lastAttempt!.correctAnswers}/${test.lastAttempt!.totalQuestions} to\'g\'ri)',
                                style: TextStyle(
                                  color: isPassed
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Locked message
                if (isLocked) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade50, Colors.orange.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20.sp,
                          color: Colors.orange.shade700,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Testni ochish uchun avval kursni sotib oling',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                              fontSize: 13.sp,
                            ),
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
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isLocked, bool isPassed, bool hasAttempted) {
    if (isLocked) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, color: Colors.grey.shade700, size: 16.sp),
            SizedBox(width: 4.w),
            Text(
              'Qulflangan',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (isPassed) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16.sp),
            SizedBox(width: 4.w),
            Text(
              'O\'tdi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (hasAttempted) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade600],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, color: Colors.white, size: 16.sp),
            SizedBox(width: 4.w),
            Text(
              'Qayta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, color: Colors.white, size: 16.sp),
            SizedBox(width: 4.w),
            Text(
              'Boshlash',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
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

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(32.w),
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.purple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
              spreadRadius: 5,
            ),
          ],
          border: Border.all(color: Colors.blue.shade200, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with gradient background
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 64.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24.h),
            // Title
            Text(
              'Testlar hozircha mavjud emas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12.h),
            // Description
            Text(
              'Bu kurs uchun test sinovlari hali qo\'shilmagan.\nKeyinroq qayta tekshirib ko\'ring.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            // Refresh button
            ElevatedButton.icon(
              onPressed: _loadTests,
              icon: Icon(Icons.refresh, size: 20.sp),
              label: Text(
                'Yangilash',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 4,
                shadowColor: Colors.blue.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
