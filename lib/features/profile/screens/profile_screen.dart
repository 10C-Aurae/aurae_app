import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/aura_logic.dart';
import '../data/profile_service.dart';
import '../models/user_profile.dart';
import '../models/ble_token.dart';
import '../models/order.dart';
import '../../orders/data/order_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? profile;
  bool loading = true;

  BleToken? bleToken;
  bool bleLoading = false;
  String? bleError;

  List<Order> orders = [];
  bool ordersLoading = false;

  bool deleteConfirm = false;
  bool deleteLoading = false;
  String? deleteError;

  bool snapLoading = false;
  String? snapResult;
  String? snapError;

  Future<void> generarSnapshot() async {
    setState(() { snapLoading = true; snapError = null; });
    try {
      final token = await TokenService().getToken();
      if (token != null && profile != null) {
        final res = await ProfileService().generateAuraSnapshot(token, profile!.id);
        if (mounted) setState(() => snapResult = res);
      }
    } catch (e) {
      if (mounted) setState(() => snapError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => snapLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final token = await TokenService().getToken();
    if (token == null) { setState(() => loading = false); return; }
    try {
      final result = await ProfileService().getMyProfile(token);
      if (!mounted) return;
      setState(() { profile = result; loading = false; });
      _loadExtraData(token, result.id);
    } catch (e) {
      print('PROFILE ERROR: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadExtraData(String token, String userId) async {
    // BLE Token
    setState(() => bleLoading = true);
    try {
      final bToken = await ProfileService().getBleToken(token);
      if (mounted) setState(() => bleToken = bToken);
    } catch (e) {
      if (mounted) setState(() => bleError = "No se pudo cargar el token BLE");
    } finally {
      if (mounted) setState(() => bleLoading = false);
    }

    // Orders
    setState(() => ordersLoading = true);
    try {
      final userOrders = await OrderService.getOrdersByUserId(userId, token);
      if (mounted) setState(() => orders = userOrders);
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => ordersLoading = false);
    }
  }

  Future<void> rotateBle() async {
    setState(() { bleLoading = true; bleError = null; });
    try {
      final token = await TokenService().getToken();
      if (token != null) {
        final bToken = await ProfileService().rotateBleToken(token);
        if (mounted) setState(() => bleToken = bToken);
      }
    } catch (e) {
      if (mounted) setState(() => bleError = "No se pudo rotar el token");
    } finally {
      if (mounted) setState(() => bleLoading = false);
    }
  }

  Future<void> deleteAccount() async {
    if (!deleteConfirm) {
      setState(() => deleteConfirm = true);
      return;
    }
    setState(() { deleteLoading = true; deleteError = null; });
    try {
      final token = await TokenService().getToken();
      if (token != null && profile != null) {
        await ProfileService().deleteAccount(token, profile!.id);
        await TokenService().deleteToken();
        // Redirect to login handled globally or navigate here. Assumed handled globally or restart needed:
        // TODO: Navigator to Auth
      }
    } catch (e) {
      if (mounted) setState(() { deleteError = e.toString().replaceFirst('Exception: ', ''); deleteConfirm = false; });
    } finally {
      if (mounted) setState(() => deleteLoading = false);
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
        body: Center(child: Text('No profile found', style: TextStyle(color: AppColors.muted))),
      );
    }

    final auraColor = AuraLogic.calcularColorAura(profile!.intereses, profile!.auraNivel);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: AppColors.nav,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text('Perfil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile!)),
                  );
                  loadProfile();
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: AppColors.border),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Avatar ────────────────────────────────────
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow ring
                      Container(
                        width: 136, height: 136,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: auraColor.withOpacity(0.5), blurRadius: 60, spreadRadius: 10)],
                        ),
                      ),
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: auraColor.withOpacity(0.5), width: 2.5),
                        ),
                        child: CircleAvatar(
                          radius: 62,
                          backgroundColor: AppColors.card,
                          backgroundImage: profile!.avatarUrl.isNotEmpty ? NetworkImage(profile!.avatarUrl) : null,
                          child: profile!.avatarUrl.isEmpty
                              ? const Icon(Icons.person_rounded, size: 55, color: AppColors.muted) : null,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Center(
                  child: Text(profile!.nombre,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
                Center(
                  child: Text(profile!.email,
                      style: const TextStyle(color: AppColors.muted, fontSize: 14)),
                ),

                if (profile!.arquetipoNombre != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 16),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile!.arquetipoNombre!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              const Text('Tu arquetipo', style: TextStyle(color: AppColors.faint, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Stats card ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _InfoTile('Nivel', '${profile!.auraNivel}')),
                      Container(height: 40, width: 1, color: AppColors.border),
                      Expanded(child: _InfoTile('Puntos', '${profile!.auraPuntos}')),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Interests ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Intereses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      const SizedBox(height: 14),
                      Builder(builder: (context) {
                        final intereses = profile!.intereses ?? [];
                        if (intereses.isEmpty) {
                          return const Text('Sin intereses seleccionados', style: TextStyle(color: AppColors.muted, fontSize: 13));
                        }
                        return Wrap(
                          spacing: 8, runSpacing: 8,
                          children: intereses.map((e) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: auraColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: auraColor.withOpacity(0.25)),
                            ),
                            child: Text(e, style: TextStyle(fontSize: 13, color: auraColor, fontWeight: FontWeight.w500)),
                          )).toList(),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Progresion de Niveles ───────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Progresión de niveles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      const SizedBox(height: 14),
                      Builder(builder: (context) {
                        final niveles = AuraLogic.getNivelesConColor(profile!.intereses ?? []);
                        return Column(
                          children: niveles.map((n) {
                            final bool activo = profile!.auraNivel == n['nivel'];
                            final bool alcanzado = profile!.auraPuntos >= (n['min'] as int);
                            final Color nColor = n['color'] as Color;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: activo ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: activo ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12, height: 12,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: nColor, boxShadow: activo ? [BoxShadow(color: nColor.withValues(alpha: 0.6), blurRadius: 8)] : []),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(n['nombre'], style: TextStyle(fontSize: 13, fontWeight: activo ? FontWeight.w700 : FontWeight.w500, color: activo ? AppColors.ink : (alcanzado ? AppColors.ink : AppColors.faint))),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text('${n['min']} pts', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                      const SizedBox(width: 12),
                                      if (activo)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                          child: const Text('Actual', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        )
                                      else if (alcanzado)
                                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16)
                                      else
                                        Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border, width: 2))),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Historial de interacciones ────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Historial de interacciones', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      SizedBox(height: 8),
                      Text('Asiste a un evento y activa BLE para ver tu historial aquí', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Smart Concierge ───────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 18),
                          const SizedBox(width: 6),
                          const Text('Smart Concierge', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        ],
                      ),
                      if (snapResult != null) ...[
                        const SizedBox(height: 14),
                        Text(snapResult!, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5)),
                      ] else ...[
                        const SizedBox(height: 14),
                        const Text('Aura IA analiza tus intereses para generarte recomendaciones óptimas de la convención.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      ],
                      if (snapError != null) ...[
                        const SizedBox(height: 8),
                        Text(snapError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          onPressed: snapLoading ? null : generarSnapshot,
                          icon: snapLoading 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary))
                            : const Icon(Icons.auto_awesome_outlined, size: 16, color: AppColors.secondary),
                          label: Text(snapLoading ? 'Generando...' : 'Generar Snapshot', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── BLE Token ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bluetooth_rounded, color: AppColors.secondary, size: 20),
                          const SizedBox(width: 8),
                          const Text('Token BLE anónimo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Tu identificador Bluetooth es anónimo y cambia periódicamente.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 14),
                      if (bleLoading) const Center(child: CircularProgressIndicator())
                      else if (bleError != null) Text(bleError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))
                      else if (bleToken != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Expanded(child: Text(bleToken!.token, style: const TextStyle(color: AppColors.secondary, fontFamily: 'monospace', fontSize: 12), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: bleLoading ? null : rotateBle,
                            icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                            label: const Text('Rotar token', style: TextStyle(color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Orders ────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text('Mis Órdenes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (ordersLoading) const Center(child: CircularProgressIndicator())
                      else if (orders.isEmpty) const Text('No tienes órdenes registradas.', style: TextStyle(color: AppColors.muted, fontSize: 13))
                      else Column(
                        children: orders.take(5).map((o) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('\$${o.montoTotal.toStringAsFixed(2)} ${o.moneda.toUpperCase()}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 14)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: o.status == 'pagada' ? Colors.green.withOpacity(0.15) : AppColors.faint.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(o.status, style: TextStyle(fontSize: 10, color: o.status == 'pagada' ? Colors.green : AppColors.faint)),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Danger Zone ───────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          const Text('Zona de peligro', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (deleteError != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(deleteError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                      if (!deleteConfirm)
                        ElevatedButton(
                          onPressed: deleteAccount,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, elevation: 0),
                          child: const Text('Eliminar mi cuenta'),
                        )
                      else ...[
                        const Text('Esta acción es irreversible. ¿Confirmas que deseas eliminar tu cuenta?', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: deleteLoading ? null : deleteAccount,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                              child: deleteLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Sí, eliminar'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => setState(() => deleteConfirm = false),
                              child: const Text('Cancelar', style: TextStyle(color: AppColors.muted)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }
}