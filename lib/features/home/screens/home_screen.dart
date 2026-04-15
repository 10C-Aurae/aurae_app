import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/aura_logic.dart';
import '../../profile/data/profile_service.dart';
import '../../profile/models/user_profile.dart';
import '../widgets/aura_display.dart';
import '../widgets/next_stop_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final token = await TokenService().getToken();
    if (token == null) { setState(() => loading = false); return; }
    try {
      final result = await ProfileService().getMyProfile(token);
      setState(() { profile = result; loading = false; });
    } catch (e) {
      print('HOME ERROR: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: Text('Error cargando datos', style: TextStyle(color: AppColors.muted))),
      );
    }

    final auraColor = AuraLogic.calcularColorAura(profile!.intereses, profile!.auraNivel);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header App Bar ─────────────────────────────
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: AppColors.nav,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                child: const Text('Aurae', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.muted),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(height: 0.5, color: AppColors.border),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Aura orb ────────────────────────────────
                  AuraDisplay(auraColor: auraColor, nombre: profile!.nombre),

                  const SizedBox(height: 28),

                  // ── Stats Row ────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Nivel', value: '${profile!.auraNivel}')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: 'Puntos', value: '${profile!.auraPuntos}')),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Next stop ────────────────────────────────
                  const NextStopCard(),

                  const SizedBox(height: 20),

                  // ── Quick-action label ───────────────────────
                  const Text('Accesos rápidos',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 12),

                  // ── Quick-action row ─────────────────────────
                  Row(
                    children: [
                      Expanded(child: _QuickLink(icon: Icons.qr_code_rounded, label: 'Mi QR')),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickLink(icon: Icons.event_rounded, label: 'Eventos')),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickLink(icon: Icons.map_rounded, label: 'Mapa')),
                    ],
                  ),

                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ── Quick Link ──────────────────────────────────────────
class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickLink({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}