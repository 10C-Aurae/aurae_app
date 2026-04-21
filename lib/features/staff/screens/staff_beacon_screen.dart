import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../theme/app_colors.dart';
import '../../../core/config/env.dart';

const Duration _heartbeatInterval = Duration(seconds: 30);

// Prefix del service UUID que identifica un beacon de Aurae (4 bytes). Los 12
// bytes restantes del UUID codifican el ObjectId del stand, por lo que cada
// stand tiene un service UUID único y determinístico.
const String _auraeServicePrefix = 'ae7ae000';

class StaffBeaconScreen extends StatefulWidget {
  final String standId;
  final String standNombre;
  final String token;

  const StaffBeaconScreen({
    super.key,
    required this.standId,
    required this.standNombre,
    required this.token,
  });

  @override
  State<StaffBeaconScreen> createState() => _StaffBeaconScreenState();
}

class _StaffBeaconScreenState extends State<StaffBeaconScreen> {
  Map<String, dynamic>? _sesion;
  bool _loading       = true;
  bool _actionLoading = false;
  String? _error;
  bool _advertising = false;

  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  Timer? _heartbeatTimer;
  Timer? _uiTickTimer;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.token}',
  };

  String get _beaconPath => '${Env.baseUrl}/api/v1/stands/${widget.standId}/beacon';

  String get _serviceUuid {
    final id = widget.standId.toLowerCase();
    // ObjectId de Mongo = 24 hex chars. Se inserta tras el prefijo Aurae.
    return '$_auraeServicePrefix-${id.substring(0, 4)}-${id.substring(4, 8)}'
           '-${id.substring(8, 12)}-${id.substring(12, 24)}';
  }

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _uiTickTimer?.cancel();
    _stopAdvertising();
    super.dispose();
  }

  // ── Backend ────────────────────────────────────────────────────────────────

  Future<void> _loadStatus() async {
    try {
      final resp = await http.get(Uri.parse('$_beaconPath/status'), headers: _headers);
      if (resp.statusCode != 200) throw Exception('Error ${resp.statusCode}');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (!mounted) return;
      final sesion = data['activo'] == true ? data['sesion'] as Map<String, dynamic>? : null;
      setState(() {
        _sesion  = sesion;
        _loading = false;
      });
      if (sesion != null) {
        await _startAdvertising();
        _startTimers();
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = _formatError(e); });
    }
  }

  Future<void> _activar() async {
    setState(() { _actionLoading = true; _error = null; });
    try {
      final ok = await _startAdvertising();
      if (!ok) return;

      final resp = await http.post(Uri.parse('$_beaconPath/activar'), headers: _headers);
      if (resp.statusCode != 201) {
        await _stopAdvertising();
        throw Exception(_extractDetail(resp) ?? 'Error ${resp.statusCode}');
      }
      final sesion = jsonDecode(resp.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _sesion = sesion);
      _startTimers();
    } catch (e) {
      if (mounted) setState(() => _error = _formatError(e));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _desactivar() async {
    setState(() { _actionLoading = true; _error = null; });
    _stopTimers();
    await _stopAdvertising();
    try {
      final resp = await http.post(Uri.parse('$_beaconPath/desactivar'), headers: _headers);
      if (resp.statusCode != 200) throw Exception(_extractDetail(resp) ?? 'Error ${resp.statusCode}');
      if (!mounted) return;
      setState(() => _sesion = null);
    } catch (e) {
      if (mounted) setState(() => _error = _formatError(e));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _heartbeat() async {
    try {
      final resp = await http.post(Uri.parse('$_beaconPath/heartbeat'), headers: _headers);
      if (resp.statusCode == 404) {
        _stopTimers();
        await _stopAdvertising();
        if (mounted) setState(() {
          _sesion = null;
          _error  = 'La sesión del beacon expiró. Actívala de nuevo.';
        });
        return;
      }
      if (resp.statusCode != 200) return;
      final sesion = jsonDecode(resp.body) as Map<String, dynamic>;
      if (mounted) setState(() => _sesion = sesion);
    } catch (_) {}
  }

  // ── BLE advertising ────────────────────────────────────────────────────────

  Future<bool> _startAdvertising() async {
    if (_advertising) return true;

    // Verifica que el dispositivo pueda emitir BLE.
    if (!await _peripheral.isSupported) {
      if (mounted) setState(() => _error = 'Este dispositivo no soporta emisión BLE.');
      return false;
    }

    // Permisos (Android 12+: BLUETOOTH_ADVERTISE y BLUETOOTH_CONNECT).
    final granted = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();
    if (granted.values.any((s) => !s.isGranted && !s.isLimited)) {
      if (mounted) setState(() => _error = 'Se requieren permisos de Bluetooth para emitir el beacon.');
      return false;
    }

    try {
      await _peripheral.start(
        advertiseData: AdvertiseData(
          serviceUuid: _serviceUuid,
          includeDeviceName: false,
        ),
        advertiseSettings: AdvertiseSettings(
          advertiseMode: AdvertiseMode.advertiseModeBalanced,
          txPowerLevel:  AdvertiseTxPower.advertiseTxPowerHigh,
          connectable: false,
        ),
      );
      if (mounted) setState(() => _advertising = true);
      return true;
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo iniciar el advertising BLE: ${_formatError(e)}');
      return false;
    }
  }

  Future<void> _stopAdvertising() async {
    if (!_advertising) return;
    try {
      await _peripheral.stop();
    } catch (_) {}
    if (mounted) setState(() => _advertising = false);
  }

  // ── Timers ─────────────────────────────────────────────────────────────────

  void _startTimers() {
    _heartbeatTimer?.cancel();
    _uiTickTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => _heartbeat());
    _uiTickTimer    = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopTimers() {
    _heartbeatTimer?.cancel(); _heartbeatTimer = null;
    _uiTickTimer?.cancel();    _uiTickTimer    = null;
  }

  // ── Utils ──────────────────────────────────────────────────────────────────

  String _formatError(Object e) => e.toString().replaceFirst('Exception: ', '');

  String? _extractDetail(http.Response resp) {
    try {
      final data = jsonDecode(resp.body);
      return data is Map && data['detail'] != null ? data['detail'].toString() : null;
    } catch (_) { return null; }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activo = _sesion != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.nav,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Beacon BLE', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            Text(widget.standNombre,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  if (_error != null) _ErrorBanner(message: _error!),
                  if (_error != null) const SizedBox(height: 14),
                  activo ? _buildActivo() : _buildInactivo(),
                ],
              ),
            ),
    );
  }

  Widget _buildInactivo() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: const Icon(Icons.bluetooth_disabled_rounded, size: 30, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          const Text('Beacon inactivo',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text(
            'Al activarlo, tu teléfono emitirá una señal Bluetooth que los asistentes detectarán al acercarse al stand.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _actionLoading ? null : AppColors.brandGradient,
                color:    _actionLoading ? AppColors.faint : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _actionLoading ? null : _activar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _actionLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.bluetooth_rounded, color: Colors.white, size: 20),
                label: Text(_actionLoading ? 'Activando…' : 'Emitir señal Bluetooth',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivo() {
    final activadoEn = DateTime.tryParse(_sesion!['activado_en'] ?? '')?.toLocal();
    final lastHb     = DateTime.tryParse(_sesion!['last_heartbeat'] ?? '')?.toLocal();
    final ahora      = DateTime.now();
    final tiempoActivo = activadoEn != null ? ahora.difference(activadoEn).inSeconds : 0;
    final segDesdeHb   = lastHb     != null ? ahora.difference(lastHb).inSeconds     : 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          const _PulseIcon(),
          const SizedBox(height: 14),
          const Text('Emitiendo señal Bluetooth',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(
            _advertising
                ? 'Los asistentes cerca del stand detectarán esta señal en su app y podrán registrar su visita automáticamente.'
                : 'Sesión activa en el servidor, pero la emisión BLE está detenida. Intenta reactivar.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('IDENTIFICADOR DE EMISIÓN',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                     color: AppColors.faint, letterSpacing: 0.8)),
                const SizedBox(height: 6),
                Text(
                  _serviceUuid,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.ink,
                    fontFeatures: [FontFeature.tabularFigures()],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Tiempo activo',     value: _fmtElapsed(tiempoActivo))),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: 'Último heartbeat',  value: 'hace ${segDesdeHb}s')),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Mantén esta pantalla abierta mientras el beacon esté activo. La emisión se detiene al salir o al desactivar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.faint),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: _actionLoading ? null : _desactivar,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.muted,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_actionLoading ? 'Desactivando…' : 'Desactivar beacon',
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtElapsed(int totalSec) {
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  final s = totalSec % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.faint)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink,
                fontFeatures: [FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  const _PulseIcon();

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84, height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => _pulse(_ctrl.value),
          ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => _pulse((_ctrl.value + 0.33) % 1.0),
          ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => _pulse((_ctrl.value + 0.66) % 1.0),
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.22),
            ),
            child: const Icon(Icons.bluetooth_rounded, color: AppColors.primary, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _pulse(double t) {
    final size = 48 + (36 * t);
    return Opacity(
      opacity: (1 - t).clamp(0.0, 1.0),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.22 * (1 - t)),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: const TextStyle(fontSize: 12, color: AppColors.primary))),
        ],
      ),
    );
  }
}
