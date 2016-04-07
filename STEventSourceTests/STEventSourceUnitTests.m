//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <XCTest/XCTest.h>

#import <STEventSource/STEventSource.h>


@interface STEventSource (STEventSourceUnitTests) <NSURLSessionTaskDelegate,NSURLSessionDataDelegate>
@end


@interface STEventSourceUnitTests : XCTestCase
@end

@implementation STEventSourceUnitTests

- (void)testInvalidInstantiation {
    STEventSource *e;
    XCTAssertThrows(e = [(id)[STEventSource alloc] init]);
    XCTAssertNil(e);
}

- (void)testInstantiation {
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    {
        STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        } completion:^(NSError * __nullable error) {
        }];
        XCTAssertNotNil(e);
        XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);
    }
    {
        STEventSource * const e = [[STEventSource alloc] initWithURL:url httpHeaders:@{} handler:^(id<STEventSourceEvent> __nonnull event) {
        } completion:^(NSError * __nullable error) {
        }];
        XCTAssertNotNil(e);
        XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);
    }
    {
        STEventSource * const e = [[STEventSource alloc] initWithSessionConfiguration:nil url:url handler:^(id<STEventSourceEvent> __nonnull event) {
        } completion:^(NSError * __nullable error) {
        }];
        XCTAssertNotNil(e);
        XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);
    }
    {
        STEventSource * const e = [[STEventSource alloc] initWithSessionConfiguration:nil url:url httpHeaders:@{
            @"key": @"value",
        } handler:^(id<STEventSourceEvent> __nonnull event) {
        } completion:^(NSError * __nullable error) {
        }];
        XCTAssertNotNil(e);
        XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);
    }
}

- (void)testDescription {
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
    } completion:^(NSError * _Nullable error) {
    }];
    XCTAssertNotNil(e);
    XCTAssertNotNil(e.description);
}

- (void)testResourceNotFoundError {
    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
    } completion:^(NSError * __nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, STEventSourceErrorDomain);
        XCTAssertEqual(error.code, STEventSourceResourceNotFoundError);
    }];

    NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:404 HTTPVersion:@"HTTP/1.1" headerFields:@{
        @"Content-Type": @"text/event-stream",
    }];

    XCTestExpectation * const receiveResponseExpectation = [self expectationWithDescription:@"handles HTTP response"];
    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    [e URLSession:(id __nonnull)nil dataTask:(id __nonnull)nil didReceiveResponse:response completionHandler:^(NSURLSessionResponseDisposition disposition) {
        [receiveResponseExpectation fulfill];
        XCTAssertEqual(disposition, NSURLSessionResponseCancel);
    }];

    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainQueueRunExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertNil(e.lastEventId);
    XCTAssertEqual(events.count, 0);
}

- (void)testPaymentRequiredStatusCode {
    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
    } completion:^(NSError * __nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, STEventSourceErrorDomain);
        XCTAssertEqual(error.code, STEventSourceUnknownError);
        XCTAssertEqualObjects(error.userInfo[@"HTTPStatusCode"], @402);
    }];

    NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:402 HTTPVersion:@"HTTP/1.1" headerFields:@{
        @"Content-Type": @"text/event-stream",
    }];

    XCTestExpectation * const receiveResponseExpectation = [self expectationWithDescription:@"handles HTTP response"];
    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    [e URLSession:(id __nonnull)nil dataTask:(id __nonnull)nil didReceiveResponse:response completionHandler:^(NSURLSessionResponseDisposition disposition) {
        [receiveResponseExpectation fulfill];
        XCTAssertEqual(disposition, NSURLSessionResponseCancel);
    }];

    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainQueueRunExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertNil(e.lastEventId);
    XCTAssertEqual(events.count, 0);
}

- (void)testIncorrectResponseContentType {
    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
    } completion:^(NSError * __nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, STEventSourceErrorDomain);
        XCTAssertEqual(error.code, STEventSourceIncorrectResponseContentTypeError);
    }];

    NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{
        @"Content-Type": @"text/octet-stream",
    }];

    XCTestExpectation * const receiveResponseExpectation = [self expectationWithDescription:@"handles HTTP response"];
    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    [e URLSession:(id __nonnull)nil dataTask:(id __nonnull)nil didReceiveResponse:response completionHandler:^(NSURLSessionResponseDisposition disposition) {
        [receiveResponseExpectation fulfill];
        XCTAssertEqual(disposition, NSURLSessionResponseCancel);
    }];

    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainQueueRunExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertNil(e.lastEventId);
    XCTAssertEqual(events.count, 0);
}

