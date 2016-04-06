//  Copyright © 2016 Scott Talbot. All rights reserved.

#import "STEventSourceLineAccumulator.h"
#import "STEventSourceLineAccumulator+Internal.h"


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

    [data enumerateByteRangesUsingBlock:^(const void * __nonnull bytes, NSRange byteRange, BOOL * __nonnull stop) {
        [self->_buffer appendBytes:bytes length:byteRange.length];

        NSRange lastLineRange = (NSRange){ .location = NSNotFound, .length = 0 };

        uint8_t const * const bufferBytes = self->_buffer.bytes;
        NSUInteger const bufferLength = self->_buffer.length;
        for (NSUInteger i = cursor; i < bufferLength; ++i) {
            uint8_t const c = bufferBytes[i];
            if (c == '\n' || state == STEventSourceLineAccumulatorStateAfterCR) {
                NSUInteger const lengthOfNewline = (!!(state == STEventSourceLineAccumulatorStateAfterCR)) + (!!(c == '\n')) - 1;
                NSRange const lineRange = lastLineRange = (NSRange){
                    .location = currentLineLocation,
                    .length = i - lengthOfNewline - currentLineLocation,
                };
                NSData * const lineData = [self->_buffer subdataWithRange:lineRange];
                if (lineData) {
                    [lines addObject:lineData];
                }
                currentLineLocation = i + 1;

                state = STEventSourceLineAccumulatorStateNormal;
            } else if (c == '\r') {
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
