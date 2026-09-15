import Foundation

final class SampleDataSeeder: @unchecked Sendable {
    static let shared = SampleDataSeeder()

    private let stationRepo = StationRepository()
    private let pipelineRepo = PipelineRepository()
    private let sensorRepo = SensorRepository()
    private let alertRepo = AlertRepository()

    private init() {}

    func seedSampleData() throws {
        let existingStations = try stationRepo.fetchAll()
        guard existingStations.isEmpty else { return }

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

        try stationRepo.insert(station1)
        try stationRepo.insert(station2)
        try stationRepo.insert(station3)
        try stationRepo.insert(station4)
        try stationRepo.insert(station5)

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

        try pipelineRepo.insert(pipeline1)
        try pipelineRepo.insert(pipeline2)
        try pipelineRepo.insert(pipeline3)
        try pipelineRepo.insert(pipeline4)

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

        try sensorRepo.insert(sensor1)
        try sensorRepo.insert(sensor2)
        try sensorRepo.insert(sensor3)
        try sensorRepo.insert(sensor4)

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

        try alertRepo.insert(alert1)
        try alertRepo.insert(alert2)
        try alertRepo.insert(alert3)
        try alertRepo.insert(alert4)
    }
}
