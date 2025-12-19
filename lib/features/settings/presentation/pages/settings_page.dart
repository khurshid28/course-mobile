import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'uz';
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sozlamalar'),
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
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Language Section
          Text(
            'Til',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          _buildLanguageCard('O\'zbekcha', 'uz'),
          SizedBox(height: 8.h),
          _buildLanguageCard('Русский', 'ru'),
          SizedBox(height: 8.h),
          _buildLanguageCard('English', 'en'),

          SizedBox(height: 32.h),

          // Appearance Section
          Text(
            'Ko\'rinish',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              title: const Text('Qorong\'u rejim'),
              subtitle: const Text('Tungi rejimni yoqish'),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() => _isDarkMode = value);
                // TODO: Implement theme change
              },
              activeColor: AppColors.primary,
            ),
          ),

          SizedBox(height: 32.h),

          // Notifications Section
          Text(
            'Bildirishnomalar',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              title: const Text('Push bildirishnomalar'),
              subtitle: const Text('Yangi kurslar va yangilanishlar haqida'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                // TODO: Update notification settings
              },
              activeColor: AppColors.primary,
            ),
          ),

          SizedBox(height: 32.h),

          // Other Settings
          Text(
            'Boshqa',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Maxfiylik siyosati',
            onTap: () {},
          ),
          SizedBox(height: 8.h),
          _buildSettingItem(
            icon: Icons.description_outlined,
            title: 'Foydalanish shartlari',
            onTap: () {},
          ),
          SizedBox(height: 8.h),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'Ilova haqida',
            trailing: 'v1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(String label, String code) {
    final isSelected = _selectedLanguage == code;
    final flagEmoji = code == 'uz'
        ? '🇺🇿'
        : code == 'ru'
        ? '🇷🇺'
        : '🇬🇧';

    return InkWell(
      onTap: () {
        setState(() => _selectedLanguage = code);
        // TODO: Implement language change
      },
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(flagEmoji, style: TextStyle(fontSize: 24.sp)),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 18.sp),
              )
            else
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 2),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 18.sp, height: 18.sp),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      trailing,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: 16.sp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
