import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/utils/aura_logic.dart';
import '../../../core/utils/color_utils.dart';
import '../../profile/data/profile_service.dart';
import '../../profile/models/user_profile.dart';
import '../../tickets/data/ticket_service.dart';
import '../../tickets/models/ticket.dart';
import '../../notifications/widgets/notification_bell.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  UserProfile? _profile;
  List<Ticket> _tickets = [];
  bool _loading = true;
  String? _error;

  // Aura level breakpoints mirrored from PWA
  static const List<Map<String, dynamic>> _niveles = [
    {'nivel': 1, 'nombre': 'Semilla',     'min': 0,    'max': 99},
    {'nivel': 2, 'nombre': 'Chispa',      'min': 100,  'max': 299},
    {'nivel': 3, 'nombre': 'Llama',       'min': 300,  'max': 599},
    {'nivel': 4, 'nombre': 'Resplandor',  'min': 600,  'max': 999},
    {'nivel': 5, 'nombre': 'Radiante',    'min': 1000, 'max': 1999},
    {'nivel': 6, 'nombre': 'Luminoso',    'min': 2000, 'max': 4999},
    {'nivel': 7, 'nombre': 'Estelar',     'min': 5000, 'max': 9999},
    {'nivel': 8, 'nombre': 'Cósmico',     'min': 10000, 'max': 99999},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await TokenService().getToken();
      if (token == null) throw Exception('Sin sesión');
      final profile = await ProfileService().getMyProfile(token);
      final tickets = await TicketService.getMyTickets(profile.id);
      if (mounted) setState(() {
        _profile = profile;
        _tickets = tickets.where((t) => t.statusUso == 'usado').toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.nav,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: ShaderMask(
              shaderCallback: (b) => AppColors.brandGradient.createShader(b),
              child: const Text('Mi Aura',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: AppColors.border),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.muted),
                onPressed: _load,
              ),
              const NotificationBell(),
            ],
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
                  ],
                ),
              ),
            )
          else if (_profile != null)
            _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    final auraColor = AuraLogic.calcularColorAura(p.intereses, p.auraNivel);
    final puntos = p.auraPuntos;

    // Find current level
    final currentLevel = _niveles.lastWhere(
      (n) => puntos >= (n['min'] as int),
      orElse: () => _niveles.first,
    );
    final nextLevel = _niveles.firstWhere(
      (n) => (n['min'] as int) > puntos,
      orElse: () => _niveles.last,
    );
    final progress = puntos >= (nextLevel['min'] as int)
        ? 1.0
        : (puntos - (currentLevel['min'] as int)) /
          ((nextLevel['min'] as int) - (currentLevel['min'] as int)).toDouble();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([

          // ── Hero orb ──────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      auraColor.withOpacity(0.9),
                      auraColor.withOpacity(0.3),
                      Colors.transparent,
                    ]),
                    boxShadow: [BoxShadow(color: auraColor.withOpacity(0.5), blurRadius: 40, spreadRadius: 8)],
                  ),
                  child: Center(
                    child: Text(
                      '✦',
                      style: TextStyle(fontSize: 42, color: Colors.white.withOpacity(0.9)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('${puntos.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} pts',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(currentLevel['nombre'] as String,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: auraColor)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Progress bar ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nivel ${currentLevel['nivel']}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    Text(puntos >= (nextLevel['min'] as int)
                        ? 'Nivel máximo'
                        : '${(nextLevel['min'] as int) - puntos} pts para Nivel ${nextLevel['nivel']}',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation(auraColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Level progression table ───────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progresión de niveles',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
                const SizedBox(height: 12),
                ..._niveles.map((n) {
                  final isActive = currentLevel['nivel'] == n['nivel'];
                  final reached = puntos >= (n['min'] as int);
                  final levelColor = _levelColor(n['nivel'] as int);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? AppColors.primary.withOpacity(0.25) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: levelColor,
                            boxShadow: isActive ? [BoxShadow(color: levelColor.withOpacity(0.6), blurRadius: 6)] : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            n['nombre'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: reached ? AppColors.ink : AppColors.faint,
                            ),
                          ),
                        ),
                        Text('${(n['min'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} pts',
                            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        const SizedBox(width: 8),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Actual',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          )
                        else if (reached)
                          const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green)
                        else
                          Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── QR ticket history ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Tickets escaneados',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_tickets.isEmpty)
                  const Text('Aún no has usado ningún ticket en un evento.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13))
                else
                  ..._tickets.take(8).map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.tipo.isEmpty ? 'General' : t.tipo,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                      color: AppColors.ink)),
                              Text('Evento · ${t.eventoId.length > 8 ? t.eventoId.substring(t.eventoId.length - 8) : t.eventoId}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.faint)),
                            ],
                          ),
                        ),
                        if (t.fechaUso != null)
                          Text(
                            _formatDate(t.fechaUso!),
                            style: const TextStyle(fontSize: 10, color: AppColors.muted),
                          ),
                      ],
                    ),
                  )),
              ],
            ),
          ),

          // ── Interests ─────────────────────────────────────────
          if (p.intereses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tus intereses',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: p.intereses.map((i) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(i, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Color _levelColor(int level) {
    const colors = [
      Color(0xFF8B7355), // Semilla — earth
      Color(0xFFFFD700), // Chispa — yellow
      Color(0xFFFF6B35), // Llama — orange
      Color(0xFF9B5DE5), // Resplandor — purple
      Color(0xFF00D4FF), // Radiante — cyan
      Color(0xFF00FF88), // Luminoso — green
      Color(0xFFFF5C5C), // Estelar — coral
      Color(0xFFFFFFFF), // Cósmico — white
    ];
    return colors[(level - 1).clamp(0, colors.length - 1)];
  }

  String _formatDate(DateTime dt) {
    const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
