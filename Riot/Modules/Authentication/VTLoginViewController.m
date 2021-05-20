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
#import "Riot-Swift.h"
#import "MXSession+Riot.h"
#import "Common.h"
#import "VTMainTabBarController.h"
#import <QMUIKit/QMUIKit.h>
#import <YYText/YYText.h>
#import "PrefixHeader.pch"
#import <MatrixSDK/MatrixSDK.h>
#import <AFNetworking/AFNetworking.h>



NSString *const kMXLoginFlowTypePassword = @"m.login.password";
NSString *const kMXLoginFlowTypeRecaptcha = @"m.login.recaptcha";
NSString *const kMXLoginFlowTypeOAuth2 = @"m.login.oauth2";
NSString *const kMXLoginFlowTypeCAS = @"m.login.cas";
NSString *const kMXLoginFlowTypeSSO = @"m.login.sso";
NSString *const kMXLoginFlowTypeEmailIdentity = @"m.login.email.identity";
NSString *const kMXLoginFlowTypeToken = @"m.login.token";
NSString *const kMXLoginFlowTypeDummy = @"m.login.dummy";
NSString *const kMXLoginFlowTypeEmailCode = @"m.login.email.code";
NSString *const kMXLoginFlowTypeMSISDN = @"m.login.msisdn";
NSString *const kMXLoginFlowTypeTerms = @"m.login.terms";

NSString *const kMXLoginIdentifierTypeUser = @"m.id.user";
NSString *const kMXLoginIdentifierTypeThirdParty = @"m.id.thirdparty";
NSString *const kMXLoginIdentifierTypePhone = @"m.id.phone";

const NSString *defaultHomeServerUrl = @"https://matrix.org";
const NSInteger loginPasswordTag = 99999;
const NSInteger registerPasswordTag = 99998;
const NSInteger usernameTag = 99997;
const NSInteger registerUsernameTag = 99996;
const NSInteger userNameLengthLimit = 2;

@interface VTLoginViewController ()

@property(nonatomic, strong) NSString *userNameStr;
@property(nonatomic, strong) NSString *homeServerUrl;
@property(nonatomic, strong) QMUITextField *userNameInput;
@property(nonatomic, strong) QMUITextField *passwordInput;
@property(nonatomic, strong) QMUITextField *registerUserNameInput;
@property(nonatomic, strong) QMUITextField *registerEmailInput;
@property(nonatomic, strong) QMUITextField *registerConfirmPasswordInput;
@property(nonatomic, strong) QMUITextField *registerPasswordInput;
@property(nonatomic, strong) QMUIButton *loginButton;
@property(nonatomic, strong) QMUIButton *registerButton;
@property(nonatomic, strong) UIView *loginView;
@property(nonatomic, strong) UIView *registerView;
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) JRDropDown *languageDropDown;
@property(nonatomic, strong) MXRestClient *mxRestClient;
@property(nonatomic, strong) MXHTTPClientOnUnrecognizedCertificate onUnrecognizedCertificateCustomBlock;
@property(nonatomic, strong) MXHTTPOperation *mxCurrentOperation;
@property (nonatomic) NSDictionary* externalRegistrationParameters;
@property (nonatomic) MXKAuthenticationType authType;
@property (nonatomic) MXCredentials *softLogoutCredentials;

@end

@implementation VTLoginViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	[self setupUI];
	[self updateRESTClient];
}

