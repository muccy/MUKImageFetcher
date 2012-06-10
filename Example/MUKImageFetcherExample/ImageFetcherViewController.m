//
//  ImageFetcherViewController.m
//  MUKImageFetcherExample
//
//  Created by Marco Muccinelli on 10/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageFetcherViewController.h"
#import <MUKImageFetcher/MUKImageFetcher.h>
#import <MUKToolkit/MUKToolkit.h>
#import <MUKNetworking/MUKNetworking.h>

#define USE_FILE_CACHE  0

@interface ImageFetcherPhoto_ : NSObject 
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *title;

+ (id)photoWithTitle:(NSString *)title URL:(NSString *)URLString;
@end

@implementation ImageFetcherPhoto_
@synthesize title = title_;
@synthesize URL = URL_;

+ (id)photoWithTitle:(NSString *)title URL:(NSString *)URLString {
    ImageFetcherPhoto_ *photo = [[[self class] alloc] init];
    photo.title = title;
    photo.URL = [NSURL URLWithString:URLString];
    return photo;
}

@end

#pragma mark - 
#pragma mark - 

@interface ImageFetcherViewController ()
@property (nonatomic, strong) NSArray *photos_;
@property (nonatomic, strong) MUKImageFetcher *imageFetcher_;

- (NSArray *)newPhotosArray_;
- (MUKImageFetcher *)newImageFetcher_;
- (MUKURLConnection *)connectionForThumbnailAtURL_:(NSURL *)thumbnailURL indexPath_:(NSIndexPath *)indexPath fetcher_:(MUKImageFetcher *)fetcher alreadyDownloading:(BOOL *)alreadyDownloading;

- (NSURL *)thumbnailURLForRowAtIndexPath_:(NSIndexPath *)indexPath;

- (void)loadThumbnailAtIndexPath_:(NSIndexPath *)indexPath onlyFromMemory_:(BOOL)onlyFromMemory completionHandler_:(void (^)(UIImage *image, NSSet *indexPaths))completionHandler;
- (void)loadThumbnailsAtIndexPaths_:(NSArray *)indexPaths onlyFromMemory_:(BOOL)onlyFromMemory;

- (void)updateCellAtIndexPath_:(NSIndexPath *)indexPath withLoadedThumbnail_:(UIImage *)image;
- (void)tableViewScrollingFinished_;
@end

@implementation ImageFetcherViewController
@synthesize photos_ = photos__;
@synthesize imageFetcher_ = imageFetcher__;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"MUKImageFetcher";
        
        photos__ = [self newPhotosArray_];
        imageFetcher__ = [self newImageFetcher_];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
    [self loadThumbnailsAtIndexPaths_:visibleIndexPaths onlyFromMemory_:NO];
}

#pragma mark - Private

- (NSArray *)newPhotosArray_ {
    return [[NSArray alloc] initWithObjects:
            [ImageFetcherPhoto_ photoWithTitle:@"B-1 Bomber" URL:@"http://farm5.staticflickr.com/4013/4255994218_258e428f5e_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Molière" URL:@"http://farm6.staticflickr.com/5169/5282437338_b8a6641e47_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Guitar" URL:@"http://farm6.staticflickr.com/5244/5343236121_63a192ee5e_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Bass Player" URL:@"http://farm6.staticflickr.com/5191/7001948910_992ca47e77_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Rabbit" URL:@"http://farm5.staticflickr.com/4124/5205069586_ef963d539b_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Don't Flash" URL:@"http://farm4.staticflickr.com/3219/3029895753_8e960bafdb_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Girl & Dog" URL:@"http://farm8.staticflickr.com/7253/6903019948_e71f3cd950_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Doll" URL:@"http://farm4.staticflickr.com/3204/2807903715_36b7a67e64_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Car" URL:@"http://farm7.staticflickr.com/6110/6312589363_5ed55bb1c5_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Felouque" URL:@"http://farm6.staticflickr.com/5236/7061366429_91a0b25c1e_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Street" URL:@"http://farm3.staticflickr.com/2402/5748798183_3555f922be_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Waterfall" URL:@"http://farm7.staticflickr.com/6024/6015050385_9341ccdf73_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Chrysanthemums" URL:@"http://farm8.staticflickr.com/7125/7123894151_c6e1282522_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Landscape" URL:@"http://farm6.staticflickr.com/5345/7160165138_727ba5195a_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Faro" URL:@"http://farm8.staticflickr.com/7126/7006571278_d8e65cb330_s.jpg"],
            [ImageFetcherPhoto_ photoWithTitle:@"Hop" URL:@"http://farm8.staticflickr.com/7237/6969715530_a39f44a816_s.jpg"],
            nil];
}

