import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'keyboard_controller.dart';

/// Enum for Text Field Types
enum TextFieldType {
  EMAIL,
  PASSWORD,
  PHONE,
  NUMBER,
  NAME,
  USERNAME,
  URL,
  OTHER,
}

/// Custom TV Text Field with integrated keyboard
class CustomTVTextField extends StatefulWidget {
  final TextEditingController controller;
  final bool isFocused;
  final String hint;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final InputDecoration? decoration;
  final double verticalContentPadding;
  final double horizontalContentPadding;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffix;
  final Widget? suffixIcon;
  final Color? backgroundColor;
  final double borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final ValueChanged<String>? onFieldSubmitted;
  final double? fontSize;
  final double? iconSize;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final ValueChanged<bool>? onVisibilityChanged;
  final bool filled;
  final Color? fillColor;
  final EdgeInsets? contentPadding;
  final KeyboardType keyboardType;
  final String? Function(String?)? validator;
  final bool isRequired;
  final TextFieldType textFieldType;

  const CustomTVTextField({
    super.key,
    required this.controller,
    this.onVisibilityChanged,
    this.isFocused = false,
    this.hint = '',
    this.textStyle,
    this.hintStyle,
    this.decoration,
    this.verticalContentPadding = 0,
    this.horizontalContentPadding = 0,
    this.prefix,
    this.prefixIcon,
    this.suffix,
    this.suffixIcon,
    this.backgroundColor,
    this.borderRadius = 12,
    this.borderColor,
    this.focusedBorderColor,
    this.onFieldSubmitted,
    this.fontSize,
    this.iconSize,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.filled = false,
    this.fillColor,
    this.contentPadding,
    this.keyboardType = KeyboardType.alphabetic,
    this.validator,
    this.isRequired = false,
    this.textFieldType = TextFieldType.OTHER,
  });

  @override
  State<CustomTVTextField> createState() => CustomTVTextFieldState();
}

