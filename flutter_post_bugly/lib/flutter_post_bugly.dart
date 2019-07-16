import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class FlutterPostBugly {
  static const MethodChannel _channel =
      const MethodChannel('flutter_post_bugly');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }


   static void postCatchedException<T>(
    T callback(), {
    bool useLog = false, //是否打印，默认不打印异常
    FlutterExceptionHandler handler, //异常捕捉，用于自定义打印异常
    String filterRegExp, //异常上报过滤正则，针对message
  }) {
    var map = {};
    // This captures errors reported by the Flutter framework.
    FlutterError.onError = (FlutterErrorDetails details) async {
      if (useLog || handler != null) {
        // In development mode simply print to console.
        handler == null
            ? FlutterError.dumpErrorToConsole(details)
            : handler(details);
      } else {
        Zone.current.handleUncaughtError(details.exception, details.stack);
      }
    };

    // This creates a [Zone] that contains the Flutter application and stablishes
    // an error handler that captures errors and reports them.
    //
    // Using a zone makes sure that as many errors as possible are captured,
    // including those thrown from [Timer]s, microtasks, I/O, and those forwarded
    // from the `FlutterError` handler.
    //
    // More about zones:
    //
    // - https://api.dartlang.org/stable/1.24.2/dart-async/Zone-class.html
    // - https://www.dartlang.org/articles/libraries/zones
    runZoned<Future<Null>>(() async {
      callback();
    }, onError: (error, stackTrace) async {
      var errorStr = error.toString();
      //异常过滤
      if (filterRegExp != null) {
        RegExp reg = new RegExp(filterRegExp);
        Iterable<Match> matches = reg.allMatches(errorStr);
        if (matches.length > 0) {
          return;
        }
      }
      map.putIfAbsent("crash_message", () => errorStr);
      map.putIfAbsent("crash_detail", () => stackTrace.toString());
      await _channel.invokeMethod('postCatchedException', map);
    });
  }
}
