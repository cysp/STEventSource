//  Copyright © 2016 Scott Talbot. All rights reserved.

#import "STEventSourceEventAccumulator.h"


NSString * const STEventSourceEventAccumulatorErrorDomain = @"STEventSourceEventAccumulatorError";

static inline BOOL NSStringConsistsSolelyOfASCIIDigits(NSString *string);


@implementation STEventSourceEventAccumulator {
@private
    NSMutableString *_data;
}

- (NSString *)data {
    return _data.copy ?: @"";
}

- (BOOL)updateWithLine:(NSString *)line error:(NSError * __autoreleasing __nullable * __nullable)error {
    if (!line) {
        if (error) {
            *error = [NSError errorWithDomain:STEventSourceEventAccumulatorErrorDomain code:STEventSourceEventAccumulatorInvalidParameterError userInfo:nil];
        }
        return NO;
    }

    if (!line.length) {
        // shouldn't happen, we should have dispatched the event instead of doing this
        if (error) {
            *error = [NSError errorWithDomain:STEventSourceEventAccumulatorErrorDomain code:STEventSourceEventAccumulatorInvalidParameterError userInfo:nil];
        }
        return NO;
    }

    NSRange const lineRange = (NSRange){ .length = line.length };

    NSUInteger const colonIndex = [line rangeOfString:@":"].location;
    if (colonIndex == 0) {
        return YES;
    }

    if (colonIndex == NSNotFound) {
        return [self updateWithField:line value:@"" error:error];
    }

    NSString * const field = [line substringToIndex:colonIndex];

    if (colonIndex == lineRange.length - 1) {
        return [self updateWithField:field value:@"" error:error];
    }

    BOOL const skipSpaceAfterColon = [line characterAtIndex:colonIndex + 1] == ' ';

    NSUInteger valueStartIndex = colonIndex + 1;
    if (skipSpaceAfterColon) {
        valueStartIndex += 1;
    }

    NSString * const value = [line substringFromIndex:valueStartIndex];
    return [self updateWithField:field value:value error:error];
}

- (BOOL)updateWithField:(NSString *)field value:(NSString *)value error:(NSError * __autoreleasing __nullable * __nullable)error {
    if ([@"event" isEqualToString:field]) {
        _type = value.copy;
        return YES;
    }

    if ([@"data" isEqualToString:field]) {
        if (!_data) {
            _data = [[NSMutableString alloc] init];
        } else {
            [_data appendString:@"\n"];
        }
        [_data appendString:value];
        return YES;
    }

    if ([@"id" isEqualToString:field]) {
        _id = value.copy;
        return YES;
    }

    if ([@"retry" isEqualToString:field]) {
        if (NSStringConsistsSolelyOfASCIIDigits(value)) {
            _retry = @(value.integerValue / 1000.);
        }
        return YES;
    }

    return YES;
}

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
