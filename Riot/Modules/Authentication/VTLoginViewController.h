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

#import "VTBaseViewController.h"
#import "MXKAuthInputsView.h"
#import <MXK3PID.h>

NS_ASSUME_NONNULL_BEGIN

@interface VTLoginViewController : VTBaseViewController {
	/**
	   The current email validation
	 */
	MXK3PID *submittedEmail;

	/**
	   The current msisdn validation
	 */
	MXK3PID *submittedMSISDN;

	/**
	    Identity Server discovery.
	 */
	MXAutoDiscovery *autoDiscovery;

	MXHTTPOperation *checkIdentityServerOperation;


	@protected
	/**
	   The authentication type (`MXKAuthenticationTypeLogin` by default).
	 */
	MXKAuthenticationType type;

	/**
	   The authentication session (nil by default).
	 */
	MXAuthenticationSession *currentSession;

	/**
	   Alert used to display inputs error.
	 */
	UIAlertController *inputsAlert;
	/**
	   Tell whether the password has been reseted with success.
	   Used to return on login screen on submit button pressed.
	 */
	BOOL isPasswordReseted;
	/**
	   The timer used to postpone the registration when the authentication is pending (for example waiting for email validation)
	 */
	NSTimer *registrationTimer;
	// successful login credentials
	MXCredentials *loginCredentials;

}
/**
   Tell whether some third-party identifiers may be added during the account registration.
 */
@property(nonatomic, readonly) BOOL areThirdPartyIdentifiersSupported;

/**
   Tell whether at least one third-party identifier is required to create a new account.
 */
@property(nonatomic, readonly) BOOL isThirdPartyIdentifierRequired;

/**
   Tell whether all the supported third-party identifiers are required to create a new account.
 */
@property(nonatomic, readonly) BOOL areAllThirdPartyIdentifiersRequired;

/**
   Update the registration inputs layout by hidding the third-party identifiers fields (YES by default).
   Set NO to show these fields and hide the others.
 */
@property(nonatomic, getter=isThirdPartyIdentifiersHidden) BOOL thirdPartyIdentifiersHidden;

/**
   Tell whether a second third-party identifier is waiting for being added to the new account.
 */
@property(nonatomic, readonly) BOOL isThirdPartyIdentifierPending;

/**
   Tell whether the flow requires a Single-Sign-On flow.
 */
@property(nonatomic, readonly) BOOL isSingleSignOnRequired;

- (MXRestClient *)authInputsViewThirdPartyIdValidationRestClient:(UIView *)authInputsView;
@end

NS_ASSUME_NONNULL_END
