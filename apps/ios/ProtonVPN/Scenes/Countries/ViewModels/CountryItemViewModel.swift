//
//  CountryItemViewModel.swift
//  ProtonVPN - Created on 01.07.19.
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

import UIKit
import vpncore
import Search
import ProtonCore_UIFoundations

class CountryItemViewModel {
    
    private let countryModel: CountryModel
    private let serverModels: [ServerModel]
    private let appStateManager: AppStateManager
    private let alertService: AlertService
    private var vpnGateway: VpnGatewayProtocol
    private var serverType: ServerType
    private let connectionStatusService: ConnectionStatusService
    private let planService: PlanService
    
    private var userTier: Int {
        do {
            return try vpnGateway.userTier()
        } catch {
            return CoreAppConstants.VpnTiers.free
        }
    }
    
    var isUsersTierTooLow: Bool {
        return userTier < countryModel.lowestTier
    }
    
    let propertiesManager: PropertiesManagerProtocol
    
    var underMaintenance: Bool {
        return !serverModels.contains { !$0.underMaintenance }
    }
    
    private var isConnected: Bool {
        if vpnGateway.connection == .connected, let activeServer = appStateManager.activeConnection()?.server, activeServer.countryCode == countryCode {
            return serverModels.contains(where: { $0 == activeServer })
        }

        return false
    }
    
    private var isConnecting: Bool {
        if let activeConnection = vpnGateway.lastConnectionRequest, vpnGateway.connection == .connecting, case ConnectionRequestType.country(let activeCountryCode, _) = activeConnection.connectionType, activeCountryCode == countryCode {
            return true
        }
        return false
    }
    
    private var connectedUiState: Bool {
        return isConnected || isConnecting
    }
    
    var connectionChanged: (() -> Void)?
    
    var countryCode: String {
        return countryModel.countryCode
    }
    
    var countryName: String {
        return LocalizationUtility.default.countryName(forCode: countryCode) ?? ""
    }
    
    var description: String {
        return LocalizationUtility.default.countryName(forCode: countryCode) ?? LocalizedString.unavailable
    }
    
    var backgroundColor: UIColor {
        return .backgroundColor()
    }

    var torAvailable: Bool {
        return countryModel.feature.contains(.tor)
    }
    
    var p2pAvailable: Bool {
        return countryModel.feature.contains(.p2p)
    }
    
    var isSmartAvailable: Bool {
        return serverModels.allSatisfy { $0.isVirtual }
    }
    
    var streamingAvailable: Bool {
        return !streamingServices.isEmpty
    }
    
    var isCurrentlyConnected: Bool {
        return isConnected || isConnecting
    }
    
    var connectIcon: UIImage? {
        if isUsersTierTooLow {
            return IconProvider.lock
        } else if underMaintenance {
            return IconProvider.wrench
        } else {
            return IconProvider.powerOff
        }
    }

    var streamingServices: [VpnStreamingOption] {
        return propertiesManager.streamingServices[countryCode]?["2"] ?? []
    }

    var partnerTypes: [PartnerType] {
        return propertiesManager.partnerTypes
    }
    
    var textInPlaceOfConnectIcon: String? {
        return isUsersTierTooLow ? LocalizedString.upgrade : nil
    }
    
    var alphaOfMainElements: CGFloat {
        if underMaintenance {
            return 0.25
        }

        if isUsersTierTooLow {
            return 0.5
        }

        return 1.0
    }
    
    private lazy var freeServerViewModels: [ServerItemViewModel] = {
        let freeServers = serverModels.filter { (serverModel) -> Bool in
            serverModel.tier == CoreAppConstants.VpnTiers.free
        }
        return serverViewModels(for: freeServers)
    }()
    
    private lazy var plusServerViewModels: [ServerItemViewModel] = {
        let plusServers = serverModels.filter({ (serverModel) -> Bool in
            serverModel.tier >= CoreAppConstants.VpnTiers.plus
        })
        return serverViewModels(for: plusServers)
    }()
    