- (void)setupUI {
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenW, kScreenH)];
	self.view = view;
	self.view.backgroundColor = WRGBHex(0x190C37);
	UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
	[self.view addSubview:scrollView];
	self.scrollView = scrollView;
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
	topLabel.text = kString(@"auth_softlogout_sign_in");
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
	self.userNameStr = kString(@"auth_user_name_placeholder");
	[signInWith didSelectWithCompletion:^(NSString *selectedText, NSInteger index, NSInteger id) {
	         WLog(@"%zd", index);
	         self.userNameStr = signInWith.optionArray[index];
	         if (self.userNameInput != nil) {
			 self.userNameInput.placeholder = self.userNameStr;
		 }
	 }];
	[mainView addSubview:signInWith];
	[signInWith mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.right.mas_equalTo(mainView.mas_right).mas_offset(-20);
	         make.top.mas_equalTo(tipLabel.mas_bottom).mas_offset(18);
	         make.width.mas_equalTo(160);
	         make.height.mas_equalTo(36);
	 }];

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
	userNameField.placeholder = self.userNameStr;
	userNameField.layer.cornerRadius = 3;
	userNameField.layer.masksToBounds = YES;
	userNameField.layer.borderWidth = 1;
	userNameField.tag = usernameTag;
	[userNameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
	userNameField.layer.borderColor = [Common fieldBorderColor].CGColor;
	[mainView addSubview:userNameField];
	self.userNameInput = userNameField;

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
	passwordField.secureTextEntry = YES;
	passwordField.layer.borderWidth = 1;
	passwordField.layer.borderColor = [Common fieldBorderColor].CGColor;
	passwordField.tag = loginPasswordTag;
	[passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
	[mainView addSubview:passwordField];
	self.passwordInput = passwordField;

	[passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(userNameField.mas_left);
	         make.right.mas_equalTo(userNameField.mas_right);
	         make.height.mas_equalTo(userNameField.mas_height);
	         make.top.mas_equalTo(userNameField.mas_bottom).mas_offset(16);
	 }];

	NSDictionary *newOneDict = @{NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: [Common text99Color]};
	NSMutableAttributedString *newOneString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@? %@", kString(@"not_sure_of_your_password"), kString(@"set_a_new_one")] attributes:newOneDict];
	[newOneString yy_setTextHighlightRange:[[newOneString string] rangeOfString:kString(@"set_a_new_one")] color:[Common textLightBlueColor] backgroundColor:[UIColor clearColor] tapAction:^(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect) {
	         [self switchRegister];
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
	gradientLayer.colors = @[(__bridge id) WRGBHex(0x00D1FF).CGColor, (__bridge id) WRGBHex(0x00FAC4).CGColor];
	gradientLayer.locations = @[@0.1, @1.0];
	gradientLayer.startPoint = CGPointMake(0, 0);
	gradientLayer.endPoint = CGPointMake(1.0, 0);
	gradientLayer.frame = CGRectMake(0, 0, 308, 40);
	gradientLayer.cornerRadius = 3;

	QMUIButton *signInButton = [[QMUIButton alloc] init];
	[signInButton.layer addSublayer:gradientLayer];

	[signInButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[signInButton addTarget:self action:@selector(signInButtonClicked) forControlEvents:UIControlEventTouchUpInside];

	[signInButton setTitle:NSLocalizedStringFromTable(@"auth_softlogout_sign_in", @"Vector", nil) forState:UIControlStateNormal];
	signInButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
	signInButton.enabled = NO;
	self.loginButton = signInButton;

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
	[createAccountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(signInButton.mas_bottom).mas_offset(8);
	         make.centerX.mas_equalTo(signInButton.mas_centerX);
	 }];
	UITapGestureRecognizer *createAccountLabelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchRegister)];
	[createAccountLabel addGestureRecognizer:createAccountLabelTap];
	createAccountLabel.userInteractionEnabled = YES;

	[mainView mas_updateConstraints:^(MASConstraintMaker *make) {
	         make.bottom.mas_equalTo(createAccountLabel.mas_bottom).mas_offset(36);
	 }];

	self.loginView = mainView;

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
	currentLanguage = currentLanguage != nil ? currentLanguage : English_US;
	NSInteger idx = [languages indexOfObject:currentLanguage];
	languageList.selectedIndex = idx;
	languageList.text = languageList.optionArray[idx];
	languageList.textAlignment = NSTextAlignmentCenter;
	[languageList didSelectWithCompletion:^(NSString *selectedText, NSInteger index, NSInteger id) {
	         [Common setNewLanguage:languages[id]];
	 }];
	self.languageDropDown = languageList;
	[scrollView addSubview:languageList];
	[languageList mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(mainView.mas_bottom).mas_offset(20);
	         make.centerX.mas_equalTo(self.view.mas_centerX);
	         make.width.mas_equalTo(150);
	         make.height.mas_equalTo(18);
	 }];

	self.authType = MXKAuthenticationTypeLogin;

}

