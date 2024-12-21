import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ollama_service.dart';
import '../services/state_manager.dart';
import '../widgets/font_size_settings.dart';
import '../widgets/service_settings.dart';
import '../widgets/prompt_settings.dart';
import '../widgets/auth_settings.dart';
import '../widgets/user_info_card.dart';
import '../widgets/language_settings.dart';
import '../l10n/strings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late OllamaService _ollamaService;
  List<String> _availableOllamaModels = [];
  bool _isLoadingModels = false;
  late TextEditingController _ollamaAddressController;
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    final stateManager = Provider.of<StateManager>(context, listen: false);
    _ollamaService = OllamaService(stateManager);
    _ollamaAddressController = TextEditingController(
      text: stateManager.ollamaAddress
    );
    _promptController = TextEditingController(
      text: stateManager.prompt
    );

    if (stateManager.selectedService == ServiceOption.ollama) {
      Future.microtask(() => _loadOllamaModels());
    }
  }

  @override
  void dispose() {
    _ollamaAddressController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _refreshUserInfo() async {
    final stateManager = Provider.of<StateManager>(context, listen: false);
    if (stateManager.isLoggedIn) {
      await stateManager.refreshUserInfo();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<List<String>> _loadOllamaModels() async {
    setState(() {
      _isLoadingModels = true;
    });

    try {
      if (_ollamaAddressController.text.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _availableOllamaModels = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.getString('enterOllamaAddress', context.read<StateManager>().selectedLanguage)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return [];
      }

      final models = await _ollamaService.getAvailableModels();
      if (mounted) {
        setState(() {
          _availableOllamaModels = models;
        });
        
        if (models.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.getString('noOllamaModels', context.read<StateManager>().selectedLanguage)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return models;
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableOllamaModels = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.getString('connectionFailed', context.read<StateManager>().selectedLanguage)}: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF090B10),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 80.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ServiceSettings(
                        onEchooSelected: () {
                          stateManager.updateSettings(
                            service: ServiceOption.echoo,
                          );
                        },
                        onOllamaSelected: () async {
                          stateManager.updateSettings(
                            service: ServiceOption.ollama,
                          );
                          
                          final models = await _loadOllamaModels();
                          
                          if (mounted) {
                            if (models.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppStrings.getString('ollamaNotAvailable', stateManager.selectedLanguage)),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              stateManager.updateSettings(model: models.first);
                            }
                          }
                        },
                        ollamaAddressController: _ollamaAddressController,
                        availableModels: _availableOllamaModels,
                        isLoadingModels: _isLoadingModels,
                      ),
                      const SizedBox(height: 16),
                      PromptSettings(controller: _promptController),
                      const SizedBox(height: 16),
                      const FontSizeSettings(),
                      const SizedBox(height: 16),
                      const LanguageSettings(),
                      const SizedBox(height: 16),
                      const UserInfoCard(),
                      if (!stateManager.isLoggedIn) ...[
                        const SizedBox(height: 16),
                        const AuthSettings(),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFF090B10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Text(
                          AppStrings.getString('settings', stateManager.selectedLanguage),
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
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
