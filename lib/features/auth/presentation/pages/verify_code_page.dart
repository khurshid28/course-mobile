import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/buttons/primary_button.dart';
import '../../../../core/components/buttons/secondary_button.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../../../injection_container.dart';
import 'complete_profile_page.dart';
import '../../../home/presentation/pages/main_page.dart';

class VerifyCodePage extends StatefulWidget {
  final String phone;

  const VerifyCodePage({super.key, required this.phone});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  int _secondsRemaining = 120;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel existing timer if any
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      await authDataSource.sendCode(widget.phone);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _secondsRemaining = 120;
        _pinController.clear();
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = "Kod yuborishda xatolik. Qaytadan urinib ko'ring";
      });
    }
  }

  void _verifyCode(String code) async {
    if (code.length != 6) return;

    setState(() => _isLoading = true);

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      final authResponse = await authDataSource.verifyCode(widget.phone, code);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (authResponse.isProfileComplete ?? false) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
          (route) => false,
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfilePage(phone: widget.phone),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      print('Verification error: $e'); // Debug log
      
      setState(() {
        _isLoading = false;
        _errorMessage = "Kod noto'g'ri. Qaytadan urinib ko'ring";
      });
    }
  }

  String get _timerText {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48.w,
      height: 56.h,
      textStyle: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.r),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF3366FF), width: 2),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
        title: Text(
          'Tasdiqlash',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phone number
              Text(
                widget.phone,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12.h),
              
              // Description
              Text(
                'Ushbu telefon raqamiga 6 sonli kod yuborildi, ushbu kodni kiritng va telefon raqamingizni tasdiqlang!',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              
              // Label
              Center(
                child: Text(
                  'Kodni kiriting',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              
              // Pin input
              Pinput(
                controller: _pinController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                errorPinTheme: errorPinTheme,
                forceErrorState: _errorMessage != null,
                onCompleted: _verifyCode,
                onChanged: (value) {
                  if (_errorMessage != null && value.isNotEmpty) {
                    setState(() => _errorMessage = null);
                  }
                },
                enabled: !_isLoading,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              ),
              
              if (_errorMessage != null) ...[
                SizedBox(height: 12.h),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.error,
                  ),
                ),
              ],
              SizedBox(height: 24.h),
              
              // Resend button
              if (_secondsRemaining == 0)
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _resendCode,
                    child: Text(
                      'Qayta yuborish',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3366FF),
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Text(
                    'Qayta yuborish ($_timerText)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ),
              
              const Spacer(),
              
              // Continue button
              PrimaryButton(
                text: 'Davom ettish',
                onPressed: _pinController.text.length == 6 ? () => _verifyCode(_pinController.text) : null,
                isLoading: _isLoading,
              ),
              SizedBox(height: 12.h),
              
              // Back to login
              SecondaryButton(
                text: 'Boshqa raqam kiritish',
                onPressed: () => Navigator.pop(context),
                icon: Icons.arrow_back,
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
