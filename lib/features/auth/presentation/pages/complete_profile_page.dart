import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../../../injection_container.dart';
import '../../../home/presentation/pages/main_page.dart';

class CompleteProfilePage extends StatefulWidget {
  final String phone;

  const CompleteProfilePage({super.key, required this.phone});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedGender;
  String? _selectedRegion;
  bool _isLoading = false;

  final Map<String, String> _regions = {
    'Toshkent shahar': 'TOSHKENT_SHAHAR',
    'Toshkent viloyati': 'TOSHKENT_VILOYATI',
    'Andijon': 'ANDIJON',
    'Buxoro': 'BUXORO',
    'Farg\'ona': 'FARGONA',
    'Jizzax': 'JIZZAX',
    'Xorazm': 'XORAZM',
    'Namangan': 'NAMANGAN',
    'Navoiy': 'NAVOIY',
    'Qashqadaryo': 'QASHQADARYO',
    'Qoraqalpog\'iston': 'QORAQALPOGISTON',
    'Samarqand': 'SAMARQAND',
    'Sirdaryo': 'SIRDARYO',
    'Surxondaryo': 'SURXONDARYO',
  };

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _completeProfile() async {
    if (_firstNameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
        _selectedGender == null ||
        _selectedRegion == null) {
      Fluttertoast.showToast(
        msg: "Barcha maydonlarni to'ldiring",
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
      await authDataSource.completeProfile(
        firstName: _firstNameController.text,
        surname: _surnameController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        gender: _selectedGender!,
        region: _regions[_selectedRegion!]!,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
        (route) => false,
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profilni to\'ldirish'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ma\'lumotlaringizni kiriting',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Bu ma\'lumotlar sizning profilingizda ko\'rsatiladi',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 32.h),
              TextField(
                controller: _firstNameController,
                cursorHeight: 18.h,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  labelText: 'Ism',
                  hintText: 'Ismingizni kiriting',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset(
                      'assets/icons/user.svg',
                      width: 24.w,
                      height: 24.h,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _surnameController,
                cursorHeight: 18.h,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  labelText: 'Familiya',
                  hintText: 'Familiyangizni kiriting',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset(
                      'assets/icons/user.svg',
                      width: 24.w,
                      height: 24.h,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                cursorHeight: 18.h,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  labelText: 'Email (ixtiyoriy)',
                  hintText: 'emailingiz@example.com',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset(
                      'assets/icons/mail.svg',
                      width: 24.w,
                      height: 24.h,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Jins',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = 'MALE'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: _selectedGender == 'MALE'
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.white,
                          border: Border.all(
                            color: _selectedGender == 'MALE'
                                ? AppColors.primary
                                : AppColors.border,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          children: [
                             SvgPicture.asset(
                              'assets/icons/man.svg',
                              width: 40.w,
                              height: 40.h,
                              colorFilter: ColorFilter.mode(
                                _selectedGender == 'MALE'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Erkak',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: _selectedGender == 'MALE'
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: _selectedGender == 'MALE'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = 'FEMALE'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: _selectedGender == 'FEMALE'
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.white,
                          border: Border.all(
                            color: _selectedGender == 'FEMALE'
                                ? AppColors.primary
                                : AppColors.border,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/woman.svg',
                              width: 40.w,
                              height: 40.h,
                              colorFilter: ColorFilter.mode(
                                _selectedGender == 'FEMALE'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Ayol',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: _selectedGender == 'FEMALE'
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: _selectedGender == 'FEMALE'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: InputDecoration(
                  labelText: 'Viloyat',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset(
                      'assets/icons/location-check.svg',
                      width: 24.w,
                      height: 24.h,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _regions.keys
                    .map(
                      (region) =>
                          DropdownMenuItem(value: region, child: Text(region)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedRegion = value),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeProfile,
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
                      : const Text('Yakunlash'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
