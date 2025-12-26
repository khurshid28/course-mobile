import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../data/models/section_model.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/datasources/saved_courses_local_datasource.dart';
import '../../data/datasources/comment_remote_datasource.dart';
import '../../../../injection_container.dart';
import 'checkout_page.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCourseDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
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
                  Row(
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
                        '4.8',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.person_outline,
                        size: 16.w,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '250 talaba',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.play_circle_outline,
                        size: 16.w,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '24 video',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
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
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSectionsTab(),
                _buildCommentsTab(),
                _buildFaqTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
          child: ElevatedButton(
            onPressed: courseData == null
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(course: courseData!),
                      ),
                    );
                    
                    // If purchase successful, reload course and notify parent
                    if (result == true && mounted) {
                      await _loadCourseDetails();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3572ED),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Kursni Sotib Olish',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _buildSectionCard(index);
      },
    );
  }

  Widget _buildSectionCard(int index) {
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
            'Bo\'lim ${index + 1}: Flutter Asoslari',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '5 video • 45 daqiqa',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
          ),
          children: List.generate(5, (videoIndex) {
            final isFree = videoIndex < 2;
            return _buildVideoItem(videoIndex, isFree);
          }),
        ),
      ),
    );
  }

  Widget _buildVideoItem(int index, bool isFree) {
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
          'Video ${index + 1}: Flutter nima?',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '8 daqiqa',
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
        onTap: isFree
            ? () {
                // TODO: Navigate to video player page
                ToastUtils.showInfo(
                  context,
                  'Video ${index + 1} ochilmoqda...',
                );
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
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: 5,
            itemBuilder: (context, index) {
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
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: const CachedNetworkImageProvider(
                            'https://i.pravatar.cc/150?img=2',
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jasur Abdullayev',
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
                                        starIndex < 5
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
                          '2 kun oldin',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Ajoyib kurs! Flutter asoslarini juda yaxshi tushuntirgan. Amaliy mashqlar ham ko\'p. O\'qituvchining tushuntirish uslubi aniq va tushunarli.',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
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
                SizedBox(width: 8.w),
                Container(
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
                          final commentDataSource = getIt<CommentRemoteDataSource>();
                          await commentDataSource.createComment(
                            courseId: widget.courseId,
                            comment: _commentController.text,
                            rating: 5,
                          );
                          
                          _commentController.clear();
                          if (mounted) {
                            ToastUtils.showSuccess(context, 'Izoh muvaffaqiyatli yuborildi!');
                            await _loadCourseDetails();
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
