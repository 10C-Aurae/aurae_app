import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/config/env.dart';
import '../models/stand_chat_message.dart';

class StandChatScreen extends StatefulWidget {
  final String standId;
  final String standNombre;
  final String? standImageUrl;

  const StandChatScreen({
    super.key,
    required this.standId,
    required this.standNombre,
    this.standImageUrl,
  });

  @override
  State<StandChatScreen> createState() => _StandChatScreenState();
}

class _StandChatScreenState extends State<StandChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  WebSocketChannel? _ws;
  String? _token;
  String? _userId;

  final List<StandChatMessage> _messages = [];
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
        Uri.parse('${Env.baseUrl}/api/v1/chat-stand/${widget.standId}/mensajes?limit=80'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _messages.addAll(data.map((j) => StandChatMessage.fromJson(j)));
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
      final uri = Uri.parse('$_wsBase/api/v1/chat-stand/ws/${widget.standId}?token=$_token');
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

  Future<void> _sendFallback(String texto) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/v1/chat-stand/${widget.standId}/mensajes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'texto': texto}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final msg = StandChatMessage.fromJson(jsonDecode(response.body));
        if (mounted) {
          setState(() {
            if (!_messages.any((m) => m.id == msg.id)) _messages.add(msg);
          });
          _scrollToBottom();
        }
      }
    } catch (_) {}
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
    if (text.isEmpty) return;
    _controller.clear();

    if (_ws != null && _connected) {
      _ws!.sink.add(jsonEncode({'texto': text}));
    } else {
      _sendFallback(text);
    }
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
        title: Row(
          children: [
            if (widget.standImageUrl != null && widget.standImageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(widget.standImageUrl!, width: 34, height: 34, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 34, height: 34)),
              ),
              const SizedBox(width: 10),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.standNombre,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
                const Text('Pedidos y preguntas al stand',
                    style: TextStyle(fontSize: 10, color: AppColors.faint)),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
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
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                              child: const Icon(Icons.shopping_bag_outlined, size: 26, color: AppColors.faint),
                            ),
                            const SizedBox(height: 12),
                            const Text('Envía tu pedido', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
                            const SizedBox(height: 4),
                            const Text('Escribe lo que quieres ordenar\ny el staff te responderá',
                                style: TextStyle(color: AppColors.muted, fontSize: 13), textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _StandBubble(
                          msg: _messages[i],
                          isOwn: !_messages[i].esStaff && _messages[i].usuarioId == _userId,
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
                      hintText: 'Escribe tu pedido o pregunta…',
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
                  onTap: _send,
                  child: Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
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

class _StandBubble extends StatelessWidget {
  final StandChatMessage msg;
  final bool isOwn;

  const _StandBubble({required this.msg, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    Color bubbleColor;
    Color textColor = AppColors.ink;

    if (isOwn) {
      bubbleColor = AppColors.primary.withOpacity(0.15);
    } else if (msg.esStaff) {
      bubbleColor = Colors.green.withOpacity(0.15);
      textColor = Colors.green.shade300;
    } else {
      bubbleColor = AppColors.surface;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              msg.esStaff ? '🧑‍🍳 Staff' : (msg.nombreUsuario ?? 'Usuario'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isOwn ? 16 : 2),
                bottomRight: Radius.circular(isOwn ? 2 : 16),
              ),
              border: Border.all(
                color: msg.esStaff ? Colors.green.withOpacity(0.3) : AppColors.border,
              ),
            ),
            child: Text(msg.texto, style: TextStyle(color: textColor, fontSize: 14, height: 1.4)),
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
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
