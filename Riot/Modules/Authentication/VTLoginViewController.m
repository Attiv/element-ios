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
//const NSString *defaultHomeServerUrl = @"https://kelare.istory.cc:8448";
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
@property(nonatomic) NSDictionary *externalRegistrationParameters;
@property(nonatomic) MXKAuthenticationType authType;
@property(nonatomic) MXCredentials *softLogoutCredentials;
/**
   The current authentication session if any.
 */
@property(nonatomic, readonly) MXAuthenticationSession *authSession;
//@property (nonatomic, strong) MXAuthenticationSession *currentSession;
@property(nonatomic, strong) NSString *session;

/**
   The identity service used to make identity server API requests.
 */
@property(nonatomic) MXIdentityService *identityService;

@end

@implementation VTLoginViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	MXAuthenticationSession *authSession = [MXAuthenticationSession modelFromJSON:@{@"flows": @[@{@"stages": @[kMXLoginFlowTypePassword]}]}];
	[self setAuthSession:authSession withAuthType:MXKAuthenticationTypeLogin];
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
	NSMutableAttributedString *tipString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", [NSString stringWithFormat:kString(@"sign_in_to_your_Matrix_account_on"), self.homeServerUrl], kString(@"change")] attributes:attributes];
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
//	signInWith.optionArray = @[kString(@"auth_user_name_placeholder"), kString(@"email_addresses"), kString(@"phone")];
	signInWith.optionArray = @[kString(@"auth_user_name_placeholder")];
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
	 }               completion:^(BOOL finished) {
	         self.authType = MXKAuthenticationTypeLogin;
	 }];

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
	 }               completion:^(BOOL finished) {
	         self.authType = MXKAuthenticationTypeRegister;
	 }];


}

- (void)registerButtonClicked {
	NSString *errorMsg = [self checkBeforeRegister];
	if (errorMsg != nil) {
		[QMUITips showError:errorMsg inView:self.view hideAfterDelay:2];
		return;
	}
	[QMUITips showLoadingInView:self.view];

	[self testUserRegistration:^(MXError *mxError) {
	         [QMUITips hideAllTipsInView:self.view];
	         if ([mxError.errcode isEqualToString:kMXErrCodeStringUserInUse]) {
			 WLog(@"[AuthenticationVC] User name is already use");
			 [self onFailureDuringAuthRequest:[NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: kString(@"auth_username_in_use")}]];
		 }
	         //   - the server quota limits is not reached
	         else if ([mxError.errcode isEqualToString:kMXErrCodeStringResourceLimitExceeded]) {
			 [self showResourceLimitExceededError:mxError.userInfo];
		 } else {

		 }
	         if (mxError == nil) {
			 [self registerStart];
		 }
	 }];
}

- (NSString *)checkBeforeLogin {
	NSString *userName = self.userNameInput.text;
	userName = [userName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString *password = self.passwordInput.text;
	NSString *errorMsg = nil;
	if ([self isFlowSupported:kMXLoginFlowTypePassword]) {
		if (!userName.length || !password) {
			errorMsg = kString(@"username_or_password_can_not_be_null");
		}
	} else {
		errorMsg = kString(@"not_supported_yet");
	}

	return errorMsg;

}

- (void)testUserRegistration:(void (^)(MXError *mxError))callback {
	self.mxCurrentOperation = [self.mxRestClient testUserRegistration:self.registerUserNameInput.text callback:callback];
}


- (NSString *)checkBeforeRegister {
	NSString *errorMsg = nil;
	if (!self.registerUserNameInput.text.length) {
		WLog(@"[AuthInputsView] Invalid user name");
		errorMsg = kString(@"auth_invalid_user_name");
	} else if (!self.registerPasswordInput.text.length) {
		WLog(@"[AuthInputsView] Missing Passwords");
		errorMsg = kString(@"auth_missing_password");
	} else if (self.registerPasswordInput.text.length < 6) {
		WLog(@"[AuthInputsView] Invalid Passwords");
		errorMsg = kString(@"auth_invalid_password");
	} else if ([self.registerConfirmPasswordInput.text isEqualToString:self.registerPasswordInput.text] == NO) {
		WLog(@"[AuthInputsView] Passwords don't match");
		errorMsg = kString(@"auth_password_dont_match");
	} else {
		// Check validity of the non empty user name
		NSString *user = self.registerUserNameInput.text;
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[a-z0-9.\\-_]+$" options:NSRegularExpressionCaseInsensitive error:nil];

		if ([regex firstMatchInString:user options:0 range:NSMakeRange(0, user.length)] == nil) {
			WLog(@"[AuthInputsView] Invalid user name");
			errorMsg = kString(@"auth_invalid_user_name");
		}
		// Check email field
		if ([self isFlowSupported:kMXLoginFlowTypeEmailIdentity] && !self.registerEmailInput.text.length) {
			if (self.areAllThirdPartyIdentifiersRequired) {
				WLog(@"[AuthInputsView] Missing email");
				errorMsg = kString(@"auth_missing_email");
			}
		}

	}
	if (!errorMsg) {
		if (self.registerEmailInput.text.length) {
			// Check validity of the non empty email
			if (![MXTools isEmailAddress:self.registerEmailInput.text]) {
				WLog(@"[AuthInputsView] Invalid email");
				errorMsg = kString(@"auth_invalid_email");
			}
		}
	}
	return errorMsg;
}

- (void)registerWithEmail {

}

- (void)updateAuthSessionWithCompletedStages:(NSArray *)completedStages didUpdateParameters:(void (^)(NSDictionary *parameters, NSError *error))callback
{
	if (callback)
	{
		if (currentSession)
		{
			currentSession.completed = completedStages;

			BOOL isMSISDNFlowCompleted = [self isFlowCompleted:kMXLoginFlowTypeMSISDN];
			BOOL isEmailFlowCompleted = [self isFlowCompleted:kMXLoginFlowTypeEmailIdentity];

			// Check the supported use cases
			if (isMSISDNFlowCompleted && self.isThirdPartyIdentifierPending)
			{
				WLog(@"[AuthInputsView] Prepare a new third-party stage");

				// Here an email address is available, we add it to the authentication session.
				[self prepareRegisterParameters:callback];

				return;
			}
			else if ((isMSISDNFlowCompleted || isEmailFlowCompleted)
			         && [self isFlowSupported:kMXLoginFlowTypeRecaptcha] && ![self isFlowCompleted:kMXLoginFlowTypeRecaptcha])
			{
				WLog(@"[AuthInputsView] Display reCaptcha stage");

				if (_externalRegistrationParameters)
				{
					[self displayRecaptchaForm:^(NSString *response) {

					         if (response.length)
						 {
							 // We finalize here a registration triggered from external inputs. All the required data are handled by the session id
							 NSDictionary *parameters = @{
							         @"auth": @{@"session": currentSession.session, @"response": response, @"type": kMXLoginFlowTypeRecaptcha},
							 };
							 callback (parameters, nil);
						 }
					         else
						 {
							 WLog(@"[AuthInputsView] reCaptcha stage failed");
							 callback (nil, [NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[NSBundle mxk_localizedStringForKey:@"not_supported_yet"]}]);
						 }
					 }];
				}
				else
				{
					[self prepareRegisterParameters:callback];
				}

				return;
			}
			else if ([self isFlowSupported:kMXLoginFlowTypeTerms] && ![self isFlowCompleted:kMXLoginFlowTypeTerms])
			{
				WLog(@"[AuthInputsView] Prepare a new terms stage");

				if (self.externalRegistrationParameters)
				{
//					[self displayTermsView:^{
//
//					         NSDictionary *parameters = @{
//					                 @"auth": @{
//					                         @"session":self->currentSession.session,
//					                         @"type": kMXLoginFlowTypeTerms
//							 }
//						 };
//					         callback(parameters, nil);
//					 }];
				}
				else
				{
					[self prepareRegisterParameters:callback];
				}

				return;
			}
		}

		WLog(@"[AuthInputsView] updateAuthSessionWithCompletedStages failed");
		callback (nil, [NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:kString(@"not_supported_yet")}]);
	}
}


