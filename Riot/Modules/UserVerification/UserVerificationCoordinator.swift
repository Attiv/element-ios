// File created from FlowTemplate
// $ createRootCoordinator.sh UserVerification UserVerification
/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

@objcMembers
final class UserVerificationCoordinator: NSObject, UserVerificationCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let presenter: Presentable
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let userId: String
    private let userDisplayName: String?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: UserVerificationCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(presenter: Presentable, session: MXSession, userId: String, userDisplayName: String?) {
        self.presenter = presenter
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.userId = userId
        self.userDisplayName = userDisplayName
    }
    
    // MARK: - Public methods
    
    func start() {
        // Do not start again if existing coordinators are presented
        guard self.childCoordinators.isEmpty else {
            return
        }
        
        let rootCoordinator = UserVerificationSessionsStatusCoordinator(session: self.session, userId: self.userId)
        rootCoordinator.delegate = self
        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)
        
        self.navigationRouter.setRootModule(rootCoordinator, hideNavigationBar: true, animated: false, popCompletion: {
            self.remove(childCoordinator: rootCoordinator)
        })
        
        let rootViewController = self.navigationRouter.toPresentable()
        rootViewController.modalPresentationStyle = .formSheet
        
        self.presenter.toPresentable().present(rootViewController, animated: true, completion: nil)
      }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func presentSessionStatus(with deviceId: String, for userId: String, userDisplayName: String?) {
        let coordinator = UserVerificationSessionStatusCoordinator(session: self.session, userId: userId, userDisplayName: userDisplayName, deviceId: deviceId)
        coordinator.delegate = self
        coordinator.start()
        
        self.navigationRouter.push(coordinator, animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
    private func presentDeviceVerification(for deviceId: String) {
        
        let deviceVerificationCoordinator = DeviceVerificationCoordinator(navigationRouter: self.navigationRouter, session: self.session, userId: self.userId, otherDeviceId: deviceId)
        deviceVerificationCoordinator.delegate = self
        deviceVerificationCoordinator.start()
        
        self.add(childCoordinator: deviceVerificationCoordinator)
        
        self.navigationRouter.push(deviceVerificationCoordinator, animated: true, popCompletion: {
            self.remove(childCoordinator: deviceVerificationCoordinator)
        })
    }
}

// MARK: - UserVerificationSessionsStatusCoordinatorDelegate
extension UserVerificationCoordinator: UserVerificationSessionsStatusCoordinatorDelegate {
    func userVerificationSessionsStatusCoordinatorDidClose(_ coordinator: UserVerificationSessionsStatusCoordinatorType) {
        
        self.presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
    func userVerificationSessionsStatusCoordinator(_ coordinator: UserVerificationSessionsStatusCoordinatorType, didSelectDeviceWithId deviceId: String, for userId: String) {
        self.presentSessionStatus(with: deviceId, for: userId, userDisplayName: self.userDisplayName)
    }
}

// MARK: - UserVerificationSessionStatusCoordinatorDelegate
extension UserVerificationCoordinator: UserVerificationSessionStatusCoordinatorDelegate {
    
    func userVerificationSessionStatusCoordinator(_ coordinator: UserVerificationSessionStatusCoordinatorType, wantsToManuallyVerifyDeviceWithId deviceId: String, for userId: String) {
        
        self.presentDeviceVerification(for: deviceId)
    }
    
    func userVerificationSessionStatusCoordinatorDidClose(_ coordinator: UserVerificationSessionStatusCoordinatorType) {
        
        self.presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
}

// MARK: - UserVerificationCoordinatorDelegate
extension UserVerificationCoordinator: DeviceVerificationCoordinatorDelegate {
    
    func deviceVerificationCoordinatorDidComplete(_ coordinator: DeviceVerificationCoordinatorType, otherUserId: String, otherDeviceId: String) {
        self.presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
}
