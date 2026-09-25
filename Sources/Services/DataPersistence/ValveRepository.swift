import Foundation
import GRDB

final class ValveRepository: Sendable {
    private let dbManager = DatabaseManager.shared

    func insert(_ valve: Valve) throws {
        try dbManager.requireQueue().write { db in
            try valve.save(db)
        }
    }

    func update(_ valve: Valve) throws {
        try dbManager.requireQueue().write { db in
            try valve.update(db)
        }
    }

    func delete(_ valve: Valve) throws {
        try dbManager.requireQueue().write { db in
            try db.execute(sql: "DELETE FROM maintenanceLog WHERE assetId = ?", arguments: [valve.id])
            try valve.delete(db)
        }
    }

    func fetchAll() throws -> [Valve] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Valve.fetchAll(db)
        }
    }

    func fetchById(_ id: UUID) throws -> Valve? {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Valve.fetchOne(db, key: id)
        }
    }

    func fetchByStation(_ stationId: UUID) throws -> [Valve] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Valve.filter(Column("stationId") == stationId).fetchAll(db)
        }
    }
}

extension Valve: FetchableRecord, PersistableRecord {
    static let databaseTableName = "valve"
}
