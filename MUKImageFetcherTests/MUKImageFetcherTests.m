//
//  MUKImageFetcherTests.m
//  MUKImageFetcherTests
//
//  Created by Marco Muccinelli on 10/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MUKImageFetcherTests.h"
#import <MUKNetworking/MUKNetworking.h>
#import <MUKObjectCache/MUKObjectCache.h>
#import <MUKToolkit/MUKToolkit.h>

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

- (void)testQueueImmutableHandlers {
    id willStartHandler = self.imageFetcher.connectionQueue.connectionWillStartHandler;
    id didFinishHandler = self.imageFetcher.connectionQueue.connectionDidFinishHandler;
    
    STAssertNotNil(willStartHandler, nil);
    STAssertNotNil(didFinishHandler, nil);
    
    self.imageFetcher.connectionQueue.connectionWillStartHandler = nil;
    self.imageFetcher.connectionQueue.connectionDidFinishHandler = nil;
    
    STAssertNotNil(self.imageFetcher.connectionQueue.connectionWillStartHandler, @"Handler unaffected");
    STAssertNotNil(self.imageFetcher.connectionQueue.connectionDidFinishHandler, @"Handler unaffected");
}

- (void)testNoURL {
    __block UIImage *returnedImage = nil;
    __block MUKImageFetcherSearchDomain returnedResultDomains = MUKImageFetcherSearchDomainNone;
    __block BOOL handlerCalled = NO;
    
    [self.imageFetcher loadImageForURL:nil searchDomains:MUKImageFetcherSearchDomainMemoryCache cacheToLocations:MUKObjectCacheLocationFile connection:nil completionHandler:^(UIImage *image, MUKImageFetcherSearchDomain resultDomains) 
    {
        handlerCalled = YES;
        returnedImage = image;
        returnedResultDomains = resultDomains;
    }];
    
    STAssertTrue(handlerCalled, nil);
    STAssertNil(returnedImage, @"No image without an URL");
    STAssertEquals(MUKImageFetcherSearchDomainNone, returnedResultDomains, nil);
}

- (void)testInMemoryImage {
    // Load image
    NSBundle *imageBundle = [NSBundle bundleForClass:[self class]];
    NSURL *imageURL = [MUK URLForImageFileWithName:@"Steve-Jobs" extension:@"jpg" bundle:imageBundle highResolution:NO];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[imageURL path]];
    STAssertNotNil(image, nil);

    // Try to fetch image (not added)
    __block BOOL handlerCalled = NO;
    __block UIImage *returnedImage = nil;
    __block MUKImageFetcherSearchDomain returnedResultDomains = MUKImageFetcherSearchDomainNone;
    [self.imageFetcher loadImageForURL:imageURL searchDomains:MUKImageFetcherSearchDomainMemoryCache cacheToLocations:MUKObjectCacheLocationNone connection:nil completionHandler:^(UIImage *image, MUKImageFetcherSearchDomain resultDomains) 
    {
        handlerCalled = YES;
        returnedImage = image;
        returnedResultDomains = resultDomains;
    }];
    
    STAssertTrue(handlerCalled, nil);
    STAssertNil(returnedImage, @"No image in cache");
    STAssertEquals(MUKImageFetcherSearchDomainMemoryCache, returnedResultDomains, nil);
    
    // Now insert image in cache
    [self.imageFetcher.cache saveObject:image forKey:imageURL locations:MUKObjectCacheLocationMemory completionHandler:nil];
    
    // Re-fetch
    handlerCalled = NO;
    returnedImage = nil;
    returnedResultDomains = MUKImageFetcherSearchDomainNone;
    [self.imageFetcher loadImageForURL:imageURL searchDomains:MUKImageFetcherSearchDomainMemoryCache cacheToLocations:MUKObjectCacheLocationNone connection:nil completionHandler:^(UIImage *image, MUKImageFetcherSearchDomain resultDomains) 
     {
         handlerCalled = YES;
         returnedImage = image;
         returnedResultDomains = resultDomains;
     }];
    
    STAssertTrue(handlerCalled, nil);
    STAssertNotNil(returnedImage, @"Image in cache");
    STAssertEquals(MUKImageFetcherSearchDomainMemoryCache, returnedResultDomains, @"Image found in memory");
}

@end
