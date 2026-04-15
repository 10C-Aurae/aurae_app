import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../theme/app_colors.dart';
import '../../../core/config/env.dart';
import '../../chat/models/stand_chat_message.dart';

/// Pantalla de chat para el staff de un stand.
/// Muestra todos los mensajes de todos los usuarios y permite responder
/// a cada uno con para_usuario_id.
class StaffChatScreen extends StatefulWidget {
  final String standId;
  final String standNombre;
  final String token;

  const StaffChatScreen({
    super.key,
    required this.standId,
    required this.standNombre,
    required this.token,
  });

  @override
  State<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends State<StaffChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  WebSocketChannel? _ws;
  List<StandChatMessage> _messages = [];
  bool _loading = true;
  bool _connected = false;
  Timer? _pollTimer;

  // Cuando el staff pulsa "Responder" en un mensaje de usuario
  String? _replyToUserId;
  String? _replyToName;

  static String get _wsBase =>
      Env.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.token}',
  };

  @override
  void initState() {
    super.initState();
    _loadHistorial();
    _connectWS();
    // Poll de respaldo cada 8 s por si el WS falla
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_connected) _loadHistorial(silent: true);
    });
  }

  @override
  void dispose() {
    _ws?.sink.close();
    _pollTimer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistorial({bool silent = false}) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/v1/chat-stand/${widget.standId}/mensajes?limit=100'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _messages = data.map((j) => StandChatMessage.fromJson(j)).toList();
            _loading = false;
          });
          if (!silent) _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _connectWS() {
    try {
      final uri = Uri.parse(
          '$_wsBase/api/v1/chat-stand/ws/${widget.standId}?token=${widget.token}');
      _ws = WebSocketChannel.connect(uri);
      if (mounted) setState(() => _connected = true);

      _ws!.stream.listen(
        (data) {
          try {
            final msg = StandChatMessage.fromJson(jsonDecode(data as String));
            if (mounted) {
              setState(() {
                if (!_messages.any((m) => m.id == msg.id)) _messages.add(msg);
              });
              _scrollToBottom();
            }
          } catch (_) {}
        },
        onError: (_) {
          if (mounted) setState(() => _connected = false);
        },
        onDone: () {
          if (mounted) setState(() => _connected = false);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();

    final body = <String, dynamic>{'texto': text};
    if (_replyToUserId != null) body['para_usuario_id'] = _replyToUserId;

    if (_ws != null && _connected) {
      _ws!.sink.add(jsonEncode(body));
    } else {
      try {
        final response = await http.post(
          Uri.parse('${Env.baseUrl}/api/v1/chat-stand/${widget.standId}/mensajes'),
          headers: _headers,
          body: jsonEncode(body),
        );
        if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
          final msg = StandChatMessage.fromJson(jsonDecode(response.body));
          setState(() {
            if (!_messages.any((m) => m.id == msg.id)) _messages.add(msg);
          });
          _scrollToBottom();
        }
      } catch (_) {}
    }

    if (mounted) setState(() { _replyToUserId = null; _replyToName = null; });
  }

  void _setReply(StandChatMessage msg) {
    setState(() {
      _replyToUserId = msg.usuarioId;
      _replyToName   = msg.nombreUsuario ?? 'Usuario';
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
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
            Text(widget.standNombre,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
            const Text('Pedidos y mensajes',
                style: TextStyle(fontSize: 10, color: AppColors.faint)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.muted),
            onPressed: _loadHistorial,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(
              _connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 18,
              color: _connected ? Colors.green : AppColors.muted,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded, size: 48, color: AppColors.faint),
                            SizedBox(height: 12),
                            Text('Sin mensajes aún',
                                style: TextStyle(color: AppColors.faint, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('Los pedidos de los asistentes aparecerán aquí',
                                style: TextStyle(color: AppColors.faint, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _StaffBubble(
                          msg: _messages[i],
                          onReply: _setReply,
                        ),
                      ),
          ),

          // Reply context banner
          if (_replyToName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Respondiendo a $_replyToName',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() { _replyToUserId = null; _replyToName = null; }),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
                  ),
                ],
              ),
            ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            decoration: const BoxDecoration(
              color: AppColors.nav,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: AppColors.ink, fontSize: 14),
                    onSubmitted: (_) => _send(),
                    maxLength: 500,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: _replyToName != null
                          ? 'Responder a $_replyToName…'
                          : 'Responder a todos…',
                      hintStyle: const TextStyle(color: AppColors.faint, fontSize: 13),
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

// ── Bubble para el staff ───────────────────────────────────────────────────────

class _StaffBubble extends StatelessWidget {
  final StandChatMessage msg;
  final void Function(StandChatMessage) onReply;

  const _StaffBubble({required this.msg, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final isStaff = msg.esStaff;
    final nombre  = msg.nombreUsuario ?? (isStaff ? 'Staff' : 'Usuario');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isStaff ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isStaff) ...[
            // User avatar circle with initial
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surface,
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isStaff ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isStaff)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text(nombre,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: AppColors.muted)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isStaff ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isStaff ? 16 : 4),
                      bottomRight: Radius.circular(isStaff ? 4 : 16),
                    ),
                    border: isStaff ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    msg.texto,
                    style: TextStyle(
                      fontSize: 13,
                      color: isStaff ? Colors.white : AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                ),
                // Reply button only on user messages
                if (!isStaff)
                  TextButton.icon(
                    onPressed: () => onReply(msg),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.reply_rounded, size: 12, color: AppColors.muted),
                    label: const Text('Responder',
                        style: TextStyle(fontSize: 10, color: AppColors.muted)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
