// chatbot_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/theme_provider.dart'; // Import your theme provider

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false; 
  
  // Theme provider instance
  final ThemeProvider _themeProvider = ThemeProvider();
  
  // Modern color palette - now dynamic based on theme
  Color get _accentColor => const Color(0xFF5C8A94); // Keep your accent color
  Color get _backgroundColor => _themeProvider.darkModeEnabled 
      ? const Color(0xFF121212) 
      : const Color(0xFFF8FAFC);
  Color get _surfaceColor => _themeProvider.darkModeEnabled 
      ? const Color(0xFF1E1E1E) 
      : Colors.white;
  Color get _textColor => _themeProvider.darkModeEnabled 
      ? const Color(0xFFE1E1E1) 
      : const Color(0xFF1E293B);
  Color get _lightTextColor => _themeProvider.darkModeEnabled 
      ? const Color(0xFFA0A0A0) 
      : const Color(0xFF64748B);
  
  final GroqService _groqService = GroqService(
    apiKey: 'YOUR_API_KEY_HERE', 
  );

  // Listen to theme changes
  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_onThemeChanged);
    _initializeTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeTheme() async {
    if (!_themeProvider.isInitialized) {
      await _themeProvider.initialize();
    }
  }

  void _onThemeChanged() {
    setState(() {}); // Rebuild when theme changes
  }

  // Responsive sizing methods
  double get _horizontalPadding => _responsiveValue(16.0, 20.0, 24.0);
  double get _verticalPadding => _responsiveValue(12.0, 16.0, 20.0);
  double get _avatarSize => _responsiveValue(32.0, 36.0, 40.0);
  double get _iconSize => _responsiveValue(16.0, 18.0, 20.0);
  double get _fontSizeBody => _responsiveValue(14.0, 15.0, 16.0);
  double get _fontSizeSmall => _responsiveValue(12.0, 14.0, 15.0);
  double get _sendButtonSize => _responsiveValue(48.0, 56.0, 64.0);
  double get _bubbleRadius => _responsiveValue(16.0, 20.0, 24.0);
  double get _inputBorderRadius => _responsiveValue(20.0, 24.0, 28.0);

  double _responsiveValue(double small, double medium, double large) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return small;    // Small phones
    if (screenWidth < 400) return medium;   // Medium phones
    return large;                           // Large phones
  }

  bool get _isSmallScreen => MediaQuery.of(context).size.width < 360;

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

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMessage);
    });

    _textController.clear();
    _scrollToBottom();

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    // Get AI response from Groq
    _groqService.generateResponse(text).then((response) {
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
      _scrollToBottom();
    }).catchError((e) {
      final errorMessage = ChatMessage(
        text: 'Error: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
      _scrollToBottom();
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  void _toggleTheme() {
    _themeProvider.toggleDarkMode(!_themeProvider.darkModeEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'AI Support',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: _responsiveValue(18.0, 20.0, 22.0),
            color: _textColor,
          ),
        ),
        backgroundColor: _surfaceColor,
        elevation: 0,
        foregroundColor: _textColor,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              _themeProvider.darkModeEnabled ? Icons.light_mode : Icons.dark_mode,
              color: _accentColor,
              size: _iconSize,
            ),
            onPressed: _toggleTheme,
            tooltip: _themeProvider.darkModeEnabled ? 'Switch to light mode' : 'Switch to dark mode',
          ),
          IconButton(
            icon: Icon(Icons.clear_all, color: _accentColor, size: _iconSize),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _backgroundColor,
                    _backgroundColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(_horizontalPadding),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return MessageBubble(
                      message: _messages[index],
                      accentColor: _accentColor,
                      backgroundColor: _backgroundColor,
                      surfaceColor: _surfaceColor,
                      textColor: _textColor,
                      lightTextColor: _lightTextColor,
                      avatarSize: _avatarSize,
                      iconSize: _iconSize,
                      bubbleRadius: _bubbleRadius,
                      fontSizeBody: _fontSizeBody,
                    );
                  } else {
                    return _buildLoadingIndicator();
                  }
                },
              ),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.all(_horizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _avatarSize,
            height: _avatarSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentColor.withOpacity(0.8),
                  _accentColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy, color: Colors.white, size: _iconSize),
          ),
          SizedBox(width: _isSmallScreen ? 8 : 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(_horizontalPadding),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(_bubbleRadius),
                  bottomLeft: Radius.circular(_bubbleRadius),
                  bottomRight: Radius.circular(_bubbleRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    ),
                  ),
                  SizedBox(width: _isSmallScreen ? 8 : 12),
                  Text(
                    'Thinking...',
                    style: TextStyle(
                      color: _lightTextColor,
                      fontSize: _fontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(_horizontalPadding),
      decoration: BoxDecoration(
        color: _surfaceColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 12,
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(_inputBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: _lightTextColor, fontSize: _fontSizeBody),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: _horizontalPadding,
                      vertical: _verticalPadding,
                    ),
                  ),
                  style: TextStyle(color: _textColor, fontSize: _fontSizeBody),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: _isSmallScreen ? 8 : 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentColor.withOpacity(0.9),
                    _accentColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(_bubbleRadius),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(_bubbleRadius),
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    width: _sendButtonSize,
                    height: _sendButtonSize,
                    padding: EdgeInsets.all(_isSmallScreen ? 8 : 12),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.send, color: Colors.white, size: _iconSize),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Models
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// Updated Groq Service with current models
class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String apiKey;
  
  GroqService({required this.apiKey});

  // Test the API key with current models
  Future<bool> testApiKey() async {
    final currentModels = [
      'llama-3.1-8b-instant',
      'llama-3.1-70b-versatile',
      'mixtral-8x7b-32768',
      'gemma2-9b-it'
    ];

    for (final model in currentModels) {
      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'messages': [
              {'role': 'user', 'content': 'Hello, test message'}
            ],
            'model': model,
            'max_tokens': 10,
          }),
        );

        print('Testing model: $model - Status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          print('✅ Groq API Key is VALID with model: $model');
          return true;
        } else if (response.statusCode == 400) {
          final errorData = json.decode(response.body);
          if (errorData['error']['code'] == 'model_decommissioned') {
            print('⚠️ Model $model is decommissioned, trying next...');
            continue;
          }
        }
      } catch (e) {
        print('❌ Error testing model $model: $e');
        continue;
      }
    }
    
    print('❌ No working models found with this API key');
    return false;
  }

  Future<String> generateResponse(String message) async {
    // Try current available models in order
    final models = [
      'llama-3.1-8b-instant',      // Fast, efficient
      'llama-3.1-70b-versatile',   // High quality
      'mixtral-8x7b-32768',        // Mixture of experts
      'gemma2-9b-it',              // Google's model
    ];

    for (final model in models) {
      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'messages': [
              {
                'role': 'user',
                'content': message,
              }
            ],
            'model': model,
            'temperature': 0.7,
            'max_tokens': 1024,
            'stream': false,
          }),
        );

        print('Trying model: $model - Status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final content = data['choices'][0]['message']['content'];
          print('✅ Success with model: $model');
          return content;
        } else if (response.statusCode == 400) {
          final errorData = json.decode(response.body);
          if (errorData['error']['code'] == 'model_decommissioned') {
            print('⚠️ Model $model is decommissioned, trying next...');
            continue;
          }
        } else if (response.statusCode == 401) {
          throw Exception('Invalid Groq API key. Please check your API key.');
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        }
      } catch (e) {
        print('❌ Error with model $model: $e');
        continue;
      }
    }
    
    throw Exception('All models failed. Please check your API key and try again.');
  }
}

