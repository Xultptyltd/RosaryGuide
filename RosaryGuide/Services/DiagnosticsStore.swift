import Foundation
#if canImport(MetricKit)
import MetricKit
#endif

/// A small rolling store of MetricKit JSON payloads in Application Support.
///
/// Nothing here leaves the device: payloads are only read back when the person taps
/// "Share diagnostics" in Settings and picks a destination in the share sheet.
/// Files are ordered by a timestamp in their *name*, so no file-date APIs are used.
struct DiagnosticsStore {
    static let defaultMaxFiles = 10
    static let defaultMaxBytes = 2 * 1024 * 1024
    static let exportFileName = "RosaryGuide-diagnostics.json"

    let directory: URL
    var maxFiles: Int = DiagnosticsStore.defaultMaxFiles
    var maxBytes: Int = DiagnosticsStore.defaultMaxBytes

    static var standard: DiagnosticsStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return DiagnosticsStore(directory: base.appendingPathComponent("Diagnostics", isDirectory: true))
    }

    enum Kind: String {
        case diagnostic
        case metric
    }

    /// Saves one payload, then deletes the oldest files until both caps hold.
    /// A payload larger than the whole size cap is dropped.
    @discardableResult
    func save(_ json: Data, kind: Kind, at date: Date = Date()) -> URL? {
        guard !json.isEmpty, json.count <= maxBytes else { return nil }
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            var dir = directory
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? dir.setResourceValues(values)

            let millis = Int64((date.timeIntervalSince1970 * 1000).rounded())
            var url = directory.appendingPathComponent(String(format: "%015lld-%@.json", millis, kind.rawValue))
            var suffix = 1
            while fm.fileExists(atPath: url.path) {
                url = directory.appendingPathComponent(String(format: "%015lld-%@-%d.json", millis, kind.rawValue, suffix))
                suffix += 1
            }
            try json.write(to: url, options: .atomic)
            prune()
            return fm.fileExists(atPath: url.path) ? url : nil
        } catch {
            return nil
        }
    }

    /// Stored payload files, oldest first.
    func files() -> [URL] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return names
            .filter { $0.hasSuffix(".json") }
            .sorted()
            .map { directory.appendingPathComponent($0) }
    }

    var isEmpty: Bool { files().isEmpty }

    /// Deletes the oldest files until there are at most `maxFiles` totalling at most `maxBytes`.
    func prune() {
        var entries = files().map { url in (url, (try? Data(contentsOf: url))?.count ?? 0) }
        var total = entries.reduce(0) { $0 + $1.1 }
        while !entries.isEmpty, entries.count > maxFiles || total > maxBytes {
            let oldest = entries.removeFirst()
            try? FileManager.default.removeItem(at: oldest.0)
            total -= oldest.1
        }
    }

    /// Deletes the whole diagnostics folder and any earlier export (used by "Clear app history").
    func removeAll(exportFolder: URL = FileManager.default.temporaryDirectory) {
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.removeItem(at: exportFolder.appendingPathComponent(Self.exportFileName))
    }

    /// One JSON file holding every stored payload, written to the temporary directory for
    /// the share sheet. Nil when there is nothing to share.
    func exportCombined(appVersion: String = Self.appVersion, to folder: URL = FileManager.default.temporaryDirectory) -> URL? {
        let payloads: [[String: Any]] = files().compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
            let name = url.deletingPathExtension().lastPathComponent
            let kind = name.contains(Kind.diagnostic.rawValue) ? Kind.diagnostic.rawValue : Kind.metric.rawValue
            return ["file": url.lastPathComponent, "kind": kind, "payload": object]
        }
        guard !payloads.isEmpty else { return nil }
        let combined: [String: Any] = [
            "app": "Rosary Guide",
            "version": appVersion,
            "exported": ISO8601DateFormatter().string(from: Date()),
            "payloads": payloads
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: combined, options: [.prettyPrinted, .sortedKeys]) else { return nil }
        let url = folder.appendingPathComponent(Self.exportFileName)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}

#if canImport(MetricKit) && os(iOS)
/// Receives MetricKit's daily metric and diagnostic (crash, hang, CPU and disk-write
/// exception) payloads and keeps them in `DiagnosticsStore.standard`.
final class MetricsCollector: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricsCollector()

    private let queue = DispatchQueue(label: "RosaryGuide.Diagnostics", qos: .utility)
    private let store: DiagnosticsStore

    init(store: DiagnosticsStore = .standard) {
        self.store = store
        super.init()
    }

    /// Registers off the main thread so launch is not delayed.
    func start() {
        queue.async { MXMetricManager.shared.add(self) }
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        let blobs = payloads.map { $0.jsonRepresentation() }
        queue.async { [store] in blobs.forEach { store.save($0, kind: .metric) } }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        let blobs = payloads.map { $0.jsonRepresentation() }
        queue.async { [store] in blobs.forEach { store.save($0, kind: .diagnostic) } }
    }
}
#endif
