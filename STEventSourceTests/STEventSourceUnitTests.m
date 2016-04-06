//  Copyright © 2016 Scott Talbot. All rights reserved.

#import <XCTest/XCTest.h>

#import <STEventSource/STEventSource.h>


@interface STEventSourceUnitTests : XCTestCase
@end

@implementation STEventSourceUnitTests

- (void)testInvalidInstantiation {
    STEventSource *e;
    XCTAssertThrows(e = [(id)[STEventSource alloc] init]);
    XCTAssertNil(e);
}

- (void)testDescription {
    NSURL * const url = [NSURL URLWithString:@"https://example.org/server-sent-events"];
    STEventSource * const e = [[STEventSource alloc] initWithURL:url handler:^(id<STEventSourceEvent>  _Nonnull event) {

    } completion:^(NSError * _Nullable error) {

    }];
    XCTAssertNotNil(e);
    XCTAssertNotNil(e.description);
}


@end
