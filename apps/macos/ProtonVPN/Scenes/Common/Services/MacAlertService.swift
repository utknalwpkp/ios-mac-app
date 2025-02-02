//
//  MacAlertService.swift
//  ProtonVPN - Created on 27/08/2019.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonVPN.
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import vpncore
import AppKit
import Modals
import Modals_macOS

final class MacAlertService {
    
    typealias Factory = UIAlertServiceFactory & AppSessionManagerFactory & WindowServiceFactory & NotificationManagerFactory & UpdateManagerFactory & PropertiesManagerFactory & TroubleshootViewModelFactory & PlanServiceFactory & SessionServiceFactory
    private let factory: Factory
    
    private lazy var uiAlertService: UIAlertService = factory.makeUIAlertService()
    private lazy var appSessionManager: AppSessionManager = factory.makeAppSessionManager()
    private lazy var windowService: WindowService = factory.makeWindowService()
    private lazy var notificationManager: NotificationManagerProtocol = factory.makeNotificationManager()
    private lazy var updateManager: UpdateManager = factory.makeUpdateManager()
    private lazy var propertiesManager: PropertiesManagerProtocol = factory.makePropertiesManager()
    private lazy var planService: PlanService = factory.makePlanService()
    private lazy var sessionService: SessionService = factory.makeSessionService()
    
    private var lastTimeCheckMaintenance = Date(timeIntervalSince1970: 0)
    
    init(factory: Factory) {
        self.factory = factory
    }
    
}

extension MacAlertService: CoreAlertService {
    
