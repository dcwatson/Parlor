//
//  DateUtils.swift
//  Parlor
//
//  Created by Daniel Watson on 5/30/25.
//

import Foundation

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

extension Date {
    func dateChanged(since: Date) -> Bool {
        dateFormatter.string(from: self) != dateFormatter.string(from: since)
    }

    func timeChanged(since: Date) -> Bool {
        timeFormatter.string(from: self) != timeFormatter.string(from: since)
    }
}
