import 'package:flutter/foundation.dart';

/// Platform checks that are safe on web.
///
/// `dart:io` `Platform` throws on web (`Unsupported operation:
/// Platform._operatingSystem`). On web, [defaultTargetPlatform] can still be
/// [TargetPlatform.iOS] (Safari on iPhone), so Apple Maps must also be gated
/// with [kIsWeb].
abstract final class AppPlatform {
  static bool get isWeb => kIsWeb;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
