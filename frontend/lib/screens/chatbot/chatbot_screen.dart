import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/chat_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final Map<String, dynamic>? settingsResponse;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    this.settingsResponse,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  
  final List<String> _suggestionChips = [
    "How to find routes?",
    "Change theme",
    "Report an incident",
    "Show air quality"
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _chatService.getMessages("userTest1");
      
      if (messages.isNotEmpty) {
        setState(() {
          _messages.clear();
          
          for (var i = messages.length - 1; i >= 0; i--) {
            final message = messages[i];
            
            if (message is Map<String, dynamic>) {
              if (message.containsKey("userMessage")) {
                _messages.add(ChatMessage(
                  text: message["userMessage"],
                  isUser: true,
                ));
              }
              
              if (message.containsKey("chatBotReply")) {
                final reply = message["chatBotReply"];
                
                if (reply is Map<String, dynamic> && reply.containsKey("text")) {
                  Map<String, dynamic>? settingsResp;
                  if (reply.containsKey("settingsResponse") && 
                      reply["settingsResponse"] is Map<String, dynamic>) {
                    settingsResp = reply["settingsResponse"];
                  }
                  
                  _messages.add(ChatMessage(
                    text: reply["text"],
                    isUser: false,
                    settingsResponse: settingsResp,
                  ));
                }
              }
            }
          }
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: "👋 Hello! I'm your navigation assistant. You can ask me anything about navigation, routes, settings, or features of the app.",
            isUser: false,
          ));
        });
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
      
      setState(() {
        _messages.add(ChatMessage(
          text: "👋 Hello! I'm your navigation assistant. You can ask me anything about navigation, routes, settings, or features of the app.",
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      _scrollToBottom();
    }
  }

  void _handleSubmitted(String text) async {
    _textController.clear();
    
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _isLoading = true;
    });
    
    _scrollToBottom();
    
    try {
      final response = await _chatService.sendMessage("userTest1", text);
      
      if (response.containsKey("chatBotReply")) {
        final chatbotReply = response["chatBotReply"];
        
        if (chatbotReply is Map<String, dynamic>) {
          Map<String, dynamic>? settingsResp;
          
          if (chatbotReply.containsKey("settingsResponse") && 
              chatbotReply["settingsResponse"] is Map<String, dynamic>) {
            settingsResp = chatbotReply["settingsResponse"];
          }
          
          setState(() {
            _messages.add(ChatMessage(
              text: chatbotReply["text"] ?? "I don't understand that.",
              isUser: false,
              settingsResponse: settingsResp,
            ));
          });
        } else if (chatbotReply is String) {
          setState(() {
            _messages.add(ChatMessage(
              text: chatbotReply,
              isUser: false,
            ));
          });
        }
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: "I'm not sure how to respond to that.",
            isUser: false,
          ));
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      String errorMessage = "I'm sorry, I don't know how to respond to that yet. I'm still learning.";
      
      setState(() {
        _messages.add(ChatMessage(
          text: errorMessage,
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      _scrollToBottom();
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSettingsNavigation(Map<String, dynamic>? settingsResponse) {
    if (settingsResponse == null) return;
    
    if (settingsResponse.containsKey("path")) {
      final path = settingsResponse["path"];
      if (path is String && path.isNotEmpty) {
        if (path.startsWith('/')) {
          context.go(path);
        } else {
          context.go('/$path');
        }
      }
    }
  }

  bool _hasValidSettingsPath(Map<String, dynamic>? settingsResponse) {
    if (settingsResponse == null) return false;
    
    if (settingsResponse.containsKey("path")) {
      final path = settingsResponse["path"];
      return path is String && path.isNotEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assistant'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              context.go('/home');
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(8.0),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (_, int index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildLoadingIndicator();
                      }
                      return _buildMessageItem(_messages[index]);
                    },
                  ),
          ),
          if (_messages.isEmpty || _messages.length < 3)
            _buildSuggestionChips(),
          Divider(height: 1.0),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildChatbotAvatar(),
          Flexible(
            child: Container(
              margin: message.isUser 
                  ? EdgeInsets.only(left: 40.0, right: 8.0)
                  : EdgeInsets.only(left: 8.0, right: 40.0),
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.blue.shade600
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (!message.isUser && _hasValidSettingsPath(message.settingsResponse)) ...[
                    SizedBox(height: 8.0),
                    TextButton.icon(
                      onPressed: () => _handleSettingsNavigation(message.settingsResponse),
                      icon: Icon(Icons.settings),
                      label: Text('Open Settings'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildChatbotAvatar() {
    return Container(
      margin: EdgeInsets.only(right: 8.0),
      child: CircleAvatar(
        backgroundColor: Colors.green.shade600,
        child: Icon(
          Icons.assistant,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      margin: EdgeInsets.only(left: 8.0),
      child: CircleAvatar(
        backgroundColor: Colors.blue.shade600,
        child: Icon(
          Icons.person,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: _isLoading ? null : _handleSubmitted,
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                enabled: !_isLoading,
              ),
            ),
          ),
          SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: _isLoading ? null : () => _handleSubmitted(_textController.text),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLoading 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.5) 
                    : Theme.of(context).colorScheme.primary,
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _suggestionChips.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(suggestion),
              onPressed: () => _handleSubmitted(suggestion),
              backgroundColor: Colors.grey.shade200,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChatbotAvatar(),
          Container(
            margin: EdgeInsets.only(left: 8.0, right: 40.0),
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade700),
                  ),
                ),
                SizedBox(width: 8),
                Text('Thinking...', style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 