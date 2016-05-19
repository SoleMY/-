

#import <UIKit/UIKit.h>
#import "XMPPManager.h"
@interface ChatTableViewController : UITableViewController

/// 当前和谁进行聊天
@property (nonatomic, strong) XMPPJID *chatToJid;



@end
