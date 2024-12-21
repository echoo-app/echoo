import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import '../l10n/strings.dart';

class LanguageSettings extends StatelessWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        // 定义所有支持的语言
        final languages = [
          {'code': 'ar', 'name': 'العربية'},
          {'code': 'zh', 'name': '中文'},
          {'code': 'de', 'name': 'Deutsch'},
          {'code': 'en', 'name': 'English'},
          {'code': 'es', 'name': 'Español'},
          {'code': 'fa', 'name': 'فارسی'},
          {'code': 'fr', 'name': 'Français'},
          {'code': 'ja', 'name': '日本語'},
          {'code': 'ko', 'name': '한국어'},
          {'code': 'ru', 'name': 'Русский'},
        ];

        var currentLanguage = stateManager.selectedLanguage;
        
        // 检查当前语言是否在支持的语言列表中
        if (!languages.any((lang) => lang['code'] == currentLanguage)) {
          // 如果不在列表中，重置为默认语言（英文）
          currentLanguage = 'en';
          stateManager.updateSettings(language: currentLanguage);
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: const Color(0xFF2C2E36),
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.getString('language', currentLanguage),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3E4A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentLanguage,
                        items: languages.map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang['code'],
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Text(
                                lang['name']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            stateManager.updateSettings(language: newValue);
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
          ),
        );
      },
    );
  }
}
