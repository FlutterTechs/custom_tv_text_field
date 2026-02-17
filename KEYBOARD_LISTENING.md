# Keyboard Key Listening Implementation

## Overview

This Flutter implementation provides modern keyboard key listening capabilities when a custom keyboard is enabled. It uses the **Focus + onKeyEvent** API to capture physical keyboard input alongside the virtual on-screen keyboard.

## Features

### ✅ Supported Input Types

1. **Lowercase Letters**: `a, b, c, ..., z`
2. **Uppercase Letters**: `A, B, C, ..., Z`
3. **Numbers**: `0, 1, 2, ..., 9`
4. **Special Characters**: `!, @, #, $, %, ^, &, *, (, ), etc.`
5. **Space**: ` ` (space bar)
6. **Backspace**: Removes the last character

### 🔧 Technical Implementation

#### Key Components

1. **KeyboardController** (`keyboard_controller.dart`)
   - Manages the internal string state
   - Provides methods: `addCharacter()`, `backspace()`, `addSpace()`, `clear()`
   - Notifies listeners on text changes

2. **CustomKeyboard Widget**
   - Uses `Focus` widget with `onKeyEvent` callback
   - Handles both `KeyDownEvent` and `KeyRepeatEvent`
   - Captures printable characters via `event.character`

#### Implementation Details

```dart
KeyEventResult _handleKey(KeyEvent event) {
  // Only handle key down and repeat events
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
    return KeyEventResult.ignored;
  }

  // Handle backspace separately
  if (event.logicalKey == LogicalKeyboardKey.backspace) {
    widget.keyboardController.backspace();
    _scrollToEnd();
    return KeyEventResult.handled;
  }

  // Handle navigation keys (arrows, enter, etc.)
  // ... navigation handling code ...

  // Capture printable characters using event.character
  final character = event.character;
  if (character != null && character.isNotEmpty) {
    final charCode = character.codeUnitAt(0);
    // Accept printable ASCII (32-126) and extended UTF-8
    if ((charCode >= 32 && charCode <= 126) || charCode > 127) {
      widget.keyboardController.addCharacter(character);
      _scrollToEnd();
      return KeyEventResult.handled;
    }
  }

  return KeyEventResult.ignored;
}
```

## Character Detection Logic

### Using `event.character`

The implementation uses `event.character` to detect printable characters. This is the modern Flutter approach that automatically handles:

- **Keyboard layouts**: Different international keyboards
- **Shift modifiers**: Automatically provides uppercase when Shift is pressed
- **Special character modifiers**: Handles combinations like `Shift+1` → `!`

### Character Filtering

```dart
final charCode = character.codeUnitAt(0);

// Printable ASCII characters: 32 (space) to 126 (~)
// Extended UTF-8 characters: > 127
if ((charCode >= 32 && charCode <= 126) || charCode > 127) {
  // Accept and add the character
}
```

This ensures only printable characters are captured, excluding:
- Control characters (0-31)
- Delete character (127)

## Internal State Management

The `KeyboardController` maintains an internal string variable:

```dart
class KeyboardController extends ChangeNotifier {
  String _text = '';
  String get text => _text;

  void addCharacter(String character) {
    _text += character;  // Append character
    notifyListeners();
    onTextChanged?.call(_text);
  }

  void backspace() {
    if (_text.isNotEmpty) {
      _text = _text.substring(0, _text.length - 1);  // Remove last char
      notifyListeners();
      onTextChanged?.call(_text);
    }
  }

  void clear() {
    _text = '';
    notifyListeners();
    onTextChanged?.call(_text);
  }
}
```

## Usage Example

```dart
import 'package:custom_tv_text_field/custom_tv_text_field.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<CustomTVTextFieldState> _fieldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return CustomTVTextField(
      key: _fieldKey,
      controller: _controller,
      hint: 'Type something...',
      keyboardType: KeyboardType.alphabetic,
      onFieldSubmitted: (text) {
        print('Submitted: $text');
      },
    );
  }

  void openKeyboard() {
    _fieldKey.currentState?.openKeyboard();
  }
}
```

## Keyboard Layouts

The implementation supports two main keyboard types:

### 1. Alphabetic Layout
- **Lower case**: `a-z` and special characters
- **Upper case**: `A-Z` (activated via SHIFT key)
- Special keys: `SHIFT`, `BACKSPACE`, `SPACE`, `123`, `DONE`

### 2. Numeric Layout
- Numbers: `0-9`
- Symbols: `!, @, #, $, %, ^, &, *, (, )`
- Brackets: `[], {}`
- Special keys: `ABC`, `BACKSPACE`, `SPACE`, `DONE`

## Testing Physical Keyboard Input

To test the keyboard listening functionality:

1. **Open the Custom Keyboard**: Click on the text field
2. **Type on Your Physical Keyboard**:
   - Letters: Type `a`, `b`, `C`, `D` - they appear in the text field
   - Numbers: Type `1`, `2`, `3` - they appear
   - Special chars: Type `!`, `@`, `#` - they appear
   - Space: Press space bar - adds a space
   - Backspace: Press backspace - removes last character

3. **Or Use the Virtual Keyboard**: Click on the on-screen keys

Both input methods work simultaneously!

## Key Benefits

1. ✅ **Modern API**: Uses Flutter's recommended `Focus` + `onKeyEvent` approach
2. ✅ **Character Detection**: Leverages `event.character` for accurate input
3. ✅ **Full Support**: Letters, numbers, special chars, space, backspace
4. ✅ **International**: Works with different keyboard layouts
5. ✅ **State Management**: Maintains internal string with proper updates
6. ✅ **Dual Input**: Physical keyboard + virtual keyboard work together

## Code Organization

```
lib/
├── custom_tv_text_field.dart       # Main export file
└── src/
    ├── custom_tv_text_field.dart   # TextField widget
    └── keyboard_controller.dart     # Keyboard logic & state management
```

## Advanced Features

### Auto-scroll to End
When typing, the preview field automatically scrolls to show the latest input:

```dart
void _scrollToEnd() {
  if (_scrollController.hasClients) {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}
```

### Navigation Keys
The implementation also handles:
- Arrow keys (Up, Down, Left, Right) for navigating the virtual keyboard
- Enter/Select for triggering key actions
- Escape/Exit for closing the keyboard

## Limitations

- Only captures keyboard input when the custom keyboard overlay is visible
- Requires the `Focus` widget to have focus (handled automatically)
- Some special system keys may not be captured depending on the platform

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

The `event.character` API is supported on all Flutter platforms.

---

**Last Updated**: February 2026
**Flutter Version**: 3.x+
**API Used**: Focus + onKeyEvent (Modern API)