- (void)registerStart {

	// Trigger here a register request in order to associate the filled userId and password to the current session id
	// This will check the availability of the userId at the same time
	[QMUITips showLoadingInView:self.view];


	NSDictionary *parameters = @{@"auth": @{},
	                             @"username": self.registerUserNameInput.text,
	                             @"password": self.registerPasswordInput.text,
	                             @"bind_email": @(NO),
	                             @"initial_device_display_name": @"Mobile"};

	self.mxCurrentOperation = [self.mxRestClient registerWithParameters:parameters success:^(NSDictionary *JSONResponse) {

	                                   [QMUITips hideAllTipsInView:self.view];
	                                   // Unexpected case where the registration succeeds without any other stages
	                                   MXLoginResponse *loginResponse;
	                                   MXJSONModelSetMXJSONModel(loginResponse, MXLoginResponse, JSONResponse);

	                                   MXCredentials *credentials = [[MXCredentials alloc] initWithLoginResponse:loginResponse
	                                                                 andDefaultCredentials:self.mxRestClient.credentials];

	                                   // Sanity check
	                                   if (!credentials.userId || !credentials.accessToken) {
						   [self onFailureDuringAuthRequest:[NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: [NSBundle mxk_localizedStringForKey:@"not_supported_yet"]}]];
					   } else {
						   WLog(@"[MXKAuthenticationVC] Registration succeeded");

						   // Report the certificate trusted by user (if any)
						   credentials.allowedCertificate = self.mxRestClient.allowedCertificate;

						   [self onSuccessfulLogin:credentials];
					   }

				   }                                                           failure:^(NSError *error) {
	                                   [QMUITips hideAllTipsInView:self.view];

	                                   self.mxCurrentOperation = nil;

	                                   // An updated authentication session should be available in response data in case of unauthorized request.
	                                   NSDictionary *JSONResponse = nil;
	                                   if (error.userInfo[MXHTTPClientErrorResponseDataKey]) {
						   JSONResponse = error.userInfo[MXHTTPClientErrorResponseDataKey];
					   }

	                                   if (JSONResponse) {
						   MXAuthenticationSession *authSession = [MXAuthenticationSession modelFromJSON:JSONResponse];

						   self.session = authSession.session;

						   // Update session identifier
//						   self.authInputsView.authSession.session = authSession.session;

						   // Launch registration by preparing parameters dict
						   [self prepareRegisterParameters:^(NSDictionary *parameters, NSError *error) {

						            if (parameters && self.mxRestClient) {

								    [self registerWithParameters:parameters];
							    } else {
								    WLog(@"[MXKAuthenticationVC] Failed to prepare parameters");
								    [self onFailureDuringAuthRequest:error];
							    }

						    }];
					   } else {
						   [self onFailureDuringAuthRequest:error];
					   }
				   }];
}

- (void)registrationTimerFireMethod:(NSTimer *)timer {
	if (timer == registrationTimer && timer.isValid) {
		WLog(@"[MXKAuthenticationVC] Retry registration");
		[self registerWithParameters:registrationTimer.userInfo];
	}
}


- (void)registerWithParameters:(NSDictionary *)parameters {

	// Add the device name
	NSMutableDictionary *theParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
	theParameters[@"initial_device_display_name"] = @"Mobile";

	self.mxCurrentOperation = [self.mxRestClient registerWithParameters:theParameters success:^(NSDictionary *JSONResponse) {

	                                   MXLoginResponse *loginResponse;
	                                   MXJSONModelSetMXJSONModel(loginResponse, MXLoginResponse, JSONResponse);

	                                   MXCredentials *credentials = [[MXCredentials alloc] initWithLoginResponse:loginResponse
	                                                                 andDefaultCredentials:self.mxRestClient.credentials];

	                                   // Sanity check
	                                   if (!credentials.userId || !credentials.accessToken) {
						   [self onFailureDuringAuthRequest:[NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: kString(@"not_supported_yet")}]];
					   } else {
						   WLog(@"[MXKAuthenticationVC] Registration succeeded");

						   // Report the certificate trusted by user (if any)
						   credentials.allowedCertificate = self.mxRestClient.allowedCertificate;

						   [self onSuccessfulLogin:credentials];
					   }

				   }                                                           failure:^(NSError *error) {

	                                   self.mxCurrentOperation = nil;

	                                   // Check whether the authentication is pending (for example waiting for email validation)
	                                   MXError *mxError = [[MXError alloc] initWithNSError:error];
	                                   if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringUnauthorized]) {
						   WLog(@"[MXKAuthenticationVC] Wait for email validation");
						   [QMUITips showLoading:kString(@"wait_for_email_validation") inView:self.view];
						   // Postpone a new attempt in 10 sec
						   self->registrationTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(registrationTimerFireMethod:) userInfo:parameters repeats:NO];
					   } else {
						   // The completed stages should be available in response data in case of unauthorized request.
						   NSDictionary *JSONResponse = nil;
						   if (error.userInfo[MXHTTPClientErrorResponseDataKey]) {
							   JSONResponse = error.userInfo[MXHTTPClientErrorResponseDataKey];
						   }

						   if (JSONResponse) {
							   MXAuthenticationSession *authSession = [MXAuthenticationSession modelFromJSON:JSONResponse];

							   if (authSession.completed) {
								   [QMUITips hideAllTipsInView:self.view];
//								   [self->_authenticationActivityIndicator stopAnimating];

								   // Update session identifier in case of change

//								   self.authInputsView.authSession.session = authSession.session;
								   self.session = authSession.session;
								   self.authSession.session = authSession.session;

								   [self updateAuthSessionWithCompletedStages:authSession.completed didUpdateParameters:^(NSDictionary *parameters, NSError *error) {
								            if (parameters && self.mxRestClient) {
										    [self registerWithParameters:parameters];
									    }
								    }];

								   return;
							   }

							   [self onFailureDuringAuthRequest:[NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: [NSBundle mxk_localizedStringForKey:@"not_supported_yet"]}]];
						   } else {
							   [self onFailureDuringAuthRequest:error];
						   }
					   }
				   }];
}

