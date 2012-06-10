//
//  MUKImageFetcherTests.m
//  MUKImageFetcherTests
//
//  Created by Marco Muccinelli on 10/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MUKImageFetcherTests.h"

@implementation MUKImageFetcherTests
@synthesize imageFetcher = imageFetcher_;

- (void)setUp {
    [super setUp];
    self.imageFetcher = [[MUKImageFetcher alloc] init];
}

- (void)tearDown {
    self.imageFetcher.shouldStartConnectionHandler = nil;
    self.imageFetcher = nil;
    
    [super tearDown];
}

- (void)testExample
{
    STFail(@"Unit tests are not implemented yet in MUKImageFetcherTests");
}

@end
