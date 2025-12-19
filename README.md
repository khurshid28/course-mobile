# Course Platform - Mobile (Flutter)

Online kurs platformasi mobil ilovasi. Flutter, Clean Architecture, BLoC bilan qurilgan.

## Xususiyatlar

✅ Splash screen animatsiya bilan
✅ Phone authentication (+998 prefix)
✅ SMS verification (6 ta raqam, 2 minut timer)
✅ Profil to'ldirish (ism, familiya, jins, viloyat)
✅ Bottom navigation (4 ta tab)
✅ Chiroyli dizayn (Primary color: #3572ED)
✅ Kurslar ro'yxati va detallari
✅ To'lovlar tarixi (Click, Payme, Uzum)
✅ Internet yo'q sahifasi
✅ Responsive dizayn (flutter_screenutil)
✅ Google Fonts (Inter)

## Texnologiyalar

- **Flutter** - UI Framework
- **flutter_bloc** - State management
- **dio** - HTTP client
- **flutter_screenutil** - Responsive design
- **google_fonts** - Custom fonts
- **pinput** - PIN input
- **shared_preferences** - Local storage
- **connectivity_plus** - Network checking

## O'rnatish

### 1. Dependencies o'rnatish
```bash
flutter pub get
```

### 2. Ishga tushirish

```bash
# Android
flutter run

# iOS
flutter run

# Web (test uchun)
flutter run -d chrome
```

## Loyiha Strukturasi (Clean Architecture)

```
lib/
├── core/
│   ├── constants/        # Konstantalar
│   ├── theme/           # Ranglar, tema
│   └── widgets/         # Umumiy widgetlar
├── features/
│   ├── splash/          # Splash screen
│   ├── auth/            # Authentication
│   │   ├── data/
│   │   │   └── models/
│   │   └── presentation/
│   │       └── pages/
│   └── home/            # Home va boshqa sahifalar
│       └── presentation/
│           └── pages/
└── main.dart            # Entry point
```

## Ekranlar

### 1. Splash Screen
- Animatsiyali logo
- 3 soniya kutish
- Token tekshirish (keyinroq)

### 2. Register Page
- Telefon raqam kiritish
- +998 prefix avtomatik
- 9 ta raqam kiritish

### 3. Verify Code Page
- 6 xonali PIN input (pinput)
- 2 minut timer (120 sekund)
- Test kod: **666666**
- Qayta yuborish funksiyasi

### 4. Complete Profile Page
- Ism, Familiya (majburiy)
- Email (ixtiyoriy)
- Jins (Erkak/Ayol)
- Viloyat (14 ta viloyat)

### 5. Main Page (Bottom Navigation)
- **Bosh sahifa**: Kurslar, kategoriyalar, banner
- **Kurslar**: Sotib olingan kurslar
- **To'lovlar**: To'lovlar tarixi
- **Profil**: User ma'lumotlari, statistika

## Ranglar

- **Primary**: `#3572ED`
- **Primary Dark**: `#2557CC`
- **Primary Light**: `#5A8DF3`
- **Success**: `#10B981`
- **Error**: `#EF4444`
- **Warning**: `#F59E0B`

## Test Ma'lumotlari

- **Telefon**: Istalgan +998 XX XXX XX XX
- **SMS kod**: `666666`
- **Backend URL**: `http://localhost:3000`

## Backend bilan bog'lash

`lib/core/constants/app_constants.dart` faylida:
```dart
static const String baseUrl = 'http://localhost:3000';
```

Android emulator uchun:
```dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

Haqiqiy qurilma uchun:
```dart
static const String baseUrl = 'http://192.168.1.X:3000';
```

## Keyingi Qadamlar

TODO:
- [ ] API integration (Dio + Retrofit)
- [ ] BLoC implementation
- [ ] SharedPreferences (token saqlash)
- [ ] Image/Video picker
- [ ] Video player
- [ ] Push notifications
- [ ] Deep linking
- [ ] Analytics

## Rasmlar va SVG

`assets/` papkasiga logo va boshqa rasmlarni qo'shing:
```
assets/
├── images/
├── icons/
└── logos/
```

SVG ikonkalar: https://www.svgrepo.com/
