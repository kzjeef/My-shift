//
//  SSTrackUtil.m
//  ShiftScheduler
//
//  Created by JiejingZhang on 15/6/10.
//
//

#import "SSTrackUtil.h"

NSString *kFurryKey = @"DBT8WY47JJRNHWH2JFSJ";

@implementation SSTrackUtil


+ (void) applicationStarted
{
    [Flurry setAppVersion:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [Flurry setCrashReportingEnabled:YES];
    [Flurry setDebugLogEnabled: YES];

    [Flurry startSession:kFurryKey];

}

+ (void) logEvent: (NSString *) event
{
    [Flurry logEvent:event];
}

+ (void) logEvent: (NSString *)event param:(NSDictionary *) param
{
    [Flurry logEvent: event withParameters:param];
}

+ (void) logTimedEvent: (NSString *) event
{
    [Flurry logEvent: event timed: YES];
}

+ (void) logTimedEvent: (NSString *) event param:(NSDictionary *)param
{
    [Flurry logEvent: event withParameters: param timed: YES];
}

+ (void) stopLogTimedEvent: (NSString *)event
{
    [Flurry endTimedEvent:event withParameters:nil];
}

+ (void) logError: (NSString *) errorID message:(NSString *)message error: (NSError *) error
{
    [Flurry logError: errorID message:message error: error];
}

+ (void) logError: (NSString *) errorID message:(NSString *)message exception: (NSException *) exception
{
    [Flurry logError: errorID message:message exception: exception];
}

+ (void) startLogPageViews: (id) target
{
    [Flurry logAllPageViewsForTarget:target];
}
+ (void) stopLogPageViews:  (id) target
{
    [Flurry stopLogPageViewsForTarget: target];
}


@end
