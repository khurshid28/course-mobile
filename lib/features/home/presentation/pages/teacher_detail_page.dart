import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/teacher_rating_widget.dart';
import '../../data/datasources/teacher_remote_datasource.dart';
import '../../../../injection_container.dart';
import 'course_detail_page.dart';

class TeacherDetailPage extends StatefulWidget {
  final int teacherId;

  const TeacherDetailPage({super.key, required this.teacherId});

  @override
  State<TeacherDetailPage> createState() => _TeacherDetailPageState();
}

class _TeacherDetailPageState extends State<TeacherDetailPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _teacher;
  int? _userRating;
  bool _isLoadingRating = false;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
    _loadUserRating();
  }

  Future<void> _loadTeacher() async {
    setState(() => _isLoading = true);

    try {
      final teacherDataSource = getIt<TeacherRemoteDataSource>();
      final teacher = await teacherDataSource.getTeacherById(widget.teacherId);

      if (!mounted) return;

      setState(() {
        _teacher = teacher;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ToastUtils.showError(context, e);
    }
  }

  Future<void> _loadUserRating() async {
    try {
      final teacherDataSource = getIt<TeacherRemoteDataSource>();
      final result = await teacherDataSource.getUserRating(widget.teacherId);

      if (!mounted) return;

      setState(() {
        _userRating = result['userRating'];
      });
    } catch (e) {
      // Silently fail - user might not be logged in
    }
  }

  Future<void> _handleRate(int rating) async {
    setState(() => _isLoadingRating = true);

    try {
      final teacherDataSource = getIt<TeacherRemoteDataSource>();
      final result = await teacherDataSource.rateTeacher(widget.teacherId, rating);

      if (!mounted) return;

      setState(() {
        _userRating = rating;
        if (_teacher != null) {
          _teacher!['rating'] = result['averageRating'];
          _teacher!['totalRatings'] = result['totalRatings'];
        }
        _isLoadingRating = false;
      });

      if (mounted) {
        ToastUtils.showSuccess(context, 'Baholash muvaffaqiyatli saqlandi!');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingRating = false);
      ToastUtils.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teacher == null
          ? Center(
              child: Text(
                'O\'qituvchi topilmadi',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                // Header with gradient
                SliverAppBar(
                  expandedHeight: 320.h,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  leading: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                        iconSize: 18.sp,
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 40.h),
                            // Avatar
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 55.r,
                                backgroundColor: Colors.white,
                                child:
                                    _teacher!['avatar'] != null &&
                                        _teacher!['avatar']
                                            .toString()
                                            .trim()
                                            .isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: _teacher!['avatar'],
                                          width: 110.r,
                                          height: 110.r,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                color: AppColors.secondary,
                                              ),
                                          errorWidget: (context, url, error) =>
                                              SvgPicture.asset(
                                                'assets/icons/user.svg',
                                                width: 50.w,
                                                height: 50.h,
                                                colorFilter: ColorFilter.mode(
                                                  AppColors.primary,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                        ),
                                      )
                                    : SvgPicture.asset(
                                        'assets/icons/user.svg',
                                        width: 50.w,
                                        height: 50.h,
                                        colorFilter: ColorFilter.mode(
                                          AppColors.primary,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            // Name
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Text(
                                _teacher!['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            // Stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatBadge(
                                  Icons.star,
                                  '${_teacher!['rating'] ?? 0}',
                                  '${_teacher!['totalRatings'] ?? 0} baho',
                                ),
                                SizedBox(width: 12.w),
                                _buildStatBadge(
                                  Icons.school_rounded,
                                  '${(_teacher!['courses'] as List?)?.length ?? 0}',
                                  'Kurslar',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bio Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
                    child: Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
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
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Haqida',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            _teacher!['bio'] ?? 'Ma\'lumot yo\'q',
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Rating Widget - Bio carddan keyin
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                    child: _isLoadingRating
                        ? const Center(child: CircularProgressIndicator())
                        : TeacherRatingWidget(
                            userRating: _userRating,
                            averageRating: (_teacher!['rating'] ?? 0.0).toDouble(),
                            totalRatings: _teacher!['totalRatings'] ?? 0,
                            onRate: _handleRate,
                          ),
                  ),
                ),

                // Categories (if available)
                if (_teacher!['categories'] != null &&
                    _teacher!['categories'].toString().isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
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
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/user.svg',
                                    width: 20.w,
                                    height: 20.h,
                                    colorFilter: ColorFilter.mode(
                                      AppColors.primary,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'Mutaxassislik',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: (_teacher!['categories'] as String)
                                  .split(',')
                                  .map(
                                    (category) => Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 8.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(
                                            0.3,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        category.trim(),
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Contact Info (if available)
                if (_teacher!['email'] != null || _teacher!['phone'] != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
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
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Icons.contact_mail_outlined,
                                    color: AppColors.primary,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'Aloqa',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            if (_teacher!['email'] != null)
                              Container(
                                padding: EdgeInsets.all(14.w),
                                margin: EdgeInsets.only(bottom: 12.h),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.email,
                                        size: 20.sp,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Email',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            _teacher!['email'],
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_teacher!['phone'] != null)
                              Container(
                                padding: EdgeInsets.all(14.w),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/icons/phone.svg',
                                        width: 20.w,
                                        height: 20.h,
                                        colorFilter: ColorFilter.mode(
                                          AppColors.primary,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Telefon',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          _teacher!['phone'],
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
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
                    ),
                  ),

                // Courses Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 12.h),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.play_circle_outline,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Kurslar',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(_teacher!['courses'] as List?)?.length ?? 0} ta',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Courses Section Header
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  sliver: (_teacher!['courses'] as List?)?.isEmpty ?? true
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.h),
                              child: Text(
                                'Kurslar mavjud emas',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final course =
                                  (_teacher!['courses'] as List)[index];
                              return _buildCourseCard(course);
                            },
                            childCount:
                                (_teacher!['courses'] as List?)?.length ?? 0,
                          ),
                        ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              ],
            ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final isFree = course['isFree'] ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailPage(courseId: course['id']),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                  child: SizedBox(
                    height: 180.h,
                    width: double.infinity,
                    child: course['thumbnail'] != null
                        ? CachedNetworkImage(
                            imageUrl: course['thumbnail'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: AppColors.border),
                            errorWidget: (context, url, error) =>
                                Container(color: AppColors.secondary),
                          )
                        : Container(color: AppColors.secondary),
                  ),
                ),
                if (isFree)
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'BEPUL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'] ?? '',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    course['subtitle'] ?? '',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12.h),

                  // Teacher info
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 14.r,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage:
                              course['teacher']?['avatar'] != null &&
                                  course['teacher']['avatar']
                                      .toString()
                                      .trim()
                                      .isNotEmpty
                              ? CachedNetworkImageProvider(
                                  course['teacher']['avatar'],
                                )
                              : null,
                          child:
                              course['teacher']?['avatar'] == null ||
                                  course['teacher']['avatar'].toString().isEmpty
                              ? SvgPicture.asset(
                                  'assets/icons/user.svg',
                                  width: 14.w,
                                  height: 14.h,
                                  colorFilter: ColorFilter.mode(
                                    AppColors.primary,
                                    BlendMode.srcIn,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          course['teacher']?['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Course details
                  Row(
                    children: [
                      // Level
                      if (course['level'] != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.signal_cellular_alt,
                                size: 14.sp,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                course['level'],
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],

                      // Duration
                      if (course['duration'] != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${(course['duration'] / 60).ceil()} soat',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Stats and Price
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16.sp),
                        SizedBox(width: 4.w),
                        Text(
                          '${course['rating'] ?? 0}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.people_outline,
                          size: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${course['totalStudents'] ?? 0}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (!isFree)
                          Text(
                            '${FormatUtils.formatPrice(course['price'])} so\'m',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
