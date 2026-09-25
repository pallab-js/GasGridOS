import Foundation
import GRDB

final class DataHistoryRepository: Sendable {
    private let dbManager = DatabaseManager.shared

    func insert(_ reading: SensorReading) throws {
        let dbQueue = try dbManager.requireQueue()
        try dbQueue.write { db in
            try reading.save(db)
        }
    }

    func insertBatch(_ readings: [SensorReading]) throws {
        let dbQueue = try dbManager.requireQueue()
        try dbQueue.write { db in
            for reading in readings {
                try reading.save(db)
            }
        }
    }

    func fetchAll() throws -> [SensorReading] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try SensorReading.fetchAll(db)
        }
    }

    func fetchBySensor(_ sensorId: UUID) throws -> [SensorReading] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try SensorReading.filter(Column("sensorId") == sensorId)
                .order(Column("timestamp").desc)
                .fetchAll(db)
        }
    }

    func fetchByTimeRange(startDate: Date, endDate: Date) throws -> [SensorReading] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try SensorReading
                .filter(Column("timestamp") >= startDate && Column("timestamp") <= endDate)
                .order(Column("timestamp").asc)
                .fetchAll(db)
        }
    }

    func countInTimeRange(startDate: Date, endDate: Date) throws -> Int {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try SensorReading
                .filter(Column("timestamp") >= startDate && Column("timestamp") <= endDate)
                .fetchCount(db)
        }
    }

    func deleteOlderThan(_ date: Date) throws {
        let dbQueue = try dbManager.requireQueue()
        try dbQueue.write { db in
            try SensorReading.filter(Column("timestamp") < date).deleteAll(db)
        }
    }

    /// Removes readings whose sensor row no longer exists (left behind by
    /// earlier versions that stored station ids in `sensorId`).
    func deleteOrphanedReadings() throws {
        let dbQueue = try dbManager.requireQueue()
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM sensorReading WHERE sensorId NOT IN (SELECT id FROM sensor)")
        }
    }
}

extension SensorReading: FetchableRecord, PersistableRecord {
    static let databaseTableName = "sensorReading"
}
