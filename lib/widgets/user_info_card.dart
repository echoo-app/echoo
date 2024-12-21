import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/state_manager.dart';
import '../l10n/strings.dart';

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({super.key});

  void _showApiCallsInfo(BuildContext context) {
    final stateManager = Provider.of<StateManager>(context, listen: false);
    final lang = stateManager.selectedLanguage;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2E36),
          title: Text(
            AppStrings.getString('apiCallsTitle', lang),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            AppStrings.getString('apiCallsContent', lang),
            style: const TextStyle(
              color: Colors.white70,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppStrings.getString('understood', lang),
                style: const TextStyle(color: Color(0xFF39FF14)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showActivateVipDialog(BuildContext context) async {
    final stateManager = Provider.of<StateManager>(context, listen: false);
    final lang = stateManager.selectedLanguage;
    final controller = TextEditingController();

    // 打开对话框前刷新支付链接
    await stateManager.refreshVipPaymentUrl();

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2E36),
          title: Text(
            AppStrings.getString('activateVip', lang),
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppStrings.getString('enterActivationCode', lang),
                  hintStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFD700)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                AppStrings.getString('noActivationCode', lang),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  final stateManager = Provider.of<StateManager>(context, listen: false);
                  final paymentUrl = stateManager.vipPaymentUrl;
                  if (paymentUrl != null) {
                    launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppStrings.getString('noPaymentUrl', lang)
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(
                  AppStrings.getString('buyVip', lang),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppStrings.getString('cancel', lang),
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () async {
                final success = await stateManager.activateVip(controller.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? AppStrings.getString('vipActivated', lang)
                            : AppStrings.getString('vipActivationFailed', lang),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(
                AppStrings.getString('activateVip', lang),
                style: const TextStyle(color: Color(0xFFFFD700)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        if (!stateManager.isLoggedIn) {
          return const SizedBox.shrink();
        }

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
                // API调用次数显示
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF39FF14).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.api,
                          color: Color(0xFF39FF14),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.getString('apiCalls', lang),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                stateManager.isVip ? AppStrings.getString('unlimited', lang) : '${stateManager.apiCalls}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (stateManager.isVip)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'VIP',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!stateManager.isVip)
                      TextButton(
                        onPressed: () => _showActivateVipDialog(context),
                        child: Text(
                          AppStrings.getString('activateVip', lang),
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: () => _showApiCallsInfo(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 邀请码
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF39FF14).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.card_giftcard,
                          color: Color(0xFF39FF14),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.getString('inviteCode', lang),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: stateManager.inviteCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.getString('inviteCodeCopied', lang)
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Text(
                              stateManager.inviteCode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF2C2E36),
                            title: Text(
                              AppStrings.getString('inviteCodeTitle', lang),
                              style: const TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              AppStrings.getString('inviteCodeHint', lang),
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.6,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  AppStrings.getString('understood', lang),
                                  style: const TextStyle(color: Color(0xFF39FF14)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                // 用户信息
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
                // 退出登录按钮
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
              ],
            ),
          ),
        );
      },
    );
  }
}
