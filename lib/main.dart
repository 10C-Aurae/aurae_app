import 'package:flutter/material.dart';
import 'router/app_router.dart';

void main() {
  runApp(const AuraeApp());
}

class AuraeApp extends StatelessWidget {
  const AuraeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Aurae",
      routerConfig: AppRouter.router,
    );
  }
}