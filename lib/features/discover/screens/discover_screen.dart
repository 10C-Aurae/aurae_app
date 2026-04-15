import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../data/event_service.dart';
import '../models/event.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';
import '../../notifications/widgets/notification_bell.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<Event> events = [];
  bool loading = true;

  String query = '';
  String? catFiltro;
  String timeTab = 'proximos'; // proximos, todos, pasados
  bool showFilters = false;

  final TextEditingController _searchController = TextEditingController();

  static const categorias = [
    'tecnologia', 'musica', 'arte', 'gaming', 'negocios',
    'gastronomia', 'deportes', 'networking', 'innovacion', 'sustentabilidad',
  ];

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      final result = await EventService().getEvents();
      if (!mounted) return;
      setState(() { events = result; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  List<Event> get _filteredEvents {
    final now = DateTime.now();
    return events.where((ev) {
      if (!ev.activo) return false;

      final start = ev.fechaInicio;
      final end = ev.fechaFin; 

      if (timeTab == 'proximos') {
        final isPast = now.isAfter(end);
        if (isPast) return false;
      } else if (timeTab == 'pasados') {
        final isPast = now.isAfter(start); // event already started/finished
        if (!isPast) return false;
      }

      if (catFiltro != null && !ev.categorias.contains(catFiltro)) return false;

      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final inName = ev.nombre.toLowerCase().contains(q);
        final inDesc = ev.descripcion.toLowerCase().contains(q);
        final inLoc = ev.ubicacionNombre.toLowerCase().contains(q) || ev.direccion.toLowerCase().contains(q);
        if (!inName && !inDesc && !inLoc) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;
    
    final bool showHero = timeTab == 'proximos' && catFiltro == null && query.isEmpty;
    final Event? hero = (showHero && filtered.isNotEmpty) ? filtered.first : null;
    final List<Event> rest = (showHero && filtered.isNotEmpty) ? filtered.sublist(1) : filtered;

    int activeFilters = (catFiltro != null ? 1 : 0) + (query.isNotEmpty ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: loadEvents,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.nav,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const Text('Explorar eventos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
              actions: const [NotificationBell()],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(height: 0.5, color: AppColors.border),
              ),
            ),

            if (loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    
                    // ── Search & Filter Toggle ──
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: AppColors.faint, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (val) => setState(() => query = val),
                                    style: const TextStyle(color: AppColors.ink, fontSize: 14),
                                    decoration: const InputDecoration(
                                      hintText: 'Buscar eventos...',
                                      hintStyle: TextStyle(color: AppColors.faint),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                if (query.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => query = '');
                                    },
                                    child: const Icon(Icons.close_rounded, color: AppColors.faint, size: 18),
                                  )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => setState(() => showFilters = !showFilters),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: (showFilters || activeFilters > 0) ? AppColors.primary : AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: (showFilters || activeFilters > 0) ? AppColors.primary : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.tune_rounded, size: 18, color: (showFilters || activeFilters > 0) ? Colors.white : AppColors.muted),
                                if (activeFilters > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                                    child: Text('$activeFilters', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Filters Panel ──
                    if (showFilters) ...[
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
                            const Text('CUÁNDO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted, letterSpacing: 1.2)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _TimeTabBtn(label: 'Próximos', selected: timeTab == 'proximos', onTap: () => setState(() => timeTab = 'proximos')),
                                _TimeTabBtn(label: 'Todos', selected: timeTab == 'todos', onTap: () => setState(() => timeTab = 'todos')),
                                _TimeTabBtn(label: 'Pasados', selected: timeTab == 'pasados', onTap: () => setState(() => timeTab = 'pasados')),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text('CATEGORÍA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted, letterSpacing: 1.2)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _CatBtn(label: 'Todas', selected: catFiltro == null, onTap: () => setState(() => catFiltro = null)),
                                ...categorias.map((c) => _CatBtn(
                                      label: c[0].toUpperCase() + c.substring(1),
                                      selected: catFiltro == c,
                                      onTap: () => setState(() => catFiltro = catFiltro == c ? null : c),
                                    )),
                              ],
                            ),
                            if (activeFilters > 0) ...[
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() { query = ''; catFiltro = null; });
                                  },
                                  child: const Text('Limpiar filtros', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // ── Inline Time Tabs ──
                      Wrap(
                        spacing: 8,
                        children: [
                          _TimeTabBtn(label: 'Próximos', selected: timeTab == 'proximos', onTap: () => setState(() => timeTab = 'proximos')),
                          _TimeTabBtn(label: 'Todos', selected: timeTab == 'todos', onTap: () => setState(() => timeTab = 'todos')),
                          _TimeTabBtn(label: 'Pasados', selected: timeTab == 'pasados', onTap: () => setState(() => timeTab = 'pasados')),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Empty State ──
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_busy_rounded, size: 52, color: AppColors.faint),
                              const SizedBox(height: 12),
                              Text((query.isNotEmpty || catFiltro != null) ? 'Sin resultados para tu búsqueda' : 'No hay eventos disponibles', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text((query.isNotEmpty || catFiltro != null) ? 'Prueba con otros términos' : 'Vuelve pronto', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // ── Hero Event ──
                      if (hero != null) ...[
                        _HeroEventCard(event: hero, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: hero)))),
                        const SizedBox(height: 16),
                      ],

                      // ── Rest List ──
                      ...rest.map((ev) => EventCard(
                        event: ev,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev))),
                      )),
                    ],

                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Components ──

class _TimeTabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimeTabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.muted)),
      ),
    );
  }
}

class _CatBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CatBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? (label == 'Todas' ? AppColors.ink : AppColors.primary) : Colors.transparent,
          border: Border.all(color: selected ? Colors.transparent : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? (label == 'Todas' ? AppColors.bg : Colors.white) : AppColors.muted)),
      ),
    );
  }
}

class _HeroEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _HeroEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 6, decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Próximo evento', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 12),
                  Text(event.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  if (event.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(event.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(event.ubicacionNombre.isNotEmpty ? event.ubicacionNombre : event.direccion, style: const TextStyle(fontSize: 13, color: AppColors.muted), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  if (event.categorias.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      children: event.categorias.map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                        child: Text(c, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}