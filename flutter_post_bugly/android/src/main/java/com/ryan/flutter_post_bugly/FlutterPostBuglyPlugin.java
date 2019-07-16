package com.ryan.flutter_post_bugly;

import com.tencent.bugly.Bugly;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterPostBuglyPlugin */
public class FlutterPostBuglyPlugin implements MethodCallHandler {
  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.ryan/flutter_post_bugly");
    channel.setMethodCallHandler(new FlutterPostBuglyPlugin());
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if(call.method.equals("postCatchedException")){
      String message = "";
      String detail = null;
      if (call.hasArgument("crash_message")) {
          message = call.argument("crash_message");
      }
      if (call.hasArgument("crash_detail")) {
          detail = call.argument("crash_detail");
      }
      if (TextUtils.isEmpty(detail)) return;
      String[] details = detail.split("#");
      List<StackTraceElement> elements = new ArrayList<>();
      for (String s : details) {
          if (!TextUtils.isEmpty(s)) {
              String methodName = null;
              String fileName = null;
              int lineNum = -1;
              String[] contents = s.split(" \\(");
              if (contents.length > 0) {
                  methodName = contents[0];
                  if (contents.length < 2) {
                      break;
                  }
                  String packageContent = contents[1].replace(")", "");
                  String[] packageContentArray = packageContent.split("\\.dart:");
                  if (packageContentArray.length > 0) {
                      if (packageContentArray.length == 1) {
                          fileName = packageContentArray[0];
                      } else {
                          fileName = packageContentArray[0] + ".dart";
                          Pattern patternTrace = Pattern.compile("[1-9]\\d*");
                          Matcher m = patternTrace.matcher(packageContentArray[1]);
                          if (m.find()) {
                              String lineNumStr = m.group();
                              lineNum = Integer.parseInt(lineNumStr);
                          }
                      }
                  }
              }
              StackTraceElement element = new StackTraceElement("Dart", methodName, fileName, lineNum);
              elements.add(element);
          }
      }
      Throwable throwable = new Throwable(message);
      if (elements.size() > 0) {
          StackTraceElement[] elementsArray = new StackTraceElement[elements.size()];
          throwable.setStackTrace(elements.toArray(elementsArray));
      }
      CrashReport.postCatchedException(throwable);
      result(null);
    }  else {
      result.notImplemented();
    }
  }
}
