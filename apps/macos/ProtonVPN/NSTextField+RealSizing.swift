//
//  NSTextField+RealSizing.swift
//  ProtonVPN - Created on 22/09/2020.
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

extension NSTextField {
    func realHeight( _ width: CGFloat ) -> CGFloat {
        let sizeTF = NSTextField()
        sizeTF.maximumNumberOfLines = maximumNumberOfLines
        sizeTF.font = font
        sizeTF.stringValue = stringValue
        sizeTF.attributedStringValue = attributedStringValue
        return sizeTF.sizeThatFits(NSSize(width: width, height: .infinity)).height
    }
}
