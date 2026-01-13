import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/image_utils.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../../../injection_container.dart';
import 'course_detail_page.dart';
import 'teacher_detail_page.dart';

class SearchPage extends StatefulWidget {
  final int? categoryId;

  const SearchPage({Key? key, this.categoryId}) : super(key: key);

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  bool _isLoadingCourses = false;
  List<Map<String, dynamic>> _courseResults = [];
  List<Map<String, dynamic>> _allCourses = []; // Cache for all courses
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _teachers = []; // All teachers for filter
  int? _selectedCategoryId;

  // Filter variables
  List<int> _selectedTeacherIds = [];
  String? _selectedPriceFilter; // 'free' or 'paid'
  String? _selectedLevelFilter; // 'BEGINNER', 'INTERMEDIATE', 'ADVANCED'

  bool get _hasActiveFilters =>
      _selectedTeacherIds.isNotEmpty ||
      _selectedPriceFilter != null ||
      _selectedLevelFilter != null;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _loadCategories();
    _loadTeachers();
    _loadDefaultCourses();
    if (_selectedCategoryId != null) {
      _loadCoursesByCategory(_selectedCategoryId!);
    }
  }

  @override
  void didUpdateWidget(SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.categoryId != widget.categoryId) {
      setState(() {
        _selectedCategoryId = widget.categoryId;
      });

      if (_selectedCategoryId != null) {
        _loadCoursesByCategory(_selectedCategoryId!);
      } else {
        setState(() {
          _courseResults = _allCourses;
        });
      }
    }
  }

  Future<void> _loadTeachers() async {
    try {
      final courseDataSource = getIt<CourseRemoteDataSource>();
      final teachers = await courseDataSource.getAllTeachers();
      if (mounted) {
        setState(() {
          _teachers = teachers.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading teachers: $e');
    }
  }

  Future<void> _loadDefaultCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final courseDataSource = getIt<CourseRemoteDataSource>();
      final courses = await courseDataSource.getAllCourses();

      if (!mounted) return;

      setState(() {
        _allCourses = courses.cast<Map<String, dynamic>>();
        _courseResults = _allCourses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _courseResults = [];
        _isLoadingCourses = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categoryDataSource = getIt<CategoryRemoteDataSource>();
      final categoriesData = await categoryDataSource.getAllCategories();

      if (!mounted) return;

      setState(() {
        _categories = categoriesData.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (!mounted) return;
    }
  }

  // Public method to update category from MainPage
  void updateCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;

    setState(() {
      _selectedCategoryId = categoryId;
      _searchController.clear(); // Qidiruv matnini tozalaymiz
    });

    // Yangi kategoriya bo'yicha filtrlaymiz
    if (_selectedCategoryId != null) {
      if (_tabController.index == 0) {
        // Courses tab
        _loadCoursesByCategory(_selectedCategoryId!);
      } else {
        // Teachers tab
        _searchTeachers('');
      }
    } else {
      // Kategoriya olib tashlangan bo'lsa, barcha natijalarni ko'rsatamiz
      setState(() {
        _courseResults = _allCourses;
        _teacherResults = _allTeachers;
      });
    }
  }

  @override
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty && _selectedCategoryId == null) {
      setState(() {
        _courseResults = _allCourses;
        _teacherResults = _allTeachers;
      });
      return;
    }

    if (_tabController.index == 0) {
      // Courses tab
      if (_selectedCategoryId != null) {
        _loadCoursesByCategory(_selectedCategoryId!, query);
      } else if (query.isNotEmpty) {
        _searchCourses(query);
      } else {
        setState(() {
          _courseResults = _allCourses;
        });
      }
    } else {
      // Teachers tab
      _searchTeachers(query);
    }
  }

  Future<void> _loadCoursesByCategory(int categoryId, [String? query]) async {
    // Filter from cache instead of API call
    List<Map<String, dynamic>> filteredCourses = _allCourses.where((course) {
      return course['categoryId'] == categoryId;
    }).toList();

    // Apply search filter if query provided
    if (query != null && query.isNotEmpty) {
      filteredCourses = filteredCourses.where((course) {
        final title = (course['title'] ?? '').toString().toLowerCase();
        return title.contains(query.toLowerCase());
      }).toList();
    }

    setState(() {
      _courseResults = filteredCourses;
    });
  }

  Future<void> _searchCourses(String query) async {
    // Filter from cache
    final filteredCourses = _allCourses.where((course) {
      final title = (course['title'] ?? '').toString().toLowerCase();
      final subtitle = (course['subtitle'] ?? '').toString().toLowerCase();
      final searchQuery = query.toLowerCase();
      return title.contains(searchQuery) || subtitle.contains(searchQuery);
    }).toList();

    setState(() {
      _courseResults = filteredCourses;
    });
  }

  Future<void> _searchTeachers(String query) async {
    // If teachers not loaded yet, load them once
    if (!_teachersLoaded) {
      setState(() {
        _isLoadingTeachers = true;
      });

      try {
        final courseDataSource = getIt<CourseRemoteDataSource>();
        final teachers = await courseDataSource.getAllTeachers();

        if (!mounted) return;

        setState(() {
          _allTeachers = teachers.cast<Map<String, dynamic>>();
          _teachersLoaded = true;
          _isLoadingTeachers = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _allTeachers = [];
          _isLoadingTeachers = false;
        });
        return;
      }
    }

    // Filter from cache
    List<Map<String, dynamic>> filteredTeachers = _allTeachers;

    // Apply category filter if selected
    if (_selectedCategoryId != null) {
      filteredTeachers = filteredTeachers.where((teacher) {
        // Check if teacher has courses in the selected category
        final courses = teacher['courses'];
        if (courses == null || courses is! List) return false;

        // Check if any course belongs to the selected category
        return courses.any((course) {
          return course['categoryId'] == _selectedCategoryId;
        });
      }).toList();
    }

    // Apply search query filter
    if (query.isNotEmpty) {
      filteredTeachers = filteredTeachers.where((teacher) {
        final name = (teacher['name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    }

    setState(() {
      _teacherResults = filteredTeachers;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.h,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,

        elevation: 0,
        // flexibleSpace: Container(
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //       colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //     ),
        //   ),
        // ),
        title: SizedBox(
          height: 48.h,
          // decoration: BoxDecoration(
          //   color: Colors.white.withOpacity(0.2),
          //   borderRadius: BorderRadius.circular(24.r),
          //   border: Border.all(
          //     color: Colors.white.withOpacity(0.3),
          //     width: 1,
          //   ),
          // ),
          child: TextField(
            controller: _searchController,
            cursorHeight: 20.h,
            cursorColor: Colors.white,

            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              fillColor: Colors.white.withOpacity(0.4),
              filled: true,
              hintText: 'Qidirish...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15.sp,
              ),
              // border: InputBorder.none,
              // enabledBorder: InputBorder.none,
              // focusedBorder: InputBorder.none,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide.none,
              ),
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.w),
                child: SvgPicture.asset(
                  'assets/icons/search-alt.svg',
                  width: 20.w,
                  height: 20.h,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                        setState(() {
                          _selectedCategoryId = null;
                        });
                      },
                    ),
                  Stack(
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/filter.svg',
                          width: 20.w,
                          height: 20.h,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: _showFilterBottomSheet,
                      ),
                      if (_hasActiveFilters)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              isDense: true,
            ),
            onChanged: _performSearch,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white.withOpacity(0.95)],
                ),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.all(4.w),
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 18.sp),
                      SizedBox(width: 6.w),
                      const Text('Kurslar'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/user.svg',
                        width: 18.w,
                        height: 18.h,
                        colorFilter: ColorFilter.mode(
                          _tabController.index == 1
                              ? AppColors.primary
                              : Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      const Text('O\'qituvchilar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Categories Horizontal List
          if (_categories.isNotEmpty)
            Container(
              height: 60.h,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _selectedCategoryId == null
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Barchasi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = null;
                                  _courseResults = _allCourses;
                                });

                                // Update teachers tab too
                                if (_tabController.index == 1 &&
                                    _teachersLoaded) {
                                  _searchTeachers('');
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  'Barchasi',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            ),
                    );
                  }

                  final category = _categories[index - 1];
                  final isSelected = _selectedCategoryId == category['id'];
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: InkWell(
                      onTap: () {
                        final newCategoryId = isSelected
                            ? null
                            : category['id'];
                        setState(() {
                          _selectedCategoryId = newCategoryId;
                        });

                        // Update both courses and teachers based on selected category
                        if (_tabController.index == 0) {
                          // Courses tab
                          if (newCategoryId != null) {
                            _loadCoursesByCategory(newCategoryId, null);
                          } else {
                            setState(() {
                              _courseResults = _allCourses;
                            });
                          }
                        } else {
                          // Teachers tab
                          _searchTeachers('');
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: isSelected
                              ? null
                              : Border.all(color: AppColors.border),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                            ],
                            Text(
                              category['nameUz'] ?? category['name'],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildCoursesTab(), _buildTeachersTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    if (_isLoadingCourses) {
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 5,
        itemBuilder: (context, index) => const CourseCardShimmer(),
      );
    }

    if (_courseResults.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await _loadDefaultCourses();
          if (_selectedCategoryId != null) {
            _loadCoursesByCategory(
              _selectedCategoryId!,
              _searchController.text.isEmpty ? null : _searchController.text,
            );
          }
        },
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildEmptyState(
                icon: Icons.search_off,
                message: 'Kurslar topilmadi',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadDefaultCourses();
        if (_selectedCategoryId != null) {
          _loadCoursesByCategory(
            _selectedCategoryId!,
            _searchController.text.isEmpty ? null : _searchController.text,
          );
        }
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _courseResults.length,
        itemBuilder: (context, index) {
          final course = _courseResults[index];
          return _buildCourseItem(course);
        },
      ),
    );
  }

  Widget _buildTeachersTab() {
    // Load teachers on first view
    if (!_teachersLoaded && !_isLoadingTeachers) {
      _searchTeachers(_searchController.text);
    }

    if (_isLoadingTeachers) {
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 5,
        itemBuilder: (context, index) => const TeacherCardShimmer(),
      );
    }

    // Show filtered teachers if category selected or search applied
    final displayTeachers =
        (_selectedCategoryId != null || _searchController.text.isNotEmpty)
        ? _teacherResults
        : _allTeachers;

    if (displayTeachers.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _teachersLoaded = false;
          });
          await _searchTeachers(_searchController.text);
        },
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildEmptyState(
                icon: Icons.search_off,
                message: 'Hech narsa topilmadi',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _teachersLoaded = false;
        });
        await _searchTeachers(_searchController.text);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: displayTeachers.length,
        itemBuilder: (context, index) {
          final teacher = displayTeachers[index];
          return _buildTeacherItem(teacher);
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80.sp,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Boshqa so\'rovlar bilan qayta urinib ko\'ring',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(Map<String, dynamic> course) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailPage(courseId: course['id']),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: course['thumbnail'] != null
                      ? CachedNetworkImage(
                          imageUrl:
                              course['thumbnail'].toString().startsWith('http')
                              ? course['thumbnail']
                              : '${AppConstants.baseUrl}${course['thumbnail']}',
                          width: 80.w,
                          height: 80.w,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 80.w,
                            height: 80.w,
                            color: AppColors.border,
                            child: Center(
                              child: Icon(
                                Icons.image,
                                color: AppColors.textHint,
                                size: 32.sp,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.8),
                                  AppColors.primary,
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.play_circle_outline,
                              color: Colors.white,
                              size: 32.sp,
                            ),
                          ),
                        )
                      : Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.8),
                                AppColors.primary,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 32.sp,
                          ),
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'] ?? '',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              course['teacher']?['name'] ?? 'O\'qituvchi',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: course['isFree']
                              ? Colors.green.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          course['isFree']
                              ? 'Bepul'
                              : '${FormatUtils.formatPrice(course['price'])} so\'m',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: course['isFree']
                                ? Colors.green
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherItem(Map<String, dynamic> teacher) {
    // Get teacher categories - handle both String and List
    List<String> categoryList = [];
    final categoriesData = teacher['categories'];

    if (categoriesData != null) {
      if (categoriesData is String) {
        // If it's a string, split by comma
        categoryList = categoriesData
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (categoriesData is List) {
        // If it's a list, process it
        categoryList = categoriesData
            .map((cat) => cat['nameUz'] ?? cat['name'] ?? '')
            .where((name) => name.isNotEmpty)
            .map((e) => e.toString())
            .toList();
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading:
            teacher['avatar'] != null && teacher['avatar'].toString().isNotEmpty
            ? CircleAvatar(
                radius: 30.r,
                backgroundImage: CachedNetworkImageProvider(
                  ImageUtils.getFullImageUrl(teacher['avatar']),
                ),
                backgroundColor: AppColors.border,
              )
            : CircleAvatar(
                radius: 30.r,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: SvgPicture.asset(
                  'assets/icons/user.svg',
                  width: 28.w,
                  height: 28.h,
                  colorFilter: ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
        title: Text(
          teacher['name'] ?? '',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${teacher['_count']?['courses'] ?? teacher['coursesCount'] ?? 0} ta kurs',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
            if (categoryList.isNotEmpty) ...[
              SizedBox(height: 6.h),
              SizedBox(
                height: 24.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryList.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(right: 6.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          categoryList[index],
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (teacher['id'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherDetailPage(teacherId: teacher['id']),
              ),
            );
          }
        },
      ),
    );
  }
}
