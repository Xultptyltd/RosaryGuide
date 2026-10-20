import Foundation
import FirebaseFirestore
import Observation
import OSLog
import UIKit

// MARK: - Synced models

extension Date {
    /// Firestore timestamps and UserDefaults doubles do not round-trip every bit of a `Date`,
    /// so every synced date is kept to whole milliseconds. That keeps "has this changed?"
    /// comparisons stable and stops a write from bouncing back as a fresh change.
    var syncRounded: Date {
        Date(timeIntervalSince1970: (timeIntervalSince1970 * 1000).rounded() / 1000)
    }

    static let syncNever = Date(timeIntervalSince1970: 0)
}

/// User-facing preferences that follow the account between devices.
/// Device-only state (onboarding seen, notification permission, caches) is not included.
struct SyncedPreferences: Codable, Equatable {
    var appearance: AppearancePreference
    var prayerLanguage: PrayerLanguage
    var rosaryLanguage: PrayerLanguage
    var textSize: PrayerTextSize
    var includeSaintMichael: Bool
    var hideIntentionText: Bool
    var dailyReminderEnabled: Bool
    var dailyReminderMinutes: Int
    var feastAlertsEnabled: Bool
    /// Feast day alert time as minutes after local midnight (default 8:00 am).
    var feastAlertMinutes: Int
    var appIcon: AppIconOption
    /// When the user last changed any of these. `.syncNever` means never (defaults or values
    /// from before sync existed), so any copy in the account wins.
    var updatedAt: Date
    /// Optional prayers and Bible translation. Nil in copies saved before this was synced,
    /// which then keep the device's own Rosary settings.
    var rosaryConfig: RosaryConfig? = nil
    /// When each field was last changed, keyed by `Field` raw value. Current copies hold every
    /// field; a field without an entry (copies saved before this existed) counts as changed at
    /// `updatedAt`, so those merge as before.
    var fieldUpdatedAt: [String: Date] = [:]

    /// The fields merged one by one. Raw values match firestore.rules `validFieldTimes`.
    enum Field: String, CaseIterable {
        case appearance, prayerLanguage, rosaryLanguage, textSize, includeSaintMichael, hideIntentionText
        case dailyReminderEnabled, dailyReminderMinutes, feastAlertsEnabled, feastAlertMinutes, appIcon
        case rosaryConfig
    }

    /// How much of the document the deployed rules accept. Rules older than this build reject
    /// unknown keys, so the app steps down after a permission error and keeps the rest syncing.
    enum Schema: Int, Comparable {
        case full = 0
        case withoutFieldTimes = 1
        case withoutRosaryConfig = 2

        static func < (a: Schema, b: Schema) -> Bool { a.rawValue < b.rawValue }
    }

    static let defaults = SyncedPreferences(
        appearance: .system,
        prayerLanguage: .english,
        rosaryLanguage: .english,
        textSize: .medium,
        includeSaintMichael: false,
        hideIntentionText: false,
        dailyReminderEnabled: false,
        dailyReminderMinutes: 19 * 60,
        feastAlertsEnabled: false,
        feastAlertMinutes: SyncedPreferences.defaultFeastAlertMinutes,
        appIcon: .blue,
        updatedAt: .syncNever
    )

    static let defaultFeastAlertMinutes = 8 * 60

    private enum CodingKeys: String, CodingKey {
        case appearance, prayerLanguage, rosaryLanguage, textSize, includeSaintMichael, hideIntentionText
        case dailyReminderEnabled, dailyReminderMinutes, feastAlertsEnabled, feastAlertMinutes, appIcon, updatedAt
        case rosaryConfig, fieldUpdatedAt
    }

    var normalized: SyncedPreferences {
        var copy = self
        copy.updatedAt = updatedAt.syncRounded
        copy.dailyReminderMinutes = max(0, min(24 * 60 - 1, dailyReminderMinutes))
        copy.feastAlertMinutes = max(0, min(24 * 60 - 1, feastAlertMinutes))
        let known = Set(Field.allCases.map(\.rawValue))
        copy.fieldUpdatedAt = fieldUpdatedAt
            .filter { known.contains($0.key) }
            .mapValues(\.syncRounded)
        return copy
    }

    /// When `field` was last changed in this copy.
    func changedAt(_ field: Field) -> Date {
        fieldUpdatedAt[field.rawValue] ?? updatedAt
    }

    /// What the account keeps of this copy under `schema`, for "does it need uploading?".
    func stored(as schema: Schema) -> SyncedPreferences {
        var copy = normalized
        if schema >= .withoutFieldTimes { copy.fieldUpdatedAt = [:] }
        if schema >= .withoutRosaryConfig { copy.rosaryConfig = nil }
        return copy
    }

