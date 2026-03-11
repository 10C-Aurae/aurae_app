import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(const AuraeApp());
}

class AuraeApp extends StatelessWidget {

  const AuraeApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: "Aurae",

      theme: AppTheme.theme,

      home: const LoginScreen(),

    );

  }
}