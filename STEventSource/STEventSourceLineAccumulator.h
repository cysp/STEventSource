//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface STEventSourceLineAccumulator : NSObject

- (NSArray<NSData *> *)linesByAccumulatingData:(NSData *)data __attribute__((warn_unused_result));

@property (nonatomic,copy,readonly) NSData *data;

@end


NS_ASSUME_NONNULL_END