    private func serverViewModels(for servers: [ServerModel]) -> [ServerItemViewModel] {
        return servers.map { (server) -> ServerItemViewModel in
            switch serverType {
            case .standard, .p2p, .tor, .unspecified:
                return ServerItemViewModel(serverModel: server, vpnGateway: vpnGateway, appStateManager: appStateManager,
                                           alertService: alertService, connectionStatusService: connectionStatusService, propertiesManager: propertiesManager, planService: planService)
            case .secureCore:
                return SecureCoreServerItemViewModel(serverModel: server, vpnGateway: vpnGateway, appStateManager: appStateManager,
                                                     alertService: alertService, connectionStatusService: connectionStatusService, propertiesManager: propertiesManager, planService: planService)
            }
        }
    }
    
    private lazy var serverViewModels = { () -> [(tier: Int, viewModels: [ServerItemViewModel])] in
        var serverTypes = [(tier: Int, viewModels: [ServerItemViewModel])]()
        if !freeServerViewModels.isEmpty {
            serverTypes.append((tier: 0, viewModels: freeServerViewModels))
        }
        if !plusServerViewModels.isEmpty {
            serverTypes.append((tier: 2, viewModels: plusServerViewModels))
        }
        
        serverTypes.sort(by: { (serverGroup1, serverGroup2) -> Bool in
            if userTier >= serverGroup1.tier && userTier >= serverGroup2.tier ||
               userTier < serverGroup1.tier && userTier < serverGroup2.tier { // sort within available then non-available groups
                return serverGroup1.tier > serverGroup2.tier
            } else {
                return serverGroup1.tier < serverGroup2.tier
            }
        })
        
        return serverTypes
    }()

    private lazy var cityItemViewModels: [CityViewModel] = {
        let servers = serverViewModels.flatMap({ $1 }).filter({ !$0.city.isEmpty })
        let groups = Dictionary(grouping: servers, by: { $0.city })
        return groups.map({
            let translatedCityName = $0.value.compactMap({ $0.translatedCity }).first
            return CityItemViewModel(cityName: $0.key, translatedCityName: translatedCityName, countryModel: self.countryModel, servers: $0.value, alertService: self.alertService, vpnGateway: self.vpnGateway, connectionStatusService: self.connectionStatusService)
        }).sorted(by: { $0.cityName < $1.cityName })
    }()
    
    init(countryGroup: CountryGroup, serverType: ServerType, appStateManager: AppStateManager, vpnGateway: VpnGatewayProtocol, alertService: AlertService, connectionStatusService: ConnectionStatusService, propertiesManager: PropertiesManagerProtocol, planService: PlanService) {
        self.countryModel = countryGroup.0
        self.serverModels = countryGroup.1
        self.appStateManager = appStateManager
        self.vpnGateway = vpnGateway
        self.alertService = alertService
        self.serverType = serverType
        self.connectionStatusService = connectionStatusService
        self.propertiesManager = propertiesManager
        self.planService = planService
        startObserving()
    }
    
    func serversCount(for section: Int) -> Int {
        return serverViewModels[section].viewModels.count
    }
    
    func sectionsCount() -> Int {
        return serverViewModels.count
    }
    
    func titleFor(section: Int) -> String {
        let tier = serverViewModels[section].tier
        return CoreAppConstants.serverTierName(forTier: tier) + " (\(self.serversCount(for: section)))"
    }

    func isServerPlusOrAbove( for section: Int) -> Bool {
        return serverViewModels[section].tier > CoreAppConstants.VpnTiers.basic
    }

    func isServerFree( for section: Int) -> Bool {
        return serverViewModels[section].tier == CoreAppConstants.VpnTiers.free
    }
    
    func cellModel(for row: Int, section: Int) -> ServerItemViewModel {
        return serverViewModels[section].viewModels[row]
    }
    
