

#import "RegistViewController.h"
#import "XMPPManager.h"
@interface RegistViewController ()<XMPPStreamDelegate>

/// 注册用户名
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
/// 注册密码
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation RegistViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[XMPPManager sharedXMPPManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    self.title = @"注册页面";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
// 注册按钮的响应方法
- (IBAction)registerAction:(id)sender {
    [[XMPPManager sharedXMPPManager] registerWithUserName:self.userNameTextField.text password:self.passwordTextField.text];
}

#pragma mark - 实现XMPPStreamDelegate协议方法
// 实现协议是为了满足需求：注册成功之后跳转（dismiss）回页面
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    NSLog(@"注册成功");
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error
{
    NSLog(@"注册失败：error = %@", error);
}

@end
