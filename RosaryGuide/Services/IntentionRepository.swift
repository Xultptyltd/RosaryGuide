import Foundation
import FirebaseFirestore

protocol IntentionRepository {
    func listen(
        uid: String,
        onChange: @escaping (Result<[OfferIntention], Error>) -> Void
    ) -> ListenerRegistration
    func upsert(_ intention: OfferIntention, uid: String) async throws
    func delete(id: UUID, uid: String) async throws
    func fetchAll(uid: String) async throws -> [OfferIntention]
    func deleteAll(uid: String) async throws
    func clearLocalCache() async throws
}

enum IntentionRepositoryFactory {
    static func make() -> IntentionRepository {
        FirestoreIntentionRepository()
    }
}

private final class FirestoreIntentionRepository: IntentionRepository {
    private var cachedDatabase: Firestore?

    func listen(
        uid: String,
        onChange: @escaping (Result<[OfferIntention], Error>) -> Void
    ) -> ListenerRegistration {
        intentions(uid: uid)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                let values = snapshot?.documents.compactMap { document in
                    OfferIntention(firestoreId: document.documentID, data: document.data())
                } ?? []
                onChange(.success(values))
            }
    }

    func upsert(_ intention: OfferIntention, uid: String) async throws {
        try await document(id: intention.id, uid: uid).setData(intention.firestoreData(), merge: false)
    }

    func delete(id: UUID, uid: String) async throws {
        try await document(id: id, uid: uid).delete()
    }

    func fetchAll(uid: String) async throws -> [OfferIntention] {
        let snapshot = try await intentions(uid: uid).getDocuments()
        return snapshot.documents.compactMap { document in
            OfferIntention(firestoreId: document.documentID, data: document.data())
        }
    }

    func deleteAll(uid: String) async throws {
        let snapshot = try await intentions(uid: uid).getDocuments()
        guard !snapshot.documents.isEmpty else { return }

        var batch = database().batch()
        var count = 0
        for document in snapshot.documents {
            batch.deleteDocument(document.reference)
            count += 1
            if count == 450 {
                try await batch.commit()
                batch = database().batch()
                count = 0
            }
        }

        if count > 0 {
            try await batch.commit()
        }
    }

    func clearLocalCache() async throws {
        guard let database = cachedDatabase else { return }
        try await database.terminate()
        try await database.clearPersistence()
        cachedDatabase = nil
    }

    private func intentions(uid: String) -> CollectionReference {
        database().collection("users").document(uid).collection("intentions")
    }

    private func document(id: UUID, uid: String) -> DocumentReference {
        intentions(uid: uid).document(id.uuidString)
    }

    private func database() -> Firestore {
        if let cachedDatabase {
            return cachedDatabase
        }
        let database = Firestore.firestore()
        cachedDatabase = database
        return database
    }
}

private extension OfferIntention {
    init?(firestoreId: String, data: [String: Any]) {
        guard
            let id = UUID(uuidString: firestoreId),
            let title = data["title"] as? String,
            let timesCarried = data["timesCarried"] as? Int,
            let isPinned = data["isPinned"] as? Bool,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
            let categoryRaw = data["category"] as? String,
            let accentRaw = data["accent"] as? String,
            let category = IntentionCategory(rawValue: categoryRaw)
        else {
            return nil
        }

        let accent = IntentionAccent.firestoreValue(accentRaw)
        let note = data["note"] as? String
        let lastCarriedAt = (data["lastCarriedAt"] as? Timestamp)?.dateValue()
        let expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue()
        let sourceId = data["sourceId"] as? String
        let emoji = data["emoji"] as? String
        let suggestOn = (data["suggestOn"] as? [String] ?? []).compactMap(MysterySetKind.init(rawValue:))

        self.init(
            id: id,
            title: title,
            note: note?.isEmpty == false ? note : nil,
            timesCarried: timesCarried,
            isPinned: isPinned,
            createdAt: createdAt,
            lastCarriedAt: lastCarriedAt,
            expiresAt: expiresAt,
            sourceId: sourceId?.isEmpty == false ? sourceId : nil,
            category: category,
            accent: accent,
            emoji: emoji?.isEmpty == false ? emoji : nil,
            suggestOn: suggestOn
        )
    }

    func firestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "schemaVersion": 1,
            "title": title,
            "timesCarried": timesCarried,
            "isPinned": isPinned,
            "createdAt": Timestamp(date: createdAt),
            "category": category.rawValue,
            "accent": accent.rawValue,
            "suggestOn": suggestOn.map(\.rawValue),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let note {
            data["note"] = note
        }
        if let lastCarriedAt {
            data["lastCarriedAt"] = Timestamp(date: lastCarriedAt)
        }
        if let expiresAt {
            data["expiresAt"] = Timestamp(date: expiresAt)
        }
        if let sourceId {
            data["sourceId"] = sourceId
        }
        if let emoji {
            data["emoji"] = emoji
        }

        return data
    }
}

private extension IntentionAccent {
    static func firestoreValue(_ rawValue: String) -> IntentionAccent {
        switch rawValue {
        case "mintGreen": .mintGreen
        case "purple": .purple
        default: .skyBlue
        }
    }
}
