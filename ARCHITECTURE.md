# Keyboard Key Listening - Architecture Diagram

## System Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Input Layer                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │  Physical        │              │  Virtual         │         │
│  │  Keyboard        │              │  On-Screen       │         │
│  │  (Type Keys)     │              │  Keyboard        │         │
│  └────────┬─────────┘              │  (Click/D-pad)   │         │
│           │                        └────────┬─────────┘         │
│           │                                 │                   │
└───────────┼─────────────────────────────────┼───────────────────┘
            │                                 │
            │                                 │
            ▼                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Event Capture Layer                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────┐        │
│  │  Focus Widget (CustomKeyboard)                      │        │
│  │  • onKeyEvent: (FocusNode, KeyEvent)               │        │
│  │  • autofocus: true                                 │        │
│  └──────────────────────┬──────────────────────────────┘        │
│                         │                                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────┐        │
│  │  _handleKey(KeyEvent event)                         │        │
│  │  • Check: KeyDownEvent or KeyRepeatEvent?          │        │
│  │  • Filter: event.character available?              │        │
│  └──────────────────────┬──────────────────────────────┘        │
│                         │                                        │
└─────────────────────────┼────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Character Processing                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌───────────────┐       ┌───────────────┐      ┌─────────────┐│
│  │  Backspace    │       │  Navigation   │      │  Printable  ││
│  │  Key?         │       │  Keys?        │      │  Character? ││
│  └───────┬───────┘       └───────┬───────┘      └──────┬──────┘│
│          │                       │                     │        │
│          │                       │                     │        │
│          │                       │                     │        │
│          ▼                       ▼                     ▼        │
│  ┌───────────────┐       ┌───────────────┐      ┌─────────────┐│
│  │ backspace()   │       │ _onMove()     │      │ Validate    ││
│  │ • Remove      │       │ • Arrow keys  │      │ charCode    ││
│  │   last char   │       │ • Enter       │      │ 32-126      ││
│  └───────┬───────┘       └───────┬───────┘      │ or > 127    ││
│          │                       │              └──────┬──────┘│
│          │                       │                     │        │
│          │                       │                     ▼        │
│          │                       │              ┌──────────────┐│
│          │                       │              │addCharacter()││
│          │                       │              │• Append to   ││
│          │                       │              │  _text       ││
│          │                       │              └──────┬───────┘│
│          │                       │                     │        │
└──────────┼───────────────────────┼─────────────────────┼────────┘
           │                       │                     │
           └───────────────┬───────┴─────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      State Management                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────┐        │
│  │  KeyboardController                                  │        │
│  │  • String _text = ''                                │        │
│  │  • notifyListeners()                                │        │
│  │  • onTextChanged?.call(_text)                       │        │
│  └──────────────────────┬──────────────────────────────┘        │
│                         │                                        │
└─────────────────────────┼────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                         UI Update                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────┐        │
│  │  ListenableBuilder                                   │        │
│  │  • Listens to KeyboardController                    │        │
│  │  • Rebuilds on change                               │        │
│  └──────────────────────┬──────────────────────────────┘        │
│                         │                                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────┐        │
│  │  _PreviewField                                       │        │
│  │  • Displays: widget.keyboardController.text         │        │
│  │  • Auto-scrolls to end                              │        │
│  └──────────────────────┬──────────────────────────────┘        │
│                         │                                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────┐        │
│  │  TextEditingController (parent widget)              │        │
│  │  • Receives: onTextChanged.call(_text)              │        │
│  │  • Updates: controller.text = text                  │        │
│  └─────────────────────────────────────────────────────┘        │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. Focus Widget
```dart
Focus(
  focusNode: widget.focusNode,
  onKeyEvent: (_, e) => _handleKey(e),
  autofocus: true,
  child: // ... keyboard UI
)
```
**Purpose**: Captures keyboard events when focused

### 2. Event Handler
```dart
KeyEventResult _handleKey(KeyEvent event) {
  // 1. Type check
  if (event is! KeyDownEvent && event is! KeyRepeatEvent)
    return KeyEventResult.ignored;
  
  // 2. Backspace
  if (event.logicalKey == LogicalKeyboardKey.backspace) {
    widget.keyboardController.backspace();
    return KeyEventResult.handled;
  }
  
  // 3. Character extraction
  final character = event.character;
  if (character != null && character.isNotEmpty) {
    final charCode = character.codeUnitAt(0);
    if ((charCode >= 32 && charCode <= 126) || charCode > 127) {
      widget.keyboardController.addCharacter(character);
      return KeyEventResult.handled;
    }
  }
  
  return KeyEventResult.ignored;
}
```
**Purpose**: Routes events to appropriate handlers

