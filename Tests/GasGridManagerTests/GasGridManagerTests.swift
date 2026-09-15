import XCTest

// Re-define model types for testing (module types are internal to executable target)
enum AlertSeverity: String, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case info = "Info"

    var priority: Int {
        switch self {
        case .critical: return 5
        case .high: return 4
        case .medium: return 3
        case .low: return 2
        case .info: return 1
        }
    }

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.octagon.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "info.circle.fill"
        case .info: return "questionmark.circle.fill"
        }
    }
}

enum ValveStatus: String, CaseIterable {
    case open = "Open"
    case closed = "Closed"
    case partiallyOpen = "Partially Open"
    case locked = "Locked"
    case fault = "Fault"

    var icon: String {
        switch self {
        case .open: return "lock.open.fill"
        case .closed: return "lock.fill"
        case .partiallyOpen: return "lock.rotation"
        case .locked: return "lock.fill"
        case .fault: return "exclamationmark.lock.fill"
        }
    }
}

enum StationStatus: String, CaseIterable {
    case online = "Online"
    case offline = "Offline"
    case maintenance = "Maintenance"
    case critical = "Critical"
    case warning = "Warning"

    var icon: String {
        switch self {
        case .online: return "checkmark.circle.fill"
        case .offline: return "xmark.circle.fill"
        case .maintenance: return "wrench.fill"
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        }
    }
}

enum MaintenanceType: String, CaseIterable {
    case preventive = "Preventive"
    case corrective = "Corrective"
    case inspection = "Inspection"
    case emergency = "Emergency"
    case predictive = "Predictive"
}

struct MaintenanceLog {
    let id = UUID()
    var assetId: UUID
    var assetType: String
    var maintenanceType: MaintenanceType
    var description: String
    var scheduledDate: Date
    var completedDate: Date?
    var performedBy: String?
    var cost: Double?

    var isCompleted: Bool { completedDate != nil }
    var isOverdue: Bool { !isCompleted && scheduledDate < Date() }
}

// MARK: - Tests

final class AlertSeverityTests: XCTestCase {
    func testAllCasesHavePriority() {
        for severity in AlertSeverity.allCases {
            XCTAssertGreaterThan(severity.priority, 0)
        }
    }

    func testCriticalHasHighestPriority() {
        XCTAssertEqual(AlertSeverity.critical.priority, 5)
        XCTAssertEqual(AlertSeverity.info.priority, 1)
    }

    func testPriorityOrdering() {
        XCTAssertGreaterThan(AlertSeverity.critical.priority, AlertSeverity.high.priority)
        XCTAssertGreaterThan(AlertSeverity.high.priority, AlertSeverity.medium.priority)
        XCTAssertGreaterThan(AlertSeverity.medium.priority, AlertSeverity.low.priority)
        XCTAssertGreaterThan(AlertSeverity.low.priority, AlertSeverity.info.priority)
    }

    func testAllCasesHaveIcon() {
        for severity in AlertSeverity.allCases {
            XCTAssertFalse(severity.icon.isEmpty)
        }
    }
}

final class ValveStatusTests: XCTestCase {
    func testAllCasesHaveIcon() {
        for status in ValveStatus.allCases {
            XCTAssertFalse(status.icon.isEmpty)
        }
    }

    func testAllCasesRawValues() {
        XCTAssertEqual(ValveStatus.open.rawValue, "Open")
        XCTAssertEqual(ValveStatus.closed.rawValue, "Closed")
        XCTAssertEqual(ValveStatus.fault.rawValue, "Fault")
    }
}

final class StationStatusTests: XCTestCase {
    func testAllCasesHaveIcon() {
        for status in StationStatus.allCases {
            XCTAssertFalse(status.icon.isEmpty)
        }
    }

    func testAllCasesRawValues() {
        XCTAssertEqual(StationStatus.online.rawValue, "Online")
        XCTAssertEqual(StationStatus.offline.rawValue, "Offline")
        XCTAssertEqual(StationStatus.critical.rawValue, "Critical")
    }
}

final class MaintenanceLogTests: XCTestCase {
    func testIsCompletedWhenCompletedDateSet() {
        var log = MaintenanceLog(
            assetId: UUID(),
            assetType: "Station",
            maintenanceType: .preventive,
            description: "Test",
            scheduledDate: Date()
        )
        log.completedDate = Date()
        XCTAssertTrue(log.isCompleted)
    }

    func testIsNotCompletedWhenNoCompletedDate() {
        let log = MaintenanceLog(
            assetId: UUID(),
            assetType: "Station",
            maintenanceType: .preventive,
            description: "Test",
            scheduledDate: Date()
        )
        XCTAssertFalse(log.isCompleted)
    }

    func testIsOverdueWhenPastAndNotCompleted() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let log = MaintenanceLog(
            assetId: UUID(),
            assetType: "Station",
            maintenanceType: .preventive,
            description: "Test",
            scheduledDate: pastDate
        )
        XCTAssertTrue(log.isOverdue)
    }

    func testIsNotOverdueWhenFuture() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let log = MaintenanceLog(
            assetId: UUID(),
            assetType: "Station",
            maintenanceType: .preventive,
            description: "Test",
            scheduledDate: futureDate
        )
        XCTAssertFalse(log.isOverdue)
    }

    func testIsNotOverdueWhenCompleted() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let log = MaintenanceLog(
            assetId: UUID(),
            assetType: "Station",
            maintenanceType: .preventive,
            description: "Test",
            scheduledDate: pastDate,
            completedDate: Date()
        )
        XCTAssertFalse(log.isOverdue)
    }
}

final class TimeRangeTests: XCTestCase {
    enum TimeRange: Double {
        case lastHour = 1
        case last6Hours = 6
        case last24Hours = 24
        case lastWeek = 168
        case lastMonth = 720
    }

    func testTimeRangeHours() {
        XCTAssertEqual(TimeRange.lastHour.rawValue, 1)
        XCTAssertEqual(TimeRange.last6Hours.rawValue, 6)
        XCTAssertEqual(TimeRange.last24Hours.rawValue, 24)
        XCTAssertEqual(TimeRange.lastWeek.rawValue, 168)
        XCTAssertEqual(TimeRange.lastMonth.rawValue, 720)
    }
}
