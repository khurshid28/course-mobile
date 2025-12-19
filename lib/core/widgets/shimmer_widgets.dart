import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class CourseCardShimmer extends StatelessWidget {
  const CourseCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail shimmer
          Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Container(
              height: 180.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title shimmer
                Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    width: double.infinity,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),

                // Subtitle shimmer
                Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    width: 200.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Meta info shimmer
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: AppColors.shimmerBase,
                      highlightColor: AppColors.shimmerHighlight,
                      child: Container(
                        width: 80.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Shimmer.fromColors(
                      baseColor: AppColors.shimmerBase,
                      highlightColor: AppColors.shimmerHighlight,
                      child: Container(
                        width: 60.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Price shimmer
                Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    width: 100.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItemShimmer extends StatelessWidget {
  const CategoryItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80.w,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: 50.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeaderShimmer extends StatelessWidget {
  const ProfileHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 24.h),
        // Avatar shimmer
        Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Container(
            width: 100.w,
            height: 100.h,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // Name shimmer
        Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Container(
            width: 150.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
        SizedBox(height: 8.h),

        // Phone shimmer
        Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Container(
            width: 120.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
      ],
    );
  }
}

class ListItemShimmer extends StatelessWidget {
  const ListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Icon shimmer
          Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 16.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    width: double.infinity,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    width: 150.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header shimmer
          Container(
            height: 380.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.shimmerBase,
                  AppColors.shimmerBase.withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.5),
                child: Container(
                  width: 120.w,
                  height: 120.h,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          // Stats shimmer
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  3,
                  (index) => Shimmer.fromColors(
                    baseColor: AppColors.shimmerBase,
                    highlightColor: AppColors.shimmerHighlight,
                    child: Column(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 50.w,
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          // Menu items shimmer
          ...List.generate(6, (index) => const ListItemShimmer()),
        ],
      ),
    );
  }
}

class CourseDetailShimmer extends StatelessWidget {
  const CourseDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail shimmer
          Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Container(
              width: double.infinity,
              height: 250.h,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    width: double.infinity,
                    height: 28.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Meta info
                Row(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: EdgeInsets.only(right: 16.w),
                      child: Shimmer.fromColors(
                        baseColor: AppColors.shimmerBase,
                        highlightColor: AppColors.shimmerHighlight,
                        child: Container(
                          width: 80.w,
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                // Description
                ...List.generate(
                  4,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Shimmer.fromColors(
                      baseColor: AppColors.shimmerBase,
                      highlightColor: AppColors.shimmerHighlight,
                      child: Container(
                        width: index == 3 ? 200.w : double.infinity,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherCardShimmer extends StatelessWidget {
  const TeacherCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Container(
              width: 60.w,
              height: 60.h,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    width: 150.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    width: 100.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CertificateCardShimmer extends StatelessWidget {
  const CertificateCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
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
          Row(
            children: [
              // Icon
              Shimmer.fromColors(
                baseColor: AppColors.shimmerBase,
                highlightColor: AppColors.shimmerHighlight,
                child: Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course name
                    Shimmer.fromColors(
                      baseColor: AppColors.shimmerBase,
                      highlightColor: AppColors.shimmerHighlight,
                      child: Container(
                        width: double.infinity,
                        height: 18.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Date
                    Shimmer.fromColors(
                      baseColor: AppColors.shimmerBase,
                      highlightColor: AppColors.shimmerHighlight,
                      child: Container(
                        width: 120.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Divider
          Container(height: 1, color: AppColors.border),
          SizedBox(height: 16.h),
          // Stats
          Row(
            children: List.generate(
              2,
              (index) => Expanded(
                child: Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Column(
                    children: [
                      Container(
                        width: 80.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        width: 60.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: child,
    );
  }
}
