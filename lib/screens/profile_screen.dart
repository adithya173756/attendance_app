import 'package:flutter/material.dart';

import 'student_profile_screen.dart';

/// Backward-compatible wrapper for the older profile route.
/// The app now uses one profile implementation everywhere so profile edits
/// cannot behave differently depending on where the user opened them.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentProfileScreen();
  }
}
