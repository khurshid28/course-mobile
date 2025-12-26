import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../../../injection_container.dart';
import 'course_detail_page.dart';

class UsedPromoCodesPage extends StatefulWidget {
  const UsedPromoCodesPage({super.key});

  @override
  State<UsedPromoCodesPage> createState() => _UsedPromoCodesPageState();
}

class _UsedPromoCodesPageState extends State<UsedPromoCodesPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _usedPromoCodes = [];

  @override
  void initState() {
    super.initState();
    _loadUsedPromoCodes();
  }

  Future<void> _loadUsedPromoCodes() async {
    setState(() => _isLoading = true);

    try {
      final dataSource = getIt<PaymentRemoteDataSource>();
      final promoCodes = await dataSource.getUserUsedPromoCodes();

      if (!mounted) return;

      setState(() {
        _usedPromoCodes = promoCodes
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Noma\'lum';

    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foydalanilgan promo kodlar'),
        leading: Padding(
          padding: EdgeInsets.all(8.w),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
              iconSize: 18.sp,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsedPromoCodes,
        child: _isLoading
            ? ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: 5,
                itemBuilder: (context, index) => const CourseCardShimmer(),
              )
            : _usedPromoCodes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 80.sp,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Foydalanilgan promo kodlar yo\'q',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Sizda hali promo kod ishlatilmagan',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _usedPromoCodes.length,
                itemBuilder: (context, index) {
                  final usage = _usedPromoCodes[index];
                  final course = usage['course'];
                  final promoCode = usage['promoCode'];

                  return GestureDetector(
                    onTap: () {
                      if (course != null && course['id'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDetailPage(
                              courseId: course['id'],
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16.h),
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
                            // Promo code badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_offer,
                                    size: 16.sp,
                                    color: AppColors.success,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    promoCode?['code'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 12.h),

                            // Course title with navigate icon
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    course?['title'] ?? 'Noma\'lum kurs',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12.h),

                            // Discount info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chegirma miqdori',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      promoCode?['discountPercent'] != null
                                          ? '${promoCode['discountPercent']}%'
                                          : '${FormatUtils.formatPrice(promoCode?['discountAmount'] ?? 0)} so\'m',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Tejaldi',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '${FormatUtils.formatPrice(usage['discount'] ?? 0)} so\'m',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            SizedBox(height: 12.h),

                            // Date used
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14.sp,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'Ishlatilgan: ${_formatDate(usage['usedAt'])}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                      
                    
                  
                },
              ),
      ),
    );
  }
}
