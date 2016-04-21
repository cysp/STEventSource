//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <XCTest/XCTest.h>

#import <STEventSource/STEventSource.h>
#import <STEventSource/STEventSource+Internal.h>
#import "STEventSourceTestURLProtocol.h"

#import <objc/runtime.h>


typedef NSURLSessionConfiguration *(*NSURLSessionConfiguration_ephemeralSessionConfiguration_t)(Class self, SEL _cmd);
static Class NSURLSessionConfigurationMetaClass = NULL;
static NSURLSessionConfiguration_ephemeralSessionConfiguration_t NSURLSessionConfiguration_ephemeralSessionConfiguration_f = NULL;

static NSURLSessionConfiguration *STEventSourceIntegrationTests_NSURLSessionConfiguration_ephemeralSessionConfiguration(Class self, SEL _cmd) {
    NSURLSessionConfiguration * const sessionConfiguration = NSURLSessionConfiguration_ephemeralSessionConfiguration_f(self, _cmd);
    Class const STEventSourceTestURLProtocolClass = STEventSourceTestURLProtocol.class;
    if (STEventSourceTestURLProtocolClass) {
        sessionConfiguration.protocolClasses = @[
            STEventSourceTestURLProtocolClass,
        ];
    }
    return sessionConfiguration;
}


@interface STEventSourceIntegrationTests : XCTestCase
@end

@implementation STEventSourceIntegrationTests

+ (void)setUp {
    NSURLSessionConfigurationMetaClass = objc_getMetaClass("NSURLSessionConfiguration");
    if (NSURLSessionConfigurationMetaClass) {
        NSURLSessionConfiguration_ephemeralSessionConfiguration_f = (NSURLSessionConfiguration_ephemeralSessionConfiguration_t)class_replaceMethod(NSURLSessionConfigurationMetaClass, sel_registerName("ephemeralSessionConfiguration"), (IMP)STEventSourceIntegrationTests_NSURLSessionConfiguration_ephemeralSessionConfiguration, "@@:");
    }
}

+ (void)tearDown {
    if (NSURLSessionConfigurationMetaClass && NSURLSessionConfiguration_ephemeralSessionConfiguration_f) {
        class_replaceMethod(NSURLSessionConfigurationMetaClass, sel_registerName("ephemeralSessionConfiguration"), (IMP)NSURLSessionConfiguration_ephemeralSessionConfiguration_f, "@@:");
    }
}

- (void)tearDown {
    [STEventSourceTestURLProtocol drainResponseQueue];
}

- (void)testOpeningWhilstOpen {
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:404 HTTPVersion:@"HTTP/1.1" headerFields:@{
        @"Content-Type": @"text/plain",
    }];
    NSData * const data = [@"resource not found\n" dataUsingEncoding:NSUTF8StringEncoding];

    [STEventSourceTestURLProtocol enqueueResponse:response datas:@[ data ]];

    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];

    XCTestExpectation * const completionExecutedExpectation = [self expectationWithDescription:@"completion block executed"];

    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
    } completion:^(NSError * __nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, STEventSourceErrorDomain);
        XCTAssertEqual(error.code, STEventSourceResourceNotFoundError);
        [completionExecutedExpectation fulfill];
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    NSError *error = nil;
    XCTAssertTrue([e openWithError:&error]);
    XCTAssertFalse([e openWithError:&error]);
    XCTAssertFalse([e openWithError:&error]);

    {
        XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [mainQueueRunExpectation fulfill];
        });
    }
    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertNil(e.lastEventId);
    XCTAssertEqual(events.count, 0);
}

- (void)testResourceNotFoundError {
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:404 HTTPVersion:@"HTTP/1.1" headerFields:@{
        @"Content-Type": @"text/plain",
    }];
    NSData * const data = [@"resource not found\n" dataUsingEncoding:NSUTF8StringEncoding];

    [STEventSourceTestURLProtocol enqueueResponse:response datas:@[ data ]];

    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];

    XCTestExpectation * const completionExecutedExpectation = [self expectationWithDescription:@"completion block executed"];

    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
    } completion:^(NSError * __nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, STEventSourceErrorDomain);
        XCTAssertEqual(error.code, STEventSourceResourceNotFoundError);
        [completionExecutedExpectation fulfill];
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    [e open];

    {
        XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [mainQueueRunExpectation fulfill];
        });
    }
    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertNil(e.lastEventId);
    XCTAssertEqual(events.count, 0);
}

- (void)testPaymentRequiredStatusCode {
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:402 HTTPVersion:@"HTTP/1.1" headerFields:@{
        @"Content-Type": @"text/event-stream",
    }];

    [STEventSourceTestURLProtocol enqueueResponse:response datas:@[]];

    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];

    XCTestExpectation * const completionExecutedExpectation = [self expectationWithDescription:@"completion block executed"];

    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
    } completion:^(NSError * __nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, STEventSourceErrorDomain);
        XCTAssertEqual(error.code, STEventSourceUnknownError);
        XCTAssertEqualObjects(error.userInfo[@"HTTPStatusCode"], @402);
        [completionExecutedExpectation fulfill];
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    [e open];

    {
        XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [mainQueueRunExpectation fulfill];
        });
    }
    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertNil(e.lastEventId);
    XCTAssertEqual(events.count, 0);
}

