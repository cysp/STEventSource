//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


extern NSString * const STEventSourceEventAccumulatorErrorDomain;

typedef NS_ENUM(NSUInteger, STEventSourceEventAccumulatorError) {
    STEventSourceEventAccumulatorUnknownError = 0,
    STEventSourceEventAccumulatorInvalidParameterError,
    STEventSourceEventAccumulatorEventTooLargeError,
};


@interface STEventSourceEventAccumulator : NSObject

@property (nonatomic,copy,nullable,readonly) NSString *type;
@property (nonatomic,copy,readonly) NSString *data;
@property (nonatomic,copy,nullable,readonly) NSString *id;
@property (nonatomic,copy,nullable,readonly) NSNumber *retry;

- (BOOL)updateWithLine:(NSString *)line error:(NSError * __autoreleasing __nullable * __nullable)error;
- (BOOL)updateWithField:(NSString *)field value:(NSString *)value error:(NSError * __autoreleasing __nullable * __nullable)error;

@end


NS_ASSUME_NONNULL_END
