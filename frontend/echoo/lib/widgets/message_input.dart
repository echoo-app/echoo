import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import '../l10n/strings.dart';
import 'dart:io';
import 'dart:io' show Platform;
import 'alert_dialog_helper.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAddNew;
  final Function(File file)? onFileSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAddNew,
    this.onFileSend,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showFeaturePanel = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter;
      final isShiftPressed = event.isShiftPressed;

      if (isEnterPressed && !isShiftPressed) {
        // 阻止默认的换行行为
        _focusNode.unfocus();
        
        if (widget.controller.text.isNotEmpty) {
          widget.onSend();
        }
      }
    }
  }

  Future<void> _handleCameraPress() async {
    final ImagePicker picker = ImagePicker();
    final lang = Provider.of<StateManager>(context, listen: false).selectedLanguage;
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null && widget.onFileSend != null) {
        widget.onFileSend!(File(image.path));
        setState(() {
          _showFeaturePanel = false;
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (mounted) {
        AlertDialogHelper.showMessage(
          context,
          AppStrings.getString('cameraNotAvailable', lang),
        );
      }
    }
  }

  Future<void> _handleFilePress() async {
    final lang = Provider.of<StateManager>(context, listen: false).selectedLanguage;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && widget.onFileSend != null) {
        final file = File(result.files.single.path!);
        widget.onFileSend!(file);
        setState(() {
          _showFeaturePanel = false;
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      if (mounted) {
        AlertDialogHelper.showMessage(
          context,
          AppStrings.getString('fileSelectFailed', lang),
        );
      }
    }
  }

  Widget _buildFeaturePanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _showFeaturePanel ? 60 : 0,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 16),
              // 只在非 macOS 平台显示相机按钮
              if (!Platform.isMacOS) ...[
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: _handleCameraPress,
                  style: ButtonStyle(
                    overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: const Icon(Icons.folder, color: Colors.white),
                onPressed: _handleFilePress,
                style: ButtonStyle(
                  overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        final lang = stateManager.selectedLanguage;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RawKeyboardListener(
              focusNode: FocusNode(),  // 使用单独的 FocusNode 用于键盘事件监听
              onKey: _handleKeyEvent,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,  // 将主要的 _focusNode 附加到 TextField
                scrollController: _scrollController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppStrings.getString('enterMessage', lang),
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF2C2E36),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 加载指示器
                        if (stateManager.isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF39FF14),
                              strokeWidth: 2.0,
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, color: Color(0xFF39FF14), size: 20),
                          onPressed: () {
                            if (widget.controller.text.isNotEmpty) {
                              widget.onSend();
                            }
                          },
                          padding: EdgeInsets.zero,
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
              ),
            ),
            _buildFeaturePanel(),
          ],
        );
      },
    );
  }
}
