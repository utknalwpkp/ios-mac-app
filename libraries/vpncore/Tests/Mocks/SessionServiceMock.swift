//
//  Created on 2022-06-16.
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
import VPNShared

class SessionServiceMock: SessionService {
    var sessionCookie: HTTPCookie? = nil
    var accountHost: URL = URL(string: "https://accountHost.com")!

    var getSelectorCallback: (Result<String, Error>)?

    func clientSessionId(forContext context: AppContext) -> String {
        return context.rawValue
    }

    func getSelector(clientId: String, independent: Bool, timeout: TimeInterval?) async throws -> String {
        switch getSelectorCallback {
        case .success(let selector):
            return selector
        case .failure(let error):
            throw error
        case .none:
            return "SELECTOR"
        }
    }
}
