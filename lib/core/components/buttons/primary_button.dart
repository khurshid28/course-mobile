import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final buttonColor = isDisabled 
        ? const Color(0xFFE0E0E0) 
        : (backgroundColor ?? const Color(0xFF3366FF));
    final buttonTextColor = isDisabled 
        ? const Color(0xFF9E9E9E) 
        : (textColor ?? Colors.white);
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 52.h,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.r),
          boxShadow: isDisabled ? [] : [
            BoxShadow(
              color: buttonColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: buttonTextColor,
            disabledBackgroundColor: const Color(0xFFE0E0E0),
            disabledForegroundColor: const Color(0xFF9E9E9E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.r),
            ),
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 14.h,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      buttonTextColor,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20.sp),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: buttonTextColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
