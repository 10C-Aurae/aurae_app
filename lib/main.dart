import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/foundation.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'core/config/env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    Stripe.publishableKey = Env.stripePublishableKey;
  }
  runApp(const ProviderScope(child: AuraeApp()));
}

class AuraeApp extends StatelessWidget {
  const AuraeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Aurae',
      theme: AppTheme.theme,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
