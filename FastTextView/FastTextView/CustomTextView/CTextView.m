//
//  CTextView.m
//  FastTextView
//
//  Created by wangweibin on 14-6-16.
//  Copyright (c) 2014年 wangweibin. All rights reserved.
//

#import "CTextView.h"
#import "CTextAttchment.h"
NSString * const CTextAttachmentAttributeName = @"CTextAttachmentAttribute";
NSString * const CTextParagraphAttributeName = @"CTextParagraphAttribute";

@interface CTextView (Private)

//- (CGRect)caretRectForIndex:(int)index;
//- (CGRect)caretRectForIndex:(int)index point:(CGPoint)point ;
//- (CGRect)firstRectForNSRange:(NSRange)range;
//- (NSInteger)closestIndexToPoint:(CGPoint)point;
//- (NSRange)characterRangeAtPoint_:(CGPoint)point;
//- (void)checkSpellingForRange:(NSRange)range;
//- (void)textChanged;
//- (void)removeCorrectionAttributesForRange:(NSRange)range;
//- (void)insertCorrectionAttributesForRange:(NSRange)range;
//- (void)showCorrectionMenuForRange:(NSRange)range;
//- (void)checkLinksForRange:(NSRange)range;
//- (void)showMenu;
//- (CGRect)menuPresentationRect;
//- (void)insertAttributedString:(NSAttributedString *)newString ;
//- (NSAttributedString *)stripStyle:(NSAttributedString *) attrstring;
+ (UIColor *)selectionColor;
+ (UIColor *)spellingSelectionColor;
+ (UIColor *)caretColor;

@end

@interface CTextView ()

@property(nonatomic,strong) NSDictionary *correctionAttributes;
@property(nonatomic,strong) NSMutableDictionary *menuItemActions;
@property(nonatomic) NSRange correctionRange;

@end




/**
 * MARK: 内容视图
 */
@implementation CContentView

@synthesize delegate=_delegate;
#if TILED_LAYER_MODE
@synthesize tiledLayer=_tiledLayer;
#endif

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        self.userInteractionEnabled = NO;
 
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

#if C_TILED_LAYER_MODE
+ (Class)layerClass {
    return [ContentViewTiledLayer class];
}

- (ContentViewTiledLayer *)tiledLayer {
    return (ContentViewTiledLayer *)self.layer;
}
#endif



-(void)refreshView{
    
    [_delegate setDisplayFlags:CustomDisplayRect];
    //wq ADD for 坐标变换
    [self setNeedsDisplayInRect:[_delegate getVisibleRect]];
    
    //[self setNeedsDisplayInRect:self.bounds];
    //wq ADD for 坐标变换 -END
    [self setNeedsLayout];
    
}

-(void)refreshAllView{
    
    [_delegate setDisplayFlags:CustomDisplayRect];
    //wq ADD for 坐标变换
    //[self setNeedsDisplayInRect:[_delegate getVisibleRect]];
    
    [self setNeedsDisplayInRect:self.bounds];
    //wq ADD for 坐标变换 -END
    [self setNeedsLayout];
    
}



- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    // Flip the coordinate system
    //wq ADD for 坐标变换
    
    CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
    CGContextTranslateCTM(ctx, 0, self.bounds.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    //wq ADD for 坐标变换 -END
    CGContextSetFillColorWithColor(ctx, [CTextView caretColor].CGColor);
    CGRect rect = CGContextGetClipBoundingBox(ctx);
    if (_delegate!=nil ) {
        [_delegate drawContentInRect:rect ctx:ctx];
    }
    
}


-(void)dealloc{
    //NSLog(@"FastContentView dealloc");
}

@end



/**
 * MARK: 背景view
 */
@implementation CBackGroudView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        self.userInteractionEnabled = NO;

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}



-(void)dealloc{
    //NSLog(@"FastContentView dealloc");
}
@end


/**
 * MARK: 显示光标的view
 */
@implementation CCaretView

static const NSTimeInterval kInitialBlinkDelay = 0.6f;
static const NSTimeInterval kBlinkRate = 1.0;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [CTextView caretColor];
    }
    return self;
}

- (void)show {
    
    [self.layer removeAllAnimations];
    
}

- (void)didMoveToSuperview {
    
    if (self.superview) {
        
        [self delayBlink];
        
    } else {
        
        [self.layer removeAllAnimations];
        
    }
}

- (void)delayBlink {
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1.0f], [NSNumber numberWithFloat:1.0f], [NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:0.0f], nil];
    animation.calculationMode = kCAAnimationCubic;
    animation.duration = kBlinkRate;
    animation.beginTime = CACurrentMediaTime() + kInitialBlinkDelay;
    animation.repeatCount = CGFLOAT_MAX;
    [self.layer addAnimation:animation forKey:@"BlinkAnimation"];
    
}
- (void)dealloc {
    
}

@end


/////////////////////////////////////////////////////////////////////////////
// MARK: FastIndexedPosition
/////////////////////////////////////////////////////////////////////////////

@implementation CIndexedPosition
@synthesize index=_index;

+ (CIndexedPosition *)positionWithIndex:(NSUInteger)index {
    CIndexedPosition *pos = [[CIndexedPosition alloc] init];
    pos.index = index;
    return pos;
}

@end


/////////////////////////////////////////////////////////////////////////////
// MARK: FastIndexedRange
/////////////////////////////////////////////////////////////////////////////

@implementation CIndexedRange
@synthesize range=_range;

+ (CIndexedRange *)rangeWithNSRange:(NSRange)theRange {
    if (theRange.location == NSNotFound)
        return nil;
    
    CIndexedRange *range = [[CIndexedRange alloc] init];
    range.range = theRange;
    return range;
}

- (UITextPosition *)start {
    return [CIndexedPosition positionWithIndex:self.range.location];
}

- (UITextPosition *)end {
	return [CIndexedPosition positionWithIndex:(self.range.location + self.range.length)];
}

-(BOOL)isEmpty {
    return (self.range.length == 0);
}

@end


@implementation CTextView

@synthesize inputDelegate=_inputDelegate;
@synthesize placeHolder=_placeHolder;
@synthesize attributedString=_attributedString;
@synthesize isImageSigleLine;
@synthesize editable=_editable;
@synthesize font;
@synthesize markedRange;


- (void)setDisplayFlags:(CustomDisplayFlags)flags
{
    displayFlags=flags;
}

-(CGRect)getVisibleRect
{
    return CGRectMake(0,self.contentOffset.y, _textContentView.frame.size.width, self.frame.size.height);
}
- (void)setEditable:(BOOL)editable {

    if (editable) {

        if (_caretView==nil) {
            _caretView = [[CCaretView alloc] initWithFrame:CGRectZero];
        }

        _tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
        _textChecker = [[UITextChecker alloc] init];

        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:(int)(kCTUnderlineStyleThick|kCTUnderlinePatternDot)], kCTUnderlineStyleAttributeName, (id)[UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f].CGColor, kCTUnderlineColorAttributeName, nil];
        self.correctionAttributes = dictionary;

    } else {

        if (_caretView) {
            [_caretView removeFromSuperview];
            _caretView=nil;
        }

        self.correctionAttributes=nil;
        if (_textChecker!=nil) {
            _textChecker=nil;
        }
        if (_tokenizer!=nil) {
            _tokenizer=nil;
        }

    }
    _editable = editable;

}

- (void)commonInit {
    self.alwaysBounceVertical = YES;
    self.editable = YES;
//    _dirty=NO;
//    isSecondTap=NO;
//    isInsertText=NO;
//    isFirstResponser=NO;
    self.backgroundColor = [UIColor clearColor];
    //[UIColor colorWithPatternImage:[UIImage imageNamed:@"paperbg.png"]];
    
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.clipsToBounds = YES;
    
    
    CBackGroudView *backgroudView = [[CBackGroudView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    backgroudView.autoresizingMask =  self.autoresizingMask;
    backgroudView.backgroundColor= [UIColor colorWithPatternImage:[UIImage imageNamed:@"note_paper_middle.png"]];
    [self addSubview:backgroudView];
    _backGroudView = backgroudView;
    
    //FastContentView *contentView = [[FastContentView alloc] initWithFrame:CGRectInset(self.bounds, 8.0f, 8.0f)];
    
    CContentView *contentView = [[CContentView alloc] initWithFrame:CGRectMake(30, 38, self.bounds.size.width-16-30, self.bounds.size.height-38)];
    contentView.autoresizingMask =  self.autoresizingMask;
    contentView.delegate = self;
    contentView.backgroundColor=[UIColor clearColor];
//    contentView.backgroundColor= [UIColor colorWithPatternImage:[UIImage imageNamed:@"note_paper_middle.png"]];
//    contentView.backgroundColor = [UIColor clearColor];
    
    [self addSubview:contentView];
    _textContentView = contentView;
    

    
    [self showPlaceHolderView];
    
//    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
//    gesture.delegate = (id<UIGestureRecognizerDelegate>)self;
//    [self addGestureRecognizer:gesture];
//    _longPress = gesture;
//    
//    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
//    [doubleTap setNumberOfTapsRequired:2];
//    [self addGestureRecognizer:doubleTap];
//    
    UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:singleTap];
    
    /*
     UISwipeGestureRecognizer *recognizer;
     recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeUp:)];
     [recognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
     [self addGestureRecognizer:recognizer];
     
     UISwipeGestureRecognizer *recognizer1;
     recognizer1 = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeDown:)];
     [recognizer1 setDirection:(UISwipeGestureRecognizerDirectionDown)];
     [self addGestureRecognizer:recognizer1];
     */
    
    _visibleTextAttchList=[[NSMutableArray alloc] init];
    self.attributeConfig=[CTextConfig editorAttributeConfig];
    self.font =  self.attributeConfig.font;
    [self addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
//    oldOffset=self.contentOffset.y;
//    
//    displayFlags=FastDisplayFull;
    
//    [self setText:@""];
    
#if C_TILED_LAYER_MODE
    //    CGSize size0=CGSizeMake(_textContentView.frame.size.width*2, self.frame.size.height*8);
    //    tiledLayer.tileSize =size0 ;
    
    ContentViewTiledLayer *tiledLayer = (ContentViewTiledLayer *)[_textContentView layer];
    
    tiledLayer.levelsOfDetail = 1;
    tiledLayer.levelsOfDetailBias = 0;
    // get larger dimension and multiply by scale
    UIScreen *mainScreen = [UIScreen mainScreen];
    CGFloat largerDimension = MAX(mainScreen.applicationFrame.size.width, mainScreen.applicationFrame.size.height);
    CGFloat scale = mainScreen.scale;
    // this way tiles cover entire screen regardless of orientation or scale
    CGSize tileSize = CGSizeMake(largerDimension * scale, largerDimension * scale);
    tiledLayer.tileSize = tileSize;
#endif
    
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self commonInit];
    }
    return self;
}


