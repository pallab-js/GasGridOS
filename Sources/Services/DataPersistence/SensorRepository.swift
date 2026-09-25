import Foundation
import GRDB

final class SensorRepository: Sendable {
    private let dbManager = DatabaseManager.shared

    func insert(_ sensor: Sensor) throws {
        try dbManager.requireQueue().write { db in
            try sensor.save(db)
        }
    }

    func update(_ sensor: Sensor) throws {
        try dbManager.requireQueue().write { db in
            try sensor.update(db)
        }
    }

    func updateBatch(_ sensors: [Sensor]) throws {
        let dbQueue = try dbManager.requireQueue()
        try dbQueue.write { db in
            for sensor in sensors {
                try sensor.save(db)
            }
        }
    }

    func delete(_ sensor: Sensor) throws {
        try dbManager.requireQueue().write { db in
            try sensor.delete(db)
        }
    }

    func fetchAll() throws -> [Sensor] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Sensor.fetchAll(db)
        }
    }

    func fetchById(_ id: UUID) throws -> Sensor? {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Sensor.fetchOne(db, key: id)
        }
    }

    func fetchByStation(_ stationId: UUID) throws -> [Sensor] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Sensor.filter(Column("stationId") == stationId).fetchAll(db)
        }
    }
}

extension Sensor: FetchableRecord, PersistableRecord {
    static let databaseTableName = "sensor"
}
