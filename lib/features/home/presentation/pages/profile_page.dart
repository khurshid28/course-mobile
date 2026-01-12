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

  @override
  void initState() {
    super.initState();
    _clearImageCache();
    _loadUserData();
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
    final userPhone = _user?.phone ?? '';
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
                            colors: [
                              Color(0xFF4C7CFF),
                              Color(0xFF3366FF),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              SizedBox(height: 20.h),
                              // Notification icon
                              Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 24.w),
                                  child: Container(
                                    width: 40.w,
                                    height: 40.h,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 20.sp,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const NotificationsPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.h),
                              // Avatar with image upload functionality
                              GestureDetector(
                                onTap: () {
                                  if (avatarUrl != null && avatarUrl.isNotEmpty) {
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
                                              title: Text('Rasmni o\'zgartirish'),
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
                                          color: Colors.black.withOpacity(0.2),
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
                                                                strokeWidth: 2,
                                                              ),
                                                        ),
                                                    errorWidget:
                                                        (context, url, error) {
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
                                    right: 4,
                                    bottom: 4,
                                    child: Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: _isUploadingImage
                                          ? SizedBox(
                                              width: 20.w,
                                              height: 20.h,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.primary),
                                              ),
                                            )
                                          : SvgPicture.asset(
                                              'assets/icons/camera.svg',
                                              width: 20.w,
                                              height: 20.h,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    AppColors.primary,
                                                    BlendMode.srcIn,
                                                  ),
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
                  ),),

                  // Stats Cards
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
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
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
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
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
                                    'assets/icons/star-fall.svg',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60.h,
                                  color: AppColors.border,
                                ),
                                Expanded(
                                  child: _buildStatCard(
                                    '$_completedCourses',
                                    'Yakunlangan\nkurslar',
                                    'assets/icons/certificate.svg',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60.h,
                                  color: AppColors.border,
                                ),
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
                  ),

                  // Menu Items - As per Figma
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: 12.h),

                        // Ma'lumotlarni tahrirlash
                        _buildMenuItem(
                          'assets/icons/user.svg',
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
                        
                        // Mening kurslarim
                        _buildMenuItem(
                          'assets/icons/courses.svg',
                          'Mening kurslarim',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ActiveCoursesPage(),
                              ),
                            ).then((_) => _loadUserData());
                          },
                        ),
                        
                        // Tranzaksiyalar tarixi
                        _buildMenuItem(
                          'assets/icons/wallet.svg',
                          'Tranzaksiyalar tarixi',
                          () {
                            ToastUtils.showInfo(context, "Jarayonda...");
                          },
                        ),
                        
                        // Til
                        _buildMenuItem(
                          null,
                          'Til',
                          () {
                            ToastUtils.showInfo(context, "Jarayonda...");
                          },
                          icon: Icons.language_rounded,
                          trailing: 'O\'zbekcha',
                        ),
                        
                        // Biz bilan aloqa
                        _buildMenuItem(
                          null,
                          'Biz bilan aloqa',
                          () {
                            ToastUtils.showInfo(context, "Jarayonda...");
                          },
                          icon: Icons.phone_rounded,
                        ),
                        
                        // O'qituvchi bo'lish
                        _buildMenuItem(
                          null,
                          'O\'qituvchi bo\'lish',
                          () {
                            ToastUtils.showInfo(context, "Jarayonda...");
                          },
                          icon: Icons.school_rounded,
                        ),

                        SizedBox(height: 8.h),
                        Divider(height: 1.h, thickness: 1, indent: 16.w, endIndent: 16.w),
                        SizedBox(height: 8.h),

                        // Akkauntdan chiqish
                        _buildMenuItem(
                          'assets/icons/logout.svg',
                          'Akkauntdan chiqish',
                          _logout,
                          color: AppColors.error,
                        ),

                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String value, String label, String iconPath) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        children: [
          SvgPicture.asset(
            iconPath,
            width: 28.w,
            height: 28.h,
            colorFilter: const ColorFilter.mode(
              AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String? iconPath,
    String title,
    VoidCallback onTap, {
    String? trailing,
    Color? color,
    IconData? icon,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: color != null
                  ? [color.withOpacity(0.15), color.withOpacity(0.05)]
                  : [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: icon != null
              ? Icon(icon, size: 22.sp, color: color ?? AppColors.primary)
              : SvgPicture.asset(
                  iconPath!,
                  width: 22.w,
                  height: 22.h,
                  colorFilter: ColorFilter.mode(
                    color ?? AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        trailing: trailing != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20.sp,
                  ),
                ],
              )
            : Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20.sp,
              ),
        onTap: onTap,
      ),
    );
  }
}
