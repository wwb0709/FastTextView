#import "CTextAttchment.h"

@implementation CTextAttchment
@synthesize cellRect,attachmentcell;

-(void)dealloc{
    self.attachmentcell=nil;
    
    NSLog(@"TextAttchment delloc");
}

@end
