//
//  AuthCredentials+vpncore.swift
//  Core
//
//  Created by Jaroslav on 2021-06-22.
//  Copyright © 2021 Proton Technologies AG. All rights reserved.
//

import Foundation
import ProtonCore_Networking

extension AuthCredentials {
    public func updatedWithAuth(auth: Credential) -> AuthCredentials {
        return AuthCredentials(version: VERSION, username: username, accessToken: auth.accessToken, refreshToken: auth.refreshToken, sessionId: sessionId, userId: userId, expiration: auth.expiration, scopes: auth.scope.compactMap({ AuthCredentials.Scope($0) }).filter({ $0 != .unknown }))
    }

    public convenience init(_ credential: Credential) {
        self.init(version: 0, username: credential.userName, accessToken: credential.accessToken, refreshToken: credential.refreshToken, sessionId: credential.UID, userId: credential.userID, expiration: credential.expiration, scopes: credential.scope.compactMap({ AuthCredentials.Scope($0) }).filter({ $0 != .unknown }))
    }
}

extension Credential {
    public init(_ credentials: AuthCredentials) {
        self.init(UID: credentials.sessionId, accessToken: credentials.accessToken, refreshToken: credentials.refreshToken, expiration: credentials.expiration, userName: credentials.username, userID: credentials.userId ?? "", scope: credentials.scopes.map({ $0.rawValue }))
    }
}
