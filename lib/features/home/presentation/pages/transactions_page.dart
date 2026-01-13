import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../../../injection_container.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  String? _selectedType;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final dataSource = getIt<PaymentRemoteDataSource>();
      final transactions = await dataSource.getPaymentHistory();

      if (!mounted) return;

      setState(() {
        _transactions = transactions
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _filteredTransactions = _transactions;
        _isLoading = false;
      });
    } catch (e) {
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
              // Header
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

              // To'lov turi
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
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: tempType,
                    isExpanded: true,
                    hint: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'Tanlang',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                    icon: Padding(
                      padding: EdgeInsets.only(right: 16.w),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text('Barchasi'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'BALANCE_TOPUP',
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text('Balans to\'ldirish'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'COURSE_PURCHASE',
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text('Kurs sotib olish'),
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

              // Sana
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

              // Saqlash button
              SizedBox(
                width: double.infinity,
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
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        // Type filter
        if (_selectedType != null) {
          final type = transaction['type'] as String?;
          if (type != _selectedType) return false;
        }

        // Date filter
        if (_selectedDate != null) {
          final createdAt = transaction['createdAt'] as String?;
          if (createdAt != null) {
            try {
              final transactionDate = DateTime.parse(createdAt);
              if (!_isSameDay(transactionDate, _selectedDate!)) {
                return false;
              }
            } catch (e) {
              return false;
            }
          }
        }

        return true;
      }).toList();
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
      _filteredTransactions = _transactions;
    });
  }

  bool get hasFilters => _selectedType != null || _selectedDate != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Tranzaksiyalar tarixi',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: hasFilters ? AppColors.primary : Colors.black,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: _filteredTransactions.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200.h,
                        child: _buildEmptyState(),
                      ),
                    )
                  : Column(
                      children: [
                        if (hasFilters) _buildFilterChips(),
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.all(16.w),
                            itemCount: _filteredTransactions.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 12.h),
                            itemBuilder: (context, index) {
                              final transaction = _filteredTransactions[index];
                              return _buildTransactionCard(transaction);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: Colors.white,
      child: Row(
        children: [
          if (_selectedType != null)
            _buildFilterChip(_getTypeText(_selectedType!), () {
              setState(() {
                _selectedType = null;
                _applyFilters();
              });
            }),
          if (_selectedType != null && _selectedDate != null)
            SizedBox(width: 8.w),
          if (_selectedDate != null)
            _buildFilterChip(
              DateFormat('dd.MM.yyyy').format(_selectedDate!),
              () {
                setState(() {
                  _selectedDate = null;
                  _applyFilters();
                });
              },
            ),
          const Spacer(),
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              'Tozalash',
              style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4.w),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close, size: 16.sp, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final amount = transaction['amount'] as num? ?? 0;
    final type = transaction['type'] as String? ?? '';
    final createdAt = transaction['createdAt'] as String?;
    final description =
        transaction['description'] as String? ??
        'Java dasturlash tili asoslari';

    return Container(
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
          // PayPal icon
          Container(
            width: 40.w,
            height: 40.h,
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: SvgPicture.asset(
              'assets/icons/wallet.svg',
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
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
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${amount > 0 ? '-' : ''}${amount.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} uzs',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'Tranzaksiyalar yo\'q',
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
                : 'Hozircha tranzaksiyalar mavjud emas',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9CA3AF)),
          ),
          if (hasFilters) ...[
            SizedBox(height: 16.h),
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                'Filterlarni tozalash',
                style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Noma\'lum';

    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd - MMMM, yyyy', 'uz').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'BALANCE_TOPUP':
        return 'Balans to\'ldirish';
      case 'COURSE_PURCHASE':
        return 'Kurs sotib olish';
      default:
        return type;
    }
  }
}
