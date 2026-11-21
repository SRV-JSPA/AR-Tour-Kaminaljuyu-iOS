import Foundation
import CoreLocation
import UIKit

// MARK: - PerformanceLogger
//
// Instrumentación de rendimiento del GPSModule para las pruebas técnicas de la
// tesis. Registra, por cada lectura de ubicación que entrega CoreLocation, un
// conjunto de métricas fáciles de obtener y defendibles en la sección de
// resultados:
//
//   - Precisión GPS         -> horizontalAccuracy / verticalAccuracy (metros)
//   - Frecuencia de updates -> intervalo entre lecturas consecutivas (s) / Hz
//   - Latencia de la lectura-> fix_age = antigüedad del fix al recibirlo (s)
//   - Latencia de cómputo   -> tiempo de la distancia Haversine a todos los POIs (ms)
//   - Tasa de descarte      -> lecturas rechazadas por los filtros de calidad
//   - Uso de memoria        -> phys_footprint del proceso (MB)
//   - Consumo de batería    -> nivel inicial/final y tasa de drenaje (%/h)
//
// Genera dos CSV en Documents/PerformanceLogs/ :
//   1. gps_samples_<fecha>.csv   -> una fila por lectura (dataset crudo para graficar)
//   2. gps_sessions_summary.csv  -> una fila por recorrido (tabla lista para resultados)
//
// La sesión arranca sola con la primera lectura y se cierra al detener el
// tracking o al mandar la app a segundo plano / cerrarla. Todo corre en el hilo
// principal (los callbacks de CoreLocation llegan ahí); solo la escritura a
// disco se delega a una cola serial para no trabar la UI.
//
// Es código exclusivo de instrumentación: no altera el comportamiento del tour.

final class PerformanceLogger {

    // MARK: - Instancia compartida
    static let shared = PerformanceLogger()

    // MARK: - Razones de descarte (filtros de LocationService)
    enum RejectReason: String {
        case invalidAccuracy = "invalid_accuracy"
        case lowAccuracy     = "low_accuracy"
        case stale           = "stale"
    }

