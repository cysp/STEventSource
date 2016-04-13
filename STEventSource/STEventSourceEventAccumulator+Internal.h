//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <STEventSource/STEventSourceEventAccumulator.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, STEventSourceEventAccumulatorState) {
    STEventSourceEventAccumulatorStateNormal = 0,
    STEventSourceEventAccumulatorStateIgnoringUntilBlankLine,
};


@interface STEventSourceEventAccumulator (Internal)

@property (nonatomic,assign,readonly) STEventSourceEventAccumulatorState state;

@property (nonatomic,copy,nullable,readonly) NSString *type;
@property (nonatomic,copy,readonly) NSString *data;
@property (nonatomic,copy,nullable,readonly) NSString *id;

@end


static inline BOOL NSStringConsistsSolelyOfASCIIDigits(NSString *string) {
    NSUInteger const stringLength = string.length;
    if (stringLength == 0) {
        return NO;
    }

    for (NSUInteger i = 0; i < stringLength; ++i) {
        unichar const c = [string characterAtIndex:i];
        if (c < '0' || c > '9') {
            return NO;
        }
    }

    return YES;
}


NS_ASSUME_NONNULL_END