- (void)setText:(NSString *)text {
    
//    [self.inputDelegate textWillChange:self];
    _attributedString =[[CTextStorage alloc]initWithString:text];
    _attributedString.paragraphSize=CGSizeMake(_textContentView.frame.size.width, 0);
//    _attributedString.delegate=self;
    
    [_attributedString beginStorageEditing];
    [_attributedString buildParagraph:_attributedString.paragraphSize.width];
    [_attributedString scanAttributes:NSMakeRange(0, _attributedString.length)];
    [_attributedString endStorageEditing];
    
//    [self.inputDelegate textDidChange:self];
    
    [_textContentView refreshView];
    
    //    if (self.attributedString.length>0 && _placeHolderView!=nil ) {
    //        [_placeHolderView removeFromSuperview];
    //        _placeHolderView=nil;
    //    }
    
//    if ( ((self.attributedString.length==2 &&![_attributedString.string isEqualToString:EMPTY_STRING])
//          ||self.attributedString.length!=2)
//        && _placeHolderView!=nil ) {
//        [_placeHolderView removeFromSuperview];
//        _placeHolderView=nil;
//    }
//    
//    if(self.attributedString.length==2 && [_attributedString.string isEqualToString:EMPTY_STRING]){
//        [_caretView removeFromSuperview];
//    }
    
}


- (void)setAttributedString:(NSMutableAttributedString *)string {

    _attributedString =[[CTextStorage alloc]initWithAttributedString:string];
    _attributedString.pragraghSpaceHeight= 10;
    _attributedString.paragraphSize=CGSizeMake(_textContentView.frame.size.width, 0);
    _attributedString.delegate=self;
    [_attributedString formatString];
//    if (string.length==0) {
//        [self insertText:EMPTY_STRING];
//    }
    
    [_attributedString beginStorageEditing];
    [_attributedString buildParagraph:_attributedString.paragraphSize.width];
    
    [_attributedString scanAttributes:NSMakeRange(0, _attributedString.length)];
    
    [_attributedString endStorageEditing];
    
    [_textContentView refreshView];
    
    //if (self.attributedString.length>0 && _placeHolderView!=nil ) {
    if ( ((self.attributedString.length==2 )
          ||self.attributedString.length!=2)
        && _placeHolderView!=nil ) {
        [_placeHolderView removeFromSuperview];
        _placeHolderView=nil;
    }
//
//    if(self.attributedString.length==2 && [_attributedString.string isEqualToString:EMPTY_STRING]){
//        [_caretView removeFromSuperview];
//    }
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
#if !TILED_LAYER_MODE
    if([keyPath isEqualToString:@"contentOffset"]){
         [_textContentView refreshView];
//        if (self.contentOffset.y!=oldOffset && !isInsertText) {
//            [_textContentView refreshView];
//            oldOffset=self.contentOffset.y;
//            NSLog(@"oldOffset: %d",oldOffset);
//        }
    }
#endif
    
}
-(void)recaculate{
    
    CGRect rect = _textContentView.frame;
    CGFloat height = 0;
    if (_attributedString!=nil) {
        height= _attributedString.paragraphSize.height;
    }
    rect.size.height = height;//+self.font.lineHeight
    
    _textContentView.frame =CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, MAX(rect.size.height, 0));
    
    CGRect backRect = _backGroudView.frame;
    backRect.size.height =  MAX(rect.size.height+38, self.bounds.size.height);
    _backGroudView.frame =  backRect;

    self.contentSize = CGSizeMake(self.frame.size.width, rect.size.height+38);
}
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self recaculate];//gfthr add for recaculate the size // 重算高度

    [_textContentView refreshView];
}


- (void)layoutSubviews {
    [super layoutSubviews];
}


//wq ADD for 坐标变换 增加 ctx:(CGContextRef)ctx 参数
- (void)drawBoundingRangeAsSelection:(NSRange)selectionRange cornerRadius:(CGFloat)cornerRadius  ctx:(CGContextRef)ctx {
	
    if (selectionRange.length == 0 || selectionRange.location == NSNotFound) {
        return;
    }
    
    NSMutableArray *pathRects = [[NSMutableArray alloc] init];
    for (int j=0; j<[_attributedString.paragraphs count]; j++) {
        
        CTextParagraph *textParagraph=[_attributedString.paragraphs objectAtIndex:j];
        NSArray *lines = textParagraph.lines;
        CGPoint *origins =textParagraph.origins ;
        NSInteger count = [lines count];
        
        for (int i = 0; i < count; i++) {
            CTextLine *fastline=[lines objectAtIndex:i];
            CFRange lineRange =[textParagraph lineGetStringRange:fastline];// CTLineGetStringRange(line);
            NSRange range = NSMakeRange(lineRange.location==kCFNotFound ? NSNotFound : lineRange.location, lineRange.length);
            NSRange intersection = [self rangeIntersection:range withSecond:selectionRange];
            
            if (intersection.location != NSNotFound && intersection.length > 0) {
                CTLineRef line =[self.attributedString buildCTLineRef:fastline withParagraph:textParagraph] ;
                NSInteger lineindex=intersection.location-textParagraph.range.location;
                NSInteger linefinalIndex=intersection.location + intersection.length-textParagraph.range.location;
                
                CGFloat xStart = [textParagraph lineGetGetOffsetForStringIndex:line fastTextLine:fastline charIndex:lineindex secondaryOffset:NULL];
                CGFloat xEnd =  [textParagraph lineGetGetOffsetForStringIndex:line fastTextLine:fastline charIndex:linefinalIndex secondaryOffset:NULL];
                
                CGPoint origin = origins[i];
                CGFloat ascent=fastline.ascent;
                CGFloat descent=fastline.descent;
                CGFloat origin_y=[textParagraph lineGetOriginY:origin.y];
                
                CGRect selectionRect = CGRectMake(origin.x + xStart, origin_y - descent, xEnd - xStart, ascent + descent);
                
                if (range.length==1) {
                    selectionRect.size.width = _textContentView.bounds.size.width;
                }
                
                [pathRects addObject:NSStringFromCGRect(selectionRect)];
                CFRelease(line);
                
            }
        }
    }
    //wq ADD for 坐标变换
    [self drawPathFromRects:pathRects cornerRadius:cornerRadius ctx:ctx];
}

//wq ADD for 坐标变换 增加 ctx:(CGContextRef)ctx 参数
- (void)drawPathFromRects:(NSArray*)array cornerRadius:(CGFloat)cornerRadius ctx:(CGContextRef)ctx{
    
    if (array==nil || [array count] == 0) return;
    
  
    CGMutablePathRef _path = CGPathCreateMutable();
    
    int index = 0;
    for (NSString *str in array) {
        NSLog(@"index :%d rect:%@",index++,str);
         CGRect rect = CGRectFromString(str);
        if (cornerRadius>0) {
            CGPathAddPath(_path, NULL, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius].CGPath);
        } else {
            CGPathAddRect(_path, NULL, rect);
        }
    }
    
