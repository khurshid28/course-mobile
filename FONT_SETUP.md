# Font Konfiguratsiyasi

## ✅ Hozirgi holat
Loyihada **Poppins** fonti Google Fonts orqali ishlatilmoqda. Bu font avtomatik ravishda barcha text'larga qo'llaniladi.

## 🎨 Font o'zgartirish

### Usul 1: Google Fonts ishlatish (tavsiya etiladi)
Google Fonts 1000+ dan ortiq bepul font taqdim etadi:

```dart
// lib/core/theme/app_theme.dart
textTheme: GoogleFonts.nunitoTextTheme(),  // Nunito font
fontFamily: GoogleFonts.nunito().fontFamily,
```

**Mashhur fontlar:**
- `poppins` - hozirgi (zamonaviy, keng qo'llaniladi)
- `nunito` - yumshoq va o'qish uchun qulay
- `rubik` - zamonaviy, professional
- `inter` - texnik, minimal
- `roboto` - Android standart
- `openSans` - klassik, professional
- `montserrat` - zamonaviy, geometric
- `lato` - elegant va o'qish uchun qulay

### Usul 2: Custom font faylini qo'shish

1. **Font fayllarini yuklab oling** (.ttf yoki .otf format)
   - [Google Fonts](https://fonts.google.com/) - bepul fontlar
   - [Font Squirrel](https://www.fontsquirrel.com/) - bepul kommersial fontlar
   - [DaFont](https://www.dafont.com/) - turli xil fontlar

2. **Font fayllarini loyihaga qo'shing:**
   ```
   course_mobile/
   └── assets/
       └── fonts/
           ├── MyFont-Regular.ttf
           ├── MyFont-Bold.ttf
           ├── MyFont-Italic.ttf
           └── MyFont-BoldItalic.ttf
   ```

3. **pubspec.yaml'ga qo'shing:**
   ```yaml
   flutter:
     fonts:
       - family: MyFont
         fonts:
           - asset: assets/fonts/MyFont-Regular.ttf
           - asset: assets/fonts/MyFont-Bold.ttf
             weight: 700
           - asset: assets/fonts/MyFont-Italic.ttf
             style: italic
   ```

4. **Theme'da ishlatish:**
   ```dart
   // lib/core/theme/app_theme.dart
   ThemeData(
     fontFamily: 'MyFont',
     textTheme: const TextTheme(
       displayLarge: TextStyle(fontFamily: 'MyFont'),
       // ... boshqalar
     ),
   )
   ```

## 🔧 Joriy konfiguratsiya

Fayl: `lib/core/theme/app_theme.dart`

```dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      textTheme: GoogleFonts.poppinsTextTheme(),
      fontFamily: GoogleFonts.poppins().fontFamily,
      appBarTheme: AppBarTheme(
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      // ... boshqa theme sozlamalari
    );
  }
}
```

## 📱 Back Button (AppBar)

AppBar'dagi back button avtomatik ravishda Flutter tomonidan qo'shiladi:
- `Navigator.push()` ishlatilganda avtomatik paydo bo'ladi
- Theme'dagi `iconTheme` orqali rangi va o'lchami boshqariladi
- Barcha screen'larda bir xil ko'rinadi

**Sozlash:**
```dart
appBarTheme: AppBarTheme(
  iconTheme: const IconThemeData(
    color: AppColors.textPrimary,  // Rang
    size: 24,                       // O'lcham
  ),
),
```

## 🚀 Font o'zgartirish bo'yicha qadamlar

1. **app_theme.dart** faylini oching
2. `poppins` o'rniga boshqa font nomini yozing:
   ```dart
   GoogleFonts.nunitoTextTheme()  // yoki rubik, inter, montserrat
   ```
3. Hot restart qiling: `flutter run` yoki VS Code'da `r` tugmasini bosing
4. O'zgarishlar darhol ko'rinadi!

## 💡 Maslahatlar

- **O'zbek tili uchun:** Poppins, Nunito, Rubik, Montserrat yaxshi ishlaydi
- **Performance:** Google Fonts avtomatik cache qiladi, tezlik muammosi yo'q
- **Custom font:** Faqat maxsus dizayn kerak bo'lsa ishlatiladi
- **Weight:** FontWeight.w400 (regular), w500 (medium), w600 (semibold), w700 (bold)

## 🔍 Hozirgi holatni tekshirish

```bash
# Flutter doctor
flutter doctor

# Package'larni yangilash
flutter pub get

# Ilovani ishga tushirish
flutter run
```