    /// Last write wins per field, by each field's own change time, so changing the text size
    /// on one device and the reminder on another keeps both. Ties go to the account copy.
    /// Change times from a clock running ahead count as now, so they cannot win for ever.
    static func merge(local: SyncedPreferences, remote: SyncedPreferences, now: Date = .now) -> SyncedPreferences {
        let limit = now.syncRounded
        var merged = local
        merged.updatedAt = max(local.updatedAt, remote.updatedAt)
        merged.fieldUpdatedAt = [:]

        for field in Field.allCases {
            let localTime = local.changedAt(field)
            let remoteTime = remote.changedAt(field)
            var useRemote = min(remoteTime, limit) >= min(localTime, limit)
            // Copies from before Rosary settings synced carry none; keep the other side's.
            if field == .rosaryConfig {
                if remote.rosaryConfig == nil { useRemote = false }
                else if local.rosaryConfig == nil { useRemote = true }
            }
            let source = useRemote ? remote : local
            merged.fieldUpdatedAt[field.rawValue] = useRemote ? remoteTime : localTime
            switch field {
            case .appearance: merged.appearance = source.appearance
            case .prayerLanguage: merged.prayerLanguage = source.prayerLanguage
            case .rosaryLanguage: merged.rosaryLanguage = source.rosaryLanguage
            case .textSize: merged.textSize = source.textSize
            case .includeSaintMichael: merged.includeSaintMichael = source.includeSaintMichael
            case .hideIntentionText: merged.hideIntentionText = source.hideIntentionText
            case .dailyReminderEnabled: merged.dailyReminderEnabled = source.dailyReminderEnabled
            case .dailyReminderMinutes: merged.dailyReminderMinutes = source.dailyReminderMinutes
            case .feastAlertsEnabled: merged.feastAlertsEnabled = source.feastAlertsEnabled
            case .feastAlertMinutes: merged.feastAlertMinutes = source.feastAlertMinutes
            case .appIcon: merged.appIcon = source.appIcon
            case .rosaryConfig: merged.rosaryConfig = source.rosaryConfig
            }
        }
        return merged.normalized
    }
}

extension SyncedPreferences {
    /// Device copies saved before `feastAlertMinutes` existed decode with the 8:00 am default.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            appearance: try c.decode(AppearancePreference.self, forKey: .appearance),
            prayerLanguage: try c.decode(PrayerLanguage.self, forKey: .prayerLanguage),
            rosaryLanguage: try c.decode(PrayerLanguage.self, forKey: .rosaryLanguage),
            textSize: try c.decode(PrayerTextSize.self, forKey: .textSize),
            includeSaintMichael: try c.decode(Bool.self, forKey: .includeSaintMichael),
            hideIntentionText: try c.decode(Bool.self, forKey: .hideIntentionText),
            dailyReminderEnabled: try c.decode(Bool.self, forKey: .dailyReminderEnabled),
            dailyReminderMinutes: try c.decode(Int.self, forKey: .dailyReminderMinutes),
            feastAlertsEnabled: try c.decode(Bool.self, forKey: .feastAlertsEnabled),
            feastAlertMinutes: try c.decodeIfPresent(Int.self, forKey: .feastAlertMinutes) ?? Self.defaultFeastAlertMinutes,
            appIcon: try c.decode(AppIconOption.self, forKey: .appIcon),
            updatedAt: try c.decode(Date.self, forKey: .updatedAt),
            rosaryConfig: try c.decodeIfPresent(RosaryConfig.self, forKey: .rosaryConfig),
            fieldUpdatedAt: try c.decodeIfPresent([String: Date].self, forKey: .fieldUpdatedAt) ?? [:]
        )
    }
}

/// Prayer progress that follows the account: prayed days and the in-progress rosary.
struct SyncedProgress: Codable, Equatable {
    /// Local calendar days ("yyyy-MM-dd") on which a rosary was finished.
    var completedDays: Set<String>
    var session: PrayerSession?
    /// When the in-progress rosary was last started, advanced, finished or discarded.
    var sessionChangedAt: Date
    /// Set by "Delete local data"; days from before it are not merged back in.
    var historyResetAt: Date?
    /// Every finished Rosary in the history window (the record behind totals and the Journey),
    /// merged by id so none is counted twice. Nil when this copy does not carry them (account
    /// documents and device copies from before they synced); nil never removes anything.
    var rosaries: [CompletedPrayerSession]? = nil

    /// Most finished Rosaries kept in the account document (well under its size limit).
    static let maxRosaries = 1500

    /// How much of the document the deployed rules accept (see `SyncedPreferences.Schema`).
    /// Each step also drops what the steps before it dropped.
    enum Schema: Int, Comparable {
        case full = 0
        case withoutRosaries = 1
        /// The in-progress Rosary carries only its first intention and no Rosary settings.
        case withoutSessionExtras = 2

        static func < (a: Schema, b: Schema) -> Bool { a.rawValue < b.rawValue }
    }

