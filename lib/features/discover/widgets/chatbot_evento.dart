import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../aura_flow/data/aura_flow_service.dart';

/// Burbuja flotante + panel de chat del evento.
/// Úsalo como [floatingActionButton] del Scaffold del detalle de evento.
class ChatbotEvento extends StatefulWidget {
  final String eventoId;
  final String eventoNombre;

  const ChatbotEvento({
    super.key,
    required this.eventoId,
    required this.eventoNombre,
  });

  @override
  State<ChatbotEvento> createState() => _ChatbotEventoState();
}

class _ChatbotEventoState extends State<ChatbotEvento>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    // Micro-bounce en el FAB
    _scaleCtrl.reverse().then((_) => _scaleCtrl.forward());

    final token = await TokenService().getToken();
    if (token == null || !mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChatPanel(
        eventoId: widget.eventoId,
        eventoNombre: widget.eventoNombre,
        token: token,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: FloatingActionButton(
        onPressed: _open,
        backgroundColor: AppColors.primary,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.chat_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

// ── Panel de chat ─────────────────────────────────────────────────────────────

class _ChatPanel extends StatefulWidget {
  final String eventoId;
  final String eventoNombre;
  final String token;

  const _ChatPanel({
    required this.eventoId,
    required this.eventoNombre,
    required this.token,
  });

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final _service = AuraFlowService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<_Msg> _messages = [];
  bool _loading = false;
  bool _historyLoading = true;

  static const _sugeridas = [
    '¿Dónde están los baños?',
    '¿Hay acceso para personas con discapacidad?',
    '¿A qué hora inicia el evento?',
    '¿Dónde está el estacionamiento?',
    '¿Hay servicio de guardarropa?',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _service.historialChat(widget.token, widget.eventoId);
      if (!mounted) return;
      if (history.isEmpty) {
        _messages = [_Msg.bot('¡Hola! 👋 Soy Aura, el asistente de "${widget.eventoNombre}". ¿Qué necesitas saber?')];
      } else {
        _messages = history
            .map((m) => m.role == 'user' ? _Msg.user(m.contenido) : _Msg.bot(m.contenido))
            .toList();
      }
    } catch (_) {
      if (mounted) {
        _messages = [_Msg.bot('¡Hola! 👋 Soy Aura, el asistente de "${widget.eventoNombre}". ¿Qué necesitas saber?')];
      }
    } finally {
      if (mounted) {
        setState(() => _historyLoading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _inputCtrl.text).trim();
    if (text.isEmpty || _loading) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add(_Msg.user(text));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final respuesta = await _service.chat(widget.token, widget.eventoId, text);
      if (mounted) setState(() => _messages.add(_Msg.bot(respuesta)));
    } catch (_) {
      if (mounted) {
        setState(() => _messages.add(_Msg.bot(
          'Tuve un problema. Intenta de nuevo o consulta al staff.',
        )));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.94,
      minChildSize: 0.35,
      builder: (_, __) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 2),
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asistente del evento',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        widget.eventoNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _historyLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) return _TypingBubble();
                      return _MessageBubble(msg: _messages[i]);
                    },
                  ),
          ),

          // Sugerencias (solo cuando hay exactamente 1 mensaje bot y sin conversación)
          if (!_historyLoading && _messages.length == 1 && _messages.first.isBot)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: _sugeridas.map((q) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _send(q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(q, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ),
                  ),
                )).toList(),
              ),
            ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + bottomPad),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    style: const TextStyle(color: AppColors.ink, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Escribe tu pregunta…',
                      hintStyle: const TextStyle(color: AppColors.faint, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _loading ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _loading ? AppColors.faint : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modelo interno ────────────────────────────────────────────────────────────

class _Msg {
  final String text;
  final bool isBot;
  _Msg.bot(this.text) : isBot = true;
  _Msg.user(this.text) : isBot = false;
}

// ── Bubble ────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _Msg msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (msg.isBot) ...[
            Container(
              width: 26, height: 26,
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, size: 13, color: AppColors.primary),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: msg.isBot ? AppColors.surface : AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isBot ? 4 : 16),
                  bottomRight: Radius.circular(msg.isBot ? 16 : 4),
                ),
                border: msg.isBot ? Border.all(color: AppColors.border) : null,
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 13,
                  color: msg.isBot ? AppColors.ink : Colors.white,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 26, height: 26,
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_rounded, size: 13, color: AppColors.primary),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.33;
                    final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
                    final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.25, 1.0);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 4.0 : 0),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: AppColors.muted, shape: BoxShape.circle),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
