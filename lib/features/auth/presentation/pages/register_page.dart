import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../../../injection_container.dart';
import 'verify_code_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendCode() async {
    final phone =
        AppConstants.phonePrefix + _phoneController.text.replaceAll(' ', '');

    if (_phoneController.text.replaceAll(' ', '').length != 9) {
      Fluttertoast.showToast(
        msg: "Telefon raqamni to'liq kiriting",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.error,
        textColor: Colors.white,
        fontSize: 16.sp,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      await authDataSource.sendCode(phone);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyCodePage(phone: phone)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      Fluttertoast.showToast(
        msg: 'Xatolik: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.error,
        textColor: Colors.white,
        fontSize: 16.sp,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xush kelibsiz! 👋',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Davom etish uchun telefon raqamingizni kiriting',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 48.h),
              Text(
                'Telefon raqam',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                  _PhoneNumberFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: '',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 12.w, right: 12.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/phone.svg',
                          width: 20.w,
                          height: 20.h,
                          colorFilter: ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          width: 1,
                          height: 24.h,
                          color: AppColors.border,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '+998',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
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
                      : const Text('Davom etish'),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text.replaceAll(' ', '');
    final newText = newValue.text;

    if (newText.isEmpty) {
      return newValue;
    }

    // Agar bo'sh joy o'chirilgan bo'lsa, undan oldingi raqamni o'chirish
    if (oldValue.text.length > newValue.text.length &&
        oldValue.selection.baseOffset > 0) {
      final deletedChar = oldValue.text[oldValue.selection.baseOffset - 1];
      if (deletedChar == ' ') {
        // Bo'sh joy o'chirildi, raqamni ham o'chirish kerak
        final digitsOnly = oldText;
        if (digitsOnly.isNotEmpty) {
          final newDigits = digitsOnly.substring(0, digitsOnly.length - 1);
          return _formatNumber(newDigits, newDigits.length);
        }
      }
    }

    return _formatNumber(newText, newValue.selection.baseOffset);
  }

  TextEditingValue _formatNumber(String digits, int cursorPosition) {
    if (digits.isEmpty) {
      return TextEditingValue.empty;
    }

    final buffer = StringBuffer();
    int newCursorPosition = cursorPosition;

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 4 || i == 6) && i < digits.length - 1) {
        buffer.write(' ');
        // Agar cursor bu pozitsiyadan keyin bo'lsa, +1 qo'shamiz
        if (i < cursorPosition) {
          newCursorPosition++;
        }
      }
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursorPosition.clamp(0, formatted.length),
      ),
    );
  }
}