    static let empty = SyncedProgress(completedDays: [], session: nil, sessionChangedAt: .syncNever, historyResetAt: nil)

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func date(forDayKey key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) else {
            return nil
        }
        return calendar.startOfDay(for: date)
    }

    static func cutoffDayKey(now: Date = .now, calendar: Calendar = .current) -> String {
        let cutoff = calendar.date(byAdding: .day, value: -SessionStore.historyWindowDays, to: now) ?? now
        return dayKey(for: cutoff, calendar: calendar)
    }

    var normalized: SyncedProgress {
        var copy = self
        copy.sessionChangedAt = sessionChangedAt.syncRounded
        copy.historyResetAt = historyResetAt?.syncRounded
        if var session = copy.session {
            session.startedAt = session.startedAt.syncRounded
            session.updatedAt = session.updatedAt.syncRounded
            session.intentionIds = Array(session.intentionIds.prefix(PrayerSession.maxIntentions))
            session.intentionTitles = session.intentionTitles
                .prefix(PrayerSession.maxIntentions)
                .map { $0.count > 160 ? String($0.prefix(160)) : $0 }
            copy.session = session
        }
        let cutoff = Self.cutoffDayKey()
        copy.completedDays = completedDays.filter { Self.date(forDayKey: $0) != nil && $0 >= cutoff }
        copy.rosaries = rosaries.map { Self.normalizedRosaries($0, cutoffDayKey: cutoff) }
        return copy
    }

    /// One record per id (the first wins), newest first, inside the history window.
    static func normalizedRosaries(_ records: [CompletedPrayerSession], cutoffDayKey cutoff: String) -> [CompletedPrayerSession] {
        var seen = Set<UUID>()
        var result: [CompletedPrayerSession] = []
        for var record in records where seen.insert(record.id).inserted {
            guard dayKey(for: record.completedAt) >= cutoff else { continue }
            record.startedAt = record.startedAt.syncRounded
            record.completedAt = record.completedAt.syncRounded
            record.duration = max(0, (record.duration * 1000).rounded() / 1000)
            record.intentionTitle = record.intentionTitle.map { String($0.prefix(160)) }
            record.intentionIds = record.intentionIds.map { Array($0.prefix(PrayerSession.maxIntentions)) }
            record.intentionTitles = record.intentionTitles.map { Array($0.prefix(PrayerSession.maxIntentions).map { String($0.prefix(160)) }) }
            result.append(record)
        }
        result.sort { $0.completedAt != $1.completedAt ? $0.completedAt > $1.completedAt : $0.id.uuidString < $1.id.uuidString }
        return Array(result.prefix(maxRosaries))
    }

    /// What the account keeps of this copy under `schema`, for "does it need uploading?".
    func stored(as schema: Schema) -> SyncedProgress {
        var copy = normalized
        if schema >= .withoutRosaries { copy.rosaries = nil }
        if schema >= .withoutSessionExtras, var session = copy.session {
            session.intentionIds = Array(session.intentionIds.prefix(1))
            session.intentionTitles = Array(session.intentionTitles.prefix(1))
            session.rosaryConfig = .default
            copy.session = session
        }
        return copy
    }

    /// An account document written before the in-progress Rosary carried its full intention
    /// list and Rosary settings has neither key. For the same Rosary, keep what this device
    /// knows instead of the single intention and default settings the document implies.
    func fillingSessionFields(missingIn data: [String: Any], from local: PrayerSession?) -> SyncedProgress {
        guard var incoming = session, let local,
              let map = data["session"] as? [String: Any],
              incoming.startedAt.syncRounded == local.startedAt.syncRounded,
              incoming.mysterySet == local.mysterySet,
              incoming.intentionId == local.intentionId
        else { return self }
        if map["intentionIds"] == nil {
            incoming.intentionIds = local.intentionIds
            incoming.intentionTitles = local.intentionTitles
        }
        if map["rosaryConfig"] == nil {
            incoming.rosaryConfig = local.rosaryConfig
        }
        var copy = self
        copy.session = incoming
        return copy.normalized
    }

    /// Prayed days are a union (minus anything wiped by the newest "Delete local data").
    /// The in-progress rosary is last write wins; ties go to the account copy.
    static func merge(local: SyncedProgress, remote: SyncedProgress) -> SyncedProgress {
        let reset = [local.historyResetAt, remote.historyResetAt].compactMap { $0 }.max()

        func contribution(_ progress: SyncedProgress) -> Set<String> {
            guard let reset, (progress.historyResetAt ?? .distantPast) < reset else {
                return progress.completedDays
            }
            // This side has not seen the newest wipe: only days after it still count.
            let resetDay = dayKey(for: reset)
            return progress.completedDays.filter { $0 > resetDay }
        }

        let newer = remote.sessionChangedAt >= local.sessionChangedAt ? remote : local
        var session = newer.session
        if let current = session, !current.isResumable {
            session = nil
        }

        // Finished Rosaries: union by id (the device's record wins a duplicate), minus any
        // finished before the newest wipe.
        var rosaries: [CompletedPrayerSession]?
        if local.rosaries != nil || remote.rosaries != nil {
            let all = (local.rosaries ?? []) + (remote.rosaries ?? [])
            rosaries = all.filter { record in reset.map { record.completedAt > $0 } ?? true }
        }
        var days = contribution(local).union(contribution(remote))
        for record in rosaries ?? [] {
            days.insert(SessionStore.creditedDayKey(startedAt: record.startedAt, completedAt: record.completedAt))
        }
        return SyncedProgress(
            completedDays: days,
            session: session,
            sessionChangedAt: newer.sessionChangedAt,
            historyResetAt: reset,
            rosaries: rosaries
        ).normalized
    }
}

// MARK: - Firestore mapping

