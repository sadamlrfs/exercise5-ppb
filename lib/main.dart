import 'package:crud_local_database_app/pages/login_page.dart';
import 'package:crud_local_database_app/pages/notes_page.dart';
import 'package:crud_local_database_app/pages/register_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: 'login',
      routes: {
        'home': (context) => const NotesPage(),
        'login': (context) => const LoginPage(),
        'register': (context) => const RegisterPage(),
      },
    );
  }
}
