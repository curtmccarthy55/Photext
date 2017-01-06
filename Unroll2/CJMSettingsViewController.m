//
//  CJMSettingsViewController.m
//  Photo Notes
//
//  Created by Curtis McCarthy on 1/4/17.
//  Copyright © 2017 Bluewraith. All rights reserved.
//

#import "CJMSettingsViewController.h"
#import "CJMFileSerializer.h"
#import "CJMAlbumManager.h"
#import "CJMPhotoAlbum.h"
#import "CJMImage.h"


@interface CJMSettingsViewController () 

@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnDone;
@property (weak, nonatomic) IBOutlet UISlider *sldOpacity;
@property (weak, nonatomic) IBOutlet UIView *noteView;
@property (weak, nonatomic) IBOutlet UITextField *lblOpacity;
@property (nonatomic) CGFloat finalVal;

@property (nonatomic, strong) PHFetchResult *fetchResult;
@property (strong) PHCachingImageManager *imageManager;

@property (weak, nonatomic) IBOutlet UIButton *whiteButton;
@end

@implementation CJMSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.btnDone setEnabled:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSNumber *currentOpacity = [[NSUserDefaults standardUserDefaults] valueForKey:@"noteOpacity"];
    CGFloat opacity = currentOpacity.floatValue ? currentOpacity.floatValue : 0.75;
    [self.noteView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:opacity]];
    [self.lblOpacity setText:[NSString stringWithFormat:@"%.f%%", roundf(opacity * 100)]];
    [self.sldOpacity setValue:(opacity * 100.0) animated:NO];
    
    UITableViewCell *cell = self.tableView.visibleCells[0];
    NSLog(@"*cjm* cell.accessoryView.width == %f", cell.accessoryView.frame.size.width);
    
    [[self.whiteButton layer] setBorderWidth:1.0f];
    [[self.whiteButton layer] setBorderColor:[UIColor blackColor].CGColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons

- (IBAction)doneAction:(id)sender {
    NSNumber *opacity = [[NSUserDefaults standardUserDefaults] valueForKey:@"noteOpacity"];
    if (opacity.floatValue != self.sldOpacity.value) {
        NSNumber *newOpac = [NSNumber numberWithFloat:(self.sldOpacity.value / 100)];
        [[NSUserDefaults standardUserDefaults] setValue:newOpac forKey:@"noteOpacity"];
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelAction:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnTwitter:(id)sender {
    NSLog(@"*cjm* direct user to twitter.com/beDevCurt");
}

#pragma mark - Opacity Slider

//- (void)viewDidLoad {
//    [super viewDidLoad];
//    float zoomVal = appSharedData.planZoom * 10.0;
//    float roundedVal = roundf(zoomVal);
//    float finalVal = roundedVal * 10.0;
//
//    [self.lblZoomScale setText:[NSString stringWithFormat:@"%.f%%", roundf(finalVal)]];
//    [self.zoomSlider setValue:appSharedData.planZoom animated:NO];
//}
//
//- (IBAction)btnApplyAction:(id)sender {
//    appSharedData.planZoom = self.finalVal;
//    NSNumber *userZoom = [NSNumber numberWithFloat:appSharedData.planZoom];
//    [userDefaults setValue:userZoom forKey:@"iOS Zoom"];
//    [self.delegate reloadViewToShowPlanChanges];
//    [self dismissViewControllerAnimated:YES completion:nil];
//}
//
- (IBAction)slider:(UISlider*)sender {
    float oVal = sender.value;
    [self.lblOpacity setText:[NSString stringWithFormat:@"%.f%%", roundf(oVal)]];
    [self.noteView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:(oVal / 100)]];
    [self.lblOpacity setAlpha:1.0];
    
    if (self.btnDone.enabled == NO) {
        [self.btnDone setEnabled:YES];
    }
    
    
    
//    float zoomVal = self.sldOpacity.value * 10.0; //75%
//    float roundedVal = roundf(zoomVal);
//    self.finalVal = roundedVal / 10.0;
//    float textVal = roundedVal * 10.0;
//    [self.sldOpacity setValue:self.finalVal animated:NO];
//    [self.noteView setAlpha:zoomVal];
//    [self.lblOpacity setText:[NSString stringWithFormat:@"%.f%%", roundf(textVal)]];
}


#pragma mark - CJMPhotoGrabber Methods and Delegate

- (void)presentPhotoGrabViewController {
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    UINavigationController *navigationVC = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"NavPhotoGrabViewController"];
    CJMPhotoGrabViewController *vc = (CJMPhotoGrabViewController *)[navigationVC topViewController];
    vc.delegate = self;
    
    [self presentViewController:navigationVC animated:YES completion:nil];
    
//    CJMPhotoGrabViewController *vc = (CJMPhotoGrabViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotoGrabViewController"];
//    vc.delegate = self;
//    
//    [self.navigationController pushViewController:vc animated:YES];
}

- (void)photoGrabViewControllerDidCancel:(CJMPhotoGrabViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//iterate through array of selected photos, convert them to CJMImages, and add to the current album.
- (void)photoGrabViewController:(CJMPhotoGrabViewController *)controller didFinishSelectingPhotos:(NSArray *)photos {
    NSMutableArray *newImages = [[NSMutableArray alloc] init];
    //Pull the images, image creation dates, and image locations from each PHAsset in the received array.
    CJMFileSerializer *fileSerializer = [[CJMFileSerializer alloc] init];
    
    if (!self.imageManager) {
        self.imageManager = [[PHCachingImageManager alloc] init];
    }
    
    __block NSInteger counter = [photos count];
    //    __weak CJMGalleryViewController *weakSelf = self;
    
    dispatch_group_t imageLoadGroup = dispatch_group_create();
    for (int i = 0; i < photos.count; i++)
    {
        __block CJMImage *assetImage = [[CJMImage alloc] init];
        PHAsset *asset = (PHAsset *)photos[i];
        
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.networkAccessAllowed = YES;
        options.version = PHImageRequestOptionsVersionCurrent;
        
        dispatch_group_enter(imageLoadGroup);
        @autoreleasepool {
            [self.imageManager requestImageDataForAsset:asset
                                                options:options
                                          resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                              
                                              counter--;
                                              if(![info[PHImageResultIsDegradedKey] boolValue])
                                              {
                                                  [fileSerializer writeObject:imageData toRelativePath:assetImage.fileName];
                                                  dispatch_group_leave(imageLoadGroup);
                                              }
                                              
                                          }];
        }
        
        [assetImage setInitialValuesForCJMImage:assetImage inAlbum:@"CJMQuickNote"];
        //        assetImage.photoLocation = [asset location];
        assetImage.photoCreationDate = [asset creationDate];
        
        [newImages addObject:assetImage];
    }
    
    CJMPhotoAlbum *album = [[CJMAlbumManager sharedInstance] userQuickNote];
    [album addMultipleCJMImages:newImages];
    
    dispatch_group_notify(imageLoadGroup, dispatch_get_main_queue(), ^{
        self.navigationController.view.userInteractionEnabled = YES;
//        [self.collectionView reloadData];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[CJMAlbumManager sharedInstance] save];
        self.navigationController.view.userInteractionEnabled = YES;
    });
}

- (void)photosFromLibrary {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
        if (status != PHAuthorizationStatusAuthorized) {
            UIAlertController *adjustPrivacyController = [UIAlertController alertControllerWithTitle:@"Denied access to Photos" message:@"You will need to give Photo Notes permission to import from your Photo Library.\n\nPlease allow Photo Notes access to your Photo Library by going to Settings>Privacy>Photos." preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
            
            [adjustPrivacyController addAction:dismiss];
            
            [self presentViewController:adjustPrivacyController animated:YES completion:nil];
        } else {
            [self presentPhotoGrabViewController];
        }
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        [self photosFromLibrary];
    } else if (indexPath.section == 2) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Table view data source

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
