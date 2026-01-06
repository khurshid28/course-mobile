import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/course_remote_datasource.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'payments_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;
  final int? categoryId;

  const MainPage({super.key, this.initialIndex = 0, this.categoryId});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  late int _currentIndex;
  late List<Widget> _pages;
  int? _selectedCategoryId;
  int _activeCoursesCount = 0;
  final GlobalKey<SearchPageState> _searchPageKey =
      GlobalKey<SearchPageState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _selectedCategoryId = widget.categoryId;
    _buildPages();
    _loadActiveCourses();
  }

  // Public method to refresh from other pages
  void refreshActiveCourses() {
    _loadActiveCourses();
  }

  Future<void> _loadActiveCourses() async {
    try {
      final courseDataSource = getIt<CourseRemoteDataSource>();
      final enrolledCourses = await courseDataSource.getEnrolledCourses();

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

      if (mounted) {
        setState(() {
          _activeCoursesCount = activeCourses;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _buildPages() {
    _pages = [
      const HomePage(),
      SearchPage(key: _searchPageKey, categoryId: _selectedCategoryId),
      const PaymentsPage(),
      const ProfilePage(),
    ];
  }

  void updateSearchCategory(int? categoryId) {
    _selectedCategoryId = categoryId;

    // SearchPage state ni to'g'ridan-to'g'ri yangilaymiz
    if (_searchPageKey.currentState != null) {
      _searchPageKey.currentState!.updateCategory(categoryId);
    }
  }

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
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
              icon: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: _currentIndex == 0 ? 1.0 : 0.0,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.85 + (value * 0.15),
                    child: Opacity(
                      opacity: 0.5 + (value * 0.5),
                      child: SvgPicture.asset(
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
                    ),
                  );
                },
              ),
              label: 'Bosh sahifa',
            ),
            BottomNavigationBarItem(
              icon: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: _currentIndex == 1 ? 1.0 : 0.0,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.85 + (value * 0.15),
                    child: Opacity(
                      opacity: 0.5 + (value * 0.5),
                      child: SvgPicture.asset(
                        'assets/icons/courses.svg',
                        width: 24.w,
                        height: 24.h,
                        colorFilter: ColorFilter.mode(
                          _currentIndex == 1
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  );
                },
              ),
              label: 'Kurslar',
            ),
            BottomNavigationBarItem(
              icon: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: _currentIndex == 2 ? 1.0 : 0.0,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.85 + (value * 0.15),
                    child: Opacity(
                      opacity: 0.5 + (value * 0.5),
                      child: SvgPicture.asset(
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
                    ),
                  );
                },
              ),
              label: 'To\'lovlar',
            ),
            BottomNavigationBarItem(
              icon: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: _currentIndex == 3 ? 1.0 : 0.0,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.85 + (value * 0.15),
                    child: Opacity(
                      opacity: 0.5 + (value * 0.5),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SvgPicture.asset(
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
                          if (_activeCoursesCount > 0)
                            Positioned(
                              right: -8,
                              top: -4,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.elasticOut,
                                builder: (context, scaleValue, child) {
                                  return Transform.scale(
                                    scale: scaleValue,
                                    child: Container(
                                      padding: EdgeInsets.all(4.w),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.success,
                                            AppColors.success.withOpacity(0.8),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      constraints: BoxConstraints(
                                        minWidth: 18.w,
                                        minHeight: 18.w,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$_activeCoursesCount',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
