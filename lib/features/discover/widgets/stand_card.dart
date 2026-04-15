import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class StandCard extends StatelessWidget {
  final Map<String, dynamic> stand;
  final double? rating;

  const StandCard({super.key, required this.stand, this.rating});

  @override
  Widget build(BuildContext context) {
    final String nombre = stand["nombre"] ?? "Stand";
    final String categoria = stand["categoria"] ?? "";
    final String imagen = stand["imagen_url"] ?? "";
    final bool hasQueue = stand["tiene_cola"] ?? false;

    return Container(
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
          // Imagen / Placeholder
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imagen.isNotEmpty
                  ? Image.network(imagen, fit: BoxFit.cover, width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.surface, child: const Icon(Icons.storefront_rounded, color: AppColors.faint)))
                  : Container(color: AppColors.surface, child: const Icon(Icons.storefront_rounded, color: AppColors.faint)),
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
                        Text(categoria.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(nombre, style: const TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (rating != null)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(rating!.toStringAsFixed(1), style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        )
                      else
                        const SizedBox(),
                      if (hasQueue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: const Text('COLA', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
