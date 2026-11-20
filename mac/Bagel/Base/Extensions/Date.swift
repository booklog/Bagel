//
//  Date.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 22.10.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa

extension Date {

    // Japanese style: year/month/day
    private static let readableFormat = "yyyy/MM/dd HH:mm:ss"
    var readable: String {
        return self.format(dateFormat: Date.readableFormat)
    }

    func format(dateFormat: String) -> String {

        let dateFormatter = DateFormatter()
        // Fixed formats need a fixed calendar/locale; otherwise e.g. the Japanese
        // calendar setting turns "yyyy" into the era year and a 12-hour setting can affect "HH".
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = dateFormat

        return dateFormatter.string(from: self)
    }
}
