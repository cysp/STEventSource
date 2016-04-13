//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <STEventSource/STEventSourceEvent.h>


@implementation STEventSourceEvent

+ (instancetype)eventWithType:(NSString * __nullable)type data:(NSString *)data id:(NSString * __nullable)id {
    return [[self alloc] initWithType:type data:data id:id];
}

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}
- (instancetype)initWithType:(NSString * __nullable)type data:(NSString *)data id:(NSString * __nullable)id {
    if ((self = [super init])) {
        _type = type.copy;
        _data = data.copy;
        _id = id.copy;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; type=%@; data=%@; id=%@>", NSStringFromClass(self.class), (void *)self, _type, _data, _id];
}

@end
