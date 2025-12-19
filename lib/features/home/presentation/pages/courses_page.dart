import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mening kurslarim')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80.sp, color: AppColors.textHint),
            SizedBox(height: 16.h),
            Text(
              'Sizda hali kurslar yo\'q',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Kurslarni sotib oling va o\'rganishni boshlang',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Kurslarni ko\'rish'),
            ),
          ],
        ),
      ),
    );
  }
}
