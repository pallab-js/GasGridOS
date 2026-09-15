import Foundation
import os.log

@MainActor
final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()

    @Published var memoryUsage: Double = 0
    @Published var isMonitoring = false

    private let logger = Logger(subsystem: "com.gasgrid.performance", category: "monitor")
    private var timer: Timer?

    private init() {}

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetrics()
            }
        }

        logger.info("Performance monitoring started")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        logger.info("Performance monitoring stopped")
    }

    private func updateMetrics() {
        memoryUsage = getMemoryUsage()
    }

    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let taskSelf = mach_task_self_

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(taskSelf, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let usedBytes = Double(info.resident_size)
        let totalBytes = Double(ProcessInfo.processInfo.physicalMemory)
        return (usedBytes / totalBytes) * 100
    }

    func logPerformance(_ operation: String, duration: TimeInterval) {
        let ms = duration * 1000
        logger.info("\(operation): \(String(format: "%.1f", ms))ms")
    }
}
