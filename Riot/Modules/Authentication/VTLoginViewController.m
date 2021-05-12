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


#import "VTLoginViewController.h"
#import "AuthFallBackViewController.h"
#import "Riot-Swift.h"
#import "MXSession+Riot.h"
#import "Common.h"
#import <QMUIKit/QMUIKit.h>
#import <YYText/YYText.h>


@interface VTLoginViewController () <AuthFallBackViewControllerDelegate, KeyVerificationCoordinatorBridgePresenterDelegate, SetPinCoordinatorBridgePresenterDelegate, SocialLoginListViewDelegate, SSOAuthenticationPresenterDelegate
        > {
    /**
     The default country code used to initialize the mobile phone number input.
     */
    NSString *defaultCountryCode;

    /**
     Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
     */
    id kThemeServiceDidChangeThemeNotificationObserver;

    /**
     Observe AppDelegateUniversalLinkDidChangeNotification to handle universal link changes.
     */
    id universalLinkDidChangeNotificationObserver;

    /**
     Server discovery.
     */
    MXAutoDiscovery *autoDiscovery;

    AuthFallBackViewController *authFallBackViewController;

    // successful login credentials
    MXCredentials *loginCredentials;

    // Check false display of this screen only once
    BOOL didCheckFalseAuthScreenDisplay;
}

@end

@implementation VTLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.defaultHomeServerUrl = RiotSettings.shared.homeserverUrlString;

    self.defaultIdentityServerUrl = RiotSettings.shared.identityServerUrlString;
}

- (void)finalizeInit {
    [super finalizeInit];
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    defaultCountryCode = @"GB";
    didCheckFalseAuthScreenDisplay = NO;
}

