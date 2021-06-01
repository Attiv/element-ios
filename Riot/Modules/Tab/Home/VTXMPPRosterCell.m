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

#import <QMUIKit/QMUILabel.h>
#import <Masonry/View+MASAdditions.h>
#import <XMPPFramework/XMPPUserCoreDataStorageObject.h>
#import "VTXMPPRosterCell.h"
#import "PrefixHeader.pch"

@implementation VTXMPPRosterCell

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
	self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 0, 44, 44)];
	self.avatarImageView.layer.cornerRadius = 22;
	self.avatarImageView.layer.masksToBounds = YES;
	[self addSubview: self.avatarImageView];
	[self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(self.mas_left).mas_offset(16);
	         make.width.mas_equalTo(44);
	         make.height.mas_equalTo(self.avatarImageView.mas_width);
	         make.centerY.mas_equalTo(self.mas_centerY);
	 }];

	self.nameLabel = [[QMUILabel alloc] init];
	[self.nameLabel setFont:[UIFont systemFontOfSize:18]];
	[self.nameLabel setTextColor:[Common textBlack]];
	[self addSubview: self.nameLabel];
	[self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(self.avatarImageView.mas_right).mas_offset(16);
	         make.centerY.mas_equalTo(self.mas_centerY);
	 }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
}

- (void)setRosterWithRoster:(XMPPUserCoreDataStorageObject *)roster {
	self.avatarImageView.image = roster.photo;
	self.nameLabel.text = roster.displayName;
}


@end
