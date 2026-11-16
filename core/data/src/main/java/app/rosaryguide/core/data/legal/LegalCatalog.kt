package app.rosaryguide.core.data.legal

import app.rosaryguide.core.data.config.RosaryJson
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer

@Serializable
data class LegalBlock(
    val id: Int,
    val kind: String,
    val text: String,
)

@Serializable
data class LicenseEntry(
    val id: String,
    val name: String,
    val version: String,
    val url: String,
    val license: String,
)

object LegalCatalog {
    fun terms(): List<LegalBlock> = loadBlocks("legal_terms.json")
    fun privacy(): List<LegalBlock> = loadBlocks("legal_privacy.json")
    fun licenses(): List<LicenseEntry> = loadLicenses()

    private fun loadBlocks(name: String): List<LegalBlock> {
        val raw = bundled(name) ?: return emptyList()
        return runCatching {
            RosaryJson.decodeFromString(ListSerializer(LegalBlock.serializer()), raw)
        }.getOrDefault(emptyList())
    }

    private fun loadLicenses(): List<LicenseEntry> {
        val raw = bundled("licenses.json") ?: return emptyList()
        return runCatching {
            RosaryJson.decodeFromString(ListSerializer(LicenseEntry.serializer()), raw)
        }.getOrDefault(emptyList())
    }

    private fun bundled(name: String): String? =
        LegalCatalog::class.java.classLoader
            ?.getResourceAsStream(name)
            ?.bufferedReader()
            ?.use { it.readText() }
}