- (MUKImageFetcher *)newImageFetcher_ {
    MUKImageFetcher *imageFetcher = [[MUKImageFetcher alloc] init];
    
    __unsafe_unretained ImageFetcherViewController *weakSelf = self;
    imageFetcher.shouldStartConnectionHandler = ^BOOL (MUKURLConnection *connection)
    {
        // I want to start connection if any of index paths are visible
        NSArray *visibleIndexPaths = [weakSelf.tableView indexPathsForVisibleRows];
        
        NSSet *indexPaths = [connection.userInfo copy];
        __block BOOL anyIndexPathIsVisible = NO;
        [indexPaths enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            if ([visibleIndexPaths containsObject:obj]) {
                anyIndexPathIsVisible = YES;
                *stop = YES;
            }
        }];
        
        return anyIndexPathIsVisible;
    };
    
    NSURL *containerURL = [[MUK URLForTemporaryDirectory] URLByAppendingPathComponent:@"ImageFetcherExampleCache"];
    imageFetcher.cache.fileCacheURLHandler = ^(id key) {
        return [MUKObjectCache standardFileCacheURLForStringKey:[key absoluteString] containerURL:containerURL];
    };
    
    return imageFetcher;
}

- (MUKURLConnection *)connectionForThumbnailAtURL_:(NSURL *)thumbnailURL indexPath_:(NSIndexPath *)indexPath fetcher_:(MUKImageFetcher *)fetcher alreadyDownloading:(BOOL *)alreadyDownloading
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:thumbnailURL];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    
    // Check thumbanil is not already downloading
    NSInteger sameConnectionIndex = [[fetcher.connectionQueue connections] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) 
    {
         MUKURLConnection *conn = obj;
         if ([conn.request isEqual:request]) {
             *stop = YES;
             return YES;
         }
         
         return NO;
    }];
    
    MUKURLConnection *resultConnection;
    if (sameConnectionIndex == NSNotFound) {
        // I'm not downloading it
        if (alreadyDownloading != NULL) {
            *alreadyDownloading = NO;
        }
        
        // Create connection and save index path
        resultConnection = [[MUKURLConnection alloc] initWithRequest:request];
        resultConnection.userInfo = [[NSMutableSet alloc] initWithObjects:indexPath, nil];
    }
    else {
        // I'm already downloading it
        if (alreadyDownloading != NULL) {
            *alreadyDownloading = YES;
        }
        
        // Save index path on same connection
        resultConnection = [[fetcher.connectionQueue connections] objectAtIndex:sameConnectionIndex];
        NSMutableSet *indexPaths = resultConnection.userInfo;
        [indexPaths addObject:indexPath];
    }
    
    return resultConnection;
}

- (NSURL *)thumbnailURLForRowAtIndexPath_:(NSIndexPath *)indexPath {
    ImageFetcherPhoto_ *photo = [MUK array:self.photos_ objectAtIndex:indexPath.row];
    return photo.URL;
}

