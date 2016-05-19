

#import "RosterListTableViewController.h"
#import "XMPPManager.h"
#import "ChatTableViewController.h"
@interface RosterListTableViewController ()<XMPPStreamDelegate, XMPPRosterDelegate>

/// 存储好友列表的数组
@property (nonatomic, strong) NSMutableArray *allRosterArray;
/// 用来存储发送请求者的JID
@property (nonatomic, strong) XMPPJID *fromJid;
@end

@implementation RosterListTableViewController
// 懒加载
- (NSMutableArray *)allRosterArray
{
    if (!_allRosterArray) {
        _allRosterArray = [NSMutableArray array];
    }
    return _allRosterArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // 添加代理
    [[XMPPManager sharedXMPPManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedXMPPManager].xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    // 设置添加按钮和返回按钮
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFriendAction)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"注销" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction)];
    self.navigationItem.leftBarButtonItem = leftItem;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"RosterCell"];
    self.title = @"好友列表";
}

#pragma mark - 添加点击事件
- (void)addFriendAction
{
    [[XMPPManager sharedXMPPManager] addFriend];
    
}

#pragma mark - 返回点击事件
- (void)cancelAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.allRosterArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RosterCell" forIndexPath:indexPath];
    // 安全判断
    if (self.allRosterArray.count > 0) {
        // 获取用户
        XMPPJID *jid = [self.allRosterArray objectAtIndex:indexPath.row];
        cell.textLabel.text = jid.user;
        NSLog(@"bare == %@", jid.bare);
    }
    
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        // 处理要删除的数据
        // 要删除用户的JID
        XMPPJID *jid = [self.allRosterArray objectAtIndex:indexPath.row];
        [[XMPPManager sharedXMPPManager] removeFriendWithName:jid.user];
        [self.allRosterArray removeObjectAtIndex:indexPath.row];
        
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
#pragma mark - 点击cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatTableViewController *chatVC = [[ChatTableViewController alloc] init];

    chatVC.chatToJid = self.allRosterArray[indexPath.row];
    [self.navigationController pushViewController:chatVC animated:YES];
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - XMPPRosterDelegate代理方法
// 获取好友
- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender
{
    
}
// 结束获取好友
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender
{
    // 当前页面使用于显示好友列表的，所以在结束好友获取的代理方法中要进行刷新页面，然后将数据显示
    
    // 刷新页面
    [self.tableView reloadData];
}
// 接收好友信息
// 这个代理方法会被执行多次，每次添加完好友，相应的好友信息都要有反馈
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(DDXMLElement *)item
{
    /*
     好友状态有五种：
     both 互为好友
     none 互不为好友
     to 我已添加对方为好友，但是对方还没有接受
     from 对方已添加自己为好友，但是自己还没有接受
     remove 曾经删除的好友
     */
    // 描述自己和对方之间的关系
    NSString *description = [[item attributeForName:@"subscription"] stringValue];
    NSLog(@"description = %@", description);
    if ([description isEqualToString:@"none"] || [description isEqualToString:@"to"] || [description isEqualToString:@"both"] || [description isEqualToString:@"from"]) {
        // 添加好友
        // 获取添加好友的jid
        NSString *friendJid = [[item attributeForName:@"jid"] stringValue];
        XMPPJID *jid = [XMPPJID jidWithString:friendJid];
        // 如果数组中含有这个用户不用再进行接下来的操作
        if ([self.allRosterArray containsObject:jid]) {
            return;
        }
        // 添加好友到数组中
        [self.allRosterArray addObject:jid];
        // 在tableView中添加这条数据
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.allRosterArray.count - 1 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
// 是否接收好友发送的请求,接收/拒绝
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    self.fromJid = presence.from;
    // 需要相关的提醒框去确定是否接受
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"好友请求" message:@"是否接受好友请求" preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self)weakSelf = self;
    UIAlertAction *recpetAction = [UIAlertAction actionWithTitle:@"接受" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 在花名册中去接受相关的好友
        [[XMPPManager sharedXMPPManager].xmppRoster acceptPresenceSubscriptionRequestFrom:weakSelf.fromJid andAddToRoster:YES];
    }];
    UIAlertAction *rejectAction = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[XMPPManager sharedXMPPManager].xmppRoster rejectPresenceSubscriptionRequestFrom:weakSelf.fromJid];
    }];
    [alertController addAction:recpetAction];
    [alertController addAction:rejectAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - XMPPStreamDelegate代理方法
// 获取好友实时在线与否
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"status = %@", presence.status);
    
    NSString *type = presence.type;
    NSString *presenceOfUser = presence.to.user;
    // 判断当前要查看的用户，他是不是我的好友
    if ([presenceOfUser isEqualToString:[sender myJID].user]) {
        if ([type isEqualToString:@"available"]) {
            NSLog(@"该用户处于上线状态");
        } else if([type isEqualToString:@"unavailable"]){
            NSLog(@"该用户处于下线状态");
        }
    }
}










@end
