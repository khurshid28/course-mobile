import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/page_transition.dart';
import '../../../../core/widgets/course_rating_widget.dart';
import '../../data/models/section_model.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/datasources/saved_courses_local_datasource.dart';
import '../../data/datasources/comment_remote_datasource.dart';
import '../../../../injection_container.dart';
import 'checkout_page.dart';
import 'video_player_page.dart';

class CourseDetailPage extends StatefulWidget {
  final int courseId;

  const CourseDetailPage({Key? key, required this.courseId}) : super(key: key);

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SectionModel> sections = [];
  bool isLoading = true;
  bool isSaved = false;
  Map<String, dynamic>? courseData;
  final TextEditingController _commentController = TextEditingController();
  double? _userCourseRating;
  bool _isLoadingRating = false;
  List<dynamic> _comments = [];
  bool _isLoadingComments = false;
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedImagePaths = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCourseDetails();
    _loadUserCourseRating();
    _loadComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCourseRating() async {
    setState(() => _isLoadingRating = true);
    try {
      final dataSource = getIt<CourseRemoteDataSource>();
      final rating = await dataSource.getUserCourseRating(widget.courseId);
      if (mounted) {
        setState(() {
          final ratingValue = rating['rating'];
          _userCourseRating = ratingValue != null
              ? (ratingValue is num ? ratingValue.toDouble() : null)
              : null;
          _isLoadingRating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRating = false);
      }
    }
  }

  Future<void> _handleCourseRate(int rating) async {
    try {
      final dataSource = getIt<CourseRemoteDataSource>();
      await dataSource.rateCourse(widget.courseId, rating);
      if (mounted) {
        setState(() => _userCourseRating = rating.toDouble());
        ToastUtils.showSuccess(context, 'Baho muvaffaqiyatli saqlandi!');
        await _loadCourseDetails(); // Refresh to get updated average
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Baholashda xatolik yuz berdi');
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final commentDataSource = getIt<CommentRemoteDataSource>();
      final comments = await commentDataSource.getCommentsByCourseId(
        widget.courseId,
      );
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _loadCourseDetails() async {
    try {
      final dataSource = getIt<CourseRemoteDataSource>();
      final course = await dataSource.getCourseById(widget.courseId);

      if (!mounted) return;

      setState(() {
        courseData = course;
        isSaved = course['isSaved'] ?? false;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ToastUtils.showError(context, e);
    }
  }

  Future<void> _toggleSave() async {
    try {
      final remoteDataSource = getIt<CourseRemoteDataSource>();
      final localDataSource = getIt<SavedCoursesLocalDataSource>();

      await remoteDataSource.toggleSaveCourse(widget.courseId);

      if (!mounted) return;

      setState(() {
        isSaved = !isSaved;
      });

      // Update local storage
      if (isSaved && courseData != null) {
        await localDataSource.saveCourse(courseData!);
      } else {
        await localDataSource.removeCourse(widget.courseId);
      }

      ToastUtils.showSuccess(
        context,
        isSaved ? 'Kurs saqlandi' : 'Kurs o\'chirildi',
      );
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || courseData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF3572ED),
          leading: Padding(
            padding: EdgeInsets.all(8.w),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
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
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Course Image
          SliverAppBar(
            expandedHeight: 220.h,
            pinned: true,
            backgroundColor: const Color(0xFF3572ED),
            leading: Padding(
              padding: EdgeInsets.all(8.w),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
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
            actions: [
              IconButton(
                icon: SvgPicture.asset(
                  isSaved
                      ? 'assets/icons/heart_filled.svg'
                      : 'assets/icons/heart.svg',
                  width: 24.w,
                  height: 24.h,
                  colorFilter: ColorFilter.mode(
                    isSaved ? Colors.red : Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: _toggleSave,
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: 'https://picsum.photos/800/400',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Course Info
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flutter - Mobil Ilovalar Yaratish',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 8.h,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/star.svg',
                            width: 16.w,
                            height: 16.h,
                            colorFilter: const ColorFilter.mode(
                              Colors.amber,
                              BlendMode.srcIn,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            courseData != null
                                ? (courseData!['rating']?.toString() ?? '0.0')
                                : '0.0',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16.w,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            courseData != null
                                ? '${courseData!['totalStudents'] ?? 0} talaba'
                                : '0 talaba',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 16.w,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            courseData != null
                                ? () {
                                    final sections =
                                        courseData!['sections']
                                            as List<dynamic>? ??
                                        [];
                                    int totalVideos = 0;
                                    for (var section in sections) {
                                      final videos =
                                          section['videos'] as List<dynamic>? ??
                                          [];
                                      totalVideos += videos.length;
                                    }
                                    return '$totalVideos video';
                                  }()
                                : '0 video',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://i.pravatar.cc/150?img=1',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alisher Usmonov',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Senior Flutter Developer',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '400,000 so\'m',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey,
                              decorationThickness: 2,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '200,000 so\'m',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3572ED),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Course Parameters Card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildParameterItem(
                                icon: Icons.topic_outlined,
                                iconColor: const Color(0xFF8B5CF6),
                                label: 'Mavzular',
                                value: '8 ta',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 70.h,
                              color: const Color(0xFFE5E7EB),
                            ),
                            Expanded(
                              child: _buildParameterItem(
                                icon: Icons.access_time,
                                iconColor: const Color(0xFFEC4899),
                                label: 'Davomiyligi',
                                value: '12 soat',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Divider(height: 1, color: const Color(0xFFE5E7EB)),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildParameterItem(
                                icon: Icons.signal_cellular_alt,
                                iconColor: const Color(0xFFF59E0B),
                                label: 'Daraja',
                                value: 'O\'rta',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 70.h,
                              color: const Color(0xFFE5E7EB),
                            ),
                            Expanded(
                              child: _buildParameterItem(
                                icon: Icons.workspace_premium,
                                iconColor: const Color(0xFF10B981),
                                label: 'Sertifikat',
                                value: 'Bor',
                                valueColor: const Color(0xFF10B981),
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

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF3572ED),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF3572ED),
                labelStyle: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Darsliklar'),
                  Tab(text: 'Izohlar'),
                  Tab(text: 'Savol-Javob'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 250.h,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSectionsTab(),
                  _buildCommentsTab(),
                  _buildFaqTab(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          courseData != null &&
              (courseData!['isEnrolled'] == true ||
                  courseData!['isFree'] == true)
          ? null
          : Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: courseData == null
                        ? null
                        : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CheckoutPage(course: courseData!),
                              ),
                            );

                            // If purchase successful, reload course and notify parent
                            if (result == true && mounted) {
                              await _loadCourseDetails();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/cart_large.svg',
                          width: 24.w,
                          height: 24.h,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Kursni Sotib Olish',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionsTab() {
    final sections = courseData?['sections'] as List<dynamic>? ?? [];

    if (sections.isEmpty) {
      return Center(
        child: Text(
          'Hali bo\'limlar mavjud emas',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        return _buildSectionCard(sections[index], index);
      },
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> section, int index) {
    final videos = section['videos'] as List<dynamic>? ?? [];
    final title = section['title'] ?? 'Bo\'lim ${index + 1}';
    final isSectionFree = section['isFree'] == true;

    // Calculate total duration
    int totalMinutes = 0;
    for (var video in videos) {
      totalMinutes += ((video['duration'] ?? 0) as num).toInt();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${videos.length} video • ${totalMinutes} daqiqa',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
          ),
          children: videos.asMap().entries.map((entry) {
            final videoIndex = entry.key;
            final video = entry.value;
            final isFree = video['isFree'] == true || isSectionFree;
            return _buildVideoItem(video, videoIndex, isFree);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video, int index, bool isFree) {
    final title = video['title'] ?? 'Video ${index + 1}';
    final duration = (video['duration'] ?? 0) as num;
    final durationText = duration > 0
        ? '${duration.toInt()} daqiqa'
        : 'Noma\'lum';
    final videoUrl = video['url'] ?? '';

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: isFree
                ? const Color(0xFF3572ED).withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.play_arrow,
            color: isFree ? const Color(0xFF3572ED) : Colors.grey,
            size: 24.w,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              durationText,
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
            ),
            if (isFree) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Bepul',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          isFree ? Icons.lock_open : Icons.lock_outline,
          color: isFree ? Colors.green : Colors.grey,
          size: 20.w,
        ),
        onTap: isFree || (courseData?['isEnrolled'] == true)
            ? () {
                if (videoUrl.isNotEmpty) {
                  context.pushWithFade(
                    VideoPlayerPage(videoUrl: videoUrl, title: title),
                  );
                } else {
                  ToastUtils.showError(context, 'Video topilmadi');
                }
              }
            : () {
                ToastUtils.showInfo(
                  context,
                  'Bu videoni ko\'rish uchun kursni sotib oling',
                );
              },
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        // Course Rating Widget
        if (courseData != null)
          Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CourseRatingWidget(
              userRating: _userCourseRating?.toInt(),
              averageRating: (courseData!['rating'] is num
                  ? (courseData!['rating'] as num).toDouble()
                  : 0.0),
              totalRatings: courseData!['_count']?['ratings'] ?? 0,
              onRate: _handleCourseRate,
            ),
          ),
        Flexible(
          child: _isLoadingComments
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _comments.isEmpty
              ? SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 40.h),
                        SvgPicture.asset(
                          'assets/icons/chat_round.svg',
                          width: 64.w,
                          height: 64.h,
                          colorFilter: ColorFilter.mode(
                            AppColors.textSecondary.withOpacity(0.5),
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Hozircha izohlar yo\'q',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    final user = comment['user'];
                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                                child:
                                    user?['avatar'] != null &&
                                        user['avatar'].toString().isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              user['avatar']
                                                  .toString()
                                                  .startsWith('http')
                                              ? user['avatar']
                                              : '${AppConstants.baseUrl}${user['avatar']}',
                                          width: 40.r,
                                          height: 40.r,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              SvgPicture.asset(
                                                'assets/icons/user.svg',
                                                width: 20.w,
                                                height: 20.h,
                                                colorFilter: ColorFilter.mode(
                                                  AppColors.primary,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                        ),
                                      )
                                    : SvgPicture.asset(
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${user?['firstName'] ?? ''} ${user?['surname'] ?? ''}',
                                      style: GoogleFonts.inter(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Padding(
                                          padding: EdgeInsets.only(right: 2.w),
                                          child: SvgPicture.asset(
                                            'assets/icons/star-circle.svg',
                                            width: 14.w,
                                            height: 14.h,
                                            colorFilter: ColorFilter.mode(
                                              starIndex <
                                                      (comment['rating'] ?? 0)
                                                  ? Colors.amber
                                                  : Colors.grey.shade300,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatDate(comment['createdAt']),
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            comment['comment'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                          // Screenshots display
                          if (comment['screenshots'] != null)
                            Builder(
                              builder: (context) {
                                final screenshots = comment['screenshots'];
                                List<dynamic> screenshotList = [];

                                print(
                                  'DEBUG RAW: screenshots type = ${screenshots.runtimeType}',
                                );
                                print(
                                  'DEBUG RAW: screenshots value = $screenshots',
                                );

                                if (screenshots is List) {
                                  print(
                                    'DEBUG: screenshots is List, length: ${screenshots.length}',
                                  );
                                  if (screenshots.isNotEmpty) {
                                    print(
                                      'DEBUG: First element = ${screenshots[0]}',
                                    );
                                    print(
                                      'DEBUG: First element type = ${screenshots[0].runtimeType}',
                                    );
                                  }

                                  // Check if nested array [[...]]
                                  if (screenshots.isNotEmpty &&
                                      screenshots[0] is List) {
                                    print(
                                      'DEBUG: Found nested array, extracting inner list',
                                    );
                                    screenshotList = List<dynamic>.from(
                                      screenshots[0],
                                    );
                                  } else if (screenshots.isNotEmpty &&
                                      screenshots[0] is String) {
                                    // Maybe JSON string?
                                    print('DEBUG: First element is String');
                                    screenshotList = screenshots;
                                  } else {
                                    screenshotList = screenshots;
                                  }
                                } else if (screenshots is String &&
                                    screenshots.isNotEmpty) {
                                  print('DEBUG: screenshots is String');
                                  // Parse JSON string to List
                                  try {
                                    final parsed = json.decode(screenshots);
                                    print('DEBUG: Parsed JSON = $parsed');
                                    if (parsed is List) {
                                      screenshotList = parsed;
                                    } else {
                                      screenshotList = [screenshots];
                                    }
                                  } catch (e) {
                                    print('DEBUG: Failed to parse JSON: $e');
                                    screenshotList = [screenshots];
                                  }
                                }

                                print(
                                  'Screenshots for comment ${comment['id']}: $screenshotList',
                                );
                                print(
                                  'Screenshot count: ${screenshotList.length}',
                                );

                                if (screenshotList.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Container(
                                  margin: EdgeInsets.only(top: 8.h),
                                  height: 60.h,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: screenshotList.length,
                                    itemBuilder: (context, imgIndex) {
                                      final screenshot =
                                          screenshotList[imgIndex];
                                      final imageUrl =
                                          screenshot.toString().startsWith(
                                            'http',
                                          )
                                          ? screenshot
                                          : '${AppConstants.baseUrl}$screenshot';

                                      print(
                                        'Screenshot $imgIndex URL: $imageUrl',
                                      );

                                      return GestureDetector(
                                        onTap: () {
                                          _showFullScreenImage(
                                            context,
                                            imageUrl,
                                            screenshotList
                                                .map(
                                                  (s) => s.startsWith('http')
                                                      ? s
                                                      : '${AppConstants.baseUrl}$s',
                                                )
                                                .toList(),
                                            imgIndex,
                                          );
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(right: 8.w),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              width: 60.w,
                                              height: 60.h,
                                              fit: BoxFit.cover,
                                              errorListener: (error) {
                                                print(
                                                  'Image load error for $imageUrl: $error',
                                                );
                                              },
                                              placeholder: (context, url) =>
                                                  Container(
                                                    color: Colors.grey.shade200,
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: AppColors
                                                                .primary,
                                                          ),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Container(
                                                    color: Colors.grey.shade200,
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                      size: 20.w,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        // Comment input
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image preview
                if (_selectedImagePaths.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 8.h, left: 8.w),
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _selectedImagePaths.asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final imagePath = entry.value;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6.r),
                              child: Image.file(
                                File(imagePath),
                                height: 50.h,
                                width: 50.w,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -6.h,
                              right: -6.w,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImagePaths.removeAt(index);
                                  });
                                },
                                child: Container(
                                  width: 20.w,
                                  height: 20.h,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 12.w,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // Image picker button
                      IconButton(
                        icon: Icon(
                          Icons.image,
                          color: AppColors.primary,
                          size: 24.w,
                        ),
                        onPressed: () async {
                          if (_selectedImagePaths.length >= 3) {
                            ToastUtils.showInfo(
                              context,
                              'Maksimal 3 ta rasm tanlash mumkin',
                            );
                            return;
                          }
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1024,
                            maxHeight: 1024,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            setState(() {
                              _selectedImagePaths.add(image.path);
                            });
                          }
                        },
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: _selectedImagePaths.isEmpty
                                ? 60.h
                                : 100.h,
                          ),
                          child: TextField(
                            controller: _commentController,
                            maxLines: null,
                            minLines: 1,
                            cursorHeight: 18.h,
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              hintText: 'Izoh yozing...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.r),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 40.w,
                        height: 40.h,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: SvgPicture.asset(
                              'assets/icons/send.svg',
                              width: 20.w,
                              height: 20.h,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            onPressed: () async {
                              if (_commentController.text.isNotEmpty) {
                                try {
                                  final commentDataSource =
                                      getIt<CommentRemoteDataSource>();

                                  await commentDataSource.createComment(
                                    courseId: widget.courseId,
                                    comment: _commentController.text,
                                    rating: 5,
                                    imagePaths: _selectedImagePaths.isNotEmpty
                                        ? _selectedImagePaths
                                        : null,
                                  );

                                  _commentController.clear();
                                  setState(() => _selectedImagePaths.clear());
                                  if (mounted) {
                                    ToastUtils.showSuccess(
                                      context,
                                      'Izoh muvaffaqiyatli yuborildi!',
                                    );
                                    await _loadComments(); // Reload comments
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ToastUtils.showError(context, e);
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 4.h,
              ),
              title: Text(
                'Bu kursdan nma foyda?',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: Text(
                    'Bu kurs orqali siz Flutter asoslarini o\'rganib, professional mobil ilovalar yaratishni boshlaysiz. iOS va Android uchun bir xil kod bilan ishlaydigan ilovalar yaratishni o\'rganasiz.',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParameterItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Color? iconColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFF3572ED)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              size: 28.w,
              color: iconColor ?? const Color(0xFF3572ED),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} oy oldin';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} kun oldin';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} soat oldin';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} daqiqa oldin';
      } else {
        return 'Hozirgina';
      }
    } catch (e) {
      return '';
    }
  }

  void _showFullScreenImage(
    BuildContext context,
    String initialImage,
    List screenshots,
    int initialIndex,
  ) {
    final pageController = PageController(initialPage: initialIndex);
    final currentPage = ValueNotifier<int>(initialIndex);
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: screenshots.length,
              controller: pageController,
              onPageChanged: (index) {
                currentPage.value = index;
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: screenshots[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64.w,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Page indicator
            Positioned(
              bottom: 40.h,
              left: 0,
              right: 0,
              child: Center(
                child: ValueListenableBuilder<int>(
                  valueListenable: currentPage,
                  builder: (context, page, child) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${page + 1}/${screenshots.length}',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40.h,
              right: 16.w,
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 24.w),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
