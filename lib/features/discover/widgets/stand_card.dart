import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../chat/screens/stand_chat_screen.dart';
import '../../concierge/screens/concierge_screen.dart';

class StandCard extends StatelessWidget {
  final Map<String, dynamic> stand;
  final double? rating;
  final String? eventoId;

  const StandCard({super.key, required this.stand, this.rating, this.eventoId});

  @override
  Widget build(BuildContext context) {
    final String id       = stand["id"] ?? stand["_id"] ?? '';
    final String nombre   = stand["nombre"] ?? "Stand";
    final String categoria = stand["categoria"] ?? "";
    final String imagen   = stand["imagen_url"] ?? "";
    final bool hasQueue   = stand["tiene_cola"] ?? false;

    return GestureDetector(
      onTap: () => _showStandSheet(context, id, nombre, imagen),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imagen.isNotEmpty
                    ? Image.network(imagen, fit: BoxFit.cover, width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.surface,
                            child: const Icon(Icons.storefront_rounded, color: AppColors.faint)))
                    : Container(color: AppColors.surface,
                        child: const Icon(Icons.storefront_rounded, color: AppColors.faint)),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (categoria.isNotEmpty)
                          Text(categoria.toUpperCase(),
                              style: const TextStyle(color: AppColors.primary, fontSize: 9,
                                  fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(nombre,
                            style: const TextStyle(color: AppColors.ink, fontSize: 13,
                                fontWeight: FontWeight.bold),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (rating != null)
                          Row(children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(rating!.toStringAsFixed(1),
                                style: const TextStyle(color: AppColors.muted, fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ])
                        else
                          const SizedBox(),
                        if (hasQueue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text('COLA',
                                style: TextStyle(color: Colors.green, fontSize: 8,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStandSheet(BuildContext context, String id, String nombre, String imagen) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(nombre,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
              const SizedBox(height: 16),
              _SheetTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat con el stand',
                subtitle: 'Pedidos y preguntas',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StandChatScreen(
                      standId: id, standNombre: nombre,
                      standImageUrl: imagen.isNotEmpty ? imagen : null,
                    ),
                  ));
                },
              ),
              if (eventoId != null) ...[
                const SizedBox(height: 8),
                _SheetTile(
                  icon: Icons.queue_rounded,
                  label: 'Unirse a la cola',
                  subtitle: 'Gestiona tu turno virtual',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ConciergeScreen(
                        eventoId: eventoId!, eventoNombre: nombre,
                      ),
                    ));
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(label,
          style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
    );
  }
}
