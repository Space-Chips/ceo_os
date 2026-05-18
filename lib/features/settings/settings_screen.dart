import 'package:flutter/widgets.dart';

import '../profile/profile_screen.dart';

/// Settings are blended directly into Profile for a single configuration surface.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
