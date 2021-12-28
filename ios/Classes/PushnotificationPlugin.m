#import "PushnotificationPlugin.h"
#if __has_include(<pushnotification/pushnotification-Swift.h>)
#import <pushnotification/pushnotification-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "pushnotification-Swift.h"
#endif

@implementation PushnotificationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPushnotificationPlugin registerWithRegistrar:registrar];
}
@end
