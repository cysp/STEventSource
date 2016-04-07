//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>


@interface STEventSourceTestURLProtocol : NSURLProtocol

+ (void)enqueueResponse:(NSURLResponse *)response datas:(NSArray<NSData *> *)datas;

+ (void)drainResponseQueue;

@end