private extension SyncedPreferences {
    init?(firestore data: [String: Any]) {
        guard
            let appearance = (data["appearance"] as? String).flatMap(AppearancePreference.init(rawValue:)),
            let prayerLanguage = (data["prayerLanguage"] as? String).flatMap(PrayerLanguage.init(rawValue:)),
            let rosaryLanguage = (data["rosaryLanguage"] as? String).flatMap(PrayerLanguage.init(rawValue:)),
            let textSize = (data["textSize"] as? String).flatMap(PrayerTextSize.init(rawValue:)),
            let includeSaintMichael = data["includeSaintMichael"] as? Bool,
            let hideIntentionText = data["hideIntentionText"] as? Bool,
            let dailyReminderEnabled = data["dailyReminderEnabled"] as? Bool,
            let dailyReminderMinutes = data["dailyReminderMinutes"] as? Int,
            let feastAlertsEnabled = data["feastAlertsEnabled"] as? Bool,
            let appIcon = (data["appIcon"] as? String).flatMap(AppIconOption.init(rawValue:)),
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        else { return nil }

        self.init(
            appearance: appearance,
            prayerLanguage: prayerLanguage,
            rosaryLanguage: rosaryLanguage,
            textSize: textSize,
            includeSaintMichael: includeSaintMichael,
            hideIntentionText: hideIntentionText,
            dailyReminderEnabled: dailyReminderEnabled,
            dailyReminderMinutes: dailyReminderMinutes,
            feastAlertsEnabled: feastAlertsEnabled,
            // Documents written before this field existed get the 8:00 am default.
            feastAlertMinutes: data["feastAlertMinutes"] as? Int ?? Self.defaultFeastAlertMinutes,
            appIcon: appIcon,
            updatedAt: updatedAt,
            rosaryConfig: (data["rosaryConfig"] as? [String: Any]).map(RosaryConfig.init(firestore:)),
            fieldUpdatedAt: (data["fieldUpdatedAt"] as? [String: Any] ?? [:])
                .compactMapValues { ($0 as? Timestamp)?.dateValue() }
        )
        self = normalized
    }

    func firestoreData(schema: Schema = .full) -> [String: Any] {
        var data: [String: Any] = [
            "schemaVersion": 1,
            "appearance": appearance.rawValue,
            "prayerLanguage": prayerLanguage.rawValue,
            "rosaryLanguage": rosaryLanguage.rawValue,
            "textSize": textSize.rawValue,
            "includeSaintMichael": includeSaintMichael,
            "hideIntentionText": hideIntentionText,
            "dailyReminderEnabled": dailyReminderEnabled,
            "dailyReminderMinutes": max(0, min(24 * 60 - 1, dailyReminderMinutes)),
            "feastAlertsEnabled": feastAlertsEnabled,
            "feastAlertMinutes": max(0, min(24 * 60 - 1, feastAlertMinutes)),
            "appIcon": appIcon.rawValue,
            "updatedAt": Timestamp(date: updatedAt)
        ]
        if let rosaryConfig, schema < .withoutRosaryConfig {
            data["rosaryConfig"] = rosaryConfig.firestoreData()
        }
        if !fieldUpdatedAt.isEmpty, schema < .withoutFieldTimes {
            data["fieldUpdatedAt"] = fieldUpdatedAt.mapValues { Timestamp(date: $0) }
        }
        return data
    }
}

/// Matches `validRosaryConfig` in firestore.rules.
extension RosaryConfig {
    init(firestore map: [String: Any]) {
        self.init()
        if let raw = map["translation"] as? String, let value = BibleTranslation(storedValue: raw) {
            translation = value
        }
        fatimaPrayer = map["fatimaPrayer"] as? Bool ?? fatimaPrayer
        oSacrament = map["oSacrament"] as? Bool ?? oSacrament
        closingPrayers = map["closingPrayers"] as? Bool ?? closingPrayers
        memorare = map["memorare"] as? Bool ?? memorare
        saintMichael = map["saintMichael"] as? Bool ?? saintMichael
        intentionsStep = map["intentionsStep"] as? Bool ?? intentionsStep
    }

    func firestoreData() -> [String: Any] {
        [
            "translation": translation.firestoreValue,
            "fatimaPrayer": fatimaPrayer,
            "oSacrament": oSacrament,
            "closingPrayers": closingPrayers,
            "memorare": memorare,
            "saintMichael": saintMichael,
            "intentionsStep": intentionsStep
        ]
    }
}

extension SyncedProgress {
    init?(firestore data: [String: Any]) {
        guard
            let days = data["completedDays"] as? [String],
            let sessionChangedAt = (data["sessionChangedAt"] as? Timestamp)?.dateValue()
        else { return nil }

        var session: PrayerSession?
        if let map = data["session"] as? [String: Any],
           let set = (map["mysterySet"] as? String).flatMap(MysterySetKind.init(rawValue:)),
           let stepIndex = map["stepIndex"] as? Int,
           let startedAt = (map["startedAt"] as? Timestamp)?.dateValue(),
           let updatedAt = (map["updatedAt"] as? Timestamp)?.dateValue(),
           let includeSaintMichael = map["includeSaintMichael"] as? Bool,
           let language = (map["language"] as? String).flatMap(PrayerLanguage.init(rawValue:)) {
            session = PrayerSession(
                mysterySet: set,
                stepIndex: stepIndex,
                startedAt: startedAt,
                updatedAt: updatedAt,
                includeSaintMichael: includeSaintMichael,
                language: language,
                intentionId: (map["intentionId"] as? String).flatMap(UUID.init(uuidString:)),
                intentionTitle: map["intentionTitle"] as? String,
                // Older clients only write the single keys; the initializer falls back to them.
                intentionIds: (map["intentionIds"] as? [String])?.compactMap(UUID.init(uuidString:)),
                intentionTitles: map["intentionTitles"] as? [String],
                // Documents from before Rosary settings synced decode as `.default`;
                // `fillingSessionFields(missingIn:from:)` keeps this device's settings for them.
                rosaryConfig: (map["rosaryConfig"] as? [String: Any]).map(RosaryConfig.init(firestore:)) ?? .default
            )
        }

        self.init(
            completedDays: Set(days),
            session: session,
            sessionChangedAt: sessionChangedAt,
            historyResetAt: (data["historyResetAt"] as? Timestamp)?.dateValue(),
            rosaries: (data["rosaries"] as? [String: Any]).map { map in
                map.compactMap { key, value in
                    (value as? [String: Any]).flatMap { CompletedPrayerSession(firestoreId: key, data: $0) }
                }
            }
        )
        self = normalized
    }

