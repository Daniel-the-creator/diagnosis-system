import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outlined, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.label,
    this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48,
    this.fontSize,
    this.isFullWidth = false,
  });

  final String? label;
  final String? text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final dynamic icon; // Can be IconData or Widget
  final double? width;
  final double height;
  final double? fontSize;
  final bool isFullWidth;

  String get effectiveLabel => label ?? text ?? '';

  Widget? _buildIcon(Color color) {
    if (icon == null) return null;
    if (icon is IconData) {
      return Icon(icon as IconData, size: 18, color: color);
    }
    if (icon is Widget) {
      return IconTheme(
        data: IconThemeData(size: 18, color: color),
        child: icon as Widget,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final style = _buildStyle();
    final fgColor = _foregroundColor();
    final iconWidget = _buildIcon(fgColor);

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: fgColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconWidget != null) ...[
                iconWidget,
                const SizedBox(width: 8),
              ],
              Text(
                effectiveLabel,
                style: AppTextStyles.buttonText.copyWith(
                  color: fgColor,
                  fontSize: fontSize,
                ),
              ),
            ],
          );

    final effectiveWidth = isFullWidth ? double.infinity : width;

    return SizedBox(
      width: effectiveWidth,
      height: height,
      child: variant == AppButtonVariant.outlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: style,
              child: child,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: style,
              child: child,
            ),
    );
  }

  ButtonStyle _buildStyle() {
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      case AppButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      case AppButtonVariant.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      case AppButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      case AppButtonVariant.ghost:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
    }
  }

  Color _foregroundColor() {
    switch (variant) {
      case AppButtonVariant.outlined:
        return AppColors.primary;
      case AppButtonVariant.ghost:
        return AppColors.primary;
      default:
        return AppColors.textOnPrimary;
    }
  }
}
