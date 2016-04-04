//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>

#import <STEventSource/STEventSource.h>


NS_ASSUME_NONNULL_BEGIN


@interface STEventSourceEvent : NSObject<STEventSourceEvent>

+ (instancetype)eventWithType:(NSString * __nullable)type data:(NSString *)data;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(NSString * __nullable)type data:(NSString *)data;

@property (nonatomic,copy,nullable,readonly) NSString *type;
@property (nonatomic,copy,readonly) NSString *data;

@end


NS_ASSUME_NONNULL_END
