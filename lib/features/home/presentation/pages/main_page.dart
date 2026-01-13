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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  iconPath: 'assets/icons/home-new.svg',
                  label: 'Asosiy',
                ),
                _buildNavItem(
                  index: 1,
                  iconPath: 'assets/icons/book-courses.svg',
                  label: 'Kurslar',
                ),
                _buildNavItem(
                  index: 2,
                  iconPath: 'assets/icons/history.svg',
                  label: 'To\'lovlar',
                ),
                _buildNavItem(
                  index: 3,
                  iconPath: 'assets/icons/user.svg',
                  label: 'Profil',
                  showBadge: _activeCoursesCount > 0,
                  badgeCount: _activeCoursesCount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required String label,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? const Color(0xFF3366FF)
        : const Color(0xFF6B7280);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24.w,
                  height: 24.h,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                if (showBadge && badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16.w,
                        minHeight: 16.h,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
