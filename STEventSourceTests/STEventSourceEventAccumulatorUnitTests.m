//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <XCTest/XCTest.h>

#import <STEventSource/STEventSource.h>
#import <STEventSource/STEventSourceEventAccumulator.h>
#import <STEventSource/STEventSourceEventAccumulator+Internal.h>


@interface STEventSourceEventAccumulatorTestDelegate : NSObject<STEventSourceEventAccumulatorDelegate>
@property (nonatomic,copy,nonnull,readonly) NSArray<STEventSourceEvent *> *events;
@property (nonatomic,copy,nullable,readonly) NSNumber *retry;
@end
@implementation STEventSourceEventAccumulatorTestDelegate {
@private
    NSMutableArray<STEventSourceEvent *> *_events;
}
- (instancetype)init {
    if ((self = [super init])) {
        _events = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)eventAccumulator:(STEventSourceEventAccumulator *)accumulator didReceiveEvent:(STEventSourceEvent *)event {
    [_events addObject:event];
}
- (void)eventAccumulator:(STEventSourceEventAccumulator *)accumulator didReceiveRetryInterval:(NSTimeInterval)retryInterval {
    _retry = @(retryInterval);
}
@end


@interface STEventSourceEventAccumulatorUnitTests : XCTestCase
@end

@implementation STEventSourceEventAccumulatorUnitTests

- (void)testSneakyInstantiation {
    STEventSourceEventAccumulator * const e = [(id)[STEventSourceEventAccumulator alloc] init];
    XCTAssertNotNil(e);
}

+ (NSArray<NSData *> *)datasFromStrings:(NSArray<NSString *> *)strings {
    NSMutableArray * const datas = [[NSMutableArray alloc] initWithCapacity:strings.count];
    for (NSString *string in strings) {
        NSData * const data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [datas addObject:data];
    }
    return datas.copy;
}

- (void)testSimpleEvent {
    STEventSourceEventAccumulatorTestDelegate * const accd = [[STEventSourceEventAccumulatorTestDelegate alloc] init];
    STEventSourceEventAccumulator * const acc = [[STEventSourceEventAccumulator alloc] initWithDelegate:accd];
    XCTAssertNotNil(acc);

    XCTAssertNil(acc.type);
    XCTAssertNil(acc.data);
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[ @"data: hello" ]]];
    XCTAssertNil(acc.type);
    XCTAssertEqualObjects(acc.data, @"hello");
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[ @"data: world" ]]];
    XCTAssertNil(acc.type);
    XCTAssertEqualObjects(acc.data, @"hello\nworld");
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[ @"something: okay" ]]];
    XCTAssertNil(acc.type);
    XCTAssertEqualObjects(acc.data, @"hello\nworld");
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[ @"event: hello world" ]]];
    XCTAssertEqualObjects(acc.type, @"hello world");
    XCTAssertEqualObjects(acc.data, @"hello\nworld");
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[ @"something: okay" ]]];
    XCTAssertEqualObjects(acc.type, @"hello world");
    XCTAssertEqualObjects(acc.data, @"hello\nworld");
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    XCTAssertEqual(accd.events.count, 0);

    [acc accumulateLines:[self.class datasFromStrings:@[ @"" ]]];
    XCTAssertEqual(accd.events.count, 1);

    STEventSourceEvent * const event = accd.events[0];
    XCTAssertEqualObjects(event.type, @"hello world");
    XCTAssertEqualObjects(event.data, @"hello\nworld");
    XCTAssertNil(event.id);
}

- (void)testInvalidUpdates {
    STEventSourceEventAccumulatorTestDelegate * const accd = [[STEventSourceEventAccumulatorTestDelegate alloc] init];
    STEventSourceEventAccumulator * const acc = [[STEventSourceEventAccumulator alloc] initWithDelegate:accd];
    XCTAssertNotNil(acc);

    XCTAssertEqual(acc.state, STEventSourceEventAccumulatorStateNormal);

    uint8_t const bytes[] = { 0xff, 0x00, 0xff, 0x00 };
    NSData * const data = [[NSData alloc] initWithBytes:(void *)bytes length:sizeof(bytes)];

    [acc accumulateLines:@[ data ]];

    XCTAssertEqual(acc.state, STEventSourceEventAccumulatorStateIgnoringUntilBlankLine);

    [acc accumulateLines:@[ [@"" dataUsingEncoding:NSUTF8StringEncoding] ]];

    XCTAssertEqual(acc.state, STEventSourceEventAccumulatorStateNormal);

    XCTAssertEqual(accd.events.count, 0);
}

