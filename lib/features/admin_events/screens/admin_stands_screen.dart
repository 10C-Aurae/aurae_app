import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../discover/data/stands_service.dart';
import '../../../core/auth/token_service.dart';
import 'admin_stand_form_screen.dart';

class AdminStandsScreen extends StatefulWidget {
  final String eventId;
  final String eventNombre;

  const AdminStandsScreen({super.key, required this.eventId, required this.eventNombre});

  @override
  State<AdminStandsScreen> createState() => _AdminStandsScreenState();
}

class _AdminStandsScreenState extends State<AdminStandsScreen> {
  final StandsService _standsService = StandsService();
  final TokenService _tokenService = TokenService();

  List<dynamic> stands = [];
  bool loading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadStands();
  }

  Future<void> _loadStands() async {
    setState(() => loading = true);
    try {
      token = await _tokenService.getToken();
      if (token == null) return;

      stands = await _standsService.getStandsByEvent(token!, widget.eventId);
    } catch (e) {
      debugPrint('Error loading stands: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gestionar Stands', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.eventNombre, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminStandFormScreen(eventId: widget.eventId)),
            ).then((_) => _loadStands()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStands,
        color: AppColors.primary,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : stands.isEmpty
                ? _buildEmptyState()
                : _buildList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront_rounded, size: 64, color: AppColors.faint),
          const SizedBox(height: 16),
          const Text('No hay stands en este evento', style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Agrega el primero para comenzar', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stands.length,
      itemBuilder: (context, index) {
        final stand = stands[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(stand["nombre"] ?? "Sin nombre", style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
            subtitle: Text(stand["descripcion"] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
              color: AppColors.card,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar', style: TextStyle(color: AppColors.ink))),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
              ],
              onSelected: (val) {
                if (val == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminStandFormScreen(eventId: widget.eventId, stand: stand)),
                  ).then((_) => _loadStands());
                } else if (val == 'delete') {
                  _confirmDelete(stand);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(dynamic stand) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('¿Eliminar stand?', style: TextStyle(color: AppColors.ink)),
        content: Text('Esta acción eliminará "${stand["nombre"]}" permanentemente.', style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: AppColors.muted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed == true && token != null) {
      try {
        await _standsService.deleteStand(token!, stand["id"]);
        _loadStands();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
