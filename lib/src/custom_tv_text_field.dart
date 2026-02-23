import 'package:flutter/material.dart';
import 'keyboard_controller.dart';

/// Enum for Text Field Types used for automatic validation.
enum TextFieldType {
  /// Email validation (checks for @ and .)
  email,

  /// Password validation (minimum length check)
  password,

  /// Phone number validation
  phone,

  /// General numeric validation
  number,

  /// Name validation
  name,

  /// Username validation (disallows spaces)
  username,

  /// URL validation
  url,

  /// Default type for other inputs
  other,
}

/// Custom TV Text Field with integrated on-screen keyboard support.
///
/// Designed specifically for TV platforms to handle D-pad navigation
/// and remote control input seamlessly.
class CustomTVTextField extends StatefulWidget {
  /// The controller that handles the text being edited.
  final TextEditingController controller;

  /// Whether this field is currently focused.
  ///
  /// For TV apps, you typically manage this state externally to handle
  /// focus changes between multiple fields via D-pad navigation.
  final bool isFocused;

  /// Text that is displayed when the field is empty.
  final String hint;

  /// The style to use for the text being edited.
  final TextStyle? textStyle;

  /// The style to use for the [hint].
  final TextStyle? hintStyle;

  /// The decoration to show around the text field.
  final InputDecoration? decoration;

  /// Vertical padding inside the field.
  final double verticalContentPadding;

  /// Horizontal padding inside the field.
  final double horizontalContentPadding;

  /// A widget to display before the text.
  final Widget? prefix;

  /// An icon to display before the text.
  final Widget? prefixIcon;

  /// A widget to display after the text.
  final Widget? suffix;

  /// An icon to display after the text.
  final Widget? suffixIcon;

  /// The background color of the text field.
  final Color? backgroundColor;

  /// The border radius of the text field.
  final double borderRadius;

  /// The color of the border when not focused.
  final Color? borderColor;

  /// The color of the border when focused.
  final Color? focusedBorderColor;

  /// Called when the user submits the text (e.g., clicks 'DONE').
  final ValueChanged<String>? onFieldSubmitted;

  /// The font size of the text.
  final double? fontSize;

  /// The size of the icons (prefix/suffix).
  final double? iconSize;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// How the text should be aligned vertically.
  final TextAlignVertical? textAlignVertical;

  /// Called when the keyboard visibility changes.
  final ValueChanged<bool>? onVisibilityChanged;

  /// Whether the text field should be filled with [fillColor].
  final bool filled;

  /// The color to fill the text field with.
  final Color? fillColor;

  /// Custom padding inside the field, overrides [verticalContentPadding] and [horizontalContentPadding].
  final EdgeInsets? contentPadding;

  /// The type of keyboard to display (alphabetic or numeric).
  final KeyboardType keyboardType;

  /// An optional validator function.
  final String? Function(String?)? validator;

  /// Whether this field is required for validation.
  final bool isRequired;

  /// The type of text being edited, affects automatic validation.
  final TextFieldType textFieldType;

  /// Creates a [CustomTVTextField].
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
    this.textFieldType = TextFieldType.other,
  });

  @override
  State<CustomTVTextField> createState() => CustomTVTextFieldState();
}

/// The state of [CustomTVTextField].
class CustomTVTextFieldState extends State<CustomTVTextField>
    with TickerProviderStateMixin {
  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnimation;
  late final KeyboardController _keyboardController;
  final ValueNotifier<bool> _isOverlayOpen = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _errorText = ValueNotifier<String?>(null);
  final FocusNode _keyboardFocusNode = FocusNode();

  /// Whether the keyboard overlay is currently visible.
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
        case TextFieldType.email:
          if (!_validateEmail(text)) return "Email is invalid";
          break;
        case TextFieldType.password:
          if (text.length < 6) return "Minimum password length should be 6";
          break;
        case TextFieldType.phone:
        case TextFieldType.number:
          if (double.tryParse(text) == null) return "Invalid number";
          break;
        case TextFieldType.url:
          if (!Uri.tryParse(text)!.hasAbsolutePath) return "Invalid URL";
          break;
        case TextFieldType.username:
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

  /// Validates the current text based on [CustomTVTextField.textFieldType] and [CustomTVTextField.validator].
  ///
  /// Returns an error string if invalid, or null if valid.
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

  /// Toggles the keyboard visibility.
  void toggleKeyboard() =>
      _keyboardController.isVisible ? closeKeyboard() : openKeyboard();

  /// Opens the keyboard overlay.
  void openKeyboard() {
    _keyboardController.setText(widget.controller.text);
    _keyboardController.show();
    _keyboardFocusNode.requestFocus();
    if (!_isOverlayOpen.value) _showKeyboardOverlay();
  }

  /// Closes the keyboard overlay.
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
      barrierColor: Colors.black.withOpacity(0.01),
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
