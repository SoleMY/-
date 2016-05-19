
#import "LoginViewController.h"
#import "XMPPManager.h"
#import "RosterListTableViewController.h"
@interface LoginViewController ()<XMPPStreamDelegate>
/// 用户名
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
/// 密码
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[XMPPManager sharedXMPPManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    self.title = @"登录";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
#pragma mark - 登录按钮的响应方法
- (IBAction)loginAction:(id)sender {
    [[XMPPManager sharedXMPPManager] loginWithUserName:self.userNameTextField.text password:self.passwordTextField.text];

}
// 登录成功跳转页面
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"登录成功");
    RosterListTableViewController *rosterVC = [[RosterListTableViewController alloc] init];
    [self.navigationController pushViewController:rosterVC animated:YES];
}

-(void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    NSLog(@"登录失败");
}



@end
