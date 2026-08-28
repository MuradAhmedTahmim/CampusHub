# 🎓 CampusHub

**CampusHub** is a Flutter-based university campus management application designed to bring essential academic and campus-related services into a single platform.

The application provides separate role-based experiences for **Students** and **Faculty Members**, with features including authentication, course management, assignments, attendance, grading, CGPA tracking, notices, fee calculation, payment records, and PDF receipt generation.

---

## 📱 Overview

CampusHub is designed to simplify common university activities by providing students and faculty members with a centralized digital platform.

The application supports:

* 👨‍🎓 Student management and academic services
* 👨‍🏫 Faculty academic management
* 🔐 Firebase Authentication
* 📧 Email OTP verification using EmailJS API
* 🔥 Firebase Realtime Database
* 📚 Course and enrollment management
* 📝 Assignment management
* 📊 Attendance and grading
* 🎓 CGPA calculation
* 📢 Notice management
* 💳 Fee calculation and demo payment flow
* 🧾 Payment history and PDF receipt generation

---

## ✨ Features

### 🔐 Authentication

CampusHub uses **Firebase Authentication** for account authentication and **EmailJS API** for OTP-based email verification during registration.

Features include:

* User registration
* Email and password login
* Student/Faculty role selection
* Email OTP verification during registration
* Duplicate email checking
* Duplicate phone number checking
* Forgot password functionality
* Persistent login session

---

## 👨‍🎓 Student Features

### 📚 Course Management

Students can:

* View available courses
* View course information
* Access enrolled courses

### 📝 Assignments

Students can:

* View assignments
* View assignment details
* Submit assignments

### 📊 Attendance

Students can:

* View attendance records
* Track attendance information

### 🎓 CGPA

Students can:

* View academic grades
* Calculate CGPA
* Track academic performance

### 📢 Notices

Students can:

* View academic notices
* Stay updated with important announcements

### 💳 Fee Management

Students can:

* Calculate semester fees
* View enrolled credits
* Apply/view waiver information
* View net payable amount
* Use the demo payment flow
* Verify payment using email OTP

### 🧾 Payment History

Students can:

* View previous payment records
* View transaction information
* View total paid amount
* Generate payment receipts as PDF
* Print payment receipts

### 👤 Profile

Students can:

* View their profile
* Access personal and academic information

---

## 👨‍🏫 Faculty Features

### 📚 Course Management

Faculty members can:

* Create courses
* Manage courses
* View courses assigned to them

### 📝 Assignment Management

Faculty members can:

* Create assignments
* Manage assignment information
* View student submissions

### 🗓️ Attendance Management

Faculty members can:

* Mark student attendance
* Manage attendance records

### 📊 Grade Management

Faculty members can:

* Manage student grades
* Update academic results

### 📢 Notice Management

Faculty members can:

* Create notices
* Publish academic announcements

### 👤 Faculty Dashboard

The faculty dashboard provides centralized access to academic management features including courses, assignments, attendance, grades, and notices.

---

## 🛠️ Tech Stack

| Technology                     | Purpose                                       |
| ------------------------------ | --------------------------------------------- |
| **Flutter**                    | Cross-platform application development        |
| **Dart**                       | Programming language                          |
| **Firebase Authentication**    | User authentication and account management    |
| **Firebase Realtime Database** | Real-time data storage and synchronization    |
| **EmailJS API**                | Email OTP delivery                            |
| **HTTP**                       | API requests, including EmailJS communication |
| **Google Fonts**               | Application typography and UI styling         |

---

## 🔥 Firebase Integration

CampusHub uses Firebase as an important part of its application infrastructure.

### Firebase Authentication

Firebase Authentication is used for:

* User registration
* Email/password login
* Password reset
* User identity management
* Persistent authentication sessions

### Firebase Realtime Database

Realtime Database is used to store application data including:

* User profiles
* Student information
* Faculty information
* Courses
* Enrollments
* Assignments
* Assignment submissions
* Attendance
* Grades
* Notices
* Payments
* Payment history

---

## 📧 Email OTP Verification

CampusHub uses the **EmailJS API** to send OTP codes through email.

The registration flow works approximately as follows:

```text
User enters registration information
              ↓
Input validation
              ↓
Duplicate email/phone check
              ↓
Generate OTP
              ↓
EmailJS API sends OTP
              ↓
User enters OTP
              ↓
OTP verification
              ↓
Firebase Authentication account creation
              ↓
User profile stored in Firebase Realtime Database
```

OTP verification is also used in the fee payment flow.

> **Security Note:** Do not expose sensitive private credentials or secrets in a public repository.

---

## 💳 Fee & Demo Payment

CampusHub includes a fee calculation and **demo payment workflow**.

Students can:

