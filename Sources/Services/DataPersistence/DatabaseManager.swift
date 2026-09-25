import Foundation
import GRDB
import os.log

private let logger = Logger(subsystem: "com.gasgrid", category: "Database")

enum DatabaseManagerError: LocalizedError {
    case notOpen
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .notOpen:
            return "The database is not open."
        case .unavailable(let reason):
            return reason
        }
    }
}

final class DatabaseManager: @unchecked Sendable {
    static let shared = DatabaseManager()

    private let lock = NSLock()
    private var storedQueue: DatabaseQueue?

    /// Every access to the underlying queue goes through `lock`.
    var dbQueue: DatabaseQueue? { lock.withLock { storedQueue } }

    private init() {}

    static var databaseDirectoryURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("GasGridManager")
    }

    static var databaseFileURL: URL? {
        databaseDirectoryURL?.appendingPathComponent("gasgrid.sqlite")
    }

    /// Returns the open queue or throws, so callers can never silently no-op.
    func requireQueue() throws -> DatabaseQueue {
        guard let queue = dbQueue else { throw DatabaseManagerError.notOpen }
        return queue
    }

    func openDatabase() throws {
        guard let dbFolder = DatabaseManager.databaseDirectoryURL else {
            throw DatabaseManagerError.unavailable("Cannot access Application Support directory")
        }

        try openDatabase(at: dbFolder.appendingPathComponent("gasgrid.sqlite"))
    }

    /// Opens and migrates the database at an explicit location, then publishes it
    /// as the live queue. Tests use this to point at a temporary database.
    func openDatabase(at fileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let queue = try DatabaseQueue(path: fileURL.path)
        try Self.migrate(queue)

        lock.lock()
        storedQueue = queue
        lock.unlock()
    }

    func closeDatabase() {
        lock.lock()
        storedQueue = nil
        lock.unlock()
    }

    func logAuditEvent(_ action: String, details: String) {
        guard let queue = dbQueue else {
            logger.warning("Audit event '\(action, privacy: .public)' dropped: database is not open")
            return
        }
        do {
            try queue.write { db in
                try db.execute(sql: """
                    INSERT INTO auditLog (id, action, details, timestamp)
                    VALUES (?, ?, ?, ?)
                    """, arguments: [UUID().uuidString, action, details, Date()])
            }
        } catch {
            logger.error("Failed to log audit event: \(error.localizedDescription)")
        }
    }

    /// Removes all recorded history without touching assets or the audit trail.
    func clearHistoricalData() throws {
        let queue = try requireQueue()
        try queue.write { db in
            try db.execute(sql: "DELETE FROM sensorReading")
        }
    }

    /// Copies the live database to `destinationURL` using SQLite's backup API,
    /// so the app keeps running with an open database throughout.
    func backup(to destinationURL: URL) throws {
        let queue = try requireQueue()
        let destination = try DatabaseQueue(path: destinationURL.path)
        try queue.backup(to: destination)
    }

    private static func migrate(_ queue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1-createSchema") { db in
            try createTables(in: db)
            try createIndexes(in: db)
        }
        try migrator.migrate(queue)
    }

    private static func createTables(in db: Database) throws {
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

        try db.create(table: "auditLog", ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("action", .text).notNull()
            t.column("details", .text).notNull()
            t.column("timestamp", .datetime).notNull()
        }
    }

    private static func createIndexes(in db: Database) throws {
        try db.create(index: "index_sensor_stationId", on: "sensor", columns: ["stationId"], ifNotExists: true)
        try db.create(index: "index_valve_stationId", on: "valve", columns: ["stationId"], ifNotExists: true)
        try db.create(index: "index_alert_stationId", on: "alert", columns: ["stationId"], ifNotExists: true)
        try db.create(index: "index_alert_isAcknowledged", on: "alert", columns: ["isAcknowledged"], ifNotExists: true)
        try db.create(index: "index_reading_sensorId", on: "sensorReading", columns: ["sensorId"], ifNotExists: true)
        try db.create(index: "index_reading_timestamp", on: "sensorReading", columns: ["timestamp"], ifNotExists: true)
        try db.create(index: "index_maintenance_assetId", on: "maintenanceLog", columns: ["assetId"], ifNotExists: true)
    }
}