- (void)testColonPositions {
    STEventSourceEventAccumulatorTestDelegate * const accd = [[STEventSourceEventAccumulatorTestDelegate alloc] init];
    STEventSourceEventAccumulator * const acc = [[STEventSourceEventAccumulator alloc] initWithDelegate:accd];
    XCTAssertNotNil(acc);

    XCTAssertNil(acc.type);
    XCTAssertNil(acc.data);
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[@":anything"]]];
    XCTAssertEqual(accd.events.count, 0);
    XCTAssertNil(acc.type, @"");
    XCTAssertNil(acc.data);
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[@"data: hello"]]];
    XCTAssertNil(acc.type);
    XCTAssertEqualObjects(acc.data, @"hello");
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[@"data: "]]];
    XCTAssertNil(acc.type);
    XCTAssertEqualObjects(acc.data, @"hello\n");
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[@"data:"]]];
    XCTAssertNil(acc.type);
    XCTAssertEqualObjects(acc.data, @"hello\n\n");
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[@"data"]]];
    XCTAssertNil(acc.type);
    XCTAssertEqualObjects(acc.data, @"hello\n\n\n");
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[@"data: world"]]];
    XCTAssertNil(acc.type);
    XCTAssertEqualObjects(acc.data, @"hello\n\n\n\nworld");
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    XCTAssertEqual(accd.events.count, 0);
}

- (void)testRetry {
    STEventSourceEventAccumulatorTestDelegate * const accd = [[STEventSourceEventAccumulatorTestDelegate alloc] init];
    STEventSourceEventAccumulator * const acc = [[STEventSourceEventAccumulator alloc] initWithDelegate:accd];
    XCTAssertNotNil(acc);

    XCTAssertNil(acc.type);
    XCTAssertNil(acc.data);
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[@"retry:"]]];
    XCTAssertNil(acc.type);
    XCTAssertNil(acc.data);
    XCTAssertNil(acc.id);
    XCTAssertNil(accd.retry);

    [acc accumulateLines:[self.class datasFromStrings:@[@"retry: 0"]]];
    XCTAssertNil(acc.type);
    XCTAssertNil(acc.data);
    XCTAssertNil(acc.id);
    XCTAssertEqualObjects(accd.retry, @0);

    [acc accumulateLines:[self.class datasFromStrings:@[@"retry:"]]];
    XCTAssertNil(acc.type);
    XCTAssertNil(acc.data);
    XCTAssertNil(acc.id);
    XCTAssertEqualObjects(accd.retry, @0);

    [acc accumulateLines:[self.class datasFromStrings:@[@"retry: 30"]]];
    XCTAssertNil(acc.type);
    XCTAssertNil(acc.data);
    XCTAssertNil(acc.id);
    XCTAssertEqualObjects(accd.retry, @0.03);

    [acc accumulateLines:[self.class datasFromStrings:@[@"retry: 1.5"]]];
    XCTAssertNil(acc.type);
    XCTAssertNil(acc.data);
    XCTAssertNil(acc.id);
    XCTAssertEqualObjects(accd.retry, @0.03);

    [acc accumulateLines:[self.class datasFromStrings:@[@"retry: asdf"]]];
    XCTAssertNil(acc.type);
    XCTAssertNil(acc.data);
    XCTAssertNil(acc.id);
    XCTAssertEqualObjects(accd.retry, @0.03);

    [acc accumulateLines:[self.class datasFromStrings:@[@"retry: 15"]]];
    XCTAssertNil(acc.type);
    XCTAssertNil(acc.data);
    XCTAssertNil(acc.id);
    XCTAssertEqualObjects(accd.retry, @0.015);
}

- (void)testSpecStream1 {
    NSArray<NSData *> * const lines = [self.class datasFromStrings:@[
        @"data: YHOO",
        @"data: +2",
        @"data: 10",
    ]];

    STEventSourceEventAccumulatorTestDelegate * const accd = [[STEventSourceEventAccumulatorTestDelegate alloc] init];
    STEventSourceEventAccumulator * const acc = [[STEventSourceEventAccumulator alloc] initWithDelegate:accd];

    {
        [acc accumulateLines:@[lines[0]]];
        XCTAssertNil(acc.type);
        XCTAssertEqualObjects(acc.data, @"YHOO");
        XCTAssertNil(acc.id);
        XCTAssertNil(accd.retry);
        [acc accumulateLines:@[lines[1]]];
        XCTAssertNil(acc.type);
        XCTAssertEqualObjects(acc.data, @"YHOO\n+2");
        XCTAssertNil(acc.id);
        XCTAssertNil(accd.retry);
        [acc accumulateLines:@[lines[2]]];
        XCTAssertNil(acc.type);
        XCTAssertEqualObjects(acc.data, @"YHOO\n+2\n10");
        XCTAssertNil(acc.id);
        XCTAssertNil(accd.retry);
    }

    [acc accumulateLines:[self.class datasFromStrings:@[@""]]];

    XCTAssertEqual(accd.events.count, 1);

    STEventSourceEvent * const event = accd.events[0];
    XCTAssertNil(event.type);
    XCTAssertEqualObjects(event.data, @"YHOO\n+2\n10");
    XCTAssertNil(event.id);
}

