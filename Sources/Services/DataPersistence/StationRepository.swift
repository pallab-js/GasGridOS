import Foundation
import GRDB

final class StationRepository {
    private let dbManager = DatabaseManager.shared

    func insert(_ station: NetworkStation) throws {
        try dbManager.dbQueue?.write { db in
            try station.save(db)
        }
    }

    func update(_ station: NetworkStation) throws {
        try dbManager.dbQueue?.write { db in
            try station.update(db)
        }
    }

    func delete(_ station: NetworkStation) throws {
        try dbManager.dbQueue?.write { db in
            try station.delete(db)
        }
    }

    func fetchAll() throws -> [NetworkStation] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try NetworkStation.fetchAll(db)
        }
    }

    func fetchById(_ id: UUID) throws -> NetworkStation? {
        try dbManager.dbQueue?.read { db in
            try NetworkStation.fetchOne(db, key: id)
        }
    }

    func fetchByStatus(_ status: StationStatus) throws -> [NetworkStation] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try NetworkStation.filter(Column("status") == status.rawValue).fetchAll(db)
        }
    }

    func updateBatch(_ stations: [NetworkStation]) throws {
        guard let dbQueue = dbManager.dbQueue else { return }
        try dbQueue.write { db in
            for station in stations {
                try station.update(db)
            }
        }
    }
}

extension NetworkStation: FetchableRecord, PersistableRecord {
    static let databaseTableName = "networkStation"
}