/**
   Check if a flow (kMXLoginFlowType*) has already been completed.

   @param flow the flow type to check.
   @return YES if the the flow has been completedd.
 */
- (BOOL)isFlowCompleted:(NSString *)flow {
	if (currentSession.completed && [currentSession.completed indexOfObject:flow] != NSNotFound) {
		return YES;
	}

	return NO;
}

- (void)prepareRegisterParameters:(void (^)(NSDictionary *parameters, NSError *error))callback {
	if (callback) {
		NSDictionary *parameters;
		if (self.registerEmailInput.text.length && ![self isFlowCompleted:kMXLoginFlowTypeEmailIdentity]) {
			WLog(@"[AuthInputsView] Prepare email identity stage");

			// Retrieve the REST client from delegate
			MXRestClient *restClient = self.mxRestClient;


			if (restClient) {
				MXWeakify(self);
				[self checkIdentityServerRequirement:restClient success:^(BOOL identityServerRequired) {
				         MXStrongifyAndReturnIfNil(self);

				         if (identityServerRequired && !restClient.identityServer) {
						 callback(nil, [NSError errorWithDomain:MXKAuthErrorDomain
						                code:0
						                userInfo:@{
						                        NSLocalizedDescriptionKey: kString(@"auth_email_is_required")
							  }]);
						 return;
					 }

				         // Check whether a second 3pid is available
//				         self->_isThirdPartyIdentifierPending = (self->nbPhoneNumber && ![self isFlowCompleted:kMXLoginFlowTypeMSISDN]);

				         // Launch email validation
				         self->submittedEmail = [[MXK3PID alloc] initWithMedium:kMX3PIDMediumEmail andAddress:self.registerEmailInput.text];

				         NSString *identityServer = restClient.identityServer;

				         [self->submittedEmail requestValidationTokenWithMatrixRestClient:restClient
				          isDuringRegistration:YES
				          nextLink:nil
				          success:^{
				                  NSMutableDictionary *threepidCreds = [NSMutableDictionary dictionaryWithDictionary:@{
				                                                                @"client_secret": self->submittedEmail.clientSecret,

				                                                                @"sid": self->submittedEmail.sid
						  }];
				                  if (identityServer) {
							  NSURL *identServerURL = [NSURL URLWithString:identityServer];
							  threepidCreds[@"id_server"] = identServerURL.host;
						  }

				                  NSDictionary *parameters;
				                  parameters = @{
				                          @"auth": @{
				                                  @"session": self->currentSession.session,
				                                  @"threepid_creds": threepidCreds,
				                                  @"type": kMXLoginFlowTypeEmailIdentity
							  },
				                          @"username": self.registerUserNameInput.text,
				                          @"password": self.registerPasswordInput.text,
						  };



//				                  self.messageLabel.text = NSLocalizedStringFromTable(@"auth_email_validation_message", @"Vector", nil);
//				                  self.messageLabel.hidden = NO;

				                  callback(parameters, nil);

					  }
				          failure:^(NSError *error) {

				                  WLog(@"[AuthInputsView] Failed to request email token");

				                  // Ignore connection cancellation error
				                  if (([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled)) {
							  return;
						  }

				                  // Translate the potential MX error.
				                  MXError *mxError = [[MXError alloc] initWithNSError:error];
				                  if (mxError && ([mxError.errcode isEqualToString:kMXErrCodeStringThreePIDInUse] || [mxError.errcode isEqualToString:kMXErrCodeStringServerNotTrusted])) {
							  NSMutableDictionary *userInfo;
							  if (error.userInfo) {
								  userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
							  } else {
								  userInfo = [NSMutableDictionary dictionary];
							  }

							  userInfo[NSLocalizedFailureReasonErrorKey] = nil;

							  if ([mxError.errcode isEqualToString:kMXErrCodeStringThreePIDInUse]) {
								  userInfo[NSLocalizedDescriptionKey] = kString(@"auth_email_in_use");
								  userInfo[@"error"] = kString(@"auth_email_in_use");
							  } else {
								  userInfo[NSLocalizedDescriptionKey] = kString(@"auth_untrusted_id_server");
								  userInfo[@"error"] = kString(@"auth_untrusted_id_server");
							  }

							  error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
						  }
				                  callback(nil, error);

					  }];
				 }                            failure:^(NSError *error) {
				         callback(nil, error);
				 }];

				// Async response
				return;
			}
			WLog(@"[AuthInputsView] Authentication failed during the email identity stage");
		} else if ([self isFlowSupported:kMXLoginFlowTypeRecaptcha] && ![self isFlowCompleted:kMXLoginFlowTypeRecaptcha]) {
			WLog(@"[AuthInputsView] Prepare reCaptcha stage");

//			[self displayRecaptchaForm:^(NSString *response) {
//
//			         if (response.length)
//				 {
//					 NSDictionary *parameters = @{
//					         @"auth": @{
//					                 @"session":currentSession.session,
//					                 @"response": response,
//					                 @"type": kMXLoginFlowTypeRecaptcha
//						 },
//					         @"username": self.userLoginTextField.text,
//					         @"password": self.passWordTextField.text,
//					 };
//
//					 callback(parameters, nil);
//				 }
//			         else
//				 {
//					 WLog(@"[AuthInputsView] reCaptcha stage failed");
//					 callback(nil, [NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[NSBundle mxk_localizedStringForKey:@"not_supported_yet"]}]);
//				 }
//
//			 }];
//
//			// Async response
//			return;
		} else if ([self isFlowSupported:kMXLoginFlowTypeDummy] && ![self isFlowCompleted:kMXLoginFlowTypeDummy]) {
			parameters = @{
			        @"auth": @{
			                @"session": currentSession.session,
			                @"type": kMXLoginFlowTypeDummy
				},
			        @"username": self.registerUserNameInput.text,
			        @"password": self.registerPasswordInput.text,
			};
		} else if ([self isFlowSupported:kMXLoginFlowTypePassword] && ![self isFlowCompleted:kMXLoginFlowTypePassword]) {
			// Note: this use case was not tested yet.
			parameters = @{
			        @"auth": @{
			                @"session": currentSession.session,
			                @"username": self.registerUserNameInput.text,
			                @"password": self.registerPasswordInput.text,
			                @"type": kMXLoginFlowTypePassword
				}
			};
		} else if ([self isFlowSupported:kMXLoginFlowTypeTerms] && ![self isFlowCompleted:kMXLoginFlowTypeTerms]) {
			WLog(@"[AuthInputsView] Prepare terms stage");

			MXWeakify(self);
//			[self displayTermsView:^{
//			         MXStrongifyAndReturnIfNil(self);
//
//			         NSDictionary *parameters = @{
//			                 @"auth": @{
//			                         @"session":self->currentSession.session,
//			                         @"type": kMXLoginFlowTypeTerms
//					 },
//			                 @"username": self.userLoginTextField.text,
//			                 @"password": self.passWordTextField.text
//				 };
//			         callback(parameters, nil);
//			 }];
//
//			// Async response
//			return;
		}

//		NSDictionary *parameters;
//		parameters = @{
//		        @"auth": @{
//		                @"session":self.session,
//		                @"type": kMXLoginFlowTypeDummy
//			},
//		        @"username": self.registerUserNameInput.text,
//		        @"password": self.registerPasswordInput.text,
//		};
//		callback(parameters, nil);
		callback(parameters, nil);
	}
}

- (void)signInButtonClicked {

	if (self.userNameInput.text.length < userNameLengthLimit || self.passwordInput.text.length < 6) {
		return;
	}

	[QMUITips showLoadingInView:self.view];
	NSString *errorMsg = [self checkBeforeLogin];
	if (errorMsg != nil) {
		[self onFailureDuringAuthRequest:[NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: errorMsg}]];
		return;
	}

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
	                                   if (!credentials.userId || !credentials.accessToken) {
						   [self onFailureDuringAuthRequest:[NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: kString(@"not_supported_yet")}]];
					   } else {
						   WLog(@"[MXKAuthenticationVC] Login process succeeded");

						   // Report the certificate trusted by user (if any)
						   credentials.allowedCertificate = self.mxRestClient.allowedCertificate;

						   [self onSuccessfulLogin:credentials];
					   }
				   }                                          failure:^(NSError *error) {
	                                   [QMUITips hideAllTips];
	                                   [self onFailureDuringAuthRequest:error];
				   }];

}

