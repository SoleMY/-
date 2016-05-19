

#import "ChatTableViewCell.h"

@interface ChatTableViewCell ()

@property(nonatomic,strong)UIImageView * headerImageView;
@property(nonatomic,strong)UIImageView * backgroundImageView;
///显示每一条聊天内容
@property(nonatomic,strong)UILabel * contentLabel;

@end

@implementation ChatTableViewCell
//使用懒加载创建并初始化所有UI控件
- (UILabel *)contentLabel{
    if (_contentLabel == nil) {
        _contentLabel = [[UILabel alloc] init];
    }
    return _contentLabel;
}
- (UIImageView *)backgroundImageView
{
    if (_backgroundImageView == nil) {
        _backgroundImageView = [[UIImageView alloc] init];
    }
    return _backgroundImageView;
}
- (UIImageView *)headerImageView
{
    if (_headerImageView == nil) {
        _headerImageView = [[UIImageView alloc] init];
    }
    return _headerImageView;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        //设置cell不能选中
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.backgroundImageView];
        [self.contentView addSubview:self.headerImageView];
        [self.backgroundImageView addSubview:self.contentLabel];
        
    }
    return self;
}


//重写isOut的setter方法，来设定cell上的不同布局
- (void)setIsOut:(BOOL)isOut
{
    _isOut = isOut;
    CGRect rect = self.frame;
    if (_isOut) {
        self.headerImageView.frame = CGRectMake(rect.size.width-50, 10, 50, 50);
        self.headerImageView.image = [UIImage imageNamed:@"xiaoming"];
    }else{
        self.headerImageView.frame = CGRectMake(0, 10, 50, 50);
        self.headerImageView.image = [UIImage imageNamed:@"angel"];
    }
}
//重写message方法，在cell上显示聊天记录
- (void)setMessage:(NSString *)message
{
    if (_message != message) {
        _message = message;
        self.contentLabel.text = _message;
        //        self.contentLabel.numberOfLines = 0;
        [self.contentLabel sizeToFit];
        
        CGRect rect = self.frame;
        if (self.isOut) {//发出去的
            self.backgroundImageView.image = [[UIImage imageNamed:@"chat_to"] stretchableImageWithLeftCapWidth:45 topCapHeight:40];
            self.backgroundImageView.frame = CGRectMake(rect.size.width - self.contentLabel.frame.size.width - 50-20, 10, self.contentLabel.frame.size.width+20, rect.size.height-20);
        }else{//接收的
            self.backgroundImageView.image = [[UIImage imageNamed:@"chat_from"] stretchableImageWithLeftCapWidth:45 topCapHeight:40];
            self.backgroundImageView.frame = CGRectMake(50, 10,self.contentLabel.frame.size.width+40, rect.size.height-20);
        }
        //因为contentLabel已经自适应文字大小，故不用设置宽高，但需要设置位置
        self.contentLabel.center = CGPointMake(self.backgroundImageView.frame.size.width/2.0, self.backgroundImageView.frame.size.height/2.0);
        
    }
}

@end
