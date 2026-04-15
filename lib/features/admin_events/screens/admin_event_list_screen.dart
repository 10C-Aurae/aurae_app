import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../discover/data/event_service.dart';
import '../../discover/models/event.dart';
import '../../../core/auth/token_service.dart';
import '../../profile/data/profile_service.dart';
import 'admin_event_form_screen.dart';
import 'admin_stands_screen.dart';
import 'admin_tickets_screen.dart';

class AdminEventListScreen extends StatefulWidget {
  const AdminEventListScreen({super.key});

  @override
  State<AdminEventListScreen> createState() => _AdminEventListScreenState();
}

class _AdminEventListScreenState extends State<AdminEventListScreen> {
  final EventService _eventService = EventService();
  final ProfileService _profileService = ProfileService();
  final TokenService _tokenService = TokenService();

  List<Event> myEvents = [];
  bool loading = true;
  String? userId;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      token = await _tokenService.getToken();
      if (token == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final profile = await _profileService.getMyProfile(token!);
      userId = profile.id;

      final allEvents = await _eventService.getEvents();
      myEvents = allEvents.where((ev) => ev.organizadorId == userId).toList();

    } catch (e) {
      debugPrint('Error loading admin events: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Mis Eventos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminEventFormScreen()),
            ).then((_) => _loadData()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : myEvents.isEmpty
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
          Icon(Icons.event_note_rounded, size: 64, color: AppColors.faint),
          const SizedBox(height: 16),
          const Text('No has creado eventos aún', style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminEventFormScreen()),
            ).then((_) => _loadData()),
            child: const Text('Crear mi primer evento →', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myEvents.length,
      itemBuilder: (context, index) {
        final ev = myEvents[index];
        return _AdminEventCard(
          event: ev,
          onEdit: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminEventFormScreen(event: ev)),
          ).then((_) => _loadData()),
          onDelete: () => _confirmDelete(ev),
        );
      },
    );
  }

  Future<void> _confirmDelete(Event ev) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('¿Eliminar evento?', style: TextStyle(color: AppColors.ink)),
        content: Text('Esta acción eliminará "${ev.nombre}" y no se puede deshacer.', style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: AppColors.muted))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && token != null) {
      try {
        await _eventService.deleteEvent(token!, ev.id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _AdminEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminEventCard({required this.event, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(event.nombre, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd MMM, yyyy').format(event.fechaInicio), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: event.activo ? Colors.greenAccent : AppColors.faint,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(event.activo ? 'Activo' : 'Inactivo', style: TextStyle(color: event.activo ? Colors.greenAccent : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            trailing: event.imagenUrl.isNotEmpty
                ? Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(image: NetworkImage(event.imagenUrl), fit: BoxFit.cover),
                    ),
                  )
                : null,
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminStandsScreen(
                        eventId: event.id,
                        eventNombre: event.nombre,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.storefront_rounded, size: 16),
                  label: const Text('Stands', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: Colors.purpleAccent),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminTicketsScreen(
                        eventId: event.id,
                        eventNombre: event.nombre,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.confirmation_num_rounded, size: 16),
                  label: const Text('Tickets', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Editar', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Eliminar', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent.withOpacity(0.8)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
