import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../data/aura_flow_service.dart';
import '../models/aura_flow_models.dart';

class AuraFlowScreen extends StatefulWidget {
  final String eventoId;
  final String eventoNombre;

  const AuraFlowScreen({
    super.key,
    required this.eventoId,
    required this.eventoNombre,
  });

  @override
  State<AuraFlowScreen> createState() => _AuraFlowScreenState();
}

class _AuraFlowScreenState extends State<AuraFlowScreen> {
  final AuraFlowService _service = AuraFlowService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

  AuraFlowResponse? _ruta;
  bool _loading = false;
  bool _chatLoading = false;
  String? _error;
  final List<AuraFlowChatMessage> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _generarRuta();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Future<void> _generarRuta() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await TokenService().getToken();
      if (token == null) throw Exception('Sin sesión');
      final ruta = await _service.recomendar(token, widget.eventoId);
      if (mounted) setState(() { _ruta = ruta; _loading = false; });
      // Load chat history
      _loadHistorial(token);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadHistorial(String token) async {
    try {
      final hist = await _service.historialChat(token, widget.eventoId);
      if (mounted && hist.isNotEmpty) {
        setState(() => _chatMessages.addAll(hist));
        _scrollChat();
      }
    } catch (_) {}
  }

  Future<void> _sendChat() async {
    final pregunta = _chatController.text.trim();
    if (pregunta.isEmpty) return;

    _chatController.clear();
    setState(() {
      _chatMessages.add(AuraFlowChatMessage(role: 'user', contenido: pregunta));
      _chatLoading = true;
    });
    _scrollChat();

    try {
      final token = await TokenService().getToken();
      if (token == null) throw Exception('Sin sesión');
      final respuesta = await _service.chat(token, widget.eventoId, pregunta);
      if (mounted) {
        setState(() {
          _chatMessages.add(AuraFlowChatMessage(role: 'assistant', contenido: respuesta));
          _chatLoading = false;
        });
        _scrollChat();
      }
    } catch (e) {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  void _scrollChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.nav,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.brandGradient.createShader(b),
              child: const Text('Aura Flow',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            Text(widget.eventoNombre,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.muted),
            tooltip: 'Regenerar ruta',
            onPressed: _loading ? null : _generarRuta,
          ),
        ],
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        children: [
                          // Intro message
                          if (_ruta!.mensajeIntro != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.secondary.withOpacity(0.12),
                                    AppColors.primary.withOpacity(0.06),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.secondary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(_ruta!.mensajeIntro!,
                                        style: const TextStyle(color: AppColors.ink, fontSize: 13, height: 1.5)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Route steps
                          const Text('Tu ruta personalizada',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                  color: AppColors.muted, letterSpacing: 0.8)),
                          const SizedBox(height: 12),
                          ..._ruta!.recomendaciones.asMap().entries.map(
                            (e) => _StandStep(stand: e.value, isLast: e.key == _ruta!.recomendaciones.length - 1),
                          ),

                          const SizedBox(height: 28),

                          // Chat section header
                          Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.muted),
                              const SizedBox(width: 6),
                              const Text('Pregúntale a la IA sobre el evento',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                      color: AppColors.muted, letterSpacing: 0.8)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Chat messages
                          if (_chatMessages.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Text(
                                '¿Tienes dudas sobre la ruta o el evento? Escribe aquí y la IA te responderá.',
                                style: TextStyle(color: AppColors.faint, fontSize: 13),
                              ),
                            )
                          else
                            SizedBox(
                              height: 240,
                              child: ListView.builder(
                                controller: _chatScroll,
                                itemCount: _chatMessages.length + (_chatLoading ? 1 : 0),
                                itemBuilder: (_, i) {
                                  if (i == _chatMessages.length) return _buildTypingIndicator();
                                  return _ChatBubble(msg: _chatMessages[i]);
                                },
                              ),
                            ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),

                    // Chat input pinned at bottom
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
                      decoration: const BoxDecoration(
                        color: AppColors.nav,
                        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              style: const TextStyle(color: AppColors.ink, fontSize: 14),
                              onSubmitted: (_) => _sendChat(),
                              decoration: InputDecoration(
                                hintText: 'Pregunta sobre el evento...',
                                hintStyle: const TextStyle(color: AppColors.faint, fontSize: 13),
                                filled: true,
                                fillColor: AppColors.card,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _chatLoading ? null : _sendChat,
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                gradient: _chatLoading ? null : AppColors.brandGradient,
                                color: _chatLoading ? AppColors.faint : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _chatLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
              boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.4), blurRadius: 40)],
            ),
            child: const Icon(Icons.route_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (b) => AppColors.brandGradient.createShader(b),
            child: const Text('Generando tu ruta...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          const Text('La IA está personalizando tu experiencia', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _generarRuta,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36, height: 36,
            child: CircleAvatar(backgroundColor: AppColors.surface,
                child: Icon(Icons.auto_awesome, size: 16, color: AppColors.secondary)),
          ),
          SizedBox(width: 8),
          Text('Escribiendo...', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Route step widget ──────────────────────────────────────────
class _StandStep extends StatelessWidget {
  final AuraFlowStand stand;
  final bool isLast;

  const _StandStep({required this.stand, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline ───────────────────────────────────────
          Column(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)],
                ),
                child: Center(
                  child: Text(
                    '${stand.orden}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 4)),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // ── Card ───────────────────────────────────────────
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stand.nombre,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  if (stand.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(stand.descripcion,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (stand.motivo != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(stand.motivo!,
                                style: const TextStyle(fontSize: 11, color: AppColors.secondary, height: 1.3),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat bubble ────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final AuraFlowChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14, backgroundColor: AppColors.surface,
              child: Icon(Icons.auto_awesome, size: 14, color: AppColors.secondary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary.withOpacity(0.15) : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 2),
                  bottomRight: Radius.circular(isUser ? 2 : 12),
                ),
                border: Border.all(color: isUser ? AppColors.primary.withOpacity(0.3) : AppColors.border),
              ),
              child: Text(msg.contenido,
                  style: TextStyle(
                      color: isUser ? AppColors.ink : AppColors.ink,
                      fontSize: 13, height: 1.4)),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
