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
#import "VTMainTabBarController.h"
#import <QMUIKit/QMUIKit.h>
#import <YYText/YYText.h>
#import <Masonry/View+MASAdditions.h>


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

    [self setupUI];
}

- (void)finalizeInit {
    [super finalizeInit];
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    defaultCountryCode = @"EN";
    didCheckFalseAuthScreenDisplay = NO;
}

- (void)setupUI {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenW, kScreenH)];
    self.view = view;
    self.view.backgroundColor = WRGBHex(0x190C37);
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
    mainView.layer.cornerRadius = 5;
    mainView.layer.masksToBounds = YES;
    mainView.layer.borderWidth = 1;
    mainView.layer.borderColor = [Common fieldBorderColor].CGColor;

    [mainView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(logoView.mas_bottom).mas_offset(25);
        make.left.mas_equalTo(self.view.mas_left).mas_offset(16);
        make.right.mas_equalTo(self.view.mas_right).mas_offset(-16);
    }];

    UILabel *topLabel = [[UILabel alloc] init];
    topLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    topLabel.text = NSLocalizedStringFromTable(@"auth_softlogout_sign_in", @"Vector", nil);
    topLabel.textColor = [Common text33Color];
    [mainView addSubview:topLabel];
    [topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(mainView.mas_top).mas_offset(20);
        make.left.mas_equalTo(mainView.mas_left).mas_offset(20);
    }];
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14], NSForegroundColorAttributeName: [Common text33Color]};
    NSMutableAttributedString *tipString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", kString(@"sign_in_to_your_Matrix_account_on_matrix_client_matrix_org"), kString(@"change")] attributes:attributes];
    [tipString yy_setTextHighlightRange:[[tipString string] rangeOfString:kString(@"change")] color:[Common textLightBlueColor] backgroundColor:[UIColor clearColor] tapAction:^(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect) {
        WLog(@"Change Clicked");
    }];
    YYLabel *tipLabel = [[YYLabel alloc] init];
    tipLabel.attributedText = tipString;
    tipLabel.textAlignment = NSTextAlignmentLeft;
    tipLabel.numberOfLines = 0;
    tipLabel.preferredMaxLayoutWidth = kScreenW - 60 - 20 - 16 - 16;
    [mainView addSubview:tipLabel];
    
    [mainView.superview layoutIfNeeded];

    [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(topLabel.mas_left);
        make.top.mas_equalTo(topLabel.mas_bottom).mas_offset(17);
    }];
    
    [tipLabel.superview layoutIfNeeded];

    JRDropDown *signInWith = [[JRDropDown alloc] initWithFrame:CGRectMake(mainView.centerX, tipLabel.y + tipLabel.h + 18, 160, 36)];
    signInWith.layer.cornerRadius = 3;
    signInWith.layer.masksToBounds = YES;
    signInWith.isSearchEnable = false;
    signInWith.selectedRowColor = [UIColor lightGrayColor];
    signInWith.layer.borderWidth = 1;
    signInWith.layer.borderColor = [Common fieldBorderColor].CGColor;
    signInWith.optionArray = @[kString(@"auth_user_name_placeholder"), kString(@"email_address"), kString(@"phone")];
    signInWith.optionIds = @[@1, @2, @3];
    signInWith.selectedIndex = 0;
    signInWith.text = signInWith.optionArray[0];
    [signInWith didSelectWithCompletion:^(NSString *selectedText, NSInteger index, NSInteger id) {
        WLog(@"%zd", index);
    }];
    [mainView addSubview:signInWith];
    [signInWith mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(mainView.mas_right).mas_offset(-20);
        make.top.mas_equalTo(tipLabel.mas_bottom).mas_offset(18);
        make.width.mas_equalTo(160);
        make.height.mas_equalTo(36);
    }];
    
