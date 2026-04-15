import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_colors.dart';

class LocationSearchField extends StatefulWidget {
  final String? initialValue;
  final Function(Map<String, dynamic> location) onLocationSelected;

  const LocationSearchField({
    super.key,
    this.initialValue,
    required this.onLocationSelected,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length > 2) {
        _search(query);
      } else {
        setState(() {
          _results = [];
          _loading = false;
        });
      }
    });
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1');
      final response = await http.get(url, headers: {'Accept-Language': 'es'});
      if (response.statusCode == 200) {
        setState(() {
          _results = jsonDecode(response.body);
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: AppColors.ink, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Buscar lugar o dirección...',
            prefixIcon: const Icon(Icons.place_rounded, size: 20, color: AppColors.faint),
            suffixIcon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.faint),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
          ),
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: _results.map((place) {
                final String nombre = place["name"] ?? place["display_name"].split(',')[0];
                final String direccion = place["display_name"];

                return ListTile(
                  dense: true,
                  title: Text(nombre, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                  subtitle: Text(direccion, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted)),
                  onTap: () {
                    widget.onLocationSelected({
                      "nombre": nombre,
                      "direccion": direccion,
                      "lat": double.parse(place["lat"]),
                      "lng": double.parse(place["lon"]),
                    });
                    setState(() {
                      _controller.text = nombre;
                      _results = [];
                    });
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
