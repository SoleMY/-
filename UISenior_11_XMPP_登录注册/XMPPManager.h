
#import <Foundation/Foundation.h>
#import "XMPPFramework.h"
@interface XMPPManager : NSObject

/// 声明一个通道的属性
@property (nonatomic, strong) XMPPStream *xmppStream;

+ (XMPPManager *)sharedXMPPManager;

/// 管理好友，好友的列表
@property (nonatomic, strong) XMPPRoster *xmppRoster;
/// 和聊天相关的属性
@property (nonatomic, strong) XMPPMessageArchiving *messageArchiving;
/// 管理上下文
@property (nonatomic, strong) NSManagedObjectContext *context;

// 登录的方法
- (void)loginWithUserName:(NSString *)userName
                 password:(NSString *)password;

// 注册的方法
- (void)registerWithUserName:(NSString *)userName
                    password:(NSString *)password;

// 添加好友
- (void)addFriend;

// 删除好友
- (void)removeFriendWithName:(NSString *)name;

@end
