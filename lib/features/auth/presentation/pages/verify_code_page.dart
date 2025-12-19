import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
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
      setState(() => _isLoading = false);

      Fluttertoast.showToast(
        msg: "Kod noto'g'ri yoki xatolik: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.error,
        textColor: Colors.white,
        fontSize: 16.sp,
      );
      _pinController.clear();
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
      width: 56.w,
      height: 60.h,
      textStyle: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tasdiqlash kodi',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                '${widget.phone} raqamiga yuborilgan 6 xonali kodni kiriting',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 48.h),
              Center(
                child: Pinput(
                  controller: _pinController,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  onCompleted: _verifyCode,
                  enabled: !_isLoading,
                ),
              ),
              SizedBox(height: 32.h),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          Text(
                            _timerText,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          if (_secondsRemaining == 0)
                            TextButton(
                              onPressed: () {
                                setState(() => _secondsRemaining = 120);
                                _startTimer();
                                // TODO: Resend code API call
                              },
                              child: const Text('Qayta yuborish'),
                            ),
                        ],
                      ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
