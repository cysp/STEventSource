//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <XCTest/XCTest.h>

#import <STEventSource/STEventSource.h>
#import <STEventSource/STEventSourceEvent.h>


@interface STEventSourceEventUnitTests : XCTestCase
@end

@implementation STEventSourceEventUnitTests

- (void)testInvalidInstantiation {
    STEventSourceEvent *e;
    XCTAssertThrows(e = [(id)[STEventSourceEvent alloc] init]);
    XCTAssertNil(e);
}

- (void)testInstantiation {
    STEventSourceEvent * const e = [[STEventSourceEvent alloc] initWithType:nil data:@"data" id:nil];
    XCTAssertNotNil(e);

    XCTAssertNil(e.type);
    XCTAssertEqualObjects(e.data, @"data");
    XCTAssertNil(e.id);
}

- (void)testDescription {
    STEventSourceEvent * const e = [[STEventSourceEvent alloc] initWithType:nil data:@"data" id:nil];
    XCTAssertNotNil(e);
    XCTAssertNotNil(e.description);
}

@end