- View their semester fee information
- Calculate payable fees
- View applicable waiver information
- Select a payment method
- Complete a simulated payment process
- View payment records

> **Note:** The current payment system is a demonstration/prototype and does not process real financial transactions.

---

## 🏗️ Project Structure

```text
CampusHub/
│
├── android/
├── ios/
├── web/
├── windows/
│
├── lib/
│   │
│   ├── models/
│   │
│   ├── screens/
│   │   │
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   │
│   │   ├── faculty/
│   │   │   ├── assignment_submissions_screen.dart
│   │   │   ├── create_assignment_screen.dart
│   │   │   ├── create_notice_screen.dart
│   │   │   ├── faculty_home.dart
│   │   │   ├── grade_management_screen.dart
│   │   │   ├── manage_course_screen.dart
│   │   │   └── mark_attendance_screen.dart
│   │   │
│   │   ├── student/
│   │   │   ├── assignment_screen.dart
│   │   │   ├── attendance_screen.dart
│   │   │   ├── cgpa_screen.dart
│   │   │   ├── course_list_screen.dart
│   │   │   ├── fee_payment_screen.dart
│   │   │   ├── notice_screen.dart
│   │   │   ├── payment_history_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── student_home.dart
│   │   │
│   │   └── landing_screen.dart
│   │
│   ├── services/
│   │   ├── assignment_service.dart
│   │   ├── attendance_service.dart
│   │   ├── auth_service.dart
│   │   ├── cgpa_service.dart
│   │   ├── course_service.dart
│   │   └── notice_service.dart
│   │
│   ├── widgets/
│   ├── firebase_options.dart
│   └── main.dart
│
├── test/
├── pubspec.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

* Flutter SDK
* Dart SDK
* Android Studio or another Flutter-supported IDE
* Android SDK
* A Firebase project
* An EmailJS account configured for email delivery

Check your Flutter environment with:

```bash
flutter doctor
```

---

## 📥 Installation

Clone the repository:

```bash
git clone https://github.com/MuradAhmedTahmim/CampusHub.git
```

Navigate to the project directory:

```bash
cd CampusHub
```

Install dependencies:

```bash
flutter pub get
```

---

## 🔥 Firebase Configuration

To configure CampusHub with your own Firebase project:

1. Create a project in Firebase Console.
2. Add the required Flutter platforms.
3. Enable **Email/Password Authentication**.
4. Enable **Firebase Realtime Database**.
5. Configure the database according to the application's data structure.
6. Configure Firebase for the Flutter project.
7. Make sure the required Firebase configuration files are available for the target platform.

> **Important:** Never upload private Firebase service-account credentials or other sensitive secrets to a public repository.

---

## 📧 EmailJS Configuration

To configure email OTP functionality:

1. Create an EmailJS account.
2. Configure an email service.
3. Create an email template for OTP delivery.
4. Configure the required EmailJS identifiers.
5. Test OTP delivery before using the application.

The application sends OTP requests to the EmailJS API through HTTP requests.

> **Security Note:** Review your EmailJS public configuration and avoid exposing any private credentials or secrets.

---

## ▶️ Run the Application

Check available Flutter devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

For Chrome/Web:

```bash
flutter run -d chrome
```

---

## 🌐 Build for Web

To create a production web build:

```bash
flutter build web
```

The generated files will be available in:

```text
build/web/
```

The web build can then be deployed to a compatible hosting service such as Firebase Hosting.


## 🎯 Project Goals

The main goals of CampusHub are to:

* Digitize common academic activities
* Reduce manual academic management
* Centralize student and faculty services
* Simplify course management
* Improve assignment management
* Simplify attendance and grading
* Provide academic performance tracking
* Improve communication through notices
* Provide convenient fee calculation and payment records
* Provide downloadable/printable payment receipts

---

## 🔮 Future Improvements

Potential future improvements include:

* 🔔 Push notifications
* 💬 Student–faculty messaging
* 📅 Class routine management
* 📆 Academic calendar
* 🧑‍💼 Dedicated administrator dashboard
* 📈 Advanced academic analytics
* 📄 Digital document management
* 💳 Production-ready payment gateway integration
* 🔒 Enhanced security and access control
* 🌐 Production web deployment
* 📱 Further platform-specific optimization

---

## 👨‍💻 Developer

### Murad Ahmed Tahmim

**Computer Science & Engineering**

GitHub:
https://github.com/MuradAhmedTahmim

---

## 📄 License

This project is developed for educational and academic purposes.

---

## ⭐ Support

If you find this project useful or interesting, consider giving the repository a ⭐ on GitHub.

---

<div align="center">

### 🎓 CampusHub

**Connecting Students, Faculty & Campus Services in One Place.**

</div>
