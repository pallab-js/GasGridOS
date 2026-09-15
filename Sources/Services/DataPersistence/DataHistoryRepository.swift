import Foundation
import GRDB

final class DataHistoryRepository {
    private let dbManager = DatabaseManager.shared

    func insert(_ reading: SensorReading) throws {
        guard let dbQueue = dbManager.dbQueue else { return }
        try dbQueue.write { db in
            try reading.save(db)
        }
    }

    func insertBatch(_ readings: [SensorReading]) throws {
        guard let dbQueue = dbManager.dbQueue else { return }
        try dbQueue.write { db in
            for reading in readings {
                try reading.save(db)
            }
        }
    }

    func fetchAll() throws -> [SensorReading] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try SensorReading.fetchAll(db)
        }
    }

    func fetchBySensor(_ sensorId: UUID) throws -> [SensorReading] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try SensorReading.filter(Column("sensorId") == sensorId)
                .order(Column("timestamp").desc)
                .fetchAll(db)
        }
    }

    func fetchByTimeRange(startDate: Date, endDate: Date) throws -> [SensorReading] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try SensorReading
                .filter(Column("timestamp") >= startDate && Column("timestamp") <= endDate)
                .order(Column("timestamp").asc)
                .fetchAll(db)
        }
    }

    func fetchLatest(readingsPerSensor: Int = 100) throws -> [UUID: [SensorReading]] {
        guard let dbQueue = dbManager.dbQueue else { return [:] }
        return try dbQueue.read { db in
            var result: [UUID: [SensorReading]] = [:]
            let sensors = try Sensor.fetchAll(db)
            for sensor in sensors {
                let readings = try SensorReading
                    .filter(Column("sensorId") == sensor.id)
                    .order(Column("timestamp").desc)
                    .limit(readingsPerSensor)
                    .fetchAll(db)
                result[sensor.id] = readings.reversed()
            }
            return result
        }
    }

    func deleteOlderThan(_ date: Date) throws {
        guard let dbQueue = dbManager.dbQueue else { return }
        try dbQueue.write { db in
            try SensorReading.filter(Column("timestamp") < date).deleteAll(db)
        }
    }
}

extension SensorReading: FetchableRecord, PersistableRecord {
    static let databaseTableName = "sensorReading"
}
