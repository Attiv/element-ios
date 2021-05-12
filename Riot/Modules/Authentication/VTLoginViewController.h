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

#import <MatrixKit/MXKAuthenticationViewController.h>
#import "VTBaseViewController.h"
#import <MatrixKit/MatrixKit.h>

@protocol AuthenticationViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface VTLoginViewController : MXKAuthenticationViewController <MXKAuthenticationViewControllerDelegate>
// MXKAuthenticationViewController has already a `delegate` member
@property(nonatomic, weak) id <AuthenticationViewControllerDelegate> authVCDelegate;

- (void)showCustomHomeserver:(NSString *)homeserver andIdentityServer:(NSString *)identityServer;

/// When SSO login succeeded, when SFSafariViewController is used, continue login with success parameters.
/// @param loginToken The login token provided when SSO succeeded.
/// @param txnId transaction id generated during SSO page presentation.
/// returns YES if the SSO login can be continued.
- (BOOL)continueSSOLoginWithToken:(NSString *)loginToken txnId:(NSString *)txnId;
@end


@protocol VTLoginViewControllerDelegate <NSObject>

- (void)authenticationViewControllerDidDismiss:(VTLoginViewController *)authenticationViewController;

@end;
NS_ASSUME_NONNULL_END
