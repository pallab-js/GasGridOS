import Foundation
import GRDB

final class AlertRepository: Sendable {
    private let dbManager = DatabaseManager.shared

    func insert(_ alert: Alert) throws {
        try dbManager.requireQueue().write { db in
            try alert.save(db)
        }
    }

    func update(_ alert: Alert) throws {
        try dbManager.requireQueue().write { db in
            try alert.update(db)
        }
    }

    func delete(_ alert: Alert) throws {
        try dbManager.requireQueue().write { db in
            try alert.delete(db)
        }
    }

    func fetchAll() throws -> [Alert] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Alert.fetchAll(db)
        }
    }

    func fetchUnacknowledged() throws -> [Alert] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Alert.filter(Column("isAcknowledged") == false).fetchAll(db)
        }
    }

    func fetchBySeverity(_ severity: AlertSeverity) throws -> [Alert] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Alert.filter(Column("severity") == severity.rawValue).fetchAll(db)
        }
    }

    func acknowledge(_ alertId: UUID) throws {
        try dbManager.requireQueue().write { db in
            if var alert = try Alert.fetchOne(db, key: alertId) {
                alert.isAcknowledged = true
                alert.acknowledgedDate = Date()
                try alert.update(db)
            }
        }
    }
}

extension Alert: FetchableRecord, PersistableRecord {
    static let databaseTableName = "alert"
}
