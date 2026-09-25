import Foundation
import GRDB

final class SampleDataSeeder: Sendable {
    static let shared = SampleDataSeeder()

    private init() {}

    /// Seeds the demo dataset once, inside a single transaction.
    /// - Returns: `true` when data was inserted, `false` when it already existed.
    @discardableResult
    func seedSampleData() throws -> Bool {
        let dbQueue = try DatabaseManager.shared.requireQueue()
        let existingStations = try dbQueue.read { db in try NetworkStation.fetchAll(db) }
        guard existingStations.isEmpty else { return false }

        let station1 = NetworkStation(
            name: "Central Distribution Hub",
            stationType: .gasMeteringStation,
            status: .online,
            latitude: 40.7128,
            longitude: -74.0060,
            pressure: 4.2,
            flowRate: 125.5,
            temperature: 28.0,
            maximumPressure: 5.0,
            minimumPressure: 3.0
        )

        let station2 = NetworkStation(
            name: "North Regulator Station",
            stationType: .pressureRegulatingStation,
            status: .online,
            latitude: 40.7580,
            longitude: -73.9855,
            pressure: 3.8,
            flowRate: 85.2,
            temperature: 26.5,
            maximumPressure: 4.5,
            minimumPressure: 2.5
        )

        let station3 = NetworkStation(
            name: "South Compressor Station",
            stationType: .compressorStation,
            status: .warning,
            latitude: 40.6892,
            longitude: -74.0445,
            pressure: 5.1,
            flowRate: 210.8,
            temperature: 32.0,
            maximumPressure: 5.0,
            minimumPressure: 3.0
        )

        let station4 = NetworkStation(
            name: "East Storage Facility",
            stationType: .storageFacility,
            status: .offline,
            latitude: 40.7282,
            longitude: -73.7949,
            pressure: 0,
            flowRate: 0,
            temperature: 22.0,
            maximumPressure: 6.0,
            minimumPressure: 2.0
        )

        let station5 = NetworkStation(
            name: "West DMA Node",
            stationType: .districtMeteringArea,
            status: .online,
            latitude: 40.7484,
            longitude: -73.9857,
            pressure: 3.5,
            flowRate: 95.3,
            temperature: 27.0,
            maximumPressure: 4.0,
            minimumPressure: 2.0
        )

        let pipeline1 = Pipeline(
            name: "Main Transmission Line",
            startStationId: station1.id,
            endStationId: station2.id,
            startLatitude: station1.latitude,
            startLongitude: station1.longitude,
            endLatitude: station2.latitude,
            endLongitude: station2.longitude,
            diameter: 300,
            material: .steel,
            pressure: 4.0,
            length: 12.5
        )

        let pipeline2 = Pipeline(
            name: "South Distribution Line",
            startStationId: station1.id,
            endStationId: station3.id,
            startLatitude: station1.latitude,
            startLongitude: station1.longitude,
            endLatitude: station3.latitude,
            endLongitude: station3.longitude,
            diameter: 200,
            material: .polyethylene,
            pressure: 4.5,
            length: 8.3
        )

        let pipeline3 = Pipeline(
            name: "East Service Line",
            startStationId: station1.id,
            endStationId: station4.id,
            startLatitude: station1.latitude,
            startLongitude: station1.longitude,
            endLatitude: station4.latitude,
            endLongitude: station4.longitude,
            diameter: 150,
            material: .polyethylene,
            pressure: 3.5,
            length: 15.2
        )

        let pipeline4 = Pipeline(
            name: "West Connection",
            startStationId: station2.id,
            endStationId: station5.id,
            startLatitude: station2.latitude,
            startLongitude: station2.longitude,
            endLatitude: station5.latitude,
            endLongitude: station5.longitude,
            diameter: 100,
            material: .steel,
            pressure: 3.2,
            length: 6.8
        )

        let sensor1 = Sensor(
            name: "Pressure Sensor A1",
            stationId: station1.id,
            sensorType: .pressure,
            isOnline: true,
            lastReading: 4.2,
            lastReadingDate: Date()
        )

        let sensor2 = Sensor(
            name: "Flow Meter A1",
            stationId: station1.id,
            sensorType: .flowRate,
            isOnline: true,
            lastReading: 125.5,
            lastReadingDate: Date()
        )

        let sensor3 = Sensor(
            name: "Temperature Sensor A1",
            stationId: station1.id,
            sensorType: .temperature,
            isOnline: true,
            lastReading: 28.0,
            lastReadingDate: Date()
        )

        let sensor4 = Sensor(
            name: "Gas Detector B1",
            stationId: station3.id,
            sensorType: .gasDetection,
            isOnline: true,
            lastReading: 0,
            lastReadingDate: Date()
        )

        let alert1 = Alert(
            stationId: station3.id,
            severity: .high,
            title: "High Pressure Warning",
            message: "Pressure exceeds normal range at South Compressor Station",
            timestamp: Date().addingTimeInterval(-300)
        )

        let alert2 = Alert(
            stationId: station4.id,
            severity: .critical,
            title: "Station Offline",
            message: "East Storage Facility is not responding",
            timestamp: Date().addingTimeInterval(-600)
        )

        let alert3 = Alert(
            stationId: station2.id,
            severity: .medium,
            title: "Scheduled Maintenance",
            message: "Maintenance due in 3 days at North Regulator Station",
            timestamp: Date().addingTimeInterval(-1800)
        )

        let alert4 = Alert(
            stationId: station1.id,
            severity: .info,
            title: "System Update",
            message: "Firmware update available for sensors",
            timestamp: Date().addingTimeInterval(-3600)
        )

        let valve1 = Valve(
            name: "Main Gate Valve",
            stationId: station1.id,
            valveType: .gate,
            status: .open,
            position: 1.0,
            diameter: 300
        )

        let valve2 = Valve(
            name: "North Butterfly Valve",
            stationId: station2.id,
            valveType: .butterfly,
            status: .closed,
            position: 0,
            diameter: 200
        )

        let valve3 = Valve(
            name: "South Ball Valve",
            stationId: station3.id,
            valveType: .ball,
            status: .partiallyOpen,
            position: 0.5,
            diameter: 150
        )

        let valve4 = Valve(
            name: "West Check Valve",
            stationId: station5.id,
            valveType: .check,
            status: .open,
            position: 1.0,
            diameter: 100
        )

        try dbQueue.write { db in
            for station in [station1, station2, station3, station4, station5] {
                try station.save(db)
            }
            for pipeline in [pipeline1, pipeline2, pipeline3, pipeline4] {
                try pipeline.save(db)
            }
            for sensor in [sensor1, sensor2, sensor3, sensor4] {
                try sensor.save(db)
            }
            for alert in [alert1, alert2, alert3, alert4] {
                try alert.save(db)
            }
            for valve in [valve1, valve2, valve3, valve4] {
                try valve.save(db)
            }
        }
        return true
    }

    /// Backfills the telemetry sensors that history generation and charts depend on.
    /// Idempotent: only sensors that are missing for a station are inserted.
    func ensureTelemetrySensors(for stations: [NetworkStation]) throws {
        let dbQueue = try DatabaseManager.shared.requireQueue()

        for station in stations {
            let existing = try dbQueue.read { db in
                try Sensor.filter(Column("stationId") == station.id).fetchAll(db)
            }
            let missingTypes = [SensorType.pressure, .flowRate, .temperature].filter { type in
                !existing.contains { $0.sensorType == type }
            }
            guard !missingTypes.isEmpty else { continue }

            try dbQueue.write { db in
                for type in missingTypes {
                    let sensor = Sensor(
                        name: "\(type.rawValue) Sensor \(station.name)",
                        stationId: station.id,
                        sensorType: type,
                        lastReading: currentReading(for: type, station: station),
                        lastReadingDate: Date()
                    )
                    try sensor.save(db)
                }
            }
        }
    }

    private func currentReading(for type: SensorType, station: NetworkStation) -> Double {
        switch type {
        case .pressure: return station.pressure
        case .flowRate: return station.flowRate
        case .temperature: return station.temperature
        default: return 0
        }
    }
}
