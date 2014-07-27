

#import <Foundation/Foundation.h>



@interface CAttributeConfig : NSObject{
    UIFont  *_font;
    NSDictionary *_attributes;
}

@property(nonatomic,strong) UIFont *font;
@property(nonatomic,strong) NSDictionary *attributes; 


-(void)setFontSize:(NSInteger)fontType;

-(void)setReadStyle:(NSInteger)readStyle;
@end
