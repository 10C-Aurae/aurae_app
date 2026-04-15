import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../data/auth_service.dart';
import '../../../core/utils/aura_logic.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController     = TextEditingController();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  List<String> selectedInterests = [];

  // IDs en español — deben coincidir con la PWA y el mapa interesAHue
  static const List<Map<String, String>> _interestItems = [
    {'id': 'tecnologia',      'label': 'Tecnología'},
    {'id': 'musica',          'label': 'Música'},
    {'id': 'arte',            'label': 'Arte'},
    {'id': 'gaming',          'label': 'Gaming'},
    {'id': 'negocios',        'label': 'Negocios'},
    {'id': 'gastronomia',     'label': 'Gastronomía'},
    {'id': 'deportes',        'label': 'Deportes'},
    {'id': 'networking',      'label': 'Networking'},
    {'id': 'innovacion',      'label': 'Innovación'},
    {'id': 'sustentabilidad', 'label': 'Sustentabilidad'},
    {'id': 'fotografia',      'label': 'Fotografía'},
    {'id': 'moda',            'label': 'Moda'},
    {'id': 'cine',            'label': 'Cine'},
    {'id': 'viajes',          'label': 'Viajes'},
    {'id': 'bienestar',       'label': 'Bienestar'},
    {'id': 'ciencia',         'label': 'Ciencia'},
    {'id': 'literatura',      'label': 'Literatura'},
    {'id': 'danza',           'label': 'Danza'},
    {'id': 'podcasts',        'label': 'Podcasts'},
    {'id': 'educacion',       'label': 'Educación'},
    {'id': 'finanzas',        'label': 'Finanzas'},
    {'id': 'teatro',          'label': 'Teatro'},
  ];

  Future<void> register() async {
    setState(() => loading = true);
    try {
      await AuthService.register(
        nameController.text,
        emailController.text,
        passwordController.text,
        selectedInterests,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada con éxito')),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear la cuenta')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void _toggle(String interest) {
    setState(() {
      if (selectedInterests.contains(interest)) {
        selectedInterests.remove(interest);
      } else {
        selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Dot texture
          Positioned.fill(child: CustomPaint(painter: _DotTexturePainter())),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Gradient heading
                ShaderMask(
                  shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                  child: const Text(
                    'Únete a Aurae',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 6),
                const Text('Completa tu perfil para empezar',
                    style: TextStyle(color: AppColors.muted, fontSize: 14)),

                const SizedBox(height: 32),

                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.ink),
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const SizedBox(height: 14),

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

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.ink),
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 28),

                const Text('Tus intereses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 5),
                const Text('Elige los que más te representen',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 14),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _interestItems.map((item) {
                    final id = item['id']!;
                    final label = item['label']!;
                    final selected = selectedInterests.contains(id);
                    return GestureDetector(
                      onTap: () => _toggle(id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: selected ? AppColors.brandGradient : null,
                          color: selected ? null : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? Colors.transparent : AppColors.border,
                          ),
                          boxShadow: selected ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.30),
                              blurRadius: 12, offset: const Offset(0, 4),
                            ),
                          ] : [],
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? Colors.white : AppColors.muted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // ── Arquetipo preview ─────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(sizeFactor: animation, child: child),
                  ),
                  child: selectedInterests.isEmpty
                      ? const SizedBox.shrink(key: ValueKey('empty'))
                      : _ArchetypePreview(
                          key: ValueKey(selectedInterests.length),
                          intereses: selectedInterests,
                        ),
                ),

                const SizedBox(height: 12),

                // ── Contador ──────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    selectedInterests.length < 3
                        ? 'Selecciona ${3 - selectedInterests.length} más'
                        : '${selectedInterests.length} seleccionados ✓',
                    key: ValueKey(selectedInterests.length),
                    style: TextStyle(
                      fontSize: 12,
                      color: selectedInterests.length >= 3
                          ? AppColors.primary
                          : AppColors.faint,
                      fontWeight: selectedInterests.length >= 3
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 28),

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
                      onPressed: loading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor:     Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Crear cuenta',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arquetipo preview widget ────────────────────────────────────────────────

class _ArchetypePreview extends StatelessWidget {
  final List<String> intereses;
  const _ArchetypePreview({super.key, required this.intereses});

  @override
  Widget build(BuildContext context) {
    final arch = AuraLogic.inferirArquetipo(intereses);
    final emoji = arch['emoji'] as String;
    final nombre = arch['nombre'] as String;
    final desc = arch['desc'] as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                    children: [
                      const TextSpan(text: 'Tu perfil: '),
                      TextSpan(
                        text: nombre,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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