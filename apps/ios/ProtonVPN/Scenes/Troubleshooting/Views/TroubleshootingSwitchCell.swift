//
//  TroubleshootingSwitchCell.swift
//  ProtonVPN - Created on 2020-04-27.
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

class TroubleshootingSwitchCell: TroubleshootingCell {
    
    // Views
    @IBOutlet private weak var toggleSwitch: UISwitch!

    var isOn: Bool {
        get {
            return toggleSwitch.isOn
        }
        set {
            toggleSwitch.isOn = newValue
        }
    }

    var isOnChanged: ((Bool) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        toggleSwitch.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
    }

    @objc private func switchChanged() {
        isOnChanged?(toggleSwitch.isOn)
    }
}
