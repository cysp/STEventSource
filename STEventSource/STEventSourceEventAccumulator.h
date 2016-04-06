//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>

#import "STEventSourceEvent.h"

NS_ASSUME_NONNULL_BEGIN


@class STEventSourceEventAccumulator;

@protocol STEventSourceEventAccumulatorDelegate <NSObject>
- (void)eventAccumulator:(STEventSourceEventAccumulator *)accumulator didReceiveEvent:(STEventSourceEvent *)event;
- (void)eventAccumulator:(STEventSourceEventAccumulator *)accumulator didReceiveRetryInterval:(NSTimeInterval)retryInterval;
@end

@interface STEventSourceEventAccumulator : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDelegate:(id<STEventSourceEventAccumulatorDelegate> __nullable)delegate;

- (void)accumulateLines:(NSArray<NSData *> *)lines;
//- (NSArray<STEventSourceEvent *> *)eventsByAccumulatingLines:(NSArray<NSData *> *)lines;

@end


NS_ASSUME_NONNULL_END
