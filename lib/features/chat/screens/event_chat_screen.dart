import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/config/env.dart';
import '../models/chat_message.dart';

class EventChatScreen extends StatefulWidget {
  final String eventoId;
  final String eventoNombre;

  const EventChatScreen({
    super.key,
    required this.eventoId,
    required this.eventoNombre,
  });

  @override
  State<EventChatScreen> createState() => _EventChatScreenState();
}

class _EventChatScreenState extends State<EventChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  WebSocketChannel? _ws;
  String? _token;
  String? _userId;

  final List<ChatMessage> _messages = [];
  bool _connected = false;
  bool _loading = true;
  String? _wsError;

  static String get _wsBase =>
      Env.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _token = await TokenService().getToken();
    if (_token == null) return;

    // Decode userId from JWT (simple base64 decode of payload)
    try {
      final parts = _token!.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _userId = data['sub'];
      }
    } catch (_) {}

    await _loadHistorial();
    _connectWS();
  }

  Future<void> _loadHistorial() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/v1/chat/${widget.eventoId}/historial?limit=50'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _messages.addAll(data.map((j) => ChatMessage.fromJson(j)));
            _loading = false;
          });
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _connectWS() {
    if (_token == null) return;
    try {
      final uri = Uri.parse('$_wsBase/api/v1/chat/ws/${widget.eventoId}?token=$_token');
      _ws = WebSocketChannel.connect(uri);
      if (mounted) setState(() => _connected = true);

      _ws!.stream.listen(
        (data) {
          try {
            final msg = ChatMessage.fromJson(jsonDecode(data as String));
            if (mounted) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          } catch (_) {}
        },
        onError: (e) {
          if (mounted) setState(() { _connected = false; _wsError = 'Error de conexión'; });
        },
        onDone: () {
          if (mounted) setState(() => _connected = false);
        },
      );
    } catch (e) {
      if (mounted) setState(() { _wsError = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _ws?.sink.close();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _ws == null) return;
    _ws!.sink.add(jsonEncode({'texto': text}));
    _controller.clear();
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
            Text(widget.eventoNombre,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
            const Text('Sala compartida con asistentes',
                style: TextStyle(fontSize: 11, color: AppColors.faint)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _connected ? Colors.green : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _connected ? 'En línea' : 'Desconectado',
                  style: TextStyle(fontSize: 11, color: _connected ? Colors.green : AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_wsError != null)
            Container(
              color: AppColors.primary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(_wsError!, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('Sé el primero en escribir algo ✌️',
                            style: TextStyle(color: AppColors.muted)),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _Bubble(
                          msg: _messages[i],
                          isOwn: _messages[i].usuarioId == _userId,
                        ),
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
                    controller: _controller,
                    style: const TextStyle(color: AppColors.ink, fontSize: 14),
                    onSubmitted: (_) => _send(),
                    maxLength: 500,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje…',
                      hintStyle: const TextStyle(color: AppColors.faint, fontSize: 13),
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.card,
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
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _connected ? _send : null,
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _connected ? AppColors.primary : AppColors.faint,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isOwn;

  const _Bubble({required this.msg, required this.isOwn});

  Color get _auraColor {
    final hex = msg.auraColor;
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Name row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isOwn) ...[
                  Text(msg.nombreUsuario,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  if (msg.arquetipo != null) ...[
                    const SizedBox(width: 4),
                    Text(msg.arquetipo!,
                        style: const TextStyle(fontSize: 10, color: AppColors.faint)),
                  ],
                ] else ...[
                  if (msg.arquetipo != null) ...[
                    Text(msg.arquetipo!,
                        style: const TextStyle(fontSize: 10, color: AppColors.faint)),
                    const SizedBox(width: 4),
                  ],
                  Text(msg.nombreUsuario,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Bubble with aura-colored border
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isOwn ? 16 : 2),
                bottomRight: Radius.circular(isOwn ? 2 : 16),
              ),
              border: Border.all(color: _auraColor, width: 1.5),
            ),
            child: Text(msg.texto,
                style: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.4)),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _formatTime(msg.createdAt),
              style: const TextStyle(fontSize: 10, color: AppColors.faint),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
