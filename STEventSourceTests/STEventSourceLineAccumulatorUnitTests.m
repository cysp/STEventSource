//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <XCTest/XCTest.h>

#import <STEventSource/STEventSource.h>
#import <STEventSource/STEventSourceLineAccumulator.h>
#import <STEventSource/STEventSourceLineAccumulator+Internal.h>


@interface STEventSourceLineAccumulatorUnitTests : XCTestCase
@end

@implementation STEventSourceLineAccumulatorUnitTests

- (void)testSimple {
    STEventSourceLineAccumulator * const acc = [[STEventSourceLineAccumulator alloc] init];

    {
        NSData * const d = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([acc linesByAccumulatingData:d], @[]);
        XCTAssertEqualObjects(acc.data, [@"hello" dataUsingEncoding:NSUTF8StringEncoding]);
    }
    {
        NSData * const d = [@" world" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([acc linesByAccumulatingData:d], @[]);
        XCTAssertEqualObjects(acc.data, [@"hello world" dataUsingEncoding:NSUTF8StringEncoding]);
    }
    {
        NSData * const d = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([acc linesByAccumulatingData:d], (@[
            [@"hello world" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(acc.data, NSData.data);
    }
    {
        NSData * const d = [@"it\n" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([acc linesByAccumulatingData:d], (@[
            [@"it" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(acc.data, NSData.data);
    }
    {
        NSData * const d = [@"is a " dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([acc linesByAccumulatingData:d], @[]);
        XCTAssertEqualObjects(acc.data, [@"is a " dataUsingEncoding:NSUTF8StringEncoding]);
    }
    {
        NSData * const d = [@"beautiful day\ndon't you think\ni do" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([acc linesByAccumulatingData:d], (@[
            [@"is a beautiful day" dataUsingEncoding:NSUTF8StringEncoding],
            [@"don't you think" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(acc.data, [@"i do" dataUsingEncoding:NSUTF8StringEncoding]);
    }
    {
        NSData * const d = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([acc linesByAccumulatingData:d], (@[
            [@"i do" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(acc.data, NSData.data);
    }
    {
        NSData * const d = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([acc linesByAccumulatingData:d], @[]);
        XCTAssertEqualObjects(acc.data, [@"hello" dataUsingEncoding:NSUTF8StringEncoding]);

    }
}

- (void)testStraddlingCRLF {
    STEventSourceLineAccumulator * const acc = [[STEventSourceLineAccumulator alloc] init];

    XCTAssertEqual(acc.state, STEventSourceLineAccumulatorStateNormal);
    {
        NSData * const d = [@"hello\r" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([acc linesByAccumulatingData:d], @[]);
        XCTAssertEqualObjects(acc.data, [@"hello\r" dataUsingEncoding:NSUTF8StringEncoding]);
    }
    XCTAssertEqual(acc.state, STEventSourceLineAccumulatorStateAfterCR);
    {
        NSData * const d = [@"\nworld" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([acc linesByAccumulatingData:d], (@[
            [@"hello" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(acc.data, [@"world" dataUsingEncoding:NSUTF8StringEncoding]);
    }
    XCTAssertEqual(acc.state, STEventSourceLineAccumulatorStateNormal);
    {
        NSData * const d = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([acc linesByAccumulatingData:d], (@[
            [@"world" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(acc.data, NSData.data);
    }
    XCTAssertEqual(acc.state, STEventSourceLineAccumulatorStateNormal);
}

- (void)testSpecStream1 {
    NSData * const data = [@"data: YHOO\ndata: +2\ndata: 10\n\n" dataUsingEncoding:NSUTF8StringEncoding];

    STEventSourceLineAccumulator * const acc = [[STEventSourceLineAccumulator alloc] init];
    NSMutableArray<NSData *> * const lines = [[NSMutableArray alloc] init];

    NSUInteger const dataLength = data.length;
    NSRange r = (NSRange){ .length = 1 };
    for (NSUInteger location = 0; location < dataLength; ++location) {
        r.location = location;
        NSData * const d = [data subdataWithRange:r];
        [lines addObjectsFromArray:[acc linesByAccumulatingData:d]];
    }

    NSMutableString * const string = [[NSMutableString alloc] init];
    for (NSData *lineData in lines) {
        NSString * const line = [[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding];
        [string appendFormat:@"%@\n", line];
    }
    XCTAssertEqualObjects(string, @"data: YHOO\ndata: +2\ndata: 10\n\n");
}

- (void)testLastEventId {
    NSData * const data = [@"id: 1\ndata: hello\n\nid: 2\ndata: world\n\n" dataUsingEncoding:NSUTF8StringEncoding];

    STEventSourceLineAccumulator * const acc = [[STEventSourceLineAccumulator alloc] init];
    NSMutableArray<NSData *> * const lines = [[NSMutableArray alloc] init];

    NSUInteger const dataLength = data.length;
    NSRange r = (NSRange){ .length = 1 };
    for (NSUInteger location = 0; location < dataLength; ++location) {
        r.location = location;
        NSData * const d = [data subdataWithRange:r];
        [lines addObjectsFromArray:[acc linesByAccumulatingData:d]];
    }

    NSMutableString * const string = [[NSMutableString alloc] init];
    for (NSData *lineData in lines) {
        NSString * const line = [[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding];
        [string appendFormat:@"%@\n", line];
    }
    XCTAssertEqualObjects(string, @"id: 1\ndata: hello\n\nid: 2\ndata: world\n\n");
}

@end
