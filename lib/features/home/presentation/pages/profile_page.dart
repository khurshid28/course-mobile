import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../injection_container.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/datasources/test_remote_datasource.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../../auth/presentation/pages/register_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import 'edit_profile_page.dart';
import 'notifications_page.dart';
import 'results_page.dart';
import 'saved_courses_page.dart';
import 'active_courses_page.dart';
import 'balance_topup_page.dart';
import 'used_promo_codes_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  UserModel? _user;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  int _coursesCount = 0;
  int _enrolledCount = 0;
  int _certificatesCount = 0;
  int _totalHours = 0;
  double _balance = 0;
  int _activeCourses = 0;
  int _completedCourses = 0;
  int _completedLessons = 0;
  double _performance = 0.0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _clearImageCache();
    _loadUserData();
    _loadUnreadNotificationCount();
  }

  Future<void> _clearImageCache() async {
    // Clear both cached_network_image and Flutter image cache
    try {
      await CachedNetworkImage.evictFromCache(_user?.avatar ?? '');
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final dataSource = getIt<NotificationRemoteDataSource>();
      final result = await dataSource.getUnreadCount();
      debugPrint('🔔 Profile - Unread count loaded: ${result['count']}');
      if (mounted) {
        setState(() {
          _unreadNotificationCount = result['count'] ?? 0;
        });
        debugPrint('🔔 Profile - State updated: $_unreadNotificationCount');
      }
    } catch (e) {
      debugPrint('❌ Profile - Error loading unread count: $e');
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      final user = await authDataSource.getProfile();

      // Fetch user stats
      final courseDataSource = getIt<CourseRemoteDataSource>();
      final testDataSource = getIt<TestRemoteDataSource>();
      final paymentDataSource = getIt<PaymentRemoteDataSource>();

      final savedCourses = await courseDataSource.getSavedCourses();
      final enrolledCourses = await courseDataSource.getEnrolledCourses();
      final certificates = await testDataSource.getUserCertificates();
      final balance = await paymentDataSource.getBalance();

      // Calculate total hours from enrolled courses
      int totalMinutes = 0;
      for (var course in enrolledCourses) {
        if (course['duration'] != null) {
          totalMinutes += (course['duration'] as num).toInt();
        }
      }

      // Calculate active courses (not expired)
      final now = DateTime.now();
      int activeCourses = 0;
      for (var course in enrolledCourses) {
        if (course['endDate'] == null) {
          activeCourses++;
        } else {
          try {
            final endDate = DateTime.parse(course['endDate']);
            if (endDate.isAfter(now)) {
              activeCourses++;
            }
          } catch (e) {
            activeCourses++;
          }
        }
      }

      // Calculate completed courses and lessons
      int completedLessons = 0;
      int completedCourses = 0;
      for (var course in enrolledCourses) {
        if (course['completed'] == true) {
          completedCourses++;
        }
        if (course['completedSections'] != null) {
          completedLessons += (course['completedSections'] as num).toInt();
        }
      }

      // Calculate performance percentage
      double performance = 0.0;
      if (enrolledCourses.isNotEmpty) {
        performance = (completedCourses / enrolledCourses.length) * 100;
      }

      if (!mounted) return;

      setState(() {
        _user = user;
        _coursesCount = savedCourses.length;
        _enrolledCount = enrolledCourses.length;
        _certificatesCount = certificates.length;
        _totalHours = (totalMinutes / 60).ceil();
        _balance = balance;
        _activeCourses = activeCourses;
        _completedCourses = completedCourses;
        _completedLessons = completedLessons;
        _performance = performance;
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Tilni tanlang',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16.h),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                'O\'zbekcha',
                'uz',
                '🇺🇿',
                true, // Active til
              ),
              Divider(height: 1.h),
              _buildLanguageOption('Русский', 'ru', '🇷🇺', false),
              Divider(height: 1.h),
              _buildLanguageOption('English', 'en', '🇬🇧', false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    String name,
    String code,
    String flag,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ToastUtils.showInfo(context, "Jarayonda...");
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Row(
          children: [
            Text(flag, style: TextStyle(fontSize: 28.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 24.sp),
          ],
        ),
      ),
    );
  }

  void _showImageViewer(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
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
            ),
            Positioned(
              top: 40.h,
              right: 16.w,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();

      print('🔍 Uploading image from path: ${image.path}');
      // Upload image
      final imageUrl = await authDataSource.uploadImage(image.path);
      print('✅ Image uploaded successfully: $imageUrl');

      // Clear old image cache first if exists
      if (_user?.avatar != null) {
        final oldFullImageUrl = _user!.avatar!.startsWith('http')
            ? _user!.avatar!
            : '${AppConstants.baseUrl}${_user!.avatar!}';
        await CachedNetworkImage.evictFromCache(oldFullImageUrl);
      }

      // Update profile with new avatar
      await authDataSource.completeProfile(
        firstName: _user!.firstName!,
        surname: _user!.surname!,
        email: _user!.email,
        gender: _user!.gender!,
        region: _user!.region!,
        avatar: imageUrl,
      );

      // Clear new image cache
      final fullImageUrl = imageUrl.startsWith('http')
          ? imageUrl
          : '${AppConstants.baseUrl}$imageUrl';

      // Clear all image caches
      await CachedNetworkImage.evictFromCache(fullImageUrl);
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Small delay to ensure cache is cleared
      await Future.delayed(const Duration(milliseconds: 100));

      // Reload profile with force refresh
      await _loadUserData();

      // Force rebuild by updating state
      if (mounted) {
        setState(() {});
      }

      if (!mounted) return;

      ToastUtils.showSuccess(context, "Rasm muvaffaqiyatli yangilandi");
    } catch (e) {
      if (!mounted) return;

      ToastUtils.showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/icons/logout.svg',
                  width: 48.w,
                  height: 48.h,
                  colorFilter: const ColorFilter.mode(
                    AppColors.error,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Title
              Text(
                'Chiqish',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),

              // Message
              Text(
                'Haqiqatan ham akkauntdan chiqmoqchimisiz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        side: BorderSide(color: AppColors.border, width: 1.5),
                      ),
                      child: Text(
                        'Bekor qilish',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Chiqish',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final authDataSource = getIt<AuthRemoteDataSource>();
        await authDataSource.logout();

        if (!mounted) return;

        // Navigate to register page and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RegisterPage()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;

        ToastUtils.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _user?.avatar;

    print('👤 User: ${_user?.firstName} ${_user?.surname}');
    print('📸 Avatar URL from _user: $avatarUrl');

    final userName = _user != null
        ? '${_user!.firstName ?? ''} ${_user!.surname ?? ''}'.trim()
        : 'Foydalanuvchi';
    final userPhone = FormatUtils.formatPhoneNumber(_user?.phone);
    final userInitials =
        _user != null && _user!.firstName != null && _user!.surname != null
        ? '${_user!.firstName![0]}${_user!.surname![0]}'.toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const ProfileShimmer()
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: CustomScrollView(
                slivers: [
                  // Header with gradient background and avatar
                  SliverAppBar(
                    expandedHeight: 280.h,
                    pinned: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF4C7CFF), Color(0xFF3366FF)],
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              SizedBox(height: 16.h),
                              // Notification icon
                              Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 16.w),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const NotificationsPage(),
                                            ),
                                          );
                                          // Reload unread count after returning
                                          _loadUnreadNotificationCount();
                                        },
                                        child: Container(
                                          width: 44.w,
                                          height: 44.h,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.15,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: SvgPicture.asset(
                                              'assets/icons/notification.svg',
                                              width: 22.w,
                                              height: 22.h,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Colors.white,
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_unreadNotificationCount > 0)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(4.w),
                                            constraints: BoxConstraints(
                                              minWidth: 18.w,
                                              minHeight: 18.w,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _unreadNotificationCount > 99
                                                    ? '99+'
                                                    : _unreadNotificationCount
                                                          .toString(),
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
                                ),
                              ),
                              SizedBox(height: 24.h),
                              // Avatar with image upload functionality
                              GestureDetector(
                                onTap: () {
                                  if (avatarUrl != null &&
                                      avatarUrl.isNotEmpty) {
                                    showModalBottomSheet(
                                      context: context,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20.r),
                                        ),
                                      ),
                                      builder: (context) => Container(
                                        padding: EdgeInsets.all(20.w),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: Icon(
                                                Icons.visibility,
                                                color: AppColors.primary,
                                              ),
                                              title: Text('Rasmni ko\'rish'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _showImageViewer(
                                                  ImageUtils.getFullImageUrl(
                                                    avatarUrl,
                                                  ),
                                                );
                                              },
                                            ),
                                            ListTile(
                                              leading: Icon(
                                                Icons.photo_camera,
                                                color: AppColors.primary,
                                              ),
                                              title: Text(
                                                'Rasmni o\'zgartirish',
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickAndUploadImage();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    _pickAndUploadImage();
                                  }
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        key: ValueKey(avatarUrl ?? 'no-avatar'),
                                        radius: 50.r,
                                        backgroundColor: Colors.white,
                                        child:
                                            avatarUrl != null &&
                                                avatarUrl.isNotEmpty
                                            ? ClipOval(
                                                child: Builder(
                                                  builder: (context) {
                                                    final fullUrl =
                                                        ImageUtils.getFullImageUrl(
                                                          avatarUrl,
                                                        );
                                                    print(
                                                      '🖼️ Avatar URL: $avatarUrl',
                                                    );
                                                    print(
                                                      '🌐 Full URL: $fullUrl',
                                                    );
                                                    return CachedNetworkImage(
                                                      imageUrl: fullUrl,
                                                      width: 100.r,
                                                      height: 100.r,
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (
                                                            context,
                                                            url,
                                                          ) => Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                  color: AppColors
                                                                      .primary,
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) {
                                                            print(
                                                              '❌ Avatar load error: $error',
                                                            );
                                                            return Text(
                                                              userInitials,
                                                              style: TextStyle(
                                                                fontSize: 32.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: AppColors
                                                                    .primary,
                                                              ),
                                                            );
                                                          },
                                                    );
                                                  },
                                                ),
                                              )
                                            : Text(
                                                userInitials,
                                                style: TextStyle(
                                                  fontSize: 32.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 32.w,
                                        height: 32.h,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF3366FF),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.15,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: _isUploadingImage
                                            ? Padding(
                                                padding: EdgeInsets.all(6.w),
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(AppColors.primary),
                                                ),
                                              )
                                            : Icon(
                                                Icons.add_rounded,
                                                color: const Color(0xFF3366FF),
                                                size: 20.sp,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                userPhone,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              SizedBox(height: 16.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Stats Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        children: [
                          // Balance Card
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BalanceTopupPage(
                                    currentBalance: _balance,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadUserData();
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Balans',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        '${FormatUtils.formatPrice(_balance)} so\'m',
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SvgPicture.asset(
                                    'assets/icons/wallet.svg',
                                    width: 32.w,
                                    height: 32.h,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Stats Row - 3 items as per Figma
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  '${_performance.toStringAsFixed(0)}%',
                                  'Samaradorlik',
                                  'assets/icons/efficiency.svg',
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _buildStatCard(
                                  '$_completedCourses',
                                  'Yakunlangan\nkurslar',
                                  'assets/icons/certificate.svg',
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _buildStatCard(
                                  '$_completedLessons',
                                  'Yakunlangan\ndarslar',
                                  'assets/icons/courses.svg',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Menu Items - As per Figma
                  SliverToBoxAdapter(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 20.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: [
                          // Ma'lumotlarni tahrirlash
                          _buildMenuItem(
                            'assets/icons/edit-profile.svg',
                            'Ma\'lumotlarni tahrirlash',
                            () async {
                              if (_user == null) return;

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfilePage(user: _user!),
                                ),
                              );

                              if (result == true) {
                                _loadUserData();
                              }
                            },
                          ),

                          _buildDivider(),

                          // Mening kurslarim
                          _buildMenuItem(
                            'assets/icons/book-courses.svg',
                            'Mening kurslarim',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ActiveCoursesPage(),
                                ),
                              ).then((_) => _loadUserData());
                            },
                            badge: _enrolledCount > 0
                                ? _enrolledCount.toString()
                                : null,
                          ),

                          _buildDivider(),

                          // Natijalarim
                          _buildMenuItem(
                            'assets/icons/certificate.svg',
                            'Natijalarim',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ResultsPage(),
                                ),
                              );
                            },
                          ),

                          _buildDivider(),

                          // Foydalanilgan promokodlar
                          _buildMenuItem(
                            'assets/icons/tag.svg',
                            'Foydalanilgan promokodlar',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UsedPromoCodesPage(),
                                ),
                              );
                            },
                          ),

                          _buildDivider(),

                          // Til
                          _buildMenuItem(
                            'assets/icons/language.svg',
                            'Til',
                            () {
                              _showLanguageDialog();
                            },
                            trailing: 'O\'zbekcha',
                          ),

                          _buildDivider(),

                          // Biz bilan aloqa
                          _buildMenuItem(
                            'assets/icons/telegram.svg',
                            'Biz bilan aloqa',
                            () {
                              ToastUtils.showInfo(context, "Jarayonda...");
                            },
                          ),

                          _buildDivider(),

                          // O'qituvchi bo'lish
                          _buildMenuItem(
                            'assets/icons/telegram.svg',
                            'O\'qituvchi bo\'lish',
                            () {
                              ToastUtils.showInfo(context, "Jarayonda...");
                            },
                          ),

                          _buildDivider(),

                          // Akkauntdan chiqish
                          _buildMenuItem(
                            'assets/icons/logout-icon.svg',
                            'Akkauntdan chiqish',
                            _logout,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 32.h)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String value, String label, String iconPath) {
    return Container(
      height: 110.h, // Fixed height for consistency
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            textAlign: TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
              height: 1.2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 24.w,
                height: 24.h,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF3366FF),
                  BlendMode.srcIn,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    dynamic icon,
    String title,
    VoidCallback onTap, {
    String? trailing,
    String? badge,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? AppColors.error : const Color(0xFF6B7280);

    debugPrint('🎨 Building menu item: $title');
    debugPrint('   Icon type: ${icon is String ? "SVG" : "IconData"}');
    debugPrint('   Icon color: $iconColor');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 24.sp,
              height: 24.sp,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.transparent),
              child: icon is String
                  ? SvgPicture.asset(
                      icon,
                      width: 24.sp,
                      height: 24.sp,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    )
                  : IconTheme(
                      data: const IconThemeData(
                        color: Color(0xFF6B7280),
                        size: 24,
                        opacity: 1.0,
                      ),
                      child: Icon(
                        icon as IconData,
                        size: 24.sp,
                        color: const Color(0xFF6B7280),
                        applyTextScaling: false,
                      ),
                    ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                  color: isDestructive
                      ? AppColors.error
                      : const Color(0xFF1F2937),
                ),
                overflow: TextOverflow.visible,
                maxLines: 1,
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: 8.w),
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
            if (badge != null) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                constraints: BoxConstraints(minWidth: 28.w),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1.h, thickness: 1.h, color: const Color(0xFFF3F4F6));
  }
}
