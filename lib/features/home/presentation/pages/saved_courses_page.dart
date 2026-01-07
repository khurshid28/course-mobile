import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/datasources/saved_courses_local_datasource.dart';
import '../../../../injection_container.dart';
import '../../../../core/utils/toast_utils.dart';
import 'course_detail_page.dart';

class SavedCoursesPage extends StatefulWidget {
  const SavedCoursesPage({super.key});

  @override
  State<SavedCoursesPage> createState() => _SavedCoursesPageState();
}

class _SavedCoursesPageState extends State<SavedCoursesPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _savedCourses = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCourses();
  }

  Future<void> _loadSavedCourses() async {
    setState(() => _isLoading = true);

    try {
      // Load from local first (offline)
      final localDataSource = getIt<SavedCoursesLocalDataSource>();
      final localCourses = await localDataSource.getSavedCourses();

      if (!mounted) return;

      setState(() {
        _savedCourses = localCourses;
        _isLoading = false;
      });

      // Then sync with remote in background
      _syncWithRemote();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ToastUtils.showError(context, e);
    }
  }

  Future<void> _syncWithRemote() async {
    try {
      final remoteDataSource = getIt<CourseRemoteDataSource>();
      final remoteCourses = await remoteDataSource.getSavedCourses();

      if (!mounted) return;

      // Save to local and update UI
      final localDataSource = getIt<SavedCoursesLocalDataSource>();
      await localDataSource.syncWithRemote(
        remoteCourses.map((e) => e as Map<String, dynamic>).toList(),
      );

      setState(() {
        _savedCourses = remoteCourses
            .map((e) => e as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      // Silent fail - local data is already shown
    }
  }

  Future<void> _toggleSaveCourse(int courseId) async {
    try {
      // Remove from local first
      final localDataSource = getIt<SavedCoursesLocalDataSource>();
      await localDataSource.removeCourse(courseId);

      if (!mounted) return;

      // Remove from UI
      setState(() {
        _savedCourses.removeWhere((c) => c['id'] == courseId);
      });

      // Then remove from remote in background
      final remoteDataSource = getIt<CourseRemoteDataSource>();
      await remoteDataSource.toggleSaveCourse(courseId);

      if (!mounted) return;
      ToastUtils.showSuccess(context, 'Kurs o\'chirildi');
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saqlangan kurslar'),
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavedCourses,
        child: _isLoading
            ? ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: 5,
                itemBuilder: (context, index) => const CourseCardShimmer(),
              )
            : _savedCourses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/heart.svg',
                      width: 80.w,
                      height: 80.h,
                      colorFilter: ColorFilter.mode(
                        AppColors.textHint,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Saqlangan kurslar yo\'q',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Sizda hozircha saqlangan kurslar yo\'q',
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
                itemCount: _savedCourses.length,
                itemBuilder: (context, index) {
                  final course = _savedCourses[index];
                  return _buildCourseCard(course);
                },
              ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailPage(courseId: course['id']),
          ),
        ).then((_) => _loadSavedCourses());
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
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
                          Icons.image,
                          size: 48.sp,
                          color: AppColors.textHint,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: GestureDetector(
                      onTap: () {
                        _toggleSaveCourse(course['id']);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/heart_filled.svg',
                          width: 20.w,
                          height: 20.h,
                          colorFilter: const ColorFilter.mode(
                            Colors.red,
                            BlendMode.srcIn,
                          ),
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
                      Text(
                        course['teacher']?['name'] ?? 'O\'qituvchi',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
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
                          Icon(Icons.star, size: 16.sp, color: Colors.amber),
                          SizedBox(width: 4.w),
                          Text(
                            '${course['rating'] ?? 0}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        course['isFree'] == true
                            ? 'Bepul'
                            : '${FormatUtils.formatPrice(course['price'])} so\'m',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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
