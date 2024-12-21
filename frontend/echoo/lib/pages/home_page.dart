import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import '../services/ollama_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/alert_dialog_helper.dart';
import 'settings_page.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late OllamaService _ollamaService;

  @override
  void initState() {
    super.initState();
    final stateManager = Provider.of<StateManager>(context, listen: false);
    _ollamaService = OllamaService(stateManager);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _addNew() {
    print('新增');
  }

  void _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _clearMessages() {
    final stateManager = Provider.of<StateManager>(context, listen: false);
    stateManager.clearMessages();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _getMimeType(String fileExtension) {
    final mimeTypes = {
      // 图片格式
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.heic': 'image/heic',
      '.heif': 'image/heif',
      // 文档格式
      '.pdf': 'application/pdf',
      // 视频格式
      '.mp4': 'video/mp4',
      '.webm': 'video/webm',
      '.mov': 'video/quicktime',
      // 音频格式
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.ogg': 'audio/ogg',
      '.m4a': 'audio/mp4'
    };
    return mimeTypes[fileExtension] ?? '';
  }

  Future<String> _processFile(File file) async {
    String fileName = path.basename(file.path);
    String fileExtension = path.extension(fileName).toLowerCase();
    String mimeType = _getMimeType(fileExtension);
    
    if (mimeType.isEmpty) {
      throw Exception('不支持的文件类型。支持的格式包括：\n'
          '- 图片：JPEG, PNG, GIF, WebP, HEIC/HEIF\n'
          '- 文档：PDF\n'
          '- 视频：MP4, WebM, MOV\n'
          '- 音频：MP3, WAV, OGG, M4A');
    }

    try {
      List<int> fileBytes = await file.readAsBytes();
      String base64Data = base64Encode(fileBytes);
      return 'data:$mimeType;base64,$base64Data';
    } catch (e) {
      throw Exception('文件处理失败，请重试');
    }
  }

  void _handleAuthenticationError(StateManager stateManager) async {
    await stateManager.logout();
    if (mounted) {
      AlertDialogHelper.showMessage(context, '认证已过期，请重新登录');
      _navigateToSettings();
    }
  }

  Future<void> _handleFileSend(File file) async {
    final stateManager = Provider.of<StateManager>(context, listen: false);
    
    try {
      String processedContent = await _processFile(file);
      
      stateManager.addMessage(processedContent, isUser: true);
      stateManager.setLoading(true);
      _scrollToBottom();

      if (!stateManager.isLoggedIn && stateManager.selectedService == ServiceOption.echoo) {
        throw Exception("使用Echoo服务需要登录");
      }

      if (stateManager.selectedService == ServiceOption.ollama) {
        if (stateManager.selectedModel.isEmpty) {
          throw Exception('请先在设置中选择一个模型');
        }
        final response = await _ollamaService.sendMessage(
          model: stateManager.selectedModel,
          message: processedContent,
        );
        stateManager.addMessage(response, isUser: false);
      } else {
        try {
          final dio = stateManager.createDio();
          final headers = await stateManager.getAuthHeaders();
          dio.options.headers.addAll(headers);
          final response = await dio.post(
            '/api/chat',
            data: {
              'content': processedContent,
              'prompt': stateManager.prompt,
              'history': stateManager.messages.map((msg) => {
                'role': msg['role'],
                'content': msg['content']
              }).toList(),
            },
          );

          if (response.statusCode == 200) {
            final result = response.data;
            await stateManager.updateApiCalls(result['remaining_calls']);
            
            stateManager.addMessage(
              result['content'],
              isUser: false,
              cost: result['cost_calls'].toDouble(),
              actualCost: result['actual_cost_calls'].toDouble(),
              promptTokens: result['prompt_tokens'],
              completionTokens: result['completion_tokens'],
              totalTokens: result['total_tokens'],
            );
          } else if (response.statusCode == 401) {
            _handleAuthenticationError(stateManager);
            throw Exception('认证已过期，请重新登录');
          } else {
            String errorMessage = response.data['error'];
            if (errorMessage.contains('Insufficient API calls')) {
              AlertDialogHelper.showMessage(context, '调用次数不足，请充值后继续使用');
              return;
            }
            AlertDialogHelper.showMessage(context, errorMessage);
            return;
          }
        } catch (e) {
          if (e.toString().contains('401')) {
            _handleAuthenticationError(stateManager);
          }
          rethrow;
        }
      }

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        AlertDialogHelper.showMessage(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      stateManager.setLoading(false);
    }
  }

  Future<void> _sendMessage() async {
    final stateManager = Provider.of<StateManager>(context, listen: false);
    
    if (_textController.text.isEmpty) return;

    final message = _textController.text;
    stateManager.addMessage(message, isUser: true);
    stateManager.setLoading(true);
    _textController.clear();
    _scrollToBottom();

    try {
      if (!stateManager.isLoggedIn && stateManager.selectedService == ServiceOption.echoo) {
        throw Exception("使用Echoo服务需要登录");
      }

      if (stateManager.selectedService == ServiceOption.ollama) {
        if (stateManager.selectedModel.isEmpty) {
          throw Exception('请先在设置中选择一个模型');
        }
        final response = await _ollamaService.sendMessage(
          model: stateManager.selectedModel,
          message: message,
        );
        stateManager.addMessage(response, isUser: false);
      } else {
        try {
          final dio = stateManager.createDio();
          final headers = await stateManager.getAuthHeaders();
          dio.options.headers.addAll(headers);
          final response = await dio.post(
            '/api/chat',
            data: {
              'content': message,
              'prompt': stateManager.prompt,
              'history': stateManager.messages.map((msg) => {
                'role': msg['role'],
                'content': msg['content']
              }).toList(),
            },
          );

          if (response.statusCode == 200) {
            final result = response.data;
            await stateManager.updateApiCalls(result['remaining_calls']);
            
            stateManager.addMessage(
              result['content'],
              isUser: false,
              cost: result['cost_calls'].toDouble(),
              actualCost: result['actual_cost_calls'].toDouble(),
              promptTokens: result['prompt_tokens'],
              completionTokens: result['completion_tokens'],
              totalTokens: result['total_tokens'],
            );
          } else if (response.statusCode == 401) {
            _handleAuthenticationError(stateManager);
            throw Exception('认证已过期，请重新登录');
          } else {
            String errorMessage = response.data['error'];
            if (errorMessage.contains('Insufficient API calls')) {
              AlertDialogHelper.showMessage(context, '调用次数不足，请充值后继续使用');
              return;
            }
            AlertDialogHelper.showMessage(context, errorMessage);
            return;
          }
        } catch (e) {
          if (e.toString().contains('401')) {
            _handleAuthenticationError(stateManager);
          }
          rethrow;
        }
      }

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        AlertDialogHelper.showMessage(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      stateManager.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B10),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: _navigateToSettings,
                  ),
                  const Text(
                    'Echoo',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.white),
                    onPressed: _clearMessages,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Consumer<StateManager>(
                  builder: (context, stateManager, child) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      itemCount: stateManager.messages.length,
                      itemBuilder: (context, index) {
                        final message = stateManager.messages[index];
                        return MessageBubble(
                          key: ValueKey('message_${message['content']}_$index'),
                          message: message['content'] ?? '',
                          isUser: message['role'] == 'user',
                          index: index,
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0),
              child: MessageInput(
                controller: _textController,
                onSend: _sendMessage,
                onAddNew: _addNew,
                onFileSend: _handleFileSend,
              ),
            ),
          ],
        ),
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
