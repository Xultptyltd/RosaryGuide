package app.rosaryguide.core.model

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

/**
 * Bible translation for the mystery scripture on each decade's announcement.
 * Catholic editions only, all public domain.
 *
 * The deployed Firestore rules only allow 'rsv2ce', 'douayRheims' and 'vulgate',
 * so the default modern translation keeps the legacy token on the wire.
 */
@Serializable(with = BibleTranslationSerializer::class)
enum class BibleTranslation(val rawValue: String) {
    WebCatholic("webc"),
    DouayRheims("douayRheims"),
    Vulgate("vulgate"),
    ;

    val title: String
        get() = when (this) {
            WebCatholic -> "World English Bible (Catholic)"
            DouayRheims -> "Douay-Rheims"
            Vulgate -> "Latin Vulgate"
        }

    /**
     * Token for `rosaryConfig.translation` in Firestore. The default modern
     * translation keeps the legacy `rsv2ce` token there.
     */
    val firestoreValue: String
        get() = if (this == WebCatholic) LEGACY_MODERN_RAW_VALUE else rawValue

    companion object {
        /** Value saved by builds up to 1.589 (5) for the app's original modern translation. */
        const val LEGACY_MODERN_RAW_VALUE = "rsv2ce"

        fun fromStoredValue(raw: String): BibleTranslation? =
            if (raw == LEGACY_MODERN_RAW_VALUE) WebCatholic
            else entries.firstOrNull { it.rawValue == raw }
    }
}

object BibleTranslationSerializer : KSerializer<BibleTranslation> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("BibleTranslation", PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: BibleTranslation) {
        encoder.encodeString(value.rawValue)
    }

    override fun deserialize(decoder: Decoder): BibleTranslation {
        val raw = decoder.decodeString()
        return BibleTranslation.fromStoredValue(raw)
            ?: BibleTranslation.WebCatholic
    }
}