//    CGRect firstRect = CGRectFromString([array lastObject]);
//    CGRect lastRect = CGRectFromString([array objectAtIndex:0]);
////    if ([array count]>1) {
////        lastRect.size.width = _textContentView.bounds.size.width-lastRect.origin.x;
////    }
//    
//    if (cornerRadius>0) {
//        CGPathAddPath(_path, NULL, [UIBezierPath bezierPathWithRoundedRect:firstRect cornerRadius:cornerRadius].CGPath);
//        CGPathAddPath(_path, NULL, [UIBezierPath bezierPathWithRoundedRect:lastRect cornerRadius:cornerRadius].CGPath);
//    } else {
//        CGPathAddRect(_path, NULL, firstRect);
//        CGPathAddRect(_path, NULL, lastRect);
//    }
//    
//    if ([array count] > 1) {
//        
////        CGRect fillRect = CGRectZero;
////        
////        CGFloat originX = ([array count]==2) ? MIN(CGRectGetMinX(firstRect), CGRectGetMinX(lastRect)) : 0.0f;
////        CGFloat originY = firstRect.origin.y + firstRect.size.height;
////        CGFloat width = ([array count]==2) ? originX+MIN(CGRectGetMaxX(firstRect), CGRectGetMaxX(lastRect)) : _textContentView.bounds.size.width;
////        CGFloat height =  MAX(0.0f, lastRect.origin.y-originY);
////        
////        fillRect = CGRectMake(originX, originY, width, height);
////        
////        if (cornerRadius>0) {
////            CGPathAddPath(_path, NULL, [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:cornerRadius].CGPath);
////        } else {
////            CGPathAddRect(_path, NULL, fillRect);
////        }
//        
//    }
    
    //CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddPath(ctx, _path);
    CGContextFillPath(ctx);
    CGPathRelease(_path);
    
}
#if C_RENDER_WITH_LINEREF
//wq ADD for 坐标变换 增加 ctx:(CGContextRef)ctx 参数
- (void)drawContentInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    
//    double starttime=[[NSDate date]timeIntervalSince1970];
    
    [self.attributedString clearDeleteParagraphs]; //clear attributedString deleted paragraphs // 清理已删除的章节
    
    if ([self.attributedString isEditing]) {
        return;
    }
    
    @synchronized(self.attributedString) {
        
        //    double starttime=[[NSDate date]timeIntervalSince1970];
        
        //[[FastTextView selectionColor] setFill];
        CGContextSetFillColorWithColor(ctx, [CTextView selectionColor].CGColor);
        
        [self drawBoundingRangeAsSelection:self.selectedRange cornerRadius:0.0f ctx:ctx];
        [self drawBoundingRangeAsSelection:self.markedRange cornerRadius:0.0f ctx:ctx];//gfthr add for markedRange IME（输入法）
        
        //CGContextRef ctx = UIGraphicsGetCurrentContext();
        
#if C_TILED_LAYER_MODE
        CGFloat ystart=rect.origin.y;
        CGFloat yend=rect.origin.y+rect.size.height;
        CGContextClipToRect(ctx, rect);
#else
        CGRect dirtyRect = [self getVisibleRect];
        CGContextClipToRect(ctx, dirtyRect);//CGContextGetClipBoundingBox(ctx);
        CGFloat ystart=dirtyRect.origin.y;
        CGFloat yend=dirtyRect.origin.y+dirtyRect.size.height;
#endif
        _visibleTextAttchList=[[NSMutableArray alloc]init];
        
        for (int j=0; j<[_attributedString.paragraphs count]; j++) {
            
            CTextParagraph *textParagraph=[_attributedString.paragraphs objectAtIndex:j];
            if (textParagraph==nil) {
                break;
            }
            @synchronized(textParagraph) {
                
                if (((textParagraph.rect.origin.y )>yend )) {
                    continue;
                }else if (((textParagraph.rect.origin.y +textParagraph.rect.size.height)<ystart )){
                    break;
                }
                
                NSArray *lines = textParagraph.linerefs;
                if (lines==nil) {
                    [_attributedString rebuildLayer:textParagraph context:ctx];
                    lines = textParagraph.linerefs;
                    
                }
                NSInteger count = [lines count];
                
                CGPoint *origins =textParagraph.origins ;
                
                for (int i = 0 ; i < count; i++) {
                    
                    CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex((CFArrayRef)lines, i);
                    
                    CGFloat ascent,descent,leading;
                    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
                    
                    if (((textParagraph.rect.origin.y + origins[i].y)>yend )) {
                        continue;
                    }else if (((textParagraph.rect.origin.y + origins[i].y+ascent)<ystart )){
                        break;
                    }
                    
                    CGContextSetTextPosition(ctx, textParagraph.rect.origin.x + origins[i].x, textParagraph.rect.origin.y + origins[i].y);
                    

                    CTLineDraw(line, ctx);
// 绘制图
                    CFArrayRef runs = CTLineGetGlyphRuns(line);
                    CFIndex runsCount = CFArrayGetCount(runs);
                    
                    CFRange linerange=CTLineGetStringRange(line);
                    for (CFIndex runsIndex = 0; runsIndex < runsCount; runsIndex++) {
                        CTRunRef run = CFArrayGetValueAtIndex(runs, runsIndex);
                        CFDictionaryRef attributes = CTRunGetAttributes(run);
                        id <CTextAttachmentCell> attachmentCell = [( __bridge NSDictionary*)(attributes) objectForKey: CTextAttachmentAttributeName];
                        if (attachmentCell != nil && [attachmentCell respondsToSelector: @selector(attachmentSize)] && [attachmentCell respondsToSelector: @selector(attachmentDrawInRect:)]) {
                            
                            CFRange runrange= CTRunGetStringRange(run);
                            NSRange nsrunrange=NSMakeRange(textParagraph.range.location+linerange.location+runrange.location, runrange.length);
                            [attachmentCell setRange:nsrunrange];
                            //NSLog(@"attachmentCell setRange: %@",NSStringFromRange(nsrunrange));
                            
                            CGPoint position;
                            CTRunGetPositions(run, CFRangeMake(0, 1), &position);
                            
                            CGSize size = [attachmentCell attachmentSize];
                            CGPoint baselineOffset = [attachmentCell cellBaselineOffset];
                            
                            if (!self.isImageSigleLine) {
                                baselineOffset=CGPointMake(0, baselineOffset.y);
                            }
                            
                            CGRect cellrect = { { textParagraph.rect.origin.x+origins[i].x + position.x+baselineOffset.x, textParagraph.rect.origin.y+origins[i].y + position.y+baselineOffset.y }, size };
                            UIGraphicsPushContext(ctx);//UIGraphicsGetCurrentContext() //WQ ADD for 坐标变换
                            [attachmentCell attachmentDrawInRect: cellrect];
                            UIGraphicsPopContext();
                            
                            CTextAttchment *txtAttachment=[[CTextAttchment alloc]init];
                            
                            txtAttachment.cellRect=cellrect;
                            txtAttachment.attachmentcell=attachmentCell;
                            [_visibleTextAttchList addObject:txtAttachment];
                        }
                    }
                }
            }//end @synchronized(textParagraph)
        }
    }
    
//    isInsertText=NO;
  
}

#else

- (void)drawContentInRect:(CGRect)rect {
    
//    double starttime=[[NSDate date]timeIntervalSince1970];
    
    
//    [[CTextView selectionColor] setFill];
//    [self drawBoundingRangeAsSelection:self.selectedRange cornerRadius:0.0f];
//    [self drawBoundingRangeAsSelection:self.markedRange cornerRadius:0.0f];//gfthr add for markedRange IME //（输入法）
    
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGRect dirtyRect = [self getVisibleRect];
    
    
    CGContextClipToRect(ctx, dirtyRect);
    
    CGFloat ystart=dirtyRect.origin.y;
    CGFloat yend=dirtyRect.origin.y+dirtyRect.size.height;
    
    _visibleTextAttchList=[[NSMutableArray alloc]init];
	
	for (int j=0; j<[_attributedString.paragraphs count]; j++) {
        
        CTextParagraph *textParagraph=[_attributedString.paragraphs objectAtIndex:j];
        
        if (((textParagraph.rect.origin.y )>yend )) {
            continue;
        }else if (((textParagraph.rect.origin.y + textParagraph.rect.size.height)<ystart )){
            break;
        }
        
        if (textParagraph.layer==NULL) {
            [_attributedString rebuildLayer:textParagraph context:ctx];
        }
        
        CGContextDrawLayerInRect(ctx, textParagraph.rect, textParagraph.layer);
        [_visibleTextAttchList addObjectsFromArray:textParagraph.textAttchmentList];
        
    }
    
//    isInsertText=NO;
//    
//    if (actiontime!=nil) {
//        double time3=[[NSDate date]timeIntervalSince1970];
//        NSLog(@"drawContentInRect  beginedittime  %f",beginedittime);
//        NSLog(@"%@",actiontime);
//        actiontime=nil;
//        NSLog(@"%@",txtreplacetime);
//        txtreplacetime=nil;
//        NSLog(@"drawContentInRect  txtchang  %f",txtchangetime);
//        NSLog(@"drawContentInRect  carettime  %f",caretedittime);
//        NSLog(@"drawContentInRect  selectrange  %f",selectedRangetime);
//        NSLog(@"drawContentInRect  setneeddisplaytime  %f",setneeddisplaytime);
//        NSLog(@"drawContentInRect  draw begintime %f",starttime);
//        NSLog(@"drawContentInRect  draw  %f",time3-starttime);
//        NSLog(@"drawContentInRect  totaltime  %f",time3-beginedittime);
//    }
    
}


#endif


-(void)setPlaceHolder:(NSString *)mplaceHolder{
    _placeHolder=mplaceHolder;
    [self showPlaceHolderView];
}
-(void)showPlaceHolderView{
    if (_placeHolderView !=nil) {
        [_placeHolderView removeFromSuperview];
    }
    _placeHolderView =[[UILabel alloc]initWithFrame:CGRectMake(8, 8, 100, 20)];
    [_placeHolderView setText:_placeHolder];
    [_placeHolderView setFont:[UIFont systemFontOfSize:16]];
    [_placeHolderView setTextColor:[UIColor lightGrayColor]];
    _placeHolderView.backgroundColor=[UIColor clearColor];
    [self addSubview:_placeHolderView];
}




