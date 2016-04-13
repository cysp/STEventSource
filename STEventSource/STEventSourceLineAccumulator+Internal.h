//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <STEventSource/STEventSourceLineAccumulator.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, STEventSourceLineAccumulatorState) {
    STEventSourceLineAccumulatorStateNormal = 0,
    STEventSourceLineAccumulatorStateAfterCR,
};


@interface STEventSourceLineAccumulator (Internal)

@property (nonatomic,assign,readonly) STEventSourceLineAccumulatorState state;

@end


NS_ASSUME_NONNULL_END