- (void)setupRegisterView {
	UIView *registerView = [[UIView alloc] init];
	registerView.hidden = YES;
	[registerView setBackgroundColor:[UIColor whiteColor]];
	registerView.layer.cornerRadius = 5;
	registerView.layer.masksToBounds = YES;
	registerView.layer.borderWidth = 1;
	registerView.layer.borderColor = [Common fieldBorderColor].CGColor;
	[self.view addSubview:registerView];
	self.registerView = registerView;
	[registerView mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(self.loginView.mas_top);
	         make.left.mas_equalTo(self.loginView.mas_left);
	         make.right.mas_equalTo(self.loginView.mas_right);
	 }];

	UILabel *topLabel = [[UILabel alloc] init];
	topLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
	topLabel.text = kString(@"set_a_new_one");
	topLabel.textColor = [Common text33Color];
	[registerView addSubview:topLabel];

	[topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(registerView.mas_top).mas_offset(20);
	         make.left.mas_equalTo(registerView.mas_left).mas_offset(20);
	 }];
	NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14], NSForegroundColorAttributeName: [Common text33Color]};
	NSMutableAttributedString *tipString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", kString(@"create_account_on_matrix_client_matrix_org"), kString(@"change")] attributes:attributes];
	[tipString yy_setTextHighlightRange:[[tipString string] rangeOfString:kString(@"change")] color:[Common textLightBlueColor] backgroundColor:[UIColor clearColor] tapAction:^(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect) {
	         WLog(@"Change Clicked");
	 }];
	YYLabel *tipLabel = [[YYLabel alloc] init];
	tipLabel.attributedText = tipString;
	tipLabel.textAlignment = NSTextAlignmentLeft;
	tipLabel.numberOfLines = 0;
	tipLabel.preferredMaxLayoutWidth = kScreenW - 60 - 20 - 16 - 16;
	[registerView addSubview:tipLabel];

	[registerView.superview layoutIfNeeded];

	[tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(topLabel.mas_left);
	         make.top.mas_equalTo(topLabel.mas_bottom).mas_offset(17);
	 }];

	[tipLabel.superview layoutIfNeeded];


	QMUITextField *userNameField = [[QMUITextField alloc] init];
	userNameField.textInsets = UIEdgeInsetsMake(0, 8, 0, 0);
	userNameField.placeholder = kString(@"auth_user_name_placeholder");
	userNameField.layer.cornerRadius = 3;
	userNameField.layer.masksToBounds = YES;
	userNameField.layer.borderWidth = 1;
	userNameField.layer.borderColor = [Common fieldBorderColor].CGColor;
	userNameField.tag = registerUsernameTag;
	[userNameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
	[registerView addSubview:userNameField];
	self.registerUserNameInput = userNameField;

	[userNameField mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(tipLabel.mas_bottom).mas_offset(16);
	         make.left.mas_equalTo(registerView.mas_left).mas_offset(20);
	         make.right.mas_equalTo(registerView.mas_right).mas_offset(-20);
	         make.height.mas_equalTo(40);
	 }];

	QMUITextField *passwordField = [[QMUITextField alloc] init];
	passwordField.textInsets = UIEdgeInsetsMake(0, 8, 0, 0);
	passwordField.placeholder = kString(@"password");
	passwordField.layer.cornerRadius = 3;
	passwordField.layer.masksToBounds = YES;
	passwordField.layer.borderWidth = 1;
	passwordField.secureTextEntry = YES;
	passwordField.layer.borderColor = [Common fieldBorderColor].CGColor;
	passwordField.tag = registerPasswordTag;
	[passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
	self.registerPasswordInput = passwordField;
	[registerView addSubview:passwordField];

	[passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(userNameField.mas_left);
	         make.right.mas_equalTo(userNameField.mas_right);
	         make.height.mas_equalTo(userNameField.mas_height);
	         make.top.mas_equalTo(userNameField.mas_bottom).mas_offset(16);
	 }];

	QMUITextField *confirmPasswordField = [[QMUITextField alloc] init];
	confirmPasswordField.textInsets = UIEdgeInsetsMake(0, 8, 0, 0);
	confirmPasswordField.placeholder = kString(@"confirm_password");
	confirmPasswordField.layer.cornerRadius = 3;
	confirmPasswordField.layer.masksToBounds = YES;
	confirmPasswordField.layer.borderWidth = 1;
	confirmPasswordField.secureTextEntry = YES;
	confirmPasswordField.layer.borderColor = [Common fieldBorderColor].CGColor;
	self.registerConfirmPasswordInput = confirmPasswordField;
	[registerView addSubview:confirmPasswordField];

	[confirmPasswordField mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(userNameField.mas_left);
	         make.right.mas_equalTo(userNameField.mas_right);
	         make.height.mas_equalTo(userNameField.mas_height);
	         make.top.mas_equalTo(passwordField.mas_bottom).mas_offset(16);
	 }];

	QMUITextField *emailField = [[QMUITextField alloc] init];
	emailField.textInsets = UIEdgeInsetsMake(0, 8, 0, 0);
	emailField.placeholder = kString(@"email_addresses");
	emailField.layer.cornerRadius = 3;
	emailField.layer.masksToBounds = YES;
	emailField.layer.borderWidth = 1;
	emailField.layer.borderColor = [Common fieldBorderColor].CGColor;
	self.registerEmailInput = emailField;
	[registerView addSubview:emailField];

	[emailField mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(userNameField.mas_left);
	         make.right.mas_equalTo(userNameField.mas_right);
	         make.height.mas_equalTo(userNameField.mas_height);
	         make.top.mas_equalTo(confirmPasswordField.mas_bottom).mas_offset(16);
	 }];


	NSDictionary *newOneDict = @{NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: [Common text99Color]};
	NSMutableAttributedString *newOneString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@? %@", kString(@"already_have_account"), kString(@"sign_in_here")] attributes:newOneDict];
	[newOneString yy_setTextHighlightRange:[[newOneString string] rangeOfString:kString(@"sign_in_here")] color:[Common textLightBlueColor] backgroundColor:[UIColor clearColor] tapAction:^(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect) {
	         [self switchLogin];
	 }];
	YYLabel *newOnLabel = [[YYLabel alloc] init];
	newOnLabel.attributedText = newOneString;
	newOnLabel.textAlignment = NSTextAlignmentLeft;
	newOnLabel.numberOfLines = 0;
	[registerView addSubview:newOnLabel];

	[newOnLabel mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(emailField.mas_bottom).mas_offset(10);
	         make.left.mas_equalTo(confirmPasswordField.mas_left);
	 }];

	//渐变颜色
	CAGradientLayer *gradientLayer = [CAGradientLayer layer];
	gradientLayer.colors = @[(__bridge id) WRGBHex(0x00D1FF).CGColor, (__bridge id) WRGBHex(0x00FAC4).CGColor];
	gradientLayer.locations = @[@0.1, @1.0];
	gradientLayer.startPoint = CGPointMake(0, 0);
	gradientLayer.endPoint = CGPointMake(1.0, 0);
	gradientLayer.frame = CGRectMake(0, 0, 308, 40);
	gradientLayer.cornerRadius = 3;

	QMUIButton *registerButton = [[QMUIButton alloc] init];
	[registerButton.layer addSublayer:gradientLayer];

	[registerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[registerButton addTarget:self action:@selector(registerButtonClicked) forControlEvents:UIControlEventTouchUpInside];

	[registerButton setTitle:kString(@"register") forState:UIControlStateNormal];
	registerButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
	registerButton.enabled = NO;
	self.registerButton = registerButton;

	[registerView addSubview:registerButton];
	[registerButton mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(newOnLabel.mas_bottom).mas_offset(16);
	         make.left.mas_equalTo(passwordField.mas_left);
	         make.right.mas_equalTo(passwordField.mas_right);
	         make.height.mas_equalTo(40);
	 }];

	[registerView mas_updateConstraints:^(MASConstraintMaker *make) {
	         make.bottom.mas_equalTo(registerButton.mas_bottom).mas_offset(36);
	 }];

}

