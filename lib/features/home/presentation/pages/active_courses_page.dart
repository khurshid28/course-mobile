import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../../../injection_container.dart';
import '../../../../core/utils/toast_utils.dart';
import 'course_detail_page.dart';
import 'main_page.dart';

class ActiveCoursesPage extends StatefulWidget {
  const ActiveCoursesPage({super.key});

  @override
  State<ActiveCoursesPage> createState() => _ActiveCoursesPageState();
}

class _ActiveCoursesPageState extends State<ActiveCoursesPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _enrolledCourses = [];

  @override
  void initState() {
    super.initState();
    _loadEnrolledCourses();
  }

  Future<void> _loadEnrolledCourses() async {
    setState(() => _isLoading = true);

    try {
      final dataSource = getIt<CourseRemoteDataSource>();
      final courses = await dataSource.getEnrolledCourses();

      if (!mounted) return;

      setState(() {
        _enrolledCourses = courses
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ToastUtils.showError(context, e);
    }
  }

  String _getTimeRemaining(String? expiresAt) {
    if (expiresAt == null) return 'Cheksiz';

    try {
      final expiry = DateTime.parse(expiresAt);
      final now = DateTime.now();
      final difference = expiry.difference(now);

      if (difference.isNegative) {
        return 'Vaqti o\'tgan';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months oy qoldi';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} kun qoldi';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} soat qoldi';
      } else {
        return '${difference.inMinutes} daqiqa qoldi';
      }
    } catch (e) {
      return 'Noma\'lum';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faol kurslar'),
        leading: Padding(
          padding: EdgeInsets.all(8.w),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
              iconSize: 18.sp,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/add_course.svg',
                  width: 20.w,
                  height: 20.h,
                  colorFilter: ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
                padding: EdgeInsets.all(8.w),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainPage(initialIndex: 1),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: 5,
              itemBuilder: (context, index) => const CourseCardShimmer(),
            )
          : _enrolledCourses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/courses.svg',
                    width: 80.w,
                    height: 80.h,
                    colorFilter: ColorFilter.mode(
                      AppColors.textHint,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Faol kurslar yo\'q',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Hali birorta kurs sotib olmadingiz',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _enrolledCourses.length,
              itemBuilder: (context, index) {
                final course = _enrolledCourses[index];
                return _buildCourseCard(course);
              },
            ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final isExpired = course['isExpired'] == true;
    final timeRemaining = _getTimeRemaining(course['expiresAt']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailPage(courseId: course['id']),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isExpired
                ? AppColors.error.withOpacity(0.3)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: course['thumbnail'].toString().startsWith('http')
                        ? course['thumbnail'].toString()
                        : '${AppConstants.baseUrl}${course['thumbnail']}',
                    height: 180.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(height: 180.h, color: AppColors.shimmerBase),
                    errorWidget: (context, url, error) {
                      print('Image error: $error for URL: $url');
                      return Container(
                        height: 180.h,
                        color: AppColors.secondary,
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 48.sp,
                          color: AppColors.textHint,
                        ),
                      );
                    },
                  ),
                  // Status badge
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired ? AppColors.error : AppColors.success,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        isExpired ? 'VAQTI O\'TGAN' : 'FAOL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Expired overlay
                  if (isExpired)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16.r),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.lock,
                            size: 48.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Course Info
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'] ?? '',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16.sp,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          course['teacher']?['name'] ?? 'O\'qituvchi',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isExpired ? Icons.timer_off : Icons.timer,
                            size: 16.sp,
                            color: isExpired
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            timeRemaining,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isExpired
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (!isExpired)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Davom etish',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