    func firestoreData(schema: Schema = .full) -> [String: Any] {
        let value = normalized
        var data: [String: Any] = [
            "schemaVersion": 1,
            "completedDays": value.completedDays.sorted(),
            "sessionChangedAt": Timestamp(date: value.sessionChangedAt),
            "updatedAt": Timestamp(date: Date())
        ]
        if let reset = value.historyResetAt {
            data["historyResetAt"] = Timestamp(date: reset)
        }
        if let session = value.session {
            var map: [String: Any] = [
                "mysterySet": session.mysterySet.rawValue,
                "stepIndex": max(0, min(500, session.stepIndex)),
                "startedAt": Timestamp(date: session.startedAt),
                "updatedAt": Timestamp(date: session.updatedAt),
                "includeSaintMichael": session.includeSaintMichael,
                "language": session.language.rawValue
            ]
            if let id = session.intentionId {
                map["intentionId"] = id.uuidString
            }
            if let title = session.intentionTitle {
                map["intentionTitle"] = title
            }
            // The single keys stay for older builds, which read only those.
            if schema < .withoutSessionExtras {
                map["intentionIds"] = session.intentionIds.map(\.uuidString)
                map["intentionTitles"] = session.intentionTitles
                map["rosaryConfig"] = session.rosaryConfig.firestoreData()
            }
            data["session"] = map
        }
        if let rosaries = value.rosaries, schema < .withoutRosaries {
            data["rosaries"] = Dictionary(uniqueKeysWithValues: rosaries.map { ($0.id.uuidString, $0.firestoreData()) })
        }
        return data
    }
}

/// One finished Rosary in `progress.rosaries`, keyed by its id. Matches `validRosaries`.
private extension CompletedPrayerSession {
    init?(firestoreId: String, data: [String: Any]) {
        guard
            let id = UUID(uuidString: firestoreId),
            let set = (data["mysterySet"] as? String).flatMap(MysterySetKind.init(rawValue:)),
            let startedAt = (data["startedAt"] as? Timestamp)?.dateValue(),
            let completedAt = (data["completedAt"] as? Timestamp)?.dateValue()
        else { return nil }
        self.init(
            id: id,
            sessionId: (data["sessionId"] as? String).flatMap(UUID.init(uuidString:)),
            mysterySet: set,
            startedAt: startedAt,
            completedAt: completedAt,
            duration: (data["duration"] as? NSNumber)?.doubleValue ?? 0,
            intentionId: (data["intentionId"] as? String).flatMap(UUID.init(uuidString:)),
            intentionTitle: data["intentionTitle"] as? String,
            intentionCategory: (data["intentionCategory"] as? String).flatMap(IntentionCategory.init(rawValue:)),
            intentionSourceId: data["intentionSourceId"] as? String,
            intentionIds: (data["intentionIds"] as? [String])?.compactMap(UUID.init(uuidString:)),
            intentionTitles: data["intentionTitles"] as? [String]
        )
    }

    func firestoreData() -> [String: Any] {
        var map: [String: Any] = [
            "mysterySet": mysterySet.rawValue,
            "startedAt": Timestamp(date: startedAt),
            "completedAt": Timestamp(date: completedAt),
            "duration": duration
        ]
        if let sessionId { map["sessionId"] = sessionId.uuidString }
        if let intentionId { map["intentionId"] = intentionId.uuidString }
        if let intentionTitle { map["intentionTitle"] = intentionTitle }
        if let intentionCategory { map["intentionCategory"] = intentionCategory.rawValue }
        if let intentionSourceId { map["intentionSourceId"] = intentionSourceId }
        if let intentionIds { map["intentionIds"] = intentionIds.map(\.uuidString) }
        if let intentionTitles { map["intentionTitles"] = intentionTitles }
        return map
    }
}

// MARK: - Repository

struct AccountDocumentSnapshot {
    var data: [String: Any]?
    var isFromCache: Bool
}

/// `/users/{uid}/meta/preferences` and `/users/{uid}/meta/progress`.
/// Uses `Firestore.firestore()` on every call: account deletion terminates the shared instance,
/// and a fresh call returns a working one afterwards.
private final class AccountDataRepository {
    enum Document: String, CaseIterable {
        case preferences
        case progress
    }

    func listen(_ document: Document, uid: String, onChange: @escaping (Result<AccountDocumentSnapshot, Error>) -> Void) -> ListenerRegistration {
        reference(document, uid: uid).addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }
            guard let snapshot else { return }
            onChange(.success(AccountDocumentSnapshot(
                data: snapshot.exists ? snapshot.data() : nil,
                isFromCache: snapshot.metadata.isFromCache
            )))
        }
    }

    /// Queues the write in Firestore's offline store at once; the completion runs when the
    /// server accepts or rejects it.
    func write(_ data: [String: Any], to document: Document, uid: String, completion: @escaping (Error?) -> Void) {
        reference(document, uid: uid).setData(data, merge: false, completion: completion)
    }

    func deleteAll(uid: String) async throws {
        for document in Document.allCases {
            try await reference(document, uid: uid).delete()
        }
    }

    private func reference(_ document: Document, uid: String) -> DocumentReference {
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("meta").document(document.rawValue)
    }
}

