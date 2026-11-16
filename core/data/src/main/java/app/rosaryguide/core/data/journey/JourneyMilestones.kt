package app.rosaryguide.core.data.journey

import app.rosaryguide.core.data.catalog.FeastCatalog
import app.rosaryguide.core.data.calendar.LiturgicalCalendar
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Milestones calculated from the retained prayer record.
 * Ported from iOS `JourneyMilestones` in Services/SessionStore.swift.
 */
data class JourneyMilestones(
    val items: List<Item>,
) {
    enum class Category(val id: String, val title: String) {
        Rosaries("Rosaries", "Rosaries"),
        Feasts("Marian feast days", "Marian feast days"),
        Days("Days in prayer", "Days in prayer"),
        Mysteries("Mystery sets", "Mystery sets"),
        Offerings("Prayer for others", "Prayer for others"),
    }

    data class Item(
        val id: String,
        val category: Category,
        val title: String,
        val description: String,
        val symbol: String,
        val count: Int,
        val target: Int,
        val earnedAtEpochMs: Long?,
    ) {
        val completed: Boolean get() = earnedAtEpochMs != null
        val progress: Double get() = minOf(1.0, count.toDouble() / target.toDouble())
        val progressText: String get() = "${minOf(count, target)} of $target"
    }

    val earnedCount: Int get() = items.count { it.completed }

    fun isCategoryCompleted(category: Category): Boolean {
        val categoryItems = items.filter { it.category == category }
        return categoryItems.isNotEmpty() && categoryItems.all { it.completed }
    }

    val orderedCategories: List<Category>
        get() = CATEGORY_ORDER.filter { !isCategoryCompleted(it) } +
            CATEGORY_ORDER.filter { isCategoryCompleted(it) }

    val preview: List<Item>
        get() {
            val remaining = items.withIndex().filter { !it.value.completed }
            fun easier(lhs: IndexedValue<Item>, rhs: IndexedValue<Item>): Boolean {
                if ((lhs.value.category == Category.Feasts) != (rhs.value.category == Category.Feasts)) {
                    return lhs.value.category != Category.Feasts
                }
                val left = maxOf(0, lhs.value.target - lhs.value.count)
                val right = maxOf(0, rhs.value.target - rhs.value.count)
                if (left != right) return left < right
                val leftCategory = CATEGORY_ORDER.indexOf(lhs.value.category)
                val rightCategory = CATEGORY_ORDER.indexOf(rhs.value.category)
                if (leftCategory != rightCategory) return leftCategory < rightCategory
                return lhs.index < rhs.index
            }
            val stages = listOf(0.0 to 1.0 / 3, 1.0 / 3 to 2.0 / 3, 2.0 / 3 to 1.0)
            val staged = stages.mapNotNull { (start, end) ->
                remaining
                    .filter { it.value.count > 0 && it.value.progress >= start && it.value.progress < end }
                    .sortedWith { a, b -> if (easier(a, b)) -1 else 1 }
                    .firstOrNull()
                    ?.value
            }
            if (staged.size == 3) return staged
            return remaining.sortedWith { a, b -> if (easier(a, b)) -1 else 1 }.take(3).map { it.value }
        }

    companion object {
        val CATEGORY_ORDER = listOf(
            Category.Rosaries,
            Category.Offerings,
            Category.Mysteries,
            Category.Days,
            Category.Feasts,
        )

        fun from(
            rosaryDatesEpochMs: List<Long>,
            prayerDatesEpochMs: List<Long>,
            mysteryDatesEpochMs: Map<String, Long>,
            offeringDatesEpochMs: Map<String, Long> = emptyMap(),
            awards: Map<String, JourneyAward> = emptyMap(),
            zone: ZoneId = ZoneId.of("Australia/Perth"),
        ): JourneyMilestones {
            val result = mutableListOf<Item>()

            fun append(
                category: Category,
                dates: List<Long>,
                targets: List<Int>,
                unit: String,
                symbol: String,
                description: String,
            ) {
                val ordered = dates.sorted()
                for (target in targets) {
                    val title = if (target == 1) {
                        "First $unit"
                    } else if (unit == "Rosary") {
                        "$target Rosaries"
                    } else {
                        "$target decades"
                    }
                    result += Item(
                        id = "${category.id}-$target",
                        category = category,
                        title = title,
                        description = description,
                        symbol = symbol,
                        count = ordered.size,
                        target = target,
                        earnedAtEpochMs = if (ordered.size >= target) ordered[target - 1] else null,
                    )
                }
            }

            append(
                category = Category.Rosaries,
                dates = rosaryDatesEpochMs,
                targets = listOf(1, 10, 50, 100),
                unit = "Rosary",
                symbol = "circle.dotted",
                description = "Completed Rosaries recorded in your journey.",
            )

            val days = prayerDatesEpochMs
                .map { Instant.ofEpochMilli(it).atZone(zone).toLocalDate() }
                .toSet()
                .sorted()
            for (target in listOf(7, 30, 54)) {
                result += Item(
                    id = "days-$target",
                    category = Category.Days,
                    title = "$target days in prayer",
                    description = "Days with a Rosary or a separate decade. They do not need to be consecutive.",
                    symbol = "calendar",
                    count = days.size,
                    target = target,
                    earnedAtEpochMs = if (days.size >= target) {
                        days[target - 1].atStartOfDay(zone).toInstant().toEpochMilli()
                    } else null,
                )
            }

            val years = prayerDatesEpochMs
                .map { LiturgicalCalendar.yearOf(Instant.ofEpochMilli(it).atZone(zone).toLocalDate()) }
                .toSet()
            val marianDayNames = mutableMapOf<LocalDate, String>()
            val rosaryFeastDays = mutableSetOf<LocalDate>()
            for (year in years) {
                for (feast in FeastCatalog.dated(year).filter { it.feast.isMarian }) {
                    marianDayNames[feast.date] = feast.feast.name.english
                    if (feast.feast.id == "rosary") rosaryFeastDays += feast.date
                }
            }
            val firstPrayerByFeastDay = mutableMapOf<LocalDate, Long>()
            for (epoch in prayerDatesEpochMs) {
                val day = Instant.ofEpochMilli(epoch).atZone(zone).toLocalDate()
                if (day !in marianDayNames) continue
                val existing = firstPrayerByFeastDay[day]
                firstPrayerByFeastDay[day] = if (existing == null) epoch else minOf(existing, epoch)
            }
            val feastPrayers = firstPrayerByFeastDay.values.sorted()
            val firstFeastPrayer = feastPrayers.firstOrNull()
            val firstFeastName = firstFeastPrayer?.let {
                marianDayNames[Instant.ofEpochMilli(it).atZone(zone).toLocalDate()]
            }
            result += Item(
                id = "marian-feasts-1",
                category = Category.Feasts,
                title = "Prayer on a Marian feast",
                description = firstFeastName?.let { "Reached on $it." }
                    ?: "Pray a Rosary or a decade on a Marian feast day.",
                symbol = "leaf",
                count = feastPrayers.size,
                target = 1,
                earnedAtEpochMs = firstFeastPrayer,
            )
            val feastRosary = rosaryDatesEpochMs
                .filter { Instant.ofEpochMilli(it).atZone(zone).toLocalDate() in rosaryFeastDays }
                .minOrNull()
            result += Item(
                id = "our-lady-of-the-rosary",
                category = Category.Feasts,
                title = "Our Lady of the Rosary",
                description = "Complete a Rosary on the feast of Our Lady of the Rosary.",
                symbol = "leaf",
                count = if (feastRosary == null) 0 else 1,
                target = 1,
                earnedAtEpochMs = feastRosary,
            )
            val sets = listOf("joyful", "luminous", "sorrowful", "glorious").mapNotNull { mysteryDatesEpochMs[it] }
            result += Item(
                id = "all-mysteries",
                category = Category.Mysteries,
                title = "All four mystery sets",
                description = "Complete a Rosary with each of the Joyful, Luminous, Sorrowful and Glorious Mysteries.",
                symbol = "sparkles",
                count = sets.size,
                target = 4,
                earnedAtEpochMs = if (sets.size == 4) sets.maxOrNull() else null,
            )
            val offerings = listOf(
                Triple("someone", "rosary-for-another", "A Rosary for someone else") to
                    ("Complete a Rosary offered for a Someone else intention." to "person.2"),
                Triple("world", "rosary-for-church", "A Rosary for the Church") to
                    ("Complete a Rosary offered for a Church & world intention." to "building"),
                Triple("papal", "rosary-for-pope", "A Rosary for the Pope’s intention") to
                    ("Complete a Rosary offered for the Holy Father’s monthly intention." to "cross"),
            )
            for ((ids, copy) in offerings) {
                val (category, id, title) = ids
                val (detail, symbol) = copy
                val date = offeringDatesEpochMs[category]
                result += Item(
                    id = id,
                    category = Category.Offerings,
                    title = title,
                    description = detail,
                    symbol = symbol,
                    count = if (date == null) 0 else 1,
                    target = 1,
                    earnedAtEpochMs = date,
                )
            }

            val items = result.map { item ->
                val savedAward = awards[item.id] ?: if (item.id == "days-54") awards["days-100"] else null
                if (savedAward != null && (item.earnedAtEpochMs == null || savedAward.dateEpochMs <= item.earnedAtEpochMs)) {
                    item.copy(
                        description = savedAward.detail,
                        count = maxOf(item.count, item.target),
                        earnedAtEpochMs = savedAward.dateEpochMs,
                    )
                } else item
            }
            return JourneyMilestones(items)
        }
    }
}
