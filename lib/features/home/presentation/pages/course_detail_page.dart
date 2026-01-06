import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/course_rating_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/section_model.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/datasources/saved_courses_local_datasource.dart';
import '../../data/datasources/comment_remote_datasource.dart';
import '../../../../injection_container.dart';
import 'checkout_page.dart';
import 'video_player_page.dart';
import '../../../test/presentation/screens/test_list_screen.dart';
import '../../../test/data/repositories/test_repository.dart';
import 'results_page.dart';

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
  bool _isEnrolled = false;
  bool _isLoadingRating = false;
  Map<String, dynamic>? courseData;
  final TextEditingController _commentController = TextEditingController();
  int? _userCourseRating;
  List<dynamic> _comments = [];
  bool _isLoadingComments = false;
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadCourseDetails();
    _loadUserCourseRating();
    _loadComments();
  }

  void _handleTabChange() {
    // Unfocus when changing tabs to hide keyboard
    if (!_tabController.indexIsChanging) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _formatDuration(dynamic durationValue) {
    if (durationValue == null) return '0:00';

    // Convert to int (handle both int and String types)
    int seconds;
    if (durationValue is int) {
      seconds = durationValue;
    } else if (durationValue is String) {
      seconds = int.tryParse(durationValue) ?? 0;
    } else if (durationValue is double) {
      seconds = durationValue.toInt();
    } else {
      return '0:00';
    }

    if (seconds == 0) return '0:00';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _loadUserCourseRating() async {
    setState(() => _isLoadingRating = true);
    try {
      final dataSource = getIt<CourseRemoteDataSource>();
      final rating = await dataSource.getUserCourseRating(widget.courseId);
      if (mounted) {
        setState(() {
          final ratingValue =
              rating['userRating']; // Backend returns 'userRating'
          _userCourseRating = ratingValue != null
              ? (ratingValue is num ? ratingValue.toInt() : null)
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
      final response = await dataSource.rateCourse(widget.courseId, rating);
      if (!mounted) return;

      // Update local state with response data
      setState(() {
        _userCourseRating = rating;
        // Update average rating from response
        if (courseData != null && response['averageRating'] != null) {
          final avgRating = response['averageRating'];
          courseData!['rating'] = avgRating is num ? avgRating.toDouble() : 0.0;
          if (response['totalRatings'] != null) {
            courseData!['_count'] = courseData!['_count'] ?? {};
            courseData!['_count']['ratings'] = response['totalRatings'];
          }
        }
      });

      ToastUtils.showSuccess(context, 'Baho muvaffaqiyatli saqlandi!');
    } catch (e) {
      print('Rating error: $e');
      if (mounted) {
        ToastUtils.showError(context, 'Baholashda xatolik: ${e.toString()}');
      }
    }
  }

  Future<void> _handleDeleteRating() async {
    try {
      final dataSource = getIt<CourseRemoteDataSource>();
      final response = await dataSource.deleteRating(widget.courseId);
      if (!mounted) return;

      // Update local state with response data
      setState(() {
        _userCourseRating = null;
        // Update average rating from response
        if (courseData != null && response['averageRating'] != null) {
          final avgRating = response['averageRating'];
          courseData!['rating'] = avgRating is num ? avgRating.toDouble() : 0.0;
          if (response['totalRatings'] != null) {
            courseData!['_count'] = courseData!['_count'] ?? {};
            courseData!['_count']['ratings'] = response['totalRatings'];
          }
        }
      });

      ToastUtils.showSuccess(context, 'Baho o\'chirildi');
    } catch (e) {
      print('Delete rating error: $e');
      if (mounted) {
        ToastUtils.showError(
          context,
          'Bahoni o\'chirishda xatolik: ${e.toString()}',
        );
      }
    }
  }

  String _calculateTotalDuration() {
    if (courseData == null || courseData!['sections'] == null) return 'N/A';

    int totalMinutes = 0;
    final sections = courseData!['sections'] as List<dynamic>;

    for (var section in sections) {
      if (section['videos'] != null) {
        final videos = section['videos'] as List<dynamic>;
        for (var video in videos) {
          if (video['duration'] != null) {
            totalMinutes += (video['duration'] is int
                ? video['duration'] as int
                : int.tryParse(video['duration'].toString()) ?? 0);
          }
        }
      }
    }

    if (totalMinutes < 60) {
      return '$totalMinutes daqiqa';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return minutes > 0 ? '$hours soat $minutes daqiqa' : '$hours soat';
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

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ToastUtils.showInfo(context, 'Maksimum 5 ta rasm yuklash mumkin');
      return;
    }

    try {
      final remainingSlots = 5 - _selectedImages.length;
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.take(remainingSlots));
        });

        if (images.length > remainingSlots) {
          ToastUtils.showInfo(
            context,
            'Faqat $remainingSlots ta rasm qo\'shildi',
          );
        }
      }
    } catch (e) {
      ToastUtils.showError(context, 'Rasm tanlashda xatolik: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ToastUtils.showError(context, 'Izoh yozish majburiy');
      return;
    }

    try {
      final commentDataSource = getIt<CommentRemoteDataSource>();

      // Convert XFile paths to string list for backend
      final imagePaths = _selectedImages.map((file) => file.path).toList();

      await commentDataSource.createComment(
        courseId: widget.courseId,
        comment: _commentController.text.trim(),
        rating: 0,
        images: imagePaths.isNotEmpty ? imagePaths : null,
      );

      if (!mounted) return;

      ToastUtils.showSuccess(context, 'Izohingiz qo\'shildi');
      _commentController.clear();
      setState(() {
        _selectedImages.clear();
      });
      _loadComments();
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context, 'Xatolik yuz berdi: $e');
    }
  }

  Future<void> _loadCourseDetails() async {
    try {
      final dataSource = getIt<CourseRemoteDataSource>();
      final course = await dataSource.getCourseById(widget.courseId);

      if (!mounted) return;

      print('=== COURSE DETAIL DEBUG ===');
      print('Full course data: $course');
      print('isEnrolled value: ${course['isEnrolled']}');
      print('isEnrolled type: ${course['isEnrolled'].runtimeType}');
      print('isFree value: ${course['isFree']}');
      print('isFree type: ${course['isFree'].runtimeType}');
      print('Course rating: ${course['rating']}');
      print('Total ratings count: ${course['_count']?['ratings']}');
      print('=========================');

      setState(() {
        courseData = course;
        _isEnrolled = course['isEnrolled'] == true;
        isSaved = course['isSaved'] ?? false;
        isLoading = false;
      });
    } catch (e) {
      print('Load course error: $e');
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

  String _formatRating(dynamic rating) {
    if (rating == null) return '0.0';
    if (rating is num) return rating.toDouble().toStringAsFixed(1);
    if (rating is String) {
      final parsed = double.tryParse(rating);
      return parsed?.toStringAsFixed(1) ?? '0.0';
    }
    return '0.0';
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    if (price is num) return price.toString();
    if (price is String) return price;
    return '0';
  }

  bool _hasOldPrice(dynamic oldPrice) {
    if (oldPrice == null) return false;
    if (oldPrice is num) return oldPrice > 0;
    if (oldPrice is String) {
      final parsed = num.tryParse(oldPrice);
      return parsed != null && parsed > 0;
    }
    return false;
  }

  bool _shouldShowPurchaseButton() {
    if (courseData == null) {
      print('DEBUG: Purchase button hidden - courseData is null');
      return false;
    }

    final isEnrolled = courseData!['isEnrolled'];
    final isFree = courseData!['isFree'];

    print(
      'DEBUG: _shouldShowPurchaseButton - isEnrolled: $isEnrolled (${isEnrolled.runtimeType}), isFree: $isFree (${isFree.runtimeType})',
    );

    // Show purchase button only if NOT enrolled AND NOT free
    if (isEnrolled == true || isFree == true) {
      print(
        'DEBUG: Purchase button hidden - isEnrolled=$isEnrolled, isFree=$isFree',
      );
      return false;
    }

    print(
      'DEBUG: Purchase button SHOWN - isEnrolled=$isEnrolled, isFree=$isFree',
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: CourseDetailShimmer(),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                    courseData?['title'] ?? 'Kurs nomi yuklanmoqda...',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                        courseData?['rating'] != null
                            ? _formatRating(courseData!['rating'])
                            : '0.0',
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
                        '${(courseData?['_count']?['enrollments'] ?? 0).toString()} talaba',
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
                        '${(courseData?['_count']?['sections'] ?? 0).toString()} video',
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
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child:
                            courseData?['teacher']?['avatar'] != null &&
                                courseData!['teacher']['avatar']
                                    .toString()
                                    .isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: courseData!['teacher']['avatar'],
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
                              '${courseData?['teacher']?['firstName'] ?? ''} ${courseData?['teacher']?['surname'] ?? ''}',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              courseData?['teacher']?['bio'] ?? 'O\'qituvchi',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_hasOldPrice(courseData?['oldPrice']))
                            Text(
                              '${_formatPrice(courseData!['oldPrice'])} so\'m',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey,
                                decorationThickness: 2,
                              ),
                            ),
                          if (_hasOldPrice(courseData?['oldPrice']))
                            SizedBox(height: 2.h),
                          Text(
                            courseData?['isFree'] == true
                                ? 'Bepul'
                                : courseData?['price'] != null
                                ? '${_formatPrice(courseData!['price'])} so\'m'
                                : '0 so\'m',
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

                  // Course Rating Widget
                  if (courseData != null)
                    Container(
                      margin: EdgeInsets.only(bottom: 20.h),
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CourseRatingWidget(
                        userRating: _userCourseRating,
                        averageRating: (courseData!['rating'] is num
                            ? (courseData!['rating'] as num).toDouble()
                            : 0.0),
                        totalRatings: courseData!['_count']?['ratings'] ?? 0,
                        onRate: _handleCourseRate,
                        onDelete: _userCourseRating != null
                            ? _handleDeleteRating
                            : null,
                      ),
                    ),

                  // Test section (only if enrolled)
                  if (_isEnrolled) ...[
                    SizedBox(height: 16.h),
                    _buildTestSection(),
                  ],

                  SizedBox(height: 16.h),

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
                                value:
                                    '${(courseData?['_count']?['sections'] ?? 0).toString()} ta',
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
                                value: _calculateTotalDuration(),
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
                                value:
                                    courseData?['level']?.toString() ?? 'N/A',
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
      bottomNavigationBar: _shouldShowPurchaseButton()
          ? Container(
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

                            // Always reload course data after returning from checkout
                            if (mounted) {
                              setState(() {
                                isLoading = true;
                              });
                              await _loadCourseDetails();
                              await _loadUserCourseRating();
                              if (mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                                // Show success message if purchase was successful
                                if (result == true) {
                                  ToastUtils.showSuccess(
                                    context,
                                    'Kurs muvaffaqiyatli sotib olindi!',
                                  );
                                }
                              }
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
                        Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 20.sp,
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
            )
          : null,
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

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // Course sections
        ...sections.asMap().entries.map((entry) {
          return _buildSectionCard(entry.value, entry.key);
        }).toList(),
      ],
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> section, int index) {
    final videos = section['videos'] as List<dynamic>? ?? [];

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
            section['title']?.toString() ?? 'Bo\'lim ${index + 1}',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${videos.length} video',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
          ),
          children: videos.asMap().entries.map((entry) {
            final videoIndex = entry.key;
            final video = entry.value;
            return _buildVideoItem(video, videoIndex);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video, int index) {
    final isEnrolled = courseData?['isEnrolled'] == true;
    final isCourseFreee = courseData?['isFree'] == true;
    final isFree = video['isFree'] == true;
    final canAccess = isFree || isEnrolled || isCourseFreee;

    print(
      'DEBUG: Video ${index + 1} - isEnrolled: $isEnrolled, isCourseFreee: $isCourseFreee, videoIsFree: $isFree, canAccess: $canAccess',
    );

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
            color: canAccess
                ? const Color(0xFF3572ED).withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.play_arrow,
            color: canAccess ? const Color(0xFF3572ED) : Colors.grey,
            size: 24.w,
          ),
        ),
        title: Text(
          video['title']?.toString() ?? 'Video ${index + 1}',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.access_time, size: 12.sp, color: Colors.grey),
            SizedBox(width: 4.w),
            Text(
              _formatDuration(video['duration']),
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
          canAccess ? Icons.lock_open : Icons.lock_outline,
          color: canAccess ? Colors.green : Colors.grey,
          size: 20.w,
        ),
        onTap: canAccess
            ? () {
                // Get all sections and videos
                final sections =
                    courseData?['sections'] as List<dynamic>? ?? [];

                if (sections.isEmpty) {
                  ToastUtils.showError(context, 'Videolar topilmadi');
                  return;
                }

                // Calculate global video index
                int globalIndex = 0;
                bool found = false;

                for (var section in sections) {
                  if (section['videos'] != null) {
                    final sectionVideos = section['videos'] as List<dynamic>;
                    for (int i = 0; i < sectionVideos.length; i++) {
                      if (i == index && !found) {
                        found = true;
                        break;
                      }
                      if (!found) globalIndex++;
                    }
                    if (found) break;
                  }
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                      sections: sections.cast<Map<String, dynamic>>(),
                      initialIndex: globalIndex,
                      title: video['title'] ?? 'Video ${index + 1}',
                      courseTitle: courseData?['title'] ?? '',
                      isLocked: !canAccess,
                    ),
                  ),
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
    if (_isLoadingComments) {
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: ListItemShimmer(),
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Not enrolled message
        if (!_isEnrolled)
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Kursni sotib oling va izoh qoldiring',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Comment input section (only if enrolled)
        if (_isEnrolled)
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Izoh qoldiring',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Focus(
                    onFocusChange: (hasFocus) {
                      if (hasFocus) {
                        // Scroll to show TextField when focused
                        Future.delayed(Duration(milliseconds: 300), () {
                          if (mounted) {
                            Scrollable.ensureVisible(
                              context,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        });
                      }
                    },
                    child: TextField(
                      controller: _commentController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Fikringizni yozing...',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.all(12.w),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Image preview
                  if (_selectedImages.isNotEmpty)
                    Container(
                      height: 80.h,
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(right: 8.w),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.file(
                                    File(_selectedImages[index].path),
                                    width: 80.w,
                                    height: 80.h,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4.h,
                                  right: 4.w,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: EdgeInsets.all(4.w),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 16.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: Icon(Icons.add_photo_alternate, size: 18.sp),
                        label: Text(
                          'Rasm (${_selectedImages.length}/5)',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: _submitComment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Yuborish',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Comments list
        _comments.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(40.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.15),
                                AppColors.primary.withOpacity(0.08),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 64.sp,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Hozircha izohlar yo\'q',
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        if (_isEnrolled) ...[
                          Text(
                            'Birinchi bo\'lib izoh qoldiring!',
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.primary,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Fikrlaringizni baham ko\'ring',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32.w),
                            child: Text(
                              'Kursni sotib oling va izohlar qoldiring',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: EdgeInsets.all(16.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
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
                                          imageUrl: user['avatar'],
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
                                      '${user?['firstName']?.toString() ?? ''} ${user?['surname']?.toString() ?? ''}',
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
                                                      (comment['rating'] is int
                                                          ? comment['rating']
                                                          : (comment['rating']
                                                                    is String
                                                                ? int.tryParse(
                                                                        comment['rating'],
                                                                      ) ??
                                                                      0
                                                                : 0))
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
                            comment['comment']?.toString() ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                          // Display images if available
                          if (comment['images'] != null &&
                              comment['images'].toString().isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 12.h),
                              child: SizedBox(
                                height: 100.h,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _parseImages(
                                    comment['images'],
                                  ).length,
                                  itemBuilder: (context, imgIndex) {
                                    final imageUrl = _parseImages(
                                      comment['images'],
                                    )[imgIndex];
                                    return Container(
                                      margin: EdgeInsets.only(right: 8.w),
                                      child: GestureDetector(
                                        onTap: () {
                                          // Show full image with pagination
                                          final allImages = _parseImages(
                                            comment['images'],
                                          );
                                          _showImageGallery(
                                            context,
                                            allImages,
                                            imgIndex,
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            width: 100.w,
                                            height: 100.h,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                                  color: Colors.grey.shade200,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              AppColors.primary,
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
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                        size: 24.sp,
                                                      ),
                                                      SizedBox(height: 4.h),
                                                      Text(
                                                        'Yuklanmadi',
                                                        style: TextStyle(
                                                          fontSize: 10.sp,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }, childCount: _comments.length),
                ),
              ),
      ],
    );
  }

  List<String> _parseImages(dynamic images) {
    if (images == null) return [];

    List<String> imagePaths = [];

    if (images is String) {
      if (images.isEmpty) return [];

      try {
        // Try parsing as JSON array first
        if (images.contains('[') && images.contains(']')) {
          final decoded = images
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .replaceAll("'", '')
              .split(',');
          imagePaths = decoded
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          // Single image or comma-separated
          imagePaths = images
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (e) {
        print('Error parsing images: $e');
        return [];
      }
    } else if (images is List) {
      imagePaths = images.map((e) => e.toString()).toList();
    }

    // Convert relative paths to full URLs
    return imagePaths.map((path) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path; // Already a full URL
      } else if (path.startsWith('/')) {
        return '${AppConstants.baseUrl}$path';
      } else {
        return '${AppConstants.baseUrl}/uploads/images/$path';
      }
    }).toList();
  }

  Widget _buildTestSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 32.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test sinovlari',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Bilimingizni sinab ko\'ring va sertifikat oling',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TestListScreen(
                          courseId: widget.courseId,
                          repository: getIt<TestRepository>(),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.play_circle_filled, size: 22.sp),
                  label: Text(
                    'Testni boshlash',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF6366F1),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResultsPage(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                  tooltip: 'Natijalar',
                ),
              ),
            ],
          ),
        ],
      ),
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

  void _showImageGallery(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) =>
          _ImageGalleryDialog(images: images, initialIndex: initialIndex),
    );
  }
}

class _ImageGalleryDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageGalleryDialog({required this.images, required this.initialIndex});

  @override
  State<_ImageGalleryDialog> createState() => _ImageGalleryDialogState();
}

class _ImageGalleryDialogState extends State<_ImageGalleryDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 64.sp,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Rasmni yuklab bo\'lmadi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: 40.h,
            right: 16.w,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.white, size: 28.sp),
              ),
            ),
          ),

          // Pagination indicator (like Telegram)
          if (widget.images.length > 1)
            Positioned(
              bottom: 40.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.images.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
