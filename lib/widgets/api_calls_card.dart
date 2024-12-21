import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import '../l10n/strings.dart';

class ApiCallsCard extends StatelessWidget {
  final int apiCalls;

  const ApiCallsCard({
    super.key,
    required this.apiCalls,
  });

  void _showApiCallsInfo(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2E36),
        title: Text(
          AppStrings.getString('apiCallsTitle', locale),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.getString('apiCallsContent', locale),
              style: const TextStyle(
                color: Colors.white70,
                height: 1.6,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppStrings.getString('understood', locale),
              style: const TextStyle(color: Color(0xFF39FF14)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
                AppStrings.getString('apiCalls', Localizations.localeOf(context).languageCode),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$apiCalls',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
    );
  }
}
