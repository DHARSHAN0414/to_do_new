import 'package:flutter/material.dart';

enum AppButtonVariant {
  filled,
  outlined,
  text,
  elevated,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.medium,
    this.isDestructive = false,
    this.isLoading = false,
    this.isFullWidth = false,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isDestructive;
  final bool isLoading;
  final bool isFullWidth;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;
    
    final button = _buildButton(theme, isTablet);
    
    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    
    return button;
  }

  Widget _buildButton(ThemeData theme, bool isTablet) {
    final buttonStyle = _getButtonStyle(theme, isTablet);
    final iconSize = _getIconSize(isTablet);
    final iconWidget = _buildIcon(theme, iconSize);
    
    Widget button;
    
    switch (variant) {
      case AppButtonVariant.filled:
        button = FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: iconWidget,
          label: Text(label),
          style: buttonStyle,
        );
        break;
      case AppButtonVariant.outlined:
        button = OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: iconWidget,
          label: Text(label),
          style: buttonStyle,
        );
        break;
      case AppButtonVariant.text:
        button = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: _getPadding(isTablet),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconWidget != const SizedBox.shrink()) ...[
                    iconWidget,
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
            ),
          ),
        );
        break;
      case AppButtonVariant.elevated:
        button = ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: iconWidget,
          label: Text(label),
          style: buttonStyle,
        );
        break;
    }
    
    if (isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }

  Widget _buildIcon(ThemeData theme, double iconSize) {
    if (isLoading) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getLoadingColor(theme),
          ),
        ),
      );
    }
    
    if (icon != null) {
      return Icon(icon, size: iconSize);
    }
    
    return const SizedBox.shrink();
  }

  ButtonStyle _getButtonStyle(ThemeData theme, bool isTablet) {
    final padding = _getPadding(isTablet);
    final borderRadius = BorderRadius.circular(12);
    
    final backgroundColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    
    final foregroundColor = isDestructive
        ? theme.colorScheme.onError
        : theme.colorScheme.onPrimary;
    
    final side = BorderSide(
      color: isDestructive
          ? theme.colorScheme.error
          : theme.colorScheme.outline,
      width: 1,
    );
    
    switch (variant) {
      case AppButtonVariant.filled:
        return FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: padding,
          elevation: 0,
        );
      case AppButtonVariant.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: isDestructive
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          side: side,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: padding,
        );
      case AppButtonVariant.text:
        return ButtonStyle(
          foregroundColor: WidgetStateProperty.all(
            isDestructive
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          padding: WidgetStateProperty.all(padding),
        );
      case AppButtonVariant.elevated:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: padding,
          elevation: 2,
        );
    }
  }

  EdgeInsets _getPadding(bool isTablet) {
    switch (size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 8 : 6,
        );
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 20,
          vertical: isTablet ? 12 : 10,
        );
      case AppButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 24,
          vertical: isTablet ? 16 : 14,
        );
    }
  }

  double _getIconSize(bool isTablet) {
    switch (size) {
      case AppButtonSize.small:
        return isTablet ? 16 : 14;
      case AppButtonSize.medium:
        return isTablet ? 18 : 16;
      case AppButtonSize.large:
        return isTablet ? 20 : 18;
    }
  }

  Color _getLoadingColor(ThemeData theme) {
    switch (variant) {
      case AppButtonVariant.filled:
      case AppButtonVariant.elevated:
        return isDestructive
            ? theme.colorScheme.onError
            : theme.colorScheme.onPrimary;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return isDestructive
            ? theme.colorScheme.error
            : theme.colorScheme.primary;
    }
  }
}

// Convenience constructors for common button types
class PrimaryButton extends AppButton {
  const PrimaryButton({
    super.key,
    required super.onPressed,
    required super.label,
    super.icon,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.isFullWidth = false,
    super.tooltip,
  }) : super(variant: AppButtonVariant.filled);
}

class SecondaryButton extends AppButton {
  const SecondaryButton({
    super.key,
    required super.onPressed,
    required super.label,
    super.icon,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.isFullWidth = false,
    super.tooltip,
  }) : super(variant: AppButtonVariant.outlined);
}

class AppTextButton extends AppButton {
  const AppTextButton({
    super.key,
    required super.onPressed,
    required super.label,
    super.icon,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.isFullWidth = false,
    super.tooltip,
  }) : super(variant: AppButtonVariant.text);
}

class DangerButton extends AppButton {
  const DangerButton({
    super.key,
    required super.onPressed,
    required super.label,
    super.icon,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.isFullWidth = false,
    super.tooltip,
  }) : super(
          variant: AppButtonVariant.filled,
          isDestructive: true,
        );
}

class DangerOutlinedButton extends AppButton {
  const DangerOutlinedButton({
    super.key,
    required super.onPressed,
    required super.label,
    super.icon,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.isFullWidth = false,
    super.tooltip,
  }) : super(
          variant: AppButtonVariant.outlined,
          isDestructive: true,
        );
}
