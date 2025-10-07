import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<String> _suggestions = [];

  // 🔥 URL corregida
  static const String N8N_WEBHOOK_URL = "http://10.0.2.2:5678/webhook/chatbot-ia";

  @override
  void initState() {
    super.initState();
    _addMessage("¡Hola! 👋 Soy tu asistente de compras deportivas. ¿En qué puedo ayudarte hoy?", false);
    _suggestions = ['Ver productos', 'Buscar zapatillas', 'Camisetas de fútbol', 'Ofertas'];
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Añadir mensaje del usuario
    _addMessage(message, true);
    _controller.clear();
    setState(() {
      _isLoading = true;
      _suggestions = [];
    });

    try {
      print('🔍 Enviando a: $N8N_WEBHOOK_URL');
      print('📤 Mensaje: "$message"');
      
      final requestBody = {
        'message': message,
        'userId': 'user_123',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('📤 Body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(N8N_WEBHOOK_URL),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10)); // Añadir timeout

      print('📥 Status: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final botResponse = data['response'] ?? 'Lo siento, no pude procesar tu mensaje.';
          final suggestions = data['suggestions'] != null 
              ? List<String>.from(data['suggestions']) 
              : <String>[];
          
          _addMessage(botResponse, false);
          setState(() {
            _suggestions = suggestions;
          });
        } catch (jsonError) {
          print('❌ Error JSON: $jsonError');
          _addMessage('❌ Error al procesar la respuesta del servidor.', false);
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        _addMessage('❌ Error del servidor: ${response.statusCode}', false);
      }
    } on http.ClientException catch (e) {
      print('❌ Error de conexión: $e');
      _addMessage('🔌 Error de conexión. ¿Está n8n ejecutándose?', false);
    } on FormatException catch (e) {
      print('❌ Error de formato: $e');
      _addMessage('❌ Respuesta inválida del servidor.', false);
    } catch (e) {
      print('❌ Error general: $e');
      _addMessage('❌ Error inesperado: $e', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text, 
        isUser: isUser, 
        timestamp: DateTime.now()
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(_suggestions[index]),
              onPressed: () {
                print('🎯 Sugerencia seleccionada: ${_suggestions[index]}');
                _sendMessage(_suggestions[index]);
              },
              backgroundColor: Colors.blue[50],
              side: BorderSide(color: Colors.blue[200]!),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 Asistente de Compras'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),
          
          // Indicador de escritura
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('El asistente está escribiendo...'),
                ],
              ),
            ),

          // Sugerencias rápidas
          if (_suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSuggestions(),
            ),

          // Campo de entrada
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: _isLoading ? null : (value) {
                      print('📝 Mensaje escrito: "$value"');
                      _sendMessage(value);
                    },
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  mini: true,
                  onPressed: _isLoading ? null : () {
                    print('🔘 Botón enviar presionado');
                    _sendMessage(_controller.text);
                  },
                  backgroundColor: _isLoading ? Colors.grey[300] : Colors.blue[600],
                  child: Icon(
                    Icons.send,
                    color: _isLoading ? Colors.grey[600] : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text, 
    required this.isUser, 
    required this.timestamp
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({required this.message, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue[600],
              child: const Text('🤖', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue[600] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(6),
                  bottomRight: message.isUser ? const Radius.circular(6) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[400],
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}