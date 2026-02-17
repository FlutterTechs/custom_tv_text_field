# 1.0.4

- Improved: Added comprehensive dartdoc comments for all public API elements.
  - Documents classes, constructors, methods, and properties.
  - Achieved >20% documentation coverage to improve package score.

# 1.0.3

- Improved: Resolved static analysis issues to improve package score.
  - Fixed `constant_identifier_names` in `TextFieldType`.
  - Fixed `curly_braces_in_flow_control_structures` in `KeyboardController`.
  - Removed unnecessary imports.
  - Cleaned up unused parameters in example app.
  - Balanced documentation with updated code examples.

# 1.0.2

- **New Feature**: Physical keyboard listening support using modern Flutter API (Focus + onKeyEvent)
  - Capture lowercase letters (a-z), uppercase letters (A-Z), numbers (0-9)
  - Support for special characters (!, @, #, $, %, etc.)
  - Space and Backspace keys fully functional
  - Works simultaneously with virtual on-screen keyboard
  - Uses `event.character` for accurate character detection
- Enhanced: Updated README with physical keyboard documentation
- Added: KEYBOARD_LISTENING.md - comprehensive technical documentation
- Added: ARCHITECTURE.md - visual diagrams and system flow
- Added: IMPLEMENTATION_SUMMARY.md - complete feature summary
- Improved: Info banner in example app to guide users

# 1.0.1

- Fix: Tap on custom keyboard keys now works correctly.
- Fix: Horizontal D-pad navigation wraps within the same row (matches system keyboard behavior).
- Updated repository URLs for pub.dev.

# 1.0.0

- Initial release of `custom_tv_text_field`.
- Features premium TV keyboard overlay.
- Support for `TextFieldType` automated validation.
- Seamless `Form` integration.
- D-pad navigation support.
