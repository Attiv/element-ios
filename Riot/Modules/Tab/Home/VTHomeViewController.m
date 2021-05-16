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


#import "VTHomeViewController.h"
#import "PrefixHeader.pch"
#import "VTHomeCell.h"

const static NSString * kHomeCellIdentifier = @"home_cll";

@interface VTHomeViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) QMUITableView *tableView;
@end

@implementation VTHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    // Do any additional setup after loading the view.
}

-(void)setupUI {
    self.view.backgroundColor = WRGBHex(0xF2F0F7);

    UIView *topView = [[UIView alloc] init];
    topView.backgroundColor = WRGBHex(0x29194F);
    [self.view addSubview:topView];
    [topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view.mas_top);
        make.left.mas_equalTo(self.view.mas_left);
        make.right.mas_equalTo(self.view.mas_right);
    }];

    UIImage *avatarImg = [UIImage imageNamed:@"tab_people"];
    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:avatarImg];
    avatarImageView.layer.cornerRadius = 22;
    avatarImageView.layer.masksToBounds = YES;
    [topView addSubview:avatarImageView];

    [avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(topView.mas_top).mas_offset(16 + StatusBarHeight);
        make.left.mas_equalTo(topView.mas_left).mas_offset(16);
        make.width.mas_equalTo(44);
        make.height.mas_equalTo(44);
    }];

    UIView *myStatusView = [self statusView];
    myStatusView.backgroundColor = [Common onlineColor];
    [topView addSubview:myStatusView];
    [myStatusView mas_makeConstraints:^(MASConstraintMaker *make) {
       make.centerY.mas_equalTo(avatarImageView.mas_bottom).mas_offset(-8);
       make.right.mas_equalTo(avatarImageView.mas_right);
       make.width.mas_equalTo(12);
       make.height.mas_equalTo(12);
    }];

    QMUILabel *nameLabel = [[QMUILabel alloc] init];
    nameLabel.font = [UIFont systemFontOfSize:18];
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.text = @"Emily Lim";
    [topView addSubview:nameLabel];
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       make.bottom.mas_equalTo(avatarImageView.mas_centerY).mas_offset(-1);
       make.left.mas_equalTo(avatarImageView.mas_right).mas_offset(16);
    }];

    QMUILabel *accountLabel = [[QMUILabel alloc] init];
    accountLabel.font = [UIFont systemFontOfSize:12];
    accountLabel.textColor = WRGBHexAlpha(0xFFFFFF, 0.75);
    accountLabel.text = @"nodefy.me";
    [topView addSubview:accountLabel];
    [accountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(avatarImageView.mas_centerY).mas_offset(1);
        make.left.mas_equalTo(nameLabel.mas_left);
    }];

    QMUIButton *rightSearchButton = [[QMUIButton alloc] qmui_initWithImage:[UIImage imageNamed:@"tab_people"] title:@""];
    rightSearchButton.layer.cornerRadius = 3;
    rightSearchButton.layer.masksToBounds = YES;
    [rightSearchButton setBackgroundColor:[Common lightGray]];
    [topView addSubview:rightSearchButton];
    [rightSearchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(avatarImageView.mas_bottom).mas_offset(16);
       make.right.mas_equalTo(topView.mas_right).mas_offset(-16);
       make.width.mas_equalTo(30);
       make.height.mas_equalTo(30);
    }];

    QMUISearchBar *searchBar = [[QMUISearchBar alloc]init];
    searchBar.layer.cornerRadius = 3;
    searchBar.layer.masksToBounds = YES;
    searchBar.backgroundColor = [Common lightGray];
    searchBar.placeholder = @"Search";
    [topView addSubview:searchBar];
    [searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(topView.mas_left).mas_offset(12);
        make.centerY.mas_equalTo(rightSearchButton.mas_centerY);
        make.right.mas_equalTo(rightSearchButton.mas_left).mas_offset(-10);
        make.height.mas_equalTo(30);
    }];

    [topView mas_updateConstraints:^(MASConstraintMaker *make) {
       make.bottom.mas_equalTo(searchBar.mas_bottom).mas_offset(16);
    }];

    UIView *pubicView = [[UIView alloc] init];
    pubicView.backgroundColor = [Common lightGray];
    [self.view addSubview:pubicView];
    [pubicView mas_makeConstraints:^(MASConstraintMaker *make) {
       make.top.mas_equalTo(topView.mas_bottom);
       make.height.mas_equalTo(53);
       make.left.mas_equalTo(self.view.mas_left);
       make.right.mas_equalTo(self.view.mas_right);
    }];

    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
       make.top.mas_equalTo(pubicView.mas_bottom);
       make.left.mas_equalTo(self.view.mas_left);
       make.right.mas_equalTo(self.view.mas_right);
       make.bottom.mas_equalTo(self.view.mas_bottom);
    }];
}

-(UIView *)statusView {
    UIView *sView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
    sView.layer.cornerRadius = 3;
    sView.layer.borderWidth = 1;
    sView.layer.borderColor = WRGBHex(0xEFF2F5).CGColor;
    return sView;
}

#pragma mark - lazyload

- (QMUITableView *)tableView {
    if (nil == _tableView) {
        _tableView = [[QMUITableView alloc] initWithFrame:CGRectMake(0, 0, kScreenW, kScreenH) style:UITableViewStylePlain];
        [_tableView registerClass:[VTHomeCell class] forCellReuseIdentifier:kHomeCellIdentifier];
    }
    return _tableView;
}

#pragma mark - tableView delegate


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.w, 54)];
    QMUILabel *titleLabel = [[QMUILabel alloc] initWithFrame:CGRectMake(60, 19, 100, 18)];
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    titleLabel.text = @"GROUP";
    titleLabel.textColor = WRGBHex(0x46494D);
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VTHomeCell *cell = [tableView dequeueReusableCellWithIdentifier:kHomeCellIdentifier forIndexPath:indexPath];
    if (nil == cell) {
        cell = [[VTHomeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kHomeCellIdentifier];
    }
    cell.statusView.backgroundColor = [Common onlineColor];
    cell.nameLabel.text = @"Lyle";
    return cell;
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
