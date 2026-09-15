import Foundation
import GRDB

final class PipelineRepository {
    private let dbManager = DatabaseManager.shared

    func insert(_ pipeline: Pipeline) throws {
        try dbManager.dbQueue?.write { db in
            try pipeline.save(db)
        }
    }

    func update(_ pipeline: Pipeline) throws {
        try dbManager.dbQueue?.write { db in
            try pipeline.update(db)
        }
    }

    func delete(_ pipeline: Pipeline) throws {
        try dbManager.dbQueue?.write { db in
            try pipeline.delete(db)
        }
    }

    func fetchAll() throws -> [Pipeline] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try Pipeline.fetchAll(db)
        }
    }

    func fetchById(_ id: UUID) throws -> Pipeline? {
        try dbManager.dbQueue?.read { db in
            try Pipeline.fetchOne(db, key: id)
        }
    }

    func fetchByStation(_ stationId: UUID) throws -> [Pipeline] {
        guard let dbQueue = dbManager.dbQueue else { return [] }
        return try dbQueue.read { db in
            try Pipeline.filter(Column("startStationId") == stationId || Column("endStationId") == stationId).fetchAll(db)
        }
    }
}

extension Pipeline: FetchableRecord, PersistableRecord {
    static let databaseTableName = "pipeline"
}
