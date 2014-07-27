//
//  CTextStorage.h
//  FastTextView
//
//  Created by wangweibin on 14-6-16.
//  Copyright (c) 2014年 wangweibin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>


enum {
    CTextAttachmentCharacter = 0xfffc // The magical Unicode character for attachments in both Cocoa (NSAttachmentCharacter) and CoreText ('run delegate' there).
};


@class  CTextStorage;

@protocol CTextStorageDelegate <NSObject>

@optional
-(void)textStorageWillProcessEditing:(CTextStorage *)storage;
-(void)textStorageDidProcessEditing:(CTextStorage *)storage;
@end



/**
 *  存储行的信息
 */
@interface CTextLine : NSObject {
@private
    CFRange _range;
    CGFloat _lineWidth;
    CGFloat _ascent;
    CGFloat _descent;
    CGFloat _leading;
    
}

@property(nonatomic,assign) CFRange range;
@property(nonatomic,assign) CGFloat lineWidth;
@property(nonatomic,assign) CGFloat ascent;
@property(nonatomic,assign) CGFloat descent;
@property(nonatomic,assign) CGFloat leading;

@end



/**
 *  存储段落信息
 */
@interface CTextParagraph : NSObject {
@private
    NSRange _range;
    CGRect _rect;
    NSMutableArray *_lines;
    CGPoint *_origins ;
    NSMutableArray *_textAttchmentList;
    NSMutableArray *_linerefs;
    CGLayerRef _layer;
    CGFloat _pragraghSpaceHeight;
}

@property(nonatomic,assign) NSRange range;
@property(nonatomic,assign) CGRect rect;
@property(nonatomic,strong) NSMutableArray *lines;
@property(nonatomic,assign) CGPoint *origins ;
@property(nonatomic,strong) NSMutableArray *textAttchmentList;
@property(nonatomic,strong) NSMutableArray *linerefs;
@property(nonatomic,assign) CGLayerRef layer;

@property(nonatomic,assign) CGFloat pragraghSpaceHeight;


- (CGFloat) lineGetOriginY:(CGFloat)originy ;

- (CFRange) lineGetStringRange:(CTextLine *)line;

-(CFIndex)lineGetStringIndexForPosition:(CTLineRef)line fastTextLine:(CTextLine *)fastline piont:(CGPoint)convertedPoint;

-(CGFloat)lineGetGetOffsetForStringIndex:(CTLineRef)line fastTextLine:(CTextLine *)fastline  charIndex:(CFIndex)charIndex secondaryOffset:(CGFloat*)secondaryOffset;

-(CGFloat)build:(NSAttributedString *)paraAttrstring paragraphSizeWidth:(CGFloat)paragraphSizeWidth paragraphOriginY:(CGFloat)paragraphOriginY paraRange:(NSRange)addParaRange isBuildLayer:(BOOL)isBuildLayer context:(CGContextRef)context;

@end



/**
 *  存储整个文本的信息
 */
@interface CTextStorage : NSMutableAttributedString{
    NSMutableAttributedString *_attrstring;
    NSMutableArray *_paragraphs;
    CGSize _paragraphSize;
    __weak id <CTextStorageDelegate> _delegate;
    BOOL _isEditing;
    BOOL _isScanAttribute;
    NSString *_buildParagraghTime;
    NSMutableArray *_textAttchmentList;
    NSMutableArray *_deleteParagraphs;;
    CGFloat _pragraghSpaceHeight;
    
}
@property(nonatomic,weak) id <CTextStorageDelegate> delegate;
@property(nonatomic,assign) CGSize paragraphSize;
@property(nonatomic,strong) NSMutableArray *paragraphs;
@property(nonatomic,strong)  NSString *buildParagraghTime;
@property(nonatomic,assign) CGFloat pragraghSpaceHeight;

- (id)init;

- (id)initWithString:(NSString *)str;

- (id)initWithAttributedString:(NSAttributedString *)attrStr;

- (NSString *)string;

- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range;

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str;

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range;

/**
 *  设置样式
 *
 */
- (void)formatString;

- (void)scanAttributes:(NSRange)range;

- (void)refreshParagraghInRange:(NSRange)range;

- (void)buildParagraph:(CGFloat)width;

- (void)rebuildLayer:(CTextParagraph *)paragraph context:(CGContextRef)context;

- (CTLineRef)buildCTLineRef:(CTextLine *)fastTextLine withParagraph:(CTextParagraph *)paragraph;

//release unvisible region object
- (void)didReceiveMemoryWarning:(CGRect)visibleRect;

- (void)printLayer;

- (void)beginStorageEditing;

- (void)endStorageEditing;

- (NSArray *)textAttchmentList;

- (BOOL)isEditing;

-(void)clearDeleteParagraphs;

-(void)clearCacheLinerefs;


@end
