import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/config/env.dart';
import 'staff_queue_screen.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Auth: form-encoded login
      final authResp = await http.post(
        Uri.parse('${Env.baseUrl}/api/v1/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'username=${Uri.encodeComponent(_emailCtrl.text.trim())}'
              '&password=${Uri.encodeComponent(_passwordCtrl.text)}',
      );

      if (authResp.statusCode != 200) {
        throw Exception('Credenciales incorrectas.');
      }

      final authData = jsonDecode(authResp.body);
      final token = authData['access_token'] as String;

      // El JWT solo lleva sub+exp; el role está en /auth/me
      final meResp = await http.get(
        Uri.parse('${Env.baseUrl}/api/v1/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (meResp.statusCode != 200) {
        throw Exception('No se pudo verificar el perfil.');
      }
      final me = jsonDecode(meResp.body) as Map<String, dynamic>;
      final role = me['role'] ?? '';
      if (role != 'staff_stand') {
        throw Exception('Esta sesión es exclusiva para staff de stands.');
      }

      await TokenService().saveToken(token);

      // Get assigned stand
      final standResp = await http.get(
        Uri.parse('${Env.baseUrl}/api/v1/stands/staff/mi-stand'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (standResp.statusCode != 200) {
        throw Exception('No tienes un stand asignado. Contacta al organizador.');
      }

      final stand = jsonDecode(standResp.body) as Map<String, dynamic>;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StaffQueueScreen(stand: stand, token: token)),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: AppColors.brandGradient,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 24)],
                  ),
                  child: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 32),
                ),

                const SizedBox(height: 16),
                const Text('Aurae Staff', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 4),
                const Text('Panel de cola virtual', style: TextStyle(color: AppColors.muted, fontSize: 14)),

                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ingresa con las credenciales que te proporcionó el organizador.',
                          style: TextStyle(fontSize: 12, color: AppColors.muted), textAlign: TextAlign.center),

                      const SizedBox(height: 20),

                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Text(_error!, style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                        ),

                      const Text('Correo electrónico',
                          style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'staff@ejemplo.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text('Contraseña',
                          style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        style: const TextStyle(color: AppColors.ink),
                        onSubmitted: (_) => _login(),
                        decoration: const InputDecoration(
                          hintText: 'Tu contraseña temporal',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _loading ? null : AppColors.brandGradient,
                            color: _loading ? AppColors.faint : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Ingresar al panel',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('¿Eres asistente? Ir al login principal',
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