#pragma mark CTextStorageDelegate
-(void)textStorageWillProcessEditing:(CTextStorage *)storage{
//    if(_delegateRespondsToDidBeginEditing)
//        [self.delegate fastTextViewDidBeginEditing:self];
}

-(void)textStorageDidProcessEditing:(CTextStorage *)storage{
    [self layoutChange];
//    if(_delegateRespondsToDidEndEditing)
//        [self.delegate CTextViewDidEndEditing:self];
}


-(void)layoutChange{
    CGRect rect =  _textContentView.frame;
    rect.size.height = self.attributedString.paragraphSize.height;
    _textContentView.frame= CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, MAX(rect.size.height, 0));
    
    CGRect backRect = _backGroudView.frame;
    backRect.size.height =  MAX(rect.size.height+38, self.bounds.size.height);
    _backGroudView.frame =  backRect;
    
    //NSLog(@"layoutChange  _textContentView.frame %@",NSStringFromCGRect(_textContentView.frame));
    
    self.contentSize=CGSizeMake(self.frame.size.width, _textContentView.frame.size.height+38);
    
//    for (UIView *view in _attachmentViews) {
//        [view removeFromSuperview];
//    }
//    [_attributedString enumerateAttribute:CTextAttachmentAttributeName inRange: NSMakeRange(0, [_attributedString length]) options: 0 usingBlock: ^(id value, NSRange range, BOOL *stop) {
//        
//        if ([value respondsToSelector: @selector(attachmentView)]) {
//            UIView *view = [value attachmentView];
//            [_attachmentViews addObject: view];
//            
//            CGRect rect = [self firstRectForNSRange: range];
//            rect.size = [view frame].size;
//            [view setFrame: rect];
//            [self addSubview: view];
//        }
//    }];
}
+ (UIColor*)selectionColor {
    static UIColor *color = nil;
    if (color == nil) {
        color = CUIColorFromRGBA(0x635752,0.2);
    }
    return color;
}

+ (UIColor*)caretColor {
    static UIColor *color = nil;
    if (color == nil) {
         color = CUIColorFromRGB(0xab8a72);
    }
    return color;
}

+ (UIColor*)spellingSelectionColor {
    static UIColor *color = nil;
    if (color == nil) {
        color = [UIColor colorWithRed:1.000f green:0.851f blue:0.851f alpha:1.0f];
    }
    return color;
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: UIResponder
/////////////////////////////////////////////////////////////////////////////

// MARK: UITextInput - Text Input Delegate and Text Input Tokenizer

- (id <UITextInputTokenizer>)tokenizer {
    return _tokenizer;
}

- (BOOL)canBecomeFirstResponder {
    
//    if (_editable && _delegateRespondsToShouldBeginEditing) {
//        return [self.delegate fastTextViewShouldBeginEditing:self];
//    }
//    isFirstResponser=YES;
    
    return YES;
}

- (BOOL)becomeFirstResponder {
//    isFirstResponser=YES;
//    if (_editable) {
//        
//        _editing = YES;
//        
//        if (_delegateRespondsToDidBeginEditing) {
//            [self.delegate fastTextViewDidBeginEditing:self];
//        }
//        [self selectionChanged];
//        
//    }
    if (_placeHolderView!=nil ) {
        [_placeHolderView removeFromSuperview];
        _placeHolderView=nil;
    }
    
    return [super becomeFirstResponder];
}

- (BOOL)canResignFirstResponder {
    
//    if (_editable && _delegateRespondsToShouldEndEditing) {
//        return [self.delegate fastTextViewShouldEndEditing:self];
//    }
    
    return YES;
}

- (BOOL)resignFirstResponder {
    
//    if (_editable) {
//        
//        _editing = NO;
//        
//        if (_delegateRespondsToDidEndEditing) {
//            [self.delegate fastTextViewDidEndEditing:self];
//        }
//        
//        [self selectionChanged];
//        
//    }
//    
//    [_caretView removeFromSuperview];//resignFirstResponder should remove caret // 需要去掉光标
//    
//    if (![self.attributedString.string isEqualToString:EMPTY_STRING] ) {//self.attributedString.length>0
//        [_placeHolderView removeFromSuperview];
//        _placeHolderView=nil;
//    }else{
//        [self showPlaceHolderView];
//    }
//    
//    isFirstResponser=NO;
    
	return [super resignFirstResponder];
    
}



#pragma mark

- (void)tap:(UITapGestureRecognizer*)gesture {
    BOOL isShowMenu=TRUE;
    
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showMenu) object:nil];
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showCorrectionMenu) object:nil];
    
    self.correctionRange = NSMakeRange(NSNotFound, 0);
    
    if (self.selectedRange.length>0) {
        self.selectedRange = NSMakeRange(_selectedRange.location, 0);
    }
    
    NSInteger index = [self closestWhiteSpaceIndexToPoint:[gesture locationInView:self]];
    
//    if (_delegateRespondsToDidSelectURL && !_editing) {
//        if ([self selectedLinkAtIndex:index]) {
//            return;
//        }
//    }
//    
    [self.inputDelegate selectionWillChange:self];
    
    self.markedRange = NSMakeRange(NSNotFound, 0);
//    NSRange oldSelectedRange=self.selectedRange;
    
    self.selectedRange = NSMakeRange(index, 0);
    
    [self applyCaretChangeForIndex:index point:[gesture locationInView:self]];
    
//    if ((oldSelectedRange.location==self.selectedRange.location)
//        &&(oldSelectedRange.length==self.selectedRange.length) ) {
//        if (isSecondTap) {
//            isShowMenu=TRUE;
//        }else{
//            isShowMenu=FALSE;
//        }
//        isSecondTap=!isSecondTap;
//    }else{
//        isShowMenu=FALSE;
//        isSecondTap=YES;
//    }
    
    [self.inputDelegate selectionDidChange:self];
    //bug fix : [self becomeFirstResponder] should place here to avoid 2 bugs: the caret positon bug and some break prison software conflict
    // [self becomeFirstResponder]; 应该放在后面 以避免两个BUG：光标定位的BUG 及某些越狱版手势软件 拦截  becomeFirstResponder的问题
    
//    if (_editable && ![self isFirstResponder]) {
//        [self becomeFirstResponder];
//        isShowMenu=FALSE;
//    }
    
    if (![self isFirstResponder]) {
        [self becomeFirstResponder];
        isShowMenu=FALSE;
    }
    
//    if (isShowMenu) {
//        UIMenuController *menuController = [UIMenuController sharedMenuController];
//        if ([menuController isMenuVisible]) {
//            
//            [menuController setMenuVisible:NO animated:NO];
//            
//        } else {
//            
//            if (index==self.selectedRange.location) {
//                [self performSelector:@selector(showMenu) withObject:nil afterDelay:0.35f];
//            } else {
//                if (_editing) {
//                    [self performSelector:@selector(showCorrectionMenu) withObject:nil afterDelay:0.35f];
//                }
//            }
//            
//        }
//        
//    }
    
    displayFlags=CustomDisplayRect;
    [_textContentView refreshView];
}

//wq ADD for 坐标变换
-(void)applyCaretChangeForIndex:(NSInteger)index point:(CGPoint)point{
    if (!_editing) {
        [_caretView removeFromSuperview];
    }
    
    if (!_caretView.superview) {
        [_textContentView addSubview:_caretView];
    }
    
    CGRect careRect = [self caretRectForIndex:index point:point];
    
    _caretView.frame = careRect;
    //NSLog(@"_caretView.frame %@",NSStringFromCGRect(_caretView.frame));
    [_caretView delayBlink];

    careRect.size.height= 3*MIN(30, MAX(careRect.size.height,25)) ;
  
    [self scrollRectToVisible:careRect animated:YES];
}


