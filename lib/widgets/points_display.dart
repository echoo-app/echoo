import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import 'settings_section_card.dart';
import 'api_calls_card.dart';

class PointsDisplay extends StatelessWidget {
  const PointsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        if (!stateManager.isLoggedIn) {
          return const SizedBox.shrink();
        }

        return SettingsSectionCard(
          title: '账户信息',
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApiCallsCard(
                apiCalls: stateManager.apiCalls,
              ),
            ],
          ),
        );
      },
    );
  }
}
