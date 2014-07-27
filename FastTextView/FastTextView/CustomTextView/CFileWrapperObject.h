
#import <Foundation/Foundation.h>

@interface CFileWrapperObject : NSObject{
    NSString *filePath;
    NSString *fileName;
}

@property (nonatomic,strong)NSString *filePath;
@property (nonatomic,strong)NSString *fileName;

@end
