import 'package:flutter/material.dart';
import 'package:waretrack_mini/features/settings/widgets/setting_section_title.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingSectionTitle(title),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
