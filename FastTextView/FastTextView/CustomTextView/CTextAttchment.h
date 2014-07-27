#import <Foundation/Foundation.h>
#import "CTextView.h"

@interface CTextAttchment : NSObject{

}
@property (assign, readwrite) CGRect cellRect;
@property (nonatomic, strong) id<CTextAttachmentCell> attachmentcell;

    
@end
