import Foundation
import GRDB

final class SensorRepository {
    private let dbManager = DatabaseManager.shared

    func insert(_ sensor: Sensor) throws {
        try dbManager.dbQueue?.write { db in
            try sensor.save(db)
        }
    }

    func update(_ sensor: Sensor) throws {
        try dbManager.dbQueue?.write { db in
            try sensor.update(db)
        }
    }

    func delete(_ sensor: Sensor) throws {
        try dbManager.dbQueue?.write { db in
            try sensor.delete(db)
        }
    }

    func fetchAll() throws -> [Sensor] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try Sensor.fetchAll(db)
        }
    }

    func fetchById(_ id: UUID) throws -> Sensor? {
        try dbManager.dbQueue?.read { db in
            try Sensor.fetchOne(db, key: id)
        }
    }

    func fetchByStation(_ stationId: UUID) throws -> [Sensor] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try Sensor.filter(Column("stationId") == stationId).fetchAll(db)
        }
    }
}

extension Sensor: FetchableRecord, PersistableRecord {
    static let databaseTableName = "sensor"
}
