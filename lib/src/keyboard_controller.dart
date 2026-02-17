import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Enum for keyboard types: [alphabetic] or [numeric].
enum KeyboardType {
  /// standard a-z layout
  alphabetic,

  /// number and symbol layout
  numeric,
}

/// Controller that manages keyboard state and text input.
class KeyboardController extends ChangeNotifier {
  String _text = '';

  /// The current text entered into the controller.
  String get text => _text;

  bool _isVisible = false;

  /// Whether the keyboard is currently visible.
  bool get isVisible => _isVisible;

  /// Callback when the text changes.
  Function(String)? onTextChanged;

  /// Callback when the keyboard is closed.
  Function(bool shouldPop)? onKeyboardClosed;

  void addCharacter(String character) {
    _text += character;
    notifyListeners();
    onTextChanged?.call(_text);
  }

  void backspace() {
    if (_text.isNotEmpty) {
      _text = _text.substring(0, _text.length - 1);
      notifyListeners();
      onTextChanged?.call(_text);
    }
  }

  /// Clears all text in the controller.
  void clear() {
    _text = '';
    notifyListeners();
    onTextChanged?.call(_text);
  }

  /// Adds a space character.
  void addSpace() {
    _text += ' ';
    notifyListeners();
    onTextChanged?.call(_text);
  }

  /// Sets the absolute text value.
  void setText(String value) {
    _text = value;
    notifyListeners();
    onTextChanged?.call(_text);
  }

  /// Shows the keyboard.
  void show() {
    _isVisible = true;
    notifyListeners();
  }

  /// Hides the keyboard.
  void hide(bool shouldPop) {
    _isVisible = false;
    notifyListeners();
    onKeyboardClosed?.call(shouldPop);
  }

  /// Toggles keyboard visibility.
  void toggle() => _isVisible ? hide(true) : show();
}

/// Static layouts for the keyboard
class KeyboardLayouts {
  static const List<List<String>> alphabeticLower = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', '@'],
    ['SHIFT', 'z', 'x', 'c', 'v', 'b', 'n', 'm', '.', 'BACKSPACE'],
    ['123', '<', '>', 'SPACE', '-', '=', 'DONE'],
  ];

  static const List<List<String>> alphabeticUpper = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', '@'],
    ['SHIFT', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '.', 'BACKSPACE'],
    ['123', '<', '>', 'SPACE', '-', '=', 'DONE'],
  ];

  static const List<List<String>> numeric = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['!', '@', '#', '\$', '%', '^', '&', '*', '(', ')'],
    ['SHIFT', '[', ']', '{', '}', '/', '\\', '|', ':', 'BACKSPACE'],
    ['ABC', '<', '>', 'SPACE', '_', '+', 'DONE'],
  ];
}

/// The custom keyboard widget displayed in the overlay.
class CustomKeyboard extends StatefulWidget {
  /// The controller to use for text input.
  final KeyboardController keyboardController;

  /// An optional placeholder to show when text is empty.
  final String? placeholder;

  /// The type of keyboard to display.
  final KeyboardType keyboardType;

  /// The focus node that handles keyboard events.
  final FocusNode focusNode;

  /// Creates a [CustomKeyboard].
  const CustomKeyboard({
    super.key,
    required this.keyboardController,
    required this.focusNode,
    this.placeholder,
    this.keyboardType = KeyboardType.alphabetic,
  });

  @override
  State<CustomKeyboard> createState() => CustomKeyboardState();
}

/// The state of [CustomKeyboard].
class CustomKeyboardState extends State<CustomKeyboard> {
  final ValueNotifier<int> _selectedRow = ValueNotifier<int>(0);
  final ValueNotifier<int> _selectedCol = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isShifted = ValueNotifier<bool>(false);
  late final ValueNotifier<KeyboardType> _activeType;
  final ScrollController _scrollController = ScrollController();

  List<List<String>> get _currentLayout {
    if (_activeType.value == KeyboardType.numeric) {
      return KeyboardLayouts.numeric;
    }
    return _isShifted.value
        ? KeyboardLayouts.alphabeticUpper
        : KeyboardLayouts.alphabeticLower;
  }

