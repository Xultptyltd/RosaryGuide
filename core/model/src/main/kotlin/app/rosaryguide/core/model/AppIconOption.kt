package app.rosaryguide.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Alternate home-screen icons. Ported from iOS `AppIconOption`. Marian blue is primary. */
@Serializable
enum class AppIconOption {
    @SerialName("blue") Blue,
    @SerialName("black") Black,
    @SerialName("white") White,
    ;

    val storageName: String
        get() = when (this) {
            Blue -> "blue"
            Black -> "black"
            White -> "white"
        }

    val title: String
        get() = when (this) {
            Blue -> "Blue"
            Black -> "Black"
            White -> "White"
        }

    companion object {
        fun fromStorage(raw: String?): AppIconOption = when (raw) {
            "black" -> Black
            "white" -> White
            else -> Blue
        }
    }
}