- (void)switchLogin {
	self.authType = MXKAuthenticationTypeLogin;
	[self.languageDropDown mas_updateConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(self.loginView.mas_bottom).mas_offset(20);
	 }];
	[UIView transitionWithView:self.view duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
	         self.registerView.hidden = YES;
	         self.loginView.hidden = NO;
	 } completion:nil];

}

- (void)switchRegister {
	if (nil == self.registerView) {
		[self setupRegisterView];
	}
	[self.languageDropDown mas_updateConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(self.loginView.mas_bottom).mas_offset(60);
	 }];
	[UIView transitionWithView:self.view duration:0.5 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
	         self.registerView.hidden = NO;
	         self.loginView.hidden = YES;
	 } completion:nil];


}

- (void)registerButtonClicked {


}

- (void)checkBeforeLogin {
	NSString *userName = self.userNameInput.text;
	userName = [userName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString *password = self.passwordInput.text;

	if (!userName.length || !password) {
		NSString *errorMsg = kString(@"username_or_password_can_not_be_null");
		[QMUITips showError:errorMsg inView:self.view hideAfterDelay:1.5];
		return;
	}

}

- (void)signInButtonClicked {

	if (self.userNameInput.text.length < userNameLengthLimit || self.passwordInput.text.length < 6) {
		return;
	}

	[QMUITips showLoadingInView:self.view];
	[self checkBeforeLogin];

	NSDictionary *parameters = @{
		@"type": kMXLoginFlowTypePassword,
		@"identifier": @{
			@"type": kMXLoginIdentifierTypeUser,
			@"user": self.userNameInput.text
		},
		@"password": self.passwordInput.text,
		@"user": self.userNameInput.text,
		@"initial_device_display_name": @"Mobile"
	};

	self.mxCurrentOperation = [self.mxRestClient login:parameters success:^(NSDictionary *JSONResponse) {
	                                   [QMUITips hideAllTips];
	                                   MXLoginResponse *loginResponse;
	                                   MXJSONModelSetMXJSONModel(loginResponse, MXLoginResponse, JSONResponse);
	                                   MXCredentials *credentials = [[MXCredentials alloc] initWithLoginResponse:loginResponse andDefaultCredentials:self.mxRestClient.credentials];
	                                   // Sanity check
	                                   if (!credentials.userId || !credentials.accessToken)
					   {
						   [self onFailureDuringAuthRequest:[NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[NSBundle mxk_localizedStringForKey:@"not_supported_yet"]}]];
					   }
	                                   else
					   {
						   NSLog(@"[MXKAuthenticationVC] Login process succeeded");

						   // Report the certificate trusted by user (if any)
						   credentials.allowedCertificate = self.mxRestClient.allowedCertificate;

						   [self onSuccessfulLogin:credentials];
					   }
				   } failure:^(NSError *error) {
	                                   [QMUITips hideAllTips];
	                                   [self onFailureDuringAuthRequest:error];
				   }];

}

