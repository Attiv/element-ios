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

#import <Riot-Swift.h>
#import "VTSetupSecurityBackupViewController.h"
#import "SecurityViewController.h"

@interface VTSetupSecurityBackupViewController () <
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
	SettingsKeyBackupTableViewSectionDelegate,
	KeyBackupSetupCoordinatorBridgePresenterDelegate,
	KeyBackupRecoverCoordinatorBridgePresenterDelegate,
#endif
	UIDocumentInteractionControllerDelegate,
	SecretsRecoveryCoordinatorBridgePresenterDelegate,
	SecureBackupSetupCoordinatorBridgePresenterDelegate,
	SetPinCoordinatorBridgePresenterDelegate>
{
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
	SettingsKeyBackupTableViewSection *keyBackupSection;
	KeyBackupSetupCoordinatorBridgePresenter *keyBackupSetupCoordinatorBridgePresenter;
#endif
	KeyBackupRecoverCoordinatorBridgePresenter *keyBackupRecoverCoordinatorBridgePresenter;

	SecretsRecoveryCoordinatorBridgePresenter *secretsRecoveryCoordinatorBridgePresenter;
}

@property (nonatomic, strong) SecureBackupSetupCoordinatorBridgePresenter *secureBackupSetupCoordinatorBridgePresenter;
@property (nonatomic, strong) CrossSigningSetupCoordinatorBridgePresenter *crossSigningSetupCoordinatorBridgePresenter;
@property (nonatomic, strong) MXKeyBackupVersion *currentkeyBackupVersion;

@end

@implementation VTSetupSecurityBackupViewController

#pragma mark - Setup & Teardown

+ (SecurityViewController*)instantiateWithMatrixSession:(MXSession*)matrixSession
{
	SecurityViewController* viewController = [[UIStoryboard storyboardWithName:@"Security" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
	[viewController addMatrixSession:matrixSession];
	return viewController;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenW, kScreenH)];
	self.view = mainView;
	self.view.backgroundColor = [UIColor whiteColor];
	[self setupSecureBackup];
	// Do any additional setup after loading the view.
}

- (void)setupSecureBackup
{
	if (self.canSetupSecureBackup)
	{
		[self setupSecureBackup2];
	}
	else
	{
		// Set up cross-signing first
		[self setupCrossSigningWithTitle:NSLocalizedStringFromTable(@"secure_key_backup_setup_intro_title", @"Vector", nil)
		 message:NSLocalizedStringFromTable(@"security_settings_user_password_description", @"Vector", nil)
		 success:^{
		         [self setupSecureBackup2];
		 } failure:^(NSError *error) {
		 }];
	}
}

