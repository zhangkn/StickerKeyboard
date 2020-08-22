//
//  BAStickerKeyboardConfig.h
//  PPStickerKeyboard
//
//  Created by Seven on 2020/8/22.
//  Copyright © 2020 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "PPSticker.h"

NS_ASSUME_NONNULL_BEGIN

@interface BAStickerKeyboardConfig : NSObject

@property (class, nonatomic, readonly) BAStickerKeyboardConfig *shared;

/**
 
 
 
 */
@property (nonatomic, copy) NSString *configFile; // Sticker.plist

- (void)config;

/// 所有的表情包
@property (nonatomic, strong, readonly) NSArray<PPSticker *> *allStickers;

/* 匹配给定attributedString中的所有emoji，如果匹配到的emoji有本地图片的话会直接换成本地的图片
 *
 * @param attributedString 可能包含表情包的attributedString
 * @param font 表情图片的对齐字体大小
 */
- (void)replaceEmojiForAttributedString:(NSMutableAttributedString *)attributedString font:(UIFont *)font;


@end

NS_ASSUME_NONNULL_END
