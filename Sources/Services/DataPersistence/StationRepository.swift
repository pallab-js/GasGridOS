import Foundation
import GRDB

final class StationRepository: Sendable {
    private let dbManager = DatabaseManager.shared

    func insert(_ station: NetworkStation) throws {
        try dbManager.requireQueue().write { db in
            try station.save(db)
        }
    }

    func update(_ station: NetworkStation) throws {
        try dbManager.requireQueue().write { db in
            try station.update(db)
        }
    }

    func delete(_ station: NetworkStation) throws {
        try dbManager.requireQueue().write { db in
            try db.execute(sql: "DELETE FROM sensor WHERE stationId = ?", arguments: [station.id])
            try db.execute(sql: "DELETE FROM valve WHERE stationId = ?", arguments: [station.id])
            try db.execute(sql: "DELETE FROM alert WHERE stationId = ?", arguments: [station.id])
            try db.execute(sql: "DELETE FROM pipeline WHERE startStationId = ? OR endStationId = ?",
                           arguments: [station.id, station.id])
            try db.execute(sql: "DELETE FROM maintenanceLog WHERE assetId = ?", arguments: [station.id])
            try station.delete(db)
        }
    }

    func fetchAll() throws -> [NetworkStation] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try NetworkStation.fetchAll(db)
        }
    }

    func fetchById(_ id: UUID) throws -> NetworkStation? {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try NetworkStation.fetchOne(db, key: id)
        }
    }

    func fetchByStatus(_ status: StationStatus) throws -> [NetworkStation] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try NetworkStation.filter(Column("status") == status.rawValue).fetchAll(db)
        }
    }

    func updateBatch(_ stations: [NetworkStation]) throws {
        let dbQueue = try dbManager.requireQueue()
        try dbQueue.write { db in
            for station in stations {
                try station.save(db)
            }
        }
    }
}

extension NetworkStation: FetchableRecord, PersistableRecord {
    static let databaseTableName = "networkStation"
}
