import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../discover/data/stands_service.dart';
import '../../../core/auth/token_service.dart';

class AdminStandFormScreen extends StatefulWidget {
  final String eventId;
  final dynamic stand; // dynamic to avoid complex model for now, or use a Stand model if exists

  const AdminStandFormScreen({super.key, required this.eventId, this.stand});

  @override
  State<AdminStandFormScreen> createState() => _AdminStandFormScreenState();
}

class _AdminStandFormScreenState extends State<AdminStandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final StandsService _standsService = StandsService();
  final TokenService _tokenService = TokenService();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late TextEditingController _imageController;
  late TextEditingController _responsibleController;
  
  bool _isActive = true;
  bool _tieneCola = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.stand;
    _nameController = TextEditingController(text: s?["nombre"] ?? "");
    _descController = TextEditingController(text: s?["descripcion"] ?? "");
    _categoryController = TextEditingController(text: s?["categoria"] ?? "");
    _imageController = TextEditingController(text: s?["imagen_url"] ?? "");
    _responsibleController = TextEditingController(text: s?["responsable"] ?? "");
    _isActive = s?["is_active"] ?? true;
    _tieneCola = s?["tiene_cola"] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _imageController.dispose();
    _responsibleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    try {
      final token = await _tokenService.getToken();
      if (token == null) return;

      final data = {
        "nombre": _nameController.text,
        "descripcion": _descController.text,
        "categoria": _categoryController.text,
        "imagen_url": _imageController.text,
        "responsable": _responsibleController.text,
        "is_active": _isActive,
        "tiene_cola": _tieneCola,
        "evento_id": widget.eventId,
      };

      if (widget.stand == null) {
        await _standsService.createStand(token, data);
      } else {
        await _standsService.updateStand(token, widget.stand["id"], data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.stand == null ? 'Crear Stand' : 'Editar Stand', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          if (_saving)
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
              _buildTextField('Nombre del stand', _nameController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Categoría', _categoryController, hint: 'Ej. Tecnología, Comida, etc.'),
              const SizedBox(height: 16),
              _buildTextField('Descripción', _descController, maxLines: 3, required: true),
              const SizedBox(height: 16),
              _buildTextField('Responsable', _responsibleController),
              const SizedBox(height: 16),
              _buildTextField('Imagen URL', _imageController, hint: 'https://...'),
              const SizedBox(height: 24),
              _buildSwitchTile('Stand Activo', 'Visible para los asistentes', _isActive, (v) => setState(() => _isActive = v)),
              _buildSwitchTile('Turnos Virtuales (Cola)', 'Permitir al usuario unirse a una cola inteligente', _tieneCola, (v) => setState(() => _tieneCola = v)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, bool required = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.ink, fontSize: 14),
          decoration: InputDecoration(hintText: hint),
          validator: (v) {
            if (required && (v == null || v.isEmpty)) return 'Este campo es requerido';
            return null;
          },
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
}
