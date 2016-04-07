//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <STEventSource/STEventSource.h>
#import <STEventSource/STEventSourceLineAccumulator.h>
#import <STEventSource/STEventSourceEventAccumulator.h>
#import <STEventSource/STEventSourceEvent.h>


NSString * const STEventSourceErrorDomain = @"STEventSourceError";


static NSTimeInterval const STEventSourceDefaultRetryInterval = 3;


static NSString *NSStringFromSTEventSourceReadyState(STEventSourceReadyState readyState) {
    switch (readyState) {
        case STEventSourceReadyStateClosed:
            return @"closed";
        case STEventSourceReadyStateConnecting:
            return @"connecting";
        case STEventSourceReadyStateOpen:
            return @"open";
    }
    return [NSString stringWithFormat:@"unknown-%lu", (unsigned long)readyState];
}


@interface STEventSource () <NSURLSessionDataDelegate,STEventSourceEventAccumulatorDelegate>
@end

@implementation STEventSource {
@private
    NSURLSession *_session;
    NSOperationQueue *_sessionDelegateQueue;
    NSURL *_url;
    NSDictionary<NSString *, NSString *> *_httpHeaders;
    NSURLSessionDataTask *_task;
    STEventSourceEventHandler _handler;
    STEventSourceCompletionHandler _completion;

    STEventSourceLineAccumulator *_lineAccumulator;
    STEventSourceEventAccumulator *_eventAccumulator;
}

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}
- (instancetype)initWithURL:(NSURL * __nonnull)url handler:(STEventSourceEventHandler __nonnull)handler completion:(STEventSourceCompletionHandler __nonnull)completion {
    return [self initWithSessionConfiguration:nil url:url httpHeaders:nil handler:handler completion:completion];
}
- (instancetype)initWithURL:(NSURL * __nonnull)url httpHeaders:(NSDictionary<NSString *,NSString *> *)httpHeaders handler:(STEventSourceEventHandler __nonnull)handler completion:(STEventSourceCompletionHandler __nonnull)completion {
    return [self initWithSessionConfiguration:nil url:url httpHeaders:httpHeaders handler:handler completion:completion];
}
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration url:(NSURL * __nonnull)url handler:(STEventSourceEventHandler __nonnull)handler completion:(STEventSourceCompletionHandler __nonnull)completion {
    return [self initWithSessionConfiguration:sessionConfiguration url:url httpHeaders:nil handler:handler completion:completion];
}
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration url:(NSURL * __nonnull)url httpHeaders:(NSDictionary<NSString *,NSString *> *)httpHeaders handler:(STEventSourceEventHandler __nonnull)handler completion:(STEventSourceCompletionHandler __nonnull)completion {

    if (!sessionConfiguration) {
        sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        sessionConfiguration.HTTPAdditionalHeaders = @{
            @"Accept": @"text/event-stream",
            @"Accept-Charset": @"utf-8",
            @"Accept-Encoding": @"identity",
        };
    }

    if ((self = [super init])) {
        _url = url.copy;
        if (httpHeaders) {
            _httpHeaders = [[NSDictionary alloc] initWithDictionary:httpHeaders copyItems:YES];
        }

        NSOperationQueue * const sessionDelegateQueue = _sessionDelegateQueue = [[NSOperationQueue alloc] init];
        sessionDelegateQueue.name = [NSString stringWithFormat:@"STEventSource.sessionDelegateQueue.%p", self];

        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:sessionDelegateQueue];

        _handler = [handler copy];
        _completion = [completion copy];
        _retryInterval = STEventSourceDefaultRetryInterval;

        _lineAccumulator = [[STEventSourceLineAccumulator alloc] init];
        _eventAccumulator = [[STEventSourceEventAccumulator alloc] initWithDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [_session invalidateAndCancel];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; url=%@>", NSStringFromClass(self.class), self, _url];
}


@synthesize readyState = _readyState;
- (STEventSourceReadyState)readyState {
    NSAssert(NSThread.isMainThread, @"not on main thread");

    return _readyState;
}

- (void)open {
    (void)[self openWithError:NULL];
}
- (BOOL)openWithError:(NSError * __nullable __autoreleasing * __nullable)error {
    NSAssert(NSThread.isMainThread, @"not on main thread");

    switch (_readyState) {
        case STEventSourceReadyStateClosed:
            break;
        case STEventSourceReadyStateConnecting:
        case STEventSourceReadyStateOpen: {
            if (error) {
                *error = [NSError errorWithDomain:STEventSourceErrorDomain code:STEventSourceInvalidOperationError userInfo:@{
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Event source opened when already in %@ state", NSStringFromSTEventSourceReadyState(_readyState)],
                }];
            }
            return NO;
        } break;
    }

    NSMutableURLRequest * const request = [[NSMutableURLRequest alloc] initWithURL:_url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    request.allHTTPHeaderFields = _httpHeaders;
    if (_lastEventId.length > 0) {
        [request setValue:_lastEventId forHTTPHeaderField:@"Last-Event-ID"];
    }

    NSURLSessionDataTask * const task = _task = [_session dataTaskWithRequest:request];
    [task resume];

    _readyState = STEventSourceReadyStateConnecting;

    return YES;
}


- (void)close {
    (void)[self closeWithError:NULL];
}
- (BOOL)closeWithError:(NSError * __nullable __autoreleasing * __nullable)error {
    NSAssert(NSThread.isMainThread, @"not on main thread");

    [_task cancel];
    _readyState = STEventSourceReadyStateClosed;
    return YES;
}


#pragma mark STEventSourceEventAccumulatorDelegate

- (void)eventAccumulator:(STEventSourceEventAccumulator *)accumulator didReceiveEvent:(STEventSourceEvent *)event {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_readyState = STEventSourceReadyStateOpen;

        if (event.id) {
            self->_lastEventId = event.id.copy;
        }

        self->_numberOfEventsHandled += 1;
        if (self->_handler) {
            self->_handler(event);
        }
    });
}

- (void)eventAccumulator:(STEventSourceEventAccumulator *)accumulator didReceiveRetryInterval:(NSTimeInterval)retryInterval {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_retryInterval = retryInterval;
    });
}


#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_readyState = STEventSourceReadyStateClosed;
        if (self->_completion) {
            self->_completion(error);
        }
    });
}


#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_readyState = STEventSourceReadyStateOpen;
    });
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSArray<NSData *> * const lines = [_lineAccumulator linesByAccumulatingData:data];
    [_eventAccumulator accumulateLines:lines];
}

@end
