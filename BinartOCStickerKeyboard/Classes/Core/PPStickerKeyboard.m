//
//  PPSktickerKeyboard.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPStickerKeyboard.h"
#import "PPEmojiPreviewView.h"
#import "PPStickerPageView.h"
#import "BAStickerKeyboardConfig.h"
#import "PPUtil.h"

static CGFloat const PPStickerTopInset = 12.0;


static CGFloat const PPStickerScrollViewHeight = 160.0;

static CGFloat const PPKeyboardPageControlTopMargin = 10.0;
static CGFloat const PPKeyboardPageControlHeight = 7.0;
static CGFloat const PPKeyboardPageControlBottomMargin = 6.0;
static CGFloat const PPKeyboardCoverButtonWidth = 50.0;

static CGFloat const BAStickerCateMenuTopInset = 8.f;
static CGFloat const BAStickerCateMenuHeight = 60.f;

static CGFloat const BAStickerCateMenuItemWidth = 48.f;
static CGFloat const BAStickerCateMenuItemHorizontalMargin = 8.f;
 
static CGFloat const PPKeyboardCoverButtonHeight = 44.0;

static CGFloat const PPPreviewViewWidth = 92.0;
static CGFloat const PPPreviewViewHeight = 137.0;

static NSString *const PPStickerPageViewReuseID = @"PPStickerPageView";

@interface PPStickerKeyboard () <PPStickerPageViewDelegate, PPQueuingScrollViewDelegate, UIInputViewAudioFeedback>

@property (nonatomic, strong) NSArray<PPSticker *> *stickers;

/// 表情类别菜单
@property (nonatomic, strong) UIScrollView *stickerCateMenu;
@property (nonatomic, strong) UIView *bottomBGView;
@property (nonatomic, strong) NSArray<PPSlideLineButton *> *stickerCoverButtons;
@property (nonatomic, strong) PPSlideLineButton *sendButton;

@property (nonatomic, strong) PPQueuingScrollView *queuingScrollView;
@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, strong) PPEmojiPreviewView *emojiPreviewView;
@end

@implementation PPStickerKeyboard {
    NSUInteger _currentStickerIndex;
}

- (instancetype)init {
    self = [self initWithFrame:CGRectZero];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _currentStickerIndex = 0;
        _stickers = BAStickerKeyboardConfig.shared.allStickers.copy;

        self.backgroundColor = [UIColor pp_colorWithRGBString:@"#373839"];
        [self addSubview:self.queuingScrollView];
        [self addSubview:self.pageControl];
        [self addSubview:self.bottomBGView];
//        [self addSubview:self.sendButton];
        [self addSubview:self.stickerCateMenu];

        [self changeStickerToIndex:0];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // 表情类别菜单
    self.stickerCateMenu.contentSize = CGSizeMake(self.stickerCoverButtons.count * (BAStickerCateMenuItemWidth+BAStickerCateMenuItemHorizontalMargin)+BAStickerCateMenuItemHorizontalMargin, PPKeyboardCoverButtonHeight);
    self.stickerCateMenu.frame =
    CGRectMake(
               0,
//               CGRectGetHeight(self.bounds) - PPKeyboardCoverButtonHeight - PP_SAFEAREAINSETS(self).bottom,
               BAStickerCateMenuTopInset,
               CGRectGetWidth(self.bounds),
               PPKeyboardCoverButtonHeight
               );
    [self reloadStickerMenuData];
    
    self.sendButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - PPKeyboardCoverButtonWidth, CGRectGetMinY(self.stickerCateMenu.frame), BAStickerCateMenuItemWidth, BAStickerCateMenuHeight/2);
    self.bottomBGView.frame =
    CGRectMake(
               0,
//               CGRectGetMinY(self.stickerCateMenu.frame),
               0,
               CGRectGetWidth(self.frame),
               BAStickerCateMenuHeight// + PP_SAFEAREAINSETS(self).bottom
               );
    
    // 表情选择
    self.queuingScrollView.contentSize =
        CGSizeMake(
                   [self numberOfPageForSticker:[self stickerAtIndex:_currentStickerIndex]] * CGRectGetWidth(self.bounds),
                   PPStickerScrollViewHeight);
    self.queuingScrollView.frame =
        CGRectMake(0,
    //               PPStickerTopInset,
                   BAStickerCateMenuTopInset + BAStickerCateMenuHeight,
                   CGRectGetWidth(self.bounds),
                   PPStickerScrollViewHeight);
    self.pageControl.frame = CGRectMake(0, CGRectGetMaxY(self.queuingScrollView.frame) + PPKeyboardPageControlTopMargin, CGRectGetWidth(self.bounds), PPKeyboardPageControlHeight);
}

