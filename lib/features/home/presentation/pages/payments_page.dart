import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final payments = [
      {
        'courseName': 'Flutter Development',
        'amount': 250000,
        'method': 'Click',
        'date': '15.12.2025',
        'status': 'SUCCESS',
      },
      {
        'courseName': 'React Native',
        'amount': 300000,
        'method': 'Payme',
        'date': '10.12.2025',
        'status': 'SUCCESS',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('To\'lovlar tarixi'),
      ),
      body: payments.isEmpty
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
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              payment['courseName'] as String,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              payment['status'] as String,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                payment['date'] as String,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${payment['amount']} so\'m',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              payment['method'] as String,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
