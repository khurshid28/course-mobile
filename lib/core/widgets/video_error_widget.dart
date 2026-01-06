import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class VideoErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final bool isLocked;

  const VideoErrorWidget({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
              // Icon based on error type
              _buildErrorIcon(),

              SizedBox(height: 24.h),

              // Title
              Text(
                _getErrorTitle(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12.h),

              // Error message
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  _getErrorDescription(),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: 32.h),

              // Action buttons
              if (!isLocked) ...[
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 14.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'Qayta urinish',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 14.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Orqaga qaytish',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 14.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: const Icon(Icons.lock_open, color: Colors.white),
                  label: Text(
                    'Kursni sotib olish',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),)
    );
  }

  Widget _buildErrorIcon() {
    if (isLocked) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Icon(Icons.lock_outline, size: 56.sp, color: Colors.orange),
      );
    } else if (errorMessage.toLowerCase().contains('network') ||
        errorMessage.toLowerCase().contains('internet') ||
        errorMessage.toLowerCase().contains('connection')) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Icon(Icons.wifi_off_rounded, size: 56.sp, color: Colors.blue),
      );
    } else if (errorMessage.toLowerCase().contains('timeout')) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Icon(Icons.timer_off_outlined, size: 56.sp, color: Colors.amber),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Icon(Icons.error_outline, size: 56.sp, color: Colors.red),
      );
    }
  }

  String _getErrorTitle() {
    if (isLocked) {
      return 'Video qulflangan';
    } else if (errorMessage.toLowerCase().contains('network') ||
        errorMessage.toLowerCase().contains('internet') ||
        errorMessage.toLowerCase().contains('connection')) {
      return 'Internet muammosi';
    } else if (errorMessage.toLowerCase().contains('timeout')) {
      return 'Vaqt tugadi';
    } else if (errorMessage.toLowerCase().contains('not found') ||
        errorMessage.toLowerCase().contains('topilmadi')) {
      return 'Video topilmadi';
    } else {
      return 'Video yuklashda xatolik';
    }
  }

  String _getErrorDescription() {
    if (isLocked) {
      return errorMessage;
    } else if (errorMessage.toLowerCase().contains('network') ||
        errorMessage.toLowerCase().contains('internet') ||
        errorMessage.toLowerCase().contains('connection')) {
      return 'Internet aloqangizni tekshirib, qayta urinib ko\'ring';
    } else if (errorMessage.toLowerCase().contains('timeout')) {
      return 'Serverga ulanish juda uzoq vaqt oldi. Qayta urinib ko\'ring';
    } else if (errorMessage.toLowerCase().contains('not found') ||
        errorMessage.toLowerCase().contains('topilmadi')) {
      return 'Kechirasiz, bu video mavjud emas';
    } else {
      return errorMessage;
    }
  }
}
