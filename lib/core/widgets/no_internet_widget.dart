import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 100.sp,
              color: AppColors.textHint,
            ),
            SizedBox(height: 24.h),
            Text(
              'Internet yo\'q',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Internet aloqasini tekshiring va qayta urinib ko\'ring',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }
}
