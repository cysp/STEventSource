//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <XCTest/XCTest.h>

#import <STEventSource/STEventSource.h>
#import <STEventSource/STEventSourceEventAccumulator.h>


@interface STEventSourceEventUnitTests : XCTestCase
@end

@implementation STEventSourceEventUnitTests

- (void)testSimpleEvent {
    STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
    XCTAssertNotNil(e);

    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"data: hello" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"hello");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"data: world" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"hello\nworld");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"something: okay" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"hello\nworld");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"event: hello world" error:NULL]);
    XCTAssertEqualObjects(e.type, @"hello world");
    XCTAssertEqualObjects(e.data, @"hello\nworld");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"something: okay" error:NULL]);
    XCTAssertEqualObjects(e.type, @"hello world");
    XCTAssertEqualObjects(e.data, @"hello\nworld");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);
}

- (void)testInvalidEventUpdates {
    STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
    XCTAssertNotNil(e);

    {
        NSError *error = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        XCTAssertFalse([e updateWithLine:nil error:&error]);
#pragma clang diagnostic pop
        XCTAssertEqualObjects(error.domain, STEventSourceEventAccumulatorErrorDomain);
        XCTAssertEqual(error.code, STEventSourceEventAccumulatorInvalidParameterError);

        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
    }

    {
        NSError *error = nil;
        XCTAssertFalse([e updateWithLine:@"" error:&error]);
        XCTAssertEqualObjects(error.domain, STEventSourceEventAccumulatorErrorDomain);
        XCTAssertEqual(error.code, STEventSourceEventAccumulatorInvalidParameterError);

        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
    }
}

- (void)testColonPositions {
    STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
    XCTAssertNotNil(e);

    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@":anything" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"data: hello" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"hello");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"data: " error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"hello\n");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"data:" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"hello\n\n");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"data" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"hello\n\n\n");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"data: world" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"hello\n\n\n\nworld");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);
}

- (void)testRetry {
    STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
    XCTAssertNotNil(e);

    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"retry:" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"");
    XCTAssertNil(e.id);
    XCTAssertNil(e.retry);

    XCTAssertTrue([e updateWithLine:@"retry: 0" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"");
    XCTAssertNil(e.id);
    XCTAssertEqualObjects(e.retry, @0);

    XCTAssertTrue([e updateWithLine:@"retry:" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"");
    XCTAssertNil(e.id);
    XCTAssertEqualObjects(e.retry, @0);

    XCTAssertTrue([e updateWithLine:@"retry: 30" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"");
    XCTAssertNil(e.id);
    XCTAssertEqualObjects(e.retry, @0.03);

    XCTAssertTrue([e updateWithLine:@"retry: 1.5" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"");
    XCTAssertNil(e.id);
    XCTAssertEqualObjects(e.retry, @0.03);

    XCTAssertTrue([e updateWithLine:@"retry: asdf" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"");
    XCTAssertNil(e.id);
    XCTAssertEqualObjects(e.retry, @0.03);

    XCTAssertTrue([e updateWithLine:@"retry: 15" error:NULL]);
    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"");
    XCTAssertNil(e.id);
    XCTAssertEqualObjects(e.retry, @0.015);
}

- (void)testSpecStream1 {
    NSArray<NSString *> * const event = @[
        @"data: YHOO",
        @"data: +2",
        @"data: 10",
    ];

    {
        STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
        XCTAssertTrue([e updateWithLine:event[0] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"YHOO");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
        XCTAssertTrue([e updateWithLine:event[1] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"YHOO\n+2");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
        XCTAssertTrue([e updateWithLine:event[2] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"YHOO\n+2\n10");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
    }
}

- (void)testSpecStream2 {
    NSArray<NSString *> * const event1 = @[
        @": test stream",
    ];
    NSArray<NSString *> * const event2 = @[
        @"data: first event",
        @"id: 1",
    ];
    NSArray<NSString *> * const event3 = @[
        @"data:second event",
        @"id",
    ];
    NSArray<NSString *> * const event4 = @[
        @"data:  third event",
    ];

    {
        STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
        XCTAssertTrue([e updateWithLine:event1[0] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
    }

    {
        STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
        XCTAssertTrue([e updateWithLine:event2[0] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"first event");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
        XCTAssertTrue([e updateWithLine:event2[1] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"first event");
        XCTAssertEqualObjects(e.id, @"1");
        XCTAssertNil(e.retry);
    }

    {
        STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
        XCTAssertTrue([e updateWithLine:event3[0] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"second event");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
        XCTAssertTrue([e updateWithLine:event3[1] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"second event");
        XCTAssertEqualObjects(e.id, @"");
        XCTAssertNil(e.retry);
    }

    {
        STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
        XCTAssertTrue([e updateWithLine:event4[0] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @" third event");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
    }
}

- (void)testSpecStream3 {
    NSArray<NSString *> * const event1 = @[
        @"data",
    ];
    NSArray<NSString *> * const event2 = @[
        @"data",
        @"data",
    ];

    {
        STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
        XCTAssertTrue([e updateWithLine:event1[0] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
    }

    {
        STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
        XCTAssertTrue([e updateWithLine:event2[0] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
        XCTAssertTrue([e updateWithLine:event2[1] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"\n");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
    }
}

- (void)testSpecStream4 {
    NSArray<NSString *> * const event1 = @[
        @"data:test",
    ];
    NSArray<NSString *> * const event2 = @[
        @"data: test",
    ];

    {
        STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
        XCTAssertTrue([e updateWithLine:event1[0] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"test");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
    }

    {
        STEventSourceEventAccumulator * const e = [[STEventSourceEventAccumulator alloc] init];
        XCTAssertTrue([e updateWithLine:event2[0] error:NULL]);
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"test");
        XCTAssertNil(e.id);
        XCTAssertNil(e.retry);
    }
}

@end
