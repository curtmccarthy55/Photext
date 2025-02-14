//
//  CJMAListTableViewCell.m
//  Unroll
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMAListTableViewCell.h"
#import "CJMPhotoAlbum.h"
#import "CJMServices.h"

@interface CJMAListTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *cellAlbumName;
@property (weak, nonatomic) IBOutlet UILabel *cellAlbumCount;

@end

@implementation CJMAListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureWithTitle:(NSString *)albumTitle withAlbumCount:(int)albumCount {
    self.cellAlbumName.text = albumTitle;
    
    NSString *albumCountText;
    if (albumCount == 0) {
        albumCountText = @"No Photos";
    } else if (albumCount == 1) {
        albumCountText = @"1 Photo";
    } else {
        albumCountText = [NSString stringWithFormat:@"%lu Photos", (unsigned long)albumCount];
    }
    self.cellAlbumCount.text = albumCountText;
}

- (void)configureThumbnailForCell:(CJMAListTableViewCell *)cell forAlbum:(CJMPhotoAlbum *)album {
    [[CJMServices sharedInstance] fetchThumbnailForImage:album.albumPreviewImage
                                                 handler:^(UIImage *thumbnail) {
                                                     cell.cellThumbnail.image = thumbnail;
                                                 }];
    if (cell.cellThumbnail.image == nil) {
        if (album.albumPhotos.count >= 1) {
            CJMImage *firstImage = album.albumPhotos[0];
            [[CJMServices sharedInstance] fetchThumbnailForImage:firstImage handler:^(UIImage *thumbnail) {
                cell.cellThumbnail.image = thumbnail;
            }];
        } else {
            cell.cellThumbnail.image = [UIImage imageNamed:@"NoImage"];
        }
    }
    if (@available(iOS 11.0, *)) {
        cell.cellThumbnail.accessibilityIgnoresInvertColors = YES;
    }
}


@end