- (void)loginSuccess {
	self.mxCurrentOperation = nil;
	VTMainTabBarController *mainTabBarController = [[VTMainTabBarController alloc] init];
	mainTabBarController.modalPresentationStyle = UIModalPresentationFullScreen;
	[self presentViewController:mainTabBarController animated:YES completion:nil];
}

- (void)didLogWithUserId:(NSString *)userId {
	MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:userId];
	MXSession *session = account.mxSession;

	BOOL botCreationEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"enableBotCreation"];
	// Create DM with Riot-bot on new account creation.
	if (self.authType == MXKAuthenticationTypeRegister && botCreationEnabled) {

		MXRoomCreationParameters *roomCreationParameters = [MXRoomCreationParameters parametersForDirectRoomWithUser:@"@riot-bot:matrix.org"];
		[session createRoomWithParameters:roomCreationParameters success:nil failure:^(NSError *error) {
		         WLog(@"[AuthenticationVC] Create chat with riot-bot failed");
		 }];
	}

	// Wait for session change to present complete security screen if needed
	[self registerSessionStateChangeNotificationForSession:session];

	[self loginSuccess];
}

- (void)onSuccessfulLogin:(MXCredentials *)credentials {
	self.mxCurrentOperation = nil;

	if (self.softLogoutCredentials) {
		// Hydrate the account with the new access token
		MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:self.softLogoutCredentials.userId];
		[[MXKAccountManager sharedManager] hydrateAccount:account withCredentials:credentials];
		[self didLogWithUserId:credentials.userId];

	}
	// Sanity check: check whether the user is not already logged in with this id
	else if ([[MXKAccountManager sharedManager] accountForUserId:credentials.userId]) {
		[QMUITips showError:kString(@"login_error_already_logged_in") inView:self.view hideAfterDelay:2.0];
	} else {
		// Report the new account in account manager
		if (!credentials.identityServer) {
//			credentials.identityServer = _identityServerTextField.text;
		}
		MXKAccount *account = [[MXKAccount alloc] initWithCredentials:credentials];
		account.identityServerURL = credentials.identityServer;

		[[MXKAccountManager sharedManager] addAccount:account andOpenSession:YES];

		[self didLogWithUserId:credentials.userId];
	}
}

- (void)registerSessionStateChangeNotificationForSession:(MXSession *)session {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionStateDidChangeNotification:) name:kMXSessionStateDidChangeNotification object:session];
}

- (void)sessionStateDidChangeNotification:(NSNotification *)notification {
	MXSession *session = (MXSession *) notification.object;

	if (session.state == MXSessionStateStoreDataReady) {
		if (session.crypto.crossSigning) {
			// Do not make key share requests while the "Complete security" is not complete.
			// If the device is self-verified, the SDK will restore the existing key backup.
			// Then, it  will re-enable outgoing key share requests
			[session.crypto setOutgoingKeyRequestsEnabled:NO onComplete:nil];
		}
	} else if (session.state == MXSessionStateRunning) {
		[self unregisterSessionStateChangeNotification];

		if (session.crypto.crossSigning) {
			[session.crypto.crossSigning refreshStateWithSuccess:^(BOOL stateUpdated) {

			         WLog(@"[AuthenticationVC] sessionStateDidChange: crossSigning.state: %@", @(session.crypto.crossSigning.state));

			         switch (session.crypto.crossSigning.state) {
				 case MXCrossSigningStateNotBootstrapped: {
					 // TODO: This is still not sure we want to disable the automatic cross-signing bootstrap
					 // if the admin disabled e2e by default.
					 // Do like riot-web for the moment
					 if ([session vc_homeserverConfiguration].isE2EEByDefaultEnabled) {
						 // Bootstrap cross-signing on user's account
						 // We do it for both registration and new login as long as cross-signing does not exist yet
						 if (self.passwordInput.text.length) {
							 WLog(@"[AuthenticationVC] sessionStateDidChange: Bootstrap with password");

							 [session.crypto.crossSigning setupWithPassword:self.passwordInput.text success:^{
							          WLog(@"[AuthenticationVC] sessionStateDidChange: Bootstrap succeeded");

							  }                                      failure:^(NSError *_Nonnull error) {
							          WLog(@"[AuthenticationVC] sessionStateDidChange: Bootstrap failed. Error: %@", error);
							          [session.crypto setOutgoingKeyRequestsEnabled:YES onComplete:nil];

							  }];
						 } else {
							 // Try to setup cross-signing without authentication parameters in case if a grace period is enabled
//                                [self.crossSigningService setupCrossSigningWithoutAuthenticationFor:session success:^{
//                                    WLog(@"[AuthenticationVC] sessionStateDidChange: Bootstrap succeeded without credentials");
//                                    [self dismiss];
//                                } failure:^(NSError * _Nonnull error) {
//                                    WLog(@"[AuthenticationVC] sessionStateDidChange: Do not know how to bootstrap cross-signing. Skip it.");
//                                    [session.crypto setOutgoingKeyRequestsEnabled:YES onComplete:nil];
//                                    [self dismiss];
//                                }];
						 }
					 } else {
						 [session.crypto setOutgoingKeyRequestsEnabled:YES onComplete:nil];
//                            [self dismiss];
					 }
					 break;
				 }
				 case MXCrossSigningStateCrossSigningExists: {
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

			 }                                            failure:^(NSError *_Nonnull error) {
			         WLog(@"[AuthenticationVC] sessionStateDidChange: Fail to refresh crypto state with error: %@", error);
			         [session.crypto setOutgoingKeyRequestsEnabled:YES onComplete:nil];
//                [self dismiss];
			 }];
		} else {
//            [self dismiss];
		}
	}
}

- (void)showResourceLimitExceededError:(NSDictionary *)errorDict {
	WLog(@"[AuthenticationVC] showResourceLimitExceededError");

	[self showResourceLimitExceededError:errorDict onAdminContactTapped:^(NSURL *adminContactURL) {

	         [[UIApplication sharedApplication] vc_open:adminContactURL completionHandler:^(BOOL success) {
	                  if (!success) {
				  WLog(@"[AuthenticationVC] adminContact(%@) cannot be opened", adminContactURL);
			  }
		  }];
	 }];
}

- (void)unregisterSessionStateChangeNotification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionStateDidChangeNotification object:nil];
}


