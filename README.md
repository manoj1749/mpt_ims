# MPT IMS - Inventory Management System

A comprehensive Flutter-based Inventory Management System designed for manufacturing and business operations. This application provides modules for managing accounts, HR, sales, design, planning, purchasing, stores, production, and quality control.

## 🚀 Features

### Core Modules
- **Admin** - Administrative functions and system management
- **Accounts** - Financial management including invoice receipts, supplier/customer masters, bank statements, expenses, payments, salary & wages, sales entries, and GST management
- **HR** - Employee details, attendance management, ESI & PF entry
- **Sales/Customer Management** - Sale order details, customer free issue lists, sale value updates
- **Design** - Material master creation, brought lists, category settings
- **Planning** - Bill of Material preparation, PR creation, job order requests
- **Purchase** - Purchase order creation and management
- **Stores** - GR, material requests, material issues, stock maintenance, delivery challans, vendor delivery challans, invoice generation
- **Production** - Job order entry, assembly work allocation
- **Quality** - Incoming inspection, category settings, final inspection, CAPA status

### Technical Features
- **Firebase Authentication** - Secure user login and registration
- **Cloud Firestore** - Real-time database synchronization
- **Local Storage** - Hive database for offline functionality
- **Responsive Design** - Works on desktop, tablet, and mobile devices
- **PDF Generation** - Export reports and documents
- **CSV Import/Export** - Bulk data operations
- **Real-time Sync** - Online/offline synchronization

## 📋 Prerequisites

Before setting up the application, ensure you have the following installed:

### Required Software
- **Flutter SDK** (>=3.0.0 <4.0.0)
- **Dart SDK** (included with Flutter)
- **Git** for version control
- **Firebase CLI** (for Firebase configuration)

### Platform-specific Requirements

#### For macOS Development:
- **Xcode** (latest version)
- **CocoaPods** (`sudo gem install cocoapods`)

#### For Windows Development:
- **Visual Studio** with C++ development tools
- **Windows 10 SDK**

## 🛠️ Installation & Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd mpt_ims
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

This application uses Firebase for authentication and data storage. The Firebase configuration is already included, but you may need to set up your own Firebase project for production use.

#### Current Firebase Configuration:
- Project ID: `mpts-ims`
- Supported platforms: macOS, Windows

#### To use your own Firebase project:
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Enable Cloud Firestore
4. Install Firebase CLI: `npm install -g firebase-tools`
5. Login to Firebase: `firebase login`
6. Configure for your project: `firebase use --add`
7. Generate new configuration: `flutterfire configure`

### 4. Generate Hive Type Adapters
```bash
flutter packages pub run build_runner build
```

### 5. Platform-specific Setup

#### macOS Setup:
```bash
cd macos
pod install
cd ..
```

#### Windows Setup:
No additional setup required for basic functionality.

## 🚀 Running the Application

### Development Mode

#### Run on macOS:
```bash
flutter run -d macos
```

#### Run on Windows:
```bash
flutter run -d windows
```

### Production Build

#### macOS Build:
```bash
flutter build macos
```
The build output will be in the `build/macos` directory.

#### Windows Build:
```bash
flutter build windows
```
The build output will be in the `build/windows` directory.

## 📱 First Time Setup

1. **Launch the Application**
   - The app will start with a login screen
   - You can either sign in with existing credentials or create a new account

2. **Create Admin Account**
   - Use the sign-up option to create the first admin account
   - This account will have full access to all modules

3. **Initial Data Setup**
   - Navigate to the Design module to set up material categories
   - Add suppliers and customers in the Accounts module
   - Set up employee details in the HR module

## 🗂️ Data Storage

### Local Storage (Hive)
The application creates a local database structure:
- **Location**: `Documents/MPT_IMS/Database/`
- **Purpose**: Offline functionality and local caching
- **Data**: All application data is stored locally and synced with Firebase

### Cloud Storage (Firebase)
- **Authentication**: User accounts and sessions
- **Firestore**: Real-time database for all business data
- **Automatic Sync**: Data synchronizes between local and cloud storage

## 🔧 Configuration

### Application Settings
- **Theme**: Dark theme with custom color scheme
- **Responsive**: Automatically adapts to screen size
- **Language**: English (internationalization ready)

### Firebase Configuration
The application is pre-configured with Firebase settings in `lib/firebase_options.dart`. For production use, update these with your own Firebase project credentials.

## 📊 Usage Guide

### Navigation
- **Sidebar Menu**: Access different modules (Accounts, HR, Sales, etc.)
- **Section Pages**: Each module contains specific functionality pages
- **Data Grids**: Most data is displayed in sortable, filterable tables

### Common Operations
1. **Adding Data**: Use the floating action button (+) on list pages
2. **Editing**: Click on rows in data grids to edit entries
3. **Searching**: Use search functionality available in most modules
4. **Exporting**: Export data to CSV format where available
5. **Bulk Operations**: Import data using CSV files

## 🛡️ Security

- **Firebase Authentication**: Secure user management
- **Data Validation**: Input validation on all forms
- **Access Control**: Module-based access (ready for role-based permissions)
- **Secure Storage**: Encrypted local storage using Hive

## 🐛 Troubleshooting

### Common Issues

#### Build Errors:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### Firebase Connection Issues:
- Check internet connectivity
- Verify Firebase project configuration
- Ensure Firebase services are enabled

#### Local Database Issues:
- Delete local database: `Documents/MPT_IMS/Database/`
- Restart application to regenerate

#### Platform-specific Issues:

**macOS:**
```bash
cd macos && pod install && cd ..
flutter clean && flutter run
```

**Windows:**
- Ensure Visual Studio C++ tools are installed
- Run as administrator if permission issues occur

## 📝 Development

### Project Structure
```
lib/
├── db/                 # Hive database initialization
├── layout/             # App scaffold and navigation
├── models/             # Data models and Hive adapters
├── pages/              # UI pages organized by modules
├── provider/           # Riverpod state management
├── services/           # Firebase and other services
└── widgets/            # Reusable UI components
```

### Adding New Features
1. Create model classes in `lib/models/`
2. Generate Hive adapters with `build_runner`
3. Create provider classes in `lib/provider/`
4. Add UI pages in appropriate `lib/pages/` subdirectory
5. Update navigation in `lib/layout/app_scaffold.dart`

### State Management
- **Riverpod**: Primary state management solution
- **Hive Boxes**: Local data persistence
- **Firebase**: Remote data synchronization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on multiple platforms
5. Submit a pull request

## 📄 License

This project is private and proprietary. All rights reserved.

## 📞 Support

For technical support or questions:
- Check the troubleshooting section above
- Review Flutter documentation: [flutter.dev](https://flutter.dev)
- Firebase documentation: [firebase.google.com](https://firebase.google.com)

---

**Note**: This application requires an active internet connection for initial setup and data synchronization. Once set up, many features work offline with automatic sync when connection is restored.