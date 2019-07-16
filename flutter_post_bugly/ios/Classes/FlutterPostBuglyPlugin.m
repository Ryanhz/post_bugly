#import "FlutterPostBuglyPlugin.h"
#import <Bugly/Bugly.h>

@implementation FlutterPostBuglyPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_post_bugly"
            binaryMessenger:[registrar messenger]];
  FlutterPostBuglyPlugin* instance = [[FlutterPostBuglyPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if([@"postCatchedException" isEqualToString:call.method]) {
      NSString *crash_detail = call.arguments[@"crash_detail"];
      NSString *crash_message = call.arguments[@"crash_message"];
      if (crash_detail == nil || crash_detail == NULL) {
         crash_message = @"";
      }
      if ([crash_detail isKindOfClass:[NSNull class]]) {
          crash_message = @"";
      }
      NSException* ex = [[NSException alloc]initWithName:crash_message
                                                  reason:crash_detail
                                                userInfo:nil];
      [Bugly reportException:ex];
      result(nil);
  } 
   else {
    result(FlutterMethodNotImplemented);
  }
}

@end
