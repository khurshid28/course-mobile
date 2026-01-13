import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../../../injection_container.dart';

class BalanceTopupPage extends StatefulWidget {
  final double currentBalance;

  const BalanceTopupPage({super.key, required this.currentBalance});

  @override
  State<BalanceTopupPage> createState() => _BalanceTopupPageState();
}

class _BalanceTopupPageState extends State<BalanceTopupPage> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'CLICK';
  bool _isLoading = false;
  final List<int> _quickAmounts = [50000, 100000, 200000, 500000, 1000000];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_formatAmount);
  }

  @override
  void dispose() {
    _amountController.removeListener(_formatAmount);
    _amountController.dispose();
    super.dispose();
  }

  void _formatAmount() {
    final text = _amountController.text.replaceAll(' ', '');
    if (text.isEmpty) return;

    final number = int.tryParse(text);
    if (number == null) return;

    final formatted = FormatUtils.formatPrice(number.toDouble());
    if (_amountController.text != formatted) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _selectQuickAmount(int amount) {
    setState(() {
      _amountController.text = FormatUtils.formatPrice(amount.toDouble());
    });
  }

  Future<void> _topupBalance() async {
    final amountText = _amountController.text.trim().replaceAll(' ', '');
    if (amountText.isEmpty) {
      ToastUtils.showError(context, "Miqdorni kiriting");
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ToastUtils.showError(context, "To'g'ri miqdor kiriting");
      return;
    }

    if (amount < 10000) {
      ToastUtils.showError(context, "Minimal to'ldirish miqdori 10,000 so'm");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dataSource = getIt<PaymentRemoteDataSource>();
      await dataSource.topupBalance(amount: amount, method: _selectedMethod);

      if (!mounted) return;

      ToastUtils.showSuccess(context, "Balans muvaffaqiyatli to'ldirildi!");
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balansni to\'ldirish'),
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
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/wallet.svg',
                        width: 24.w,
                        height: 24.h,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Joriy balans',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${FormatUtils.formatPrice(widget.currentBalance)} so\'m',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // Amount Input
            Text(
              'To\'ldirish miqdori',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              cursorHeight: 18.h,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Miqdorni kiriting',
                suffixText: 'so\'m',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: SvgPicture.asset(
                    'assets/icons/card-receive.svg',
                    width: 24.w,
                    height: 24.h,
                    colorFilter: ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Quick Amount Buttons
            Text(
              'Tez tanlash',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _quickAmounts.map((amount) {
                return InkWell(
                  onTap: () => _selectQuickAmount(amount),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${FormatUtils.formatPrice(amount.toDouble())} so\'m',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 32.h),

            // Payment Method Selection
            Text(
              'To\'lov usulini tanlang',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            _buildMethodCard('CLICK', 'Click', 'assets/logos/click_logo.png'),
            SizedBox(height: 12.h),
            _buildMethodCard('PAYME', 'Payme', 'assets/logos/payme_logo.png'),
            SizedBox(height: 12.h),
            _buildMethodCard('UZUM', 'Uzum', 'assets/logos/uzum_logo.png'),
            SizedBox(height: 32.h),

            // Topup Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _topupBalance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'To\'ldirish',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 16.h),

            // Info Text
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'To\'lov tizimi sahifasiga yo\'naltirilasiz. To\'lovni amalga oshirgandan so\'ng balansga avtomatik tarzda qo\'shiladi.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(String value, String label, String logoUrl) {
    final isSelected = _selectedMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = value),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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
                border: Border.all(color: AppColors.border),
              ),
              child: Image.asset(logoUrl, fit: BoxFit.contain),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 16.sp),
              )
            else
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