- (CGFloat)heightThatFits {
    CGFloat bottomInset = 0;
    if (@available(iOS 11.0, *)) {
        bottomInset = UIApplication.sharedApplication.delegate.window.safeAreaInsets.bottom;
    }
    return
        PPStickerTopInset +
        PPStickerScrollViewHeight +
        PPKeyboardPageControlTopMargin +
        PPKeyboardPageControlHeight +
        BAStickerCateMenuTopInset +
        BAStickerCateMenuHeight +
        bottomInset;
}

// MARK: - getter / setter

- (PPQueuingScrollView *)queuingScrollView {
    if (!_queuingScrollView) {
        _queuingScrollView = [[PPQueuingScrollView alloc] init];
        _queuingScrollView.delegate = self;
        _queuingScrollView.pagePadding = 0;
        _queuingScrollView.alwaysBounceHorizontal = NO;
        _queuingScrollView.backgroundColor = [UIColor pp_colorWithRGBString:@"#373839"];
    }
    return _queuingScrollView;
}

- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.hidesForSinglePage = YES;
        _pageControl.currentPageIndicatorTintColor = [UIColor pp_colorWithRGBString:@"#F5A623"];
        _pageControl.pageIndicatorTintColor = [UIColor pp_colorWithRGBString:@"#BCBCBC"];
    }
    return _pageControl;
}

- (PPSlideLineButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [[PPSlideLineButton alloc] init];
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        [_sendButton setTitleColor:[UIColor pp_colorWithRGBString:@"#040302"] forState:UIControlStateNormal];
        [_sendButton setBackgroundColor:[UIColor pp_colorWithRGBString:@"FFE164"]];
//        _sendButton.linePosition = PPSlideLineButtonPositionLeft;
//        _sendButton.lineColor = [UIColor pp_colorWithRGBString:@"#D1D1D1"];
        [_sendButton addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
        _sendButton.layer.cornerRadius = 4.f;
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:13];
    }
    return _sendButton;
}

- (UIScrollView *)stickerCateMenu {
    if (!_stickerCateMenu) {
        _stickerCateMenu = [[UIScrollView alloc] init];
        _stickerCateMenu.showsHorizontalScrollIndicator = NO;
        _stickerCateMenu.showsVerticalScrollIndicator = NO;
        _stickerCateMenu.backgroundColor = [UIColor clearColor];
    }
    return _stickerCateMenu;
}

- (UIView *)bottomBGView {
    if (!_bottomBGView) {
        _bottomBGView = [[UIView alloc] init];
        _bottomBGView.backgroundColor = [UIColor pp_colorWithRGBString:@"#484848"];
    }
    return _bottomBGView;
}

- (PPEmojiPreviewView *)emojiPreviewView {
    if (!_emojiPreviewView) {
        _emojiPreviewView = [[PPEmojiPreviewView alloc] init];
        _emojiPreviewView.backgroundColor = [UIColor pp_colorWithRGBString:@"484848"];
    }
    return _emojiPreviewView;
}

// MARK: - private method

- (PPSticker *)stickerAtIndex:(NSUInteger)index {
    if (self.stickers && index < self.stickers.count) {
        return self.stickers[index];
    }
    return nil;
}

- (NSUInteger)numberOfPageForSticker:(PPSticker *)sticker {
    if (!sticker) {
        return 0;
    }

    NSUInteger numberOfPage = (sticker.data.count / PPStickerPageViewMaxEmojiCount) + ((sticker.data.count % PPStickerPageViewMaxEmojiCount == 0) ? 0 : 1);
    return numberOfPage;
}

- (void)reloadStickerMenuData {
    for (UIButton *button in self.stickerCoverButtons) {
        [button removeFromSuperview];
    }
    self.stickerCoverButtons = nil;

    if (!self.stickers || !self.stickers.count) {
        return;
    }

    NSMutableArray *stickerCoverButtons = [[NSMutableArray alloc] init];
    for (NSUInteger index = 0, max = self.stickers.count; index < max; index++) {
        PPSticker *sticker = self.stickers[index];
        if (!sticker) {
            return;
        }

        PPSlideLineButton *button = [[PPSlideLineButton alloc] init];
        button.tag = index;
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        button.layer.cornerRadius = 2.f;
//        button.linePosition = PPSlideLineButtonPositionRight;
//        button.lineColor = [UIColor pp_colorWithRGBString:@"#D1D1D1"];
        button.backgroundColor = (_currentStickerIndex == index ? [UIColor pp_colorWithRGBString:@"#434343"] : [UIColor clearColor]);
        [button setImage:[self emojiImageWithName:sticker.cover] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(changeSticker:) forControlEvents:UIControlEventTouchUpInside];
        [self.stickerCateMenu addSubview:button];
        [stickerCoverButtons addObject:button];
        button.frame = CGRectMake(index * (BAStickerCateMenuItemWidth +BAStickerCateMenuItemHorizontalMargin), 0, PPKeyboardCoverButtonWidth, PPKeyboardCoverButtonHeight);
    }
    self.stickerCoverButtons = stickerCoverButtons;
}

