# Custom TV Text Field

A premium, TV-optimized custom text field and keyboard for Flutter applications. Designed for seamless remote control navigation and high-quality user experience on Android TV, Apple TV, and other smart TV platforms.

## Features

- **TV-Optimized Keyboard**: Custom on-screen keyboard designed for D-pad navigation.
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
  textFieldType: TextFieldType.EMAIL,
  isRequired: true,
  isFocused: true, // Handle focus state for TV navigation
)
```

## Validation

The package supports automated validation through `TextFieldType`:

- `TextFieldType.EMAIL`: Validates email patterns.
- `TextFieldType.PASSWORD`: Minimum length of 6 characters.
- `TextFieldType.PHONE` / `TextFieldType.NUMBER`: Numeric validation.
- `TextFieldType.USERNAME`: Space-free strings.
- `TextFieldType.URL`: Valid absolute URIs.

## Focus Management

Since this is built for TV, you manage `isFocused` state externally to handle D-pad navigation between fields.

```dart
CustomTVTextField(
  isFocused: _currentSection == LoginSection.email,
  // ...
)
```
