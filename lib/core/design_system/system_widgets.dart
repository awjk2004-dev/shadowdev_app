import 'package:flutter/material.dart';

import 'chamfered_border.dart';
import '../theme/app_theme.dart';

class SystemPanel extends StatelessWidget {
  const SystemPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.active = false,
    this.dashed = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool active;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: ChamferedBorder(
          cut: 14,
          dashed: dashed,
          glow: active,
          side: BorderSide(
            color: active
                ? AppColors.primary
                : dashed
                    ? AppColors.inactive.withValues(alpha: 0.55)
                    : AppColors.primary.withValues(alpha: 0.3),
            width: active ? 1.4 : 1,
          ),
        ),
      ),
      child: child,
    );
  }
}

class SystemTag extends StatelessWidget {
  const SystemTag(
    this.label, {
    super.key,
    this.active = true,
    this.compact = false,
  });

  final String label;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.inactive;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.08),
        shape: ChamferedBorder(
          cut: 6,
          dashed: !active,
          side: BorderSide(color: color.withValues(alpha: 0.6)),
        ),
      ),
      child: Text(
        '[$label]',
        style: TextStyle(
          color: color,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class SystemTextField extends StatelessWidget {
  const SystemTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: AppColors.background,
        shape: ChamferedBorder(
          cut: 10,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.42)),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: const TextStyle(color: AppColors.textMain),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
        ),
      ),
    );
  }
}

class SystemButton extends StatelessWidget {
  const SystemButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final shape = ChamferedBorder(
      cut: 11,
      side: BorderSide(
        color: AppColors.primary.withValues(alpha: outlined ? 0.75 : 1),
      ),
    );
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: busy ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide.none,
                shape: shape,
                backgroundColor: AppColors.primary.withValues(alpha: 0.06),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon ?? Icons.arrow_forward),
              label: Text(label),
            )
          : FilledButton.icon(
              onPressed: busy ? null : onPressed,
              style: FilledButton.styleFrom(
                foregroundColor: AppColors.background,
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.45),
                shape: shape,
                side: BorderSide.none,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.background,
                      ),
                    )
                  : Icon(icon ?? Icons.arrow_forward),
              label: Text(label),
            ),
    );
  }
}
