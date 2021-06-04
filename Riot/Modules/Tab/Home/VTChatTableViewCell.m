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

#import "VTChatTableViewCell.h"

@implementation VTChatTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		[self setupUI];
	}
	return self;
}

-(void)setupUI {
	[self setBackgroundColor:[UIColor whiteColor]];
	[self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
	         [obj removeFromSuperview];
	 }];

	self.timeLabel = [[QMUILabel alloc] init];
	[self addSubview:self.timeLabel];
	[self.timeLabel setFont:[UIFont systemFontOfSize:12]];
	self.timeLabel.textColor = [Common text99Color];
	self.timeLabel.hidden = YES;
	[self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(self.mas_top);
	         make.centerX.mas_equalTo(self.mas_centerX);
	 }];
	self.chatView = [[UIView alloc] init];
	[self.chatView setBackgroundColor:[Common F5Color]];
	[self addSubview:self.chatView];
	[self.chatView mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(self.mas_left).mas_offset(30);
	         make.bottom.mas_equalTo(self.mas_bottom);
	         make.top.mas_equalTo(self.timeLabel.mas_bottom);
	 }];
	self.chatLabel = [[QMUILabel alloc] init];
	[self.chatView addSubview:self.chatLabel];
	[self.chatLabel setFont:[UIFont systemFontOfSize:16]];
	self.chatLabel.textColor = [Common text33Color];
	[self.chatLabel mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(self.chatView.mas_left).mas_offset((8));
	         make.centerY.mas_equalTo(self.chatView.mas_centerY);
	 }];
	[self.chatView mas_updateConstraints:^(MASConstraintMaker *make) {
	         make.right.mas_equalTo(self.chatLabel.mas_right).mas_offset(8);
	 }];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
}

@end
