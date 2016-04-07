//  Copyright © 2016 Scott Talbot. All rights reserved.

#import "STEventSourceTestURLProtocol.h"


@interface STEventSourceTestURLProtocolQueueItem : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithResponse:(NSURLResponse *)response datas:(NSArray<NSData *> *)datas;
@property (nonatomic,strong,readonly) NSURLResponse *response;
@property (nonatomic,copy,readonly) NSArray<NSData *> *datas;
@end
@implementation STEventSourceTestURLProtocolQueueItem
- (instancetype)initWithResponse:(NSURLResponse *)response datas:(NSArray<NSData *> *)datas {
    if ((self = [super init])) {
        _response = response;
        NSMutableData * const data = [[NSMutableData alloc] init];
        for (NSData *d in datas) {
            [data appendData:d];
        }
        _datas = [[NSArray alloc] initWithArray:@[ data ] copyItems:YES];
    }
    return self;
}
@end


static NSMutableArray<STEventSourceTestURLProtocolQueueItem *> *STEventSourceTestURLProtocolQueue = nil;


@implementation STEventSourceTestURLProtocol {
@private
    BOOL _initialized;
    STEventSourceTestURLProtocolQueueItem *_queueItem;
    BOOL _stopped;
}

+ (void)initialize {
    if (self == STEventSourceTestURLProtocol.class) {
        STEventSourceTestURLProtocolQueue = [[NSMutableArray alloc] init];
    }
}

+ (void)enqueueResponse:(NSURLResponse *)response datas:(NSArray<NSData *> *)datas {
    STEventSourceTestURLProtocolQueueItem * const item = [[STEventSourceTestURLProtocolQueueItem alloc] initWithResponse:response datas:datas];
    [STEventSourceTestURLProtocolQueue addObject:item];
}

+ (void)drainResponseQueue {
    [STEventSourceTestURLProtocolQueue removeAllObjects];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    STEventSourceTestURLProtocolQueueItem * const item = STEventSourceTestURLProtocolQueue.firstObject;
    BOOL can = [item.response.URL isEqual:request.URL];
    return can;
}

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task {
    NSURLRequest * const request = task.currentRequest;
    return [self canInitWithRequest:request];
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    if ((self = [super initWithRequest:request cachedResponse:cachedResponse client:client])) {
        STEventSourceTestURLProtocolCommonInit(self);
    }
    return self;
}

- (instancetype)initWithTask:(NSURLSessionTask *)task cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    if ((self = [super initWithTask:task cachedResponse:cachedResponse client:client])) {
        STEventSourceTestURLProtocolCommonInit(self);
    }
    return self;
}

static void STEventSourceTestURLProtocolCommonInit(STEventSourceTestURLProtocol *self) {
    if (!self || self->_initialized) {
        return;
    }
    self->_initialized = YES;
    STEventSourceTestURLProtocolQueueItem * const item = STEventSourceTestURLProtocolQueue.firstObject;
    if (item) {
        [STEventSourceTestURLProtocolQueue removeObjectAtIndex:0];
    }
    self->_queueItem = item;
}

- (void)startLoading {
//    if (_stopped) {
//        return;
//    }
    [self.client URLProtocol:self didReceiveResponse:_queueItem.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
//
//    if (_stopped) {
//        return;
//    }

    for (NSData *data in _queueItem.datas) {
        NSUInteger const dataLength = data.length;
        NSRange r = (NSRange){ .length = 1 };
        for (NSUInteger location = 0; location < dataLength; ++location) {
            r.location = location;
            [self.client URLProtocol:self didLoadData:[data subdataWithRange:r]];
        }
//        [self.client URLProtocol:self didLoadData:data];
//        if (_stopped) {
//            return;
//        }
    }

    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
    _stopped = YES;
}

@end
