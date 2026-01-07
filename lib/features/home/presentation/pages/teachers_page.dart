import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../data/datasources/teacher_remote_datasource.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../../../injection_container.dart';
import '../../../../core/utils/toast_utils.dart';
import 'teacher_detail_page.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  List<Map<String, dynamic>> _allTeachers = [];
  List<Map<String, dynamic>> _filteredTeachers = [];
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadTeachers(), _loadCategories()]);
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categoryDataSource = getIt<CategoryRemoteDataSource>();
      final categories = await categoryDataSource.getAllCategories();
      if (!mounted) return;

      setState(() {
        _categories = categories.cast<Map<String, dynamic>>();
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);

    try {
      final teacherDataSource = getIt<TeacherRemoteDataSource>();
      final teachers = await teacherDataSource.getAllTeachers();

      if (!mounted) return;

      setState(() {
        _allTeachers = teachers;
        _filteredTeachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ToastUtils.showError(context, e);
    }
  }

  void _filterTeachers() {
    List<Map<String, dynamic>> filtered = _allTeachers;

    // Apply category filter
    if (_selectedCategoryId != null) {
      filtered = filtered.where((teacher) {
        final courses = teacher['courses'];
        if (courses == null || courses is! List) return false;

        return courses.any((course) {
          return course['categoryId'] == _selectedCategoryId;
        });
      }).toList();
    }

    // Apply search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((teacher) {
        final user = teacher['user'];
        final userName = user != null
            ? '${user['firstName'] ?? ''} ${user['surname'] ?? ''}'
                  .toLowerCase()
            : '';
        final teacherName = (teacher['name'] ?? '').toString().toLowerCase();
        final bio = (teacher['bio'] ?? '').toString().toLowerCase();

        return userName.contains(query) ||
            teacherName.contains(query) ||
            bio.contains(query);
      }).toList();
    }

    setState(() {
      _filteredTeachers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
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
        title: Text(
          'O\'qituvchilar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              cursorColor: AppColors.primary,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                fillColor: AppColors.background,
                filled: true,
                hintText: 'O\'qituvchi qidirish...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15.sp,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: SvgPicture.asset(
                    'assets/icons/search-alt.svg',
                    width: 20.w,
                    height: 20.h,
                    colorFilter: ColorFilter.mode(
                      AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _filterTeachers();
                        },
                      )
                    : null,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                isDense: true,
              ),
              onChanged: (_) => _filterTeachers(),
            ),
          ),

          // Categories Horizontal List
          if (!_isLoadingCategories && _categories.isNotEmpty)
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
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GestureDetector(
                              onTap: () {
                                setState(() => _selectedCategoryId = null);
                                _filterTeachers();
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
                    child: GestureDetector(
                      onTap: () {
                        setState(
                          () => _selectedCategoryId = isSelected
                              ? null
                              : category['id'],
                        );
                        _filterTeachers();
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
                              category['nameUz'] ?? category['name'] ?? '',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 13.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
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

          // Teachers list
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: 5,
                    itemBuilder: (context, index) => const TeacherCardShimmer(),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _filteredTeachers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  size: 64.sp,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'O\'qituvchi topilmadi',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16.w),
                            itemCount: _filteredTeachers.length,
                            itemBuilder: (context, index) {
                              final teacher = _filteredTeachers[index];
                              return _buildTeacherCard(teacher);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    final courseCount = teacher['_count']?['courses'] ?? 0;
    final user = teacher['user'];
    final hasUser = user != null;

    // Get teacher name
    String name = '';
    if (hasUser) {
      name = '${user['firstName'] ?? ''} ${user['surname'] ?? ''}'.trim();
    }
    if (name.isEmpty) {
      name = teacher['name'] ?? 'O\'qituvchi';
    }

    // Get teacher avatar
    String? avatarUrl;
    if (hasUser && user['avatar'] != null) {
      avatarUrl = '${AppConstants.baseUrl}${user['avatar']}';
    } else if (teacher['avatar'] != null) {
      avatarUrl = '${AppConstants.baseUrl}${teacher['avatar']}';
    }

    // Get teacher categories from courses
    List<String> categoryNames = [];
    final courses = teacher['courses'];
    if (courses != null && courses is List) {
      // Extract unique category names from courses
      final categories = <String>{};
      for (var course in courses) {
        final categoryName = _getCategoryName(course['categoryId']);
        if (categoryName.isNotEmpty) {
          categories.add(categoryName);
        }
      }
      categoryNames = categories.toList();
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
        leading: avatarUrl != null && avatarUrl.isNotEmpty
            ? CircleAvatar(
                radius: 30.r,
                backgroundImage: NetworkImage(avatarUrl),
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
          name,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$courseCount ta kurs',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
            if (categoryNames.isNotEmpty) ...[
              SizedBox(height: 6.h),
              SizedBox(
                height: 24.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryNames.length,
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
                          categoryNames[index],
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TeacherDetailPage(teacherId: teacher['id'] as int),
            ),
          );
        },
      ),
    );
  }

  String _getCategoryName(int? categoryId) {
    if (categoryId == null) return '';
    try {
      final category = _categories.firstWhere(
        (cat) => cat['id'] == categoryId,
        orElse: () => <String, dynamic>{},
      );
      return category['nameUz'] ?? category['name'] ?? '';
    } catch (e) {
      return '';
    }
  }
}