- (void)onFailureDuringAuthRequest:(NSError *)error {
	self.mxCurrentOperation = nil;

	// Ignore connection cancellation error
	if (([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled)) {
		WLog(@"[MXKAuthenticationVC] Auth request cancelled");
		return;
	}

	WLog(@"[MXKAuthenticationVC] Auth request failed: %@", error);

	// Cancel external registration parameters if any
	self.externalRegistrationParameters = nil;

	// Translate the error code to a human message
	NSString *title = error.localizedFailureReason;
	if (!title) {
		if (self.authType == MXKAuthenticationTypeLogin) {
			title = kString(@"login_error_title");
		} else if (self.authType == MXKAuthenticationTypeRegister) {
			title = kString(@"register_error_title");
		} else {
			title = kString(@"error");
		}
	}
	NSString *message = error.localizedDescription;
	NSDictionary *dict = error.userInfo;

	// detect if it is a Matrix SDK issue
	if (dict) {
		NSString *localizedError = [dict valueForKey:@"error"];
		NSString *errCode = [dict valueForKey:@"errcode"];

		if (localizedError.length > 0) {
			message = localizedError;
		}

		if (errCode) {
			if ([errCode isEqualToString:kMXErrCodeStringForbidden]) {
				message = kString(@"login_error_forbidden");
			} else if ([errCode isEqualToString:kMXErrCodeStringUnknownToken]) {
				message = kString(@"login_error_unknown_token");
			} else if ([errCode isEqualToString:kMXErrCodeStringBadJSON]) {
				message = kString(@"login_error_bad_json");
			} else if ([errCode isEqualToString:kMXErrCodeStringNotJSON]) {
				message = kString(@"login_error_not_json");
			} else if ([errCode isEqualToString:kMXErrCodeStringLimitExceeded]) {
				message = kString(@"login_error_limit_exceeded");
			} else if ([errCode isEqualToString:kMXErrCodeStringUserInUse]) {
				message = kString(@"login_error_user_in_use");
			} else if ([errCode isEqualToString:kMXErrCodeStringLoginEmailURLNotYet]) {
				message = kString(@"login_error_login_email_not_yet");
			} else if ([errCode isEqualToString:kMXErrCodeStringResourceLimitExceeded]) {
				[self showResourceLimitExceededError:dict onAdminContactTapped:nil];
				return;
			} else if (!message.length) {
				message = errCode;
			}
		}
	}

	[QMUITips showError:message inView:self.view hideAfterDelay:2.0];
	[self setAuthSession:self.authSession withAuthType:_authType];
	// Update authentication inputs view to return in initial step
//	[self.authInputsView setAuthSession:self.authInputsView.authSession withAuthType:_authType];
//	if (self.softLogoutCredentials)
//	{
//		self.authInputsView.softLogoutCredentials = self.softLogoutCredentials;
//	}
}

- (void)showResourceLimitExceededError:(NSDictionary *)errorDict onAdminContactTapped:(void (^)(NSURL *adminContact))onAdminContactTapped {
	self.mxCurrentOperation = nil;


	// Parse error data
	NSString *limitType, *adminContactString;
	NSURL *adminContact;

	MXJSONModelSetString(limitType, errorDict[kMXErrorResourceLimitExceededLimitTypeKey]);
	MXJSONModelSetString(adminContactString, errorDict[kMXErrorResourceLimitExceededAdminContactKey]);

	if (adminContactString) {
		adminContact = [NSURL URLWithString:adminContactString];
	}

	NSString *title = kString(@"login_error_resource_limit_exceeded_title");

	// Build the message content
	NSMutableString *message = [NSMutableString new];
	if ([limitType isEqualToString:kMXErrorResourceLimitExceededLimitTypeMonthlyActiveUserValue]) {
		[message appendString:kString(@"login_error_resource_limit_exceeded_message_monthly_active_user")];
	} else {
		[message appendString:kString(@"login_error_resource_limit_exceeded_message_default")];
	}

	[message appendString:kString(@"login_error_resource_limit_exceeded_message_contact")];


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
- (void)updateRESTClient {
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
							     NSString *title = kString(@"ssl_could_not_verify");
							     NSString *homeserverURLStr = [NSString stringWithFormat:kString(@"ssl_homeserver_url"), self.homeServerUrl];
							     NSString *fingerprint = [NSString stringWithFormat:kString(@"ssl_fingerprint_hash"), @"SHA256"];
							     NSString *certFingerprint = [certificate mx_SHA256AsHexString];

							     NSString *msg = [NSString stringWithFormat:@"%@\n\n%@\n\n%@\n\n%@\n\n%@\n\n%@", kString(@"ssl_cert_not_trust"), kString(@"ssl_cert_new_account_expl"), homeserverURLStr, fingerprint, certFingerprint, kString(@"ssl_only_accept")];
							     dispatch_async(dispatch_get_main_queue(), ^{
										    [QMUITips showError:msg inView:self.view hideAfterDelay:2];
									    });
							     dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
							     if (!isTrusted) {
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

- (void)setOnUnrecognizedCertificateBlock:(MXHTTPClientOnUnrecognizedCertificate)onUnrecognizedCertificateBlock {
	self.onUnrecognizedCertificateCustomBlock = onUnrecognizedCertificateBlock;
}


#pragma mark - AuthView Methods

- (MXRestClient *)authInputsViewThirdPartyIdValidationRestClient:(UIView *)authInputsView
{
	return self.mxRestClient;
}

- (BOOL)setExternalRegistrationParameters:(NSDictionary *)registrationParameters
{
	// Presently we only support a registration based on next_link associated to a successful email validation.
	NSString *homeserverURL;
	NSString *identityURL;

	// Check the current authentication type
	if (self.authType != MXKAuthenticationTypeRegister)
	{
		WLog(@"[AuthInputsView] setExternalRegistrationParameters failed: wrong auth type");
		return NO;
	}

	// Retrieve the REST client from delegate
	MXRestClient *
	        restClient = [self authInputsViewThirdPartyIdValidationRestClient:self.view];


	if (restClient)
	{
		// Sanity check on homeserver
		id hs_url = registrationParameters[@"hs_url"];
		if (hs_url && [hs_url isKindOfClass:NSString.class])
		{
			homeserverURL = hs_url;

			if ([homeserverURL isEqualToString:restClient.homeserver] == NO)
			{
				WLog(@"[AuthInputsView] setExternalRegistrationParameters failed: wrong homeserver URL");
				return NO;
			}
		}

		// Sanity check on identity server
		id is_url = registrationParameters[@"is_url"];
		if (is_url && [is_url isKindOfClass:NSString.class])
		{
			identityURL = is_url;

			if ([identityURL isEqualToString:restClient.identityServer] == NO)
			{
				WLog(@"[AuthInputsView] setExternalRegistrationParameters failed: wrong identity server URL");
				return NO;
			}
		}
	}
	else
	{
		WLog(@"[AuthInputsView] setExternalRegistrationParameters failed: not supported");
		return NO;
	}

	// Retrieve other parameters
	NSString *clientSecret;
	NSString *sid;
	NSString *sessionId;

	id value = registrationParameters[@"client_secret"];
	if (value && [value isKindOfClass:NSString.class])
	{
		clientSecret = value;
	}
	value = registrationParameters[@"sid"];
	if (value && [value isKindOfClass:NSString.class])
	{
		sid = value;
	}
	value = registrationParameters[@"session_id"];
	if (value && [value isKindOfClass:NSString.class])
	{
		sessionId = value;
	}

	// Check validity of the required parameters
	if (!homeserverURL.length || !clientSecret.length || !sid.length || !sessionId.length)
	{
		WLog(@"[AuthInputsView] setExternalRegistrationParameters failed: wrong parameters");
		return NO;
	}

	// Prepare the registration parameters (Ready to use)

	NSMutableDictionary *threepidCreds = [NSMutableDictionary dictionaryWithDictionary:@{
	                                              @"client_secret": clientSecret,

	                                              @"sid": sid
	}];
	if (identityURL)
	{
		NSURL *identServerURL = [NSURL URLWithString:identityURL];
		threepidCreds[@"id_server"] = identServerURL.host;
	}

	_externalRegistrationParameters = @{
	        @"auth": @{
	                @"session": sessionId,
	                @"threepid_creds": threepidCreds,
	                @"type": kMXLoginFlowTypeEmailIdentity
		},
	};

	// Hide all inputs by default


	return YES;
}

- (void)onReachabilityStatusChange:(NSNotification *)notif {
	AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
	AFNetworkReachabilityStatus status = reachabilityManager.networkReachabilityStatus;

	if (status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self refreshAuthenticationSession];
		});
	} else if (status == AFNetworkReachabilityStatusNotReachable) {
		[QMUITips showError:kString(@"network_error_not_reachable") inView:self.view hideAfterDelay:2.0];
	}
}

- (void)onFailureDuringMXOperation:(NSError *)error {
	self.mxCurrentOperation = nil;

	if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
		// Ignore this error
		WLog(@"[MXKAuthenticationVC] flows request cancelled");
		return;
	}

	WLog(@"[MXKAuthenticationVC] Failed to get %@ flows: %@", (_authType == MXKAuthenticationTypeLogin ? @"Login" : @"Register"), error);

	// Cancel external registration parameters if any
	_externalRegistrationParameters = nil;

	// Alert user
	NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
	if (!title) {
		title = kString(@"error");
	}
	NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];

	[QMUITips showError:msg inView:self.view hideAfterDelay:2.0];

	// Handle specific error code here
	if ([error.domain isEqualToString:NSURLErrorDomain]) {
		// Check network reachability
		if (error.code == NSURLErrorNotConnectedToInternet) {
			// Add reachability observer in order to launch a new request when network will be available
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReachabilityStatusChange:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
		} else if (error.code == kCFURLErrorTimedOut) {
			// Send a new request in 2 sec
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[self refreshAuthenticationSession];
			});
		} else {
			// Remove the potential auth inputs view
//			self.authInputsView = nil;
		}
	} else {
		// Remove the potential auth inputs view
//		self.authInputsView = nil;
	}

