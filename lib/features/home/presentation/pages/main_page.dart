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
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF3366FF),
            unselectedItemColor: const Color(0xFF9E9E9E),
            selectedFontSize: 12.sp,
            unselectedFontSize: 11.sp,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.8,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              height: 1.8,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: SvgPicture.asset(
                    'assets/icons/home.svg',
                    width: 24.w,
                    height: 24.h,
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 0
                          ? const Color(0xFF3366FF)
                          : const Color(0xFF9E9E9E),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: 'Asosiy',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: SvgPicture.asset(
                    'assets/icons/courses.svg',
                    width: 24.w,
                    height: 24.h,
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 1
                          ? const Color(0xFF3366FF)
                          : const Color(0xFF9E9E9E),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: 'Kurslar',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: SvgPicture.asset(
                    'assets/icons/history.svg',
                    width: 24.w,
                    height: 24.h,
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 2
                          ? const Color(0xFF3366FF)
                          : const Color(0xFF9E9E9E),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: 'Reyting',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/user.svg',
                        width: 24.w,
                        height: 24.h,
                        colorFilter: ColorFilter.mode(
                          _currentIndex == 3
                              ? const Color(0xFF3366FF)
                              : const Color(0xFF9E9E9E),
                          BlendMode.srcIn,
                        ),
                      ),
                      if (_activeCoursesCount > 0)
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
                                _activeCoursesCount > 9
                                    ? '9+'
                                    : _activeCoursesCount.toString(),
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
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