- (void)testOpeningWhilstOpen {
    NSData * const data = [@"data: a\n\n" dataUsingEncoding:NSUTF8StringEncoding];

    XCTestExpectation * __block receiveEventExpectation = nil;
    XCTestExpectation * __block receiveResponseExpectation = nil;

    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
        [receiveEventExpectation fulfill];
    } completion:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{
        @"Content-Type": @"text/event-stream",
    }];

    receiveResponseExpectation = [self expectationWithDescription:@"handles HTTP response"];
    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    [e URLSession:(id __nonnull)nil dataTask:(id __nonnull)nil didReceiveResponse:response completionHandler:^(NSURLSessionResponseDisposition disposition) {
        [receiveResponseExpectation fulfill];
        XCTAssertEqual(disposition, NSURLSessionResponseAllow);
    }];

    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainQueueRunExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateOpen);
    XCTAssertEqual(e.retryInterval, 3);

    NSError *error = nil;
    XCTAssertFalse([e openWithError:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, STEventSourceErrorDomain);
    XCTAssertEqual(error.code, STEventSourceInvalidOperationError);

    receiveEventExpectation = [self expectationWithDescription:@"receive event"];
    [e URLSession:(id __nonnull)nil dataTask:(id __nonnull)nil didReceiveData:data];

    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateOpen);

    [e close];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertNil(e.lastEventId);
    XCTAssertEqual(events.count, 1);

    id<STEventSourceEvent> const event = events[0];
    XCTAssertNil(event.type);
    XCTAssertEqualObjects(event.data, @"a");
}

- (void)testRetryInterval {
    NSData * const data = [@"data: a\nretry: 12345\ndata: b\n\n" dataUsingEncoding:NSUTF8StringEncoding];

    XCTestExpectation * __block receiveEventExpectation = nil;
    XCTestExpectation * __block receiveResponseExpectation = nil;

    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
        [receiveEventExpectation fulfill];
    } completion:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{
        @"Content-Type": @"text/event-stream",
    }];

    receiveResponseExpectation = [self expectationWithDescription:@"handles HTTP response"];
    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    [e URLSession:(id __nonnull)nil dataTask:(id __nonnull)nil didReceiveResponse:response completionHandler:^(NSURLSessionResponseDisposition disposition) {
        [receiveResponseExpectation fulfill];
        XCTAssertEqual(disposition, NSURLSessionResponseAllow);
    }];

    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainQueueRunExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateOpen);
    XCTAssertEqual(e.retryInterval, 3);

    receiveEventExpectation = [self expectationWithDescription:@"receive event"];
    [e URLSession:(id __nonnull)nil dataTask:(id __nonnull)nil didReceiveData:data];

    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateOpen);
    XCTAssertEqual(e.retryInterval, 12.345);

    [e close];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertNil(e.lastEventId);
    XCTAssertEqual(events.count, 1);

    id<STEventSourceEvent> const event = events[0];
    XCTAssertNil(event.type);
    XCTAssertEqualObjects(event.data, @"a\nb");
}

- (void)testSpecStream1 {
    NSData * const data = [@"data: YHOO\ndata: +2\ndata: 10\n\n" dataUsingEncoding:NSUTF8StringEncoding];

    XCTestExpectation * __block receiveEventExpectation = nil;
    XCTestExpectation * __block receiveResponseExpectation = nil;

    NSMutableArray<id<STEventSourceEvent>> * const events = [[NSMutableArray alloc] init];
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent> __nonnull event) {
        [events addObject:event];
        [receiveEventExpectation fulfill];
    } completion:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    NSHTTPURLResponse * const response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{
        @"Content-Type": @"text/event-stream",
    }];

    receiveResponseExpectation = [self expectationWithDescription:@"handles HTTP response"];
    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    [e URLSession:(id __nonnull)nil dataTask:(id __nonnull)nil didReceiveResponse:response completionHandler:^(NSURLSessionResponseDisposition disposition) {
        [receiveResponseExpectation fulfill];
        XCTAssertEqual(disposition, NSURLSessionResponseAllow);
    }];

    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTestExpectation * const mainQueueRunExpectation = [self expectationWithDescription:@"main queue run"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainQueueRunExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateOpen);

    receiveEventExpectation = [self expectationWithDescription:@"receive event"];
    [e URLSession:(id __nonnull)nil dataTask:(id __nonnull)nil didReceiveData:data];

    [self waitForExpectationsWithTimeout:.5 handler:^(NSError * __nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateOpen);

    [e close];

    XCTAssertEqual(e.readyState, STEventSourceReadyStateClosed);

    XCTAssertNil(e.lastEventId);
    XCTAssertEqual(events.count, 1);

    id<STEventSourceEvent> const event = events[0];
    XCTAssertNil(event.type);
    XCTAssertEqualObjects(event.data, @"YHOO\n+2\n10");
}

@end
