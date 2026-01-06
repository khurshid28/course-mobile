import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../injection_container.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  String? _selectedGender;
  String? _selectedRegion;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Region mapping
  final Map<String, String> _regions = {
    'Toshkent shahar': 'TOSHKENT_SHAHAR',
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
    'Toshkent viloyati': 'TOSHKENT_VILOYATI',
  };

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _surnameController = TextEditingController(text: widget.user.surname);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedGender = widget.user.gender;

    // Convert backend region to display name
    if (widget.user.region != null) {
      _selectedRegion = _regions.entries
          .firstWhere(
            (entry) => entry.value == widget.user.region,
            orElse: () => MapEntry('', ''),
          )
          .key;
      if (_selectedRegion!.isEmpty) _selectedRegion = null;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null || _selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcha maydonlarni to\'ldiring')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();

      // Upload image if selected
      String? avatarUrl;
      if (_imageFile != null) {
        avatarUrl = await authDataSource.uploadImage(_imageFile!.path);
      }

      await authDataSource.completeProfile(
        firstName: _firstNameController.text,
        surname: _surnameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        gender: _selectedGender!,
        region: _regions[_selectedRegion!]!,
        avatar: avatarUrl,
      );

      if (!mounted) return;

      ToastUtils.showSuccess(context, 'Profil muvaffaqiyatli yangilandi');

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ToastUtils.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shaxsiy ma\'lumotlar'),
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(8.w),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
              iconSize: 18.sp,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 60.r,
                        backgroundColor: AppColors.secondary,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (widget.user.avatar != null &&
                                      widget.user.avatar!.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      ImageUtils.getFullImageUrl(
                                        widget.user.avatar,
                                      ),
                                    )
                                  : null),
                        child:
                            _imageFile == null &&
                                (widget.user.avatar == null ||
                                    widget.user.avatar!.isEmpty)
                            ? Text(
                                '${widget.user.firstName?[0] ?? ''}${widget.user.surname?[0] ?? ''}'
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/camera.svg',
                          width: 20.w,
                          height: 20.h,
                          colorFilter: const ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // First Name
              TextFormField(
                controller: _firstNameController,
                cursorHeight: 18.h,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  labelText: 'Ism',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset(
                      'assets/icons/user.svg',
                      width: 24.w,
                      height: 24.h,
                      colorFilter: ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ismni kiriting';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Surname
              TextFormField(
                controller: _surnameController,
                cursorHeight: 18.h,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  labelText: 'Familiya',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset(
                      'assets/icons/user.svg',
                      width: 24.w,
                      height: 24.h,
                      colorFilter: ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Familiyani kiriting';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                cursorHeight: 18.h,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  labelText: 'Email (ixtiyoriy)',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset(
                      'assets/icons/mail.svg',
                      width: 24.w,
                      height: 24.h,
                      colorFilter: ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Email noto\'g\'ri formatda';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),

              // Gender Selection
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
                        padding: EdgeInsets.all(20.w),
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
                          boxShadow: [
                            if (_selectedGender == 'MALE')
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/man.svg',
                              width: 52.w,
                              height: 52.h,
                              colorFilter: ColorFilter.mode(
                                _selectedGender == 'MALE'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Erkak',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: _selectedGender == 'MALE'
                                    ? FontWeight.w700
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
                        padding: EdgeInsets.all(20.w),
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
                          boxShadow: [
                            if (_selectedGender == 'FEMALE')
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/woman.svg',
                              width: 52.w,
                              height: 52.h,
                              colorFilter: ColorFilter.mode(
                                _selectedGender == 'FEMALE'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Ayol',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: _selectedGender == 'FEMALE'
                                    ? FontWeight.w700
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

              // Region
              Text(
                'Hudud',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset(
                      'assets/icons/location-check.svg',
                      width: 24.w,
                      height: 24.h,
                      colorFilter: ColorFilter.mode(
                        _selectedRegion != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  hintText: 'Hududni tanlang',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  filled: false,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: 28.sp,
                ),
                dropdownColor: Colors.white,
                items: _regions.keys.map((region) {
                  return DropdownMenuItem(
                    value: region,
                    child: Text(
                      region,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Hududni tanlang';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32.h),

              // Phone (readonly)
              TextFormField(
                initialValue: widget.user.phone,
                enabled: false,
                cursorHeight: 18.h,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset(
                      'assets/icons/phone.svg',
                      width: 24.w,
                      height: 24.h,
                      colorFilter: ColorFilter.mode(
                        AppColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: AppColors.secondary,
                ),
              ),
              SizedBox(height: 40.h),

              // Save Button
              Container(
                width: double.infinity,
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [Colors.grey, Colors.grey.shade400]
                        : [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
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
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Saqlanmoqda...',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Saqlash',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
