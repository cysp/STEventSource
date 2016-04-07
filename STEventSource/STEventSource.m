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
@property (nonatomic,strong,readonly) NSURLSession *URLSession;
@end

@implementation STEventSource {
@private
    NSURLSession *_URLSession;
    NSOperationQueue *_URLSessionDelegateQueue;
    NSURL *_url;
    NSDictionary<NSString *, NSString *> *_httpHeaders;
    NSURLSessionDataTask *_task;
    STEventSourceEventHandler _handler;
    STEventSourceCompletionHandler _completion;
    BOOL _completionInvokedForTheCurrentSession;

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
    }

    if ((self = [super init])) {
        _url = url.copy;
        if (httpHeaders) {
            _httpHeaders = [[NSDictionary alloc] initWithDictionary:httpHeaders copyItems:YES];
        }

        NSOperationQueue * const sessionDelegateQueue = _URLSessionDelegateQueue = [[NSOperationQueue alloc] init];
        sessionDelegateQueue.name = [NSString stringWithFormat:@"STEventSource.sessionDelegateQueue.%p", self];

        _URLSession = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:sessionDelegateQueue];

        _handler = [handler copy];
        _completion = [completion copy];
        _retryInterval = STEventSourceDefaultRetryInterval;

        _lineAccumulator = [[STEventSourceLineAccumulator alloc] init];
        _eventAccumulator = [[STEventSourceEventAccumulator alloc] initWithDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [_URLSession invalidateAndCancel];
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
        } return NO;
    }

    NSMutableURLRequest * const request = [[NSMutableURLRequest alloc] initWithURL:_url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    NSMutableDictionary<NSString *, NSString *> * const allHTTPHeaderFields = @{
        @"Accept": @"text/event-stream",
        @"Accept-Charset": @"utf-8",
        @"Accept-Encoding": @"identity",
    }.mutableCopy;
    if (_httpHeaders) {
        [allHTTPHeaderFields addEntriesFromDictionary:_httpHeaders];
    }
    request.allHTTPHeaderFields = allHTTPHeaderFields;
    if (_lastEventId.length > 0) {
        [request setValue:_lastEventId forHTTPHeaderField:@"Last-Event-ID"];
    }

    NSURLSessionDataTask * const task = _task = [_URLSession dataTaskWithRequest:request];
    [task resume];

    _readyState = STEventSourceReadyStateConnecting;
    _completionInvokedForTheCurrentSession = NO;

    return YES;
}


- (void)close {
    (void)[self closeWithError:NULL];
}
- (BOOL)closeWithError:(NSError * __nullable __autoreleasing * __nullable)error {
    NSAssert(NSThread.isMainThread, @"not on main thread");

    [_task cancel];
    _readyState = STEventSourceReadyStateClosed;
    _completionInvokedForTheCurrentSession = NO;

    return YES;
}


- (void)completeWithError:(NSError *)error {
    if (_completionInvokedForTheCurrentSession) {
        return;
    }

    _completionInvokedForTheCurrentSession = YES;

    STEventSourceCompletionHandler const completion = _completion;
    if (completion) {
        completion(error);
    }
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
    if (error) {
        error = [NSError errorWithDomain:STEventSourceErrorDomain code:STEventSourceUnknownError userInfo:@{
            NSUnderlyingErrorKey: error,
        }];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_readyState = STEventSourceReadyStateClosed;
        [self completeWithError:error];
    });
}


#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse * const httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode == 404) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_readyState = STEventSourceReadyStateClosed;
            [self completeWithError:[NSError errorWithDomain:STEventSourceErrorDomain code:STEventSourceResourceNotFoundError userInfo:nil]];
        });
        return completionHandler(NSURLSessionResponseCancel);
    }
    if (httpResponse.statusCode < 200 || httpResponse.statusCode > 299) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_readyState = STEventSourceReadyStateClosed;
            [self completeWithError:[NSError errorWithDomain:STEventSourceErrorDomain code:STEventSourceUnknownError userInfo:@{
                @"HTTPStatusCode": @(httpResponse.statusCode),
                NSLocalizedDescriptionKey: [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode],
            }]];
        });
        return completionHandler(NSURLSessionResponseCancel);
    }
    NSString * const responseMIMEType = response.MIMEType;
    if (!responseMIMEType || ![responseMIMEType isEqualToString:@"text/event-stream"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_readyState = STEventSourceReadyStateClosed;
            [self completeWithError:[NSError errorWithDomain:STEventSourceErrorDomain code:STEventSourceIncorrectResponseContentTypeError userInfo:nil]];
        });
        return completionHandler(NSURLSessionResponseCancel);
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self->_readyState = STEventSourceReadyStateOpen;
    });
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_readyState = STEventSourceReadyStateOpen;
    });
    NSArray<NSData *> * const lines = [_lineAccumulator linesByAccumulatingData:data];
    [_eventAccumulator accumulateLines:lines];
}

@end
