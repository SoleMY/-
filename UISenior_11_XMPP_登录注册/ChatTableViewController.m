
#import "ChatTableViewController.h"
#import "ChatTableViewCell.h"
@interface ChatTableViewController ()<XMPPStreamDelegate>
@property (nonatomic, strong) NSMutableArray *allMessageArray;

@end

@implementation ChatTableViewController
- (NSMutableArray *)allMessageArray
{
    if (!_allMessageArray) {
        _allMessageArray = [NSMutableArray array];
    }
    return _allMessageArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // 注册cell
    [self.tableView registerClass:[ChatTableViewCell class] forCellReuseIdentifier:@"chatCell"];
    // 写两个按钮，一个按钮用于发送，一个按钮用于取消
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStylePlain target:self action:@selector(sendMessageAction)];
    self.navigationItem.rightBarButtonItem = rightItem;
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction)];
    self.navigationItem.leftBarButtonItem = leftItem;
    // 隐藏cell分割线
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    // 设置代理
    [[XMPPManager sharedXMPPManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    // 获取显示消息的方法
    [self showMessage];
    self.title = @"对话框";
}
#pragma mark - 发送方法
- (void)sendMessageAction
{
    // 设置Message的body
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.chatToJid];
    [message addBody:@"可以"];
    // 通过通道进行消息发送
    [[XMPPManager sharedXMPPManager].xmppStream sendElement:message];
    
}
#pragma mark - 取消方法
- (void)cancelAction
{
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - 显示消息
- (void)showMessage
{
    // 获取管理上下文
    NSManagedObjectContext *context = [XMPPManager sharedXMPPManager].context;
    // 初始化请求对象
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    // 获取实体
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject" inManagedObjectContext:context];
    // 设置查询请求的实体
    [request setEntity:entity];
    // 设置谓词查询(当前用户JID 对方用户的JID)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@ AND bareJidStr == %@",[XMPPManager sharedXMPPManager].xmppStream.myJID.bare, self.chatToJid.bare];
    [request setPredicate:predicate];
    // 按照时间顺序进行排列
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    [request setSortDescriptors:@[sort]];
    // 执行相关的操作
    NSArray *resultArray = [context executeFetchRequest:request error:nil];
    NSLog(@"%ld", resultArray.count);
    // 先清空消息数组，再添加消息
    [self.allMessageArray removeAllObjects];
    // 在进行添加context执行的结果数组
    [self.allMessageArray addObjectsFromArray:resultArray];
//    self.allMessageArray = resultArray.mutableCopy;
    NSLog(@"dasdsa == %@", self.allMessageArray);
    // 刷新UI
    [self.tableView reloadData];
    // 当前聊天记录跳到最后一行
    if (self.allMessageArray.count > 0) {
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:self.allMessageArray.count - 1 inSection:0];
        // 跳到最后一行
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
    }
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"%ld", self.allMessageArray.count);
    return self.allMessageArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chatCell" forIndexPath:indexPath];
    
    // 数组里存储的message对象是XMPPMessageArchiving_Message_CoreDataObject类型的
    XMPPMessageArchiving_Message_CoreDataObject *message = [self.allMessageArray objectAtIndex:indexPath.row];
    // 设置cell中的相关数据
    cell.isOut = message.isOutgoing;
    cell.message = message.body;
    NSLog(@"%@", cell);
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

#pragma mark - XMPPStreamDelegate的相关代理
// 发送消息成功
-(void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    // 重新显示
    [self showMessage];
}
// 接收消息成功
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    [self showMessage];
}
// 发送消息失败
- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

@end