- (void)loadThumbnailAtIndexPath_:(NSIndexPath *)indexPath onlyFromMemory_:(BOOL)onlyFromMemory completionHandler_:(void (^)(UIImage *image, NSSet *indexPaths))completionHandler
{
    // Check if handler exists
    if (!completionHandler) return;
    
    // Take URL
    NSURL *thumbnailURL = [self thumbnailURLForRowAtIndexPath_:indexPath];
    if (!thumbnailURL) {
        completionHandler(nil, [NSSet setWithObject:indexPath]);
        return;
    }

    // Where are you searching thumbnail?
    MUKImageFetcherSearchDomain searchDomain;
    if (onlyFromMemory) {
        searchDomain = MUKImageFetcherSearchDomainMemoryCache;
    }
    else {
#if USE_FILE_CACHE
        searchDomain = MUKImageFetcherSearchDomainEverywhere;
#else
        searchDomain = MUKImageFetcherSearchDomainMemoryCache|MUKImageFetcherSearchDomainRemote;
#endif
    }
    
    // Where are you saving thumbnail?
    MUKObjectCacheLocation cacheLocations;
    if (onlyFromMemory) {
        cacheLocations = MUKObjectCacheLocationNone;
    }
    else {
#if USE_FILE_CACHE
        cacheLocations = MUKObjectCacheLocationLocal;
#else
        cacheLocations = MUKObjectCacheLocationNone;
#endif
    }
    
    // How are you downloading thumbnail?
    MUKURLConnection *connection;
    if (onlyFromMemory) {
        connection = nil;
    }
    else {
        BOOL alreadyDownloading = NO;
        connection = [self connectionForThumbnailAtURL_:thumbnailURL indexPath_:indexPath fetcher_:self.imageFetcher_ alreadyDownloading:&alreadyDownloading];

        if (alreadyDownloading) {
            // Do not launch same connection again
            connection = nil;
        }
    }
    
    // Load image
    [self.imageFetcher_ loadImageForURL:thumbnailURL searchDomains:searchDomain cacheToLocations:cacheLocations connection:connection completionHandler:^(UIImage *image, MUKImageFetcherSearchDomain resultDomains) 
     {
         // Image is here: just notify it
         NSSet *indexPaths = [connection.userInfo copy];
         if (!indexPaths) {
             indexPaths = [[NSSet alloc] initWithObjects:indexPath, nil];
         }
         
         completionHandler(image, indexPaths);
     }];
}

- (void)loadThumbnailsAtIndexPaths_:(NSArray *)indexPaths onlyFromMemory_:(BOOL)onlyFromMemory
{
    [indexPaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
     {
         [self loadThumbnailAtIndexPath_:obj onlyFromMemory_:onlyFromMemory completionHandler_:^(UIImage *loadedThumbnail, NSSet *thumbnailIndexPaths) 
          {
              [thumbnailIndexPaths enumerateObjectsUsingBlock:^(id ip, BOOL *stop) 
               {
                   [self updateCellAtIndexPath_:ip withLoadedThumbnail_:loadedThumbnail];
               }]; // enumerate thumbnailIndexPaths
          }]; // loadThumb
     }]; // enumerate indexPaths
}

- (void)updateCellAtIndexPath_:(NSIndexPath *)indexPath withLoadedThumbnail_:(UIImage *)image
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.imageView.image = image;
    [cell setNeedsLayout];
}

- (void)tableViewScrollingFinished_ {
    NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
    [self loadThumbnailsAtIndexPaths_:visibleIndexPaths onlyFromMemory_:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.photos_ count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    ImageFetcherPhoto_ *photo = [self.photos_ objectAtIndex:indexPath.row];
    cell.textLabel.text = photo.title;
    
    [self loadThumbnailAtIndexPath_:indexPath onlyFromMemory_:YES completionHandler_:^(UIImage *image, NSSet *indexPaths) 
    {
        cell.imageView.image = image;
    }];
    
    return cell;
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self tableViewScrollingFinished_];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self tableViewScrollingFinished_];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self tableViewScrollingFinished_];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self tableViewScrollingFinished_];
}

@end
