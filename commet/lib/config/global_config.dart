import 'dart:convert';

import 'package:commet/debug/log.dart';
import 'package:flutter/services.dart';

class GlobalConfig {
  static Map<String, dynamic> data = const {
    "default_homeserver": "matrix.org",
    "calendar_widget": "calendar-widget.commet.chat",
  };

  static String get defaultHomeserver {
    return data["default_homeserver"] ?? "matrix.org";
  }

  static String get calendarWidgetHost {
    return data["calendar_widget"] ?? "calendar-widget.commet.chat";
  }

  static Future<void> init() async {
    try {
      String jsonData = await rootBundle.loadString(
        'assets/config/global_config.json',
        cache: false,
      );

      data = const JsonDecoder().convert(jsonData);
      Log.i(jsonData);
    } catch (_) {
      Log.e("Failed to load global config");
    }
  }
}
