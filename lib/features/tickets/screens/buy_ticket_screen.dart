import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../discover/models/event.dart';
import '../../orders/data/order_service.dart';
import '../data/ticket_service.dart';
import 'ticket_detail_screen.dart';
import '../../profile/data/profile_service.dart';

const double _kServiceFee = 0.10; // 10 % — espejo exacto de la PWA

class BuyTicketScreen extends StatefulWidget {
  final Event event;
  const BuyTicketScreen({super.key, required this.event});

  @override
  State<BuyTicketScreen> createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  // ── State ──────────────────────────────────────────────────
  int _step = 1; // 1 resumen | 2 stripe | 3 ok
  bool _procesando = false;
  String? _error;
  String? _ordenId;

  // ── Pricing helpers ────────────────────────────────────────
  double get _precioBase => widget.event.precio;
  double get _tarifa     => double.parse((_precioBase * _kServiceFee).toStringAsFixed(2));
  double get _total      => double.parse((_precioBase + _tarifa).toStringAsFixed(2));

  // ── Helpers ────────────────────────────────────────────────
  Future<String> _getUsuarioId() async {
    final token = await TokenService().getToken();
    if (token == null) throw Exception('Sin sesión');
    final parts = token.split('.');
    final payload = parts[1];
    final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
    final claims  = jsonDecode(decoded) as Map<String, dynamic>;
    final sub = claims['sub'] as String?;
    if (sub == null || sub.isEmpty) throw Exception('Token inválido');
    return sub;
  }

  // ── Paso 1 → 2/3: Iniciar compra ──────────────────────────
  Future<void> _handleContinuar() async {
    setState(() { _procesando = true; _error = null; });
    try {
      final usuarioId = await _getUsuarioId();

      // ── Evento gratuito: saltar Stripe ──
      if (widget.event.esGratuito || _precioBase == 0) {
        final orden = await OrderService.crearOrden(
          usuarioId: usuarioId,
          eventoId:  widget.event.id,
          montoTotal: 0,
        );
        _ordenId = orden['id'] as String;
        await _crearTicketYNavegar(usuarioId);
        return;
      }

      // ── Evento de pago: crear orden → PaymentIntent → PaymentSheet ──
      final orden = await OrderService.crearOrden(
        usuarioId:  usuarioId,
        eventoId:   widget.event.id,
        montoTotal: _total,
      );
      _ordenId = orden['id'] as String;

      final pago = await OrderService.iniciarPago(_ordenId!);
      final clientSecret = pago['client_secret'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName:       'Aurae',
          style:                     ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary:     AppColors.primary,
              background:  AppColors.bg,
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Stripe confirmó el pago — crear ticket
      setState(() => _step = 2);
      await _crearTicketYNavegar(usuarioId);
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // Usuario canceló el sheet — no es error
        setState(() { _procesando = false; });
        return;
      }
      setState(() { _error = e.error.localizedMessage ?? 'Error en el pago'; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted && _step != 3) setState(() => _procesando = false);
    }
  }

  Future<void> _crearTicketYNavegar(String usuarioId) async {
    try {
      final ticket = await TicketService.createTicket(
        usuarioId: usuarioId,
        eventoId:  widget.event.id,
        ordenId:   _ordenId!,
        precio:    _precioBase,
      );
      if (!mounted) return;
      setState(() => _step = 3);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)),
      );
    } catch (e) {
      setState(() { _error = 'Pago recibido pero hubo un problema al crear el ticket. Contacta soporte.'; _procesando = false; });
    }
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.nav,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Comprar Ticket',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: () {
        if (_step == 3 || (_step == 2 && _procesando)) return _buildLoadingConfirm();
        return _buildResumen();
      }(),
    );
  }

  // ── Paso 1: Resumen ────────────────────────────────────────
  Widget _buildResumen() {
    final esGratis = widget.event.esGratuito || _precioBase == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del evento
          if (widget.event.imagenUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.event.imagenUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          const SizedBox(height: 20),

          Text(widget.event.nombre,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(widget.event.ubicacionNombre,
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),

          const SizedBox(height: 24),

          // Desglose de precios
          _buildPriceCard(esGratis),

          const SizedBox(height: 16),

          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.primary, fontSize: 13))),
                ],
              ),
            ),

          if (_error != null) const SizedBox(height: 12),

          // Botón principal
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _procesando ? null : AppColors.brandGradient,
                color: _procesando ? AppColors.faint : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _procesando ? [] : [
                  BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _procesando ? null : _handleContinuar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor:     Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _procesando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(
                        esGratis ? Icons.confirmation_number_rounded : Icons.credit_card_rounded,
                        color: Colors.white,
                      ),
                label: Text(
                  _procesando
                      ? 'Procesando…'
                      : esGratis
                          ? 'Obtener Ticket Gratis'
                          : 'Pagar \$${_total.toStringAsFixed(2)} MXN',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),

          if (!esGratis) ...const [
            SizedBox(height: 12),
            Center(
              child: Text(
                'Pago seguro con Stripe · No guardamos datos de tarjeta',
                style: TextStyle(fontSize: 10, color: AppColors.faint),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceCard(bool esGratis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Entrada general × 1',
            value: esGratis ? 'Gratis' : '\$${_precioBase.toStringAsFixed(2)} MXN',
          ),
          if (!esGratis) ...[ 
            const SizedBox(height: 10),
            _buildPriceRow(
              icon: Icons.receipt_long_outlined,
              label: 'Tarifa de servicio (10%)',
              value: '\$${_tarifa.toStringAsFixed(2)} MXN',
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
                Text(
                  '\$${_total.toStringAsFixed(2)} MXN',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
        Text(value, style: const TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Loading / confirmación ─────────────────────────────────
  Widget _buildLoadingConfirm() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Confirmando tu ticket…', style: TextStyle(color: AppColors.muted, fontSize: 15)),
        ],
      ),
    );
  }
}
