import 'package:flutter/material.dart';

import 'create_account_screen.dart';

/// Backward-compatible route retained for older navigation code.
/// Account creation is implemented only once in CreateAccountScreen.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreateAccountScreen();
  }
}
