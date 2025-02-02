//
//  ConnectButton.swift
//  ProtonVPN - Created on 27.06.19.
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

import Cocoa
import vpncore

class ConnectButton: ResizingTextButton {
    
    override var title: String {
        didSet {
            needsDisplay = true
        }
    }
    
    var isConnected: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    var upgradeRequired: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    var nameForAccessibility: String? {
        didSet {
            needsDisplay = true
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureButton()
        setAccessibilityRole(.button)
    }
    
    override func viewWillDraw() {
        super.viewWillDraw()
        configureButton()
    }
    
    private func configureButton() {
        wantsLayer = true
        layer?.cornerRadius = AppTheme.ButtonConstants.cornerRadius
        layer?.borderWidth = 2
        layer?.backgroundColor = self.cgColor(.background)
        layer?.borderColor = self.cgColor(.border)

        let title: String
        if isConnected {
            title = isHovered ? LocalizedString.disconnect : LocalizedString.connected
            setAccessibilityLabel(String(format: "%@ %@", LocalizedString.disconnect, nameForAccessibility ?? ""))
        } else {
            title = upgradeRequired ? LocalizedString.upgrade : LocalizedString.connect
            setAccessibilityLabel(String(format: "%@ %@", title, nameForAccessibility ?? ""))
        }
        attributedTitle = title.styled(font: .themeFont(.small))
    }
}

extension ConnectButton: CustomStyleContext {
    func customStyle(context: AppTheme.Context) -> AppTheme.Style {
        if context == .text {
            return .normal
        }

        let defaultStyle: AppTheme.Style = context == .border ? .normal : .weak
        if isConnected {
            return isHovered ? .danger : defaultStyle
        } else {
            return isHovered ? .interactive : defaultStyle
        }
    }
}
