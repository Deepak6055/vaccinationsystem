import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vaccination_system/pages/ChatPage.dart';
import 'package:vaccination_system/pages/Doctor/DoctorSettingsPage.dart';
import 'package:vaccination_system/pages/Nurse/NurseSettingsPage.dart';
import 'package:vaccination_system/pages/Parent/ParentSettingsPage.dart';
import 'package:vaccination_system/pages/chat_list_page.dart';
import './pages/LoginPage.dart';
import './pages/SignupPage.dart';
import 'pages/Parent/ParentDetailsPage.dart';  
import 'pages/Parent/ParentHomePage.dart';
import 'pages/Admin/AdminHomePage.dart';
import 'pages/Doctor/DoctorHomePage.dart';
import 'pages/Nurse/NurseHomePage.dart';
import 'pages/Doctor/AddDoctorPage.dart';
import 'pages/Nurse/AddNursePage.dart';
import 'pages/Admin/AddVaccinationPage.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 Got background message: [32m${message.notification?.title}[0m");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const VaccinationApp());
}

class VaccinationApp extends StatefulWidget {
  const VaccinationApp({super.key});

  @override
  State<VaccinationApp> createState() => _VaccinationAppState();
}

class _VaccinationAppState extends State<VaccinationApp> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground message: [34m${message.notification?.title}[0m - ${message.notification?.body}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/parent_details': (context) => const ParentDetailsPage(),
        '/parent_home': (context) => const ParentHomePage(),
        '/admin_home': (context) => const AdminHomePage(),
        '/doctor_home': (context) => const DoctorHomePage(),
        '/nurse_home': (context) => const NurseHomePage(),
        '/add_doctor': (context) => const AddDoctorPage(),
        '/add_nurse': (context) => const AddNursePage(),
        '/add_vaccine': (context) => const AddVaccinationPage(),
        '/chat':(context)=> const ChatListPage(),
        '/doctor_settings':(context)=> const DoctorSettingsPage(),
        '/nurse_settings':(context)=> const NurseSettingsPage(),
        '/parent_settings':(context)=> const ParentSettingsPage(),
      },
    );
  }
}
