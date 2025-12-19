import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../data/datasources/teacher_remote_datasource.dart';
import '../../../../injection_container.dart';
import '../../../../core/utils/toast_utils.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);

    try {
      final teacherDataSource = getIt<TeacherRemoteDataSource>();
      final teachers = await teacherDataSource.getAllTeachers();

      if (!mounted) return;

      setState(() {
        _teachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ToastUtils.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('O\'qituvchilar'),
        leading: Padding(
          padding: EdgeInsets.all(8.w),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
              iconSize: 18.sp,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: 5,
              itemBuilder: (context, index) => const TeacherCardShimmer(),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _teachers.length,
              itemBuilder: (context, index) {
                final teacher = _teachers[index];
                return _buildTeacherCard(teacher);
              },
            ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 35.r,
                    backgroundColor: AppColors.secondary,
                    backgroundImage: teacher['avatar'] != null
                        ? CachedNetworkImageProvider(teacher['avatar'])
                        : null,
                    child: teacher['avatar'] == null
                        ? Text(
                            teacher['name']?.substring(0, 1) ?? 'T',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher['name'] ?? '',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        teacher['bio'] ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  Icons.school,
                  '${teacher['_count']?['courses'] ?? 0}',
                  'Kurslar',
                ),
                Container(width: 1, height: 30.h, color: AppColors.border),
                _buildStat(Icons.people, '0', 'O\'quvchilar'),
                Container(width: 1, height: 30.h, color: AppColors.border),
                _buildStat(Icons.star, '5.0', 'Reyting'),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to teacher detail
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text('Kurslarni ko\'rish'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20.sp, color: AppColors.primary),
            SizedBox(width: 4.w),
            Text(
              value,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