- (void)testSpecStream2 {
    NSArray<NSData *> * const lines = [self.class datasFromStrings:@[
        @": test stream",
        @"",
        @"data: first event",
        @"id: 1",
        @"",
        @"data:second event",
        @"id",
        @"",
        @"data:  third event",
    ]];

    STEventSourceEventAccumulatorTestDelegate * const accd = [[STEventSourceEventAccumulatorTestDelegate alloc] init];
    STEventSourceEventAccumulator * const acc = [[STEventSourceEventAccumulator alloc] initWithDelegate:accd];

    {
        [acc accumulateLines:@[lines[0]]];
        XCTAssertNil(acc.type);
        XCTAssertNil(acc.data);
        XCTAssertNil(acc.id);
        XCTAssertNil(accd.retry);

        [acc accumulateLines:@[lines[1]]];
        XCTAssertEqual(accd.events.count, 0);
    }

    {
        [acc accumulateLines:@[lines[2]]];
        XCTAssertNil(acc.type);
        XCTAssertEqualObjects(acc.data, @"first event");
        XCTAssertNil(acc.id);
        XCTAssertNil(accd.retry);
        [acc accumulateLines:@[lines[3]]];
        XCTAssertNil(acc.type);
        XCTAssertEqualObjects(acc.data, @"first event");
        XCTAssertEqualObjects(acc.id, @"1");
        XCTAssertNil(accd.retry);

        [acc accumulateLines:@[lines[4]]];
        XCTAssertEqual(accd.events.count, 1);

        STEventSourceEvent * const event = accd.events[0];
        XCTAssertNil(event.type);
        XCTAssertEqualObjects(event.data, @"first event");
        XCTAssertEqualObjects(event.id, @"1");

    }

    {
        [acc accumulateLines:@[lines[5]]];
        XCTAssertNil(acc.type);
        XCTAssertEqualObjects(acc.data, @"second event");
        XCTAssertNil(acc.id);
        XCTAssertNil(accd.retry);
        [acc accumulateLines:@[lines[6]]];
        XCTAssertNil(acc.type);
        XCTAssertEqualObjects(acc.data, @"second event");
        XCTAssertEqualObjects(acc.id, @"");
        XCTAssertNil(accd.retry);

        [acc accumulateLines:@[lines[7]]];
        XCTAssertEqual(accd.events.count, 2);

        STEventSourceEvent * const event = accd.events[1];
        XCTAssertNil(event.type);
        XCTAssertEqualObjects(event.data, @"second event");
        XCTAssertEqualObjects(event.id, @"");
    }

    {
        [acc accumulateLines:@[lines[8]]];
        XCTAssertNil(acc.type);
        XCTAssertEqualObjects(acc.data, @" third event");
        XCTAssertNil(acc.id);
        XCTAssertNil(accd.retry);
    }

    XCTAssertEqual(accd.events.count, 2);
}

- (void)testSpecStream3 {
    NSArray<NSData *> * const lines = [self.class datasFromStrings:@[
        @"data",
        @"",
        @"data",
        @"data",
        @"",
        @"data:",
    ]];

    STEventSourceEventAccumulatorTestDelegate * const accd = [[STEventSourceEventAccumulatorTestDelegate alloc] init];
    STEventSourceEventAccumulator * const acc = [[STEventSourceEventAccumulator alloc] initWithDelegate:accd];

    [acc accumulateLines:lines];
    XCTAssertEqual(accd.events.count, 2);

    {
        STEventSourceEvent * const e = accd.events[0];
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"");
        XCTAssertNil(e.id);
        XCTAssertNil(accd.retry);
    }

    {
        STEventSourceEvent * const e = accd.events[1];
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"\n");
        XCTAssertNil(e.id);
        XCTAssertNil(accd.retry);
    }

    XCTAssertNil(acc.type);
    XCTAssertEqualObjects(acc.data, @"");
    XCTAssertNil(acc.id);
}

- (void)testSpecStream4 {
    NSArray<NSData *> * const lines = [self.class datasFromStrings:@[
        @"data:test",
        @"",
        @"data: test",
        @"",
    ]];

    STEventSourceEventAccumulatorTestDelegate * const accd = [[STEventSourceEventAccumulatorTestDelegate alloc] init];
    STEventSourceEventAccumulator * const acc = [[STEventSourceEventAccumulator alloc] initWithDelegate:accd];

    [acc accumulateLines:lines];
    XCTAssertEqual(accd.events.count, 2);

    {
        STEventSourceEvent * const e = accd.events[0];
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"test");
        XCTAssertNil(e.id);
        XCTAssertNil(accd.retry);
    }

    {
        STEventSourceEvent * const e = accd.events[1];
        XCTAssertNil(e.type);
        XCTAssertEqualObjects(e.data, @"test");
        XCTAssertNil(e.id);
        XCTAssertNil(accd.retry);
    }
}

@end
