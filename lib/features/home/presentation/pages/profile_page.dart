import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/format_utils.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

      if (!mounted) return;

      setState(() {
        _user = user;
        _coursesCount = savedCourses.length;
        _enrolledCount = enrolledCourses.length;
        _certificatesCount = certificates.length;
        _totalHours = (totalMinutes / 60).ceil();
        _balance = balance;
        _activeCourses = activeCourses;
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

      // Upload image
      final imageUrl = await authDataSource.uploadImage(image.path);

      // Update profile with new avatar
      await authDataSource.completeProfile(
        firstName: _user!.firstName!,
        surname: _user!.surname!,
        email: _user!.email,
        gender: _user!.gender!,
        region: _user!.region!,
        avatar: imageUrl,
      );

      // Reload profile
      await _loadUserData();

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
    final userName = _user != null
        ? '${_user!.firstName ?? ''} ${_user!.surname ?? ''}'.trim()
        : 'Foydalanuvchi';
    final userPhone = _user?.phone ?? '';
    final userInitials =
        _user != null && _user!.firstName != null && _user!.surname != null
        ? '${_user!.firstName![0]}${_user!.surname![0]}'.toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const ProfileShimmer()
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: CustomScrollView(
                slivers: [
                  // Header with gradient background
                  SliverAppBar(
                    expandedHeight: 360.h,
                    pinned: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 60.h),
                            // Settings Button
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 16.w, top: 8.h),
                                child: IconButton(
                                  icon: SvgPicture.asset(
                                    'assets/icons/settings.svg',
                                    width: 24.w,
                                    height: 24.h,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SettingsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            // Avatar with Active Courses Badge
                            GestureDetector(
                              onTap: _isUploadingImage
                                  ? null
                                  : _pickAndUploadImage,
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
                                      radius: 50.r,
                                      backgroundColor: Colors.white,
                                      backgroundImage:
                                          avatarUrl != null &&
                                              avatarUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              avatarUrl,
                                            )
                                          : null,
                                      child:
                                          avatarUrl == null || avatarUrl.isEmpty
                                          ? Text(
                                              userInitials,
                                              style: TextStyle(
                                                fontSize: 32.sp,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : null,
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
                  ),

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
                            // Stats Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    '$_enrolledCount',
                                    'Kurslar',
                                    'assets/icons/courses.svg',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60.h,
                                  color: AppColors.border,
                                ),
                                Expanded(
                                  child: _buildStatCard(
                                    '$_certificatesCount',
                                    'Sertifikatlar',
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
                                    '$_totalHours',
                                    'Soat',
                                    'assets/icons/time.svg',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Menu Items
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: 12.h),

                        _buildMenuItem(
                          'assets/icons/user.svg',
                          'Shaxsiy ma\'lumotlar',
                          () async {
                            if (_user == null) return;

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfilePage(user: _user!),
                              ),
                            );

                            // Reload profile if edited
                            if (result == true) {
                              _loadUserData();
                            }
                          },
                        ),
                        _buildMenuItem(
                          'assets/icons/courses.svg',
                          'Faol kurslar',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ActiveCoursesPage(),
                              ),
                            ).then((_) => _loadUserData());
                          },
                          trailing: '$_activeCourses',
                        ),
                        _buildMenuItem(
                          'assets/icons/book_saved.svg',
                          'Saqlangan kurslar',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SavedCoursesPage(),
                              ),
                            ).then((_) => _loadUserData());
                          },
                          trailing: '$_coursesCount',
                        ),
                        _buildMenuItem(
                          'assets/icons/star-fall.svg',
                          'Mening natijalarim',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ResultsPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          'assets/icons/notification-bell.svg',
                          'Bildirishnomalar',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          'assets/icons/ticket-discount.svg',
                          'Foydalanilgan promo kodlar',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UsedPromoCodesPage(),
                              ),
                            );
                          },
                        ),

                        Divider(height: 32.h, thickness: 1),

                        _buildMenuItem(
                          'assets/icons/logout.svg',
                          'Chiqish',
                          _logout,
                          color: AppColors.error,
                        ),

                        SizedBox(height: 24.h),

                        // Teacher Banner
                        GestureDetector(
                          onTap: () {
                            ToastUtils.showInfo(context, "Jarayonda...");
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 16.w),
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(14.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Icon(
                                    Icons.school_rounded,
                                    color: Colors.white,
                                    size: 32.sp,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'O\'qituvchi bo\'lish',
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Bilimingizni baham ko\'ring va daromad qiling',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
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
    String iconPath,
    String title,
    VoidCallback onTap, {
    String? trailing,
    Color? color,
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
          child: SvgPicture.asset(
            iconPath,
            width: 24.w,
            height: 24.h,
            colorFilter: ColorFilter.mode(
              color ?? AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        trailing: trailing != null
            ? Text(
                trailing,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              )
            : Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 24.sp,
              ),
        onTap: onTap,
      ),
    );
  }
}
