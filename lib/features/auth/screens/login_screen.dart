import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../data/auth_service.dart';
import '../../../navigation/main_navigation.dart';
import 'register_screen.dart';
import '../../../core/auth/token_service.dart';
import '../../staff/screens/staff_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() { loading = true; error = null; });
    try {
      final token = await AuthService.login(
        emailController.text,
        passwordController.text,
      );
      await TokenService().saveToken(token);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } catch (e) {
      setState(() { error = 'Credenciales incorrectas'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Dot texture background
          Positioned.fill(
            child: CustomPaint(painter: _DotTexturePainter()),
          ),
          // Gradient glow top
          Positioned(
            top: -120, left: -80,
            child: Container(
              width: 360, height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            top: -60, right: -100,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.secondary.withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Logo glow
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.card,
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 40, spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome, size: 42, color: AppColors.primary),
                    ),

                    const SizedBox(height: 20),

                    // Title gradient text
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.brandGradient.createShader(bounds),
                      child: const Text(
                        'Aurae',
                        style: TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Discover your digital aura',
                      style: TextStyle(color: AppColors.muted, fontSize: 15),
                    ),

                    const SizedBox(height: 44),

                    // Email
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Password
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.30)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(error!, style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Primary gradient button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: loading ? null : AppColors.brandGradient,
                          color: loading ? AppColors.faint : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: loading ? [] : [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 20, offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: loading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor:     Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: loading
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Iniciar sesión',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: RichText(
                        text: const TextSpan(children: [
                          TextSpan(text: '¿No tienes cuenta? ', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                          TextSpan(text: 'Regístrate', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                        ]),
                      ),
                    ),

                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
                      ),
                      child: RichText(
                        text: const TextSpan(children: [
                          TextSpan(text: '¿Staff de un stand? ', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          TextSpan(text: 'Ingresa aquí', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot texture Painter ─────────────────────────────────
class _DotTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..style = PaintingStyle.fill;
    const step = 18.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}