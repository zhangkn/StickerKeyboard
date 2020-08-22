//
//  PPEmoji.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPEmoji.h"

@implementation PPEmoji

- (UIImage *)image {
    NSString *bundleFileName = [NSString stringWithFormat:@"%@.bundle", self.bundle];
    return [UIImage imageNamed:[bundleFileName stringByAppendingPathComponent:self.imageName]];
}

@end
