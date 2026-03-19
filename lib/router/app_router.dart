import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../../navigation/main_navigation.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: "/",
    routes: [
      GoRoute(
        path: "/",
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: "/login",
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: "/home",
        builder: (context, state) => const Scaffold(
        body: Center(child: Text("Home Screen")),
        ),
      ),
      GoRoute(
        path: "/register",
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: "/profile",
        builder: (context, state) =>
            const ProfileScreen(),
      ),
  
      GoRoute(
        path: "/edit-profile",
        builder: (context, state) =>
            const EditProfileScreen(),
      ),
    ],
  );
}