//
//  ViewController.m
//  FastTextView
//
//  Created by wangweibin on 14-2-13.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "ViewController.h"
#import "FastTextView.h"
#import "NSAttributedString+TextUtil.h"
#import "TextConfig.h"


#import "CTextView.h"
#define NAVBAR_HEIGHT 44.0f
#define TABBAR_HEIGHT 49.0f
#define STATUS_HEIGHT 20.0f

#define TOP_VIEW_HEIGHT 33.0f
#define TOP_VIEW_WIDTH 48.0f

#define ARRSIZE(a)      (sizeof(a) / sizeof(a[0]))

#define ios7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)

#define SHOWFASTVIEW 0
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    if(ios7){
        origin_y= NAVBAR_HEIGHT+STATUS_HEIGHT;
    }else{
        origin_y=0;
    }

    if (_fastTextView==nil) {
        
#if SHOWFASTVIEW
        FastTextView *view = [[FastTextView alloc] initWithFrame:CGRectMake(0, origin_y, self.view.bounds.size.width, self.view.bounds.size.height-origin_y)];
        
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.delegate = (id<FastTextViewDelegate>)self;
        view.attributeConfig=[TextConfig editorAttributeConfig];
        view.delegate = (id<FastTextViewDelegate>)self;
        view.placeHolder=@"章节内容";
        [view setFont:[UIFont systemFontOfSize:17]];
        view.pragraghSpaceHeight=15;
        view.backgroundColor = [UIColor blueColor];
        view.backgroundColor= [UIColor colorWithPatternImage:[UIImage imageNamed:@"note_paper_middle.png"]];
        
        [self.view addSubview:view];
        self.fastTextView = view;
        
        NSString *default_txt = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"a.txt"];
        // #endif
        
        NSError *error;
        NSString *base_content=[NSString stringWithContentsOfFile:default_txt encoding:NSUTF8StringEncoding error:&error];
        
        NSMutableAttributedString *parseStr=[[NSMutableAttributedString alloc]initWithString:base_content];
        [parseStr addAttributes:[self defaultAttributes] range:NSMakeRange(0, [parseStr length])];
        self.fastTextView.attributedString=parseStr;
        //[view becomeFirstResponder];
#else
        
        CTextView *view = [[CTextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
//        view.delegate = (id<CTextViewDelegate>)self;
        view.placeHolder=@"章节内容";
        [self.view addSubview:view];
        self.cTextView = view;
//        view.backgroundColor= [UIColor colorWithPatternImage:[UIImage imageNamed:@"note_paper_middle.png"]];
        
        NSString *default_txt = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"a.txt"];
        NSError *error;
        NSString *base_content=[NSString stringWithContentsOfFile:default_txt encoding:NSUTF8StringEncoding error:&error];
        CTextStorage *parseStr=[[CTextStorage alloc]initWithString:base_content];
        [parseStr addAttributes:[self defaultAttributes] range:NSMakeRange(0, [parseStr length])];
        self.cTextView.attributedString=parseStr;

#endif
        
        
        
        
        
        
        
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
-(NSDictionary *)defaultAttributes{
    
    NSString *fontName = @"Helvetica";
    CGFloat fontSize= 17.0f;
    UIColor *color = [UIColor blackColor];
    //UIColor *strokeColor = [UIColor whiteColor];
    //CGFloat strokeWidth = 0.0;
    CGFloat paragraphSpacing = 0.0;
    CGFloat lineSpacing = 0.0;
    //CGFloat minimumLineHeight=24.0f;
    
    
    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName,
                                             fontSize, NULL);
    
    CTParagraphStyleSetting settings[] = {
        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing },
        { kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing },
        // { kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(CGFloat), &minimumLineHeight },
    };
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, ARRSIZE(settings));
    
    //apply the current text style //2
    /* NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
     (id)color.CGColor, kCTForegroundColorAttributeName,
     (__bridge id)fontRef, kCTFontAttributeName,
     (id)strokeColor.CGColor, (NSString *) kCTStrokeColorAttributeName,
     (id)[NSNumber numberWithFloat: strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
     (__bridge id) paragraphStyle, (NSString *) kCTParagraphStyleAttributeName,
     nil];
     */
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (id)color.CGColor, kCTForegroundColorAttributeName,
                           (__bridge id)fontRef, kCTFontAttributeName,
                           //(id)strokeColor.CGColor, (NSString *) kCTStrokeColorAttributeName,
                           //                           (id)[NSNumber numberWithFloat: strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
                           //(__bridge id) paragraphStyle, (NSString *) kCTParagraphStyleAttributeName,
                           nil];
    
    CFRelease(fontRef);
    return attrs;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




- (void)keyboardWillShow:(NSNotification *)notification {
    
    NSDictionary* info = [notification userInfo];
    CGSize keyBoardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
#if SHOWFASTVIEW
    self.fastTextView.frame = CGRectMake(self.fastTextView.frame.origin.x, origin_y, self.fastTextView.frame.size.width,self.view.bounds.size.height -origin_y - keyBoardSize.height-TOP_VIEW_HEIGHT );
#else
    self.cTextView.frame = CGRectMake(self.cTextView.frame.origin.x, 0, self.cTextView.frame.size.width,self.view.bounds.size.height  - keyBoardSize.height );
    
#endif

    
    
}

- (void)keyboardWillHide:(NSNotification *)notification{
    
#if SHOWFASTVIEW
    self.fastTextView.frame = CGRectMake(self.fastTextView.frame.origin.x, origin_y, self.fastTextView.frame.size.width, self.view.bounds.size.height-origin_y);
#else
    self.cTextView.frame = CGRectMake(self.cTextView.frame.origin.x, 0, self.cTextView.frame.size.width,self.view.bounds.size.height );
#endif

    
}

@end
