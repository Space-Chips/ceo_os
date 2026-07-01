// Native SwiftUI `Label(token)` bridges for iOS Family Controls.
//
// Apple intentionally hides the real display name and icon of an app or web
// domain picked through `FamilyActivityPicker`: a returned `ApplicationToken`
// (or `WebDomainToken`) is an opaque blob that cannot be decoded into a
// plain name/identifier. The only way to surface the real label and icon is
// to render the `Label(token)` SwiftUI view from inside the host app. The
// Swift side (`AppDelegate.swift`) registers four `FlutterPlatformViewFactory`
// instances for this exact purpose:
//
//   * com.ceoos.app/blocked_app_token_label
//   * com.ceoos.app/blocked_app_token_icon
//   * com.ceoos.app/blocked_website_token_label
//   * com.ceoos.app/blocked_website_token_icon
//
// Each factory takes a `payload` (the FamilyActivitySelection encoded as
// JSON+base64 string), decodes the first token, and shows the system Label.
// On Android or older iOS we fall back to a plain text widget so the list
// still renders something.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class BlockedAppTokenLabel extends StatelessWidget {
  final String payload;
  final String? fallbackTitle;
  final String? textColorHex;
  final bool isDarkTheme;
  final double height;

  /// When false, the SwiftUI `Label(token)` switches to `.titleOnly`, so the
  /// app icon is not rendered. Use this in contexts where the icon is
  /// redundant (e.g. the ManageBlockedItemSheet header, where the user just
  /// tapped the card that already shows the icon). Avoids the gray
  /// placeholder rectangle Apple draws around the icon glyph when the
  /// hosting view is taller than the icon's intrinsic bounds.
  final bool showIcon;

  const BlockedAppTokenLabel({
    super.key,
    required this.payload,
    this.fallbackTitle,
    this.textColorHex,
    this.isDarkTheme = true,
    this.height = 22,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return Text(fallbackTitle ?? 'Selected app');
    }
    return SizedBox(
      height: height,
      child: UiKitView(
        viewType: 'com.ceoos.app/blocked_app_token_label',
        creationParams: <String, dynamic>{
          'payload': payload,
          'fallbackTitle': fallbackTitle ?? 'Selected app',
          if (textColorHex != null) 'textColorHex': textColorHex,
          'isDarkTheme': isDarkTheme,
          'showIcon': showIcon,
        },
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      ),
    );
  }
}

class BlockedWebsiteTokenLabel extends StatelessWidget {
  final String payload;
  final String? fallbackTitle;
  final String? textColorHex;
  final bool isDarkTheme;
  final double height;

  /// See [BlockedAppTokenLabel.showIcon] — same semantics for websites.
  final bool showIcon;

  const BlockedWebsiteTokenLabel({
    super.key,
    required this.payload,
    this.fallbackTitle,
    this.textColorHex,
    this.isDarkTheme = true,
    this.height = 22,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return Text(fallbackTitle ?? 'Selected website');
    }
    return SizedBox(
      height: height,
      child: UiKitView(
        viewType: 'com.ceoos.app/blocked_website_token_label',
        creationParams: <String, dynamic>{
          'payload': payload,
          'fallbackTitle': fallbackTitle ?? 'Selected website',
          if (textColorHex != null) 'textColorHex': textColorHex,
          'isDarkTheme': isDarkTheme,
          'showIcon': showIcon,
        },
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      ),
    );
  }
}