//获得光标的RECT 增加了一个位置参数point，对于 tap: doubletap: longpress: 等操作来讲，可以获得更精准的光标位置
- (CGRect)caretRectForIndex:(NSInteger)index point:(CGPoint)point {
    
    // no text / first index
    if (_attributedString.length == 0 && index == 0) {
        caretLineIndex=0;
        caretLineWidth=0;
        if (self.selectedRange.length!=0) {
            caretLineIndex_selected=(caretLineIndex_selected<caretLineIndex)?caretLineIndex_selected: caretLineIndex;
        }
        /*   CGPoint origin = CGPointMake(0, -self.font.lineHeight);
         // NSLog(@"********* caretLineIndex %d caretLineWidth %f",caretLineIndex,caretLineWidth);
         return CGRectMake(origin.x, origin.y, 3, self.font.ascender + fabs(self.font.descender*2));
         */
        //NSLog(@"_textContentView.bounds %@",NSStringFromCGRect(_textContentView.bounds));
        
        CGPoint origin = CGPointMake(CGRectGetMinX(_textContentView.bounds), CGRectGetMaxY(_textContentView.bounds) - self.font.leading);//gfthr add for caret not in first line
        
        
        CGRect careRect=CGRectMake(origin.x, origin.y, 3, self.font.ascender + fabs(self.font.descender*2));
        
        careRect=CGRectApplyAffineTransform (careRect,CGAffineTransformMake(1.0, 0.0, 0.0, -1.0,0.0,_textContentView.frame.size.height));
        
        return careRect;
        
    } else if (_attributedString.length == 0 || index == 0) {
        CGPoint origin = CGPointMake(CGRectGetMinX(_textContentView.bounds), CGRectGetMaxY(_textContentView.bounds) - self.font.leading);//gfthr add for caret not in first line
        
        
        CGRect careRect=CGRectMake(origin.x, origin.y, 3, self.font.ascender + fabs(self.font.descender*2));
        
        careRect=CGRectApplyAffineTransform (careRect,CGAffineTransformMake(1.0, 0.0, 0.0, -1.0,0.0,_textContentView.frame.size.height));
        return careRect;
    }
    
    
    
    index = MAX(index, 0);
    index = MIN(_attributedString.string.length, index);
    
    BOOL isfound=FALSE;
    CGRect returnRect = CGRectZero;
    for (int j=0; j<[_attributedString.paragraphs count]; j++) {
        if (isfound) {
            break;
        }
        CTextParagraph *textParagraph=[_attributedString.paragraphs objectAtIndex:j];
        NSArray *lines = textParagraph.lines;
        NSInteger count = [lines count];
        CGPoint *origins = textParagraph.origins;
        
        for (int i = 0; i < count; i++) {
            CTextLine *fastline=[lines objectAtIndex:i];
            
            CFRange cfRange =[textParagraph lineGetStringRange:fastline];
            NSRange range = NSMakeRange(cfRange.location == kCFNotFound ? NSNotFound : cfRange.location, cfRange.length);
            
            if ((index >=range.location) && (index <= range.location+range.length)) {
                CTLineRef line =[self.attributedString buildCTLineRef:fastline withParagraph:textParagraph] ;
                NSInteger lineindex=index-textParagraph.range.location;
                BOOL lineHasImage= [self checkLineHasImage:line lineRange:fastline.range];
                CGFloat ascent=fastline.ascent, descent=fastline.descent, xPos;
                xPos = [textParagraph lineGetGetOffsetForStringIndex:line fastTextLine:fastline charIndex:lineindex secondaryOffset:NULL];
                
                CFRelease(line);
                
                double lineWidth=fastline.lineWidth;
                CGPoint origin = origins[i];
                
                CGFloat  origin_y=[textParagraph lineGetOriginY:origin.y];
                
                if (_selectedRange.length>0 && index != _selectedRange.location && range.length == 1) {
                    xPos = _textContentView.bounds.size.width - 3.0f; // selection of entire line
                } else if ((([_attributedString.string characterAtIndex:index-1] == '\n')||([_attributedString.string characterAtIndex:index-1] == '\r')) && range.length == 1) {
                    xPos = 0.0f; // empty line
                }
                
                caretLineIndex=i;
                caretLineWidth=origin.x+ lineWidth;
                if (self.selectedRange.length!=0) {
                    caretLineIndex_selected=(caretLineIndex_selected<caretLineIndex)?caretLineIndex_selected: caretLineIndex;
                }
                // NSLog(@"********* caretLineIndex %d caretLineWidth %f",caretLineIndex,caretLineWidth);
                returnRect = CGRectMake(origin.x + xPos,  floorf(origin_y - descent), 3, ceilf((descent*2) + ascent));
                // gfthr add: make the caret positon more accurate
                //更精准的控制光标
                point = [self convertPoint:point toView:_textContentView];
                if(point.x>=0 && point.y>=0 && !lineHasImage){
                    if (point.y > origin_y) {
                        isfound=TRUE;
                        break;
                    }
                }
                
                if (index == _attributedString.length && (([_attributedString.string characterAtIndex:(index - 1)] == '\n')||([_attributedString.string characterAtIndex:(index - 1)] == '\r')) ) {
                    //                    if (lineHasImage) {
                    
                    //wq ADD for 坐标变换
                    CGRect careRect=CGRectMake(origin.x, floorf(origin_y - descent*2 - self.font.ascender) , 3, self.font.ascender + fabs(self.font.descender*2));
                    
                    careRect=CGRectApplyAffineTransform (careRect,CGAffineTransformMake(1.0, 0.0, 0.0, -1.0,0.0,_textContentView.frame.size.height));
                    //wq ADD for 坐标变换 -END
                    return careRect;
                    //                    }
                }
            }
        }
    }
    
    returnRect=CGRectApplyAffineTransform (returnRect,CGAffineTransformMake(1.0, 0.0, 0.0, -1.0,0.0,_textContentView.frame.size.height));
    return returnRect;
}

//MARK: 转换坐标
- (CGPoint)convertPoint:(CGPoint)point toView:(UIView *)view{
    point = [super convertPoint:point toView:_textContentView];
    point=CGPointMake(point.x, _textContentView.frame.size.height-point.y);
    return point;
}
//fix bug :gfthr when tap on the editor, the caret not on the image line // tap时光标不要在 图片行
- (NSInteger)closestWhiteSpaceIndexToPoint:(CGPoint)point {
    
    point = [self convertPoint:point toView:_textContentView];
    
    __block NSRange returnRange = NSMakeRange(_attributedString.length, 0);
    
    BOOL isfound=FALSE;
    
    for (int j=0; j<[_attributedString.paragraphs count]; j++) {
        if (isfound) {
            break;
        }
        
        CTextParagraph *textParagraph=[_attributedString.paragraphs objectAtIndex:j];
        
        NSArray *lines = textParagraph.lines;
        CGPoint *origins = textParagraph.origins;
        
        for (int i = 0; i < lines.count; i++) {
            CGFloat originsy=[textParagraph lineGetOriginY:origins[i].y];
            NSLog(@"point y:%f origin y:%f",point.y,originsy);
            
            if (point.y > originsy) {
                NSLog(@"point.y > originsy");
                CTextLine *fastline=[lines objectAtIndex:i];
                CTLineRef line =[self.attributedString buildCTLineRef:fastline withParagraph:textParagraph] ;
                
                BOOL lineHasImage= [self checkLineHasImage:line lineRange:fastline.range];
                
                CFRange cfRange =[textParagraph lineGetStringRange:fastline];
                NSRange range = NSMakeRange(cfRange.location == kCFNotFound ? NSNotFound : cfRange.location, cfRange.length);
                CGPoint convertedPoint = CGPointMake(point.x - origins[i].x, point.y - originsy);
                CFIndex cfIndex = [textParagraph lineGetStringIndexForPosition:line fastTextLine:fastline piont:convertedPoint];
                NSInteger index = cfIndex == kCFNotFound ? NSNotFound : cfIndex;
                
                returnRange =NSMakeRange(index,0);
                
                if(range.location==NSNotFound){
                    isfound=TRUE;
                    break;
                }
                
                
                if (index>=_attributedString.length) {
                    returnRange = NSMakeRange(_attributedString.length, 0);
                    isfound=TRUE;
                    break;
                }
                
                if (range.length <= 1) {
                    returnRange = NSMakeRange(range.location, 0);
                    if (lineHasImage) {
                        returnRange=[self changRangeImageLine:lines curParagraph:textParagraph curParagraphIndex:j curline:i];
                    }
                    isfound=TRUE;
                    break;
                }
                
                if (index == range.location) {
                    returnRange = NSMakeRange(range.location, 0);
                    if (lineHasImage) {
                        returnRange=[self changRangeImageLine:lines curParagraph:textParagraph curParagraphIndex:j curline:i];
                    }
                    isfound=TRUE;
                    break;
                }
                
                
                if (index >= (range.location+range.length)) {
                    
                    if (range.length > 1 && (([_attributedString.string characterAtIndex:(range.location+range.length)-1] == '\n')||([_attributedString.string characterAtIndex:(range.location+range.length)-1] == '\r'))) {
                        
                        returnRange = NSMakeRange(index-1, 0);
                        if (lineHasImage) {
                            returnRange=[self changRangeImageLine:lines curParagraph:textParagraph curParagraphIndex:j curline:i];
                        }
                        isfound=TRUE;
                        break;
                        
                    } else {
                        
                        returnRange = NSMakeRange(range.location+range.length, 0);
                        if (lineHasImage) {
                            returnRange=[self changRangeImageLine:lines curParagraph:textParagraph curParagraphIndex:j curline:i];
                        }
                        isfound=TRUE;
                        break;
                        
                    }
                    
                }
                /*
                 [_attributedString.string enumerateSubstringsInRange:range options:NSStringEnumerationByWords usingBlock:^(NSString *subString, NSRange subStringRange, NSRange enclosingRange, BOOL *stop){
                 
                 if (NSLocationInRange(index, enclosingRange)) {
                 
                 if (index > (enclosingRange.location+(enclosingRange.length/2))) {
                 
                 returnRange = NSMakeRange(subStringRange.location+subStringRange.length, 0);
                 
                 } else {
                 
                 returnRange = NSMakeRange(subStringRange.location, 0);
                 
                 }
                 
                 *stop = YES;
                 }
                 
                 }];*/
                if (lineHasImage) {
                    returnRange=[self changRangeImageLine:lines curParagraph:textParagraph curParagraphIndex:j curline:i];
                }
                CFRelease(line);
                isfound=TRUE;
                break;
            }
        }
        
    }
    
    
    return returnRange.location;
}

//fix bug :gfthr ADD:to check line has image // 检查某一行是否有图片
-(BOOL)checkLineHasImage:(CTLineRef )line lineRange:(CFRange)lineRange{
    BOOL lineHasImage=FALSE;
    if (!self.isImageSigleLine) {
        return lineHasImage;
    }
    
    CFRange cfRange = lineRange;
    if (cfRange.location == kCFNotFound ) {
        return lineHasImage;
    }
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    CFIndex runsCount = CFArrayGetCount(runs);
    
    for (CFIndex runsIndex = 0; runsIndex < runsCount; runsIndex++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, runsIndex);
        CFDictionaryRef attributes = CTRunGetAttributes(run);
        id <CTextAttachmentCell> attachmentCell = [( __bridge NSDictionary*)(attributes) objectForKey: CTextAttachmentAttributeName];
        if (attachmentCell != nil && [attachmentCell respondsToSelector: @selector(attachmentSize)] && [attachmentCell respondsToSelector: @selector(attachmentDrawInRect:)]) {
            lineHasImage=TRUE;
            break;
        }
    }
    return  lineHasImage;
}