- (void)setupSecureBackup2
{
	SecureBackupSetupCoordinatorBridgePresenter *secureBackupSetupCoordinatorBridgePresenter = [[SecureBackupSetupCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];
	secureBackupSetupCoordinatorBridgePresenter.delegate = self;

	[secureBackupSetupCoordinatorBridgePresenter presentFrom:self animated:YES];

	self.secureBackupSetupCoordinatorBridgePresenter = secureBackupSetupCoordinatorBridgePresenter;
}

- (void)setupCrossSigningWithTitle:(NSString*)title
        message:(NSString*)message
        success:(void (^)(void))success
        failure:(void (^)(NSError *error))failure

{
	[self startActivityIndicator];

	MXWeakify(self);

	void (^animationCompletion)(void) = ^void () {
		MXStrongifyAndReturnIfNil(self);

		[self stopActivityIndicator];
		[self.crossSigningSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:^{}];
		self.crossSigningSetupCoordinatorBridgePresenter = nil;
	};

	CrossSigningSetupCoordinatorBridgePresenter *crossSigningSetupCoordinatorBridgePresenter = [[CrossSigningSetupCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];

	[crossSigningSetupCoordinatorBridgePresenter presentWith:title
	 message:message
	 from:self
	 animated:YES
	 success:^{
	         animationCompletion();
//	         [self reloadData];
	         success();
	 } cancel:^{
	         animationCompletion();
	         failure(nil);
	 } failure:^(NSError * _Nonnull error) {
	         animationCompletion();
//	         [self reloadData];
	         [[AppDelegate theDelegate] showErrorAsAlert:error];
	         failure(error);
	 }];

	self.crossSigningSetupCoordinatorBridgePresenter = crossSigningSetupCoordinatorBridgePresenter;
}

- (BOOL)canSetupSecureBackup
{
	// Accept to create a setup only if we have the 3 cross-signing keys
	// This is the path to have a sane state
	MXRecoveryService *recoveryService = self.mainSession.crypto.recoveryService;

	NSArray *crossSigningServiceSecrets = @[
		MXSecretId.crossSigningMaster,
		MXSecretId.crossSigningSelfSigning,
		MXSecretId.crossSigningUserSigning];

	return ([recoveryService.secretsStoredLocally mx_intersectArray:crossSigningServiceSecrets].count
	        == crossSigningServiceSecrets.count);
}

#pragma mark - KeyBackupRecoverCoordinatorBridgePresenter

- (void)showSecretsRecovery
{
	secretsRecoveryCoordinatorBridgePresenter = [[SecretsRecoveryCoordinatorBridgePresenter alloc] initWithSession:self.mainSession recoveryGoal:SecretsRecoveryGoalKeyBackup];

	[secretsRecoveryCoordinatorBridgePresenter presentFrom:self animated:true];
	secretsRecoveryCoordinatorBridgePresenter.delegate = self;
}

- (void)secretsRecoveryCoordinatorBridgePresenterDelegateDidCancel:(SecretsRecoveryCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
	[secretsRecoveryCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
	secretsRecoveryCoordinatorBridgePresenter = nil;
}

- (void)secretsRecoveryCoordinatorBridgePresenterDelegateDidComplete:(SecretsRecoveryCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
	UIViewController *presentedViewController = [coordinatorBridgePresenter toPresentable];

	if (coordinatorBridgePresenter.recoveryGoal == SecretsRecoveryGoalKeyBackup)
	{
		// Go to the true key backup recovery screen
		if ([presentedViewController isKindOfClass:UINavigationController.class])
		{
			UINavigationController *navigationController = (UINavigationController*)self.presentedViewController;
			[self pushKeyBackupRecover:self.currentkeyBackupVersion fromNavigationController:navigationController];
		}
		else
		{
			[self showKeyBackupRecover:self.currentkeyBackupVersion fromViewController:presentedViewController];
		}
	}
	else
	{
		[secretsRecoveryCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
		secretsRecoveryCoordinatorBridgePresenter = nil;
	}
}

#pragma mark - SecureBackupSetupCoordinatorBridgePresenterDelegate

- (void)secureBackupSetupCoordinatorBridgePresenterDelegateDidComplete:(SecureBackupSetupCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
	[self.secureBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
	self.secureBackupSetupCoordinatorBridgePresenter = nil;
}

- (void)secureBackupSetupCoordinatorBridgePresenterDelegateDidCancel:(SecureBackupSetupCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
	[self.secureBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
	self.secureBackupSetupCoordinatorBridgePresenter = nil;
}

#pragma mark - SetPinCoordinatorBridgePresenterDelegate

- (void)setPinCoordinatorBridgePresenterDelegateDidComplete:(SetPinCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
//	[self.tableView reloadData];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setPinCoordinatorBridgePresenterDelegateDidCancel:(SetPinCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
//	[self.tableView reloadData];
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KeyBackupRecoverCoordinatorBridgePresenter

- (void)showKeyBackupRecover:(MXKeyBackupVersion*)keyBackupVersion fromViewController:(UIViewController*)presentingViewController
{
	keyBackupRecoverCoordinatorBridgePresenter = [[KeyBackupRecoverCoordinatorBridgePresenter alloc] initWithSession:self.mainSession keyBackupVersion:keyBackupVersion];

	[keyBackupRecoverCoordinatorBridgePresenter presentFrom:presentingViewController animated:true];
	keyBackupRecoverCoordinatorBridgePresenter.delegate = self;
}

- (void)pushKeyBackupRecover:(MXKeyBackupVersion*)keyBackupVersion fromNavigationController:(UINavigationController*)navigationController
{
	keyBackupRecoverCoordinatorBridgePresenter = [[KeyBackupRecoverCoordinatorBridgePresenter alloc] initWithSession:self.mainSession keyBackupVersion:keyBackupVersion];

	[keyBackupRecoverCoordinatorBridgePresenter pushFrom:navigationController animated:YES];
	keyBackupRecoverCoordinatorBridgePresenter.delegate = self;
}

- (void)keyBackupRecoverCoordinatorBridgePresenterDidCancel:(KeyBackupRecoverCoordinatorBridgePresenter *)bridgePresenter {
	[keyBackupRecoverCoordinatorBridgePresenter dismissWithAnimated:true];
	keyBackupRecoverCoordinatorBridgePresenter = nil;
	secretsRecoveryCoordinatorBridgePresenter = nil;
}

- (void)keyBackupRecoverCoordinatorBridgePresenterDidRecover:(KeyBackupRecoverCoordinatorBridgePresenter *)bridgePresenter {
	[keyBackupRecoverCoordinatorBridgePresenter dismissWithAnimated:true];
	keyBackupRecoverCoordinatorBridgePresenter = nil;
	secretsRecoveryCoordinatorBridgePresenter = nil;
}


@end
