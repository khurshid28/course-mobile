import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/test_remote_datasource.dart';
import '../../../test/presentation/screens/certificate_list_screen.dart';

class ResultsPage extends StatefulWidget {
  final int initialTab;

  const ResultsPage({super.key, this.initialTab = 0});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _testResults = [];
  List<Map<String, dynamic>> _certificates = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadResults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);

    try {
      final testDataSource = getIt<TestRemoteDataSource>();
      final certificates = await testDataSource.getUserCertificates();
      final testResults = await testDataSource.getUserTestResults();

      if (!mounted) return;

      setState(() {
        _certificates = certificates.cast<Map<String, dynamic>>();
        _testResults = testResults.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
    }
  }

  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.tokenKey) ?? '';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Mening natijalarim',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Padding(
          padding: EdgeInsets.all(8.w),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              iconSize: 18.sp,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              labelStyle: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              indicatorPadding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text('Testlar'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium_outlined, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text('Sertifikatlar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.02),
              AppColors.scaffoldBackground,
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [_buildTestResultsTab(), _buildCertificatesTab()],
        ),
      ),
    );
  }

  Widget _buildTestResultsTab() {
    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: ListItemShimmer(),
        ),
      );
    }

    if (_testResults.isEmpty) {
      return _buildEmptyState(
        'assets/icons/star-fall.svg',
        'Hali test natijalari yo\'q',
        'Testlardan o\'ting va natijalaringizni bu yerda ko\'ring',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadResults,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _testResults.length,
        itemBuilder: (context, index) {
          final result = _testResults[index];
          return _buildTestResultCard(result);
        },
      ),
    );
  }

  Widget _buildCertificatesTab() {
    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 3,
        itemBuilder: (context, index) => const CertificateCardShimmer(),
      );
    }

    if (_certificates.isEmpty) {
      return _buildEmptyState(
        'assets/icons/certificate.svg',
        'Hali sertifikatlar yo\'q',
        'Testlardan yuqori natija bilan o\'ting va sertifikat oling',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadResults,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _certificates.length,
        itemBuilder: (context, index) {
          final certificate = _certificates[index];
          return _buildCertificateCard(certificate);
        },
      ),
    );
  }

  Widget _buildEmptyState(String iconPath, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                iconPath,
                width: 80.w,
                height: 80.h,
                colorFilter: ColorFilter.mode(
                  AppColors.primary.withOpacity(0.6),
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultCard(Map<String, dynamic> result) {
    final test = result['test'] as Map<String, dynamic>?;
    final course = test?['course'] as Map<String, dynamic>?;

    final testTitle = test?['title'] ?? 'Test';
    final courseTitle = course?['title'] ?? 'Kurs';
    final score = result['score'] ?? 0;
    final correctAnswers = result['correctAnswers'] ?? 0;
    final totalQuestions = result['totalQuestions'] ?? 0;
    final isPassed = result['isPassed'] ?? false;
    final completedAt = result['completedAt'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPassed
              ? [Colors.green.withOpacity(0.05), Colors.white]
              : [Colors.orange.withOpacity(0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isPassed
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? Colors.green : Colors.orange).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPassed
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    isPassed ? Icons.check_circle : Icons.info,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testTitle,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        courseTitle,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isPassed
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    isPassed ? 'O\'tdi' : 'Qayta',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isPassed
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Ball', '$correctAnswers/$totalQuestions'),
                  Container(width: 1, height: 40.h, color: AppColors.border),
                  _buildStatItem('Natija', '$score%'),
                ],
              ),
            ),
            if (completedAt != null) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Tugallangan: ${completedAt.substring(0, 10)}',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> certificate) {
    final testResult = certificate['testResult'] as Map<String, dynamic>?;
    final test = testResult?['test'] as Map<String, dynamic>?;
    final course = test?['course'] as Map<String, dynamic>?;

    final courseName = course?['title'] ?? 'Kurs';
    final score = testResult?['score'] ?? 0;
    final totalQuestions = testResult?['totalQuestions'] ?? 0;
    final correctAnswers = testResult?['correctAnswers'] ?? 0;
    // score is already a percentage (0-100), don't multiply again
    final percentage = score is int || score is double ? score.round() : 0;
    final certificateNo = certificate['certificateNo'] ?? '';
    final issuedAt = certificate['issuedAt'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.verified, color: Colors.white, size: 28.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseName,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Sertifikat №$certificateNo',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'To\'g\'ri',
                    '$correctAnswers/$totalQuestions',
                  ),
                  Container(width: 1, height: 40.h, color: AppColors.border),
                  _buildStatItem('Natija', '$percentage%'),
                ],
              ),
            ),
            if (issuedAt != null) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/calendar.svg',
                    width: 14.w,
                    height: 14.h,
                    colorFilter: ColorFilter.mode(
                      AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Berilgan: ${issuedAt.substring(0, 10)}',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Open PDF viewer directly
                      final token = await _getToken();
                      if (!mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewScreen(
                            pdfUrl:
                                '${AppConstants.baseUrl}/tests/certificates/download/$certificateNo',
                            certificateNo: certificateNo,
                            token: token,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: Text(
                      'Ko\'rish',
                      style: GoogleFonts.inter(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Download button with custom SVG icon
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      try {
                        // Download certificate
                        final dir = await getApplicationDocumentsDirectory();
                        final file = File(
                          '${dir.path}/certificate_$certificateNo.pdf',
                        );

                        ToastUtils.showSuccess(context, 'Yuklab olinmoqda...');

                        final response = await http.get(
                          Uri.parse(
                            '${AppConstants.baseUrl}/tests/certificates/download/$certificateNo',
                          ),
                          headers: {
                            'Authorization': 'Bearer ${await _getToken()}',
                          },
                        );

                        if (response.statusCode == 200) {
                          await file.writeAsBytes(response.bodyBytes);

                          // Copy to downloads folder
                          final downloadsDir = Directory(
                            '/storage/emulated/0/Download',
                          );
                          if (!await downloadsDir.exists()) {
                            await downloadsDir.create(recursive: true);
                          }

                          final newPath =
                              '${downloadsDir.path}/certificate_${certificateNo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
                          await file.copy(newPath);

                          if (!mounted) return;

                          ToastUtils.showSuccess(
                            context,
                            'Yuklab olindi: Download',
                          );
                        } else {
                          throw Exception('Yuklanmadi');
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ToastUtils.showError(context, e);
                      }
                    },
                    icon: SvgPicture.asset(
                      'assets/icons/download.svg',
                      width: 20.w,
                      height: 20.h,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    tooltip: 'Yuklab olish',
                  ),
                ),
                SizedBox(width: 8.w),
                // Share button with custom SVG icon
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      try {
                        // Download and share certificate
                        final dir = await getApplicationDocumentsDirectory();
                        final file = File(
                          '${dir.path}/certificate_$certificateNo.pdf',
                        );

                        if (await file.exists()) {
                          // Share if already downloaded
                          await Share.shareXFiles([
                            XFile(file.path),
                          ], text: 'Mening sertifikatim');
                        } else {
                          // Download first
                          ToastUtils.showSuccess(
                            context,
                            'Yuklab olinmoqda...',
                          );

                          final response = await http.get(
                            Uri.parse(
                              '${AppConstants.baseUrl}/tests/certificates/download/$certificateNo',
                            ),
                            headers: {
                              'Authorization': 'Bearer ${await _getToken()}',
                            },
                          );

                          if (response.statusCode == 200) {
                            await file.writeAsBytes(response.bodyBytes);

                            if (!mounted) return;

                            await Share.shareXFiles([
                              XFile(file.path),
                            ], text: 'Mening sertifikatim');
                          }
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ToastUtils.showError(context, e);
                      }
                    },
                    icon: SvgPicture.asset(
                      'assets/icons/share.svg',
                      width: 20.w,
                      height: 20.h,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    tooltip: 'Ulashish',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