//	if (!_authInputsView)
//	{
//		// Display failure reason
//		_noFlowLabel.hidden = NO;
//		_noFlowLabel.text = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
//		if (!_noFlowLabel.text.length)
//		{
//			_noFlowLabel.text = [NSBundle mxk_localizedStringForKey:@"login_error_no_login_flow"];
//		}
//		[_retryButton setTitle:[NSBundle mxk_localizedStringForKey:@"retry"] forState:UIControlStateNormal];
//		[_retryButton setTitle:[NSBundle mxk_localizedStringForKey:@"retry"] forState:UIControlStateNormal];
//		_retryButton.hidden = NO;
//	}
}

- (void)handleAuthenticationSession:(MXAuthenticationSession *)authSession {
	self.mxCurrentOperation = nil;


	// Check whether fallback is defined, and retrieve the right input view class.
	Class authInputsViewClass;
	if (_authType == MXKAuthenticationTypeLogin) {
//        authenticationFallback = [mxRestClient loginFallback];
//        authInputsViewClass = loginAuthInputsViewClass;

	} else if (_authType == MXKAuthenticationTypeRegister) {
//        authenticationFallback = [mxRestClient registerFallback];
//        authInputsViewClass = registerAuthInputsViewClass;
	} else {
		// Not supported for other types
		WLog(@"[MXKAuthenticationVC] handleAuthenticationSession is ignored");
		return;
	}

	MXKAuthInputsView *authInputsView = nil;

	// Apply authentication session on inputs view
	if ([self setAuthSession:authSession withAuthType:_authType] == NO) {
		WLog(@"[MXKAuthenticationVC] Received authentication settings are not supported");
//            authInputsView = nil;
	} else if (!_softLogoutCredentials) {
		// If all listed flows in this authentication session are not supported we suggest using the fallback page.
//            if (authenticationFallback.length && authInputsView.authSession.flows.count == 0)
//            {
//                WLog(@"[MXKAuthenticationVC] No supported flow, suggest using fallback page");
//                authInputsView = nil;
//            }
//            else if (authInputsView.authSession.flows.count != authSession.flows.count)
//            {
//                WLog(@"[MXKAuthenticationVC] The authentication session contains at least one unsupported flow");
//            }
	}


//    if (authInputsView)
//    {
	// Check whether the current view must be replaced
//        if (self.authInputsView != authInputsView)
//        {
//            // Refresh layout
//            self.authInputsView = authInputsView;
//        }

	// Refresh user interaction
//        self.userInteractionEnabled = _userInteractionEnabled;

	// Check whether an external set of parameters have been defined to pursue a registration
//        if (self.externalRegistrationParameters)
//        {
//            if ([authInputsView setExternalRegistrationParameters:self.externalRegistrationParameters])
//            {
//                // Launch authentication now
//                [self onButtonPressed:_submitButton];
//            }
//            else
//            {
//                [self onFailureDuringAuthRequest:[NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[NSBundle mxk_localizedStringForKey:@"not_supported_yet"]}]];
//
//                _externalRegistrationParameters = nil;
//
//                // Restore login screen on failure
//                self.authType = MXKAuthenticationTypeLogin;
//            }
//        }
//
//        if (_softLogoutCredentials)
//        {
//            [authInputsView setSoftLogoutCredentials:_softLogoutCredentials];
//        }
//    }
//    else
//    {
//        // Remove the potential auth inputs view
//        self.authInputsView = nil;
//
//        // Cancel external registration parameters if any
//        _externalRegistrationParameters = nil;
//
//        // Notify user that no flow is supported
//        if (_authType == MXKAuthenticationTypeLogin)
//        {
//            _noFlowLabel.text = [NSBundle mxk_localizedStringForKey:@"login_error_do_not_support_login_flows"];
//        }
//        else
//        {
//            _noFlowLabel.text = [NSBundle mxk_localizedStringForKey:@"login_error_registration_is_not_supported"];
//        }
//        WLog(@"[MXKAuthenticationVC] Warning: %@", _noFlowLabel.text);
//
//        if (authenticationFallback.length)
//        {
//            [_retryButton setTitle:[NSBundle mxk_localizedStringForKey:@"login_use_fallback"] forState:UIControlStateNormal];
//            [_retryButton setTitle:[NSBundle mxk_localizedStringForKey:@"login_use_fallback"] forState:UIControlStateNormal];
//        }
//        else
//        {
//            [_retryButton setTitle:[NSBundle mxk_localizedStringForKey:@"retry"] forState:UIControlStateNormal];
//            [_retryButton setTitle:[NSBundle mxk_localizedStringForKey:@"retry"] forState:UIControlStateNormal];
//        }
//
//        _noFlowLabel.hidden = NO;
//        _retryButton.hidden = NO;
//    }
}

