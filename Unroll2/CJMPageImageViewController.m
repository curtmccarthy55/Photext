//
//  CJMPageImageViewController.m
//  Unroll
//
//  Created by Curt on 5/1/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMPageImageViewController.h"

@interface CJMPageImageViewController ()

@property (nonatomic) BOOL makeViewsVisible;
@property (nonatomic) BOOL makeHomeVisible;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonFavorite;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonOptions;
@property (nonatomic) CGFloat noteOpacity;
@property (nonatomic) NSInteger currentIndex;

@end

@implementation CJMPageImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentIndex = self.initialIndex;
    self.dataSource = self;
    self.makeViewsVisible = YES; //cjm note shift
    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
    self.view.backgroundColor = [UIColor whiteColor];
    NSNumber *numOpacity = [[NSUserDefaults standardUserDefaults] valueForKey:@"noteOpacity"];
    self.noteOpacity = numOpacity ? numOpacity.floatValue : 0.75;
    
    CJMFullImageViewController *fullImageVC = [self fullImageViewControllerForIndex:self.initialIndex];
    [self setViewControllers:@[fullImageVC]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:NULL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setPrefersLargeTitles:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
//    NSLog(@"PageVC deallocated!");
}

-(BOOL)prefersStatusBarHidden {
    if (!self.makeViewsVisible || self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        NSLog(@"PageImageVC prefersStatusBarHidden returned YES");
        return YES;
    } else {
        NSLog(@"PageImageVC prefersStatusBarHidden returned NO");
        return NO;
    }
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    if (!self.makeViewsVisible && !self.makeHomeVisible) { //if bars aren't visible or 
        NSLog(@"PageImageVC prefersHomeIndicatorAutoHidden returned YES");
        return YES;
    } else {
        NSLog(@"PageImageVC prefersHomeIndicatorAutoHidden returned NO");
        return NO;
    }
}

#pragma mark UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(CJMFullImageViewController *)currentImageVC {
    NSInteger previousIndex = currentImageVC.index - 1;
    return [self fullImageViewControllerForIndex:previousIndex];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(CJMFullImageViewController *)currentImageVC {
    NSInteger nextIndex = currentImageVC.index + 1;
    return [self fullImageViewControllerForIndex:nextIndex];
}

- (CJMFullImageViewController *)fullImageViewControllerForIndex:(NSInteger)index {
    if (index >= self.albumCount || index < 0) {
        return nil;
    } else {
        self.currentIndex = index;
        CJMFullImageViewController *fullImageController = [self.storyboard instantiateViewControllerWithIdentifier:@"FullImageVC"];
        fullImageController.index = index;
        fullImageController.albumName = self.albumName;
        fullImageController.delegate = self;
        fullImageController.noteOpacity = self.noteOpacity;
        fullImageController.barsVisible = self.makeViewsVisible;
            
        return fullImageController;
    }
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        //currentIndex should match the new vc's index.
    } else {
        //currentIndex should match the original vc's index.
    }
}

#pragma mark - navBar and toolbar buttons

- (IBAction)favoriteImage:(UIBarButtonItem *)sender { //cjm favorites PageVC -> ImageVC
    CJMFullImageViewController *currentVC = (CJMFullImageViewController *)self.viewControllers[0];
    
    if ([sender.image isEqual:[UIImage imageNamed:@"WhiteStarEmpty"]]) {
        [sender setImage:[UIImage imageNamed:@"WhiteStarFull"]];
        [currentVC actionFavorite:YES];
    } else {
        [sender setImage:[UIImage imageNamed:@"WhiteStarEmpty"]];
        [currentVC actionFavorite:NO];
    }
}


- (IBAction)currentPhotoOptions:(id)sender {
    CJMFullImageViewController *currentVC = (CJMFullImageViewController *)self.viewControllers[0];
    
    [currentVC showPopUpMenu];
}

- (IBAction)deleteCurrentPhoto:(id)sender {
    CJMFullImageViewController *currentVC = (CJMFullImageViewController *)self.viewControllers[0];
    
    [currentVC confirmImageDelete];
}

#pragma mark - CJMFullImageVC Delegate Methods

- (void)updateBarsHidden:(BOOL)setting {
    self.makeViewsVisible = setting;
    [self setNeedsStatusBarAppearanceUpdate];
    if (self.makeViewsVisible) {
        [NSNotificationCenter.defaultCenter postNotificationName:@"ImageShowBars" object:nil];
    } else {
        [NSNotificationCenter.defaultCenter postNotificationName:@"ImageHideBars" object:nil];
    }
}

- (void)makeHomeIndicatorVisible:(BOOL)visible {
    self.makeHomeVisible = visible;
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
}

//deletes the currently displayed image and updates screen based on position in album
- (void)viewController:(CJMFullImageViewController *)currentVC deletedImageAtIndex:(NSInteger)imageIndex {
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

- (void)photoIsFavorited:(BOOL)isFavorited { //cjm favorites ImageVC -> PageVC
    if (!isFavorited) {
        [self.barButtonFavorite setImage:[UIImage imageNamed:@"WhiteStarEmpty"]];
    } else {
        [self.barButtonFavorite setImage:[UIImage imageNamed:@"WhiteStarFull"]];
    }
}

@end
