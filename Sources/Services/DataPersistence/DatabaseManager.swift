import Foundation
import GRDB

final class DatabaseManager: @unchecked Sendable {
    static let shared = DatabaseManager()

    private(set) var dbQueue: DatabaseQueue?

    private init() {}

    func openDatabase() throws {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "DatabaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access Application Support directory"])
        }
        let dbFolder = appSupport.appendingPathComponent("GasGridManager")

        try fileManager.createDirectory(at: dbFolder, withIntermediateDirectories: true)

        let dbPath = dbFolder.appendingPathComponent("gasgrid.sqlite").path
        dbQueue = try DatabaseQueue(path: dbPath)

        try createTables()
    }

    func closeDatabase() {
        dbQueue = nil
    }

    private func createTables() throws {
        try dbQueue?.write { db in
            try db.create(table: "networkStation", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("stationType", .text).notNull()
                t.column("status", .text).notNull()
                t.column("latitude", .double).notNull()
                t.column("longitude", .double).notNull()
                t.column("pressure", .double).notNull().defaults(to: 0)
                t.column("flowRate", .double).notNull().defaults(to: 0)
                t.column("temperature", .double).notNull().defaults(to: 20)
                t.column("maximumPressure", .double).notNull().defaults(to: 10)
                t.column("minimumPressure", .double).notNull().defaults(to: 1)
                t.column("installedDate", .datetime).notNull()
                t.column("lastMaintenanceDate", .datetime)
                t.column("notes", .text)
            }

            try db.create(table: "pipeline", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("startStationId", .text).notNull()
                t.column("endStationId", .text).notNull()
                t.column("startLatitude", .double).notNull()
                t.column("startLongitude", .double).notNull()
                t.column("endLatitude", .double).notNull()
                t.column("endLongitude", .double).notNull()
                t.column("diameter", .double).notNull()
                t.column("material", .text).notNull()
                t.column("pressure", .double).notNull().defaults(to: 0)
                t.column("length", .double).notNull().defaults(to: 0)
                t.column("installedDate", .datetime).notNull()
                t.column("lastInspectionDate", .datetime)
                t.column("notes", .text)
            }

            try db.create(table: "sensor", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("stationId", .text).notNull()
                t.column("sensorType", .text).notNull()
                t.column("isOnline", .boolean).notNull().defaults(to: true)
                t.column("lastReading", .double)
                t.column("lastReadingDate", .datetime)
                t.column("minimumValue", .double)
                t.column("maximumValue", .double)
                t.column("installedDate", .datetime).notNull()
            }

            try db.create(table: "sensorReading", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("sensorId", .text).notNull()
                t.column("value", .double).notNull()
                t.column("unit", .text).notNull()
                t.column("timestamp", .datetime).notNull()
                t.column("isAboveThreshold", .boolean).notNull().defaults(to: false)
                t.column("isBelowThreshold", .boolean).notNull().defaults(to: false)
            }

            try db.create(table: "valve", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("stationId", .text).notNull()
                t.column("valveType", .text).notNull()
                t.column("status", .text).notNull()
                t.column("position", .double).notNull().defaults(to: 0)
                t.column("diameter", .double).notNull()
                t.column("lastMaintenanceDate", .datetime)
                t.column("notes", .text)
            }

            try db.create(table: "alert", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("stationId", .text)
                t.column("pipelineId", .text)
                t.column("severity", .text).notNull()
                t.column("title", .text).notNull()
                t.column("message", .text).notNull()
                t.column("timestamp", .datetime).notNull()
                t.column("isAcknowledged", .boolean).notNull().defaults(to: false)
                t.column("acknowledgedDate", .datetime)
                t.column("notes", .text)
            }

            try db.create(table: "maintenanceLog", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("assetId", .text).notNull()
                t.column("assetType", .text).notNull()
                t.column("maintenanceType", .text).notNull()
                t.column("description", .text).notNull()
                t.column("scheduledDate", .datetime).notNull()
                t.column("completedDate", .datetime)
                t.column("performedBy", .text)
                t.column("cost", .double)
                t.column("notes", .text)
            }
        }
    }
}
