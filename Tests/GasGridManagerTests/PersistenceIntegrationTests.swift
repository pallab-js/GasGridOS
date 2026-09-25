import XCTest
import GRDB
@testable import GasGridManager

/// Integration tests for the persistence layer. Each test runs against a
/// temporary database file so the real app database is never touched.
final class PersistenceIntegrationTests: XCTestCase {
    private var tempDirectory: URL?
    private let dbManager = DatabaseManager.shared

    override func setUpWithError() throws {
        try super.setUpWithError()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gasgrid-tests-\(UUID().uuidString)", isDirectory: true)
        tempDirectory = directory
        dbManager.closeDatabase()
        try dbManager.openDatabase(at: directory.appendingPathComponent("test.sqlite"))
    }

    override func tearDownWithError() throws {
        dbManager.closeDatabase()
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        try super.tearDownWithError()
    }

    // MARK: - Helpers

    private func makeStation(name: String = "Test Station") -> NetworkStation {
        NetworkStation(
            name: name,
            stationType: .compressorStation,
            latitude: 52.52,
            longitude: 13.405,
            pressure: 5,
            maximumPressure: 10,
            minimumPressure: 1
        )
    }

    private func rowCount(_ table: String) throws -> Int {
        try dbManager.requireQueue().read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table)") ?? 0
        }
    }

    // MARK: - Schema

    func testMigrationsCreateAllTablesAndIndexes() throws {
        let queue = try dbManager.requireQueue()
        let tables = [
            "networkStation", "pipeline", "sensor", "sensorReading",
            "valve", "alert", "maintenanceLog", "auditLog"
        ]

        for table in tables {
            XCTAssertTrue(try queue.read { db in try db.tableExists(table) }, "Missing table: \(table)")
        }

        let indexes = try queue.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type = 'index'")
        }
        XCTAssertTrue(indexes.contains("index_sensor_stationId"))
        XCTAssertTrue(indexes.contains("index_reading_sensorId"))
    }

    func testReopeningTheSameDatabaseIsIdempotent() throws {
        let url = tempDirectory!.appendingPathComponent("test.sqlite")
        try StationRepository().insert(makeStation(name: "Persistent"))

        try dbManager.openDatabase(at: url)

        XCTAssertEqual(try StationRepository().fetchAll().map(\.name), ["Persistent"])
    }

    // MARK: - Cascade deletes

    func testDeletingStationRemovesDependentRows() throws {
        let station = makeStation()
        let other = makeStation(name: "Other Station")

        let stationRepo = StationRepository()
        try stationRepo.insert(station)
        try stationRepo.insert(other)

        try SensorRepository().insert(
            Sensor(name: "PS-1", stationId: station.id, sensorType: .pressure)
        )
        try SensorRepository().insert(
            Sensor(name: "PS-other", stationId: other.id, sensorType: .pressure)
        )
        try ValveRepository().insert(
            Valve(name: "V-1", stationId: station.id, valveType: .gate, diameter: 100)
        )
        try AlertRepository().insert(
            Alert(stationId: station.id, severity: .critical, title: "Leak", message: "Gas leak")
        )
        try MaintenanceRepository().insert(
            GasGridManager.MaintenanceLog(
                assetId: station.id,
                assetType: "Station",
                maintenanceType: .preventive,
                description: "Inspection",
                scheduledDate: Date()
            )
        )

        try stationRepo.delete(station)

        XCTAssertEqual(try StationRepository().fetchAll().map(\.id), [other.id])
        XCTAssertEqual(try SensorRepository().fetchAll().map(\.stationId), [other.id])
        XCTAssertEqual(try ValveRepository().fetchAll().count, 0)
        XCTAssertEqual(try AlertRepository().fetchAll().count, 0)
        XCTAssertEqual(try MaintenanceRepository().fetchAll().count, 0)
    }

    func testDeletingStationRemovesConnectedPipelines() throws {
        let start = makeStation(name: "Start")
        let end = makeStation(name: "End")
        let startRepo = StationRepository()
        try startRepo.insert(start)
        try startRepo.insert(end)

        try PipelineRepository().insert(
            Pipeline(
                name: "Main Line",
                startStationId: start.id,
                endStationId: end.id,
                startLatitude: start.latitude,
                startLongitude: start.longitude,
                endLatitude: end.latitude,
                endLongitude: end.longitude,
                diameter: 300,
                material: .steel,
                length: 12
            )
        )
        XCTAssertEqual(try PipelineRepository().fetchAll().count, 1)

        try startRepo.delete(start)

        XCTAssertEqual(try PipelineRepository().fetchAll().count, 0)
        XCTAssertEqual(try StationRepository().fetchAll().map(\.id), [end.id])
    }

    // MARK: - History management

    func testClearHistoricalDataKeepsAssetsAndAuditTrail() throws {
        let station = makeStation()
        try StationRepository().insert(station)
        let sensor = Sensor(name: "TS-1", stationId: station.id, sensorType: .temperature)
        try SensorRepository().insert(sensor)
        try DataHistoryRepository().insert(
            SensorReading(sensorId: sensor.id, value: 21.5, unit: "°C", timestamp: Date())
        )
        DatabaseManager.shared.logAuditEvent("TEST", details: "setup")

        XCTAssertEqual(try rowCount("sensorReading"), 1)
        XCTAssertGreaterThan(try rowCount("auditLog"), 0)

        try dbManager.clearHistoricalData()

        XCTAssertEqual(try rowCount("sensorReading"), 0)
        XCTAssertEqual(try StationRepository().fetchAll().count, 1)
        XCTAssertEqual(try SensorRepository().fetchAll().count, 1)
        XCTAssertGreaterThan(try rowCount("auditLog"), 0)
    }

    func testLogAuditEventWithoutOpenDatabaseDoesNotCrash() throws {
        dbManager.closeDatabase()
        DatabaseManager.shared.logAuditEvent("NO_DB", details: "database is closed")
        XCTAssertThrowsError(try dbManager.requireQueue())
    }

    // MARK: - Backup

    func testBackupProducesAReadableCopy() throws {
        try StationRepository().insert(makeStation(name: "Backed Up"))

        let backupURL = tempDirectory!.appendingPathComponent("backup.sqlite")
        try dbManager.backup(to: backupURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))

        let backupQueue = try DatabaseQueue(path: backupURL.path)
        let names = try backupQueue.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM networkStation")
        }
        XCTAssertEqual(names, ["Backed Up"])
    }

    // MARK: - Model behaviour used by the UI

    func testStationPressureNormalBoundaries() {
        var station = makeStation()
        station.pressure = 5
        XCTAssertTrue(station.isPressureNormal)

        station.pressure = 0.5
        XCTAssertFalse(station.isPressureNormal)

        station.pressure = 11
        XCTAssertFalse(station.isPressureNormal)
    }

    func testMaintenanceLogOverdueLogic() {
        let past = Date().addingTimeInterval(-86_400)
        let upcoming = GasGridManager.MaintenanceLog(
            assetId: UUID(),
            assetType: "Station",
            maintenanceType: .preventive,
            description: "Upcoming",
            scheduledDate: Date().addingTimeInterval(86_400)
        )
        let overdue = GasGridManager.MaintenanceLog(
            assetId: UUID(),
            assetType: "Station",
            maintenanceType: .inspection,
            description: "Overdue",
            scheduledDate: past
        )
        var completed = GasGridManager.MaintenanceLog(
            assetId: UUID(),
            assetType: "Station",
            maintenanceType: .corrective,
            description: "Completed",
            scheduledDate: past,
            completedDate: Date()
        )

        XCTAssertFalse(upcoming.isOverdue)
        XCTAssertTrue(overdue.isOverdue)
        XCTAssertFalse(completed.isOverdue)
        XCTAssertTrue(completed.isCompleted)

        completed.completedDate = nil
        XCTAssertFalse(completed.isCompleted)
        XCTAssertTrue(completed.isOverdue)
    }

    func testAlertSeverityPriorityOrdering() {
        let severities = GasGridManager.AlertSeverity.allCases
        XCTAssertEqual(severities.count, 5)
        XCTAssertEqual(GasGridManager.AlertSeverity.critical.priority, 5)
        XCTAssertEqual(GasGridManager.AlertSeverity.info.priority, 1)
        XCTAssertTrue(
            GasGridManager.AlertSeverity.critical.priority >
                GasGridManager.AlertSeverity.high.priority
        )
    }
}
