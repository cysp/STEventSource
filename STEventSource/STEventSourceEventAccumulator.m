//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <STEventSource/STEventSourceEventAccumulator.h>
#import <STEventSource/STEventSourceEventAccumulator+Internal.h>


NSString * const STEventSourceEventAccumulatorErrorDomain = @"STEventSourceEventAccumulatorError";

static inline BOOL NSStringConsistsSolelyOfASCIIDigits(NSString *string);


@implementation STEventSourceEventAccumulator {
@private
    STEventSourceEventAccumulatorState _state;
    id<STEventSourceEventAccumulatorDelegate> __weak _delegate;
    NSString *_type;
    NSMutableString *_data;
    NSString *_id;
}

- (instancetype)init {
    return [self initWithDelegate:nil];
}
- (instancetype)initWithDelegate:(id<STEventSourceEventAccumulatorDelegate>)delegate {
    if ((self = [super init])) {
        _delegate = delegate;
    }
    return self;
}

- (STEventSourceEventAccumulatorState)state {
    return _state;
}
- (NSString *)type {
    return _type;
}
- (NSString *)data {
    return _data.copy;
}
- (NSString *)id {
    return _id;
}


- (void)accumulateLines:(NSArray<NSData *> *)lines {
    for (NSData *lineData in lines) {
        NSString * const line = [[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding];
        if (!line) {
            _state = STEventSourceEventAccumulatorStateIgnoringUntilBlankLine;
            [self st_clearState];
            continue;
        }
        switch (_state) {
            case STEventSourceEventAccumulatorStateNormal: {
                if (line.length == 0) {
                    if (_type || _data || _id) {
                        STEventSourceEvent * const event = self.st_eventAndClearState;
                        if (event) {
                            [_delegate eventAccumulator:self didReceiveEvent:event];
                        }
                    }
                } else {
                    [self st_processLine:line];
                }
            } break;
            case STEventSourceEventAccumulatorStateIgnoringUntilBlankLine: {
                if (line.length == 0) {
                    _state = STEventSourceEventAccumulatorStateNormal;
                }
            } break;
        }
    }
}

- (void)st_clearState {
    _type = nil;
    _data = nil;
    _id = nil;
}
- (STEventSourceEvent *)st_eventAndClearState {
    STEventSourceEvent * const event = [STEventSourceEvent eventWithType:_type data:_data id:_id];
    [self st_clearState];
    return event;
}

- (BOOL)st_processLine:(NSString *)line {
    NSParameterAssert(line);
    NSParameterAssert(line.length > 0);

    NSRange const lineRange = (NSRange){ .length = line.length };

    NSUInteger const colonIndex = [line rangeOfString:@":"].location;
    if (colonIndex == 0) {
        return YES;
    }

    if (colonIndex == NSNotFound) {
        return [self st_processField:line value:@""];
    }

    NSString * const field = [line substringToIndex:colonIndex];

    if (colonIndex == lineRange.length - 1) {
        return [self st_processField:field value:@""];
    }

    BOOL const skipSpaceAfterColon = [line characterAtIndex:colonIndex + 1] == ' ';

    NSUInteger valueStartIndex = colonIndex + 1;
    if (skipSpaceAfterColon) {
        valueStartIndex += 1;
    }

    NSString * const value = [line substringFromIndex:valueStartIndex];
    return [self st_processField:field value:value];
}

- (BOOL)st_processField:(NSString *)field value:(NSString *)value {
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
            NSTimeInterval const retryInterval = ((NSTimeInterval)value.longLongValue) / 1000.;
            [_delegate eventAccumulator:self didReceiveRetryInterval:retryInterval];
        }
        return YES;
    }

    return YES;
}

@end
