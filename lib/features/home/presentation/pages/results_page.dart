import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/test_remote_datasource.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _certificates = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);

    try {
      final testDataSource = getIt<TestRemoteDataSource>();
      final certificates = await testDataSource.getUserCertificates();

      if (!mounted) return;

      setState(() {
        _certificates = certificates.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Mening natijalarim',
          style: TextStyle(color: Colors.white),
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
      ),
      body: _isLoading
          ? ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: 3,
              itemBuilder: (context, index) => const CertificateCardShimmer(),
            )
          : _certificates.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadResults,
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _certificates.length,
                itemBuilder: (context, index) {
                  final certificate = _certificates[index];
                  return _buildCertificateCard(certificate);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              'assets/icons/star-fall.svg',
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
            'Hali natijalar yo\'q',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Text(
              'Kurslarni tugatib testlardan o\'ting va sertifikat oling',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> certificate) {
    final testResult = certificate['testResult'] as Map<String, dynamic>?;
    final test = testResult?['test'] as Map<String, dynamic>?;
    final course = test?['course'] as Map<String, dynamic>?;
    final user = certificate['user'] as Map<String, dynamic>?;

    final courseName = course?['title'] ?? 'Kurs';
    final score = testResult?['score'] ?? 0;
    final totalQuestions = testResult?['totalQuestions'] ?? 0;
    final percentage = totalQuestions > 0
        ? (score / totalQuestions * 100).round()
        : 0;
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
                        style: TextStyle(
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
                        style: TextStyle(
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
                  _buildStatItem('Ball', '$score/$totalQuestions'),
                  Container(width: 1, height: 40.h, color: AppColors.border),
                  _buildStatItem('Natija', '$percentage%'),
                ],
              ),
            ),
            if (issuedAt != null) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Berilgan: ${issuedAt.substring(0, 10)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final testDataSource = getIt<TestRemoteDataSource>();
                    final url = await testDataSource.downloadCertificate(
                      certificateNo,
                    );

                    if (!mounted) return;

                    ToastUtils.showSuccess(
                      context,
                      'Sertifikat yuklanmoqda...',
                    );

                    // Open in browser for download
                    // TODO: Implement url_launcher or download to device
                  } catch (e) {
                    if (!mounted) return;
                    ToastUtils.showError(context, e);
                  }
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Sertifikatni yuklab olish'),
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
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