- (void)refreshAuthenticationSession {
	// Remove reachability observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];

	// Cancel potential request in progress
	[self.mxCurrentOperation cancel];
	self.mxCurrentOperation = nil;

	// Reset potential authentication fallback url
//    self.authenticationFallback = nil;

	if (self.mxRestClient) {
		if (_authType == MXKAuthenticationTypeLogin) {
			self.mxCurrentOperation = [self.mxRestClient getLoginSession:^(MXAuthenticationSession *authSession) {

			                                   [self handleAuthenticationSession:authSession];

						   }                                                    failure:^(NSError *error) {

			                                   [self onFailureDuringMXOperation:error];

						   }];
		} else if (_authType == MXKAuthenticationTypeRegister) {
			self.mxCurrentOperation = [self.mxRestClient getRegisterSession:^(MXAuthenticationSession *authSession) {

			                                   [self handleAuthenticationSession:authSession];

						   }                                                       failure:^(NSError *error) {

			                                   [self onFailureDuringMXOperation:error];

						   }];
		} else {
			// Not supported for other types
			WLog(@"[MXKAuthenticationVC] refreshAuthenticationSession is ignored");
		}
	}
}

- (void)setAuthType:(MXKAuthenticationType)authType {
	if (_authType != authType) {
		_authType = authType;

		// Cancel external registration parameters if any
		_externalRegistrationParameters = nil;
		isPasswordReseted = NO;
	}

	if (authType == MXKAuthenticationTypeLogin) {

		[self refreshAuthenticationSession];
	} else if (authType == MXKAuthenticationTypeRegister) {

		// Update supported authentication flow and associated information (defined in authentication session)
		[self refreshAuthenticationSession];
	} else if (authType == MXKAuthenticationTypeForgotPassword) {
//		_subTitleLabel.hidden = YES;

		if (isPasswordReseted) {

		} else {

//			[self refreshForgotPasswordSession];
		}
	}

	[self checkIdentityServer];
}

- (void)setIdentityServerTextFieldText:(NSString *)identityServerUrl {
//    _identityServerTextField.text = identityServerUrl;

	[self updateIdentityServerURL:identityServerUrl];
}

- (void)updateIdentityServerURL:(NSString *)url {
	if (![self.identityService.identityServer isEqualToString:url]) {
		if (url.length) {
			self.identityService = [[MXIdentityService alloc] initWithIdentityServer:url accessToken:nil andHomeserverRestClient:self.mxRestClient];
		} else {
			self.identityService = nil;
		}
	}

	[self.mxRestClient setIdentityServer:url.length ? url : nil];
}

- (void)checkIdentityServer {
	[self cancelIdentityServerCheck];

	// Hide the field while checking data
//    [self setIdentityServerHidden:YES];

	NSString *homeserver = self.mxRestClient.homeserver;

	// First, fetch the IS advertised by the HS
	if (homeserver) {
		WLog(@"[MXKAuthenticationVC] checkIdentityServer for homeserver %@", homeserver);

		autoDiscovery = [[MXAutoDiscovery alloc] initWithUrl:homeserver];

		MXWeakify(self);
		checkIdentityServerOperation = [autoDiscovery findClientConfig:^(MXDiscoveredClientConfig *_Nonnull discoveredClientConfig) {
		                                        MXStrongifyAndReturnIfNil(self);

		                                        NSString *identityServer = discoveredClientConfig.wellKnown.identityServer.baseUrl;
		                                        WLog(@"[MXKAuthenticationVC] checkIdentityServer: Identity server: %@", identityServer);

		                                        if (identityServer) {
								// Apply the provided IS
								[self setIdentityServerTextFieldText:identityServer];
							}

		                                        // Then, check if the HS needs an IS for running
		                                        MXWeakify(self);
		                                        MXHTTPOperation *operation = [self checkIdentityServerRequirementWithCompletion:^(BOOL identityServerRequired) {

		                                                                              MXStrongifyAndReturnIfNil(self);

		                                                                              self->checkIdentityServerOperation = nil;

		                                                                              // Show the field only if an IS is required so that the user can customise it
//		                                                                              [self setIdentityServerHidden:!identityServerRequired];
										      }];

		                                        if (operation) {
								[self->checkIdentityServerOperation mutateTo:operation];
							} else {
								self->checkIdentityServerOperation = nil;
							}

		                                        self->autoDiscovery = nil;

						}                                                      failure:^(NSError *error) {
		                                        MXStrongifyAndReturnIfNil(self);

		                                        // No need to report this error to the end user
		                                        // There will be already an error about failing to get the auth flow from the HS
		                                        WLog(@"[MXKAuthenticationVC] checkIdentityServer. Error: %@", error);

		                                        self->autoDiscovery = nil;
						}];
	}
}

