//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <XCTest/XCTest.h>

#import <STEventSource/STEventSource.h>


@interface STEventSourceTests : XCTestCase
@end

@implementation STEventSourceTests

- (void)testVersionNumber {
    XCTAssertEqual(STEventSourceVersionNumber, 1);
}

@end
