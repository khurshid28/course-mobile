import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../../../injection_container.dart';
import 'main_page.dart';
import 'balance_topup_page.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> course;

  const CheckoutPage({Key? key, required this.course}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _promoController = TextEditingController();
  String? _selectedMethod;
  String _selectedDuration = 'ONE_YEAR'; // Default 1 yillik
  bool _isValidatingPromo = false;
  bool _isPurchasing = false;
  Map<String, dynamic>? _promoCodeData;

  double get _basePrice {
    final price = widget.course['price'];
    if (price == null) return 0;
    if (price is num) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0;
    return 0;
  }

  // Subscription narxlarini hisoblash
  Map<String, dynamic> _calculateSubscriptionPrice(String duration) {
    switch (duration) {
      case 'ONE_MONTH':
        return {
          'price': _basePrice,
          'discount': 0.0,
          'months': 1,
          'label': '1 oylik',
          'discountPercent': 0,
        };
      case 'SIX_MONTHS':
        final sixMonthTotal = _basePrice * 6;
        final discount = sixMonthTotal * 0.15; // 15% chegirma
        return {
          'price': sixMonthTotal - discount,
          'discount': discount,
          'months': 6,
          'label': '6 oylik',
          'discountPercent': 15,
        };
      case 'ONE_YEAR':
        final yearTotal = _basePrice * 12;
        final discount = yearTotal * 0.25; // 25% chegirma
        return {
          'price': yearTotal - discount,
          'discount': discount,
          'months': 12,
          'label': '1 yillik',
          'discountPercent': 25,
        };
      default:
        return {
          'price': _basePrice,
          'discount': 0.0,
          'months': 1,
          'label': '1 oylik',
          'discountPercent': 0,
        };
    }
  }

  double get _originalPrice {
    final subscriptionInfo = _calculateSubscriptionPrice(_selectedDuration);
    return subscriptionInfo['price'] as double;
  }

  double get _subscriptionDiscount {
    final subscriptionInfo = _calculateSubscriptionPrice(_selectedDuration);
    return subscriptionInfo['discount'] as double;
  }

  double get _promoDiscountAmount {
    final discount = _promoCodeData?['discountAmount'];
    if (discount == null) return 0;
    if (discount is num) return discount.toDouble();
    if (discount is String) return double.tryParse(discount) ?? 0;
    return 0;
  }

  double get _finalPrice {
    final finalPrice = _promoCodeData?['finalPrice'];
    if (finalPrice != null) {
      if (finalPrice is num) return finalPrice.toDouble();
      if (finalPrice is String)
        return double.tryParse(finalPrice) ?? _originalPrice;
    }
    return _originalPrice;
  }

  final List<Map<String, String>> _paymentMethods = [
    {'id': 'BALANCE', 'name': 'Balans', 'icon': 'assets/icons/wallet.svg'},
    {'id': 'CLICK', 'name': 'Click', 'logo': 'assets/logos/click_logo.png'},
    {'id': 'PAYME', 'name': 'Payme', 'logo': 'assets/logos/payme_logo.png'},
    {'id': 'UZUM', 'name': 'Uzum', 'logo': 'assets/logos/uzum_logo.png'},
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('');
    debugPrint('🟢 ========== CHECKOUT PAGE INITIALIZED ==========');
    debugPrint('📦 Course: ${widget.course['title']}');
    debugPrint('💰 Base Price: $_basePrice');
    debugPrint('🏦 Payment Methods Available: $_paymentMethods');
    debugPrint('🎯 Default Selected Method: $_selectedMethod');
    debugPrint('📅 Default Duration: $_selectedDuration');
    debugPrint('🟢 ================================================');
    debugPrint('');
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _validatePromoCode() async {
    if (_promoController.text.trim().isEmpty) {
      ToastUtils.showError(context, 'Promo code kiriting');
      return;
    }

    setState(() => _isValidatingPromo = true);

    try {
      final paymentDataSource = getIt<PaymentRemoteDataSource>();
      final result = await paymentDataSource.validatePromoCode(
        _promoController.text.trim(),
        widget.course['id'],
      );

      if (!mounted) return;

      setState(() {
        _promoCodeData = result;
        _isValidatingPromo = false;
      });

      ToastUtils.showSuccess(
        context,
        result['message'] ?? 'Promo code qo\'llanildi',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidatingPromo = false;
        _promoCodeData = null;
      });
      ToastUtils.showError(context, e);
    }
  }

  Future<void> _purchaseCourse() async {
    if (_selectedMethod == null) {
      ToastUtils.showError(context, 'To\'lov usulini tanlang');
      return;
    }

    debugPrint('💳 Starting purchase process...');
    debugPrint('📦 Course ID: ${widget.course['id']}');
    debugPrint('💰 Final Price: $_finalPrice');
    debugPrint('🏦 Payment Method: $_selectedMethod');
    debugPrint('📅 Subscription Duration: $_selectedDuration');
    debugPrint(
      '🎟️ Promo Code: ${_promoCodeData != null ? _promoController.text.trim() : "null"}',
    );

    setState(() => _isPurchasing = true);

    try {
      final paymentDataSource = getIt<PaymentRemoteDataSource>();
      debugPrint('🚀 Sending payment request to backend...');
      final response = await paymentDataSource.createPayment(
        courseId: widget.course['id'],
        amount: _finalPrice,
        method: _selectedMethod!,
        subscriptionDuration: _selectedDuration,
        promoCode: _promoCodeData != null ? _promoController.text.trim() : null,
      );

      debugPrint('✅ Payment response received: $response');

      if (!mounted) return;

      ToastUtils.showSuccess(context, 'Kurs muvaffaqiyatli sotib olindi!');

      // Try to refresh main page active courses count
      final mainPageState = context.findAncestorStateOfType<MainPageState>();
      mainPageState?.refreshActiveCourses();

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('❌ Payment error: $e');
      debugPrint('📊 Error type: ${e.runtimeType}');

      if (!mounted) return;
      setState(() => _isPurchasing = false);

      // Handle specific error messages
      final errorMessage = e.toString();
      debugPrint('📝 Error message: $errorMessage');

      if (errorMessage.contains('Insufficient balance') ||
          errorMessage.contains('yetarli emas')) {
        // Save context and get current balance
        final scaffoldContext = context;
        double currentBalance = 0;

        try {
          final paymentDataSource = getIt<PaymentRemoteDataSource>();
          currentBalance = await paymentDataSource.getBalance();
        } catch (balanceError) {
          print('Error getting balance: $balanceError');
        }

        if (!mounted) return;

        // Show beautiful dialog with option to topup balance
        showDialog(
          context: scaffoldContext,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            elevation: 8,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                      size: 48.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Title
                  Text(
                    'Mablag\' yetarli emas',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Message
                  Text(
                    'Kursni sotib olish uchun balansingizda yetarli mablag\' yo\'q.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Balansni to\'ldirishni xohlaysizmi?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            side: BorderSide(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Bekor qilish',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.8),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              // Close dialog first
                              Navigator.of(dialogContext).pop();

                              // Small delay to ensure dialog is closed
                              await Future.delayed(
                                const Duration(milliseconds: 150),
                              );

                              // Check if widget is still mounted after delay
                              if (!mounted) return;

                              try {
                                // Navigate to balance topup page using scaffold context
                                final result =
                                    await Navigator.of(scaffoldContext).push(
                                      MaterialPageRoute(
                                        builder: (_) => BalanceTopupPage(
                                          currentBalance: currentBalance,
                                        ),
                                      ),
                                    );

                                // If topup was successful, show success message
                                if (result == true && mounted) {
                                  ToastUtils.showSuccess(
                                    scaffoldContext,
                                    'Balans to\'ldirildi! Endi kursni sotib olishingiz mumkin.',
                                  );
                                }
                              } catch (e) {
                                print('Balance topup navigation error: $e');
                                if (!mounted) return;
                                ToastUtils.showError(
                                  scaffoldContext,
                                  'Xatolik yuz berdi. Qaytadan urinib ko\'ring.',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_card,
                                  color: Colors.white,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'To\'ldirish',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        ToastUtils.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 Building checkout page...');
    debugPrint('📋 Payment methods list: $_paymentMethods');
    debugPrint('🎯 Currently selected method: $_selectedMethod');

    return Scaffold(
      appBar: AppBar(
        title: const Text('To\'lovni amalga oshirish'),
        leading: Container(
          width: 36.w,
          height: 36.h,
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: const Color(0xFF666666),
              size: 16.sp,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Info Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: widget.course['thumbnail'] != null
                        ? CachedNetworkImage(
                            imageUrl:
                                widget.course['thumbnail']
                                    .toString()
                                    .startsWith('http')
                                ? widget.course['thumbnail'].toString()
                                : '${AppConstants.baseUrl}${widget.course['thumbnail']}',
                            width: 80.w,
                            height: 80.w,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 80.w,
                              height: 80.w,
                              color: AppColors.secondary,
                              child: Icon(
                                Icons.image,
                                color: AppColors.textHint,
                                size: 32.sp,
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              print('Checkout image error: $url - $error');
                              return Container(
                                width: 80.w,
                                height: 80.w,
                                color: AppColors.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.school,
                                  color: AppColors.primary,
                                  size: 32.sp,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 80.w,
                            height: 80.w,
                            color: AppColors.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.play_circle_outline,
                              color: AppColors.primary,
                              size: 32.sp,
                            ),
                          ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course['title'] ?? '',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.course['teacher']?['name'] ?? '',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Subscription Duration Section
            Text(
              'Obuna muddati',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            ...[
              {'id': 'ONE_MONTH', 'label': '1 oylik', 'recommended': false},
              {'id': 'SIX_MONTHS', 'label': '6 oylik', 'recommended': false},
              {'id': 'ONE_YEAR', 'label': '1 yillik', 'recommended': true},
            ].map((duration) {
              final isSelected = _selectedDuration == duration['id'];
              final durationInfo = _calculateSubscriptionPrice(
                duration['id'] as String,
              );
              final hasDiscount = (durationInfo['discountPercent'] as int) > 0;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDuration = duration['id'] as String;
                  _promoCodeData = null; // Reset promo when changing duration
                  _promoController.clear();
                }),
                child: Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  duration['label'] as String,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (duration['recommended'] == true) ...[
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: Text(
                                      'Tavsiya',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                if (hasDiscount) ...[
                                  Text(
                                    '${FormatUtils.formatPrice(_basePrice * (durationInfo['months'] as int))} so\'m',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                ],
                                Text(
                                  '${FormatUtils.formatPrice(durationInfo['price'] as double)} so\'m',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (hasDiscount) ...[
                              SizedBox(height: 4.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  '${durationInfo['discountPercent']}% chegirma',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: 24.h),

            // Promo Code Section
            Text(
              'Promo kod',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    enabled: _promoCodeData == null,
                    cursorHeight: 18.h,
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'Promo kodni kiriting',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                      suffixIcon: _promoCodeData != null
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                SizedBox(width: 8.w),
                SizedBox(
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _promoCodeData == null && !_isValidatingPromo
                        ? _validatePromoCode
                        : _promoCodeData != null
                        ? () {
                            setState(() {
                              _promoCodeData = null;
                              _promoController.clear();
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isValidatingPromo
                        ? SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: Lottie.asset(
                              'assets/animations/loading.json',
                              width: 24.w,
                              height: 24.h,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Text(
                            _promoCodeData == null
                                ? 'Tekshirish'
                                : 'O\'chirish',
                          ),
                  ),
                ),
              ],
            ),

            if (_promoCodeData != null) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _promoCodeData!['message'] ?? 'Promo kod qo\'llanildi',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 24.h),

            // Payment Method Section
            Text(
              'To\'lov usuli',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            ..._paymentMethods.map((paymentMethod) {
              print('🔍 Payment Method Data: $paymentMethod');
              final methodId = paymentMethod['id']!;
              final methodName = paymentMethod['name']!;
              final methodIcon = paymentMethod['icon'];
              final methodLogo = paymentMethod['logo'];
              final isSelected = _selectedMethod == methodId;
              print(
                '📝 Method ID: $methodId, Name: $methodName, Icon: $methodIcon, Logo: $methodLogo, Selected: $isSelected',
              );

              return GestureDetector(
                onTap: () {
                  print('👆 Tapped payment method: $methodId - $methodName');
                  setState(() => _selectedMethod = methodId);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56.w,
                        height: 56.h,
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.border.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: methodIcon != null
                            ? Center(
                                child: SvgPicture.asset(
                                  methodIcon,
                                  width: 28.w,
                                  height: 28.h,
                                  colorFilter: ColorFilter.mode(
                                    AppColors.primary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              )
                            : Center(
                                child: Image.asset(
                                  methodLogo!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                        methodName.substring(0, 1),
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                ),
                              ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          methodName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 24.h),

            // Price Summary
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kurs narxi', style: TextStyle(fontSize: 14.sp)),
                      Text(
                        '${FormatUtils.formatPrice(_originalPrice)} so\'m',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ],
                  ),
                  if (_subscriptionDiscount > 0) ...[
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Obuna chegirmasi',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          '- ${FormatUtils.formatPrice(_subscriptionDiscount)} so\'m',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_promoCodeData != null) ...[
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Promo kod chegirmasi',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '- ${FormatUtils.formatPrice(_promoDiscountAmount)} so\'m',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Divider(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jami',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${FormatUtils.formatPrice(_finalPrice)} so\'m',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Purchase Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPurchasing ? null : _purchaseCourse,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isPurchasing
                    ? SizedBox(
                        width: 30.w,
                        height: 30.h,
                        child: Lottie.asset(
                          'assets/animations/loading.json',
                          width: 30.w,
                          height: 30.h,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Text(
                        'To\'lovni amalga oshirish',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
