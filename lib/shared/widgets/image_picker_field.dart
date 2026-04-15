import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../../core/api/api_client.dart';
import '../../theme/app_colors.dart';

/// Widget reutilizable para seleccionar y subir una imagen a S3 vía backend.
/// Muestra preview, botones de galería/cámara, progress bar y fallback de URL manual.
class ImagePickerField extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChange;
  final String label;
  final String token;

  const ImagePickerField({
    super.key,
    required this.value,
    required this.onChange,
    required this.token,
    this.label = 'Imagen',
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  final _picker = ImagePicker();
  final _urlController = TextEditingController();

  bool _uploading = false;
  double _progress = 0;
  String? _error;
  bool _urlMode = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.value ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Devuelve un MIME type válido para el backend a partir de la extensión del archivo.
  /// image_picker con imageQuality convierte HEIC → JPEG en iOS automáticamente.
  String _mimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg'; // cámara siempre produce JPEG tras compresión
    }
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    if (picked == null) return;

    // image_picker puede reportar el mimeType directamente; si no, lo deducimos
    final mime = picked.mimeType ?? _mimeType(picked.path);

    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final url = await _uploadFile(File(picked.path), mime);
      widget.onChange(url);
      _urlController.text = url;
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String> _uploadFile(File file, String mimeType) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/media/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${widget.token}'
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ));

    // Simula progreso en pasos ya que http no expone progreso real
    setState(() => _progress = 0.2);
    final streamed = await request.send();
    setState(() => _progress = 0.8);

    final body = await streamed.stream.bytesToString();
    setState(() => _progress = 1.0);

    if (streamed.statusCode != 201) {
      String detail = 'Error al subir imagen (${streamed.statusCode})';
      try {
        final decoded = jsonDecode(body);
        detail = decoded['detail'] ?? detail;
      } catch (_) {}
      throw Exception(detail);
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['url'] as String;
  }

  void _submitUrl() {
    final trimmed = _urlController.text.trim();
    if (trimmed.isNotEmpty) {
      widget.onChange(trimmed);
      setState(() => _urlMode = false);
    }
  }

  void _clear() {
    widget.onChange('');
    _urlController.clear();
    setState(() {
      _error = null;
      _urlMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.value != null && widget.value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Preview
        if (hasImage && !_uploading)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.value!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(showError: true),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _clear,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.54),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),

        // Upload progress
        if (_uploading)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  'Subiendo… ${(_progress * 100).toInt()}%',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: AppColors.surface,
                      color: AppColors.primary,
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Drop zone (sin imagen y sin carga)
        if (!hasImage && !_uploading) _placeholder(),

        const SizedBox(height: 8),

        // Botones de acción
        if (!_uploading)
          Row(
            children: [
              _actionButton(
                icon: Icons.photo_library_rounded,
                label: 'Galería',
                onTap: () => _pickAndUpload(ImageSource.gallery),
              ),
              const SizedBox(width: 8),
              _actionButton(
                icon: Icons.camera_alt_rounded,
                label: 'Cámara',
                onTap: () => _pickAndUpload(ImageSource.camera),
              ),
              const SizedBox(width: 8),
              _actionButton(
                icon: Icons.link_rounded,
                label: _urlMode ? 'Cancelar' : 'URL',
                onTap: () => setState(() => _urlMode = !_urlMode),
              ),
            ],
          ),

        // Modo URL manual
        if (_urlMode && !_uploading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: AppColors.ink, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'https://ejemplo.com/imagen.jpg',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _submitUrl(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitUrl,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Usar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Error
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: Colors.redAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _placeholder({bool showError = false}) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: showError ? Colors.redAccent.withValues(alpha: 0.4) : AppColors.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showError ? Icons.broken_image_rounded : Icons.image_outlined,
            size: 28,
            color: AppColors.faint,
          ),
          const SizedBox(height: 4),
          Text(
            showError ? 'URL inválida' : 'Sin imagen',
            style: const TextStyle(color: AppColors.faint, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.muted),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
