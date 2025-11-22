import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../providers/service_providers.dart';

class AIChatbotPage extends ConsumerStatefulWidget {
  const AIChatbotPage({super.key});

  @override
  ConsumerState<AIChatbotPage> createState() => _AIChatbotPageState();
}

class _AIChatbotPageState extends ConsumerState<AIChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _sessionId;
  bool _showError = false;
  bool _needsSession = false;
  bool _sendFailed = false;
  String? _lastSentText;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final healthy = await ref.read(chatbotServiceProvider).checkHealth();
      if (!healthy) {
        if (mounted) setState(() => _showError = true);
        debugPrint('chatbot: health check failed');
      } else {
        debugPrint('chatbot: health check ok');
      }
      final sessionManager = ref.read(sessionManagerProvider);
      final sid = await sessionManager.getSessionId();
      if (sid == null) {
        if (mounted) setState(() { _needsSession = true; _sessionId = null; });
        debugPrint('chatbot: no stored session id, showing create-session UI');
      } else {
        if (mounted) setState(() => _sessionId = sid);
        debugPrint('chatbot: restoring session: $sid');
        try {
          final history = await ref.read(chatbotServiceProvider).getHistory(sid);
          if (mounted && history.isNotEmpty) {
            setState(() => _messages.addAll(history));
          }
          debugPrint('chatbot: history messages loaded: ${history.length}');
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {}

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) return;
    _lastSentText = messageText;

    if (_sessionId == null) {
      setState(() { _needsSession = true; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a session to start chatting')),
      );
      debugPrint('chatbot: blocked send — no session id');
      return;
    }

    // Add user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isLoading = true;
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final chatbotService = ref.read(chatbotServiceProvider);
      final reply = await chatbotService.sendMessage(_sessionId!, messageText);
      debugPrint('chatbot: backend reply length: ${reply.length}');
      if (reply.contains('Session not found') || reply.contains('Too many requests')) {
        setState(() {
          _isTyping = false;
          _sendFailed = true;
        });
        debugPrint('chatbot: send failed: $reply');
      } else if (reply.isNotEmpty) {
        final aiMessage = Message(
          id: '${DateTime.now().millisecondsSinceEpoch}_ai',
          role: 'assistant',
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(aiMessage);
          _isTyping = false;
        });
        debugPrint('chatbot: message appended');
      } else {
        final errorMessage = Message(
          id: '${DateTime.now().millisecondsSinceEpoch}_error',
          role: 'assistant',
          text: 'Sorry, I\'m having trouble responding right now. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(errorMessage);
          _isTyping = false;
          _sendFailed = true;
        });
        debugPrint('chatbot: empty reply, showing error');
      }
    } catch (e) {
      // Handle network or other errors
      final errorMessage = Message(
        id: '${DateTime.now().millisecondsSinceEpoch}_error',
        role: 'assistant',
        text: 'Sorry, I encountered an error. Please check your connection and try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isTyping = false;
        _sendFailed = true;
      });
      debugPrint('chatbot: send error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(sessionManagerProvider).clearSessionId();
              setState(() {
                _messages.clear();
                _sessionId = null;
                _needsSession = true;
                _sendFailed = false;
              });
              debugPrint('chatbot: session cleared');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Chat'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showError)
            Container(
              width: double.infinity,
              color: Colors.red.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Assistant is currently unavailable',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final healthy = await ref.read(chatbotServiceProvider).checkHealth();
                      if (mounted) setState(() => _showError = !healthy);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          if (_needsSession)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text('No active session'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final healthy = await ref.read(chatbotServiceProvider).checkHealth();
                        if (!healthy) {
                          if (mounted) setState(() => _showError = true);
                          debugPrint('chatbot: health check failed on create-session');
                          return;
                        }
                        final created = await ref.read(chatbotServiceProvider).createSession();
                        final sid = created['session_id']?.toString();
                        if (sid != null) {
                          debugPrint('chatbot: new session created: $sid');
                          await ref.read(sessionManagerProvider).saveSession(sid);
                          if (mounted) setState(() { _sessionId = sid; _needsSession = false; });
                          debugPrint('chatbot: session initialized');
                        }
                      },
                      child: const Text('Create Session'),
                    ),
                  ],
                ),
              ),
            ),
          if (!_needsSession && _sendFailed)
            Container(
              width: double.infinity,
              color: Colors.orange.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Message failed. You can retry or start a new session.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_lastSentText != null) {
                        _messageController.text = _lastSentText!;
                        _sendFailed = false;
                        _sendMessage();
                      }
                    },
                    child: const Text('Resend'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref.read(sessionManagerProvider).clearSession();
                      setState(() {
                        _messages.clear();
                        _sessionId = null;
                        _needsSession = true;
                        _sendFailed = false;
                      });
                      _addWelcomeMessage();
                    },
                    child: const Text('New Session'),
                  ),
                ],
              ),
            ),
          // Chat messages
          if (!_needsSession)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _TypingIndicator();
                }

                final message = _messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          
          
          
          // Message input
          if (!_needsSession)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask about dog health, behavior, nutrition, or first aid',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: message.isUser
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomLeft: message.isUser ? const Radius.circular(20) : Radius.zero,
              bottomRight: message.isUser ? Radius.zero : const Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TypingDot(delay: 0),
              const SizedBox(width: 4),
              const _TypingDot(delay: 200),
              const SizedBox(width: 4),
              const _TypingDot(delay: 400),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}