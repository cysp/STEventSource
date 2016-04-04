//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <STEventSource/STEventSource.h>
#import <STEventSource/STEventSourceLineAccumulator.h>
#import <STEventSource/STEventSourceEventAccumulator.h>
#import <STEventSource/STEventSourceEvent.h>


static NSTimeInterval const STEventSourceDefaultRetryInterval = 3;


@interface STEventSource () <NSURLSessionDataDelegate>
@end

@implementation STEventSource {
@private
    NSURLSession *_session;
    NSURLSessionDataTask *_task;
    STEventSourceEventHandler _handler;
    STEventSourceCompletionHandler _completion;

    STEventSourceLineAccumulator *_accumulator;
    STEventSourceEventAccumulator *_currentEvent;
}

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration request:(NSURLRequest *)request handler:(STEventSourceEventHandler)handler completion:(STEventSourceCompletionHandler)completion {

    if (!sessionConfiguration) {
        sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    }

    if ((self = [super init])) {
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
        _handler = [handler copy];
        _completion = [completion copy];
        _retryInterval = STEventSourceDefaultRetryInterval;

        _accumulator = [[STEventSourceLineAccumulator alloc] init];

        _task = [_session dataTaskWithRequest:request];
        [_task resume];
    }
    return self;
}


#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    NSParameterAssert(NSThread.isMainThread);

    _readyState = STEventSourceReadyStateClosed;
    if (_completion) {
        _completion(error);
    }
}


#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSParameterAssert(NSThread.isMainThread);

    _readyState = STEventSourceReadyStateOpen;
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSParameterAssert(NSThread.isMainThread);

    _readyState = STEventSourceReadyStateOpen;

    NSMutableArray<STEventSourceEvent *> * const events = [[NSMutableArray alloc] init];

    for (NSData *line in [_accumulator linesByAccumulatingData:data]) {
        if (line.length == 0) {
            if (_currentEvent) {
                if (_currentEvent.id) {
                    _lastEventId = _currentEvent.id.copy;
                }
                if (_currentEvent.retry) {
                    _retryInterval = _currentEvent.retry.doubleValue;
                }
                STEventSourceEvent * const event = [STEventSourceEvent eventWithType:_currentEvent.type data:_currentEvent.data];
                if (event) {
                    [events addObject:event];
                }
                _currentEvent = nil;
            }
        } else {
            NSString * const lineString = [[NSString alloc] initWithData:line encoding:NSUTF8StringEncoding];
            if (!_currentEvent) {
                _currentEvent = [[STEventSourceEventAccumulator alloc] init];
            }
            [_currentEvent updateWithLine:lineString error:NULL];
        }
    }

    if (_handler) {
        for (STEventSourceEvent *event in events) {
            _handler(event);
        }
    }
}

@end
