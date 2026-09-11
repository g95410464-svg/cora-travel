import 'package:flutter/material.dart';
import '../../services/chat_api.dart';
import '../../models/traveler_profile.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen(
      {super.key, required this.profile, this.initialMessage});
  final TravelerProfile profile;
  final String? initialMessage;
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _api = ChatApi();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <({bool isUser, String text})>[];

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) _input.text = widget.initialMessage!;
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _messages.add((isUser: true, text: text));
      _input.clear();
    });
    _scrollDown();
    try {
      final reply = await _api.send(text, widget.profile.id,
          context: widget.profile.toContext());
      if (!mounted) return;
      setState(() => _messages.add((isUser: false, text: reply)));
    } on ChatException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _input.text = text;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollDown();
      }
    }
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });

  @override
  void dispose() {
    _api.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'CORA',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3),
          ),
      leading: const BackButton(),
          backgroundColor: const Color(0xFFF6F8F4),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EL SALVADOR · A TU RITMO',
                          style: TextStyle(
                            color: Color(0xFF007F79),
                            letterSpacing: 2,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Un país pequeño.\nMil formas de descubrirlo.',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Soy CORA, tu compañera de viaje. ¿Qué te gustaría descubrir?',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Align(
                          alignment: message.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 520),
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: message.isUser
                                  ? const Color(0xFFDCEEE6)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: SelectableText(message.text),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('CORA está pensando…'),
                        ],
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            enabled: !_busy,
                            maxLength: 4000,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Cuéntame qué tienes en mente…',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          onPressed: _busy ? null : _send,
                          tooltip: 'Enviar mensaje',
                          icon: const Icon(Icons.arrow_upward),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