-(void) loginSuccess {
	VTMainTabBarController *mainTabBarController = [[VTMainTabBarController alloc] init];
	mainTabBarController.modalPresentationStyle = UIModalPresentationFullScreen;
	[self presentViewController:mainTabBarController animated:YES completion:nil];
}

-(void) didLogWithUserId:(NSString *)userId {
	MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:userId];
	MXSession *session = account.mxSession;

	BOOL botCreationEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"enableBotCreation"];
	// Create DM with Riot-bot on new account creation.
	if (self.authType == MXKAuthenticationTypeRegister && botCreationEnabled)
	{

		MXRoomCreationParameters *roomCreationParameters = [MXRoomCreationParameters parametersForDirectRoomWithUser:@"@riot-bot:matrix.org"];
		[session createRoomWithParameters:roomCreationParameters success:nil failure:^(NSError *error) {
		         WLog(@"[AuthenticationVC] Create chat with riot-bot failed");
		 }];
	}

	// Wait for session change to present complete security screen if needed
	[self registerSessionStateChangeNotificationForSession:session];
}

- (void)onSuccessfulLogin:(MXCredentials*)credentials
{
	self.mxCurrentOperation = nil;

	if (self.softLogoutCredentials)
	{
		// Hydrate the account with the new access token
		MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:self.softLogoutCredentials.userId];
		[[MXKAccountManager sharedManager] hydrateAccount:account withCredentials:credentials];
		[self didLogWithUserId:credentials.userId];

	}
	// Sanity check: check whether the user is not already logged in with this id
	else if ([[MXKAccountManager sharedManager] accountForUserId:credentials.userId])
	{
		[QMUITips showError:[NSBundle mxk_localizedStringForKey:@"login_error_already_logged_in"] inView:self.view hideAfterDelay:2.0];
	}
	else
	{
		// Report the new account in account manager
		if (!credentials.identityServer)
		{
//			credentials.identityServer = _identityServerTextField.text;
		}
		MXKAccount *account = [[MXKAccount alloc] initWithCredentials:credentials];
		account.identityServerURL = credentials.identityServer;

		[[MXKAccountManager sharedManager] addAccount:account andOpenSession:YES];

		[self didLogWithUserId:credentials.userId];
	}
}

- (void)registerSessionStateChangeNotificationForSession:(MXSession*)session
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionStateDidChangeNotification:) name:kMXSessionStateDidChangeNotification object:session];
}

