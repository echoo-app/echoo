import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'state_manager.dart';

class OllamaService {
  final StateManager _stateManager;
  static const int MAX_CHARS = 30000;

  OllamaService(this._stateManager);

  // 获取Ollama的基础URL
  String get _baseUrl => _stateManager.ollamaAddress;

  // 创建一个配置了基础URL的Dio实例
  Dio _createDio() {
    return Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  // 发送消息到Ollama模型并获取响应
  Future<String> sendMessage({
    required String model, 
    required String message,
  }) async {
    try {
      final prompt = _stateManager.prompt;
      String systemPrompt = '';
      
      // 如果有提示词，添加系统提示词
      if (prompt.isNotEmpty) {
        systemPrompt = prompt;
      }

      // 构建历史消息
      String context = '';
      if (_stateManager.messages.isNotEmpty) {
        context = _stateManager.messages
            .map((msg) => "${msg['role'] == 'user' ? 'Human' : 'Assistant'}: ${msg['content']}")
            .join("\n\n");
      }

      // 检查总字数
      if (context.length > MAX_CHARS) {
        // 提取需要总结的消息（保留最新的一半）
        final messages = _stateManager.messages;
        final splitIndex = messages.length ~/ 2;
        final messagesToSummarize = messages.sublist(0, splitIndex);
        
        // 构建总结请求
        final summaryPrompt = "请总结以下对话的关键信息，保持简洁但不遗漏重要内容：\n\n" +
          messagesToSummarize.map((msg) => "${msg['role'] == 'user' ? 'Human' : 'Assistant'}: ${msg['content']}").join("\n\n");
        
        // 请求总结
        final dio = _createDio();
        final summaryResponse = await dio.post(
          '/api/generate',
          data: {
            'model': model,
            'prompt': summaryPrompt,
            'stream': false
          },
        );

        if (summaryResponse.statusCode == 200) {
          final summaryContent = summaryResponse.data['response'];
          
          // 重建上下文
          context = "前文总结：$summaryContent\n\n" +
            messages.sublist(splitIndex)
                .map((msg) => "${msg['role'] == 'user' ? 'Human' : 'Assistant'}: ${msg['content']}")
                .join("\n\n");
        }
      }

      // 构建完整的提示词
      String fullPrompt = '';
      if (systemPrompt.isNotEmpty) {
        fullPrompt += "System: $systemPrompt\n\n";
      }
      if (context.isNotEmpty) {
        fullPrompt += "$context\n\n";
      }
      fullPrompt += "Human: $message\n\nAssistant:";

      // 发送消息到Ollama
      final dio = _createDio();
      final response = await dio.post(
        '/api/generate',
        data: {
          'model': model,
          'prompt': fullPrompt,
          'stream': false
        },
      );

      if (response.statusCode == 200) {
        return response.data['response'];
      } else {
        throw Exception('Failed to get response from Ollama: ${response.data}');
      }
    } catch (e) {
      print('Error communicating with Ollama: $e');
      return '无法连接到Ollama服务';
    }
  }

  // 获取可用的模型列表
  Future<List<String>> getAvailableModels() async {
    try {
      print('Fetching models from Ollama at: $_baseUrl/api/tags');
      
      final dio = _createDio();
      final response = await dio.get('/api/tags');

      print('Ollama response status: ${response.statusCode}');
      print('Ollama response body: ${response.data}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = response.data;
          if (data.containsKey('models')) {
            final List<dynamic> models = data['models'];
            final modelNames = models
                .where((model) => model is Map && model.containsKey('name'))
                .map((model) => model['name'].toString())
                .toList();
            print('Found models: $modelNames');
            return modelNames;
          } else {
            print('No models field in response');
            return [];
          }
        } catch (e) {
          print('JSON parsing error: $e');
          print('Raw response: ${response.data}');
          rethrow;
        }
      } else {
        print('Error response from Ollama: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to get models from Ollama');
      }
    } catch (e, stackTrace) {
      print('Error fetching Ollama models: $e');
      print('Stack trace: $stackTrace');
      if (e is FormatException) {
        print('JSON parsing error: ${e.message}');
      }
      return [];
    }
  }
}
