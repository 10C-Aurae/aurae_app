import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../discover/models/event.dart';
import '../../discover/data/event_service.dart';
import '../../../core/auth/token_service.dart';
import '../widgets/location_search_field.dart';

class AdminEventFormScreen extends StatefulWidget {
  final Event? event;
  const AdminEventFormScreen({super.key, this.event});

  @override
  State<AdminEventFormScreen> createState() => _AdminEventFormScreenState();
}

class _AdminEventFormScreenState extends State<AdminEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();
  final TokenService _tokenService = TokenService();

  bool loading = false;
  bool saving = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _imageController;
  late TextEditingController _priceController;
  late TextEditingController _passwordController;
  late TextEditingController _promptController;
  late TextEditingController _chatbotController;
  late TextEditingController _capacityController;

  // State
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic> _location = {"nombre": "", "direccion": "", "lat": 0.0, "lng": 0.0};
  List<String> _selectedCategories = [];
  bool _isPublic = true;
  bool _hasPassword = false;
  bool _isFree = true;
  bool _chatEnabled = true;
  bool _isActive = true;
  List<String> _selectedArchetypes = [];

  static const categories = [
    'tecnologia', 'musica', 'arte', 'gaming', 'negocios',
    'gastronomia', 'deportes', 'networking', 'innovacion', 'sustentabilidad',
  ];

  static const archetypes = ['Techie', 'Foodie', 'Networking Master', 'Explorer', 'Creativo'];

  @override
  void initState() {
    super.initState();
    final ev = widget.event;
    _nameController = TextEditingController(text: ev?.nombre ?? '');
    _descController = TextEditingController(text: ev?.descripcion ?? '');
    _imageController = TextEditingController(text: ev?.imagenUrl ?? '');
    _priceController = TextEditingController(text: ev?.precio.toString() ?? '');
    _passwordController = TextEditingController(text: ev?.passwordAcceso ?? '');
    _promptController = TextEditingController(text: ev?.auraFlowPrompt ?? '');
    _chatbotController = TextEditingController(text: ev?.infoChatbot ?? '');
    _capacityController = TextEditingController(text: ev?.capacidadMax?.toString() ?? '');

    if (ev != null) {
      _startDate = ev.fechaInicio;
      _endDate = ev.fechaFin;
      _location = {
        "nombre": ev.ubicacionNombre,
        "direccion": ev.direccion,
        "lat": ev.lat,
        "lng": ev.lng,
      };
      _selectedCategories = List.from(ev.categorias);
      _isPublic = ev.esPublico;
      _hasPassword = ev.tienePassword;
      _isFree = ev.esGratuito;
      _chatEnabled = ev.chatHabilitado;
      _isActive = ev.activo;
      _selectedArchetypes = List.from(ev.arquetiposDisponibles ?? []);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _imageController.dispose();
    _priceController.dispose();
    _passwordController.dispose();
    _promptController.dispose();
    _chatbotController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime((isStart ? _startDate : _endDate) ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          final fullDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
          if (isStart) {
            _startDate = fullDate;
          } else {
            _endDate = fullDate;
          }
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona fechas de inicio y fin')));
      return;
    }

    setState(() => saving = true);
    try {
      final token = await _tokenService.getToken();
      if (token == null) return;

      final data = {
        "nombre": _nameController.text,
        "descripcion": _descController.text,
        "imagen_url": _imageController.text,
        "ubicacion": _location["direccion"].isNotEmpty ? _location : null,
        "fecha_inicio": _startDate!.toIso8601String(),
        "fecha_fin": _endDate!.toIso8601String(),
        "capacidad_max": int.tryParse(_capacityController.text) ?? 0,
        "categorias": _selectedCategories,
        "es_publico": _isPublic,
        "tiene_password": _hasPassword,
        "password_acceso": _hasPassword ? _passwordController.text : null,
        "es_gratuito": _isFree,
        "precio": _isFree ? 0 : double.tryParse(_priceController.text) ?? 0,
        "chat_habilitado": _chatEnabled,
        "is_active": _isActive,
        "aura_flow_prompt": _promptController.text,
        "arquetipos_disponibles": _selectedArchetypes,
        "info_chatbot": _chatbotController.text,
      };

      if (widget.event == null) {
        await _eventService.createEvent(token, data);
      } else {
        await _eventService.updateEvent(token, widget.event!.id, data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.event == null ? 'Crear Evento' : 'Editar Evento', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          if (saving)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))))
          else
            TextButton(onPressed: _save, child: const Text('Guardar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Información básica'),
              _buildTextField('Nombre del evento', _nameController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Descripción', _descController, maxLines: 4, required: true),
              const SizedBox(height: 16),
              _buildTextField('Imagen URL (Portada)', _imageController, hint: 'https://...'),
              
              const SizedBox(height: 24),
              _sectionTitle('Lugar y tiempo'),
              _buildDateTimeRow(),
              const SizedBox(height: 16),
              const Text('Ubicación', style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              LocationSearchField(
                initialValue: _location["nombre"],
                onLocationSelected: (loc) => setState(() => _location = loc),
              ),
              if (_location["direccion"].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_location["direccion"], style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                ),

              const SizedBox(height: 24),
              _sectionTitle('Detalles'),
              _buildTextField('Capacidad máxima (0 = sin límite)', _capacityController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              const Text('Categorías', style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _buildChips(categories, _selectedCategories),

              const SizedBox(height: 24),
              _sectionTitle('Acceso'),
              _buildSwitchTile('Evento público', 'Cualquier usuario puede ver y comprar tickets', _isPublic, (v) => setState(() => _isPublic = v)),
              _buildSwitchTile('Requiere contraseña', 'Código de 8 dígitos para inscribirse', _hasPassword, (v) => setState(() => _hasPassword = v)),
              if (_hasPassword)
                _buildTextField('Contraseña (8 dígitos)', _passwordController, keyboardType: TextInputType.number, maxLength: 8),

              const SizedBox(height: 24),
              _sectionTitle('Precio'),
              _buildSwitchTile('Evento gratuito', 'Sin costo de entrada', _isFree, (v) => setState(() => _isFree = v)),
              if (!_isFree)
                _buildTextField('Precio (MXN)', _priceController, keyboardType: TextInputType.number, prefixText: '\$'),

              const SizedBox(height: 24),
              _sectionTitle('Aura Flow IA'),
              _buildTextField('Prompt maestro (IA)', _promptController, maxLines: 3, hint: 'Ej. Prioriza stands de tecnología...'),
              const SizedBox(height: 16),
              const Text('Arquetipos de asistente', style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _buildChips(archetypes, _selectedArchetypes),

              const SizedBox(height: 24),
              _sectionTitle('Chatbot'),
              _buildTextField('Información FAQ', _chatbotController, maxLines: 5, hint: 'Escribe aquí información útil sobre el evento para el bot...'),

              const SizedBox(height: 24),
              _buildSwitchTile('Habilitar Chat', 'Permitir mensajes entre asistentes', _chatEnabled, (v) => setState(() => _chatEnabled = v)),
              _buildSwitchTile('Publicar evento', 'Visible para todos los usuarios ahora', _isActive, (v) => setState(() => _isActive = v)),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted, letterSpacing: 1.2)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, bool required = false, String? hint, TextInputType? keyboardType, String? prefixText, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: const TextStyle(color: AppColors.ink, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            counterText: "",
          ),
          validator: (v) {
            if (required && (v == null || v.isEmpty)) return 'Este campo es requerido';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Inicio', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(_startDate == null ? 'Elegir...' : DateFormat('dd/MM HH:mm').format(_startDate!), style: const TextStyle(color: AppColors.ink, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fin', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(_endDate == null ? 'Elegir...' : DateFormat('dd/MM HH:mm').format(_endDate!), style: const TextStyle(color: AppColors.ink, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildChips(List<String> items, List<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected.contains(item);
        return FilterChip(
          label: Text(item, style: TextStyle(color: isSelected ? Colors.white : AppColors.muted, fontSize: 12)),
          selected: isSelected,
          onSelected: (v) {
            setState(() {
              if (v) {
                selected.add(item);
              } else {
                selected.remove(item);
              }
            });
          },
          backgroundColor: AppColors.card,
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
        );
      }).toList(),
    );
  }
}
