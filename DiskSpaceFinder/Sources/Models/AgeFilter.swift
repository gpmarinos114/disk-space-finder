import Foundation

enum AgeFilter: Identifiable, Equatable {
    case all
    case olderThan(value: Int, unit: Calendar.Component)
    case unknown

    var id: String {
        switch self {
        case .all: return "all"
        case .olderThan(let value, let unit): return "olderThan_\(value)_\(unit)"
        case .unknown: return "unknown"
        }
    }

    var displayName: String {
        switch self {
        case .all: return "All Files"
        case .olderThan(let value, let unit):
            let unitName: String
            switch unit {
            case .day: unitName = value == 1 ? "Day" : "Days"
            case .month: unitName = value == 1 ? "Month" : "Months"
            case .year: unitName = value == 1 ? "Year" : "Years"
            default: unitName = "Days"
            }
            return "Older Than \(value) \(unitName)"
        case .unknown: return "Unknown Date"
        }
    }

    static func == (lhs: AgeFilter, rhs: AgeFilter) -> Bool {
        lhs.id == rhs.id
    }

    static var presets: [AgeFilter] {
        [
            .all,
            .olderThan(value: 7, unit: .day),
            .olderThan(value: 30, unit: .day),
            .olderThan(value: 90, unit: .day),
            .olderThan(value: 6, unit: .month),
            .olderThan(value: 1, unit: .year),
            .olderThan(value: 2, unit: .year),
            .unknown
        ]
    }
}