- (void)cancelIdentityServerCheck {
	if (checkIdentityServerOperation) {
		[checkIdentityServerOperation cancel];
		checkIdentityServerOperation = nil;
	}
}

- (MXHTTPOperation *)checkIdentityServerRequirementWithCompletion:(void (^)(BOOL identityServerRequired))completion {
	MXHTTPOperation *operation;

	if (_authType == MXKAuthenticationTypeLogin) {
		// The identity server is only required for registration and password reset
		// It is then stored in the user account data
		completion(NO);
	} else {
		operation = [self.mxRestClient supportedMatrixVersions:^(MXMatrixVersions *matrixVersions) {

		                     WLog(@"[MXKAuthenticationVC] checkIdentityServerRequirement: %@", matrixVersions.doesServerRequireIdentityServerParam ? @"YES" : @"NO");
		                     completion(matrixVersions.doesServerRequireIdentityServerParam);

			     }                                              failure:^(NSError *error) {
		                     // No need to report this error to the end user
		                     // There will be already an error about failing to get the auth flow from the HS
		                     WLog(@"[MXKAuthenticationVC] checkIdentityServerRequirement. Error: %@", error);
			     }];
	}

	return operation;
}

- (BOOL)displayRecaptchaForm:(void (^)(NSString *response))callback {
	// Retrieve the site key
	NSString *siteKey;

	id recaptchaParams = currentSession.params[kMXLoginFlowTypeRecaptcha];
	if (recaptchaParams && [recaptchaParams isKindOfClass:NSDictionary.class]) {
		NSDictionary *recaptchaParamsDict = (NSDictionary *) recaptchaParams;
		siteKey = recaptchaParamsDict[@"public_key"];
	}

	// Retrieve the REST client from delegate
	MXRestClient *restClient = self.mxRestClient;
	// Sanity check
	if (siteKey.length && restClient && callback) {
//        [self hideInputsContainer];

//        self.messageLabel.hidden = NO;
//        self.messageLabel.text = kString(@"auth_recaptcha_message");

//        self.recaptchaContainer.hidden = NO;
//        self.currentLastContainer = self.recaptchaContainer;

		// IB does not support WKWebview in a xib before iOS 11
		// So, add it by coding

		// Do some cleaning/reset before
//        for (UIView *view in self.recaptchaContainer.subviews)
//        {
//            [view removeFromSuperview];
//        }

		MXKAuthenticationRecaptchaWebView *reCaptchaWebView = [MXKAuthenticationRecaptchaWebView new];
		reCaptchaWebView.translatesAutoresizingMaskIntoConstraints = NO;
//        [self.recaptchaContainer addSubview:reCaptchaWebView];

		// Disable the webview scrollView to avoid 2 scrollviews on the same screen
		reCaptchaWebView.scrollView.scrollEnabled = NO;
//
//        [self.recaptchaContainer addConstraints:
//         [NSLayoutConstraint constraintsWithVisualFormat:@"|-[view]-|"
//          options:0
//          metrics:0
//          views:@{
//                  @"view": reCaptchaWebView
//          }
//         ]
//        ];
//        [self.recaptchaContainer addConstraints:
//         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[view]-|"
//          options:0
//          metrics:0
//          views:@{
//                  @"view": reCaptchaWebView
//          }
//         ]
//        ];
//
//
//        [reCaptchaWebView openRecaptchaWidgetWithSiteKey:siteKey fromHomeServer:restClient.homeserver callback:callback];

		return YES;
	}

	return NO;
}

- (BOOL)setAuthSession:(MXAuthenticationSession *)authSession withAuthType:(MXKAuthenticationType)authType {
	if (authSession) {
		type = authType;
		currentSession = authSession;

		return YES;
	}

	return NO;
}

/**
   Check if a flow (kMXLoginFlowType*) is part of the required flows steps.

   @param flow the flow type to check.
   @return YES if the the flow must be implemented.
 */
- (BOOL)isFlowSupported:(NSString *)flow {
	for (MXLoginFlow *loginFlow in currentSession.flows) {
		if ([loginFlow.type isEqualToString:flow] || [loginFlow.stages indexOfObject:flow] != NSNotFound) {
			return YES;
		}
	}

	return NO;
}

- (void)checkIdentityServerRequirement:(MXRestClient *)mxRestClient
        success:(void (^)(BOOL identityServerRequired))success
        failure:(void (^)(NSError *error))failure {
	[mxRestClient supportedMatrixVersions:^(MXMatrixVersions *matrixVersions) {

	         WLog(@"[AuthInputsView] checkIdentityServerRequirement: %@", matrixVersions.doesServerRequireIdentityServerParam ? @"YES" : @"NO");
	         success(matrixVersions.doesServerRequireIdentityServerParam);

	 }                             failure:failure];
}


- (BOOL)areThirdPartyIdentifiersSupported {
	return ([self isFlowSupported:kMXLoginFlowTypeEmailIdentity] || [self isFlowSupported:kMXLoginFlowTypeMSISDN]);
}

- (BOOL)isThirdPartyIdentifierRequired {
	// Check first whether some 3pids are supported
	if (!self.areThirdPartyIdentifiersSupported) {
		return NO;
	}

	// Check whether an account may be created without third-party identifiers.
	for (MXLoginFlow *loginFlow in currentSession.flows) {
		if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeEmailIdentity] == NSNotFound
		    && [loginFlow.stages indexOfObject:kMXLoginFlowTypeMSISDN] == NSNotFound) {
			// There is a flow with no 3pids
			return NO;
		}
	}

	return YES;
}

- (BOOL)areAllThirdPartyIdentifiersRequired {
	// Check first whether some 3pids are required
	if (!self.isThirdPartyIdentifierRequired) {
		return NO;
	}

	BOOL isEmailIdentityFlowSupported = [self isFlowSupported:kMXLoginFlowTypeEmailIdentity];
	BOOL isMSISDNFlowSupported = [self isFlowSupported:kMXLoginFlowTypeMSISDN];

	for (MXLoginFlow *loginFlow in currentSession.flows) {
		if (isEmailIdentityFlowSupported) {
			if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeEmailIdentity] == NSNotFound) {
				return NO;
			} else if (isMSISDNFlowSupported) {
				if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeMSISDN] == NSNotFound) {
					return NO;
				}
			}
		} else if (isMSISDNFlowSupported) {
			if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeMSISDN] == NSNotFound) {
				return NO;
			}
		}
	}

	return YES;
}

#pragma mark - Lazyload

- (NSString *)homeServerUrl {
	if (nil == _homeServerUrl) {
		_homeServerUrl = defaultHomeServerUrl;
	}
	return _homeServerUrl;
}


@end
