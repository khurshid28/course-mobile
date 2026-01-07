import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class CourseRatingWidget extends StatefulWidget {
  final int? userRating; // User's current rating (null if not rated yet)
  final double averageRating; // Course's average rating
  final int totalRatings; // Total number of ratings
  final Function(int rating) onRate; // Callback when user rates
  final VoidCallback? onDelete; // Callback when user deletes rating

  const CourseRatingWidget({
    super.key,
    this.userRating,
    required this.averageRating,
    required this.totalRatings,
    required this.onRate,
    this.onDelete,
  });

  @override
  State<CourseRatingWidget> createState() => _CourseRatingWidgetState();
}

class _CourseRatingWidgetState extends State<CourseRatingWidget> {
  int? _hoveredStar;
  bool _isRating = false;

  @override
  void didUpdateWidget(CourseRatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset editing mode if user rating changed
    if (oldWidget.userRating != widget.userRating) {
      setState(() {
        _isRating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                widget.userRating != null
                    ? 'Sizning bahoyingiz'
                    : 'Kursni baholang',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Average Rating Display (only show if there are ratings or user has rated)
          if (widget.totalRatings > 0 || widget.userRating != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < widget.averageRating.floor()
                              ? Icons.star_rounded
                              : (index < widget.averageRating
                                    ? Icons.star_half_rounded
                                    : Icons.star_outline_rounded),
                          color: Colors.amber,
                          size: 20.sp,
                        );
                      }),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${widget.totalRatings} ta baho',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24.h),
          ],

          // User Rating Section
          if (widget.userRating != null) ...[
            // Show user's current rating
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Icon(
                          index < widget.userRating!
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppColors.primary,
                          size: 32.sp,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Siz ${widget.userRating} yulduz bilan baholadingiz',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _isRating
                            ? null
                            : () {
                                setState(() {
                                  _isRating = true;
                                });
                              },
                        icon: SvgPicture.asset(
                          'assets/icons/edit.svg',
                          width: 18.w,
                          height: 18.h,
                          colorFilter: ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                        label: Text(
                          'O\'zgartirish',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                      if (widget.onDelete != null) ...[
                        SizedBox(width: 8.w),
                        TextButton.icon(
                          onPressed: () async {
                            // Show confirmation dialog
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Bahoni o\'chirish',
                                  style: TextStyle(fontSize: 18.sp),
                                ),
                                content: Text(
                                  'Bahoni o\'chirishni xohlaysizmi?',
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Bekor qilish'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('O\'chirish'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              widget.onDelete!();
                            }
                          },
                          icon: Icon(Icons.delete_outline, size: 18.sp),
                          label: Text(
                            'O\'chirish',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Rating Input (shown if not rated or editing)
          if (widget.userRating == null || _isRating) ...[
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return GestureDetector(
                        onTap: () {
                          // Update local state immediately
                          if (mounted) {
                            setState(() {
                              _isRating = false;
                              _hoveredStar = null;
                            });
                          }
                          // Call parent callback (no await to prevent state issues)
                          widget.onRate(starValue);
                        },
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _hoveredStar = starValue;
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _hoveredStar = null;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Icon(
                              (_hoveredStar != null &&
                                      starValue <= _hoveredStar!)
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color:
                                  (_hoveredStar != null &&
                                      starValue <= _hoveredStar!)
                                  ? AppColors.primary
                                  : AppColors.border,
                              size: 40.sp,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _hoveredStar != null
                        ? '$_hoveredStar yulduz'
                        : 'Baholash uchun yulduzni bosing',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: _hoveredStar != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isRating) ...[
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isRating = false;
                          _hoveredStar = null;
                        });
                      },
                      child: Text(
                        'Bekor qilish',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
