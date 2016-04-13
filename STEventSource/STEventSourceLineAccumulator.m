//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <STEventSource/STEventSourceLineAccumulator.h>
#import <STEventSource/STEventSourceLineAccumulator+Internal.h>


@implementation STEventSourceLineAccumulator {
@private
    NSMutableData *_buffer;
    STEventSourceLineAccumulatorState _state;
}

- (instancetype)init {
    if ((self = [super init])) {
        _buffer = [[NSMutableData alloc] init];
    }
    return self;
}

- (STEventSourceLineAccumulatorState)state {
    return _state;
}
- (NSData *)data {
    return _buffer.copy;
}

- (NSArray<NSData *> *)linesByAccumulatingData:(NSData *)data {
    NSMutableArray<NSData *> * const lines = [[NSMutableArray alloc] init];

    STEventSourceLineAccumulatorState __block state = self->_state;
    NSUInteger __block currentLineLocation = 0;
    NSUInteger __block cursor = _buffer.length;

    [data enumerateByteRangesUsingBlock:^(const void * __nonnull bytes, NSRange byteRange, BOOL * __nonnull __unused stop) {
        [self->_buffer appendBytes:bytes length:byteRange.length];

        uint8_t const * const bufferBytes = self->_buffer.bytes;
        NSUInteger const bufferLength = self->_buffer.length;
        for (; cursor < bufferLength; ++cursor) {
            uint8_t const c = bufferBytes[cursor];
            BOOL const isAfterCR = (state == STEventSourceLineAccumulatorStateAfterCR);
            if (c == '\n') {
                if (isAfterCR) {
                    currentLineLocation = cursor + 1;
                } else {
                    NSRange const lineRange = (NSRange){
                        .location = currentLineLocation,
                        .length = cursor /*- (isAfterCR ? 1 : 0)*/ - currentLineLocation,
                    };
                    NSData * const lineData = [self->_buffer subdataWithRange:lineRange];
                    if (lineData) {
                        [lines addObject:lineData];
                    }
                    currentLineLocation = cursor + 1;
                }
                state = STEventSourceLineAccumulatorStateNormal;
            } else if (c == '\r') {
                NSRange const lineRange = (NSRange){
                    .location = currentLineLocation,
                    .length = cursor - currentLineLocation,
                };
                NSData * const lineData = [self->_buffer subdataWithRange:lineRange];
                if (lineData) {
                    [lines addObject:lineData];
                }
                currentLineLocation = cursor + 1;
                state = STEventSourceLineAccumulatorStateAfterCR;
            } else {
                state = STEventSourceLineAccumulatorStateNormal;
            }
        }
    }];

    if (currentLineLocation != 0) {
        NSUInteger const bufferLength = _buffer.length;
        NSData * const remainingData = [_buffer subdataWithRange:(NSRange){ .location = currentLineLocation, .length = bufferLength - currentLineLocation }];
        [_buffer setData:remainingData];
    }
    _state = state;

    return lines.copy;
}

@end