//fix bug :gfthr ADD: move caret to next line or last line //把光标放到下一行或者最后一行，用于在图片行用
-(NSRange)changRangeImageLine:(NSArray *)lines curParagraph:(CTextParagraph *)curParagraph curParagraphIndex:(int)paragraphIndex curline:(int)curline {
    NSRange returnRange = NSMakeRange(_attributedString.length, 0);
    if (curline==(lines.count-1) && paragraphIndex==([_attributedString.paragraphs count]-1)) {//last line //最后一行
        returnRange = NSMakeRange(_attributedString.length, 0);
    }else if(curline==(lines.count-1)){//next paragraph first line // 下一个章节的第一行
        
        CTextParagraph *textParagraph=[_attributedString.paragraphs objectAtIndex:(paragraphIndex+1)];
        NSArray *newlines = textParagraph.lines;
        CTextLine *nextline=[newlines objectAtIndex:0];
        CFRange nextcfRange =[textParagraph lineGetStringRange:nextline];
        NSRange nextrange = NSMakeRange(nextcfRange.location == kCFNotFound ? NSNotFound : nextcfRange.location, nextcfRange.length);
        if(nextrange.location==NSNotFound){
            returnRange = NSMakeRange(_attributedString.length, 0);
        }
        returnRange=NSMakeRange(nextrange.location, 0);
    }else{//next line first  //获得下一行第一个
        CTextLine *nextline=[lines objectAtIndex:(curline+1)];
        CFRange nextcfRange = [curParagraph lineGetStringRange:nextline];
        NSRange nextrange = NSMakeRange(nextcfRange.location == kCFNotFound ? NSNotFound : nextcfRange.location, nextcfRange.length);
        if(nextrange.location==NSNotFound){
            returnRange = NSMakeRange(_attributedString.length, 0);
        }
        returnRange=NSMakeRange(nextrange.location, 0);
        
    }
    return returnRange;
    
}

/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Layout methods
/////////////////////////////////////////////////////////////////////////////

- (NSRange)rangeIntersection:(NSRange)first withSecond:(NSRange)second {
    
    NSRange result = NSMakeRange(NSNotFound, 0);
    
    if (first.location > second.location) {
        NSRange tmp = first;
        first = second;
        second = tmp;
    }
    
    if (second.location < first.location + first.length) {
        result.location = second.location;
        NSUInteger end = MIN(first.location + first.length, second.location + second.length);
        result.length = end - result.location;
    }
    
    return result;
}

-(void)applyCaretChangeForIndex:(NSInteger)index{
    return [self applyCaretChangeForIndex:index point:CGPointMake(-1.0f, -1.0f)];
    
}

/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: UITextInput methods
/////////////////////////////////////////////////////////////////////////////

- (NSString *)textInRange:(UITextRange *)range {
    CIndexedRange *r = (CIndexedRange *)range;
    //IOS7 BUG FIX
    if ((r.range.location+r.range.length)<=[_attributedString.string length]) {
        return ([_attributedString.string substringWithRange:r.range]);
    }else{
        return @"";
    }
    
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)text {
    
    CIndexedRange *r = (CIndexedRange *)range;
    
    NSRange selectedNSRange = self.selectedRange;
    if ((r.range.location + r.range.length) <= selectedNSRange.location) {
        selectedNSRange.location -= (r.range.length - text.length);
    } else {
        selectedNSRange = [self rangeIntersection:r.range withSecond:_selectedRange];
    }
    [_attributedString replaceCharactersInRange:r.range withString:text];
    self.selectedRange = selectedNSRange;
//    _dirty=YES;
    
}

// MARK: UITextInput - Working with Marked and Selected Text

- (UITextRange *)selectedTextRange {
    return [CIndexedRange rangeWithNSRange:self.selectedRange];
}

- (void)setSelectedTextRange:(UITextRange *)range {
    CIndexedRange *r = (CIndexedRange *)range;
    self.selectedRange = r.range;
    if (self.selectedRange.length == 0) {
        [self applyCaretChangeForIndex:self.selectedRange.location];
    }
}

- (UITextRange *)markedTextRange {
    return [CIndexedRange rangeWithNSRange:self.markedRange];
}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange {
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    
    if ([menuController isMenuVisible]) {
        [menuController setMenuVisible:NO animated:NO];
    }
    
    
//    isInsertText=TRUE;
//    
//    actiontime=[NSString stringWithFormat:@"markedText %@",markedText];
//    beginedittime=[[NSDate date]timeIntervalSince1970];
    
    if (markedText!=nil && [markedText length]>0) {  //gfthr add for fix baidu input bug baidu3.5.5
        [self.attributedString beginStorageEditing];
        
        NSRange selectedNSRange = self.selectedRange;
        NSRange markedTextRange = self.markedRange;
        
        if (markedTextRange.location != NSNotFound) {
            if (!markedText)
                markedText = @"";
            
            [self.attributedString replaceCharactersInRange:markedTextRange withString:markedText];
            markedTextRange.length =markedText.length;
            
        } else if (selectedNSRange.length > 0) {
//            lastMarkedText=nil;
            [self.attributedString replaceCharactersInRange:selectedNSRange withString:markedText];
            markedTextRange.location = selectedNSRange.location;
            markedTextRange.length = markedText.length;
            
        } else {
//            lastMarkedText=nil;
            NSAttributedString *string = [[NSAttributedString alloc] initWithString:markedText attributes:self.attributeConfig.attributes];
            [self.attributedString insertAttributedString:string atIndex:selectedNSRange.location];
            
            markedTextRange.location = selectedNSRange.location;
            markedTextRange.length = markedText.length;
            
        }
        
        selectedNSRange = NSMakeRange(selectedRange.location + markedTextRange.location, selectedRange.length);
        //NSLog(@"setMarkedText selectedNSRange %@",NSStringFromRange(selectedNSRange));
        
//        txtreplacetime=self.attributedString.buildParagraghTime;
//        double begintxttime=[[NSDate date]timeIntervalSince1970];
        
        [self.attributedString endStorageEditing];
        
        double endtxttime=[[NSDate date]timeIntervalSince1970];
//        txtchangetime=endtxttime-begintxttime;
        
//        double beginselectedRangetime=[[NSDate date]timeIntervalSince1970];
        self.markedRange = markedTextRange;
        self.selectedRange = selectedNSRange;
//        double endselectedRangetime=[[NSDate date]timeIntervalSince1970];
//        selectedRangetime=endselectedRangetime-beginselectedRangetime;
        
//        _dirty=YES;
        
        
//        double beginCarettime=[[NSDate date]timeIntervalSince1970];
        
        if (self.selectedRange.length == 0) {
            [self applyCaretChangeForIndex:self.selectedRange.location];
        }
//        double endCarettime=[[NSDate date]timeIntervalSince1970];
//        caretedittime=endCarettime-beginCarettime;
        
        /*
         if (![markedText isEqualToString:lastMarkedText]) { //baidu 4.0 markedText 和 lastMarkedText 老是相等
         [_textContentView refreshView];
         NSLog(@"_textContentView refreshView");
         }else{
         isInsertText=NO;
         }
         */
        [_textContentView refreshView];//fixbug baidu 4.0 markedText 和 lastMarkedText 老是相等
//        lastMarkedText=markedText;
//        setneeddisplaytime=[[NSDate date]timeIntervalSince1970];
        
    }else{//gfthr fix bug:delete markedText left one char and avoid baidu bug baidu3.5.5
        
//        NSRange selectedNSRange = self.selectedRange;
//        NSRange markedTextRange = self.markedRange;
//        if (markedTextRange.location != NSNotFound) {
//            if (!markedText)
//                markedText = @"";
//            [self.attributedString beginStorageEditing];
//            [self.attributedString replaceCharactersInRange:markedTextRange withString:markedText];
//            markedTextRange.length = markedText.length;
//            selectedNSRange = NSMakeRange(selectedRange.location + markedTextRange.location, selectedRange.length);
//            
//            self.markedRange = markedTextRange;
//            self.selectedRange = selectedNSRange;
//            
//            [self.attributedString endStorageEditing];
//            
//            if (self.selectedRange.length == 0) {
//                [self applyCaretChangeForIndex:self.selectedRange.location];
//            }
//            
//            if (![markedText isEqualToString:lastMarkedText]) {
//                [_textContentView refreshView];
//            }else{
////                isInsertText=NO;
//            }
//            
//            lastMarkedText=markedText;
//        }
    }
    
    
}

- (void)unmarkText {
    
    NSRange markedTextRange = self.markedRange;
    
    if (markedTextRange.location == NSNotFound)
        return;
    
    markedTextRange.location = NSNotFound;
    self.markedRange = markedTextRange;
    
}



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: UIKeyInput methods
/////////////////////////////////////////////////////////////////////////////

- (BOOL)hasText {
    return (_attributedString.length != 0);
}

