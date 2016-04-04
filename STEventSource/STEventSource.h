//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double STEventSourceVersionNumber;
FOUNDATION_EXPORT const unsigned char STEventSourceVersionString[];


NS_ASSUME_NONNULL_BEGIN


extern NSString * const STEventSourceErrorDomain;

typedef NS_ENUM(NSUInteger, STEventSourceErrorCode) {
    STEventSourceUnknownError = 0,
};


typedef NS_ENUM(NSUInteger, STEventSourceReadyState) {
    STEventSourceReadyStateConnecting = 1,
    STEventSourceReadyStateOpen,
    STEventSourceReadyStateClosed,
};


@protocol STEventSourceEvent <NSObject>
@property (nonatomic,copy,readonly) NSString *type;
@property (nonatomic,copy,readonly) NSString *data;
@end


typedef void(^STEventSourceEventHandler)(id<STEventSourceEvent> event);
typedef void(^STEventSourceCompletionHandler)(NSError * __nullable error);


@interface STEventSource : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration request:(NSURLRequest *)request handler:(STEventSourceEventHandler)handler completion:(STEventSourceCompletionHandler)completion NS_DESIGNATED_INITIALIZER;

@property (nonatomic,strong,readonly) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic,assign,readonly) STEventSourceReadyState readyState;

@property (nonatomic,assign,readonly) NSUInteger numberOfEventsHandled;
@property (nonatomic,copy,nullable,readonly) NSString *lastEventId;

@property (nonatomic,assign,readonly) NSTimeInterval retryInterval;

@end


NS_ASSUME_NONNULL_END
