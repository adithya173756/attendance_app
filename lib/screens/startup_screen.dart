import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/student_service.dart';

import 'login_screen.dart';
import 'create_account_screen.dart';
import 'student_profile_screen.dart';
import '../widgets/bottom_nav.dart';

enum _StartupDestination {
  createAccount,
  login,
  profileSetup,
  home,
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupDestination>(
      future: _checkStartup(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to start the app.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        switch (snapshot.data) {
          case _StartupDestination.createAccount:
            return const CreateAccountScreen();
          case _StartupDestination.login:
            return const LoginScreen();
          case _StartupDestination.profileSetup:
            return const StudentProfileScreen(initialSetup: true);
          case _StartupDestination.home:
          default:
            return const BottomNav();
        }
      },
    );
  }

  Future<_StartupDestination> _checkStartup() async {
    if (!AuthService.isLoggedIn()) {
      return AuthService.hasAccount()
          ? _StartupDestination.login
          : _StartupDestination.createAccount;
    }

    final hasProfile = await StudentService.hasProfile();
    return hasProfile
        ? _StartupDestination.home
        : _StartupDestination.profileSetup;
  }
}
