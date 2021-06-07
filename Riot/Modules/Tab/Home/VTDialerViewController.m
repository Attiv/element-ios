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

#import "VTDialerViewController.h"
#import "PrefixHeader.pch"

@interface VTDialerViewController ()

@property(nonatomic, strong) JXCategoryTitleImageView *categoryView;

@end

@implementation VTDialerViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupUI];
	// Do any additional setup after loading the view.
}


-(void)setupUI {
	self.view.backgroundColor = [Common lightGray];
	UIView *topView = [[UIView alloc] init];
	topView.backgroundColor = [Common themeColor];
	[self.view addSubview:topView];
	[topView mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(self.view.mas_top);
	         make.left.mas_equalTo(self.view.mas_left);
	         make.right.mas_equalTo(self.view.mas_right);
	 }];

	QMUILabel *dialerLabel = [[QMUILabel alloc] init];
	dialerLabel.textColor = [UIColor whiteColor];
	dialerLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
	dialerLabel.text = kString(@"dialer");
	[topView addSubview:dialerLabel];
	[dialerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(topView.mas_top).mas_offset(14 + StatusBarHeight);
	         make.left.mas_equalTo(topView.mas_left).mas_offset(12);
	 }];

	QMUIButton *settingButton = [[QMUIButton alloc] init];
	[settingButton setImage:[UIImage imageNamed:@"tab_people"] forState:UIControlStateNormal];
	[settingButton addTarget:self action:@selector(settingButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	[topView addSubview:settingButton];
	[settingButton mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.width.mas_equalTo(22);
	         make.height.mas_equalTo(22);
	         make.right.mas_equalTo(topView.mas_right).mas_offset(-16);
	         make.centerY.mas_equalTo(dialerLabel.mas_centerY);
	 }];

	[self.view layoutIfNeeded];
	self.categoryView = [[JXCategoryTitleImageView alloc] initWithFrame:CGRectMake(0, 0, topView.w, 44)];
	self.categoryView.titles = @[kString(@"history"), kString(@"contact"), kString(@"messaging")];
	self.categoryView.imageNames = @[@"tab_people", @"tab_people", @"tab_people"];
	self.categoryView.titleColor = [UIColor lightGrayColor];
	self.categoryView.titleImageSpacing = 7;
	self.categoryView.titleSelectedColor = [UIColor whiteColor];
	[topView addSubview:self.categoryView];
	[self.categoryView mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(topView.mas_left);
	         make.right.mas_equalTo(topView.mas_right);
	         make.height.mas_equalTo(44);
	         make.top.mas_equalTo(dialerLabel.mas_bottom).mas_offset(18);
	 }];

	JXCategoryIndicatorLineView *lineView = [[JXCategoryIndicatorLineView alloc] init];
	lineView.indicatorColor = WRGBHex(0xD5C4FF);
	lineView.indicatorWidth = (topView.w / 3) * 0.56;
	lineView.indicatorHeight = 3;
	self.categoryView.indicators = @[lineView];

	[topView mas_updateConstraints:^(MASConstraintMaker *make) {
	         make.bottom.mas_equalTo(self.categoryView.mas_bottom).mas_offset(1);
	 }];
	[topView.superview layoutIfNeeded];

}

-(void)settingButtonClicked {

}

/*
 #pragma mark - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
   }
 */

@end
