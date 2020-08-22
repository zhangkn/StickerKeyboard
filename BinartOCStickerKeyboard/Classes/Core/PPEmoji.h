//
//  PPEmoji.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface PPEmoji : NSObject

@property (nonatomic, copy) NSString *bundle;
@property (nonatomic, copy) NSString *imageName;
@property (nonatomic, copy) NSString *emojiDescription;

// MARK: = 便携方法

@property (nonatomic, readonly) UIImage *image;

@end
