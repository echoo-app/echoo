import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../l10n/strings.dart';
import 'settings_section_card.dart';

class AuthSettings extends StatelessWidget {
  const AuthSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        final lang = stateManager.selectedLanguage;
        
        return Card(
          color: const Color(0xFF2C2E36),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (stateManager.isLoggedIn) ...[
                  // 显示当前用户信息
                  Row(
                    children: [
                      const Icon(Icons.account_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.getStringWithArgs('currentUser', lang, [stateManager.username ?? '']),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 登出按钮
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      stateManager.logout();
                    },
                    child: Text(AppStrings.getString('logout', lang)),
                  ),
                ] else ...[
                  // 登录和注册按钮
                  Row(
                    children: [
                      // 登录按钮
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: Text(AppStrings.getString('login', lang)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 注册按钮
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF39FF14),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: Text(AppStrings.getString('register', lang)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
