import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/components/buttons/primary_button.dart';
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
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4C7CFF), Color(0xFF3366FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Logo section
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          width: 180.w,
                          height: 100.h,
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/logo.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // White bottom section
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24.r),
                            topRight: Radius.circular(24.r),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 32.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                'Tizimga kirish',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Google Sign In Button
                              _buildSocialButton(
                                icon: 'G',
                                text: 'Google orqali davom ettrish',
                                onTap: () {
                                  Fluttertoast.showToast(
                                    msg: "Google login hozirda ishlamaydi",
                                    backgroundColor: AppColors.info,
                                  );
                                },
                              ),
                              SizedBox(height: 12.h),

                              // Apple Sign In Button
                              _buildSocialButton(
                                icon: '',
                                text: 'Sign up with Apple',
                                onTap: () {
                                  Fluttertoast.showToast(
                                    msg: "Apple login hozirda ishlamaydi",
                                    backgroundColor: AppColors.info,
                                  );
                                },
                                isApple: true,
                              ),
                              SizedBox(height: 20.h),

                              // Divider with text
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                    ),
                                    child: Text(
                                      'Yoki telefon raqam orqali davom ettiring',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),

                              // Phone label
                              Text(
                                'Telefon raqami',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8.h),

                              // Phone input
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(9),
                                    _PhoneNumberFormatter(),
                                  ],
                                  cursorColor: AppColors.primary,
                                  decoration: InputDecoration(
                                    hintText: '__ ___ __ __',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16.sp,
                                    ),
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(
                                        left: 16.w,
                                        right: 12.w,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '+998',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 16.h,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Login button
                              PrimaryButton(
                                text: 'Tizimga kirish',
                                onPressed: _sendCode,
                                isLoading: _isLoading,
                              ),
                              SizedBox(height: 16.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String text,
    required VoidCallback onTap,
    bool isApple = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isApple)
              Icon(Icons.apple, size: 24.sp, color: Colors.black)
            else
              SvgPicture.asset(
                'assets/icons/google.svg',
                width: 24.w,
                height: 24.h,
              ),
            SizedBox(width: 12.w),
            Text(
              text,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
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