  @override
  void initState() {
    super.initState();
    _activeType = ValueNotifier<KeyboardType>(widget.keyboardType);
  }

  @override
  void didUpdateWidget(CustomKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyboardType != widget.keyboardType) {
      _activeType.value = widget.keyboardType;
      _resetSelection();
    }
  }

  void _resetSelection() {
    _selectedRow.value = 0;
    _selectedCol.value = 0;
  }

  void _switchType() {
    _activeType.value = _activeType.value == KeyboardType.alphabetic
        ? KeyboardType.numeric
        : KeyboardType.alphabetic;
    _isShifted.value = false;
    _resetSelection();
  }

  void _onMove(int dRow, int dCol) {
    int nextRow = (_selectedRow.value + dRow).clamp(
      0,
      _currentLayout.length - 1,
    );
    int nextCol = _selectedCol.value;

    if (dRow != 0) {
      // Vertical movement: clamp column to new row's bounds
      nextCol = nextCol.clamp(0, _currentLayout[nextRow].length - 1);
    } else {
      // Horizontal movement: wrap within the same row
      final int rowLength = _currentLayout[nextRow].length;
      nextCol = (nextCol + dCol) % rowLength;
      if (nextCol < 0) nextCol += rowLength;
    }
    _selectedRow.value = nextRow;
    _selectedCol.value = nextCol;
  }

  void _onAction() {
    final key = _currentLayout[_selectedRow.value][_selectedCol.value];
    final controller = widget.keyboardController;

    switch (key) {
      case 'BACKSPACE':
        controller.backspace();
        break;
      case 'SPACE':
        controller.addSpace();
        break;
      case 'SHIFT':
        _isShifted.value = !_isShifted.value;
        break;
      case 'DONE':
        controller.hide(true);
        break;
      case '123':
      case 'ABC':
        _switchType();
        break;
      default:
        controller.addCharacter(key);
        break;
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    // Handle backspace
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      widget.keyboardController.backspace();
      _scrollToEnd();
      return KeyEventResult.handled;
    }

    // Handle navigation and control keys
    final handlers = {
      LogicalKeyboardKey.arrowUp: () => _onMove(-1, 0),
      LogicalKeyboardKey.arrowDown: () => _onMove(1, 0),
      LogicalKeyboardKey.arrowLeft: () => _onMove(0, -1),
      LogicalKeyboardKey.arrowRight: () => _onMove(0, 1),
      LogicalKeyboardKey.enter: _onAction,
      LogicalKeyboardKey.select: _onAction,
      LogicalKeyboardKey.escape: () => widget.keyboardController.hide(false),
      LogicalKeyboardKey.exit: () => widget.keyboardController.hide(false),
      LogicalKeyboardKey.goBack: () => widget.keyboardController.hide(false),
    };

    if (handlers.containsKey(event.logicalKey)) {
      handlers[event.logicalKey]?.call();
      return KeyEventResult.handled;
    }

    // Handle printable characters using event.character
    // This captures:
    // - Lowercase letters (a-z)
    // - Uppercase letters (A-Z)
    // - Numbers (0-9)
    // - Special characters (!, @, #, $, %, etc.)
    // - Space
    final character = event.character;
    if (character != null && character.isNotEmpty) {
      // Filter out control characters and only accept printable characters
      final charCode = character.codeUnitAt(0);
      // Printable ASCII characters range from 32 (space) to 126 (~)
      // Also allow extended UTF-8 characters (> 127)
      if ((charCode >= 32 && charCode <= 126) || charCode > 127) {
        widget.keyboardController.addCharacter(character);
        _scrollToEnd();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.keyboardController,
      builder: (context, _) {
        if (!widget.keyboardController.isVisible) {
          return const SizedBox.shrink();
        }

        return SizedBox.expand(
          child: GestureDetector(
            onTap: () => widget.keyboardController.hide(true),
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: SafeArea(
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Focus(
                        focusNode: widget.focusNode,
                        onKeyEvent: (_, e) => _handleKey(e),
                        autofocus: true,
                        child: ValueListenableBuilder<KeyboardType>(
                          valueListenable: _activeType,
                          builder: (context, type, _) =>
                              ValueListenableBuilder<bool>(
                                valueListenable: _isShifted,
                                builder: (context, shifted, _) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _PreviewField(
                                      text: widget.keyboardController.text,
                                      placeholder:
                                          widget.placeholder ?? 'Enter text...',
                                      scrollController: _scrollController,
                                    ),
                                    const SizedBox(height: 24),
                                    _KeyboardGrid(
                                      layout: _currentLayout,
                                      selectedRow: _selectedRow,
                                      selectedCol: _selectedCol,
                                      isShifted: _isShifted,
                                      onKeyTapped: (int row, int col) {
                                        _selectedRow.value = row;
                                        _selectedCol.value = col;
                                        _onAction();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _selectedRow.dispose();
    _selectedCol.dispose();
    _isShifted.dispose();
    _activeType.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _PreviewField extends StatelessWidget {
  final String text;
  final String placeholder;
  final ScrollController scrollController;

  const _PreviewField({
    required this.text,
    required this.placeholder,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = text.isEmpty;
    return Container(
      height: 44,
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            isEmpty ? placeholder : text,
            style: TextStyle(
              color: isEmpty
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyboardGrid extends StatelessWidget {
  final List<List<String>> layout;
  final ValueListenable<int> selectedRow;
  final ValueListenable<int> selectedCol;
  final ValueListenable<bool> isShifted;
  final void Function(int row, int col) onKeyTapped;

  const _KeyboardGrid({
    required this.layout,
    required this.selectedRow,
    required this.selectedCol,
    required this.isShifted,
    required this.onKeyTapped,
  });

  double _getKeyWidth(String key, double base) {
    if (key == 'SPACE') return base * 3.85;
    if (['123', 'ABC', 'DONE'].contains(key)) return base * 1.3;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double horizontalGapFactor = 0.15;
        const int maxKeysPerRow = 10;
        final double baseWidth =
            constraints.maxWidth /
            (maxKeysPerRow + (maxKeysPerRow - 1) * horizontalGapFactor);
        final double spacing = baseWidth * horizontalGapFactor;

        return Column(
          children: List.generate(layout.length, (r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(layout[r].length, (c) {
                  final key = layout[r][c];
                  return ValueListenableBuilder<int>(
                    valueListenable: selectedRow,
                    builder: (context, sR, _) => ValueListenableBuilder<int>(
                      valueListenable: selectedCol,
                      builder: (context, sC, _) => _KeyboardKey(
                        label: key,
                        isSelected: sR == r && sC == c,
                        isShifted: isShifted,
                        width: _getKeyWidth(key, baseWidth),
                        margin: EdgeInsets.only(
                          right: c < layout[r].length - 1 ? spacing : 0,
                        ),
                        onTap: () => onKeyTapped(r, c),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}

class _KeyboardKey extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueListenable<bool> isShifted;
  final double width;
  final EdgeInsets margin;
  final VoidCallback onTap;

  const _KeyboardKey({
    required this.label,
    required this.isSelected,
    required this.isShifted,
    required this.width,
    required this.margin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 48,
        margin: margin,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(child: _buildContent(context)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final color = isSelected ? Colors.black : Colors.white;
    switch (label) {
      case 'BACKSPACE':
        return Icon(Icons.backspace_outlined, color: color, size: 20);
      case 'DONE':
        return Icon(
          Icons.check_circle_outline,
          color: isSelected ? Colors.black : const Color(0xFF4CAF50),
          size: 22,
        );
      case 'SHIFT':
        return ValueListenableBuilder<bool>(
          valueListenable: isShifted,
          builder: (context, shifted, _) => Icon(
            shifted ? Icons.keyboard_capslock : Icons.keyboard_arrow_up,
            color: shifted ? const Color(0xFF4CAF50) : color,
            size: 22,
          ),
        );
      case 'SPACE':
        return Container(
          width: width * 0.5,
          height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      default:
        return Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        );
    }
  }
}