// Updated MessageBubble with responsive design and theme support
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color lightTextColor;
  final double avatarSize;
  final double iconSize;
  final double bubbleRadius;
  final double fontSizeBody;

  const MessageBubble({
    super.key,
    required this.message,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.lightTextColor,
    required this.avatarSize,
    required this.iconSize,
    required this.bubbleRadius,
    required this.fontSizeBody,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 6.0 : 8.0),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) 
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.8),
                    accentColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: iconSize),
            ),
          if (!message.isUser) SizedBox(width: isSmallScreen ? 8 : 12),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? accentColor 
                    : surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(bubbleRadius),
                  topRight: Radius.circular(bubbleRadius),
                  bottomLeft: Radius.circular(message.isUser ? bubbleRadius : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : bubbleRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: message.isUser ? Colors.white : textColor,
                    fontSize: fontSizeBody,
                    height: 1.4,
                  ),
                  code: TextStyle(
                    color: message.isUser ? Colors.white : textColor,
                    backgroundColor: message.isUser 
                        ? Colors.white.withOpacity(0.1) 
                        : backgroundColor,
                  ),
                ),
              ),
            ),
          ),
          if (message.isUser) SizedBox(width: isSmallScreen ? 8 : 12),
          if (message.isUser)
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.8),
                    Colors.green,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.white, size: iconSize),
            ),
        ],
      ),
    );
  }
}