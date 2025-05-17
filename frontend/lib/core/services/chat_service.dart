import 'package:flutter/foundation.dart';
import 'http_service.dart' as http;

class ChatService {
  final http.HttpService _httpService = http.HttpService(baseUrl: "http://10.0.2.2:8888");
  static const String _sendMessageEndpoint = "/send_message";
  static const String _getMessagesEndpoint = "/messages";

  Future<Map<String, dynamic>> sendMessage(String userId, String message) async {
    try {
      final response = await _httpService.request(
        endpoint: _sendMessageEndpoint,
        method: 'POST',
        body: {
          "userId": userId,
          "message": message,
        },
      );
      
      if (response.containsKey("error")) {
        throw Exception(response["error"]);
      }
      
      return response;
    } catch (e) {
      debugPrint('Error sending message: $e');

      return {
        "chatBotReply": {
          "text": "I'm sorry, I can't access the server right now. Please try again later.",
        }
      };
    }
  }

  Future<List<dynamic>> getMessages(String userId) async {
    try {
      final response = await _httpService.request(
        endpoint: _getMessagesEndpoint,
        method: 'POST',
        body: {
          "userId": userId,
        },
      );
      
      if (response.containsKey("error")) {
        throw Exception(response["error"]);
      }
      
      List<dynamic> messagesList = [];
      
      if (response.containsKey("messages")) {
        final messages = response["messages"];
        if (messages is List) {
          messagesList = messages;
        }
      }
      else if (response.containsKey("0")) {
        int i = 0;
        while (response.containsKey(i.toString())) {
          messagesList.add(response[i.toString()]);
          i++;
        }
      }
      else {
        try {
          final list = response["data"] ?? [];
          if (list is List) {
            messagesList = list;
          }
        } catch (e) {
          debugPrint('Error parsing messages: $e');
        }
      }
      
      return messagesList;
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }
}