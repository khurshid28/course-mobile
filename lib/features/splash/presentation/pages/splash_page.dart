import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/pages/register_page.dart';
import '../../../home/presentation/pages/main_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Check for token and navigate accordingly
    Timer(const Duration(seconds: 3), () async {
      final prefs = getIt<SharedPreferences>();
      final token = prefs.getString(AppConstants.tokenKey);

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        // Token exists, navigate to home
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
      } else {
        // No token, navigate to register
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RegisterPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120.w,
                  height: 120.h,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/logo.svg',
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Course Platform',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'O\'rganing va rivojlaning',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
