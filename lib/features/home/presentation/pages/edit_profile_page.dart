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
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 32.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF3366FF),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: const Color(0xFF3366FF),
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // First Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextFormField(
                      controller: _firstNameController,
                      cursorColor: const Color(0xFF3366FF),
                      decoration: InputDecoration(
                        hintText: 'Fakhriyor',
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
                      style: TextStyle(fontSize: 14.sp, color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ismni kiriting';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Surname
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextFormField(
                      controller: _surnameController,
                      cursorColor: const Color(0xFF3366FF),
                      decoration: InputDecoration(
                        hintText: 'Eshonov',
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
                      style: TextStyle(fontSize: 14.sp, color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Familiyani kiriting';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Email
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextFormField(
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
                      style: TextStyle(fontSize: 14.sp, color: Colors.black),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!value.contains('@')) {
                            return 'Email noto\'g\'ri formatda';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Birth Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tug\'ilgan sana',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.user.dateOfBirth ?? '25.08.1998',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black,
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
                ],
              ),
              SizedBox(height: 24.h),

              // Gender Selection
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
                              : const Color(0xFFE8E8E8),
                          borderRadius: BorderRadius.circular(25.r),
                          boxShadow: _selectedGender == 'MALE'
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3366FF,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
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
                              : const Color(0xFFE8E8E8),
                          borderRadius: BorderRadius.circular(25.r),
                          boxShadow: _selectedGender == 'FEMALE'
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3366FF,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
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

              // Region
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hudud',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
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
                      style: TextStyle(fontSize: 14.sp, color: Colors.black),
                      items: _regions.keys.map((region) {
                        return DropdownMenuItem(
                          value: region,
                          child: Text(region),
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
                  ),
                ],
              ),
              SizedBox(height: 40.h),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3366FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF3366FF).withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : Text(
                          'Saqlash',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
