# G-PSF Monitoring System (G-PSF MIS) Mobile App

A modern, multi-module Flutter mobile application for the Government-Private Sector Forum (G-PSF) Monitoring and Information System (MIS) in Cambodia.

---

## 🔑 Demo Accounts for Login (គណនីគំរូសម្រាប់ចូលប្រើប្រាស់)

All accounts share the same default password: **`12345678`**

| Module / ផ្នែក | Email (Gmail) | Password | Description / ការពិពណ៌នា |
| :--- | :--- | :--- | :--- |
| **Line Ministry (ក្រសួងស្ថាប័ន)** | `ministry@gmail.com` | `12345678` | Line Ministry portal for managing issues, meeting requests, and progress reports. |
| **Private Sector (វិស័យឯកជន)** | `privatesector@gmail.com` | `12345678` | Private Sector Working Group portal for submitting and tracking issues. |
| **CDC Section** | `cdc@gmail.com` | `12345678` | Council for the Development of Cambodia (CDC) section dashboard & reviews. |
| **CDC Secretariat** | `secretariat@gmail.com` | `12345678` | CDC Secretariat coordination and reporting portal. |
| **CEFP** | `cefp@gmail.com` | `12345678` | Committee for Economic and Financial Policy (CEFP) monitoring view. |

> **Note**: You can also log in with any valid custom email address.

---

## ✨ Features (លក្ខណៈពិសេស)

- 🌐 **Multilingual Support (Khmer & English)**: Seamless real-time language switching across all screens and filters.
- 🌙 **Dark Mode & Light Mode**: Complete theme customization supporting System, Light, and Dark modes.
- 📊 **Interactive Dashboard & Reports**: Donut charts, bar charts, and implementation status metrics.
- 📋 **Issue Tracking & Matrix**: View, filter, and track issues by Working Group, Categories, Status, and Primary Agencies.
- 📅 **Meeting & Request Management**: Schedule meetings, track deadlines, view request details, and RGC decisions.
- 🔍 **Comprehensive Filtering**: Dynamic bottom sheets with multi-select chips and toggles.

---

## 🚀 Getting Started (ការចាប់ផ្តើម)

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0.0 or higher)
- [Dart SDK](https://dart.dev/get-started/sdk)
- Android Studio / VS Code with Flutter extensions
- Android Emulator or physical device

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd gpsf_mis
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

---

## 📁 Project Structure (រចនាសម្ព័ន្ធគម្រោង)

```
lib/
├── core/                   # Core configurations, colors, assets, settings
│   ├── app_colors.dart
│   ├── app_settings.dart
│   └── config/
├── features/               # Feature modules
│   ├── line_ministry/      # Line Ministry feature screens & widgets
│   ├── private_sector/     # Private Sector feature screens & widgets
│   ├── cdc_secretariat/    # CDC Secretariat feature screens
│   ├── cdc_section/        # CDC Section feature screens
│   └── cefp/               # CEFP feature screens
├── screens/                # Core shared screens (Auth, Account, Details)
│   ├── account/
│   ├── auth/
│   ├── issues/
│   ├── meeting/
│   └── report/
├── translations/           # App Localizations & Translation maps (EN / KM)
│   ├── app_language.dart
│   ├── app_localizations.dart
│   ├── en.dart
│   └── km.dart
└── main.dart               # Entry point
```

---

## 🛠️ Build & Analysis

To verify code quality and static analysis:
```bash
flutter analyze
```

---

© 2026 G-PSF MIS - Royal Government of Cambodia.
