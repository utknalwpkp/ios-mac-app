//
//  Created on 02.03.2022.
//
//  Copyright (c) 2022 Proton AG
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

import Foundation

protocol SearchViewModelDelegate: AnyObject {
    func statusDidChange(status: SearchStatus)
}

final class SearchViewModel {

    // MARK: Properties

    private let recentSearchesService: RecentSearchesService

    private(set) var status: SearchStatus {
        didSet {
            delegate?.statusDidChange(status: status)
        }
    }

    private let data: [CountryViewModel]
    private let mode: SearchMode
    private let constants: Constants

    weak var delegate: SearchViewModelDelegate?

    var numberOfServers: Int {
        return constants.numberOfCountries
    }

    init(recentSearchesService: RecentSearchesService, data: [CountryViewModel], constants: Constants, mode: SearchMode) {
        self.data = data
        self.recentSearchesService = recentSearchesService
        self.mode = mode
        self.constants = constants

        let recent = recentSearchesService.get()
        status = recent.isEmpty ? .placeholder : .recentSearches(recent)
    }

    // MARK: Actions

    func clearRecentSearches() {
        recentSearchesService.clear()
        status = .placeholder
    }

    func search(searchText: String) {
        guard !searchText.isEmpty else {
            let recent = recentSearchesService.get()
            status = recent.isEmpty ? .placeholder : .recentSearches(recent)
            return
        }

        status = .searching

        let filter = { (name: String) -> Bool in
            let normalizedSearchText = searchText.normalized
            let normalizedParts = name.components(separatedBy: CharacterSet.whitespaces).map({ $0.normalized })
            return normalizedParts.contains(where: { $0.starts(with: normalizedSearchText) })
        }

        var results: [SearchResult] = []
        let countries = data.filter({ filter($0.description) })

        switch mode {
        case .standard, .freeUser:
            if !countries.isEmpty {
                results.append(SearchResult.countries(countries: countries))
            }
            var servers: [ServerTier: [ServerViewModel]] = [:]
            for tier in ServerTier.allCases {
                servers[tier] = []
            }
            for country in data {
                let groups = country.getServers()
                for (key, values) in groups {
                    servers[key]?.append(contentsOf: values)
                }
            }
            for tier in servers.keys {
                let tierServers = servers[tier]?.filter({ filter($0.description) }) ?? []
                if !tierServers.isEmpty {
                    results.append(SearchResult.servers(tier: tier, servers: tierServers))
                }
            }
        case .secureCore:
            if !countries.isEmpty {
                let servers = countries.flatMap({ $0.getServers().flatMap { $0.1 } })
                results.append(SearchResult.secureCoreCountries(servers: servers))
            }
        }

        let freeSection = mode == .freeUser ? [SearchResult.upsell] : []
        status = results.isEmpty ? .noResults : .results(freeSection + results)
    }

    func saveSearch(searchText: String) {
        recentSearchesService.add(searchText: searchText)
    }
}
