import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../navigation/main_navigation.dart';

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
        path: "/register",
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: "/home",
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: "/profile",
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
