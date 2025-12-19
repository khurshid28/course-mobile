import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Yangi kurs qo\'shildi',
        'message': 'Flutter Development kursi sizga mos keladi',
        'time': '2 soat oldin',
        'isRead': false,
        'icon': Icons.school,
      },
      {
        'title': 'Chegirma',
        'message': 'Barcha kurslarga 20% chegirma!',
        'time': '5 soat oldin',
        'isRead': false,
        'icon': Icons.discount,
      },
      {
        'title': 'Sertifikat tayyor',
        'message': 'Python Foundation kursidan sertifikatingiz tayyor',
        'time': '1 kun oldin',
        'isRead': true,
        'icon': Icons.verified,
      },
      {
        'title': 'Yangi video',
        'message': 'UI/UX Design kursiga yangi dars qo\'shildi',
        'time': '2 kun oldin',
        'isRead': true,
        'icon': Icons.play_circle,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Bildirishnomalar',
          style: TextStyle(color: Colors.white),
        ),
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
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Mark all as read
            },
            child: Text(
              'Hammasini o\'qilgan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80.sp,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Bildirishnomalar yo\'q',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Sizda hozircha yangi xabarlar yo\'q',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['isRead'] as bool;

                return Container(
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.white
                        : AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isRead
                          ? AppColors.border
                          : AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.w),
                    leading: Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        notification['icon'] as IconData,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] as String,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4.h),
                        Text(
                          notification['message'] as String,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          notification['time'] as String,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // TODO: Handle notification tap
                    },
                  ),
                );
              },
            ),
    );
  }
}
