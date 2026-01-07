import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/page_transition.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/datasources/banner_remote_datasource.dart';
import '../../data/datasources/teacher_remote_datasource.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../../../injection_container.dart';
import 'notifications_page.dart';
import 'teachers_page.dart';
import 'course_detail_page.dart';
import 'teacher_detail_page.dart';
import 'main_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isLoading = false;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _teachers = [];
  int _currentBannerIndex = 0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload when returning to this page
      _loadUnreadNotificationCount();
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final dataSource = getIt<NotificationRemoteDataSource>();
      final result = await dataSource.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = result['count'] ?? 0;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courseDataSource = getIt<CourseRemoteDataSource>();
      final categoryDataSource = getIt<CategoryRemoteDataSource>();
      final bannerDataSource = getIt<BannerRemoteDataSource>();
      final teacherDataSource = getIt<TeacherRemoteDataSource>();

      final coursesData = await courseDataSource.getAllCourses();
      final categoriesData = await categoryDataSource.getAllCategories();
      final bannersData = await bannerDataSource.getActiveBanners();
      final teachersData = await teacherDataSource.getAllTeachers();

      if (!mounted) return;

      setState(() {
        _courses = coursesData.cast<Map<String, dynamic>>();
        _categories = categoriesData.cast<Map<String, dynamic>>();
        _banners = bannersData.cast<Map<String, dynamic>>();
        _teachers = teachersData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ToastUtils.showError(context, e);
    }
  }

  Future<void> _toggleSaveCourse(int courseId) async {
    try {
      final courseDataSource = getIt<CourseRemoteDataSource>();
      await courseDataSource.toggleSaveCourse(courseId);

      if (!mounted) return;

      // Update local state
      setState(() {
        final index = _courses.indexWhere((c) => c['id'] == courseId);
        if (index != -1) {
          _courses[index]['isSaved'] = !(_courses[index]['isSaved'] ?? false);
          final isSaved = _courses[index]['isSaved'];
          ToastUtils.showSuccess(
            context,
            isSaved ? 'Kurs saqlandi' : 'Kurs o\'chirildi',
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kurslar'),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/search-alt.svg',
              width: 24.w,
              height: 24.h,
              colorFilter: ColorFilter.mode(
                AppColors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {
              final mainPageState = context
                  .findAncestorStateOfType<MainPageState>();
              if (mainPageState != null) {
                mainPageState.changeTab(1);
              }
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/notification-bell.svg',
                  width: 24.w,
                  height: 24.h,
                  colorFilter: ColorFilter.mode(
                    AppColors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () async {
                  final result = await context.pushWithFade(
                    const NotificationsPage(),
                  );
                  // Reload unread count after returning from notifications
                  _loadUnreadNotificationCount();

                  // Handle tab change if result is a tab index
                  if (result is int && mounted) {
                    final mainPageState = context
                        .findAncestorStateOfType<MainPageState>();
                    if (mainPageState != null) {
                      mainPageState.changeTab(result);
                    }
                  }
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8.w,
                  top: 8.h,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    constraints: BoxConstraints(
                      minWidth: 18.w,
                      minHeight: 18.w,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _unreadNotificationCount > 99
                            ? '99+'
                            : _unreadNotificationCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Carousel
              _isLoading || _banners.isEmpty
                  ? Container(
                      width: double.infinity,
                      height: 200.h,
                      margin: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    )
                  : Column(
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200.h,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 4),
                            autoPlayAnimationDuration: const Duration(
                              milliseconds: 800,
                            ),
                            enlargeCenterPage: true,
                            viewportFraction: 0.9,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentBannerIndex = index;
                              });
                            },
                          ),
                          items: _banners.map((banner) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Extract course ID from link
                                      final link = banner['link'] ?? '';
                                      if (link.isNotEmpty) {
                                        // Parse link like '/courses/1'
                                        final parts = link.split('/');
                                        if (parts.length >= 3 &&
                                            parts[1] == 'courses') {
                                          final courseId = int.tryParse(
                                            parts[2],
                                          );
                                          if (courseId != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CourseDetailPage(
                                                      courseId: courseId,
                                                    ),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20.r),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  (banner['image'] ?? '')
                                                      .toString()
                                                      .startsWith('http')
                                                  ? banner['image'] ?? ''
                                                  : '${AppConstants.baseUrl}${banner['image'] ?? ''}',
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    color: AppColors.border,
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                        color: AppColors.primary
                                                            .withOpacity(0.1),
                                                      ),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.black.withOpacity(
                                                      0.6,
                                                    ),
                                                    Colors.transparent,
                                                  ],
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 20.h,
                                            left: 20.w,
                                            right: 20.w,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  banner['title'] ?? '',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  banner['description'] ?? '',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                    fontSize: 14.sp,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _banners.asMap().entries.map((entry) {
                            return Container(
                              width: _currentBannerIndex == entry.key
                                  ? 24.w
                                  : 8.w,
                              height: 8.h,
                              margin: EdgeInsets.symmetric(horizontal: 4.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4.r),
                                color: _currentBannerIndex == entry.key
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

              // O'qituvchilar bo'limi
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Mashhur o\'qituvchilar',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    TextButton(
                      onPressed: () {
                        context.pushWithFade(const TeachersPage());
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Hammasi', style: TextStyle(fontSize: 14.sp)),
                    ),
                  ],
                ),
              ),

              // Teachers List
              _isLoading
                  ? SizedBox(
                      height: 200.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        physics: const BouncingScrollPhysics(),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return const TeacherCardHorizontalShimmer();
                        },
                      ),
                    )
                  : _teachers.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 20.h,
                      ),
                      child: Center(
                        child: Text(
                          'O\'qituvchilar topilmadi',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 200.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _teachers.length > 5 ? 5 : _teachers.length,
                        itemBuilder: (context, index) {
                          final teacher = _teachers[index];
                          final avatarUrl = teacher['avatar'] != null
                              ? '${AppConstants.baseUrl}${teacher['avatar']}'
                              : null;
                          final hasAvatar =
                              avatarUrl != null && avatarUrl.isNotEmpty;

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              context.pushWithFade(
                                TeacherDetailPage(teacherId: teacher['id']),
                              );
                            },
                            child: Container(
                              width: 150.w,
                              margin: EdgeInsets.only(
                                right: 16.w,
                                top: 8.h,
                                bottom: 8.h,
                              ),
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: AppColors.border.withOpacity(0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 36.r,
                                      backgroundColor: AppColors.secondary,
                                      child: hasAvatar
                                          ? ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl: avatarUrl!,
                                                width: 72.r,
                                                height: 72.r,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Shimmer.fromColors(
                                                      baseColor:
                                                          AppColors.shimmerBase,
                                                      highlightColor: AppColors
                                                          .shimmerHighlight,
                                                      child: Container(
                                                        width: 72.r,
                                                        height: 72.r,
                                                        decoration:
                                                            const BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Text(
                                                          teacher['name']
                                                                  ?.substring(
                                                                    0,
                                                                    1,
                                                                  ) ??
                                                              'T',
                                                          style: TextStyle(
                                                            fontSize: 28.sp,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: AppColors
                                                                .primary,
                                                          ),
                                                        ),
                                              ),
                                            )
                                          : Text(
                                              teacher['name']?.substring(
                                                    0,
                                                    1,
                                                  ) ??
                                                  'T',
                                              style: TextStyle(
                                                fontSize: 28.sp,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Flexible(
                                    child: Text(
                                      teacher['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    '${teacher['_count']?['courses'] ?? 0} kurs',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

              SizedBox(height: 24.h),

              // Categories
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  'Kategoriyalar',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              _isLoading
                  ? SizedBox(
                      height: 120.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(right: 12.w),
                            child: const CategoryItemShimmer(),
                          );
                        },
                      ),
                    )
                  : SizedBox(
                      height: 120.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              final mainPageState = context
                                  .findAncestorStateOfType<MainPageState>();
                              if (mainPageState != null) {
                                mainPageState.updateSearchCategory(
                                  category['id'],
                                );
                                mainPageState.changeTab(1);
                              }
                            },
                            child: Container(
                              width: 140.w,
                              margin: EdgeInsets.only(right: 12.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: Stack(
                                  children: [
                                    // Background Image
                                    if (category['image'] != null)
                                      Positioned.fill(
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              category['image']
                                                  .toString()
                                                  .startsWith('http')
                                              ? category['image']
                                              : '${AppConstants.baseUrl}${category['image']}',
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                color: AppColors.border,
                                              ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                color: AppColors.primary
                                                    .withOpacity(0.1),
                                              ),
                                        ),
                                      ),

                                    // Gradient Overlay
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withOpacity(0.6),
                                              Colors.black.withOpacity(0.3),
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Category Name
                                    Positioned(
                                      bottom: 12.h,
                                      left: 12.w,
                                      right: 12.w,
                                      child: Text(
                                        category['nameUz'] ?? category['name'],
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.5,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              SizedBox(height: 24.h),

              // Popular Courses
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mashhur kurslar',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Barchasini ko\'rish'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              _isLoading
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return const CourseCardShimmer();
                      },
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        return _buildCourseCard(course);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final isFree = course['isFree'] ?? false;
    final isSaved = course['isSaved'] ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final result = await context.pushWithFade(
          CourseDetailPage(courseId: course['id']),
        );

        // Reload data and refresh main page badge
        _loadData();

        // Find MainPage and refresh active courses count
        if (result == true && mounted) {
          final mainPageState = context
              .findAncestorStateOfType<MainPageState>();
          mainPageState?.refreshActiveCourses();
        }
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
            // Thumbnail with badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                  child: SizedBox(
                    height: 200.h,
                    width: double.infinity,
                    child: course['thumbnail'] != null
                        ? CachedNetworkImage(
                            imageUrl:
                                '${AppConstants.baseUrl}${course['thumbnail']}',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => ShimmerLoading(
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.secondary,
                              child: Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: 64.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.secondary,
                            child: Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 64.sp,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                // Free badge
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
                // Save button
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleSaveCourse(course['id']),
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
                        isSaved
                            ? 'assets/icons/heart_filled.svg'
                            : 'assets/icons/heart.svg',
                        width: 20.w,
                        height: 20.h,
                        colorFilter: ColorFilter.mode(
                          isSaved ? Colors.red : AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'],
                    style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    course['subtitle'] ?? '',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16.h),
                  // Teacher info with avatar
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12.r,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: SvgPicture.asset(
                          'assets/icons/user.svg',
                          width: 14.w,
                          height: 14.h,
                          colorFilter: ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
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
                  // Stats row
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
                        SvgPicture.asset(
                          'assets/icons/star-circle.svg',
                          width: 16.w,
                          height: 16.h,
                          colorFilter: const ColorFilter.mode(
                            Colors.amber,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          (course['rating'] ?? 0).toString(),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        SvgPicture.asset(
                          'assets/icons/group.svg',
                          width: 16.w,
                          height: 16.h,
                          colorFilter: ColorFilter.mode(
                            AppColors.textSecondary,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${course['_count']?['enrollments'] ?? 0}',
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
                              fontSize: 18.sp,
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
}
