import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Text field with a consistent look, inline validation and a password mode
/// that includes a visibility toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofillHints,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autovalidateMode,
    this.enabled = true,
    this.focusNode,
    this.inputFormatters,
    this.showCounter = false,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final bool showCounter;
  final String? semanticLabel;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _visible = !widget.obscure;

  @override
  Widget build(BuildContext context) {
    final bool isPassword = widget.obscure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: Text(
              widget.label!.toUpperCase(),
              style: AppType.labelSmall(color: AppColors.textMuted),
            ),
          ),
        ],
        Semantics(
          label: widget.semanticLabel ?? widget.label,
          textField: true,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            obscureText: isPassword && !_visible,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            minLines: widget.obscure ? 1 : widget.minLines,
            maxLength: widget.maxLength,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            enableSuggestions: !isPassword,
            autocorrect: !isPassword,
            style: AppType.bodyLarge(color: AppColors.textPrimary),
            cursorColor: AppColors.accent,
            buildCounter: (
              BuildContext context, {
              required int currentLength,
              required int? maxLength,
              required bool isFocused,
            }) {
              if (!widget.showCounter || maxLength == null) return null;
              final double ratio = currentLength / maxLength;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '$currentLength / $maxLength',
                  style: AppType.mono(
                    size: 11,
                    color: ratio > 0.9 ? AppColors.danger : AppColors.textMuted,
                  ),
                ),
              );
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helper,
              helperMaxLines: 3,
              helperStyle: AppType.bodySmall(color: AppColors.textMuted),
              errorText: widget.errorText,
              errorMaxLines: 3,
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: Icon(widget.prefixIcon, size: 19, color: AppColors.textMuted),
                    ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: isPassword
                  ? IconButton(
                      onPressed: () => setState(() => _visible = !_visible),
                      tooltip: _visible ? 'Hide password' : 'Show password',
                      icon: Icon(
                        _visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    )
                  : widget.suffix,
            ),
          ),
        ),
      ],
    );
  }
}

/// Labelled dropdown with the same visual language as [AppTextField].
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(label.toUpperCase(), style: AppType.labelSmall(color: AppColors.textMuted)),
        ),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
          hint: hint == null ? null : Text(hint!, style: AppType.bodyMedium(color: AppColors.textMuted)),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
          style: AppType.bodyLarge(color: AppColors.textPrimary),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
        ),
      ],
    );
  }
}
