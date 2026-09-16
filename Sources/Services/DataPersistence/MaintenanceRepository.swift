import Foundation
import GRDB

final class MaintenanceRepository {
    private let dbManager = DatabaseManager.shared

    func insert(_ log: MaintenanceLog) throws {
        try dbManager.dbQueue?.write { db in
            try log.save(db)
        }
    }

    func update(_ log: MaintenanceLog) throws {
        try dbManager.dbQueue?.write { db in
            try log.update(db)
        }
    }

    func delete(_ log: MaintenanceLog) throws {
        try dbManager.dbQueue?.write { db in
            try log.delete(db)
        }
    }

    func fetchAll() throws -> [MaintenanceLog] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try MaintenanceLog.fetchAll(db)
        }
    }

    func fetchById(_ id: UUID) throws -> MaintenanceLog? {
        try dbManager.dbQueue?.read { db in
            try MaintenanceLog.fetchOne(db, key: id)
        }
    }

    func fetchByAsset(_ assetId: UUID) throws -> [MaintenanceLog] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try MaintenanceLog.filter(Column("assetId") == assetId).fetchAll(db)
        }
    }
}

extension MaintenanceLog: FetchableRecord, PersistableRecord {
    static let databaseTableName = "maintenanceLog"
}