- (void)testIncorrectResponseContentType {
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{
        @"Content-Type": @"text/octet-stream",
    }];
    NSData * const data = [@"hello world\n" dataUsingEncoding:NSUTF8StringEncoding];

    [STEventSourceTestURLProtocol enqueueResponse:response datas:@[ data ]];

    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];

    XCTestExpectation * const completionExecutedExpectation = [self expectationWithDescription:@"completion block executed"];

    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
    } completion:^(NSError * __nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, STEventSourceErrorDomain);
        XCTAssertEqual(error.code, STEventSourceIncorrectResponseContentTypeError);
        [completionExecutedExpectation fulfill];
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    [e open];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateConnecting);

    {
        XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [mainQueueRunExpectation fulfill];
        });
    }
    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertNil(e.lastEventId);
    XCTAssertEqual(events.count, 0);
}

- (void)testSpecStream1 {
    XCTestExpectation * const receiveEventExpectation = [self expectationWithDescription:@"receive event"];

    NSURL * const url = [NSURL URLWithString:@"mock://example.org/server-sent-events"];
    NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{
        @"Content-Type": @"text/event-stream",
    }];
    NSData * const data = [@"data: YHOO\ndata: +2\ndata: 10\n\n" dataUsingEncoding:NSUTF8StringEncoding];

    [STEventSourceTestURLProtocol enqueueResponse:response datas:@[ data ]];

    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];
    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
        [receiveEventExpectation fulfill];
    } completion:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertTrue([e openWithError:NULL]);

    XCTAssertEqual(e.readyState, STEventSourceReadyStateConnecting);

    {
        XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [mainQueueRunExpectation fulfill];
        });
    }
    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    [e close];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertNil(e.lastEventId);
    XCTAssertEqual(events.count, 1);

    id<STEventSourceEvent> const event = events[0];
    XCTAssertNil(event.type);
    XCTAssertEqualObjects(event.data, @"YHOO\n+2\n10");
}

- (void)testLastEventId {
    XCTestExpectation * __block receiveEventExpectation = nil;

    NSURL * const url = [NSURL URLWithString:@"mock://example.org/server-sent-events"];

    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];

    STEventSource * const e = [[STEventSource alloc] initWithURL:url httpHeaders:@{
        @"something": @"something",
    } handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
        XCTAssertNotNil(receiveEventExpectation);
        [receiveEventExpectation fulfill];
    } completion:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    {
        NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{
            @"Content-Type": @"text/event-stream",
        }];
        NSData * const data = [@"id: 1\ndata: hello\n\n" dataUsingEncoding:NSUTF8StringEncoding];

        [STEventSourceTestURLProtocol enqueueResponse:response datas:@[ data ]];
    }

    {
        XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

        XCTAssertTrue([e openWithError:NULL]);

        XCTAssertEqual(e.readyState, STEventSourceReadyStateConnecting);

        {
            XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [mainQueueRunExpectation fulfill];
            });
        }
        [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
            XCTAssertNil(error);
        }];

        receiveEventExpectation = [self expectationWithDescription:@"receive event"];

        {
            XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [mainQueueRunExpectation fulfill];
            });
        }
        [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
            XCTAssertNil(error);
        }];

        [e close];

        XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

        XCTAssertEqualObjects(e.lastEventId, @"1");
    }

    XCTAssertEqual(events.count, 1);

    {
        NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{
            @"Content-Type": @"text/event-stream",
        }];
        NSData * const data = [@"id: 2\ndata: world\n\n" dataUsingEncoding:NSUTF8StringEncoding];

        [STEventSourceTestURLProtocol enqueueResponse:response datas:@[ data ]];
    }

    {
        XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

        XCTAssertTrue([e openWithError:NULL]);

        XCTAssertEqual(e.readyState, STEventSourceReadyStateConnecting);

        {
            XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [mainQueueRunExpectation fulfill];
            });
        }
        [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
            XCTAssertNil(error);
        }];

        receiveEventExpectation = [self expectationWithDescription:@"receive event"];

        {
            XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [mainQueueRunExpectation fulfill];
            });
        }
        [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
            XCTAssertNil(error);
        }];

        [e close];

        XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

        XCTAssertEqualObjects(e.lastEventId, @"2");
    }

    XCTAssertEqual(events.count, 2);

    {
        id<STEventSourceEvent> const event = events[0];
        XCTAssertNil(event.type);
        XCTAssertEqualObjects(event.data, @"hello");
    }
    {
        id<STEventSourceEvent> const event = events[1];
        XCTAssertNil(event.type);
        XCTAssertEqualObjects(event.data, @"world");
    }
}

@end
