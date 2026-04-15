import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../data/notification_service.dart';
import '../models/notification_model.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final t = await TokenService().getToken();
    if (t == null || !mounted) return;
    try {
      final count = await NotificationService().getUnreadCount(t);
      if (mounted) setState(() { _unread = count; _token = t; });
    } catch (_) {}
  }

  Future<void> _openPanel() async {
    final t = _token;
    if (t == null) return;

    // Abre el sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NotificationSheet(token: t),
    );

    // Al cerrar, recarga el contador (puede haber leído todo)
    _loadCount();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openPanel,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.notifications_outlined, size: 18, color: AppColors.muted),
            ),
            if (_unread > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet ─────────────────────────────────────────────────────────────

class _NotificationSheet extends StatefulWidget {
  final String token;
  const _NotificationSheet({required this.token});

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  final _service = NotificationService();
  List<NotificationModel>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.getNotifications(widget.token);
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
      // Marcar todas como leídas en background
      _service.markAllRead(widget.token);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder: (_, controller) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Text('Notificaciones',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const Spacer(),
                  if (_items != null && _items!.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        await _service.markAllRead(widget.token);
                        setState(() {
                          _items = _items!.map((n) => NotificationModel(
                            id: n.id, tipo: n.tipo, titulo: n.titulo, cuerpo: n.cuerpo,
                            leida: true, metadata: n.metadata, createdAt: n.createdAt,
                          )).toList();
                        });
                      },
                      child: const Text('Marcar todo leído',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : (_items == null || _items!.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.notifications_none_rounded, size: 44, color: AppColors.faint),
                              SizedBox(height: 10),
                              Text('Sin notificaciones', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items!.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: AppColors.border),
                          itemBuilder: (_, i) => _NotifTile(item: _items![i]),
                        ),
            ),
          ],
        );
      },
    );
  }
}

// ── Tile individual ───────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final NotificationModel item;
  const _NotifTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.leida ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono por tipo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(child: Icon(_iconForType(item.tipo), size: 18, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.titulo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: item.leida ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.ink,
                          )),
                    ),
                    if (!item.leida)
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(item.cuerpo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(_relativeTime(item.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.faint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String tipo) {
    switch (tipo) {
      case 'ticket_comprado':    return Icons.confirmation_number_rounded;
      case 'turno_llamado':      return Icons.queue_rounded;
      case 'aura_subio':         return Icons.auto_awesome_rounded;
      case 'mensaje_stand':      return Icons.store_rounded;
      case 'mensaje_evento':     return Icons.event_rounded;
      case 'bienvenida':         return Icons.celebration_rounded;
      default:                   return Icons.notifications_rounded;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1)    return 'Ayer';
    if (diff.inDays < 7)     return 'Hace ${diff.inDays} días';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
