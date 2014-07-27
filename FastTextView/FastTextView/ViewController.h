//
//  ViewController.h
//  FastTextView
//
//  Created by wangweibin on 14-2-13.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FastTextView;
@class CTextView;
@interface ViewController : UIViewController
{
    CGFloat origin_y;
}
@property(nonatomic,strong) FastTextView *fastTextView;
@property(nonatomic,strong) CTextView *cTextView;
@end