- (void)sessionStateDidChangeNotification:(NSNotification*)notification
{
	MXSession *session = (MXSession*)notification.object;

	if (session.state == MXSessionStateStoreDataReady)
	{
		if (session.crypto.crossSigning)
		{
			// Do not make key share requests while the "Complete security" is not complete.
			// If the device is self-verified, the SDK will restore the existing key backup.
			// Then, it  will re-enable outgoing key share requests
			[session.crypto setOutgoingKeyRequestsEnabled:NO onComplete:nil];
		}
	}
	else if (session.state == MXSessionStateRunning)
	{
		[self unregisterSessionStateChangeNotification];

		if (session.crypto.crossSigning)
		{
			[session.crypto.crossSigning refreshStateWithSuccess:^(BOOL stateUpdated) {

			         WLog(@"[AuthenticationVC] sessionStateDidChange: crossSigning.state: %@", @(session.crypto.crossSigning.state));

			         switch (session.crypto.crossSigning.state)
				 {
				 case MXCrossSigningStateNotBootstrapped:
					 {
						 // TODO: This is still not sure we want to disable the automatic cross-signing bootstrap
						 // if the admin disabled e2e by default.
						 // Do like riot-web for the moment
						 if ([session vc_homeserverConfiguration].isE2EEByDefaultEnabled)
						 {
							 // Bootstrap cross-signing on user's account
							 // We do it for both registration and new login as long as cross-signing does not exist yet
							 if (self.passwordInput.text.length)
							 {
								 NSLog(@"[AuthenticationVC] sessionStateDidChange: Bootstrap with password");

								 [session.crypto.crossSigning setupWithPassword:self.passwordInput.text success:^{
								          WLog(@"[AuthenticationVC] sessionStateDidChange: Bootstrap succeeded");

								  } failure:^(NSError * _Nonnull error) {
								          WLog(@"[AuthenticationVC] sessionStateDidChange: Bootstrap failed. Error: %@", error);
								          [session.crypto setOutgoingKeyRequestsEnabled:YES onComplete:nil];

								  }];
							 }
							 else
							 {
								 // Try to setup cross-signing without authentication parameters in case if a grace period is enabled
//                                [self.crossSigningService setupCrossSigningWithoutAuthenticationFor:session success:^{
//                                    NSLog(@"[AuthenticationVC] sessionStateDidChange: Bootstrap succeeded without credentials");
//                                    [self dismiss];
//                                } failure:^(NSError * _Nonnull error) {
//                                    NSLog(@"[AuthenticationVC] sessionStateDidChange: Do not know how to bootstrap cross-signing. Skip it.");
//                                    [session.crypto setOutgoingKeyRequestsEnabled:YES onComplete:nil];
//                                    [self dismiss];
//                                }];
							 }
						 }
						 else
						 {
							 [session.crypto setOutgoingKeyRequestsEnabled:YES onComplete:nil];
//                            [self dismiss];
						 }
						 break;
					 }
				 case MXCrossSigningStateCrossSigningExists:
					 {
						 WLog(@"[AuthenticationVC] sessionStateDidChange: Complete security");

						 // Ask the user to verify this session



//                        [self presentCompleteSecurityWithSession:session];
						 break;
					 }

				 default:
					 WLog(@"[AuthenticationVC] sessionStateDidChange: Nothing to do");

					 [session.crypto setOutgoingKeyRequestsEnabled:YES onComplete:nil];
//                        [self dismiss];
					 break;
				 }

			 } failure:^(NSError * _Nonnull error) {
			         WLog(@"[AuthenticationVC] sessionStateDidChange: Fail to refresh crypto state with error: %@", error);
			         [session.crypto setOutgoingKeyRequestsEnabled:YES onComplete:nil];
//                [self dismiss];
			 }];
		}
		else
		{
//            [self dismiss];
		}
	}
}

- (void)unregisterSessionStateChangeNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionStateDidChangeNotification object:nil];
}


