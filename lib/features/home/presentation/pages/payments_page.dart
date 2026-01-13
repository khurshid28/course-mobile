import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/toast_utils.dart';
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
  List<Map<String, dynamic>> _filteredPayments = [];
  String? _selectedType;
  DateTime? _selectedDate;

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

      debugPrint('💳 ========== PAYMENTS PAGE ==========');
      debugPrint('📊 Loaded ${payments.length} payments');
      for (var payment in payments) {
        debugPrint(
          '  - Payment: ${payment['type']}, Method: ${payment['method']}, Amount: ${payment['amount']}',
        );
      }
      debugPrint('💳 =====================================');

      if (!mounted) return;

      setState(() {
        _payments = payments.map((e) => e as Map<String, dynamic>).toList();
        _filteredPayments = _payments;
        _isLoading = false;
      });

      // Re-apply filters if any are active
      if (_selectedType != null || _selectedDate != null) {
        debugPrint('🔍 Re-applying filters after refresh...');
        _applyFilters();
      }
    } catch (e) {
      debugPrint('❌ Payment history error: $e');
      if (!mounted) return;

      setState(() => _isLoading = false);
      ToastUtils.showError(context, e);
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    String? tempType = _selectedType;
    DateTime? tempDate = _selectedDate;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filterlash',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Text(
                'To\'lov turi',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12.r),
                  color: const Color(0xFFF9FAFB),
                ),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: tempType,
                    isExpanded: true,
                    isDense: false,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    menuMaxHeight: 300.h,
                    dropdownColor: Colors.white,
                    hint: Text(
                      'Tanlang',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF6B7280),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Barchasi',
                          style: TextStyle(fontSize: 15.sp),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'BALANCE_TOPUP',
                        child: Text(
                          'Balans to\'ldirish',
                          style: TextStyle(fontSize: 15.sp),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'COURSE_PURCHASE',
                        child: Text(
                          'Kurs sotib olish',
                          style: TextStyle(fontSize: 15.sp),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        tempType = value;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Sana',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 12.h),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setModalState(() {
                      tempDate = date;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12.r),
                    color: const Color(0xFFF9FAFB),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tempDate != null
                            ? DateFormat('dd.MM.yyyy').format(tempDate!)
                            : 'Tanlang',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: tempDate != null
                              ? const Color(0xFF1F2937)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        color: const Color(0xFF6B7280),
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        debugPrint('🧹 Clearing all filters');
                        setModalState(() {
                          tempType = null;
                          tempDate = null;
                        });
                        setState(() {
                          _selectedType = null;
                          _selectedDate = null;
                          _filteredPayments = _payments;
                        });
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        side: BorderSide(
                          color: const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Tozalash',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = tempType;
                          _selectedDate = tempDate;
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Saqlash',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  void _applyFilters() {
    debugPrint('🔍 Applying filters...');
    debugPrint('  Selected Type: $_selectedType');
    debugPrint('  Selected Date: $_selectedDate');
    debugPrint('  Total Payments: ${_payments.length}');

    setState(() {
      _filteredPayments = _payments.where((payment) {
        if (_selectedType != null) {
          final type = payment['type'] as String?;
          if (type != _selectedType) {
            debugPrint(
              '  Filtered out: Type mismatch ($type != $_selectedType)',
            );
            return false;
          }
        }

        if (_selectedDate != null) {
          final paymentDate = payment['paymentDate'] as String?;
          if (paymentDate != null) {
            try {
              final date = DateTime.parse(paymentDate);
              if (!_isSameDay(date, _selectedDate!)) {
                debugPrint('  Filtered out: Date mismatch');
                return false;
              }
            } catch (e) {
              debugPrint('  Filtered out: Date parse error');
              return false;
            }
          }
        }

        return true;
      }).toList();

      debugPrint('  Filtered Results: ${_filteredPayments.length} payments');
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedDate = null;
      _filteredPayments = _payments;
    });
  }

  bool get hasFilters => _selectedType != null || _selectedDate != null;

  void _showPaymentDetails(Map<String, dynamic> payment) {
    final amountValue = payment['amount'];
    final amount = amountValue is String
        ? int.tryParse(amountValue) ?? 0
        : (amountValue as num?)?.toInt() ?? 0;
    final course = payment['course'] as Map<String, dynamic>?;
    final promoCode = payment['promoCode'] as Map<String, dynamic>?;
    final paymentProvider = payment['method'] as String? ?? 'CLICK';
    final transactionId = payment['transactionId'] as String? ?? 'N/A';

    debugPrint(
      '🔍 Payment Details - Method: $paymentProvider, Type: ${payment['type']}',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: double.maxFinite,
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Provider logo
                Container(
                  width: 60.w,
                  height: 60.h,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: paymentProvider.toUpperCase() == 'BALANCE'
                      ? SvgPicture.asset(
                          _getProviderLogo(paymentProvider),
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                        )
                      : Image.asset(
                          _getProviderLogo(paymentProvider),
                          fit: BoxFit.contain,
                        ),
                ),
                SizedBox(height: 16.h),

                // Title
                Text(
                  'To\'lov ma\'lumotlari',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 20.h),

                // Payment details
                _buildDetailRow(
                  'To\'lov turi:',
                  payment['type'] == 'BALANCE_TOPUP'
                      ? 'Balans to\'ldirish'
                      : 'Kurs sotib olish',
                ),
                if (course != null) ...[
                  SizedBox(height: 12.h),
                  _buildDetailRow('Kurs:', course['title'] ?? 'N/A'),
                ],
                SizedBox(height: 12.h),
                _buildDetailRow(
                  'To\'lov tizimi:',
                  _getProviderName(paymentProvider),
                ),
                SizedBox(height: 12.h),
                _buildDetailRow('Tranzaksiya ID:', transactionId),
                SizedBox(height: 12.h),
                _buildDetailRow('Sana:', _formatDate(payment['paymentDate'])),
                if (promoCode != null) ...[
                  SizedBox(height: 12.h),
                  _buildDetailRow(
                    'Promokod:',
                    promoCode['code'] ?? 'N/A',
                    valueColor: const Color(0xFF10B981),
                  ),
                ],
                SizedBox(height: 12.h),
                Divider(height: 1.h, color: const Color(0xFFE5E7EB)),
                SizedBox(height: 12.h),
                _buildDetailRow(
                  'Summa:',
                  '${payment['type'] == 'BALANCE_TOPUP' ? '+' : '-'}${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} uzs',
                  valueColor: payment['type'] == 'BALANCE_TOPUP'
                      ? const Color(0xFF10B981)
                      : const Color(0xFF1F2937),
                  isBold: true,
                ),
                SizedBox(height: 20.h),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Yopish',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: valueColor ?? const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _getProviderLogo(String provider) {
    debugPrint('🖼️ Getting logo for provider: $provider');
    switch (provider.toUpperCase()) {
      case 'BALANCE':
        return 'assets/icons/wallet.svg';
      case 'PAYME':
        return 'assets/logos/payme_logo.png';
      case 'UZUM':
        return 'assets/logos/uzum_logo.png';
      case 'CLICK':
      default:
        return 'assets/logos/click_logo.png';
    }
  }

  String _getProviderName(String provider) {
    debugPrint('📝 Getting name for provider: $provider');
    switch (provider.toUpperCase()) {
      case 'BALANCE':
        return 'Balans';
      case 'PAYME':
        return 'Payme';
      case 'UZUM':
        return 'Uzum';
      case 'CLICK':
      default:
        return 'Click';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Noma\'lum';

    try {
      final date = DateTime.parse(dateStr);
      final monthNames = {
        1: 'Yanvar',
        2: 'Fevral',
        3: 'Mart',
        4: 'Aprel',
        5: 'May',
        6: 'Iyun',
        7: 'Iyul',
        8: 'Avgust',
        9: 'Sentyabr',
        10: 'Oktyabr',
        11: 'Noyabr',
        12: 'Dekabr',
      };
      return '${date.day} - ${monthNames[date.month]}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'To\'lovlar',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/filter.svg',
                  width: 24.sp,
                  height: 24.sp,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () {
                  _showFilterDialog();
                },
              ),
              if (hasFilters)
                Positioned(
                  right: 8.w,
                  top: 8.h,
                  child: Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPayments,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredPayments.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200.h,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64.sp,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'To\'lovlar yo\'q',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          hasFilters
                              ? 'Filterlar bo\'yicha natija topilmadi'
                              : 'Hozircha to\'lovlar mavjud emas',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        if (hasFilters) ...[
                          SizedBox(height: 16.h),
                          TextButton(
                            onPressed: _clearFilters,
                            child: Text(
                              'Filterlarni tozalash',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: _filteredPayments.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final payment = _filteredPayments[index];
                  final amountValue = payment['amount'];
                  final amount = amountValue is String
                      ? int.tryParse(amountValue) ?? 0
                      : (amountValue as num?)?.toInt() ?? 0;
                  final course = payment['course'] as Map<String, dynamic>?;
                  final promoCode =
                      payment['promoCode'] as Map<String, dynamic>?;
                  final description = payment['type'] == 'BALANCE_TOPUP'
                      ? 'Balans to\'ldirish'
                      : (course?['title'] ?? 'Kurs sotib olish');
                  final paymentProvider =
                      payment['method'] as String? ?? 'CLICK';

                  debugPrint(
                    '📋 List Item - Method: $paymentProvider, Type: ${payment['type']}',
                  );

                  return GestureDetector(
                    onTap: () => _showPaymentDetails(payment),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Provider logo
                          Container(
                            width: 40.w,
                            height: 40.h,
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: paymentProvider.toUpperCase() == 'BALANCE'
                                ? SvgPicture.asset(
                                    _getProviderLogo(paymentProvider),
                                    fit: BoxFit.contain,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.primary,
                                      BlendMode.srcIn,
                                    ),
                                  )
                                : Image.asset(
                                    _getProviderLogo(paymentProvider),
                                    fit: BoxFit.contain,
                                  ),
                          ),
                          SizedBox(width: 12.w),
                          // Transaction info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1F2937),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  _formatDate(payment['paymentDate']),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                if (promoCode != null) ...[
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_offer,
                                        size: 12.sp,
                                        color: const Color(0xFF10B981),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        promoCode['code'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF10B981),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Amount
                          Text(
                            '${payment['type'] == 'BALANCE_TOPUP' ? '+' : '-'}${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} uzs',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: payment['type'] == 'BALANCE_TOPUP'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
