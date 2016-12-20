//
//  CJMFIGalleryViewController.m
//  Unroll
//
//  Created by Curt on 5/1/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMFIGalleryViewController.h"

@interface CJMFIGalleryViewController ()

@property (nonatomic) BOOL makeViewsVisible;

@end

@implementation CJMFIGalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.dataSource = self;
    self.makeViewsVisible = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CJMFullImageViewController *fullImageVC = [self fullImageViewControllerForIndex:self.initialIndex];
    
    [self setViewControllers:@[fullImageVC]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
//    NSLog(@"PageVC deallocated!");
}

-(BOOL)prefersStatusBarHidden
{
    if (self.navigationController.navigationBar.hidden == NO) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(CJMFullImageViewController *)currentImageVC
{
    NSInteger previousIndex = currentImageVC.index - 1;
//    NSLog(@"Creating previous VC.");
    return [self fullImageViewControllerForIndex:previousIndex];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(CJMFullImageViewController *)currentImageVC
{
    NSInteger nextIndex = currentImageVC.index + 1;
//    NSLog(@"Creating next VC.");
    return [self fullImageViewControllerForIndex:nextIndex];
}

- (CJMFullImageViewController *)fullImageViewControllerForIndex:(NSInteger)index
{
    if (index >= self.albumCount || index < 0) {
        return nil;
    } else {
    CJMFullImageViewController *fullImageController = [self.storyboard instantiateViewControllerWithIdentifier:@"FullImageVC"];
    fullImageController.index = index;
    fullImageController.albumName = self.albumName;
    fullImageController.delegate = self;
    [fullImageController setViewsVisible:self.makeViewsVisible];
        
    return fullImageController;
    }
}

#pragma mark - navBar and toolbar visibility

- (void)setMakeViewsVisible:(BOOL)makeViewsVisible
{
    _makeViewsVisible = makeViewsVisible;

    [self toggleViewVisibility];
}

#pragma mark - navBar and toolbar buttons

- (IBAction)favoriteImage:(UIBarButtonItem *)sender {
    if ([sender.image isEqual:[UIImage imageNamed:@"WhiteStarEmpty"]]) {
        [sender setImage:[UIImage imageNamed:@"WhiteStarFull"]];
    } else {
        [sender setImage:[UIImage imageNamed:@"WhiteStarEmpty"]];
    }
}


- (IBAction)currentPhotoOptions:(id)sender
{
    CJMFullImageViewController *currentVC = (CJMFullImageViewController *)self.viewControllers[0];
    
    [currentVC showPopUpMenu];
}

- (IBAction)deleteCurrentPhoto:(id)sender
{
    CJMFullImageViewController *currentVC = (CJMFullImageViewController *)self.viewControllers[0];
    
    [currentVC confirmImageDelete];
}

- (void)toggleViewVisibility
{
    if (self.makeViewsVisible == NO) {
        [UIApplication sharedApplication].statusBarHidden = YES;
        [UIView animateWithDuration:0.2 animations:^{
            self.navigationController.navigationBar.alpha = 0;
            self.navigationController.toolbar.alpha = 0;
        }];
    } else if (self.makeViewsVisible == YES) {
        [UIApplication sharedApplication].statusBarHidden = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.navigationController.navigationBar.alpha = 1;
            self.navigationController.toolbar.alpha = 1;
        }];
    }
}

#pragma mark - CJMFullImageVC Delegate Methods

- (void)toggleFullImageShowForViewController:(CJMFullImageViewController *)viewController
{
    self.makeViewsVisible = !self.makeViewsVisible;
    [viewController setViewsVisible:self.makeViewsVisible];
}

//deletes the currently displayed image and updates screen based on position in album
- (void)viewController:(CJMFullImageViewController *)currentVC deletedImageAtIndex:(NSInteger)imageIndex
{
    if (self.albumCount - 1 == 0) {
        
        [self.navigationController popViewControllerAnimated:YES];
        
    } else if ((imageIndex + 1) >= self.albumCount) {
        
        CJMFullImageViewController *previousVC = (CJMFullImageViewController *)[self pageViewController:self viewControllerBeforeViewController:currentVC];
        self.albumCount -= 1;
        
        [self setViewControllers:@[previousVC]
                                          direction:UIPageViewControllerNavigationDirectionReverse
                                           animated:YES
                                         completion:nil];
    } else {
        
        CJMFullImageViewController *nextVC = (CJMFullImageViewController *)[self pageViewController:self viewControllerAfterViewController:currentVC];
        nextVC.index = imageIndex;
        self.albumCount -= 1;
    
        [self setViewControllers:@[nextVC]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:YES
                      completion:NULL];
    }
}

@end
