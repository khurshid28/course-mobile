import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'payments_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    SearchPage(),
    PaymentsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12.sp,
          unselectedFontSize: 12.sp,
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/logo.svg',
                width: 24.w,
                height: 24.h,
                colorFilter: ColorFilter.mode(
                  _currentIndex == 0
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Bosh sahifa',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/video-file.svg',
                width: 24.w,
                height: 24.h,
                colorFilter: ColorFilter.mode(
                  _currentIndex == 1
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Kurslar',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/history.svg',
                width: 24.w,
                height: 24.h,
                colorFilter: ColorFilter.mode(
                  _currentIndex == 2
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
              label: 'To\'lovlar',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/user.svg',
                width: 24.w,
                height: 24.h,
                colorFilter: ColorFilter.mode(
                  _currentIndex == 3
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
