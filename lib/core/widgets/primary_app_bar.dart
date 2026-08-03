import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';

class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PrimaryAppBar({
    super.key,
    required this.title,
    this.showBackButton,
    this.showSettingsButton = false,
    this.showHelpButton = false,
    this.onBackPressed,
    this.onSettingsPressed,
    this.onHelpPressed,
    this.leading,
    this.showLogo = true,
  });

  final String title;
  final bool? showBackButton;
  final bool showSettingsButton;

  /// When true, a help (?) button is shown on the right side of the app bar,
  /// before the settings button and logo.
  final bool showHelpButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onHelpPressed;

  /// Widget shown on the left side of the app bar, after the back button
  /// (used by the main menu for the user id chip).
  final Widget? leading;

  /// When true, the app logo is pinned to the far-right of the app bar.
  final bool showLogo;

  static const double toolbarHeight = 60;
  static const double _logoSize = 26;

  /// Width reserved for the logo block (logo + app name text below it).
  static const double _logoBlockWidth = 58;

  /// Side of the white square manual/help tile — matches the height of the
  /// user profile chip so both read at the same scale.
  static const double _helpSquareSize = 36;

  /// Small, consistent spacing between the help tile and the logo block.
  static const double _helpLogoGap = 4;

  @override
  Size get preferredSize => const Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBackButton ?? canPop;
    final backgroundColor =
        theme.appBarTheme.backgroundColor ??
        (theme.brightness == Brightness.dark
            ? colorScheme.surface
            : colorScheme.primary);
    final foregroundColor =
        theme.appBarTheme.foregroundColor ??
        (theme.brightness == Brightness.dark
            ? colorScheme.onSurface
            : colorScheme.onPrimary);
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: toolbarHeight + topInset,
        padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const logoGap = 6.0;
            final backWidth = shouldShowBack ? 40.0 : 0.0;
            final leadingChipWidth = leading != null
                ? (constraints.maxWidth < 360 ? 104.0 : 120.0) +
                      (shouldShowBack ? logoGap : 0.0)
                : 0.0;
            final leadingWidth = backWidth + leadingChipWidth;
            final settingsWidth = showSettingsButton ? 40.0 : 0.0;
            // With a logo present, the help tile is grouped with the logo
            // block in a single row; it only renders standalone when there
            // is no logo.
            final embedHelp = showHelpButton && showLogo;
            final standaloneHelp = showHelpButton && !showLogo;
            final logoBlockW = embedHelp
                ? _helpSquareSize + _helpLogoGap + _logoBlockWidth
                : _logoBlockWidth;
            final helpWidth = standaloneHelp
                ? _helpSquareSize + (showSettingsButton ? logoGap : 0.0)
                : 0.0;
            final logoWidth = showLogo
                ? logoBlockW +
                      ((showSettingsButton || standaloneHelp) ? logoGap : 0.0)
                : 0.0;
            final actionWidth = settingsWidth + helpWidth + logoWidth;
            final titleHorizontalPadding =
                (leadingWidth > actionWidth ? leadingWidth : actionWidth) + 8;
            final titleStyle =
                (constraints.maxWidth < 360
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.titleLarge)
                    ?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    );
            final zaicomTile = ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                AppBuildConfig.isTrial
                    ? 'assets/images/branding/app_icon_trial.png'
                    : 'assets/images/branding/app_icon.png',
                height: _logoSize,
                width: _logoSize,
                fit: BoxFit.contain,
              ),
            );
            final zaicomText = FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppBuildConfig.displayName(
                  AppLocalizations.of(context).appTitle,
                ),
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
            );
            final logoColumn = SizedBox(
              width: _logoBlockWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [zaicomTile, const SizedBox(height: 2), zaicomText],
              ),
            );
            final logo = showLogo
                ? (embedHelp
                      // Help tile grouped beside the logo block: the app name
                      // stays fully visible below the logo, nothing overlaps.
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _HelpSquareButton(
                              circleColor: colorScheme.primary,
                              onPressed: onHelpPressed,
                            ),
                            const SizedBox(width: _helpLogoGap),
                            logoColumn,
                          ],
                        )
                      : logoColumn)
                : null;

            return Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (shouldShowBack)
                        _AppBarIconButton(
                          icon: Icons.arrow_back_rounded,
                          color: foregroundColor,
                          onPressed:
                              onBackPressed ??
                              () => Navigator.of(context).pop(),
                        ),
                      if (leading != null) ...[
                        if (shouldShowBack) const SizedBox(width: logoGap),
                        leading!,
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: titleHorizontalPadding,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                        style: titleStyle,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (standaloneHelp)
                        _HelpSquareButton(
                          circleColor: colorScheme.primary,
                          onPressed: onHelpPressed,
                        ),
                      if (showSettingsButton) ...[
                        if (standaloneHelp) const SizedBox(width: logoGap),
                        _AppBarIconButton(
                          icon: Icons.settings_outlined,
                          color: foregroundColor,
                          onPressed: onSettingsPressed,
                        ),
                      ],
                      if (logo != null) ...[
                        if (showSettingsButton || standaloneHelp)
                          const SizedBox(width: logoGap),
                        logo,
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PrimaryAppBarAction extends StatelessWidget {
  const PrimaryAppBarAction({
    super.key,
    this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData? icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 17) : null,
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: TextButton.styleFrom(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        disabledBackgroundColor: colorScheme.surface,
        disabledForegroundColor: colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        maximumSize: const Size(160, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

//Trial Action Button
class TrialActionButton extends StatelessWidget {
  const TrialActionButton({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Manual/help button styled to match the app logo tile: a white rounded
/// square holding a theme-colored circle with a white question mark.
class _HelpSquareButton extends StatelessWidget {
  const _HelpSquareButton({required this.circleColor, this.onPressed});

  final Color circleColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: SizedBox(
          width: PrimaryAppBar._helpSquareSize,
          height: PrimaryAppBar._helpSquareSize,
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.question_mark_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: color,
      iconSize: 24,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
