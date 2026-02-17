# Custom TV Text Field

A premium, TV-optimized custom text field and keyboard for Flutter applications. Designed for seamless remote control navigation and high-quality user experience on Android TV, Apple TV, and other smart TV platforms.

## Features

- **TV-Optimized Keyboard**: Custom on-screen keyboard designed for D-pad navigation.
- **Physical Keyboard Support**: Modern keyboard listening using Flutter's Focus + onKeyEvent API - type with your physical keyboard when the custom keyboard is open!
- **Automated Validation**: Built-in support for Email, Password, URL, and more via `TextFieldType`.
- **Remote Control Support**: Full handling of Arrow keys, Enter/Select, and Back/Escape.
- **Premium Aesthetics**: Smooth animations, glassmorphism-ready overlays, and customizable border styles.
- **Form Integration**: Fully compatible with Flutter's `Form` and `GlobalKey<FormState>`.
- **Zero Configuration**: Ready to use out of the box with sensible defaults for TV.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  custom_tv_text_field: ^1.0.0
```

## Usage

```dart
import 'package:custom_tv_text_field/custom_tv_text_field.dart';

// ... inside your widget tree
CustomTVTextField(
  controller: myController,
  hint: 'Enter your email',
  textFieldType: TextFieldType.email,
  isRequired: true,
  isFocused: true, // Handle focus state for TV navigation
)
```

## Validation

The package supports automated validation through `TextFieldType`:

- `TextFieldType.email`: Validates email patterns.
- `TextFieldType.password`: Minimum length of 6 characters.
- `TextFieldType.phone` / `TextFieldType.number`: Numeric validation.
- `TextFieldType.username`: Space-free strings.
- `TextFieldType.url`: Valid absolute URIs.

## Focus Management

Since this is built for TV, you manage `isFocused` state externally to handle D-pad navigation between fields.

```dart
CustomTVTextField(
  isFocused: _currentSection == LoginSection.email,
  // ...
)
```

## Physical Keyboard Support

The custom keyboard now supports physical keyboard input using Flutter's modern `Focus` + `onKeyEvent` API. When the custom keyboard overlay is open, users can type using either:

- **The virtual on-screen keyboard** (click keys with mouse/touch or navigate with D-pad)
- **Their physical keyboard** (type directly!)

### Supported Input

✅ **Lowercase letters**: a, b, c, ..., z  
✅ **Uppercase letters**: A, B, C, ..., Z (with Shift)  
✅ **Numbers**: 0, 1, 2, ..., 9  
✅ **Special characters**: !, @, #, $, %, ^, &, *, etc.  
✅ **Space**: Space bar  
✅ **Backspace**: Remove last character  

### How It Works

The implementation uses `event.character` to accurately detect printable characters, which means:

- **Automatic modifier handling**: Shift+A gives you "A", Shift+1 gives you "!"
- **International keyboard support**: Works with different keyboard layouts
- **Smart filtering**: Only accepts printable characters (ASCII 32-126 and UTF-8)

### Example

```dart
final _controller = TextEditingController();
final _fieldKey = GlobalKey<CustomTVTextFieldState>();

// In your build method:
CustomTVTextField(
  key: _fieldKey,
  controller: _controller,
  hint: 'Type something...',
  keyboardType: KeyboardType.alphabetic,
  onFieldSubmitted: (text) {
    print('You typed: $text');
  },
)

// Open the keyboard programmatically:
_fieldKey.currentState?.openKeyboard();
```

Once the keyboard is open, users can type using their physical keyboard seamlessly!

For more technical details, see [KEYBOARD_LISTENING.md](KEYBOARD_LISTENING.md).
