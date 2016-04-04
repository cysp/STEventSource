//  Copyright © 2016 Scott Talbot. All rights reserved.

#import "STEventSourceEvent.h"


@implementation STEventSourceEvent

+ (instancetype)eventWithType:(NSString *)type data:(NSString *)data {
    return [[self alloc] initWithType:type data:data];
}

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}
- (instancetype)initWithType:(NSString *)type data:(NSString *)data {
    if ((self = [super init])) {
        _type = type.copy;
        _data = data.copy;
    }
    return self;
}

@end