- (void)onFailureDuringAuthRequest:(NSError *)error
{
	self.mxCurrentOperation = nil;

	// Ignore connection cancellation error
	if (([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled))
	{
		WLog(@"[MXKAuthenticationVC] Auth request cancelled");
		return;
	}

	WLog(@"[MXKAuthenticationVC] Auth request failed: %@", error);

	// Cancel external registration parameters if any
	self.externalRegistrationParameters = nil;

	// Translate the error code to a human message
	NSString *title = error.localizedFailureReason;
	if (!title)
	{
		if (self.authType == MXKAuthenticationTypeLogin)
		{
			title = [NSBundle mxk_localizedStringForKey:@"login_error_title"];
		}
		else if (self.authType == MXKAuthenticationTypeRegister)
		{
			title = [NSBundle mxk_localizedStringForKey:@"register_error_title"];
		}
		else
		{
			title = [NSBundle mxk_localizedStringForKey:@"error"];
		}
	}
	NSString* message = error.localizedDescription;
	NSDictionary* dict = error.userInfo;

	// detect if it is a Matrix SDK issue
	if (dict)
	{
		NSString* localizedError = [dict valueForKey:@"error"];
		NSString* errCode = [dict valueForKey:@"errcode"];

		if (localizedError.length > 0)
		{
			message = localizedError;
		}

		if (errCode)
		{
			if ([errCode isEqualToString:kMXErrCodeStringForbidden])
			{
				message = [NSBundle mxk_localizedStringForKey:@"login_error_forbidden"];
			}
			else if ([errCode isEqualToString:kMXErrCodeStringUnknownToken])
			{
				message = [NSBundle mxk_localizedStringForKey:@"login_error_unknown_token"];
			}
			else if ([errCode isEqualToString:kMXErrCodeStringBadJSON])
			{
				message = [NSBundle mxk_localizedStringForKey:@"login_error_bad_json"];
			}
			else if ([errCode isEqualToString:kMXErrCodeStringNotJSON])
			{
				message = [NSBundle mxk_localizedStringForKey:@"login_error_not_json"];
			}
			else if ([errCode isEqualToString:kMXErrCodeStringLimitExceeded])
			{
				message = [NSBundle mxk_localizedStringForKey:@"login_error_limit_exceeded"];
			}
			else if ([errCode isEqualToString:kMXErrCodeStringUserInUse])
			{
				message = [NSBundle mxk_localizedStringForKey:@"login_error_user_in_use"];
			}
			else if ([errCode isEqualToString:kMXErrCodeStringLoginEmailURLNotYet])
			{
				message = [NSBundle mxk_localizedStringForKey:@"login_error_login_email_not_yet"];
			}
			else if ([errCode isEqualToString:kMXErrCodeStringResourceLimitExceeded])
			{
				[self showResourceLimitExceededError:dict onAdminContactTapped:nil];
				return;
			}
			else if (!message.length)
			{
				message = errCode;
			}
		}
	}

	[QMUITips showError:message inView:self.view hideAfterDelay:2.0];
	// Update authentication inputs view to return in initial step
//	[self.authInputsView setAuthSession:self.authInputsView.authSession withAuthType:_authType];
//	if (self.softLogoutCredentials)
//	{
//		self.authInputsView.softLogoutCredentials = self.softLogoutCredentials;
//	}
}

- (void)showResourceLimitExceededError:(NSDictionary *)errorDict onAdminContactTapped:(void (^)(NSURL *adminContact))onAdminContactTapped
{
	self.mxCurrentOperation = nil;


	// Parse error data
	NSString *limitType, *adminContactString;
	NSURL *adminContact;

	MXJSONModelSetString(limitType, errorDict[kMXErrorResourceLimitExceededLimitTypeKey]);
	MXJSONModelSetString(adminContactString, errorDict[kMXErrorResourceLimitExceededAdminContactKey]);

	if (adminContactString)
	{
		adminContact = [NSURL URLWithString:adminContactString];
	}

	NSString *title = [NSBundle mxk_localizedStringForKey:@"login_error_resource_limit_exceeded_title"];

	// Build the message content
	NSMutableString *message = [NSMutableString new];
	if ([limitType isEqualToString:kMXErrorResourceLimitExceededLimitTypeMonthlyActiveUserValue])
	{
		[message appendString:[NSBundle mxk_localizedStringForKey:@"login_error_resource_limit_exceeded_message_monthly_active_user"]];
	}
	else
	{
		[message appendString:[NSBundle mxk_localizedStringForKey:@"login_error_resource_limit_exceeded_message_default"]];
	}

	[message appendString:[NSBundle mxk_localizedStringForKey:@"login_error_resource_limit_exceeded_message_contact"]];


	[QMUITips showError:message inView:self.view hideAfterDelay:2.0];
//	MXWeakify(self);
//	if (adminContact && onAdminContactTapped)
//	{
//		[alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"login_error_resource_limit_exceeded_contact_button"]
//		                  style:UIAlertActionStyleDefault
//		                  handler:^(UIAlertAction * action)
//		                  {
//		                          MXStrongifyAndReturnIfNil(self);
//		                          self->alert = nil;
//
//		                          // Let the system handle the URI
//		                          // It could be something like "mailto: server.admin@example.com"
//		                          onAdminContactTapped(adminContact);
//				  }]];
//	}
//
//	[alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
//	                  style:UIAlertActionStyleDefault
//	                  handler:^(UIAlertAction * action)
//	                  {
//	                          MXStrongifyAndReturnIfNil(self);
//	                          self->alert = nil;
//			  }]];
//
//	[self presentViewController:alert animated:YES completion:nil];
//
//	// Update authentication inputs view to return in initial step
//	[self.authInputsView setAuthSession:self.authInputsView.authSession withAuthType:_authType];
}


#pragma mark - UITextField

- (void)textFieldDidChange:(UITextField *)textField {
	if (textField.markedTextRange == nil) {
		WLog(@"text:%@", textField.text);
		if (textField.tag == loginPasswordTag) {
			if (textField.text.length > 5 && self.userNameInput.text.length >= userNameLengthLimit) {
				self.loginButton.enabled = YES;
			} else {
				self.loginButton.enabled = NO;
			}
		} else if (textField.tag == registerPasswordTag) {
			if (textField.text.length > 5 && self.registerUserNameInput.text.length >= userNameLengthLimit) {
				self.registerButton.enabled = YES;
			} else {
				self.registerButton.enabled = NO;
			}
		} else if (textField.tag == usernameTag) {
			if (textField.text.length > 5 && self.passwordInput.text.length >= 6) {
				self.loginButton.enabled = YES;
			} else {
				self.loginButton.enabled = NO;
			}
		} else if (textField.tag == registerUsernameTag) {
			if (textField.text.length > 5 && self.registerPasswordInput.text.length >= 6) {
				self.registerButton.enabled = YES;
			} else {
				self.registerButton.enabled = NO;
			}
		}
	}
}

#pragma mark - Matrix Related

/**
   should change when home server url changed
 */
-(void) updateRESTClient {
	if (self.homeServerUrl.length) {
		if (![self.mxRestClient.homeserver isEqualToString:self.homeServerUrl]) {
			self.mxRestClient = [[MXRestClient alloc] initWithHomeServer:self.homeServerUrl andOnUnrecognizedCertificateBlock:^BOOL (NSData *certificate) {
			                             // Check first if the app developer provided its own certificate handler.
			                             if (self.onUnrecognizedCertificateCustomBlock) {
							     return self.onUnrecognizedCertificateCustomBlock(certificate);
						     } else {
							     // Else prompt the user by displaying a fingerprint (SHA256) of the certificat
							     __block BOOL isTrusted;
							     dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
							     NSString *title = [NSBundle mxk_localizedStringForKey:@"ssl_could_not_verify"];
							     NSString *homeserverURLStr = [NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"ssl_homeserver_url"], self.homeServerUrl];
							     NSString *fingerprint = [NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"ssl_fingerprint_hash"], @"SHA256"];
							     NSString *certFingerprint = [certificate mx_SHA256AsHexString];

							     NSString *msg = [NSString stringWithFormat:@"%@\n\n%@\n\n%@\n\n%@\n\n%@\n\n%@", [NSBundle mxk_localizedStringForKey:@"ssl_cert_not_trust"], [NSBundle mxk_localizedStringForKey:@"ssl_cert_new_account_expl"], homeserverURLStr, fingerprint, certFingerprint, [NSBundle mxk_localizedStringForKey:@"ssl_only_accept"]];
							     dispatch_async(dispatch_get_main_queue(), ^{
										    [QMUITips showError:msg inView:self.view hideAfterDelay:2];
									    });
							     dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
							     if (!isTrusted)
							     {
								     // Cancel request in progress
								     if (nil != self.mxCurrentOperation) {
									     [self.mxCurrentOperation cancel];
									     self.mxCurrentOperation = nil;
								     }
								     [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];

							     }

							     return isTrusted;

						     }
					     }];
		}
	} else {
		[self.mxRestClient close];
		self.mxRestClient = nil;
	}
}

- (void)setOnUnrecognizedCertificateBlock:(MXHTTPClientOnUnrecognizedCertificate)onUnrecognizedCertificateBlock
{
	self.onUnrecognizedCertificateCustomBlock = onUnrecognizedCertificateBlock;
}

#pragma mark - Lazyload

-(NSString *)homeServerUrl {
	if (nil == _homeServerUrl) {
		_homeServerUrl = defaultHomeServerUrl;
	}
	return _homeServerUrl;
}


@end
