import Foundation
import GRDB

final class PipelineRepository: Sendable {
    private let dbManager = DatabaseManager.shared

    func insert(_ pipeline: Pipeline) throws {
        try dbManager.requireQueue().write { db in
            try pipeline.save(db)
        }
    }

    func update(_ pipeline: Pipeline) throws {
        try dbManager.requireQueue().write { db in
            try pipeline.update(db)
        }
    }

    func delete(_ pipeline: Pipeline) throws {
        try dbManager.requireQueue().write { db in
            try db.execute(sql: "DELETE FROM maintenanceLog WHERE assetId = ?", arguments: [pipeline.id])
            try pipeline.delete(db)
        }
    }

    func fetchAll() throws -> [Pipeline] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Pipeline.fetchAll(db)
        }
    }

    func fetchById(_ id: UUID) throws -> Pipeline? {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Pipeline.fetchOne(db, key: id)
        }
    }

    func fetchByStation(_ stationId: UUID) throws -> [Pipeline] {
        let dbQueue = try dbManager.requireQueue()
        return try dbQueue.read { db in
            try Pipeline.filter(Column("startStationId") == stationId || Column("endStationId") == stationId).fetchAll(db)
        }
    }
}

extension Pipeline: FetchableRecord, PersistableRecord {
    static let databaseTableName = "pipeline"
}
