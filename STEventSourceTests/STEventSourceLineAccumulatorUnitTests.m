//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <XCTest/XCTest.h>

#import <STEventSource/STEventSourceLineAccumulator.h>


@interface STEventSourceLineAccumulatorUnitTests : XCTestCase
@end

@implementation STEventSourceLineAccumulatorUnitTests

- (void)testSimple {
    STEventSourceLineAccumulator * const a = [[STEventSourceLineAccumulator alloc] init];

    {
        NSData * const d = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([a linesByAccumulatingData:d], @[]);
        XCTAssertEqualObjects(a.data, [@"hello" dataUsingEncoding:NSUTF8StringEncoding]);
    }
    {
        NSData * const d = [@" world" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([a linesByAccumulatingData:d], @[]);
        XCTAssertEqualObjects(a.data, [@"hello world" dataUsingEncoding:NSUTF8StringEncoding]);
    }
    {
        NSData * const d = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([a linesByAccumulatingData:d], (@[
            [@"hello world" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(a.data, NSData.data);
    }
    {
        NSData * const d = [@"it\n" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([a linesByAccumulatingData:d], (@[
            [@"it" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(a.data, NSData.data);
    }
    {
        NSData * const d = [@"is a " dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([a linesByAccumulatingData:d], @[]);
        XCTAssertEqualObjects(a.data, [@"is a " dataUsingEncoding:NSUTF8StringEncoding]);
    }
    {
        NSData * const d = [@"beautiful day\ndon't you think\ni do" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([a linesByAccumulatingData:d], (@[
            [@"is a beautiful day" dataUsingEncoding:NSUTF8StringEncoding],
            [@"don't you think" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(a.data, [@"i do" dataUsingEncoding:NSUTF8StringEncoding]);
    }
    {
        NSData * const d = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([a linesByAccumulatingData:d], (@[
            [@"i do" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(a.data, NSData.data);
    }
    {
        NSData * const d = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([a linesByAccumulatingData:d], @[]);
        XCTAssertEqualObjects(a.data, [@"hello" dataUsingEncoding:NSUTF8StringEncoding]);

    }
}

- (void)testStraddlingCRLF {
    STEventSourceLineAccumulator * const a = [[STEventSourceLineAccumulator alloc] init];

    {
        NSData * const d = [@"hello\r" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([a linesByAccumulatingData:d], @[]);
        XCTAssertEqualObjects(a.data, [@"hello\r" dataUsingEncoding:NSUTF8StringEncoding]);
    }
    {
        NSData * const d = [@"\nworld" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([a linesByAccumulatingData:d], (@[
            [@"hello" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(a.data, [@"world" dataUsingEncoding:NSUTF8StringEncoding]);
    }
    {
        NSData * const d = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects([a linesByAccumulatingData:d], (@[
            [@"world" dataUsingEncoding:NSUTF8StringEncoding],
        ]));
        XCTAssertEqualObjects(a.data, NSData.data);
    }
}

@end