    func connectAction() {
        log.debug("Connect requested by clicking on Country item", category: .connectionConnect, event: .trigger)
        
        if isUsersTierTooLow {
            log.debug("Connect rejected because user plan is too low", category: .connectionConnect, event: .trigger)
            alertService.push(alert: AllCountriesUpsellAlert())
        } else if underMaintenance {
            log.debug("Connect rejected because server is in maintenance", category: .connectionConnect, event: .trigger)
            alertService.push(alert: MaintenanceAlert(countryName: countryName))
        } else if isConnected {
            log.debug("VPN is connected already. Will be disconnected.", category: .connectionDisconnect, event: .trigger)
            vpnGateway.disconnect()
        } else if isConnecting {
            log.debug("VPN is connecting. Will stop connecting.", category: .connectionDisconnect, event: .trigger)
            vpnGateway.stopConnecting(userInitiated: true)
        } else {
            log.debug("Will connect to country: \(countryCode) serverType: \(serverType)", category: .connectionConnect, event: .trigger)
            vpnGateway.connectTo(country: countryCode, ofType: serverType)
            connectionStatusService.presentStatusViewController()
        }
    }
    
    // MARK: - Private functions
    
    fileprivate func startObserving() {
        NotificationCenter.default.addObserver(self, selector: #selector(stateChanged),
                                               name: VpnGateway.connectionChanged, object: nil)
    }
    
    @objc fileprivate func stateChanged() {
        if let connectionChanged = connectionChanged {
            DispatchQueue.main.async {
                connectionChanged()
            }
        }
    }
}

extension CountryItemViewModel {
    func serversInformationViewModel() -> ServersInformationViewController.ViewModel {
        let freeServersRow: InformationTableViewCell.ViewModel = .init(title: LocalizedString.featureFreeServers,
                                                                       description: LocalizedString.featureFreeServersDescription,
                                                                       icon: .image(IconProvider.servers))
        var serverInformationViewModels: [InformationTableViewCell.ViewModel] = partnerTypes.map {
            .init(title: $0.type,
                  description: $0.description,
                  icon: .url($0.iconURL))
        }
        serverInformationViewModels.insert(freeServersRow, at: 0)
        let partners: [InformationTableViewCell.ViewModel] = partnerTypes.flatMap {
            $0.partners.map {
                .init(title: $0.name,
                      description: $0.description,
                      icon: .url($0.iconURL))
            }
        }
        var sections: [ServersInformationViewController.Section]
        sections = [.init(title: nil, rowViewModels: serverInformationViewModels)]
        if !partners.isEmpty {
            sections.append(.init(title: LocalizedString.dwPartner2022PartnersTitle, rowViewModels: partners))
        }

        return .init(title: LocalizedString.informationTitle, sections: sections)
    }
}

// MARK: - Search

extension CountryItemViewModel: CountryViewModel {
    func getServers() -> [ServerTier: [ServerViewModel]] {
        let convertTier = { (tier: Int) -> ServerTier in
            switch tier {
            case CoreAppConstants.VpnTiers.free:
                return .free
            case CoreAppConstants.VpnTiers.plus:
                return .plus
            default:
                return .plus
            }
        }

        return serverViewModels.reduce(into: [ServerTier: [ServerViewModel]]()) {
            $0[convertTier($1.tier)] = $1.viewModels
        }
    }

    func getCities() -> [CityViewModel] {
        return cityItemViewModels
    }

    var flag: UIImage? {
        return UIImage.flag(countryCode: countryCode)
    }

    var connectButtonColor: UIColor {
        if underMaintenance {
            return isUsersTierTooLow ? UIColor.weakInteractionColor() : .clear
        }
        return isCurrentlyConnected ? UIColor.interactionNorm() : UIColor.weakInteractionColor()
    }

    var textColor: UIColor {
        return UIColor.normalTextColor()
    }

    var isSecureCoreCountry: Bool {
        return serverModels.allSatisfy({ $0.serverType == .secureCore })
    }
}
