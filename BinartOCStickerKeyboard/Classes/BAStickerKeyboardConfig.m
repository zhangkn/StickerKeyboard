//
//  BAStickerKeyboardConfig.m
//  PPStickerKeyboard
//
//  Created by Seven on 2020/8/22.
//  Copyright © 2020 Vernon. All rights reserved.
//

#import "BAStickerKeyboardConfig.h"
#import "PPUtil.h"

@interface PPStickerMatchingResult : NSObject
@property (nonatomic, assign) NSRange range;                    // 匹配到的表情包文本的range
@property (nonatomic, strong) UIImage *emojiImage;              // 如果能在本地找到emoji的图片，则此值不为空
@property (nonatomic, strong) NSString *showingDescription;     // 表情的实际文本(形如：[哈哈])，不为空
@end

@implementation PPStickerMatchingResult
@end

@interface BAStickerKeyboardConfig ()
@property (nonatomic, strong, readwrite) NSArray<PPSticker *> *allStickers;
@end

@implementation BAStickerKeyboardConfig
@dynamic shared;

+ (BAStickerKeyboardConfig *)shared {
    static dispatch_once_t onceToken;
    static __strong id __singleton__ = nil;
    dispatch_once(&onceToken, ^{
        __singleton__ = [BAStickerKeyboardConfig new];
    });
    return __singleton__;
}

- (void)config {
    NSAssert(self.configFile != nil, @"配置文件为空");
    
    NSArray *fileNameSplits = [self.configFile componentsSeparatedByString:@"."];
    
    NSAssert(fileNameSplits.count==2, @"配置文件出错");
    
    NSString *path = [NSBundle.mainBundle pathForResource:fileNameSplits.firstObject ofType:fileNameSplits.lastObject];
    if (!path) {
        return;
    }

    NSArray *array = [[NSArray alloc] initWithContentsOfFile:path];
    NSMutableArray<PPSticker *> *stickers = [[NSMutableArray alloc] init];
    for (NSDictionary *stickerDict in array) {
        PPSticker *sticker = [PPSticker new];
        if (![stickerDict.allKeys containsObject:@"bundle"]) continue;
        sticker.bundle = stickerDict[@"bundle"];
        if (![stickerDict.allKeys containsObject:@"cover"]) continue;
        sticker.cover = stickerDict[@"cover"];
        
        if (![stickerDict.allKeys containsObject:@"data"]) continue;
        
        NSArray *emojiArr = stickerDict[@"data"];
        NSMutableArray<PPEmoji *> *emojis = [@[] mutableCopy];
        for (NSDictionary *emojiDict in emojiArr) {
            PPEmoji *emoji = [PPEmoji new];
            
            emoji.bundle = sticker.bundle;
            emoji.imageName = emojiDict[@"image"];
            emoji.emojiDescription = emojiDict[@"desc"];
            
            [emojis addObject:emoji];
        }
        
        sticker.data = emojis;
        [stickers addObject:sticker];
    }
    self.allStickers = stickers;
}

#pragma mark - public method

- (void)replaceEmojiForAttributedString:(NSMutableAttributedString *)attributedString font:(UIFont *)font {
    if (!attributedString || !attributedString.length || !font) {
        return;
    }

    NSArray<PPStickerMatchingResult *> *matchingResults = [self matchingEmojiForString:attributedString.string];

    if (matchingResults && matchingResults.count) {
        NSUInteger offset = 0;
        for (PPStickerMatchingResult *result in matchingResults) {
            if (result.emojiImage) {
                CGFloat emojiHeight = font.lineHeight;
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = result.emojiImage;
                attachment.bounds = CGRectMake(0, font.descender, emojiHeight, emojiHeight);
                NSMutableAttributedString *emojiAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
                [emojiAttributedString pp_setTextBackedString:[PPTextBackedString stringWithString:result.showingDescription] range:NSMakeRange(0, emojiAttributedString.length)];
                if (!emojiAttributedString) {
                    continue;
                }
                NSRange actualRange = NSMakeRange(result.range.location - offset, result.showingDescription.length);
                [attributedString replaceCharactersInRange:actualRange withAttributedString:emojiAttributedString];
                offset += result.showingDescription.length - emojiAttributedString.length;
            }
        }
    }
}

#pragma mark - private method

- (NSArray<PPStickerMatchingResult *> *)matchingEmojiForString:(NSString *)string {
    if (!string.length) {
        return nil;
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[.+?\\]" options:0 error:NULL];
    NSArray<NSTextCheckingResult *> *results = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    if (results && results.count) {
        NSMutableArray *emojiMatchingResults = [[NSMutableArray alloc] init];
        for (NSTextCheckingResult *result in results) {
            NSString *showingDescription = [string substringWithRange:result.range];
            NSString *emojiSubString = [showingDescription substringFromIndex:1];       // 去掉[
            emojiSubString = [emojiSubString substringWithRange:NSMakeRange(0, emojiSubString.length - 1)];    // 去掉]
            PPEmoji *emoji = [self emojiWithEmojiDescription:emojiSubString];
            if (emoji) {
                PPStickerMatchingResult *emojiMatchingResult = [[PPStickerMatchingResult alloc] init];
                emojiMatchingResult.range = result.range;
                emojiMatchingResult.showingDescription = showingDescription;
                emojiMatchingResult.emojiImage = emoji.image;
                [emojiMatchingResults addObject:emojiMatchingResult];
            }
        }
        return emojiMatchingResults;
    }
    return nil;
}

- (PPEmoji *)emojiWithEmojiDescription:(NSString *)emojiDescription {
    for (PPSticker *sticker in self.allStickers) {
        for (PPEmoji *emoji in sticker.data) {
            if ([emoji.emojiDescription isEqualToString:emojiDescription]) {
                return emoji;
            }
        }
    }
    return nil;
}

@end
