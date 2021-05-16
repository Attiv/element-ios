// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "VTHomeCell.h"
#import "PrefixHeader.pch"

@implementation VTHomeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

-(void)setupUI {
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView *obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];

    UIImageView *avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(13, 8, 30, 30)];
    avatarImageView.image = [UIImage imageNamed:@"tab_people"];
    avatarImageView.layer.cornerRadius = 15;
    avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView = avatarImageView;
    [self addSubview:avatarImageView];
    [avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.mas_left).mas_offset(13);
        make.width.mas_equalTo(30);
        make.height.mas_equalTo(30);
        make.centerY.mas_equalTo(self.mas_centerY);
    }];

    UIView *statusView = [self statusView];
    self.statusView = statusView;
    [self addSubview:statusView];

    [statusView mas_makeConstraints:^(MASConstraintMaker *make) {
       make.width.mas_equalTo(10);
       make.height.mas_equalTo(10);
       make.left.mas_equalTo(avatarImageView.mas_right).mas_offset(-5);
       make.bottom.mas_equalTo(avatarImageView.mas_bottom).mas_offset(-2);
    }];

    QMUILabel *nameLabel = [[QMUILabel alloc] init];
    self.nameLabel = nameLabel;
    nameLabel.font = [UIFont systemFontOfSize:16];
    nameLabel.textColor = WRGBHex(0x373B40);
    [self addSubview:nameLabel];
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       make.left.mas_equalTo(avatarImageView.mas_right).mas_equalTo(10);
       make.centerY.mas_equalTo(self.mas_centerY);
    }];


}

-(UIView *)statusView {
    UIView *sView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    sView.layer.cornerRadius = 3;
    sView.layer.borderWidth = 1;
    sView.layer.borderColor = WRGBHex(0xEFF2F5).CGColor;
    return sView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
