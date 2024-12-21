import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import '../l10n/strings.dart';
import 'settings_section_card.dart';

class FontSizeSettings extends StatelessWidget {
  const FontSizeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        final lang = stateManager.selectedLanguage;
        
        return SettingsSectionCard(
          title: AppStrings.getString('fontSize', lang),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                AppStrings.getStringWithArgs('fontSizeValue', lang, [stateManager.fontSize.toStringAsFixed(0)]),
                style: const TextStyle(color: Colors.white),
              ),
              Expanded(
                child: Slider(
                  value: stateManager.fontSize,
                  min: 12.0,
                  max: 20.0,
                  divisions: 8,
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey,
                  onChanged: (double value) {
                    stateManager.updateSettings(fontSize: value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
