
#import <UIKit/UIKit.h>

@interface ChatTableViewCell : UITableViewCell
/// 判断是对方发送过来的消息还是自己发出的消息
@property (nonatomic, assign) BOOL isOut;
/// 接受消息内容
@property (nonatomic, strong) NSString *message;

@end
