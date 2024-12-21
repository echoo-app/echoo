import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import '../l10n/strings.dart';

class AlertDialogHelper {
  static Future<void> showMessage(BuildContext context, String message) async {
    final lang = Provider.of<StateManager>(context, listen: false).selectedLanguage;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2E36),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppStrings.getString('dialogConfirm', lang),
              style: const TextStyle(
                color: Color(0xFF39FF14),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