// MARK: - Store

/// Keeps preferences and prayer progress in step with the signed-in account.
///
/// Local first: the app always reads and writes `SettingsStore` and `SessionStore`, which work
/// offline and signed out. Each account also has its own copy on this device, so switching
/// accounts never mixes data. While signed in, changes are uploaded after a short pause, and
/// account changes from other devices are merged in (preferences: last write wins by
/// `updatedAt`; prayed days: union).
@Observable
@MainActor
final class AccountSyncStore {
    private enum Keys {
        /// The account whose data `SettingsStore` and `SessionStore` currently hold.
        static let activeOwner = "sync.activeOwner"
        static func preferences(_ uid: String) -> String { "sync.preferences." + uid }
        static func progress(_ uid: String) -> String { "sync.progress." + uid }
    }

    private static let preferencesDelay: Duration = .seconds(2)
    private static let progressDelay: Duration = .seconds(3)

    private let defaults: UserDefaults
    private let settings: SettingsStore
    private let session: SessionStore
    private let appIcon: AppIconService
    private let repository = AccountDataRepository()
    private let log = Logger(subsystem: "com.shasasmith.RosaryGuide", category: "AccountSync")

    private var userID: String?
    private var preferencesListener: ListenerRegistration?
    private var progressListener: ListenerRegistration?
    private var preferencesUpload: Task<Void, Never>?
    private var progressUpload: Task<Void, Never>?
    /// Bead-by-bead progress is not uploaded on every step (Spark quota); it goes up with the
    /// next significant change or when the app leaves the foreground.
    private var progressNeedsUpload = false
    /// A listener that failed (offline start, or rules that reject a read) is dead; it is restarted
    /// the next time the app comes to the foreground.
    private var listenerFailed = false
    /// Steps down when the deployed rules reject newer fields (see `SyncedPreferences.Schema`).
    private var preferencesSchema: SyncedPreferences.Schema = .full
    private var progressSchema: SyncedProgress.Schema = .full
    private(set) var syncErrorMessage: String?

    init(settings: SettingsStore, session: SessionStore, appIcon: AppIconService, defaults: UserDefaults = .standard) {
        self.settings = settings
        self.session = session
        self.appIcon = appIcon
        self.defaults = defaults

        if !settings.hasStoredAppIconChoice {
            settings.applySyncedAppIconChoice(appIcon.current)
        }
        settings.onUserChange = { [weak self] in
            Task { @MainActor in self?.preferencesChangedLocally() }
        }
        session.onUserChange = { [weak self] significant in
            Task { @MainActor in self?.progressChangedLocally(significant: significant) }
        }
        appIcon.onUserSelect = { [weak settings] option in
            settings?.appIconChoice = option
        }
        settings.migrateToBluePrimaryIcon(showing: appIcon.current)
    }

