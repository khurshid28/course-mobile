import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../../../injection_container.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);

    try {
      final dataSource = getIt<PaymentRemoteDataSource>();
      final payments = await dataSource.getPaymentHistory();

      if (!mounted) return;

      setState(() {
        _payments = payments.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ToastUtils.showError(context, e);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Noma\'lum';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Bugun';
      } else if (difference.inDays == 1) {
        return 'Kecha';
      } else if (difference.inDays < 30) {
        return '${difference.inDays} kun oldin';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months oy oldin';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years yil oldin';
      }
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return AppColors.success;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return 'Muvaffaqiyatli';
      case 'PENDING':
        return 'Kutilmoqda';
      case 'FAILED':
        return 'Muvaffaqiyatsiz';
      case 'CANCELLED':
        return 'Bekor qilindi';
      default:
        return status;
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method.toUpperCase()) {
      case 'CLICK':
        return Icons.payment;
      case 'PAYME':
        return Icons.account_balance_wallet;
      case 'UZUM':
        return Icons.credit_card;
      case 'BALANCE':
        return Icons.add_card;
      default:
        return Icons.payment;
    }
  }

  String? _getMethodLogo(String method) {
    switch (method.toUpperCase()) {
      case 'CLICK':
        return 'https://click.uz/click/images/logo.svg';
      case 'PAYME':
        return 'https://cdn.payme.uz/logo/payme_01.svg';
      case 'UZUM':
        return 'https://uzum.uz/static/img/logo-icon.svg';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('To\'lovlar tarixi'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPayments,
        child: _isLoading
            ? ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: 5,
                itemBuilder: (context, index) => const PaymentCardShimmer(),
              )
            : _payments.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.payment_outlined,
                      size: 80.sp,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'To\'lovlar tarixi bo\'sh',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _payments.length,
                itemBuilder: (context, index) {
                  final payment = _payments[index];
                  final course = payment['course'] as Map<String, dynamic>?;
                  final statusColor = _getStatusColor(payment['status'] ?? '');

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Course/Teacher Image and Title Row
                          if (course != null && course['thumbnail'] != null)
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        course['thumbnail']
                                            .toString()
                                            .startsWith('http')
                                        ? course['thumbnail'].toString()
                                        : '${AppConstants.baseUrl}${course['thumbnail']}',
                                    width: 60.w,
                                    height: 60.h,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 60.w,
                                      height: 60.h,
                                      color: AppColors.secondary,
                                      child: Icon(
                                        Icons.image,
                                        color: AppColors.textHint,
                                        size: 24.sp,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      print('Image error: $url - $error');
                                      return Container(
                                        width: 60.w,
                                        height: 60.h,
                                        color: AppColors.secondary,
                                        child: Icon(
                                          Icons.school,
                                          color: AppColors.primary,
                                          size: 24.sp,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course['title'] ?? 'Noma\'lum kurs',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (course['teacher'] != null) ...[
                                        SizedBox(height: 4.h),
                                        Row(
                                          children: [
                                            if (course['teacher']['avatar'] !=
                                                null)
                                              ClipOval(
                                                child: CachedNetworkImage(
                                                  imageUrl:
                                                      course['teacher']['avatar']
                                                          .toString()
                                                          .startsWith('http')
                                                      ? course['teacher']['avatar']
                                                            .toString()
                                                      : '${AppConstants.baseUrl}${course['teacher']['avatar']}',
                                                  width: 16.w,
                                                  height: 16.h,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                        width: 16.w,
                                                        height: 16.h,
                                                        color:
                                                            AppColors.secondary,
                                                      ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Icon(
                                                            Icons.person,
                                                            size: 16.sp,
                                                            color: AppColors
                                                                .textHint,
                                                          ),
                                                ),
                                              ),
                                            SizedBox(width: 4.w),
                                            Expanded(
                                              child: Text(
                                                course['teacher']['name'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          if (payment['type'] == 'BALANCE_TOPUP')
                            Row(
                              children: [
                                Container(
                                  width: 60.w,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: AppColors.primary,
                                    size: 32.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    'Balans to\'ldirildi',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  _getStatusText(payment['status'] ?? ''),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/calendar.svg',
                                width: 14.w,
                                height: 14.h,
                                colorFilter: ColorFilter.mode(
                                  AppColors.textSecondary,
                                  BlendMode.srcIn,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                _formatDate(payment['paymentDate']),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              // Payment method logo or icon
                              _buildMethodBadge(payment['method'] ?? ''),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          // Promo Code info (if used)
                          if (payment['promoCode'] != null)
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: AppColors.success.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_offer,
                                        size: 16.sp,
                                        color: AppColors.success,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Promo kod: ${payment['promoCode']['code']}',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.success,
                                              ),
                                            ),
                                            if (payment['originalAmount'] !=
                                                null)
                                              Text(
                                                'Asl narx: ${FormatUtils.formatPrice(payment['originalAmount'])} so\'m',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color:
                                                      AppColors.textSecondary,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (payment['discount'] != null)
                                        Text(
                                          '-${FormatUtils.formatPrice(payment['discount'])} so\'m',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                              ],
                            ),
                          Divider(height: 1, color: AppColors.border),
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'To\'lov summasi',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${FormatUtils.formatPrice(payment['amount'])} so\'m',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (payment['transactionId'] != null) ...[
                            SizedBox(height: 8.h),
                            Text(
                              'ID: ${payment['transactionId']}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textHint,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMethodBadge(String method) {
    final logo = _getMethodLogo(method);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (logo != null)
            CachedNetworkImage(
              imageUrl: logo,
              width: 18.w,
              height: 18.h,
              fit: BoxFit.contain,
              placeholder: (context, url) => SizedBox(
                width: 18.w,
                height: 18.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              errorWidget: (context, url, error) => Icon(
                _getMethodIcon(method),
                size: 16.sp,
                color: AppColors.primary,
              ),
            )
          else
            Icon(_getMethodIcon(method), size: 16.sp, color: AppColors.primary),
          SizedBox(width: 6.w),
          Text(
            method,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
