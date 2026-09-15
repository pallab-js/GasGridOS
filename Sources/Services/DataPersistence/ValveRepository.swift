import Foundation
import GRDB

final class ValveRepository {
    private let dbManager = DatabaseManager.shared

    func insert(_ valve: Valve) throws {
        guard let dbQueue = dbManager.dbQueue else { return }
        try dbQueue.write { db in
            try valve.save(db)
        }
    }

    func update(_ valve: Valve) throws {
        guard let dbQueue = dbManager.dbQueue else { return }
        try dbQueue.write { db in
            try valve.update(db)
        }
    }

    func delete(_ valve: Valve) throws {
        guard let dbQueue = dbManager.dbQueue else { return }
        try dbQueue.write { db in
            try valve.delete(db)
        }
    }

    func fetchAll() throws -> [Valve] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try Valve.fetchAll(db)
        }
    }

    func fetchById(_ id: UUID) throws -> Valve? {
        guard let dbQueue = dbManager.dbQueue else { return nil }
        return try dbQueue.read { db in
            try Valve.fetchOne(db, key: id)
        }
    }

    func fetchByStation(_ stationId: UUID) throws -> [Valve] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try Valve.filter(Column("stationId") == stationId).fetchAll(db)
        }
    }
}

extension Valve: FetchableRecord, PersistableRecord {
    static let databaseTableName = "valve"
}
