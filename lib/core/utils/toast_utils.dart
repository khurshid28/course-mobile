import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:course_mobile/core/theme/app_colors.dart';

class ToastUtils {
  static void showError(BuildContext context, dynamic error) {
    String message = _parseError(error);
    _showToast(context, message, AppColors.error);
  }

  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, AppColors.success);
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(context, message, AppColors.primary);
  }

  static String _parseError(dynamic error) {
    String errorMessage = error.toString();

    // Remove "Exception: " prefix
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.substring(11);
    }

    // Limit length to 100 characters
    if (errorMessage.length > 100) {
      errorMessage = '${errorMessage.substring(0, 97)}...';
    }

    return errorMessage;
  }

  static void _showToast(BuildContext context, String message, Color color) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(message: message, color: color),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color color;

  const _ToastWidget({required this.message, required this.color});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50.h,
      left: 16.w,
      right: 16.w,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getIcon(), color: Colors.white, size: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    if (widget.color == AppColors.error) {
      return Icons.error_outline;
    } else if (widget.color == AppColors.success) {
      return Icons.check_circle_outline;
    } else {
      return Icons.info_outline;
    }
  }
}
