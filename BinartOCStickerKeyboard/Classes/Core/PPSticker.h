//
//  PPSticker.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPEmoji.h"

@interface PPSticker : NSObject

@property (nonatomic, copy) NSString *bundle;
@property (nonatomic, copy) NSString *cover;
@property (nonatomic, strong) NSArray<PPEmoji *> *data;

// MARK: = 便携方法
@property (nonatomic, readonly) NSString *defaultBundleName;

@end
