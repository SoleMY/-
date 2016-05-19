
#import "XMPPManager.h"


static XMPPManager *manager = nil;

// 记录状态
typedef NS_ENUM(NSUInteger, ConnectToServerPurpose) {
    ConnectToServerPurposeLogin,
    ConnectToServerPurposeRegister,
};

@interface XMPPManager ()<XMPPStreamDelegate, XMPPRosterDelegate>
/// 记录当前状态（登录/注册）
@property (nonatomic) ConnectToServerPurpose connectToServer;
/// 用户名
@property (nonatomic, strong) NSString *userName;
/// 密码
@property (nonatomic, strong) NSString *password;
/// 注册的用户名
@property (nonatomic, strong) NSString *registerUserName;
/// 注册的密码
@property (nonatomic, strong) NSString *registerPassword;
/// 接收添加好友的名字
@property (nonatomic, strong) UITextField *textField;
@end

@implementation XMPPManager

+ (XMPPManager *)sharedXMPPManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[XMPPManager alloc] init];
        
    });
    return manager;
}

#pragma mark - 1.创建通道
- (instancetype)init
{
    self = [super init];
    if (self) {
        // 初始化通道
        self.xmppStream = [[XMPPStream alloc] init];
        // openfire服务器IP地址
        self.xmppStream.hostName = kHostName;
        // openfire服务器端口 默认5222
        self.xmppStream.hostPort = kHostPort;
        // 添加代理
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
#pragma mark - 管理好友
        // 获取管理好友的单例对象
        XMPPRosterCoreDataStorage *rosterStorage = [XMPPRosterCoreDataStorage sharedInstance];
        // 给roster属性进行初始化
        self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:rosterStorage dispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
        // 将好友列表在通道中激活
        [self.xmppRoster activate:self.xmppStream];
        // 设置花名册代理
        [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
#pragma mark - 管理消息
        // 获取管理消息的存储对象
        XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
        // 进行消息管理器的初始化
        self.messageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:storage dispatchQueue:dispatch_get_main_queue()];
        
        // 在通道中设置相关的消息
        [self.messageArchiving activate:self.xmppStream];
        // 设置代理
        [self.messageArchiving addDelegate:self delegateQueue:dispatch_get_main_queue()];
        // 设置管理上下文
        self.context = storage.mainThreadManagedObjectContext;
        
    }
    return self;
}


#pragma mark - 登录的方法
- (void)loginWithUserName:(NSString *)userName password:(NSString *)password
{
    self.userName = userName;
    self.password = password;
    // 记录登录状态
    self.connectToServer = ConnectToServerPurposeLogin;
    // 连接服务器
    [self linkServer];
}
#pragma mark - 注册的方法
- (void)registerWithUserName:(NSString *)userName password:(NSString *)password
{
    self.registerUserName = userName;
    self.registerPassword = password;
    // 记录注册状态
    self.connectToServer = ConnectToServerPurposeRegister;
    // 连接服务器
    [self linkServer];
    
    
}
#pragma mark - 连接服务器
- (void)linkServer
{
    NSString *string = [[NSString alloc] init];
    switch (self.connectToServer) {
        case ConnectToServerPurposeLogin:
            string = [NSString stringWithFormat:@"%@", self.userName];
            break;
        case ConnectToServerPurposeRegister:
            string = [NSString stringWithFormat:@"%@", self.registerUserName];
            break;
        default:
            break;
    }
    // 要连接服务器，要有用户身份认证
    // 身份证
    // 第一个参数：用户名
    // 第二个参数：域名
    // 第三个参数：资源
    XMPPJID *jid = [XMPPJID jidWithUser:string domain:kDomin resource:kResource];
    // 通过通道进行身份验证
    self.xmppStream.myJID = jid;
    
    // 如果当前聊天工具处于连接状态或者已经连接，此时，需要切断连接（此逻辑不唯一，根据需求而定）
    if ([self.xmppStream isConnected] || [self.xmppStream isConnecting]) {
        // 切断连接
        [self disConnectedToServer];
    }
    // 设置连接超时
    NSError *error = nil;
    [self.xmppStream connectWithTimeout:30 error:&error];
    if (error) {
        NSLog(@"服务器连接超时");
    }
}
#pragma mark - 断开连接
- (void)disConnectedToServer
{
    // 当前用户下线了
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    // 告诉通道下线了
    [self.xmppStream sendElement:presence];
    // 使通道失去连接
    [self.xmppStream disconnect];
   
}

#pragma mark - XMPPStreamDelegate协议方法
// 连接超时
- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender
{
    NSLog(@"连接超时");
}

// 连接成功
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSLog(@"连接成功");
    // 登录密码的验证
//    [self.xmppStream authenticateWithPassword:self.password error:nil];
    // 区分登录和注册进行密码验证
    switch (self.connectToServer) {
        case ConnectToServerPurposeLogin:
            [self.xmppStream authenticateWithPassword:self.password error:nil];
            break;
        case ConnectToServerPurposeRegister:
            [self.xmppStream registerWithPassword:self.registerPassword error:nil];
            break;
        default:
            break;
    }

}
// 断开连接
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    // 自己手动断开
    // 被动断开
    if (error) {
        NSLog(@"断开连接，erroe = @%@", error);
    }
}
// 认证失败
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    NSLog(@"认证失败：error = %@", error);
}
// 认证成功
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    // 上线
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"available"];
    [self.xmppStream sendElement:presence];
    NSLog(@"认证成功");
    
}

#pragma mark - 添加好友
- (void)addFriend
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"添加好友" message:@"请输入添加好友的名字" preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self)weakSelf = self;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        weakSelf.textField = textField;
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"取消添加好友");
    }];
    UIAlertAction *ensureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 使用JID记录
        XMPPJID *friendJid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@", weakSelf.textField.text, kDomin]];
        // 监听好友的动作
        [weakSelf.xmppRoster subscribePresenceToUser:friendJid];
        // 添加好友
        [weakSelf.xmppRoster addUser:friendJid withNickname:weakSelf.textField.text];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:ensureAction];
    
    [[self getCurrentVC] presentViewController:alertController animated:YES completion:nil];
    
}

#pragma mark - 获取当前屏幕显示的viewcontroller
- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}

#pragma mark - 删除好友
- (void)removeFriendWithName:(NSString *)name
{
    // 使用JID记录要删除的用户
    XMPPJID *friendJid = [XMPPJID jidWithUser:name domain:kDomin resource:kResource];
    // 停止监听好友
    [self.xmppRoster unsubscribePresenceFromUser:friendJid];
    // 删除好友
    [self.xmppRoster removeUser:friendJid];
}

#pragma mark - XMPPRosterDelegate代理方法
// 开始获取好友
- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender
{
    NSLog(@"开始获取好友");
}
// 结束获取好友
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender
{
    NSLog(@"结束获取好友");
}
// 接收好友的信息
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(DDXMLElement *)item
{
    // 好友状态的显示信息
    NSLog(@"好友信息 ==== %@", item);
}
// 监听方法
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    NSLog(@"获取好友请求");
}








@end
