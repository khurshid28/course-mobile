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
  String _selectedDuration = 'ONE_MONTH';
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

  double _calculateDurationPrice(String duration) {
    switch (duration) {
      case 'ONE_MONTH':
        return _basePrice;
      case 'SIX_MONTHS':
        // 6 months with 15% discount
        return (_basePrice * 6) * 0.85;
      case 'ONE_YEAR':
        // 12 months with 25% discount
        return (_basePrice * 12) * 0.75;
      default:
        return _basePrice;
    }
  }

  double get _promoDiscountAmount {
    final discount = _promoCodeData?['discountAmount'];
    if (discount == null) return 0;
    if (discount is num) return discount.toDouble();
    if (discount is String) return double.tryParse(discount) ?? 0;
    return 0;
  }

  double get _finalPrice {
    final durationPrice = _calculateDurationPrice(_selectedDuration);
    final finalPrice = _promoCodeData?['finalPrice'];
    if (finalPrice != null) {
      if (finalPrice is num) return finalPrice.toDouble();
      if (finalPrice is String)
        return double.tryParse(finalPrice) ?? durationPrice;
    }
    return durationPrice - _promoDiscountAmount;
  }

  final List<Map<String, String>> _paymentMethods = [
    {'id': 'BALANCE', 'name': 'Balans', 'icon': 'assets/icons/wallet.svg'},
    {'id': 'CLICK', 'name': 'Click', 'logo': 'assets/logos/click_logo.png'},
    {'id': 'PAYME', 'name': 'Payme', 'logo': 'assets/logos/payme_logo.png'},
    {'id': 'UZUM', 'name': 'Uzum', 'logo': 'assets/logos/uzum_logo.png'},
  ];

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

      setState(() {
        _promoCodeData = result;
        _isValidatingPromo = false;
      });

      if (mounted) {
        ToastUtils.showSuccess(context, 'Promo kod qo\'llanildi');
      }
    } catch (e) {
      setState(() {
        _isValidatingPromo = false;
        _promoCodeData = null;
      });

      if (mounted) {
        ToastUtils.showError(context, e);
      }
    }
  }

  void _clearPromoCode() {
    setState(() {
      _promoCodeData = null;
      _promoController.clear();
    });
  }

  Future<void> _purchaseCourse() async {
    if (_selectedMethod == null) {
      ToastUtils.showError(context, 'To\'lov usulini tanlang');
      return;
    }

    setState(() => _isPurchasing = true);

    final scaffoldContext = context;

    try {
      final paymentDataSource = getIt<PaymentRemoteDataSource>();

      // Check balance if BALANCE method selected
      if (_selectedMethod == 'BALANCE') {
        final balance = await paymentDataSource.getBalance();
        if (balance < _finalPrice) {
          setState(() => _isPurchasing = false);

          if (!mounted) return;

          final dialogContext = context;
          await showDialog(
            context: dialogContext,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Text(
                      'Mablag\' yetarli emas',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
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
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await Future.delayed(
                                const Duration(milliseconds: 150),
                              );
                              if (!mounted) return;
                              final result = await Navigator.of(scaffoldContext)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => BalanceTopupPage(
                                        currentBalance: balance,
                                      ),
                                    ),
                                  );
                              if (result == true && mounted) {
                                ToastUtils.showSuccess(
                                  scaffoldContext,
                                  'Balans to\'ldirildi!',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'To\'ldirish',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
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
          return;
        }
      }

      final result = await paymentDataSource.createPayment(
        courseId: widget.course['id'],
        amount: _finalPrice,
        method: _selectedMethod!,
        subscriptionDuration: _selectedDuration,
        promoCode: _promoCodeData != null ? _promoController.text.trim() : null,
      );

      if (!mounted) return;

      // Check if payment was successful
      if (result['status'] == 'SUCCESS' || result['paymentId'] != null) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animations/loading.json',
                    width: 120.w,
                    height: 120.h,
                    fit: BoxFit.contain,
                    repeat: false,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Kurs muvaffaqiyatli sotib olindi!',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Kurs sizning profilingizga qo\'shildi. Endi o\'qishni boshlashingiz mumkin.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(scaffoldContext).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const MainPage(initialIndex: 1),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Kurslarimga o\'tish',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        setState(() => _isPurchasing = false);
        if (mounted) {
          ToastUtils.showError(
            context,
            result['message'] ?? 'Xatolik yuz berdi',
          );
        }
      }
    } catch (e) {
      setState(() => _isPurchasing = false);
      if (mounted) {
        ToastUtils.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sotib olish'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Info Card
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: CachedNetworkImage(
                            imageUrl:
                                widget.course['thumbnail'] != null &&
                                    widget.course['thumbnail']
                                        .toString()
                                        .isNotEmpty
                                ? (widget.course['thumbnail']
                                          .toString()
                                          .startsWith('http')
                                      ? widget.course['thumbnail'].toString()
                                      : '${AppConstants.baseUrl}${widget.course['thumbnail']}')
                                : '',
                            width: 80.w,
                            height: 80.h,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.course['teacher']?['name'] != null)
                                Text(
                                  widget.course['teacher']['name'],
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (widget.course['teacher']?['name'] != null)
                                SizedBox(height: 6.h),
                              Text(
                                widget.course['title'] ?? '',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '${FormatUtils.formatPrice(_basePrice)} UZS',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3366FF),
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
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...[
                    {'id': 'ONE_MONTH', 'label': '1 oylik'},
                    {'id': 'SIX_MONTHS', 'label': '6 oylik'},
                    {'id': 'ONE_YEAR', 'label': '1 yillik'},
                  ].map((duration) {
                    final isSelected = _selectedDuration == duration['id'];
                    final durationPrice = _calculateDurationPrice(
                      duration['id'] as String,
                    );
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedDuration = duration['id'] as String;
                        _promoCodeData =
                            null; // Reset promo when changing duration
                        _promoController.clear();
                      }),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3366FF)
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF3366FF)
                                      : const Color(0xFFD1D5DB),
                                  width: 2,
                                ),
                                color: isSelected
                                    ? const Color(0xFF3366FF)
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 8.w,
                                        height: 8.h,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                duration['label']!,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Text(
                              '${FormatUtils.formatPrice(durationPrice)} so\'m',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3366FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 24.h),

                  // Payment Method Section
                  Text(
                    'To\'lov tizimini tanlang',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ..._paymentMethods.map((method) {
                    final isSelected = _selectedMethod == method['id'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedMethod = method['id']),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3366FF)
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF3366FF)
                                      : const Color(0xFFD1D5DB),
                                  width: 2,
                                ),
                                color: isSelected
                                    ? const Color(0xFF3366FF)
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 8.w,
                                        height: 8.h,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                method['name']!,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            if (method['icon'] != null)
                              SvgPicture.asset(
                                method['icon']!,
                                height: 24.h,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF3366FF),
                                  BlendMode.srcIn,
                                ),
                              )
                            else
                              Image.asset(
                                method['logo']!,
                                height: 24.h,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  SizedBox(height: 24.h),

                  // Promo Code Section
                  Text(
                    'Promo kod (ixtiyoriy)',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: TextField(
                            controller: _promoController,
                            decoration: InputDecoration(
                              hintText: 'Promo kodni kiriting',
                              hintStyle: TextStyle(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 14.sp,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed: _isValidatingPromo
                            ? null
                            : (_promoCodeData == null
                                  ? _validatePromoCode
                                  : _clearPromoCode),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _promoCodeData == null
                              ? const Color(0xFF3366FF)
                              : Colors.red,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: _isValidatingPromo
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _promoCodeData == null
                                    ? 'Tekshirish'
                                    : 'O\'chirish',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),

                  if (_promoCodeData != null) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _promoCodeData!['message'] ??
                                      'Promo kod qo\'llanildi',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                if (_promoDiscountAmount > 0) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${FormatUtils.formatPrice(_promoDiscountAmount)} so\'m chegirma',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Umumiy to\'lov',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '${FormatUtils.formatPrice(_finalPrice)} so\'m',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3366FF),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPurchasing ? null : _purchaseCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3366FF),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isPurchasing
                          ? SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Davom etish',
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
          ),
        ],
      ),
    );
  }
}
