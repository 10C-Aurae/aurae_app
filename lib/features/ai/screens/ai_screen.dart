import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/utils/aura_logic.dart';
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

  // Colores por nivel — blanco → azul cielo → azul royal → púrpura → dorado → rojo
  static const _nivelColors = [
    Color(0xFFE0E0E0), // Neutro     — gris claro
    Color(0xFF87CEEB), // Despertar  — azul cielo
    Color(0xFF4169E1), // Explorador — azul royal
    Color(0xFF9B5DE5), // Influyente — púrpura
    Color(0xFFFFD700), // Visionario — dorado
    Color(0xFFE6670A), // Legendario — rojo/naranja
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
        _tickets = tickets;
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

    // Usar los niveles reales de AuraLogic (Neutro, Despertar, Explorador…)
    final nivelNombre   = AuraLogic.getNombreNivel(p.auraNivel);
    final siguienteNom  = AuraLogic.nombreSiguienteNivel(p.auraNivel);
    final faltan        = AuraLogic.puntosParaSiguiente(puntos);
    final porcentaje    = AuraLogic.getPorcentajeNivel(puntos);
    final arquetipo     = AuraLogic.inferirArquetipo(p.intereses);

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
                Text(nivelNombre,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: auraColor)),
                const SizedBox(height: 4),
                // Arquetipo badge
                if (p.intereses.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(arquetipo['emoji'] as String, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(arquetipo['nombre'] as String,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
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
                    Text('Nivel ${p.auraNivel} · $nivelNombre',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    Text(siguienteNom == null
                        ? 'Nivel máximo'
                        : 'Faltan $faltan pts para $siguienteNom',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: porcentaje / 100.0,
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
                ...AuraLogic.niveles.map((n) {
                  final isActive = p.auraNivel == n.nivel;
                  final reached  = puntos >= n.min;
                  final lvlColor = _nivelColors[(n.nivel - 1).clamp(0, _nivelColors.length - 1)];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: lvlColor,
                            boxShadow: isActive
                                ? [BoxShadow(color: lvlColor.withValues(alpha: 0.6), blurRadius: 6)]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            n.nombre,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: reached ? AppColors.ink : AppColors.faint,
                            ),
                          ),
                        ),
                        Text('${n.min} pts',
                            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        const SizedBox(width: 8),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
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
                    Icon(Icons.confirmation_number_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Mis tickets',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_tickets.isEmpty)
                  const Text('Aún no tienes tickets.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13))
                else
                  ..._tickets.take(10).map((t) {
                    final isUsed      = t.statusUso == 'usado';
                    final isCancelled = t.statusUso == 'cancelado';
                    final statusColor = isUsed
                        ? Colors.green
                        : isCancelled
                            ? AppColors.faint
                            : AppColors.primary;
                    final statusLabel = isUsed
                        ? 'Usado'
                        : isCancelled
                            ? 'Cancelado'
                            : 'Activo';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isUsed ? Icons.check_circle_rounded
                              : isCancelled ? Icons.cancel_rounded
                              : Icons.qr_code_rounded,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.tipo.isEmpty ? 'General' : _capitalize(t.tipo),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                        color: AppColors.ink)),
                                Text(
                                  t.fechaUso != null
                                      ? 'Usado el ${_formatDate(t.fechaUso!)}'
                                      : 'Creado el ${_parseCreatedAt(t.createdAt)}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.faint),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(statusLabel,
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                    color: statusColor)),
                          ),
                        ],
                      ),
                    );
                  }),
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

  String _formatDate(DateTime dt) {
    const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _parseCreatedAt(dynamic createdAt) {
    try {
      final dt = createdAt is DateTime
          ? createdAt
          : DateTime.parse(createdAt.toString());
      return _formatDate(dt);
    } catch (_) {
      return '—';
    }
  }
}
