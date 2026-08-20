import 'package:flutter/foundation.dart';

/// Lightweight app-wide refresh signal used by top-level screens.
/// It keeps the current architecture simple while ensuring tab content
/// reflects changes made in another screen.
class AppRefreshService {
  AppRefreshService._();

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static void refresh() {
    notifier.value++;
  }
}
