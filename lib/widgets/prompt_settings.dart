import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import '../l10n/strings.dart';
import 'settings_section_card.dart';

class PromptSettings extends StatelessWidget {
  final TextEditingController controller;

  const PromptSettings({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        final lang = stateManager.selectedLanguage;
        
        return SettingsSectionCard(
          title: AppStrings.getString('prompt', lang),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: AppStrings.getString('promptHint', lang),
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              stateManager.updateSettings(prompt: value);
            },
          ),
        );
      },
    );
  }
}
