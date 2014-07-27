
#import <Foundation/Foundation.h>

@interface NSAttributedString (CTextUtil)

+ (NSAttributedString *)fromHtmlString:(NSString *)htmlstr withAttachmentPath:(NSString *)attachpath;



- (void)printDesc;

+ (NSMutableAttributedString *)scanAttachments:(NSMutableAttributedString *)_attributedString;

+ (NSString *)scanAttachmentsForNewFileName:(NSAttributedString *)_attributedString ;

+ (NSMutableAttributedString *)stripStyle:(NSAttributedString *) attrstring;

- (CGFloat)boundingHeightForWidth:(CGFloat)width;

@end