- (void)setupUI {
    [self.view setBackgroundColor:[UIColor colorWithRed:25 green:12 blue:55 alpha:1]];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nodefy-logo"]];
    [scrollView addSubview:logoView];
    [logoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(scrollView.mas_centerX);
        make.top.mas_equalTo(scrollView.mas_top).mas_offset(80);
        make.width.mas_equalTo(123);
        make.height.mas_equalTo(104);
    }];

    UIView *mainView = [[UIView alloc] init];
    [scrollView addSubview:mainView];
    [mainView setBackgroundColor:[UIColor whiteColor]];

    [mainView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(logoView.mas_bottom).mas_offset(25);
        make.left.mas_equalTo(self.view.mas_left).mas_offset(16);
        make.right.mas_equalTo(self.view.mas_right).mas_offset(-16);
    }];

    UILabel *topLabel = [[UILabel alloc] init];
    topLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    topLabel.text = @"Sign in";
    topLabel.textColor = [Common text33Color];
    [mainView addSubview:topLabel];
    [topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(mainView.mas_top).mas_offset(20);
        make.left.mas_equalTo(mainView.mas_left).mas_offset(20);
    }];

    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14], NSForegroundColorAttributeName: [Common text33Color]};
    NSMutableAttributedString *tipString = [[NSMutableAttributedString alloc] initWithString:@"Sign in to your Matrix account on matrix-client.matrix.org Change" attributes:attributes];
    [tipString yy_setTextHighlightRange:[[tipString string] rangeOfString:@"Change"] color:[Common textLightBlueColor] backgroundColor:[UIColor clearColor] tapAction:^(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect) {
        WLog(@"Change Clicked");
    }];
    YYLabel *tipLabel = [[YYLabel alloc] init];
    tipLabel.attributedText = tipString;
    tipLabel.textAlignment = NSTextAlignmentLeft;
    tipLabel.numberOfLines = 0;
    [mainView addSubview:tipLabel];

    [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(topLabel.mas_left);
        make.top.mas_equalTo(topLabel.mas_bottom).mas_offset(17);
        make.right.mas_equalTo(mainView.mas_right).mas_offset(-60);
    }];

    JRDropDown *signInWith = [[JRDropDown alloc] init];
    signInWith.optionArray = @[@"Username", @"1", @"2"];
    signInWith.optionIds = @[@1, @2, @3];
    [signInWith didSelectWithCompletion:^(NSString *selectedText, NSInteger index, NSInteger id) {
        WLog(@"%@", selectedText);
    }];
    [mainView addSubview:signInWith];
    [signInWith mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(mainView.mas_right).mas_offset(-16);
        make.top.mas_equalTo(tipLabel.mas_bottom).mas_offset(18);
        make.width.mas_equalTo(160);
        make.height.mas_equalTo(36);
    }];

    UILabel *signInLabel = [[UILabel alloc] init];
    signInLabel.text = @"Sign in with";
    signInLabel.textColor = [Common text66Color];
    signInLabel.font = [UIFont systemFontOfSize:16.0];
    [mainView addSubview:signInLabel];
    [signInLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(signInWith.mas_centerY);
        make.left.mas_equalTo(tipLabel.mas_left);
    }];

    QMUITextField *userNameField = [[QMUITextField alloc] init];
    userNameField.placeholder = @"Username";
    userNameField.qmui_borderLayer.cornerRadius = 3;
    userNameField.qmui_borderLayer.masksToBounds = YES;
    userNameField.qmui_borderWidth = 1;
    userNameField.qmui_borderColor = [Common fieldBorderColor];
    [mainView addSubview:userNameField];

    [userNameField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(signInWith.mas_bottom).mas_offset(16);
        make.left.mas_equalTo(signInLabel.mas_left);
        make.right.mas_equalTo(signInWith.mas_right);
        make.height.mas_equalTo(40);
    }];

    QMUITextField *passwordField = [[QMUITextField alloc] init];
    passwordField.placeholder = @"Password";
    passwordField.qmui_borderLayer.cornerRadius = 3;
    passwordField.qmui_borderLayer.masksToBounds = YES;
    passwordField.qmui_borderWidth = 1;
    passwordField.qmui_borderColor = [Common fieldBorderColor];
    [mainView addSubview:passwordField];

    [passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(userNameField.mas_left);
        make.right.mas_equalTo(userNameField.mas_right);
        make.height.mas_equalTo(userNameField.mas_height);
        make.top.mas_equalTo(userNameField.mas_bottom).mas_offset(16);
    }];

    NSDictionary *newOneDict = @{NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: [Common text99Color]};
    NSMutableAttributedString *newOneString = [[NSMutableAttributedString alloc] initWithString:@"Not sure of your password ? Set a new one" attributes:newOneDict];
    [tipString yy_setTextHighlightRange:[[tipString string] rangeOfString:@"Set a new one"] color:[Common textLightBlueColor] backgroundColor:[UIColor clearColor] tapAction:^(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect) {
        WLog(@"Set a new one Clicked");
    }];
    YYLabel *newOnLabel = [[YYLabel alloc] init];
    newOnLabel.attributedText = tipString;
    newOnLabel.textAlignment = NSTextAlignmentLeft;
    newOnLabel.numberOfLines = 0;
    [mainView addSubview:newOnLabel];

    [newOnLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(passwordField.mas_bottom).mas_offset(10);
        make.left.mas_equalTo(passwordField.mas_left);
    }];

    //渐变颜色
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors     = @[(__bridge id) WRGBHex(0x00FAC4).CGColor, (__bridge id) WRGBHex(0x00D1FF).CGColor];
    gradientLayer.locations  = @[@0.1, @1.0];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint   = CGPointMake(1.0, 0);
    gradientLayer.frame      = CGRectMake(0, 0,  308, 40);
    gradientLayer.cornerRadius = 3;

    QMUIButton *signInButton = [[QMUIButton alloc] init];
    [signInButton.layer addSublayer:gradientLayer];

    [signInButton setTitleColor:[UIColor whiteColor] forState:<#(UIControlState)state#>];


}

@end
