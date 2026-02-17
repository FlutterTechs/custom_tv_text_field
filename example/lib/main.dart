import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:custom_tv_text_field/custom_tv_text_field.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Keyboard Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const TVLoginScreen(),
    );
  }
}

enum LoginSection { email, password, phone, loginButton }

class TVLoginScreen extends StatefulWidget {
  const TVLoginScreen({super.key});

  @override
  State<TVLoginScreen> createState() => _TVLoginScreenState();
}

class _TVLoginScreenState extends State<TVLoginScreen> {
  final FocusNode screenFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ValueNotifier<LoginSection> _currentSection =
      ValueNotifier<LoginSection>(LoginSection.email);
  final ValueNotifier<bool> _hasKeyboardOpen = ValueNotifier<bool>(false);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final GlobalKey<CustomTVTextFieldState> emailKey =
      GlobalKey<CustomTVTextFieldState>();
  final GlobalKey<CustomTVTextFieldState> passwordKey =
      GlobalKey<CustomTVTextFieldState>();
  final GlobalKey<CustomTVTextFieldState> phoneKey =
      GlobalKey<CustomTVTextFieldState>();

  @override
  void initState() {
    super.initState();
    screenFocusNode.requestFocus();
  }

  @override
  void dispose() {
    screenFocusNode.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    _currentSection.dispose();
    _hasKeyboardOpen.dispose();
    super.dispose();
  }

  bool _canHandleKeys() => screenFocusNode.hasFocus && !_hasKeyboardOpen.value;

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (!_canHandleKeys() ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }

    final handlers = {
      LogicalKeyboardKey.arrowUp: () => _navigate(-1),
      LogicalKeyboardKey.arrowDown: () => _navigate(1),
      LogicalKeyboardKey.enter: _handleSelect,
      LogicalKeyboardKey.select: _handleSelect,
    };

    final handler = handlers[event.logicalKey];
    if (handler != null) {
      handler();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _navigate(int delta) {
    final nextIndex =
        (LoginSection.values.indexOf(_currentSection.value) + delta);
    if (nextIndex >= 0 && nextIndex < LoginSection.values.length) {
      _currentSection.value = LoginSection.values[nextIndex];
    }
  }

  void _handleSelect() {
    switch (_currentSection.value) {
      case LoginSection.email:
        emailKey.currentState?.toggleKeyboard();
        break;
      case LoginSection.password:
        passwordKey.currentState?.toggleKeyboard();
        break;
      case LoginSection.phone:
        phoneKey.currentState?.toggleKeyboard();
        break;
      case LoginSection.loginButton:
        _submitLogin();
        break;
    }
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logging in as ${emailController.text}...'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: screenFocusNode,
      onKeyEvent: (_, event) => _handleKeyEvent(event),
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: ValueListenableBuilder<LoginSection>(
                valueListenable: _currentSection,
                builder: (context, section, _) => ValueListenableBuilder<bool>(
                  valueListenable: _hasKeyboardOpen,
                  builder: (context, hasKeyboardOpen, _) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'TV Login',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Info banner about keyboard support
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard,
                              color: Colors.blue[300],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tip: Use your physical keyboard when the custom keyboard is open!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[200],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _Field(
                        fieldKey: emailKey,
                        controller: emailController,
                        label: "Email",
                        icon: Icons.email,
                        isSelected:
                            section == LoginSection.email && !hasKeyboardOpen,
                        isRequired: true,
                        textFieldType: TextFieldType.email,
                        onVisibilityChanged: (v) => _hasKeyboardOpen.value = v,
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        fieldKey: passwordKey,
                        controller: passwordController,
                        label: "Password",
                        icon: Icons.lock,
                        isSelected:
                            section == LoginSection.password &&
                            !hasKeyboardOpen,
                        isRequired: true,
                        textFieldType: TextFieldType.password,
                        onVisibilityChanged: (v) => _hasKeyboardOpen.value = v,
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        fieldKey: phoneKey,
                        controller: phoneController,
                        label: "Phone",
                        icon: Icons.phone,
                        isSelected:
                            section == LoginSection.phone && !hasKeyboardOpen,
                        isRequired: false,
                        textFieldType: TextFieldType.phone,
                        keyboardType: KeyboardType.numeric,
                        onVisibilityChanged: (v) => _hasKeyboardOpen.value = v,
                      ),
                      const SizedBox(height: 32),
                      _LoginButton(
                        isSelected:
                            section == LoginSection.loginButton &&
                            !hasKeyboardOpen,
                        onTap: _submitLogin,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final GlobalKey<CustomTVTextFieldState> fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<bool> onVisibilityChanged;
  final KeyboardType keyboardType;
  final bool isRequired;
  final TextFieldType textFieldType;

  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onVisibilityChanged,
    this.keyboardType = KeyboardType.alphabetic,
    this.isRequired = false,
    this.textFieldType = TextFieldType.other,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTVTextField(
      key: fieldKey,
      controller: controller,
      hint: label,
      prefixIcon: Icon(icon, color: Colors.white70),
      isFocused: isSelected,
      onVisibilityChanged: onVisibilityChanged,
      onFieldSubmitted: (_) {}, // Removed unused onSubmitted parameter
      keyboardType: keyboardType,
      backgroundColor: Colors.grey[900],
      focusedBorderColor: Colors.white,
      borderRadius: 4,
      isRequired: isRequired, // Removed unused validator parameter
      textFieldType: textFieldType,
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _LoginButton({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.deepPurpleAccent
            : Colors.deepPurple.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: const Center(
          child: Text(
            "SIGN IN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