### 3. State Controller
```dart
class KeyboardController extends ChangeNotifier {
  String _text = '';
  
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
}
```
**Purpose**: Manages text state and notifies listeners

## Event Flow Example

### Example 1: Typing "Hello!"

```
User presses: H
  ↓
KeyDownEvent(logicalKey: keyH, character: "H")
  ↓
_handleKey() called
  ↓
event.character = "H"
  ↓
charCode = 72 (valid: 32-126)
  ↓
addCharacter("H")
  ↓
_text = "" + "H" = "H"
  ↓
notifyListeners()
  ↓
UI updates: shows "H"
```

```
User presses: Shift+1
  ↓
KeyDownEvent(logicalKey: digit1, character: "!")
  ↓
_handleKey() called
  ↓
event.character = "!" (modifier already applied!)
  ↓
charCode = 33 (valid: 32-126)
  ↓
addCharacter("!")
  ↓
_text = "Hello" + "!" = "Hello!"
  ↓
notifyListeners()
  ↓
UI updates: shows "Hello!"
```

### Example 2: Backspace

```
User presses: Backspace
  ↓
KeyDownEvent(logicalKey: backspace)
  ↓
_handleKey() called
  ↓
Matches: LogicalKeyboardKey.backspace
  ↓
backspace()
  ↓
_text = "Hello!".substring(0, 5) = "Hello"
  ↓
notifyListeners()
  ↓
UI updates: shows "Hello"
```

## Character Validation

```
Character Code Ranges:

0-31        → Control characters (REJECTED)
32          → Space (ACCEPTED)
33-126      → Printable ASCII (ACCEPTED)
            Examples:
            ! " # $ % & ' ( ) * + , - . /
            0 1 2 3 4 5 6 7 8 9
            : ; < = > ? @
            A B C ... Z
            [ \ ] ^ _ `
            a b c ... z
            { | } ~
127         → Delete (REJECTED)
128+        → Extended UTF-8 (ACCEPTED)
```

## Performance Considerations

### ✅ Efficient
- Only handles KeyDownEvent and KeyRepeatEvent
- Early return for invalid events
- Minimal processing per keystroke
- Direct string concatenation

### ✅ No Re-renders
- Uses ChangeNotifier for targeted updates
- Only rebuilds affected widgets
- Auto-scroll isolated in separate method

### ✅ Memory Safe
- No large buffers or caches
- Simple string concatenation
- Proper disposal of listeners

## Platform Compatibility

| Platform | Support | Notes |
|----------|---------|-------|
| Android  | ✅ Full | Physical & Bluetooth keyboards |
| iOS      | ✅ Full | External keyboards supported |
| Web      | ✅ Full | All browser keyboard events |
| macOS    | ✅ Full | Native keyboard support |
| Windows  | ✅ Full | Native keyboard support |
| Linux    | ✅ Full | Native keyboard support |

## Character Mapping Examples

| Key Press    | event.logicalKey | event.character | Result |
|--------------|-----------------|-----------------|--------|
| a            | keyA            | "a"             | "a"    |
| Shift + a    | keyA            | "A"             | "A"    |
| 5            | digit5          | "5"             | "5"    |
| Shift + 5    | digit5          | "%"             | "%"    |
| Space        | space           | " "             | " "    |
| Shift + 2    | digit2          | "@"             | "@"    |
| Backspace    | backspace       | null            | (del)  |
| Arrow Up     | arrowUp         | null            | (nav)  |

## Integration Points

```dart
CustomTVTextField
    ↓
  creates
    ↓
KeyboardController (state)
    ↓
  passed to
    ↓
CustomKeyboard (widget)
    ↓
  contains
    ↓
Focus (event capture)
    ↓
  calls
    ↓
_handleKey (event processing)
    ↓
  updates
    ↓
KeyboardController._text (state)
    ↓
  notifies
    ↓
TextEditingController (parent)
```

---

**Legend**:
- `→` = Rejected/Filtered
- `✅` = Accepted/Processed
- `(nav)` = Navigation handling
- `(del)` = Delete operation
