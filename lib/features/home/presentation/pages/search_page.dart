import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../../../injection_container.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  bool _isSearching = false;
  bool _isLoadingCategories = false;
  List<Map<String, dynamic>> _courseResults = [];
  List<Map<String, dynamic>> _teacherResults = [];
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categoryDataSource = getIt<CategoryRemoteDataSource>();
      final categoriesData = await categoryDataSource.getAllCategories();

      if (!mounted) return;

      setState(() {
        _categories = categoriesData.cast<Map<String, dynamic>>();
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _courseResults = [];
        _teacherResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // TODO: API call for search
    // Temporary mock data
    setState(() {
      _courseResults = [];
      _teacherResults = [];
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: EdgeInsets.all(8.w),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              iconSize: 18.sp,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Container(
          height: 45.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Kurslar va o\'qituvchilarni qidirish...',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14.sp),
              border: InputBorder.none,
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.w),
                child: SvgPicture.asset(
                  'assets/icons/search-alt.svg',
                  width: 20.w,
                  height: 20.h,
                  colorFilter: ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                          size: 22.sp,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                          setState(() {
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 10.h,
              ),
            ),
            style: TextStyle(fontSize: 15.sp),
            onChanged: _performSearch,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Kurslar'),
            Tab(text: 'O\'qituvchilar'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Categories Horizontal List
          if (_categories.isNotEmpty)
            Container(
              height: 50.h,
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
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                                  _performSearch(_searchController.text);
                                });
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
                        setState(() {
                          _selectedCategoryId = isSelected
                              ? null
                              : category['id'];
                          _performSearch(_searchController.text);
                        });
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
    if (_isSearching) {
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 3,
        itemBuilder: (context, index) => const CourseCardShimmer(),
      );
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search,
        message: 'Kurs nomini kiriting',
      );
    }

    if (_courseResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        message: 'Hech narsa topilmadi',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _courseResults.length,
      itemBuilder: (context, index) {
        final course = _courseResults[index];
        return _buildCourseItem(course);
      },
    );
  }

  Widget _buildTeachersTab() {
    if (_isSearching) {
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 3,
        itemBuilder: (context, index) => const TeacherCardShimmer(),
      );
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search,
        message: 'O\'qituvchi nomini kiriting',
      );
    }

    if (_teacherResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        message: 'Hech narsa topilmadi',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _teacherResults.length,
      itemBuilder: (context, index) {
        final teacher = _teacherResults[index];
        return _buildTeacherItem(teacher);
      },
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
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64.sp,
              color: AppColors.primary.withOpacity(0.6),
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
            // TODO: Navigate to course detail
          },
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 32.sp,
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
                              course['teacher'] ?? '',
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
                              : '${course['price']} so\'m',
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
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: CircleAvatar(
          radius: 30.r,
          backgroundColor: AppColors.primary,
          child: Text(
            teacher['name']?.substring(0, 1) ?? 'T',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          teacher['name'] ?? '',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${teacher['coursesCount'] ?? 0} ta kurs',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to teacher detail
        },
      ),
    );
  }
}
