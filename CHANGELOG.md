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
