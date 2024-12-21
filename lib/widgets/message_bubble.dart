import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import '../services/ollama_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MessageBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final int index;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.index,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  Future<void> _copyMessage(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.message));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('复制失败：$e')),
        );
      }
    }
  }

  Future<void> _regenerateMessage(BuildContext context) async {
    final stateManager = Provider.of<StateManager>(context, listen: false);
    
    // 找到上一条用户消息
    final userMessages = stateManager.messages
        .where((msg) => msg['role'] == 'user')
        .toList();
    
    if (userMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有找到用户消息')),
      );
      return;
    }

    final lastUserMessage = userMessages.last['content'] ?? '';

    try {
      // 设置加载状态
      stateManager.setLoading(true);

      if (stateManager.selectedService == ServiceOption.ollama) {
        if (stateManager.selectedModel.isEmpty) {
          throw Exception('请先在设置中选择一个模型');
        }
        final ollamaService = OllamaService(stateManager);
        final response = await ollamaService.sendMessage(
          model: stateManager.selectedModel,
          message: lastUserMessage,
        );
        if (mounted) {
          stateManager.addMessage(response, isUser: false);
        }
      } else {
        if (!stateManager.isLoggedIn) {
          throw Exception('请先在设置中登录');
        }
        
        try {
          final headers = await stateManager.getAuthHeaders();
          final response = await http.post(
            Uri.parse('${StateManager.baseUrl}/api/chat'),
            headers: headers,
            body: jsonEncode({
              'content': lastUserMessage,
              'model_id': stateManager.selectedModel,
              'prompt': stateManager.prompt,
              'history': stateManager.messages,
            }),
          );

          if (response.statusCode == 200) {
            final result = jsonDecode(utf8.decode(response.bodyBytes));
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
            throw Exception('认证已过期，请重新登录');
          } else {
            final errorData = jsonDecode(utf8.decode(response.bodyBytes));
            throw Exception(errorData['error']);
          }
        } catch (e) {
          if (e.toString().contains('401')) {
            await stateManager.logout();
          }
          rethrow;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重新生成失败：$e')),
        );
      }
    } finally {
      stateManager.setLoading(false);
    }
  }

  void _deleteMessage(BuildContext context) {
    final stateManager = Provider.of<StateManager>(context, listen: false);
    stateManager.removeMessageAtIndex(widget.index);
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: MaterialButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        color: Colors.black26,
        shape: const CircleBorder(),
        child: Icon(icon, color: Colors.white, size: 12),
      ),
    );
  }

  Widget _buildFilePreview(String mimeType, Uint8List data) {
    if (mimeType.startsWith('image/')) {
      return Image.memory(
        data,
        fit: BoxFit.contain,
        width: 200,
      );
    } else if (mimeType == 'application/pdf') {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, 
              color: widget.isUser ? Colors.black : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'PDF 文档',
              style: TextStyle(
                color: widget.isUser ? Colors.black : Colors.white,
                fontSize: Provider.of<StateManager>(context).fontSize,
              ),
            ),
          ],
        ),
      );
    } else if (mimeType.startsWith('video/')) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_file, 
              color: widget.isUser ? Colors.black : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '视频文件',
              style: TextStyle(
                color: widget.isUser ? Colors.black : Colors.white,
                fontSize: Provider.of<StateManager>(context).fontSize,
              ),
            ),
          ],
        ),
      );
    } else if (mimeType.startsWith('audio/')) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.audio_file, 
              color: widget.isUser ? Colors.black : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '音频文件',
              style: TextStyle(
                color: widget.isUser ? Colors.black : Colors.white,
                fontSize: Provider.of<StateManager>(context).fontSize,
              ),
            ),
          ],
        ),
      );
    }
    
    return Text(
      '不支持的文件类型',
      style: TextStyle(
        color: widget.isUser ? Colors.black : Colors.white,
        fontSize: Provider.of<StateManager>(context).fontSize,
      ),
    );
  }

  Widget _buildMessageContent() {
    // 检查是否是 base64 文件
    if (widget.message.startsWith('data:')) {
      try {
        // 提取 MIME 类型和 base64 数据
        final mimeTypeEnd = widget.message.indexOf(';');
        if (mimeTypeEnd == -1) return Text('文件格式错误');
        
        final mimeType = widget.message.substring(5, mimeTypeEnd);
        final startIndex = widget.message.indexOf('base64,') + 7;
        final base64Data = widget.message.substring(startIndex);
        final fileData = base64Decode(base64Data);
        
        return _buildFilePreview(mimeType, fileData);
      } catch (e) {
        return Text(
          '文件加载失败',
          style: TextStyle(
            color: widget.isUser ? Colors.black : Colors.white,
            fontSize: Provider.of<StateManager>(context).fontSize,
          ),
        );
      }
    }
    
    // 普通文本消息
    return Text(
      widget.message,
      style: TextStyle(
        color: widget.isUser ? Colors.black : Colors.white,
        fontSize: Provider.of<StateManager>(context).fontSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        final isSelected = stateManager.selectedMessageIndex == widget.index;
        final message = stateManager.messages[widget.index];

        return GestureDetector(
          onTap: () {
            if (!widget.isUser) {
              stateManager.setSelectedMessageIndex(isSelected ? null : widget.index);
            }
          },
          child: Container(
            margin: EdgeInsets.only(
              bottom: isSelected ? 8.0 : 8.0,
              left: widget.isUser ? 32.0 : 8.0,
              right: widget.isUser ? 8.0 : 32.0,
            ),
            child: Column(
              crossAxisAlignment: 
                  widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isUser ? Color(0xFF00FF00) : const Color(0xFF2C2E36),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: _buildMessageContent(),
                ),
                if (!widget.isUser && isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.refresh,
                          onPressed: () => _regenerateMessage(context),
                        ),
                        _buildActionButton(
                          icon: Icons.copy,
                          onPressed: () => _copyMessage(context),
                        ),
                        _buildActionButton(
                          icon: Icons.delete,
                          onPressed: () => _deleteMessage(context),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