    // MARK: - Infraestructura
    private let ioQueue = DispatchQueue(label: "gps.performance.logger.io")
    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private let fileStampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f
    }()

    private let samplesHeader = [
        "session_id", "timestamp_iso", "elapsed_s", "accepted", "reject_reason",
        "latitude", "longitude", "horizontal_accuracy_m", "vertical_accuracy_m",
        "speed_mps", "course_deg", "fix_age_s", "interval_since_last_s",
        "proximity_calc_ms", "distance_to_target_m", "memory_footprint_mb",
        "battery_level_pct", "battery_state"
    ].joined(separator: ",")

    private let summaryHeader = [
        "session_id", "start_iso", "end_iso", "duration_s",
        "total_fixes", "accepted_fixes", "rejected_fixes", "rejection_rate_pct",
        "reject_invalid_accuracy", "reject_low_accuracy", "reject_stale",
        "acc_mean_m", "acc_median_m", "acc_min_m", "acc_max_m", "acc_p90_m",
        "update_rate_hz", "interval_mean_s", "fix_age_mean_s",
        "proximity_calc_mean_ms", "proximity_calc_max_ms",
        "mem_mean_mb", "mem_peak_mb",
        "battery_start_pct", "battery_end_pct", "battery_drained_pct",
        "battery_drain_rate_pct_per_hr", "battery_charging"
    ].joined(separator: ",")

    // MARK: - Estado de la sesión activa (solo se toca en hilo principal)
    private var sessionActive = false
    private var sessionId = ""
    private var sessionStart = Date()
    private var samplesURL: URL?
    private var lastSampleTime: Date?

    private var totalFixes = 0
    private var acceptedFixes = 0
    private var rejectInvalid = 0
    private var rejectLow = 0
    private var rejectStale = 0

    private var accuracies: [Double] = []
    private var fixAges: [Double] = []
    private var intervals: [Double] = []
    private var calcTimes: [Double] = []
    private var memorySamples: [Double] = []

    private var batteryStartPct: Double = .nan
    private var batteryEndPct: Double = .nan
    private var sawCharging = false

    // MARK: - Init
    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        // La app en segundo plano o cerrándose cierra la sesión y escribe el
        // resumen. API basada en closures para no depender de NSObject/@objc.
        // El logger es un singleton (vive toda la app), así que no removemos los
        // observadores.
        let nc = NotificationCenter.default
        let closeSession: (Notification) -> Void = { [weak self] _ in self?.finishSession() }
        nc.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                       object: nil, queue: .main, using: closeSession)
        nc.addObserver(forName: UIApplication.willTerminateNotification,
                       object: nil, queue: .main, using: closeSession)
    }

    // MARK: - API pública

    /// Registra una lectura aceptada (pasó los filtros de calidad). `proximityCalcMs`
    /// es el tiempo de calcular la distancia Haversine del usuario a todos los POIs.
    func logAcceptedFix(_ location: CLLocation,
                        proximityCalcMs: Double,
                        distanceToTarget: Double) {
        ensureSessionStarted()

        let now = Date()
        let interval = intervalSinceLast(now)
        let fixAge = max(0, now.timeIntervalSince(location.timestamp))
        let mem = memoryFootprintMB()

        totalFixes += 1
        acceptedFixes += 1
        if location.horizontalAccuracy >= 0 { accuracies.append(location.horizontalAccuracy) }
        fixAges.append(fixAge)
        if let interval { intervals.append(interval) }
        calcTimes.append(proximityCalcMs)
        if let mem { memorySamples.append(mem) }
        recordBattery()

        appendSample(
            accepted: true,
            reason: "",
            location: location,
            fixAge: fixAge,
            interval: interval,
            proximityCalcMs: proximityCalcMs,
            distanceToTarget: distanceToTarget,
            memoryMB: mem,
            timestamp: now
        )
    }

    /// Registra una lectura descartada por los filtros de calidad del GPS.
    func logRejectedFix(_ location: CLLocation, reason: RejectReason) {
        ensureSessionStarted()

        let now = Date()
        let interval = intervalSinceLast(now)
        let fixAge = max(0, now.timeIntervalSince(location.timestamp))

        totalFixes += 1
        switch reason {
        case .invalidAccuracy: rejectInvalid += 1
        case .lowAccuracy:     rejectLow += 1
        case .stale:           rejectStale += 1
        }
        if let interval { intervals.append(interval) }
        recordBattery()

        appendSample(
            accepted: false,
            reason: reason.rawValue,
            location: location,
            fixAge: fixAge,
            interval: interval,
            proximityCalcMs: nil,
            distanceToTarget: .nan,
            memoryMB: nil,
            timestamp: now
        )
    }

    /// Cierra la sesión activa y escribe la fila de resumen. Idempotente.
    func finishSession() {
        guard sessionActive else { return }
        sessionActive = false

        let end = Date()
        let duration = end.timeIntervalSince(sessionStart)

        // Sin lecturas no vale la pena una fila de resumen.
        guard totalFixes > 0 else {
            resetSessionState()
            return
        }

        let rejected = totalFixes - acceptedFixes
        let rejectionRate = Double(rejected) / Double(totalFixes) * 100.0

        let accMean = mean(accuracies)
        let accMedian = percentile(accuracies, 50)
        let accP90 = percentile(accuracies, 90)
        let accMin = accuracies.min() ?? .nan
        let accMax = accuracies.max() ?? .nan

        let intervalMean = mean(intervals)
        let updateRateHz = intervalMean > 0 ? 1.0 / intervalMean : .nan
        let fixAgeMean = mean(fixAges)
        let calcMean = mean(calcTimes)
        let calcMax = calcTimes.max() ?? .nan
        let memMean = mean(memorySamples)
        let memPeak = memorySamples.max() ?? .nan

        let drained = (batteryStartPct.isNaN || batteryEndPct.isNaN)
            ? Double.nan
            : (batteryStartPct - batteryEndPct)
        let drainRatePerHr = (drained.isNaN || duration <= 0)
            ? Double.nan
            : drained / (duration / 3600.0)

        let row = [
            sessionId,
            iso(sessionStart),
            iso(end),
            num(duration, 1),
            String(totalFixes),
            String(acceptedFixes),
            String(rejected),
            num(rejectionRate, 2),
            String(rejectInvalid),
            String(rejectLow),
            String(rejectStale),
            num(accMean, 2),
            num(accMedian, 2),
            num(accMin, 2),
            num(accMax, 2),
            num(accP90, 2),
            num(updateRateHz, 3),
            num(intervalMean, 3),
            num(fixAgeMean, 3),
            num(calcMean, 4),
            num(calcMax, 4),
            num(memMean, 2),
            num(memPeak, 2),
            num(batteryStartPct, 1),
            num(batteryEndPct, 1),
            num(drained, 1),
            num(drainRatePerHr, 2),
            sawCharging ? "yes" : "no"
        ].joined(separator: ",")

        let summaryURL = logsDirectory().appendingPathComponent("gps_sessions_summary.csv")
        append(line: row, to: summaryURL, header: summaryHeader)

        print("[PerformanceLogger] Sesión \(sessionId) cerrada: \(totalFixes) lecturas, " +
              "\(acceptedFixes) aceptadas, precisión media \(num(accMean, 1))m. " +
              "Resumen -> \(summaryURL.path)")

        resetSessionState()
    }

    // MARK: - Arranque / reinicio de sesión

    private func ensureSessionStarted() {
        guard !sessionActive else { return }
        sessionActive = true
        sessionStart = Date()
        sessionId = fileStampFormatter.string(from: sessionStart)
        lastSampleTime = nil

        totalFixes = 0; acceptedFixes = 0
        rejectInvalid = 0; rejectLow = 0; rejectStale = 0
        accuracies = []; fixAges = []; intervals = []; calcTimes = []; memorySamples = []
        batteryStartPct = currentBatteryPct()
        batteryEndPct = batteryStartPct
        sawCharging = isCharging()

        let url = logsDirectory().appendingPathComponent("gps_samples_\(sessionId).csv")
        samplesURL = url
        append(line: nil, to: url, header: samplesHeader) // crea el archivo con cabecera

        print("[PerformanceLogger] Sesión \(sessionId) iniciada. Muestras -> \(url.path)")
    }

    private func resetSessionState() {
        samplesURL = nil
        lastSampleTime = nil
        accuracies = []; fixAges = []; intervals = []; calcTimes = []; memorySamples = []
    }

    // MARK: - Escritura de una muestra

    private func appendSample(accepted: Bool,
                             reason: String,
                             location: CLLocation,
                             fixAge: Double,
                             interval: Double?,
                             proximityCalcMs: Double?,
                             distanceToTarget: Double,
                             memoryMB: Double?,
                             timestamp: Date) {
        guard let url = samplesURL else { return }

        let elapsed = timestamp.timeIntervalSince(sessionStart)
        let row = [
            sessionId,
            iso(timestamp),
            num(elapsed, 2),
            accepted ? "1" : "0",
            reason,
            num(location.coordinate.latitude, 7),
            num(location.coordinate.longitude, 7),
            num(location.horizontalAccuracy, 2),
            num(location.verticalAccuracy, 2),
            num(location.speed >= 0 ? location.speed : .nan, 2),
            num(location.course >= 0 ? location.course : .nan, 1),
            num(fixAge, 3),
            interval.map { num($0, 3) } ?? "",
            proximityCalcMs.map { num($0, 4) } ?? "",
            num(distanceToTarget, 2),
            memoryMB.map { num($0, 2) } ?? "",
            num(currentBatteryPct(), 1),
            batteryStateString()
        ].joined(separator: ",")

        append(line: row, to: url, header: samplesHeader)
    }

    private func intervalSinceLast(_ now: Date) -> Double? {
        defer { lastSampleTime = now }
        guard let last = lastSampleTime else { return nil }
        return now.timeIntervalSince(last)
    }

    // MARK: - Muestreo de sistema

    private func memoryFootprintMB() -> Double? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return Double(info.phys_footprint) / 1024.0 / 1024.0
    }

    private func currentBatteryPct() -> Double {
        let level = UIDevice.current.batteryLevel // 0...1, o -1 si se desconoce
        return level >= 0 ? Double(level) * 100.0 : .nan
    }

    private func isCharging() -> Bool {
        switch UIDevice.current.batteryState {
        case .charging, .full: return true
        default:               return false
        }
    }

    private func batteryStateString() -> String {
        switch UIDevice.current.batteryState {
        case .charging: return "charging"
        case .full:     return "full"
        case .unplugged: return "unplugged"
        default:        return "unknown"
        }
    }

    private func recordBattery() {
        let pct = currentBatteryPct()
        if !pct.isNaN { batteryEndPct = pct }
        if isCharging() { sawCharging = true }
    }

    // MARK: - Utilidades de archivo

    private func logsDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("PerformanceLogs", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Añade una línea al CSV (creándolo con `header` si no existe). `line == nil`
    /// solo crea el archivo con cabecera. La E/S va en una cola serial.
    private func append(line: String?, to url: URL, header: String) {
        ioQueue.async {
            let fm = FileManager.default
            if !fm.fileExists(atPath: url.path) {
                try? (header + "\n").write(to: url, atomically: true, encoding: .utf8)
            }
            guard let line else { return }
            guard let handle = try? FileHandle(forWritingTo: url) else { return }
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            if let data = (line + "\n").data(using: .utf8) {
                handle.write(data)
            }
        }
    }

    // MARK: - Estadística y formato

    private func mean(_ xs: [Double]) -> Double {
        guard !xs.isEmpty else { return .nan }
        return xs.reduce(0, +) / Double(xs.count)
    }

    private func percentile(_ xs: [Double], _ p: Double) -> Double {
        guard !xs.isEmpty else { return .nan }
        let sorted = xs.sorted()
        if sorted.count == 1 { return sorted[0] }
        let rank = (p / 100.0) * Double(sorted.count - 1)
        let lower = Int(rank.rounded(.down))
        let upper = Int(rank.rounded(.up))
        let weight = rank - Double(lower)
        return sorted[lower] * (1 - weight) + sorted[upper] * weight
    }

    private func iso(_ date: Date) -> String { isoFormatter.string(from: date) }

    /// Formatea con `decimals` decimales; NaN/infinito -> "" (celda vacía en el CSV).
    private func num(_ value: Double, _ decimals: Int) -> String {
        guard value.isFinite else { return "" }
        return String(format: "%.\(decimals)f", value)
    }
}