- (void)insertText:(NSString *)text {
    NSString *newText=text;
    NSLog(@"text :%@",text);
//    if ([text isEqualToString:@"\n"]) {
//        newText=[NSString stringWithFormat:@"\n%@",EMPTY_STRING];
//    }
//    isInsertText=TRUE;
    
    _textContentView.tiledLayer.isChangeFrame=TRUE;
    
//    actiontime=[NSString stringWithFormat:@"insertText %@",newText];
//    
//    beginedittime=[[NSDate date]timeIntervalSince1970];
    NSAttributedString *newString = [[NSAttributedString alloc] initWithString:newText attributes:self.attributeConfig.attributes];
//    caretedittime=[[NSDate date]timeIntervalSince1970];
    NSRange oldrange= NSMakeRange(self.selectedRange.location, newString.length);
    
    [self insertAttributedString:newString isRefresh:YES range:oldrange];
    
//    selectedRangetime=[[NSDate date]timeIntervalSince1970];
    
    if (self.selectedRange.length == 0) {
        [self applyCaretChangeForIndex:self.selectedRange.location];
    }
    
    
    
//    setneeddisplaytime=[[NSDate date]timeIntervalSince1970];
    
//    _dirty=YES;
    displayFlags=CustomDisplayRect;
    [_textContentView refreshView];
    
//    _dirty=YES;
}


- (void)insertAttributedString:(NSAttributedString *)newString isRefresh:(BOOL)isRefresh range:(NSRange)range{
    
    NSRange selectedNSRange = self.selectedRange;
    NSRange markedTextRange = self.markedRange;
    
    NSString *text=newString.string;
    
    /*if (_correctionRange.location != NSNotFound && _correctionRange.length > 0){
     ace
     [_mutableAttributedString replaceCharactersInRange:self.correctionRange withAttributedString:newString];
     selectedNSRange.length = 0;
     selectedNSRange.location = (self.correctionRange.location+text.length);
     self.correctionRange = NSMakeRange(NSNotFound, 0);
     
     } else*/
    [self.attributedString beginStorageEditing];
    if (markedTextRange.location != NSNotFound) {
        
        [self.attributedString replaceCharactersInRange:markedTextRange withAttributedString:newString];
        selectedNSRange.location = markedTextRange.location + text.length;
        selectedNSRange.length = 0;
        markedTextRange = NSMakeRange(NSNotFound, 0);
        
    } else if (selectedNSRange.length > 0) {
        
        [self.attributedString replaceCharactersInRange:selectedNSRange withAttributedString:newString];
        selectedNSRange.length = 0;
        selectedNSRange.location = (selectedNSRange.location + text.length);
        
    } else {
        
        [self.attributedString insertAttributedString:newString atIndex:selectedNSRange.location];
        selectedNSRange.location += text.length;
        
    }
    
    if (isRefresh) {
        [self.attributedString refreshParagraghInRange:range];
    }
    
    [self.attributedString endStorageEditing];
    
//    txtreplacetime=self.attributedString.buildParagraghTime;
    
    self.markedRange = markedTextRange;
    self.selectedRange = selectedNSRange;
    /*
     if (text.length > 1 || ([text isEqualToString:@" "] || [text isEqualToString:@"\n"])) {
     //[self checkSpellingForRange:[self characterRangeAtIndex:self.selectedRange.location-1]];
     [self checkLinksForRange:NSMakeRange(0, self.attributedString.length)];
     }
     */
    
    
}



- (void)insertAttributedString:(NSAttributedString *)newString {
    NSRange range=NSMakeRange(NSNotFound, 0);
    [self insertAttributedString:newString isRefresh:NO range:range];
}

- (void)deleteBackward  {
//    return;
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    
    if ([menuController isMenuVisible]) {
        [menuController setMenuVisible:NO animated:NO];
    }
    
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showCorrectionMenuWithoutSelection) object:nil];
    
    NSRange selectedNSRange = self.selectedRange;
    NSRange markedTextRange = self.markedRange;
    [self.attributedString beginStorageEditing];
    
    /*  if (_correctionRange.location != NSNotFound && _correctionRange.length > 0) {
     
     [_mutableAttributedString beginStorageEditing];
     [_mutableAttributedString deleteCharactersInRange:self.correctionRange];
     [_mutableAttributedString endStorageEditing];
     self.correctionRange = NSMakeRange(NSNotFound, 0);
     selectedNSRange.length = 0;
     
     } else*/
    
    if (markedTextRange.location != NSNotFound) {
        
        //[self.attributedString beginStorageEditing];
        [self.attributedString deleteCharactersInRange:selectedNSRange];
        //[self.attributedString endStorageEditing];
        
        selectedNSRange.location = markedTextRange.location;
        selectedNSRange.length = 0;
        markedTextRange = NSMakeRange(NSNotFound, 0);
        
    } else if (selectedNSRange.length > 0) {
        
        if ([_attributedString.string characterAtIndex:selectedNSRange.location] == '\n' && selectedNSRange.length==1) {
            //NSLog(@"selectedNSRange.length > 0");
            
            //fix bug: IOS7 new bug >>> gfthr ADD delete the image bug
            //删除时，删除整张图片
            NSRange checkImageRang=NSMakeRange(MAX(0, selectedNSRange.location-1), 2) ;
            unichar attachmentCharacter = CTextAttachmentCharacter;
            
            if ([[_attributedString.string substringWithRange:checkImageRang] isEqualToString:[NSString stringWithFormat:@"%@\n",[NSString stringWithCharacters:&attachmentCharacter length:1]]]) {
                selectedNSRange=checkImageRang;
            }
            //fix bug end
            
        }
        
        
        [self.attributedString deleteCharactersInRange:selectedNSRange];
        
        selectedNSRange.length = 0;
        
    } else if (selectedNSRange.location > 0) {
        
        NSInteger index = MAX(0, selectedNSRange.location-1);
        index = MIN(_attributedString.length-1, index);
        if ([_attributedString.string characterAtIndex:index] == ' ') {
//            [self performSelector:@selector(showCorrectionMenuWithoutSelection) withObject:nil afterDelay:0.2f];
        }
        
        NSInteger itmp=selectedNSRange.location - 1;
        if (itmp>=0 && itmp<[[_attributedString string] length]) { //fix ios7 删除字符时的bug
            
            selectedNSRange = [[_attributedString string] rangeOfComposedCharacterSequenceAtIndex:selectedNSRange.location - 1];
            //fix bug: gfthr ADD delete the image bug
            //删除时，删除整张图片
            NSRange checkImageRang=NSMakeRange(MAX(0, selectedNSRange.location-1), 2) ;
            unichar attachmentCharacter = CTextAttachmentCharacter;
            
            if ([[_attributedString.string substringWithRange:checkImageRang] isEqualToString:[NSString stringWithFormat:@"%@\n",[NSString stringWithCharacters:&attachmentCharacter length:1]]]) {
                selectedNSRange=checkImageRang;
            }
            //fix bug end
            [self.attributedString deleteCharactersInRange:selectedNSRange];
        }
        
        
        selectedNSRange.length = 0;
    }
    
    //fix bug: gfthr ADD check selectrange line is have image and move to next line
    //看看selectrange 这一行 是否有图片，有则 往下一行
    selectedNSRange= [self checkSelectedNSRangeLineImage:selectedNSRange];
    //fix bug end
    
    [self.attributedString endStorageEditing];
    self.markedRange = markedTextRange;
    self.selectedRange = selectedNSRange;
    if (self.selectedRange.length == 0) {
        [self applyCaretChangeForIndex:self.selectedRange.location];
    }
//    _dirty=YES;
    displayFlags=CustomDisplayRect;
    [_textContentView refreshView];
}

-(NSRange)checkSelectedNSRangeLineImage:(NSRange)selectedNSRange{
    
    __block NSRange returnRange = selectedNSRange;
    
    for (int j=0; j<[_attributedString.paragraphs count]; j++) {
        CTextParagraph *textParagraph=[_attributedString.paragraphs objectAtIndex:j];
        __block NSArray *lines = textParagraph.lines;
        
        for (int i = 0; i < lines.count; i++) {
            CTextLine *fastline=[lines objectAtIndex:i];
            
            CFRange cfRange = [textParagraph lineGetStringRange:fastline];
            if (cfRange.location == kCFNotFound ) {
                return returnRange;
            }
            
            long start=cfRange.location;
            long end=cfRange.location+cfRange.length;
            
            if (selectedNSRange.location>=start && selectedNSRange.location<=end) {
                CTLineRef line =[self.attributedString buildCTLineRef:fastline withParagraph:textParagraph] ;
                BOOL lineHasImage= [self checkLineHasImage:line lineRange:fastline.range ];
                if (lineHasImage) {
                    returnRange=[self changRangeImageLine:lines curParagraph:textParagraph curParagraphIndex:j curline:i];
                }
                CFRelease(line);
                return returnRange;
            }
            
        }
        
    }
    
    return  returnRange;
    
}
// MARK: UITextInput - Computing Text Ranges and Text Positions

- (UITextPosition*)beginningOfDocument {
    return [CIndexedPosition positionWithIndex:0];
}

- (UITextPosition*)endOfDocument {
    return [CIndexedPosition positionWithIndex:_attributedString.length];
}

- (UITextRange*)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition {
    
    CIndexedPosition *from = (CIndexedPosition *)fromPosition;
    CIndexedPosition *to = (CIndexedPosition *)toPosition;
    NSRange range = NSMakeRange(MIN(from.index, to.index), ABS(to.index - from.index));
    return [CIndexedRange rangeWithNSRange:range];
    
}

