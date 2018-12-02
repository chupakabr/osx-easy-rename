//
//  Localization.swift
//  EasyRename
//
//  Created by Valeriy Chevtaev on 02/12/2018.
//  Copyright © 2018 7bit. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