    func push(alert: SystemAlert) {
        executeOnUIThread {
            self.pushOnUIThread(alert: alert)
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    func pushOnUIThread(alert: SystemAlert) {
        log.debug("Alert shown: \(String(describing: type(of: alert)))", category: .ui)
        
        switch alert {
        case let appUpdateRequiredAlert as AppUpdateRequiredAlert:
            show(appUpdateRequiredAlert)
            
        case let cannotAccessVpnCredentialsAlert as CannotAccessVpnCredentialsAlert:
            show(cannotAccessVpnCredentialsAlert)
            
        case is ExistingConnectionAlert:
            showDefaultSystemAlert(alert)
            
        case let firstTimeConnectingAlert as FirstTimeConnectingAlert:
            // Neagent popup is no longer an issue in macOS 10.15+, so we don't need to show the help anymore
            if #unavailable(OSX 10.15) {
                show(firstTimeConnectingAlert)
            }
            
        case is P2pBlockedAlert:
            showDefaultSystemAlert(alert)
            
        case let p2pForwardedAlert as P2pForwardedAlert:
            show(p2pForwardedAlert)
            
        case let refreshTokenExpiredAlert as RefreshTokenExpiredAlert:
            show(refreshTokenExpiredAlert)

        case let alert as AllCountriesUpsellAlert:
            let plus = AccountPlan.plus
            let countriesCount = planService.countriesCount
            let allCountriesUpsell = UpsellType.allCountries(numberOfDevices: plus.devicesCount, numberOfServers: plus.serversCount, numberOfCountries: countriesCount)
            show(alert: alert, upsellType: allCountriesUpsell)

        case let alert as ModerateNATUpsellAlert:
            show(alert: alert, upsellType: .moderateNAT)

        case let alert as SafeModeUpsellAlert:
            show(alert: alert, upsellType: .safeMode)

        case let alert as SecureCoreUpsellAlert:
            show(alert: alert, upsellType: .secureCore)

        case let alert as NetShieldUpsellAlert:
            show(alert: alert, upsellType: .netShield)

        case let alert as DiscourageSecureCoreAlert:
            show(alert)

        case is DelinquentUserAlert:
            showDefaultSystemAlert(alert)
            
        case is VpnStuckAlert:
            showDefaultSystemAlert(alert)
            
        case is VpnNetworkUnreachableAlert:
            showDefaultSystemAlert(alert)
            
        case is MaintenanceAlert:
            showDefaultSystemAlert(alert)
            
        case is LogoutWarningAlert:
            showDefaultSystemAlert(alert)
            
        case is BugReportSentAlert:
            showDefaultSystemAlert(alert)
            
        case is UnknownErrortAlert:
            showDefaultSystemAlert(alert)

        case is MITMAlert:
            showDefaultSystemAlert(alert)            
            
        case let killSwitchRequiresSwift5Alert as KillSwitchRequiresSwift5Alert:
            show(killSwitchRequiresSwift5Alert)           
            
        case is ClearApplicationDataAlert:
            showDefaultSystemAlert(alert)
            
        case is ActiveSessionWarningAlert:
            showDefaultSystemAlert(alert)
            
        case is QuitWarningAlert:
            showDefaultSystemAlert(alert)

        case is SecureCoreToggleDisconnectAlert:
            showDefaultSystemAlert(alert)
            
        case let vpnServerOnMaintenanceAlert as VpnServerOnMaintenanceAlert:
            show(vpnServerOnMaintenanceAlert)
            
        case is ReconnectOnNetshieldChangeAlert:
            showDefaultSystemAlert(alert)
            
        case is NetShieldRequiresUpgradeAlert:
            showDefaultSystemAlert(alert)

        case let connectionTroubleshootingAlert as ConnectionTroubleshootingAlert:
            show(connectionTroubleshootingAlert)

        case is UnreachableNetworkAlert:
            showDefaultSystemAlert(alert)
            
        case is SysexEnabledAlert:
            showDefaultSystemAlert(alert)
            
        case is SysexInstallingErrorAlert:
            showDefaultSystemAlert(alert)
            
        case let systemExtensionTourAlert as SystemExtensionTourAlert:
            show(systemExtensionTourAlert)
            
        case is ReconnectOnSettingsChangeAlert:
            showDefaultSystemAlert(alert)
            
        case let verificationAlert as UserVerificationAlert:
            show(verificationAlert)
            
        case is UserAccountUpdateAlert:
            showDefaultSystemAlert(alert)

        case is ReconnectOnSmartProtocolChangeAlert:
            showDefaultSystemAlert(alert)
            
        case is ReconnectOnActionAlert:
            showDefaultSystemAlert(alert)
            
        case is TurnOnKillSwitchAlert:
            showDefaultSystemAlert(alert)
            
        case is AllowLANConnectionsAlert:
            showDefaultSystemAlert(alert)

        case is VpnServerErrorAlert:
            showDefaultSystemAlert(alert)

        case is VpnServerSubscriptionErrorAlert:
            showDefaultSystemAlert(alert)
            
        case is VPNAuthCertificateRefreshErrorAlert:
            showDefaultSystemAlert(alert)

        case let announcementOfferAlert as AnnouncementOfferAlert:
            show(announcementOfferAlert)
            
        case let subuserAlert as SubuserWithoutConnectionsAlert:
            show(subuserAlert)
            
        case is TooManyCertificateRequestsAlert:
            showDefaultSystemAlert(alert)
            
        case is WireguardKSOnCatalinaAlert:
            showDefaultSystemAlert(alert)

        case let neKST2Alert as NEKSOnT2Alert:
            show(neKST2Alert)

        case is ProtonUnreachableAlert:
            showDefaultSystemAlert(alert)

        case is LocalAgentSystemErrorAlert:
            showDefaultSystemAlert(alert)

        default:
            #if DEBUG
            fatalError("Alert type handling not implemented: \(String(describing: alert))")
            #else
            showDefaultSystemAlert(alert)
            #endif
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    // MARK: Alerts UI
    
    private func showDefaultSystemAlert(_ alert: SystemAlert) {
        if alert.actions.isEmpty {
            alert.actions.append(AlertAction(title: LocalizedString.ok, style: .confirmative, handler: nil))
        }
        uiAlertService.displayAlert(alert)
    }
    
    // MARK: Custom Alerts
    
    private func show(_ alert: AppUpdateRequiredAlert) {
        let supportAction = AlertAction(title: LocalizedString.updateRequiredSupport, style: .confirmative) {
            SafariService().open(url: CoreAppConstants.ProtonVpnLinks.supportForm)
        }
        let updateAction = AlertAction(title: LocalizedString.updateRequiredUpdate, style: .confirmative) {
            self.updateManager.startUpdate()
        }
        
        alert.actions.append(supportAction)
        alert.actions.append(updateAction)
        
        uiAlertService.displayAlert(alert)
    }
    
    private func show(_ alert: CannotAccessVpnCredentialsAlert) {
        guard appSessionManager.sessionStatus == .established else { return } // already logged out
        appSessionManager.logOut(force: true, reason: LocalizedString.errorSignInAgain)
    }
    
    private func show(_ alert: FirstTimeConnectingAlert) {
        let neagentViewController = NeagentHelpPopUpViewController()
        windowService.presentKeyModal(viewController: neagentViewController)
    }

    private func show(_ alert: SystemExtensionTourAlert) {
        let viewModel = SystemExtensionGuideViewModel(extensionsCount: alert.extensionsCount,
                                                      userWasShownTourBefore: alert.userWasShownTourBefore,
                                                      alertService: self,
                                                      propertiesManager: propertiesManager,
                                                      cancelledHandler: alert.cancelHandler)
        windowService.openSystemExtensionGuideWindow(viewModel: viewModel)
    }
    
    private func show(_ alert: P2pForwardedAlert) {
        let p2pIcon = AppTheme.Icon.arrowsSwitch.asAttachment(size: .rect(width: 15, height: 12))
        
        let bodyP1 = (LocalizedString.p2pForwardedPopupBodyP1 + " ").styled(alignment: .natural)
        let bodyP2 = (" " + LocalizedString.p2pForwardedPopupBodyP2).styled(alignment: .natural)
        let body = NSAttributedString.concatenate(bodyP1, p2pIcon, bodyP2)
        
        alert.actions.append(AlertAction(title: LocalizedString.ok, style: .confirmative, handler: nil))
        
        uiAlertService.displayAlert(alert, message: body)
    }
    
    private func show(_ alert: RefreshTokenExpiredAlert) {
        appSessionManager.logOut(force: true, reason: LocalizedString.invalidRefreshTokenPleaseLogin)
    }

    private func show( _ alert: KillSwitchRequiresSwift5Alert ) {
        let killSwitch5ViewController = KillSwitchSwift5Popup()
        killSwitch5ViewController.alert = alert
        windowService.presentKeyModal(viewController: killSwitch5ViewController)
    }
    
    private func show(_ alert: VpnServerOnMaintenanceAlert) {
        guard self.lastTimeCheckMaintenance.timeIntervalSinceNow < -AppConstants.Time.maintenanceMessageTimeThreshold else {
            return
        }
        self.notificationManager.displayServerGoingOnMaintenance()
        self.lastTimeCheckMaintenance = Date()
    }

    private func show(_ alert: ConnectionTroubleshootingAlert) {
        let connectionTroubleshootingAlert = TroubleshootingPopup()
        connectionTroubleshootingAlert.viewModel = factory.makeTroubleshootViewModel()
        windowService.presentKeyModal(viewController: connectionTroubleshootingAlert)
    }
    
    private func show( _ alert: UserVerificationAlert) {
        alert.actions.append(AlertAction(title: LocalizedString.ok, style: .confirmative, handler: nil))
        showDefaultSystemAlert(alert)
    }
    
    private func show(alert: UpsellAlert, upsellType: UpsellType) {
        let factory = ModalsFactory(colors: UpsellColors())

        let upgradeAction: (() -> Void) = { [weak self] in
            Task { [weak self] in
                guard let url = await self?.sessionService.getPlanSession(mode: .upgrade) else {
                    return
                }
                SafariService.openLink(url: url)
            }
        }
        let upsellViewController = factory.upsellViewController(upsellType: upsellType, upgradeAction: upgradeAction, learnMoreAction: alert.learnMore)
        windowService.presentKeyModal(viewController: upsellViewController)
    }

    private func show(_ alert: AnnouncementOfferAlert) {
        guard let panelMode = alert.data.panelMode() else {
            log.warning("Couldn't determine panelMode from: \(alert.data)")
            return
        }
        let vc: NSViewController
        switch panelMode {
        case .legacy(let legacyPanel):
            vc = AnnouncementDetailViewController(legacyPanel)
        case .image(let imagePanel):
            vc = AnnouncementImageViewController(data: imagePanel, sessionService: sessionService)
        }

        windowService.presentKeyModal(viewController: vc)
    }
    
    private func show(_ alert: SubuserWithoutConnectionsAlert) {
        windowService.openSubuserAlertWindow()
    }

    private func show(_ alert: DiscourageSecureCoreAlert) {
        let factory = ModalsFactory(colors: UpsellColors())

        let viewController = factory.discourageSecureCoreViewController(onDontShowAgain: alert.onDontShowAgain, onActivate: alert.onActivate, onCancel: alert.dismiss, onLearnMore: alert.onLearnMore)
        windowService.presentKeyModal(viewController: viewController)
    }

    private func show(_ alert: NEKSOnT2Alert) {
        let vc = NET2WarningPopupViewController(viewModel: WarningPopupViewModel(alert: alert))
        windowService.presentKeyModal(viewController: vc)
    }
}
