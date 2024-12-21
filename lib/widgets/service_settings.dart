import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import '../l10n/strings.dart';

class ServiceSettings extends StatelessWidget {
  final Function() onEchooSelected;
  final Function() onOllamaSelected;
  final TextEditingController ollamaAddressController;
  final List<String> availableModels;
  final bool isLoadingModels;

  const ServiceSettings({
    super.key,
    required this.onEchooSelected,
    required this.onOllamaSelected,
    required this.ollamaAddressController,
    required this.availableModels,
    required this.isLoadingModels,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        final lang = stateManager.selectedLanguage;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.getString('selectService', lang),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFF2C2E36),
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.white.withOpacity(0.1),
                          highlightColor: Colors.white.withOpacity(0.1),
                          onTap: onEchooSelected,
                          child: ListTile(
                            title: const Text(
                              'Echoo',
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: Icon(
                              stateManager.selectedService == ServiceOption.echoo
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              color: const Color(0xFF39FF14),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.white.withOpacity(0.1),
                          highlightColor: Colors.white.withOpacity(0.1),
                          onTap: onOllamaSelected,
                          child: ListTile(
                            title: const Text(
                              'Ollama',
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: Icon(
                              stateManager.selectedService == ServiceOption.ollama
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              color: const Color(0xFF39FF14),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (stateManager.selectedService == ServiceOption.ollama) ...[
                      const Divider(
                        color: Color(0xFF3A3E4A),
                        height: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.getString('ollamaServiceAddress', lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A3E4A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: ollamaAddressController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: AppStrings.getString('enterOllamaAddressHint', lang),
                                  hintStyle: const TextStyle(color: Colors.grey),
                                ),
                                onChanged: (value) async {
                                  stateManager.updateSettings(ollamaAddress: value);
                                  if (stateManager.selectedService == ServiceOption.ollama) {
                                    onOllamaSelected();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.getString('selectModel', lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A3E4A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: isLoadingModels
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : availableModels.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            AppStrings.getString('noModelsFound', lang),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        )
                                      : DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: stateManager.selectedModel.isEmpty 
                                                ? (availableModels.isNotEmpty ? availableModels.first : null)
                                                : stateManager.selectedModel,
                                            items: availableModels.map((model) {
                                              return DropdownMenuItem<String>(
                                                value: model,
                                                child: Text(
                                                  model,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                stateManager.updateSettings(model: newValue);
                                              }
                                            },
                                            dropdownColor: const Color(0xFF3A3E4A),
                                            isExpanded: true,
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.white,
                                            ),
                                            menuMaxHeight: 300,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
