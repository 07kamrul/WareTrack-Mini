import 'package:flutter/material.dart';

class MainMenuCard extends StatelessWidget {
  const MainMenuCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = colorScheme.primary;
    final foregroundColor = colorScheme.onPrimary;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: foregroundColor, size: 26),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Icon(
                  Icons.chevron_right_rounded,
                  color: foregroundColor,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
