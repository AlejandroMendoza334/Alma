import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_flow/views/widgets/breathing_exercise_card.dart';
import '../features/affirmations/data/models/models.dart';
import '../services/ai_service.dart';
import '../services/ai_exceptions.dart';
import '../services/theme.dart';

enum ChatMessageType { text, breathingCard }

class ExtendedChatMessage {
  final String role;
  final String content;
  final ChatMessageType type;
  final Function(String feedback)? onBreathingCompleted; // Callback para cuando termine o se detenga

  ExtendedChatMessage({
    required this.role,
    required this.content,
    this.type = ChatMessageType.text,
    this.onBreathingCompleted,
  });
}

class ChatView extends StatefulWidget {
  final ProviderAI provider;
  final String apiKey;
  final String? initialMoodContext;
  final Function(ViewState) onNavigate;

  // Opcional: si quieres persistir o recibir un historial externo
  static List<ExtendedChatMessage> globalChatHistory = [];

  const ChatView({
    super.key,
    required this.provider,
    required this.apiKey,
    this.initialMoodContext,
    required this.onNavigate,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late List<ExtendedChatMessage> _messages;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    // Recuperamos el historial global o inicializamos uno nuevo si está vacío
    if (ChatView.globalChatHistory.isNotEmpty) {
      _messages = ChatView.globalChatHistory;
    } else {
      _messages = [];
      _initializeChat();
    }
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    // Guardamos el historial en la variable estática para que no se pierda al salir
    ChatView.globalChatHistory = _messages;
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    if (widget.initialMoodContext != null && widget.initialMoodContext!.trim().isNotEmpty) {
      final mood = widget.initialMoodContext!;
      _messages.add(ExtendedChatMessage(role: 'user', content: 'Hola, hoy me siento $mood.'));
      _messages.add(
        ExtendedChatMessage(
          role: 'assistant',
          content: 'Hola. Veo que hoy te sientes "$mood". Lamento mucho que estés pasando por un momento difícil. Estoy aquí para escucharte y darte un espacio seguro, sin juzgarte. ¿Te gustaría contarme un poco más sobre qué es lo que te hace sentir así?',
        ),
      );
    } else {
      _messages.add(
        ExtendedChatMessage(
          role: 'assistant',
          content: 'Hola, soy Alma. Estoy aquí para ofrecerte un espacio seguro y tranquilo. ¿De qué te gustaría hablar hoy?',
        ),
      );
    }
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (widget.apiKey.isEmpty) {
      _showMissingApiKeyDialog();
      return;
    }

    setState(() {
      _messages.add(ExtendedChatMessage(role: 'user', content: text));
      if (customText == null) {
        _controller.clear();
      }
      _isLoading = true;
    });
    _scrollToBottom();

    final lowerText = text.toLowerCase();
    bool triggersBreathing = lowerText.contains('respirar') ||
        lowerText.contains('ansiedad') ||
        lowerText.contains('estresado') ||
        lowerText.contains('calmar');

    try {
      // Solo se reenvían los últimos turnos (y solo los de texto real, sin
      // las tarjetas de respiración) — antes se mandaba TODO el historial
      // acumulado desde que se abrió la app, así que una sola respuesta
      // rara o fuera de tema se quedaba contaminando cada mensaje
      // siguiente para siempre, hasta cerrar la app.
      const maxHistoryMessages = 20;
      final textMessages = _messages.where((m) => m.type == ChatMessageType.text).toList();
      final recentMessages = textMessages.length > maxHistoryMessages
          ? textMessages.sublist(textMessages.length - maxHistoryMessages)
          : textMessages;
      final standardMessages = recentMessages.map((m) => ChatMessage(role: m.role, content: m.content)).toList();

      final response = await AIService.callAI(
        provider: widget.provider,
        apiKey: widget.apiKey,
        messages: standardMessages,
        moodContext: widget.initialMoodContext,
      );

      // 🛡️ VERIFICACIÓN CLAVE: Si el usuario salió de la vista, no ejecutamos setState
      if (!mounted) return;

      setState(() {
        _messages.add(ExtendedChatMessage(role: 'assistant', content: response));

        if (triggersBreathing) {
          _messages.add(
            ExtendedChatMessage(
              role: 'assistant',
              content: 'Tómate un par de minutos. Hagamos juntos un ejercicio de respiración para bajar las revoluciones:',
              type: ChatMessageType.breathingCard,
              onBreathingCompleted: (feedbackState) {
                String replyMessage;
                if (feedbackState == 'better') {
                  replyMessage = '¡Qué bueno leer eso! Me alegra que la respiración te haya ayudado a centrarte. ¿Continuamos conversando o prefieres descansar un momento?';
                } else if (feedbackState == 'stopped') {
                  replyMessage = 'Entiendo perfectamente que hayas decidido detenerlo. No hay presión, ¿quieres que conversemos sobre lo que sientes o prefieres hacer otra cosa?';
                } else {
                  replyMessage = 'Entiendo perfectamente, a veces la tensión no se va a la primera. ¿Quieres que conversemos sobre qué te agobia?';
                }

                // 🛠️ CORRECCIÓN: Añadirlo directamente como asistente sin simular que lo escribiste tú
                setState(() {
                  _messages.add(ExtendedChatMessage(role: 'assistant', content: replyMessage));
                });
                _scrollToBottom();
              },
            ),
          );
        }
      });
    } on AIException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ExtendedChatMessage(role: 'assistant', content: e.message));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ExtendedChatMessage(
            role: 'assistant',
            content: 'Ocurrió un inconveniente inesperado al procesar tu mensaje.',
          ),
        );
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _resetConversation() {
    setState(() {
      _messages = [];
      ChatView.globalChatHistory = [];
      _initializeChat();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showMissingApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AlmaTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('API Key Requerida', style: GoogleFonts.lora(color: Colors.white)),
        content: Text(
          'Para conversar con Alma necesitas ingresar tu clave API en configuración.',
          style: GoogleFonts.nunito(color: AlmaTheme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.nunito(color: AlmaTheme.mutedForeground)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onNavigate(ViewState.settings);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AlmaTheme.primary,
              foregroundColor: AlmaTheme.primaryForeground,
            ),
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AlmaTheme.background,
            Color(0xFF17152E),
            Color(0xFF121020),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildChatHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildThinkingBubble();
                }

                final message = _messages[index];
                final isUser = message.role == 'user';

                // Si es una tarjeta de respiración, renderizamos el diseño especial
                if (message.type == ChatMessageType.breathingCard) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: GoogleFonts.nunito(fontSize: 13, color: AlmaTheme.mutedForeground, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        BreathingExerciseCard(
                          onFinished: (feltBetter) {
                            if (message.onBreathingCompleted != null) {
                              message.onBreathingCompleted!(feltBetter ? 'better' : 'same');
                            }
                          },
                          onStopped: () {
                            if (message.onBreathingCompleted != null) {
                              message.onBreathingCompleted!('stopped');
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }

                return _buildMessageBubble(message, isUser);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: AlmaTheme.card.withOpacity(0.6),
        border: Border(bottom: BorderSide(color: AlmaTheme.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          _buildAvatar(size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alma', style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  'Tu espacio seguro para hablar',
                  style: GoogleFonts.nunito(fontSize: 11.5, color: AlmaTheme.mutedForeground),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _resetConversation,
            tooltip: 'Nueva conversación',
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AlmaTheme.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({double size = 40}) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/alma_icon.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.auto_awesome_rounded, color: AlmaTheme.primary, size: size * 0.7),
      ),
    );
  }

  Widget _buildMessageBubble(ExtendedChatMessage message, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _buildAvatar(size: 34),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AlmaTheme.primary, Color(0xFF6A3FE0)],
                          )
                        : null,
                    color: isUser ? null : AlmaTheme.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: AlmaTheme.border.withOpacity(0.5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: (isUser ? AlmaTheme.primary : Colors.black).withOpacity(isUser ? 0.25 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      height: 1.5,
                      color: isUser ? AlmaTheme.primaryForeground : Colors.white.withOpacity(0.95),
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 4),
            ],
          ),
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: _CopyButton(text: message.content),
            ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          _buildAvatar(size: 34),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AlmaTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AlmaTheme.border.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AlmaTheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Alma está reflexionando...',
                  style: GoogleFonts.nunito(fontSize: 12.5, color: AlmaTheme.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AlmaTheme.card.withOpacity(0.95),
        border: Border(top: BorderSide(color: AlmaTheme.border.withOpacity(0.4), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 46),
                decoration: BoxDecoration(
                  color: AlmaTheme.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AlmaTheme.border.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.nunito(color: Colors.white, fontSize: 14.5),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Cuéntale a Alma cómo te sientes...',
                    hintStyle: GoogleFonts.nunito(color: AlmaTheme.mutedForeground, fontSize: 13.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _hasText && !_isLoading
                      ? const [AlmaTheme.primary, Color(0xFF6A3FE0)]
                      : [AlmaTheme.border, AlmaTheme.border],
                ),
                boxShadow: _hasText && !_isLoading
                    ? [BoxShadow(color: AlmaTheme.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))]
                    : null,
              ),
              child: IconButton(
                onPressed: _hasText && !_isLoading ? () => _sendMessage() : null,
                icon: Icon(Icons.send_rounded, color: _hasText ? Colors.white : AlmaTheme.mutedForeground, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Botón de copiar bajo los mensajes de Alma. Estado propio y aislado por
// mensaje para que el ícono cambie a "Copiado" solo en el que se tocó, sin
// afectar al resto de la conversación.
class _CopyButton extends StatefulWidget {
  final String text;

  const _CopyButton({required this.text});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copied ? null : _handleCopy,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 14,
              color: _copied ? Colors.greenAccent : AlmaTheme.mutedForeground,
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? 'Copiado' : 'Copiar',
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: _copied ? Colors.greenAccent : AlmaTheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
