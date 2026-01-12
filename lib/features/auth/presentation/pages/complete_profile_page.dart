import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/buttons/primary_button.dart';
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
  DateTime? _selectedDate;
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF3366FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _completeProfile() async {
    if (_firstNameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
        _selectedGender == null) {
      Fluttertoast.showToast(
        msg: "Ism, Familiya va Jins majburiy maydonlar",
        backgroundColor: AppColors.error,
        textColor: Colors.white,
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
        dateOfBirth: _selectedDate != null 
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
        region: _selectedRegion != null ? _regions[_selectedRegion] : null,
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
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Shaxsiy ma\'lumotlar',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Barcha shaxsiy ma\'lumotlaringizni kiriting',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF666666),
                ),
              ),
              SizedBox(height: 32.h),
              
              // Ism
              Text(
                'Ism',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  controller: _firstNameController,
                  cursorColor: const Color(0xFF3366FF),
                  decoration: InputDecoration(
                    hintText: 'Ismingizni kiriting',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
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
              SizedBox(height: 16.h),
              
              // Familiya
              Text(
                'Familiya',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  controller: _surnameController,
                  cursorColor: const Color(0xFF3366FF),
                  decoration: InputDecoration(
                    hintText: 'Familiyangizni kiriting',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
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
              SizedBox(height: 16.h),
              
              // Email
              Text(
                'Email (ixtiyoriy)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: const Color(0xFF3366FF),
                  decoration: InputDecoration(
                    hintText: 'Email manzilingizni kiriting',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
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
              SizedBox(height: 16.h),
              
              // Tug'ilgan sana
              Text(
                'Tug\'ilgan sana',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
                            : '25.08.2025',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: _selectedDate != null 
                              ? Colors.black 
                              : Colors.grey[400],
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/icons/calendar.svg',
                        width: 18.w,
                        height: 18.h,
                        colorFilter: ColorFilter.mode(
                          Colors.grey[600]!,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              
              // Jins
              Text(
                'Jins',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedGender = 'MALE'),
                      child: Container(
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: _selectedGender == 'MALE'
                              ? const Color(0xFF3366FF)
                              : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(25.r),
                          boxShadow: _selectedGender == 'MALE' ? [
                            BoxShadow(
                              color: const Color(0xFF3366FF).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ] : [],
                        ),
                        child: Center(
                          child: Text(
                            'Erkak',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: _selectedGender == 'MALE'
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedGender = 'FEMALE'),
                      child: Container(
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: _selectedGender == 'FEMALE'
                              ? const Color(0xFF3366FF)
                              : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(25.r),
                          boxShadow: _selectedGender == 'FEMALE' ? [
                            BoxShadow(
                              color: const Color(0xFF3366FF).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ] : [],
                        ),
                        child: Center(
                          child: Text(
                            'Ayol',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: _selectedGender == 'FEMALE'
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              
              // Hudud
              Text(
                'Hudud (ixtiyoriy)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  icon: Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                      size: 24.sp,
                    ),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Hududingizni tanlang',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14.sp,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black,
                  ),
                  items: _regions.keys
                      .map(
                        (region) => DropdownMenuItem(
                          value: region,
                          child: Text(region),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRegion = value),
                ),
              ),
              SizedBox(height: 32.h),
              
              // Yakunlash button
              PrimaryButton(
                text: 'Yakunlash',
                onPressed: _completeProfile,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
