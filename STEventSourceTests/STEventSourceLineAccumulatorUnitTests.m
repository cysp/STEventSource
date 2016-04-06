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

@end