- (UITextPosition*)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset {
    
    CIndexedPosition *pos = (CIndexedPosition *)position;
    NSInteger end = pos.index + offset;
	
    if (end > _attributedString.length || end < 0)
        return nil;
    
    return [CIndexedPosition positionWithIndex:end];
}

- (UITextPosition*)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset {
    
    CIndexedPosition *pos = (CIndexedPosition *)position;
    NSInteger newPos = pos.index;
    
    switch (direction) {
        case UITextLayoutDirectionRight:
            newPos += offset;
            break;
        case UITextLayoutDirectionLeft:
            newPos -= offset;
            break;
        UITextLayoutDirectionUp: // not supported right now
            break;
        UITextLayoutDirectionDown: // not supported right now
            break;
        default:
            break;
            
    }
    
    if (newPos < 0)
        newPos = 0;
    
    if (newPos > _attributedString.length)
        newPos = _attributedString.length;
    
    return [CIndexedPosition positionWithIndex:newPos];
}

// MARK: UITextInput - Geometry

- (CGRect)firstRectForRange:(UITextRange *)range {
    
    CIndexedRange *r = (CIndexedRange *)range;
    return [self firstRectForNSRange:r.range];
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range{
    return [[NSArray alloc] init]; //need TODO
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
    
    CIndexedPosition *pos = (CIndexedPosition *)position;
	return [self caretRectForIndex:pos.index];
}

- (UIView *)textInputView {
    return _textContentView;
}

// MARK: UITextInput - Hit testing

- (UITextPosition*)closestPositionToPoint:(CGPoint)point {
    
    CIndexedPosition *position = [CIndexedPosition positionWithIndex:[self closestIndexToPoint:point]];
    return position;
    
}

- (UITextPosition*)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range {
	
    CIndexedPosition *position = [CIndexedPosition positionWithIndex:[self closestIndexToPoint:point]];
    return position;
    
}

- (UITextRange*)characterRangeAtPoint:(CGPoint)point {
	
    CIndexedRange *range = [CIndexedRange rangeWithNSRange:[self characterRangeAtPoint_:point]];
    return range;
    
}

- (NSRange)characterRangeAtPoint_:(CGPoint)point {
    
    BOOL isfound=FALSE;
    __block NSRange returnRange = NSMakeRange(NSNotFound, 0);
    
    for (int j=0; j<[_attributedString.paragraphs count]; j++) {
        if (isfound) {
            break;
        }
        CTextParagraph *textParagraph=[_attributedString.paragraphs objectAtIndex:j];
        __block NSArray *lines =textParagraph.lines;
        
        CGPoint *origins = textParagraph.origins;
        
        for (int i = 0; i < lines.count; i++) {
            CGFloat origin_y=[textParagraph lineGetOriginY:origins[i].y];
            if (point.y > origin_y) { //wq ADD for 坐标变换
                //if (point.y > origin_y) {//
                
                CTextLine *fastline=[lines objectAtIndex:i];
                CTLineRef line =[self.attributedString buildCTLineRef:fastline withParagraph:textParagraph] ;
                
                CGPoint convertedPoint = CGPointMake(point.x - origins[i].x, point.y - origin_y);
                NSInteger index =[textParagraph lineGetStringIndexForPosition:line fastTextLine:fastline piont:convertedPoint];
                
                CFRange cfRange = [textParagraph lineGetStringRange:fastline];
                NSRange range = NSMakeRange(cfRange.location == kCFNotFound ? NSNotFound : cfRange.location, cfRange.length);
                returnRange = range;
                
                [_attributedString.string enumerateSubstringsInRange:range options:NSStringEnumerationByWords usingBlock:^(NSString *subString, NSRange subStringRange, NSRange enclosingRange, BOOL *stop){
                    
                    if (index - subStringRange.location <= subStringRange.length) {
                        returnRange = subStringRange;
                        *stop = YES;
                    }
                    
                }];
                
                CFRelease(line);
                isfound=TRUE;
                break;
            }
        }
    }
    
    return  returnRange;
    
}


- (NSInteger)closestIndexToPoint:(CGPoint)point {
    
    point = [self convertPoint:point toView:_textContentView];
    
    BOOL isfound=FALSE;
    CFIndex index = kCFNotFound;
    
    for (int j=0; j<[_attributedString.paragraphs count]; j++) {
        if (isfound) {
            break;
        }
        
        CTextParagraph *textParagraph=[_attributedString.paragraphs objectAtIndex:j];
        NSArray *lines = textParagraph.lines;
        CGPoint *origins = textParagraph.origins;
        for (int i = 0; i < lines.count; i++) {
            CGFloat originsy=[textParagraph lineGetOriginY:origins[i].y];
            if (point.y > originsy) {
                CTextLine *fastline=[lines objectAtIndex:i];
                
                CTLineRef line =[self.attributedString buildCTLineRef:fastline withParagraph:textParagraph] ;
                
                BOOL lineHasImage=[self checkLineHasImage:line lineRange:fastline.range];
                
                CGPoint convertedPoint = CGPointMake(point.x - origins[i].x, point.y - originsy);
                index = [textParagraph lineGetStringIndexForPosition:line fastTextLine:fastline piont:convertedPoint];
                //fix bug : gfthr ADD :when long press ,the caret not on the image line // 长按时光标不要放在图片行
                if (lineHasImage) {
                    NSRange returnRange=[self changRangeImageLine:lines curParagraph:textParagraph curParagraphIndex:j curline:i];
                    index=returnRange.location;
                }
                //fix bug end
                CFRelease(line);
                isfound=TRUE;
                break;
            }
        }
    }
    
    if (index == kCFNotFound) {
        index = [_attributedString length];
    }
    
    
    return index;
    
}
//获得光标的RECT
- (CGRect)caretRectForIndex:(NSInteger)index {
    return [self caretRectForIndex:index point:CGPointMake(-1.0f, -1.0f)];
}

- (CGRect)firstRectForNSRange:(NSRange)range {
    //TODO get the range rect
    // 获得某个range的rect
    NSInteger index = range.location;
    CGRect returnRect = CGRectNull;
    
    BOOL isfound=FALSE;
    
    for (int j=0; j<[_attributedString.paragraphs count]; j++) {
        if (isfound) {
            break;
        }
        CTextParagraph *textParagraph=[_attributedString.paragraphs objectAtIndex:j];
        NSArray *lines = textParagraph.lines;
        NSInteger count = [lines count];
        CGPoint *origins = textParagraph.origins;
        
        for (int i = 0; i < count; i++) {
            CTextLine *fastline=[lines objectAtIndex:i];
            CFRange lineRange = [textParagraph lineGetStringRange:fastline];
            NSInteger localIndex = index - lineRange.location;
            
            if (localIndex >= 0 && localIndex < lineRange.length) {
                CTLineRef line =[self.attributedString buildCTLineRef:fastline withParagraph:textParagraph] ;
                NSInteger finalIndex = MIN(lineRange.location + lineRange.length, range.location + range.length);
                
                NSInteger lineindex=index-textParagraph.range.location;
                NSInteger linefinalIndex=finalIndex-textParagraph.range.location;
                CGFloat xStart =  [textParagraph lineGetGetOffsetForStringIndex:line fastTextLine:fastline charIndex:lineindex secondaryOffset:NULL];
                CGFloat xEnd =  [textParagraph lineGetGetOffsetForStringIndex:line fastTextLine:fastline charIndex:linefinalIndex secondaryOffset:NULL];
                CGPoint origin = origins[i];
                CGFloat ascent=fastline.ascent, descent=fastline.descent;
                
                CFRelease(line);
                
                returnRect = [_textContentView convertRect:CGRectMake(textParagraph.rect.origin.x+ origin.x + xStart, textParagraph.rect.origin.y+origin.y - descent, xEnd - xStart, ascent + (descent*2)) toView:self];
                break;
            }
        }
    }
    
    return returnRect;
}
// MARK: UITextInput - Evaluating Text Positions

- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other {
    CIndexedPosition *pos = (CIndexedPosition *)position;
    CIndexedPosition *o = (CIndexedPosition *)other;
    
    if (pos.index == o.index) {
        return NSOrderedSame;
    } if (pos.index < o.index) {
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
    }
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition {
    CIndexedPosition *f = (CIndexedPosition *)from;
    CIndexedPosition *t = (CIndexedPosition *)toPosition;
    return (t.index - f.index);
}

// MARK: UITextInput - Text Layout, writing direction and position

- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction {
    
    CIndexedRange *r = (CIndexedRange *)range;
    NSInteger pos = r.range.location;
    
    switch (direction) {
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            pos = r.range.location;
            break;
        case UITextLayoutDirectionRight:
        case UITextLayoutDirectionDown:
            pos = r.range.location + r.range.length;
            break;
    }
    
    return [CIndexedPosition positionWithIndex:pos];
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction {
    
    CIndexedPosition *pos = (CIndexedPosition *)position;
    NSRange result = NSMakeRange(pos.index, 1);
    
    switch (direction) {
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            result = NSMakeRange(pos.index - 1, 1);
            break;
        case UITextLayoutDirectionRight:
        case UITextLayoutDirectionDown:
            result = NSMakeRange(pos.index, 1);
            break;
    }
    
    return [CIndexedRange rangeWithNSRange:result];
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction {
    return UITextWritingDirectionLeftToRight;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range {
    // only ltr supported for now.
}
@end
