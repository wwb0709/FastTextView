
#import "CTextConfig.h"
#import <CoreText/CoreText.h>
#define ARRSIZE(a)      (sizeof(a) / sizeof(a[0]))


static CAttributeConfig *editorAttributeConfig = nil;
static CAttributeConfig *readerAttributeConfig = nil;
static CAttributeConfig *readerTitleAttributeConfig = nil;

@implementation CTextConfig


+(CAttributeConfig *)editorAttributeConfig{

    @synchronized (self)
    {
        if (editorAttributeConfig == nil)
        {
            editorAttributeConfig= [[CAttributeConfig alloc] init];
            //TODO load from config
            
            editorAttributeConfig.attributes=[self defaultAttributes];
        }
    }
    return editorAttributeConfig;

}

+(CAttributeConfig *)readerAttributeConfig{

    @synchronized (self)
    {
        if (readerAttributeConfig == nil)
        {
            readerAttributeConfig= [[CAttributeConfig alloc] init];
            readerAttributeConfig.attributes=[self defaultReaderAttributes];
            //TODO load from config
        }
        
    }
    return readerAttributeConfig;
}


+(CAttributeConfig *)readerTitleAttributeConfig{
    
    @synchronized (self)
    {
        if (readerTitleAttributeConfig == nil)
        {
            readerTitleAttributeConfig= [[CAttributeConfig alloc] init];
            readerTitleAttributeConfig.attributes=[self defaultReaderTitleAttributes];
            //TODO load from config
        }
        
    }
    return readerTitleAttributeConfig;
}



+(NSDictionary *)defaultAttributes{

//    NSString *fontName =[[UIFont systemFontOfSize:17]fontName];//@"Hiragino Sans GB";
//    CGFloat fontSize= 17.0f;
//    UIColor *color = [UIColor blackColor];
//    UIColor *strokeColor = [UIColor whiteColor];
//    CGFloat strokeWidth = 0.0;
//    CGFloat paragraphSpacing = 20.0;
//    CGFloat paragraphSpacingBefore = 20.0;
//    CGFloat lineSpacing = 5.0;
//    CGFloat minimumLineHeight=0.0f;
//    
//    //CGFloat headIndent= 20.0;
//    
//    
//    
//        
//    
//    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName,
//                                             fontSize, NULL);
//    
//    CTParagraphStyleSetting settings[] = {
//        { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore },        
//        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing },
//        { kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing },
//        { kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(CGFloat), &minimumLineHeight },
//        //{ kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &headIndent },
//    };
//    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, ARRSIZE(settings));
//    
//    //apply the current text style //2
//   /* NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
//                           (id)color.CGColor, kCTForegroundColorAttributeName,
//                           (__bridge id)fontRef, kCTFontAttributeName,
//                           (id)strokeColor.CGColor, (NSString *) kCTStrokeColorAttributeName,
//                           (id)[NSNumber numberWithFloat: strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
//                           (__bridge id) paragraphStyle, (NSString *) kCTParagraphStyleAttributeName,
//                           nil];
//    */
//    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
//                           (id)color.CGColor, kCTForegroundColorAttributeName,
//                           (__bridge id)fontRef, kCTFontAttributeName,
//                           (id)strokeColor.CGColor, (NSString *) kCTStrokeColorAttributeName,
//                           (id)[NSNumber numberWithFloat: strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
//                           (__bridge id) paragraphStyle, (NSString *) kCTParagraphStyleAttributeName,
//                           nil];
//    
//    CFRelease(fontRef);
//    return attrs;
    
    
    CTTextAlignment alignment = kCTTextAlignmentNatural;
    
    CGFloat paragraphSpacing = 0.0;
    CGFloat paragraphSpacingBefore = 0.0;
    CGFloat firstLineHeadIndent = 0.0;
    CGFloat headIndent = 0.0;
    CGFloat LineSpace = 10;
    CGFloat lineHeight = 28;
    
    CTParagraphStyleSetting settings[] =
    {
        {kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &alignment},
        {kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineHeadIndent},
        {kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &headIndent},
        {kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing},
        {kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &LineSpace},
        {kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(CGFloat), &lineHeight},
        {kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(CGFloat), &lineHeight},
        {kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(CGFloat), &lineHeight},
        {kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore},
    };
    
    CTParagraphStyleRef style;
    style = CTParagraphStyleCreate(settings, sizeof(settings)/sizeof(CTParagraphStyleSetting));
    
    if (NULL == style) {
        // error...
        return nil;
    }
    
//    [_attrstring addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge NSObject*)style, (NSString*)kCTParagraphStyleAttributeName, nil]
//                         range:NSMakeRange(0, [_attrstring length])];
    
   
    
    
    UIFont *font =[UIFont fontWithName:@"Helvetica Neue" size:16.5];
    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
//    if (font) {
//        CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
//        [_attrstring addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge NSObject*)fontRef, (NSString*)kCTFontAttributeName, nil]
//                             range:NSMakeRange(0, [_attrstring length])];
//    }
    
    UIColor *color =CUIColorFromRGB(0x6e432f);
//    if (color) {
//        [_attrstring addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge NSObject*)color.CGColor,(NSString*)kCTForegroundColorAttributeName, nil]
//                             range:NSMakeRange(0, [_attrstring length])];
//    }
    
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (id)color.CGColor, kCTForegroundColorAttributeName,
                           (__bridge id)fontRef, kCTFontAttributeName,
                          
                           (__bridge id) style, (NSString *) kCTParagraphStyleAttributeName,
                           nil];
    CFRelease(fontRef);
    CFRelease(style);
    return attrs;
}


//modify by yangzongming
+(NSDictionary *)defaultReaderAttributes{
    return  [self defaultAttributes];
    
}

/*
+(NSDictionary *)defaultImageDescAttributes{
    
    NSString *fontName =[[UIFont systemFontOfSize:12]fontName];//@"Hiragino Sans GB";
    CGFloat fontSize= 12.0f;
    UIColor *color = [UIColor blackColor];
    UIColor *strokeColor = [UIColor whiteColor];
    CGFloat strokeWidth = 0.0;    
    
    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName,
                                             fontSize, NULL);  
    
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (id)color.CGColor, kCTForegroundColorAttributeName,
                           (__bridge id)fontRef, kCTFontAttributeName,
                           (id)strokeColor.CGColor, (NSString *) kCTStrokeColorAttributeName,
                           (id)[NSNumber numberWithFloat: strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
                           nil];
    
    CFRelease(fontRef);
    return attrs;
}
 */



+(NSDictionary *)defaultReaderTitleAttributes{
    return  [self defaultAttributes];
}




@end

