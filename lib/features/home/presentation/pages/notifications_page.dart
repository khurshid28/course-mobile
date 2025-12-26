import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../../../injection_container.dart';
import '../../../../core/utils/toast_utils.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final dataSource = getIt<NotificationRemoteDataSource>();
      final notifications = await dataSource.getUserNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = notifications
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ToastUtils.showError(context, e);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final dataSource = getIt<NotificationRemoteDataSource>();
      await dataSource.markAsRead(id);

      // Update local state
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context, e);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final dataSource = getIt<NotificationRemoteDataSource>();
      await dataSource.markAllAsRead();

      // Update local state
      setState(() {
        for (var notification in _notifications) {
          notification['isRead'] = true;
        }
      });

      if (!mounted) return;
      ToastUtils.showSuccess(context, 'Barcha bildirishnomalar o\'qilgan');
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context, e);
    }
  }

  IconData _getIconFromType(String? type) {
    switch (type) {
      case 'course':
        return Icons.school;
      case 'discount':
        return Icons.discount;
      case 'certificate':
        return Icons.verified;
      case 'video':
        return Icons.play_circle;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _notifications.any((n) => n['isRead'] == false)
                ? _markAllAsRead
                : null,
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
      body: _isLoading
          ? ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: 5,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) => const NotificationCardShimmer(),
            )
          : _notifications.isEmpty
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
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                final isRead = notification['isRead'] == true;
                final hasImage =
                    notification['image'] != null &&
                    notification['image'].toString().isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    if (!isRead) {
                      _markAsRead(notification['id']);
                    }
                  },
                  child: Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image (if available)
                        if (hasImage)
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12.r),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: notification['image'],
                              height: 140.h,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 140.h,
                                color: AppColors.shimmerBase,
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 140.h,
                                color: AppColors.secondary,
                                child: Icon(
                                  Icons.image,
                                  size: 48.sp,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ),

                        // Content
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                width: 48.w,
                                height: 48.w,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  _getIconFromType(notification['type']),
                                  color: AppColors.primary,
                                  size: 24.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),

                              // Text Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notification['title'] ?? '',
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
                                            margin: EdgeInsets.only(left: 8.w),
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      notification['message'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      _formatDate(notification['createdAt']),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Hozir';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} daqiqa oldin';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} soat oldin';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} kun oldin';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks hafta oldin';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months oy oldin';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years yil oldin';
      }
    } catch (e) {
      return dateString;
    }
  }
}