//    [signInWith.superview layoutIfNeeded];
//    signInWith.rightView.x = signInWith.rightView.x - 20;

    UILabel *signInLabel = [[UILabel alloc] init];
    signInLabel.text = kString(@"sign_in_with");
    signInLabel.textColor = [Common text66Color];
    signInLabel.font = [UIFont systemFontOfSize:16.0];
    [mainView addSubview:signInLabel];
    [signInLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(signInWith.mas_centerY);
        make.left.mas_equalTo(tipLabel.mas_left);
    }];

    QMUITextField *userNameField = [[QMUITextField alloc] init];
    userNameField.textInsets = UIEdgeInsetsMake(0, 8, 0, 0);
    userNameField.placeholder = kString(@"auth_user_name_placeholder");
    userNameField.layer.cornerRadius = 3;
    userNameField.layer.masksToBounds = YES;
    userNameField.layer.borderWidth = 1;
    userNameField.layer.borderColor = [Common fieldBorderColor].CGColor;
    [mainView addSubview:userNameField];

    [userNameField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(signInWith.mas_bottom).mas_offset(16);
        make.left.mas_equalTo(mainView.mas_left).mas_offset(20);
        make.right.mas_equalTo(mainView.mas_right).mas_offset(-20);
        make.height.mas_equalTo(40);
    }];

    QMUITextField *passwordField = [[QMUITextField alloc] init];
    passwordField.textInsets = UIEdgeInsetsMake(0, 8, 0, 0);
    passwordField.placeholder = kString(@"password");
    passwordField.layer.cornerRadius = 3;
    passwordField.layer.masksToBounds = YES;
    passwordField.layer.borderWidth = 1;
    passwordField.layer.borderColor = [Common fieldBorderColor].CGColor;
    [mainView addSubview:passwordField];

    [passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(userNameField.mas_left);
        make.right.mas_equalTo(userNameField.mas_right);
        make.height.mas_equalTo(userNameField.mas_height);
        make.top.mas_equalTo(userNameField.mas_bottom).mas_offset(16);
    }];

    NSDictionary *newOneDict = @{NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: [Common text99Color]};
    NSMutableAttributedString *newOneString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@? %@", kString(@"not_sure_of_your_password"), kString(@"set_a_new_one")] attributes:newOneDict];
    [newOneString yy_setTextHighlightRange:[[newOneString string] rangeOfString:kString(@"set_a_new_one")] color:[Common textLightBlueColor] backgroundColor:[UIColor clearColor] tapAction:^(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect) {
        WLog(@"Set a new one Clicked");
    }];
    YYLabel *newOnLabel = [[YYLabel alloc] init];
    newOnLabel.attributedText = newOneString;
    newOnLabel.textAlignment = NSTextAlignmentLeft;
    newOnLabel.numberOfLines = 0;
    [mainView addSubview:newOnLabel];

    [newOnLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(passwordField.mas_bottom).mas_offset(10);
        make.left.mas_equalTo(passwordField.mas_left);
    }];

    //渐变颜色
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors     = @[(__bridge id) WRGBHex(0x00D1FF).CGColor, (__bridge id) WRGBHex(0x00FAC4).CGColor];
    gradientLayer.locations  = @[@0.1, @1.0];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint   = CGPointMake(1.0, 0);
    gradientLayer.frame      = CGRectMake(0, 0,  308, 40);
    gradientLayer.cornerRadius = 3;

    QMUIButton *signInButton = [[QMUIButton alloc] init];
    [signInButton.layer addSublayer:gradientLayer];

    [signInButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [signInButton addTarget:self action:@selector(signInButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [signInButton setTitle:NSLocalizedStringFromTable(@"auth_softlogout_sign_in", @"Vector", nil) forState:UIControlStateNormal];
    signInButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
    
    [mainView addSubview:signInButton];
    [signInButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(newOnLabel.mas_bottom).mas_offset(16);
        make.left.mas_equalTo(passwordField.mas_left);
        make.right.mas_equalTo(passwordField.mas_right);
        make.height.mas_equalTo(40);
    }];

    UILabel *createAccountLabel = [[UILabel alloc] init];
    createAccountLabel.text = kString(@"create_account");
    createAccountLabel.font = [UIFont systemFontOfSize:12];
    createAccountLabel.textColor = [Common textLightBlueColor];
    [mainView addSubview:createAccountLabel];
    [createAccountLabel mas_makeConstraints:^(MASConstraintMaker *make){
        make.top.mas_equalTo(signInButton.mas_bottom).mas_offset(8);
        make.centerX.mas_equalTo(signInButton.mas_centerX);
    }];

    [mainView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(createAccountLabel.mas_bottom).mas_offset(36);
    }];
    
    JRDropDown *languageList = [[JRDropDown alloc] initWithFrame:CGRectMake(self.view.centerX, mainView.y + mainView.h + 20, 150, 18)];
    languageList.textColor = [UIColor whiteColor];
    languageList.font = [UIFont systemFontOfSize:14];
    languageList.arrowColor = [UIColor whiteColor];
    languageList.isSearchEnable = false;
    languageList.selectedRowColor = [UIColor lightGrayColor];
    languageList.optionArray = @[@"English(US)", @"中文"];
    languageList.optionIds = @[@0, @1];
    __block NSArray *languages = @[English_US, Chinese_Simple];
    NSString *currentLanguage = [Common currentLanguage];
    NSInteger idx = [languages indexOfObject:currentLanguage];
    languageList.selectedIndex = idx;
    languageList.text = languageList.optionArray[idx];
    [languageList didSelectWithCompletion:^(NSString *selectedText, NSInteger index, NSInteger id) {
        [Common setNewLanguage:languages[id]];
    }];
    
    [scrollView addSubview:languageList];
    [languageList mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(mainView.mas_bottom).mas_offset(20);
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.width.mas_equalTo(150);
        make.height.mas_equalTo(18);
    }];

}

-(void) signInButtonClicked {
    VTMainTabBarController *mainTabBarController = [[VTMainTabBarController alloc] init];
    mainTabBarController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController: mainTabBarController animated:YES completion:nil];
}

@end