    private var activeOwner: String? {
        get { defaults.string(forKey: Keys.activeOwner) }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Keys.activeOwner)
            } else {
                defaults.removeObject(forKey: Keys.activeOwner)
            }
        }
    }

    // MARK: Account switching

    /// Switches to the signed-in account's data (signed out keeps the current data on device).
    func configureSync(for uid: String?) {
        if uid == userID && (uid == nil || preferencesListener != nil) { return }

        stopListening()
        cancelPendingUploads()
        userID = uid
        syncErrorMessage = nil

        guard let uid else { return }
        activateLocalData(for: uid)
        startListening(uid: uid)
    }

    private func activateLocalData(for uid: String) {
        session.activateMilestoneOwner(uid)
        switch activeOwner {
        case uid:
            break // Already this account's data, including any changes made while signed out.
        case nil:
            // No account owns the data on this device (first run with sync, or after a deleted
            // account). Use this account's device copy if there is one; otherwise the account
            // adopts what is here, the way older builds' intentions are adopted.
            if let preferences = loadPreferences(uid) { applyPreferences(preferences) }
            if let progress = loadProgress(uid) { session.applySynced(progress) }
        case let other?:
            saveLocalCopies(for: other)
            applyPreferences(loadPreferences(uid) ?? .defaultsKeepingIcon(appIcon.current))
            session.applySynced(loadProgress(uid) ?? .empty)
        }
        activeOwner = uid
        saveLocalCopies(for: uid)
    }

    // MARK: Listening and merging

    private func startListening(uid: String) {
        listenerFailed = false
        preferencesListener = repository.listen(.preferences, uid: uid) { [weak self] result in
            Task { @MainActor in self?.handlePreferences(result, uid: uid) }
        }
        progressListener = repository.listen(.progress, uid: uid) { [weak self] result in
            Task { @MainActor in self?.handleProgress(result, uid: uid) }
        }
    }

    private func stopListening() {
        preferencesListener?.remove()
        preferencesListener = nil
        progressListener?.remove()
        progressListener = nil
    }

    private func handlePreferences(_ result: Result<AccountDocumentSnapshot, Error>, uid: String) {
        guard uid == userID else { return }
        switch result {
        case .failure(let error):
            listenerFailed = true
            report(error, while: "listening to preferences")
        case .success(let snapshot):
            let local = settings.syncedPreferences.normalized
            guard let data = snapshot.data, let remote = SyncedPreferences(firestore: data) else {
                // Nothing in the account yet. Only a server-confirmed answer means that.
                if !snapshot.isFromCache { uploadPreferencesNow() }
                return
            }
            if !snapshot.isFromCache { syncErrorMessage = nil }
            let merged = SyncedPreferences.merge(local: local, remote: remote)
            if merged != local {
                applyPreferences(merged)
                saveLocalCopies(for: uid)
            }
            if merged.stored(as: preferencesSchema) != remote.stored(as: preferencesSchema) {
                schedulePreferencesUpload(after: .zero)
            }
        }
    }

    private func handleProgress(_ result: Result<AccountDocumentSnapshot, Error>, uid: String) {
        guard uid == userID else { return }
        switch result {
        case .failure(let error):
            listenerFailed = true
            report(error, while: "listening to progress")
        case .success(let snapshot):
            let local = session.syncedProgress.normalized
            guard let data = snapshot.data, let remote = SyncedProgress(firestore: data) else {
                if !snapshot.isFromCache { uploadProgressNow() }
                return
            }
            if !snapshot.isFromCache { syncErrorMessage = nil }
            let filled = remote.fillingSessionFields(missingIn: data, from: local.session)
            let merged = SyncedProgress.merge(local: local, remote: filled)
            if merged != local {
                session.applySynced(merged)
                saveLocalCopies(for: uid)
            }
            if merged.stored(as: progressSchema) != remote.stored(as: progressSchema) {
                scheduleProgressUpload(after: .zero)
            }
        }
    }

    /// Applies preferences without counting them as a user change, then brings notifications
    /// and the app icon in line. Notifications are only rescheduled through
    /// `NotificationService.reschedule`, which never asks for permission and schedules nothing
    /// unless it was already granted.
    private func applyPreferences(_ preferences: SyncedPreferences) {
        let oldPlan = settings.notificationPlan
        settings.applySynced(preferences)
        let plan = settings.notificationPlan
        if plan != oldPlan {
            Task { await NotificationService.reschedule(plan) }
        }
        appIcon.applySynced(preferences.appIcon)
    }

    // MARK: Local changes and uploads

    private func preferencesChangedLocally() {
        if let owner = activeOwner {
            savePreferencesCopy(for: owner)
        }
        schedulePreferencesUpload(after: Self.preferencesDelay)
    }

    private func progressChangedLocally(significant: Bool) {
        if let owner = activeOwner {
            saveProgressCopy(for: owner)
        }
        guard userID != nil else { return }
        progressNeedsUpload = true
        if significant {
            scheduleProgressUpload(after: Self.progressDelay)
        }
    }

    private func schedulePreferencesUpload(after delay: Duration) {
        guard userID != nil else { return }
        preferencesUpload?.cancel()
        preferencesUpload = Task { [weak self] in
            if delay > .zero { try? await Task.sleep(for: delay) }
            guard !Task.isCancelled else { return }
            self?.uploadPreferencesNow()
        }
    }

    private func scheduleProgressUpload(after delay: Duration) {
        guard userID != nil else { return }
        progressNeedsUpload = true
        progressUpload?.cancel()
        progressUpload = Task { [weak self] in
            if delay > .zero { try? await Task.sleep(for: delay) }
            guard !Task.isCancelled else { return }
            self?.uploadProgressNow()
        }
    }

    private func uploadPreferencesNow() {
        preferencesUpload?.cancel()
        preferencesUpload = nil
        guard let uid = userID else { return }
        if settings.preferencesUpdatedAt == .syncNever {
            // First upload of values that were never stamped (defaults or pre-sync settings).
            settings.stampPreferences()
            savePreferencesCopy(for: uid)
        }
        let schema = preferencesSchema
        let data = settings.syncedPreferences.normalized.firestoreData(schema: schema)
        repository.write(data, to: .preferences, uid: uid) { [weak self] error in
            guard let error else { return }
            Task { @MainActor in self?.preferencesWriteFailed(error, schema: schema, uid: uid) }
        }
    }

    /// Rules published before this build reject the newer fields; retry without them
    /// rather than leave every preference unsynced.
    private func preferencesWriteFailed(_ error: Error, schema: SyncedPreferences.Schema, uid: String) {
        guard uid == userID else { return }
        if Self.isPermissionDenied(error), let next = SyncedPreferences.Schema(rawValue: schema.rawValue + 1) {
            if preferencesSchema <= schema {
                log.info("Preferences rules reject schema \(schema.rawValue); retrying with \(next.rawValue)")
                preferencesSchema = next
                uploadPreferencesNow()
            }
            return
        }
        report(error, while: "saving preferences")
    }

    private static func isPermissionDenied(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == FirestoreErrorDomain && nsError.code == FirestoreErrorCode.permissionDenied.rawValue
    }

    private func uploadProgressNow() {
        progressUpload?.cancel()
        progressUpload = nil
        progressNeedsUpload = false
        guard let uid = userID else { return }
        let schema = progressSchema
        let data = session.syncedProgress.firestoreData(schema: schema)
        repository.write(data, to: .progress, uid: uid) { [weak self] error in
            guard let error else { return }
            Task { @MainActor in self?.progressWriteFailed(error, schema: schema, uid: uid) }
        }
    }

    /// Older rules reject `rosaries` or the in-progress Rosary's full intention list and settings;
    /// step down so prayed days keep syncing. The deployed rules accept the full document.
    private func progressWriteFailed(_ error: Error, schema: SyncedProgress.Schema, uid: String) {
        guard uid == userID else { return }
        if Self.isPermissionDenied(error), let next = SyncedProgress.Schema(rawValue: schema.rawValue + 1) {
            if progressSchema <= schema {
                log.info("Progress rules reject schema \(schema.rawValue); retrying with \(next.rawValue)")
                progressSchema = next
                uploadProgressNow()
            }
            return
        }
        report(error, while: "saving progress")
    }

    private func cancelPendingUploads() {
        preferencesUpload?.cancel()
        preferencesUpload = nil
        progressUpload?.cancel()
        progressUpload = nil
        progressNeedsUpload = false
    }

    // MARK: App lifecycle

    func sceneBecameActive() {
        appIcon.applyPendingSyncedIcon()
        if listenerFailed, let uid = userID {
            stopListening()
            startListening(uid: uid)
        }
    }

    /// Hands anything still waiting to Firestore, which keeps it on disk until it reaches the
    /// server, even if the app is closed.
    func sceneWillLeaveForeground() {
        guard userID != nil else { return }
        if preferencesUpload != nil { uploadPreferencesNow() }
        if progressUpload != nil || progressNeedsUpload { uploadProgressNow() }
    }

    // MARK: Account deletion

    /// Deletes this account's preferences and progress documents. Call while still signed in.
    func deleteCloudDataForCurrentUser() async throws {
        guard let uid = userID else { return }
        stopListening()
        cancelPendingUploads()
        try await repository.deleteAll(uid: uid)
    }

    /// Account deletion stopped part way: put the device copy back in the account.
    func restoreCloudDataAfterFailedDeletion() {
        guard let uid = userID else { return }
        stopListening()
        uploadPreferencesNow()
        uploadProgressNow()
        startListening(uid: uid)
    }

    /// After the Auth account is gone: remove this account's device copies and reset the
    /// synced preferences and progress on this device.
    func finishAccountDeletion(uid: String?) {
        let deletedUID = uid ?? userID
        stopListening()
        cancelPendingUploads()
        userID = nil
        if let deletedUID {
            defaults.removeObject(forKey: Keys.preferences(deletedUID))
            defaults.removeObject(forKey: Keys.progress(deletedUID))
        }
        activeOwner = nil
        applyPreferences(.defaultsKeepingIcon(appIcon.current))
        session.clearForAccountDeletion()
        syncErrorMessage = nil
    }

    // MARK: Device copies

    private func saveLocalCopies(for uid: String) {
        savePreferencesCopy(for: uid)
        saveProgressCopy(for: uid)
    }

    private func savePreferencesCopy(for uid: String) {
        if let data = try? JSONEncoder().encode(settings.syncedPreferences.normalized) {
            defaults.set(data, forKey: Keys.preferences(uid))
        }
    }

    private func saveProgressCopy(for uid: String) {
        if let data = try? JSONEncoder().encode(session.syncedProgress.normalized) {
            defaults.set(data, forKey: Keys.progress(uid))
        }
    }

    private func loadPreferences(_ uid: String) -> SyncedPreferences? {
        guard let data = defaults.data(forKey: Keys.preferences(uid)) else { return nil }
        return try? JSONDecoder().decode(SyncedPreferences.self, from: data)
    }

    private func loadProgress(_ uid: String) -> SyncedProgress? {
        guard let data = defaults.data(forKey: Keys.progress(uid)) else { return nil }
        return try? JSONDecoder().decode(SyncedProgress.self, from: data)
    }

    /// Shows a quiet notice for real failures only. Being offline is not one: Firestore keeps
    /// the change and sends it later, so connectivity errors are logged and nothing is shown.
    private func report(_ error: Error, while action: String) {
        let nsError = error as NSError
        if Self.isConnectivity(nsError) {
            log.info("Account sync waiting for the network while \(action, privacy: .public)")
            return
        }
        log.error("Account sync failed while \(action, privacy: .public): \(nsError.domain, privacy: .public) \(nsError.code) \(nsError.localizedDescription, privacy: .public)")
        #if DEBUG
        print("[AccountSync] failed while \(action): \(nsError.domain) \(nsError.code) \(nsError.localizedDescription)")
        #endif
        syncErrorMessage = "Settings and prayer history are saved on this device but could not sync"
    }

    private static func isConnectivity(_ error: NSError) -> Bool {
        if error.domain == NSURLErrorDomain { return true }
        guard error.domain == FirestoreErrorDomain else { return false }
        let codes: [FirestoreErrorCode.Code] = [.unavailable, .deadlineExceeded, .cancelled]
        return codes.map(\.rawValue).contains(error.code)
    }
}

private extension SyncedPreferences {
    /// Defaults for a fresh account, keeping the icon already on the Home Screen
    /// (changing it shows a system alert, so it only changes when the user's choice says so).
    static func defaultsKeepingIcon(_ icon: AppIconOption) -> SyncedPreferences {
        var value = SyncedPreferences.defaults
        value.appIcon = icon
        return value
    }
}