- (UIImage *)emojiImageWithName:(NSString *)name {
    if (!name.length) {
        return nil;
    }

    return [UIImage imageNamed:[@"Sticker.bundle" stringByAppendingPathComponent:name]];
}

- (void)changeStickerToIndex:(NSUInteger)toIndex {
    if (toIndex >= self.stickers.count) {
        return;
    }

    PPSticker *sticker = [self stickerAtIndex:toIndex];
    if (!sticker) {
        return;
    }

    _currentStickerIndex = toIndex;

    PPStickerPageView *pageView = [self queuingScrollView:self.queuingScrollView pageViewForStickerAtIndex:0];
    [self.queuingScrollView displayView:pageView];

    [self reloadStickerMenuData];
}

#pragma mark - target / action

- (void)changeSticker:(UIButton *)button
{
    [self changeStickerToIndex:button.tag];
}

- (void)sendAction:(PPSlideLineButton *)button
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerKeyboardDidClickSendButton:)]) {
        [self.delegate stickerKeyboardDidClickSendButton:self];
    }
}

#pragma mark - PPQueuingScrollViewDelegate

- (void)queuingScrollViewChangedFocusView:(PPQueuingScrollView *)queuingScrollView previousFocusView:(UIView *)previousFocusView
{
    PPStickerPageView *currentView = (PPStickerPageView *)self.queuingScrollView.focusView;
    self.pageControl.currentPage = currentView.pageIndex;
}

- (UIView<PPReusablePage> *)queuingScrollView:(PPQueuingScrollView *)queuingScrollView viewBeforeView:(UIView *)view
{
    return [self queuingScrollView:queuingScrollView pageViewForStickerAtIndex:((PPStickerPageView *)view).pageIndex - 1];
}

- (UIView<PPReusablePage> *)queuingScrollView:(PPQueuingScrollView *)queuingScrollView viewAfterView:(UIView *)view
{
    return [self queuingScrollView:queuingScrollView pageViewForStickerAtIndex:((PPStickerPageView *)view).pageIndex + 1];
}

- (PPStickerPageView *)queuingScrollView:(PPQueuingScrollView *)queuingScrollView pageViewForStickerAtIndex:(NSUInteger)index
{
    PPSticker *sticker = [self stickerAtIndex:_currentStickerIndex];
    if (!sticker) {
        return nil;
    }

    NSUInteger numberOfPages = [self numberOfPageForSticker:sticker];
    self.pageControl.numberOfPages = numberOfPages;
    if (index >= numberOfPages) {
        return nil;
    }

    PPStickerPageView *pageView = [queuingScrollView reusableViewWithIdentifer:PPStickerPageViewReuseID];
    if (!pageView) {
        pageView = [[PPStickerPageView alloc] initWithReuseIdentifier:PPStickerPageViewReuseID];
        pageView.delegate = self;
    }
    pageView.pageIndex = index;
    [pageView configureWithSticker:sticker];
    return pageView;
}

#pragma mark - PPStickerPageViewDelegate

- (void)stickerPageView:(PPStickerPageView *)stickerPageView didClickEmoji:(PPEmoji *)emoji
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerKeyboard:didClickEmoji:)]) {
        [[UIDevice currentDevice] playInputClick];
        [self.delegate stickerKeyboard:self didClickEmoji:emoji];
    }
}

- (void)stickerPageViewDidClickDeleteButton:(PPStickerPageView *)stickerPageView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerKeyboardDidClickDeleteButton:)]) {
        [[UIDevice currentDevice] playInputClick];
        [self.delegate stickerKeyboardDidClickDeleteButton:self];
    }
}

- (void)stickerPageView:(PPStickerPageView *)stickerKeyboard showEmojiPreviewViewWithEmoji:(PPEmoji *)emoji buttonFrame:(CGRect)buttonFrame
{
    if (!emoji) {
        return;
    }

    self.emojiPreviewView.emoji = emoji;

    CGRect buttonFrameAtKeybord = CGRectMake(buttonFrame.origin.x, PPStickerTopInset + buttonFrame.origin.y, buttonFrame.size.width, buttonFrame.size.height);
    self.emojiPreviewView.frame = CGRectMake(CGRectGetMidX(buttonFrameAtKeybord) - PPPreviewViewWidth / 2, UIScreen.mainScreen.bounds.size.height - CGRectGetHeight(self.bounds) + CGRectGetMaxY(buttonFrameAtKeybord) - PPPreviewViewHeight, PPPreviewViewWidth, PPPreviewViewHeight);

    UIWindow *window = [UIApplication sharedApplication].windows.lastObject;
    if (window) {
        [window addSubview:self.emojiPreviewView];
    }
}

- (void)stickerPageViewHideEmojiPreviewView:(PPStickerPageView *)stickerKeyboard
{
    [self.emojiPreviewView removeFromSuperview];
}

#pragma mark - UIInputViewAudioFeedback

- (BOOL)enableInputClicksWhenVisible
{
    return YES;
}

@end