class CustomTVTextFieldState extends State<CustomTVTextField>
    with TickerProviderStateMixin {
  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnimation;
  late final KeyboardController _keyboardController;
  final ValueNotifier<bool> _isOverlayOpen = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _errorText = ValueNotifier<String?>(null);
  final FocusNode _keyboardFocusNode = FocusNode();

  bool get isKeyboardVisible => _keyboardController.isVisible;

  bool _validateEmail(String value) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(value);
  }

  String? _validateInternal(String? value) {
    final text = value?.trim() ?? "";

    if (widget.isRequired && text.isEmpty) {
      return "This field is required";
    }

    if (text.isNotEmpty) {
      switch (widget.textFieldType) {
        case TextFieldType.EMAIL:
          if (!_validateEmail(text)) return "Email is invalid";
          break;
        case TextFieldType.PASSWORD:
          if (text.length < 6) return "Minimum password length should be 6";
          break;
        case TextFieldType.PHONE:
        case TextFieldType.NUMBER:
          if (double.tryParse(text) == null) return "Invalid number";
          break;
        case TextFieldType.URL:
          if (!Uri.tryParse(text)!.hasAbsolutePath) return "Invalid URL";
          break;
        case TextFieldType.USERNAME:
          if (text.contains(' ')) return "Username should not contain space";
          break;
        default:
          break;
      }
    }

    if (widget.validator != null) {
      return widget.validator!(value);
    }
    return null;
  }

  String? validate() {
    final error = _validateInternal(widget.controller.text);
    _errorText.value = error;
    return error;
  }

  @override
  void initState() {
    super.initState();
    _initController();
    _initAnimation();
  }

  void _initController() {
    _keyboardController = KeyboardController();
    _keyboardController.setText(widget.controller.text);
    _keyboardController.onTextChanged = (text) => widget.controller.text = text;
    _keyboardController.onKeyboardClosed = (shouldPop) {
      widget.onFieldSubmitted?.call(widget.controller.text);
      if (shouldPop && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };
    _keyboardController.addListener(_onKeyboardStateChanged);
  }

  void _initAnimation() {
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_blinkController);
    if (widget.isFocused) _blinkController.repeat(reverse: true);
  }

  void _onKeyboardStateChanged() {
    if (!_keyboardController.isVisible && _isOverlayOpen.value) {
      _isOverlayOpen.value = false;
    }
    widget.onVisibilityChanged?.call(_keyboardController.isVisible);
  }

  @override
  void didUpdateWidget(CustomTVTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFocused != oldWidget.isFocused) {
      widget.isFocused
          ? _blinkController.repeat(reverse: true)
          : _blinkController.stop();
    }
  }

  void toggleKeyboard() =>
      _keyboardController.isVisible ? closeKeyboard() : openKeyboard();

  void openKeyboard() {
    _keyboardController.setText(widget.controller.text);
    _keyboardController.show();
    _keyboardFocusNode.requestFocus();
    if (!_isOverlayOpen.value) _showKeyboardOverlay();
  }

  void closeKeyboard() {
    if (_keyboardController.isVisible) _keyboardController.hide(true);
  }

  void _onTextFieldTapped() => openKeyboard();

  void _showKeyboardOverlay() {
    if (_isOverlayOpen.value) return;
    _isOverlayOpen.value = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.01),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: CustomKeyboard(
          keyboardController: _keyboardController,
          focusNode: _keyboardFocusNode,
          placeholder: widget.hint,
          keyboardType: widget.keyboardType,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keyboardController.removeListener(_onKeyboardStateChanged);
    _keyboardController.dispose();
    _isOverlayOpen.dispose();
    _errorText.dispose();
    _blinkController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => validate(),
      builder: (FormFieldState<String> state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _onTextFieldTapped,
              child: Stack(
                children: [
                  _HiddenInput(
                    controller: widget.controller,
                    onTap: _onTextFieldTapped,
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: _errorText,
                    builder: (context, error, _) => _FieldDisplay(
                      widget: widget,
                      blinkAnimation: _blinkAnimation,
                      hasError: error != null,
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: _errorText,
              builder: (context, error, _) {
                if (error == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _HiddenInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;

  const _HiddenInput({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TextField(
        controller: controller,
        readOnly: true,
        showCursor: false,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onTap: () {
          onTap();
        },
      ),
    );
  }
}

class _FieldDisplay extends StatelessWidget {
  final CustomTVTextField widget;
  final Animation<double> blinkAnimation;
  final bool hasError;

  const _FieldDisplay({
    required this.widget,
    required this.blinkAnimation,
    this.hasError = false,
  });

  BoxDecoration _buildDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = hasError
        ? Colors.redAccent
        : (widget.borderColor ?? theme.canvasColor);
    final focusedColor =
        widget.focusedBorderColor ??
        (widget.isFocused
            ? (hasError ? Colors.redAccent : Colors.white)
            : borderColor);

    return BoxDecoration(
      color: widget.fillColor ?? widget.backgroundColor,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      border: Border.all(
        color: focusedColor,
        width: widget.isFocused ? 2.5 : 1.0,
      ),
    );
  }

  EdgeInsets _getPadding() =>
      widget.contentPadding ??
      EdgeInsets.symmetric(
        vertical: widget.verticalContentPadding > 0
            ? widget.verticalContentPadding
            : 16,
        horizontal: widget.horizontalContentPadding > 0
            ? widget.horizontalContentPadding
            : 16,
      );

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.fontSize ?? 16;
    final iconSize = widget.iconSize ?? 18;
    final textStyle =
        widget.textStyle ?? TextStyle(fontSize: fontSize, color: Colors.white);
    final hintStyle = widget.hintStyle ?? const TextStyle(color: Colors.grey);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: _buildDecoration(context),
      padding: _getPadding(),
      child: Row(
        children: [
          if (widget.prefixIcon != null) ...[
            IconTheme(
              data: IconThemeData(size: iconSize),
              child: widget.prefixIcon!,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                final isEmpty = value.text.isEmpty;
                return Row(
                  children: [
                    Text(
                      isEmpty ? widget.hint : value.text,
                      style: isEmpty ? hintStyle : textStyle,
                      textAlign: widget.textAlign,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.isFocused)
                      _Cursor(
                        animation: blinkAnimation,
                        height: fontSize * 1.2,
                      ),
                  ],
                );
              },
            ),
          ),
          if (widget.suffixIcon != null) ...[
            const SizedBox(width: 8),
            IconTheme(
              data: IconThemeData(size: iconSize),
              child: widget.suffixIcon!,
            ),
          ],
        ],
      ),
    );
  }
}

class _Cursor extends StatelessWidget {
  final Animation<double> animation;
  final double height;

  const _Cursor({required this.animation, required this.height});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Opacity(
        opacity: animation.value,
        child: Container(
          width: 2,
          height: height,
          margin: const EdgeInsets.only(left: 2),
          color: Colors.white,
        ),
      ),
    );
  }
}
