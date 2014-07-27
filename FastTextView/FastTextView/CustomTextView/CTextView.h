//
//  CTextView.h
//  FastTextView
//
//  Created by wangweibin on 14-6-16.
//  Copyright (c) 2014年 wangweibin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <UIKit/UITextChecker.h>
#include <objc/runtime.h>
#import "CFileWrapperObject.h"
//#import "CTextAttchment.h"
#import "NSAttributedString+CTextUtil.h"
#import "NSMutableAttributedString+CTextUtil.h"
#import "CTextStorage.h"
#import "ContentViewTiledLayer.h"
#import "CAttributeConfig.h"
#import "CTextConfig.h"
NSString * const CTextAttachmentAttributeName;
NSString * const CTextParagraphAttributeName;


#define C_TILED_LAYER_MODE 1
#define C_RENDER_WITH_LINEREF 1


typedef enum {
    
    CustomDisplayFull = 0, //full refresh 全部刷新
    CustomDisplayRect = 1, //rect refresh 局部RECT刷新，一般是当前可视的局部刷新
    
} CustomDisplayFlags;

/**
 *  MARK:CTextAttachmentCell
 */
@protocol CTextAttachmentCell <NSObject>

@optional
- (UIView *)attachmentView;
- (CGSize) attachmentSize;
- (CGPoint)cellBaselineOffset;
- (void) attachmentDrawInRect: (CGRect)r;
@property (nonatomic,readwrite) NSRange range ;
@property (nonatomic,strong)  CFileWrapperObject *fileWrapperObject;

@end


/**
 * MARK: 显示内容的view
 */
@interface CContentView : UIView {
    
@private
    id __weak _delegate;
#if C_TILED_LAYER_MODE
    ContentViewTiledLayer *_tiledLayer;
#endif
    
}

@property(nonatomic,weak) id delegate;
@property (nonatomic, readonly) ContentViewTiledLayer *tiledLayer;
-(void) refreshView;
-(void) refreshAllView;

@end


/**
 * MARK: 背景view
 */

@interface CBackGroudView : UIView


@end

/**
 * MARK: 显示光标的view
 */

@interface CCaretView : UIView {
    
    NSTimer *_blinkTimer;
}
- (void)delayBlink;
- (void)show;

@end

//MARK: CIndexedPosition definition
@interface CIndexedPosition : UITextPosition {
    NSUInteger               _index;
    id <UITextInputDelegate> _inputDelegate;
}
@property (nonatomic) NSUInteger index;
+ (CIndexedPosition *)positionWithIndex:(NSUInteger)index;

@end

//MARK: UITextRange definition
@interface CIndexedRange : UITextRange {
    NSRange _range;
}
@property (nonatomic) NSRange range;
+ (CIndexedRange *)rangeWithNSRange:(NSRange)range;

@end


/**
 * MARK: 自定义textview控件
 */
@interface CTextView : UIScrollView<UITextInput,CTextStorageDelegate>
{
    CustomDisplayFlags displayFlags; //refresh mode  刷新模式
    CContentView      *_textContentView;
    CBackGroudView    *_backGroudView;
    NSMutableArray    *_visibleTextAttchList;
    
    UILabel           *_placeHolderView;//默认显示内容
    CTextStorage      *_attributedString;
    CCaretView        *_caretView;//光标
    
    BOOL                _editable;
    BOOL                _editing;
    
    int caretLineIndex; //caret Line Index  光标所在的行号
    CGFloat caretLineWidth; //caret Line width   光标所在的行的宽度
    int caretLineIndex_selected; //when selectedRang.length>0 caret Line Index,selectedRang.length>0 时 前导光标所在的行号
    
    __unsafe_unretained id <UITextInputDelegate>   _inputDelegate;
    UITextInputStringTokenizer         *_tokenizer;
    UITextChecker                      *_textChecker;
    
    NSString *_placeHolder;
}

@property(nonatomic,strong) CTextStorage *attributedString;
@property(nonatomic,strong) NSString *placeHolder;
@property(nonatomic) NSRange selectedRange;
@property(nonatomic) NSRange markedRange;
@property(nonatomic,assign) BOOL isImageSigleLine;
@property(nonatomic,getter=isEditable) BOOL editable; //default YES
@property(nonatomic,strong) UIFont *font; // ignored when attributedString is not nil
@property(nonatomic,strong) CAttributeConfig *attributeConfig;


- (void)setDisplayFlags:(CustomDisplayFlags)flags;
- (CGRect)getVisibleRect;
- (void)drawContentInRect:(CGRect)rect ctx:(CGContextRef)ctx;

@end
