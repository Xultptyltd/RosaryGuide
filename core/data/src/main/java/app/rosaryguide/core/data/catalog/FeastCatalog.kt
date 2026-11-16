package app.rosaryguide.core.data.catalog

import app.rosaryguide.core.data.calendar.LiturgicalCalendar
import app.rosaryguide.core.data.search.localizedStandardContains
import app.rosaryguide.core.model.BilingualText
import app.rosaryguide.core.model.DatedFeast
import app.rosaryguide.core.model.Feast
import app.rosaryguide.core.model.FeastCelebration
import app.rosaryguide.core.model.FeastRank
import app.rosaryguide.core.model.MysterySetKind
import java.time.LocalDate

/**
 * Liturgical feast catalog, ported as-is from iOS `FeastCatalog`.
 * Copy, ranks, date rules, celebrations, taglines and search aliases are unchanged.
 */
object FeastCatalog {
    val celebrations: Map<String, FeastCelebration> = mapOf(
        "annunciation" to FeastCelebration(today = "Today the angel Gabriel announces to Mary that she will bear the Son of God.", occasion = "on the Annunciation"),
        "assumption" to FeastCelebration(today = "Today we celebrate Mary taken up body and soul into the glory of heaven.", occasion = "on the Assumption"),
        "immaculate-conception" to FeastCelebration(today = "Today we celebrate Mary, conceived without original sin.", occasion = "on the Immaculate Conception"),
        "christmas" to FeastCelebration(today = "Today we celebrate the birth of our Lord.", occasion = "at Christmas"),
        "ash-wednesday" to FeastCelebration(today = "Today we begin Lent with prayer, fasting and repentance.", occasion = "on Ash Wednesday"),
        "holy-thursday" to FeastCelebration(today = "Today we remember the Last Supper and the gift of the Eucharist.", occasion = "on Holy Thursday"),
        "good-friday" to FeastCelebration(today = "Today we remember the Passion and death of our Lord on the Cross.", occasion = "on Good Friday"),
        "easter" to FeastCelebration(today = "Today we celebrate the Resurrection of our Lord.", occasion = "at Easter"),
        "pentecost" to FeastCelebration(today = "Today the Holy Spirit comes down upon Mary and the apostles.", occasion = "at Pentecost"),
        "corpus-christi" to FeastCelebration(today = "Today we adore the Lord truly present in the Eucharist.", occasion = "on Corpus Christi"),
        "baptism-movable" to FeastCelebration(today = "Today we celebrate the Lord's baptism in the Jordan.", occasion = "on the Baptism of the Lord")
    )

    /** One-line, calm subtitles for feast list rows. Sentence case, no full stop. */
    val taglines: Map<String, String> = mapOf(
        "mary-mother-of-god" to "Honoring Mary as Mother of God",
        "epiphany" to "Christ revealed to the nations",
        "presentation" to "Jesus presented in the Temple",
        "lourdes" to "Mary appears to Saint Bernadette",
        "joseph" to "Guardian of the Redeemer",
        "annunciation" to "The Word becomes flesh",
        "fatima" to "Mary calls the world to prayer",
        "visitation" to "Mary visits her cousin Elizabeth",
        "peter-paul" to "Pillars of the early Church",
        "carmel" to "Mary, mother of Carmel",
        "assumption" to "Mary taken up into heaven",
        "queenship" to "Mary crowned Queen of Heaven",
        "nativity-mary" to "The birth of Our Lady",
        "holy-name-mary" to "Honoring the name of Mary",
        "sorrows" to "Mary stands beside the cross",
        "michael" to "The archangels who serve God",
        "guardian-angels" to "The angels who watch over us",
        "rosary" to "Giving thanks for the Rosary",
        "all-saints" to "Celebrating all the saints in heaven",
        "all-souls" to "Remembering the faithful departed",
        "presentation-mary" to "A life offered to God",
        "immaculate-conception" to "Mary, conceived without sin",
        "guadalupe" to "Mother of the Americas",
        "christmas" to "The birth of Jesus",
        "ash-wednesday" to "The season of Lent begins",
        "palm-sunday" to "Jesus enters Jerusalem",
        "holy-thursday" to "The Lord's Supper",
        "good-friday" to "Christ dies on the cross",
        "holy-saturday" to "Waiting in silence at the tomb",
        "easter" to "Christ is risen",
        "divine-mercy" to "Trusting in God's mercy",
        "ascension" to "Jesus ascends into heaven",
        "pentecost" to "The Holy Spirit comes down",
        "mother-of-the-church" to "Mary, Mother of the Church",
        "trinity" to "One God in three Persons",
        "corpus-christi" to "The Body and Blood of Christ",
        "sacred-heart" to "The loving heart of Jesus",
        "immaculate-heart" to "The pure heart of Mary",
        "christ-the-king" to "Christ, King of all creation",
        "advent-1" to "Preparing for Christ's coming",
        "baptism-movable" to "Jesus is baptized in the Jordan",
        "john-baptist" to "The birth of the Lord's forerunner",
        "joachim-anne" to "The parents of Mary",
        "transfiguration" to "Christ's glory revealed on the mountain",
        "holy-cross" to "The Cross, sign of salvation",
        "loreto" to "The holy house of Nazareth",
        "holy-family" to "Jesus, Mary and Joseph at home"
    )

    val searchAliases: Map<String, List<String>> = mapOf(
        "presentation" to listOf("Candlemas"),
        "mary-mother-of-god" to listOf("Theotokos"),
        "holy-thursday" to listOf("Holy Thursday"),
        "good-friday" to listOf("Good Friday"),
        "corpus-christi" to listOf("Corpus Christi"),
        "divine-mercy" to listOf("Divine Mercy Sunday"),
        "christ-the-king" to listOf("Christ the King"),
        "all-souls" to listOf("All Souls Day")
    )

    private fun feast(
        id: String,
        name: BilingualText,
        summary: String,
        suggestedMysterySet: MysterySetKind?,
        isMarian: Boolean,
        rank: FeastRank,
        dateOn: (Int) -> LocalDate?,
    ): Feast = Feast(
        id = id,
        name = name,
        summary = summary,
        suggestedMysterySet = suggestedMysterySet,
        isMarian = isMarian,
        rank = rank,
        dateOn = dateOn,
        tagline = taglines[id] ?: "",
        celebration = celebrations[id],
    )

    val all: List<Feast> = listOf(
        feast(
            id = "mary-mother-of-god",
            name = BilingualText("Mary, Mother of God", "Sancta María, Dei Génitrix"),
            summary = "The octave of Christmas honors Mary as Theotokos, Mother of God.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.date(year, 1, 1) },
        ),
        feast(
            id = "epiphany",
            name = BilingualText("Epiphany of the Lord", "Epiphanía Dómini"),
            summary = "Christ is revealed to the nations. In the United States this solemnity is observed on the Sunday after January 1.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.epiphany(year) },
        ),
        feast(
            id = "presentation",
            name = BilingualText("Presentation of the Lord", "Præsentátio Dómini"),
            summary = "Candlemas: Jesus is presented in the Temple; Simeon and Anna confess the Light.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.Feast,
            dateOn = { year -> LiturgicalCalendar.date(year, 2, 2) },
        ),
        feast(
            id = "lourdes",
            name = BilingualText("Our Lady of Lourdes", "Beáta María Virgo de Lúrdibus"),
            summary = "The Immaculate Virgin appears to St. Bernadette. World Day of the Sick.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.OptionalMemorial,
            dateOn = { year -> LiturgicalCalendar.date(year, 2, 11) },
        ),
        feast(
            id = "joseph",
            name = BilingualText("Saint Joseph, Spouse of the Blessed Virgin Mary", "Sanctus Ioseph"),
            summary = "Guardian of the Redeemer and chaste spouse of Mary. On a Sunday of Lent the solemnity is kept the next day; in Holy Week it is kept on the Saturday before Palm Sunday.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.saintJoseph(year) },
        ),
        feast(
            id = "annunciation",
            name = BilingualText("The Annunciation of the Lord", "Annuntiátio Dómini"),
            summary = "The Word becomes flesh in the womb of the Virgin. On a Sunday of Lent it is kept the next day. In Holy Week or the Octave of Easter it moves to the Monday after Divine Mercy Sunday.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.annunciation(year) },
        ),
        feast(
            id = "fatima",
            name = BilingualText("Our Lady of Fatima", "Beáta María Virgo de Fátima"),
            summary = "Mary asks for daily Rosary and conversion of heart.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.OptionalMemorial,
            dateOn = { year -> LiturgicalCalendar.date(year, 5, 13) },
        ),
        feast(
            id = "visitation",
            name = BilingualText("The Visitation of the Blessed Virgin Mary", "Visitátio Beátæ Maríæ Vírginis"),
            summary = "Mary carries Christ to Elizabeth; the infant leaps, and the Magnificat is sung.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.Feast,
            dateOn = { year -> LiturgicalCalendar.date(year, 5, 31) },
        ),
        feast(
            id = "john-baptist",
            name = BilingualText("The Nativity of Saint John the Baptist", "Natívitas Sancti Ioánnis Baptístæ"),
            summary = "The forerunner of the Lord is born to Elizabeth and Zechariah. If the Sacred Heart falls on June 24, this solemnity is kept on June 23.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year ->
                val jun24 = LiturgicalCalendar.date(year, 6, 24)
                val sacredHeart = LiturgicalCalendar.sacredHeart(year)
                if (sacredHeart == jun24) jun24.minusDays(1) else jun24
            },
        ),
        feast(
            id = "peter-paul",
            name = BilingualText("Saints Peter and Paul", "Sancti Petrus et Paulus"),
            summary = "The apostles on whom the Church is built.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.date(year, 6, 29) },
        ),
        feast(
            id = "carmel",
            name = BilingualText("Our Lady of Mount Carmel", "Beáta María Virgo de Monte Carmélo"),
            summary = "Mary of Carmel, associated with the Brown Scapular.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = true,
            rank = FeastRank.OptionalMemorial,
            dateOn = { year -> LiturgicalCalendar.date(year, 7, 16) },
        ),
        feast(
            id = "joachim-anne",
            name = BilingualText("Saints Joachim and Anne, Parents of the Blessed Virgin Mary", "Sancti Ióachim et Anna, paréntes Beátæ Maríæ Vírginis"),
            summary = "The parents of Mary and grandparents of Jesus.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = false,
            rank = FeastRank.Memorial,
            dateOn = { year -> LiturgicalCalendar.date(year, 7, 26) },
        ),
        feast(
            id = "transfiguration",
            name = BilingualText("The Transfiguration of the Lord", "In Transfiguratióne Dómini"),
            summary = "Christ is transfigured before Peter, James and John. The fourth Luminous Mystery.",
            suggestedMysterySet = MysterySetKind.Luminous,
            isMarian = false,
            rank = FeastRank.Feast,
            dateOn = { year -> LiturgicalCalendar.date(year, 8, 6) },
        ),
        feast(
            id = "assumption",
            name = BilingualText("The Assumption of the Blessed Virgin Mary", "Assúmptio Beátæ Maríæ Vírginis"),
            summary = "Mary is taken body and soul into heavenly glory.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = true,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.date(year, 8, 15) },
        ),
        feast(
            id = "queenship",
            name = BilingualText("The Queenship of the Blessed Virgin Mary", "Beáta María Virgo Regína"),
            summary = "The octave of the Assumption: Mary is Queen beside her Son.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = true,
            rank = FeastRank.Memorial,
            dateOn = { year -> LiturgicalCalendar.date(year, 8, 22) },
        ),
        feast(
            id = "nativity-mary",
            name = BilingualText("The Nativity of the Blessed Virgin Mary", "Natívitas Beátæ Maríæ Vírginis"),
            summary = "The birthday of the Mother of God.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.Feast,
            dateOn = { year -> LiturgicalCalendar.date(year, 9, 8) },
        ),
        feast(
            id = "holy-name-mary",
            name = BilingualText("The Most Holy Name of Mary", "Sanctíssimum Nomen Maríæ"),
            summary = "The name of Mary is our sweetness and defense.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.OptionalMemorial,
            dateOn = { year -> LiturgicalCalendar.date(year, 9, 12) },
        ),
        feast(
            id = "holy-cross",
            name = BilingualText("The Exaltation of the Holy Cross", "In Exaltatióne Sanctæ Crucis"),
            summary = "The Cross, instrument of death, is honored as the sign of victory and salvation.",
            suggestedMysterySet = MysterySetKind.Sorrowful,
            isMarian = false,
            rank = FeastRank.Feast,
            dateOn = { year -> LiturgicalCalendar.date(year, 9, 14) },
        ),
        feast(
            id = "sorrows",
            name = BilingualText("Our Lady of Sorrows", "Beáta María Virgo Perdolens"),
            summary = "Mary stands at the Cross. The seven sorrows keep company with the Sorrowful Mysteries.",
            suggestedMysterySet = MysterySetKind.Sorrowful,
            isMarian = true,
            rank = FeastRank.Memorial,
            dateOn = { year -> LiturgicalCalendar.date(year, 9, 15) },
        ),
        feast(
            id = "michael",
            name = BilingualText("Saints Michael, Gabriel, and Raphael, Archangels", "Sancti Míchael, Gábriel et Ráphael"),
            summary = "The holy angels who serve the throne of God. Saint Michael is invoked as defender in battle.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = false,
            rank = FeastRank.Feast,
            dateOn = { year -> LiturgicalCalendar.date(year, 9, 29) },
        ),
        feast(
            id = "guardian-angels",
            name = BilingualText("The Holy Guardian Angels", "Sancti Ángeli Custódes"),
            summary = "Each soul is entrusted to an angel’s care.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = false,
            rank = FeastRank.Memorial,
            dateOn = { year -> LiturgicalCalendar.date(year, 10, 2) },
        ),
        feast(
            id = "rosary",
            name = BilingualText("Our Lady of the Rosary", "Beáta María Virgo a Sacratíssimo Rosário"),
            summary = "Instituted after Lepanto. The memorial invites the whole Church to the daily Rosary.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = true,
            rank = FeastRank.Memorial,
            dateOn = { year -> LiturgicalCalendar.date(year, 10, 7) },
        ),
        feast(
            id = "all-saints",
            name = BilingualText("All Saints", "Omnium Sanctórum"),
            summary = "The Church in glory, with Mary Queen of All Saints.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.date(year, 11, 1) },
        ),
        feast(
            id = "all-souls",
            name = BilingualText("The Commemoration of All the Faithful Departed", "Commemorátio ómnium fidélium defunctórum"),
            summary = "Pray the Rosary for the holy souls, especially with the Fatima prayer.",
            suggestedMysterySet = MysterySetKind.Sorrowful,
            isMarian = false,
            rank = FeastRank.Seasonal,
            dateOn = { year -> LiturgicalCalendar.date(year, 11, 2) },
        ),
        feast(
            id = "presentation-mary",
            name = BilingualText("The Presentation of the Blessed Virgin Mary", "Præsentátio Beátæ Maríæ Vírginis"),
            summary = "Mary is offered in the Temple; a feast of consecration.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.Memorial,
            dateOn = { year -> LiturgicalCalendar.date(year, 11, 21) },
        ),
        feast(
            id = "immaculate-conception",
            name = BilingualText("The Immaculate Conception of the Blessed Virgin Mary", "Immaculáta Conceptio Beátæ Maríæ Vírginis"),
            summary = "Mary is preserved from original sin from the first instant of her conception. Patronal solemnity of the United States. When 8 December is a Sunday, it is kept the next day.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.immaculateConception(year) },
        ),
        feast(
            id = "loreto",
            name = BilingualText("Our Lady of Loreto", "Beáta María Virgo de Laureto"),
            summary = "The Holy House of Loreto recalls the home of Nazareth, where the Word was made flesh.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.OptionalMemorial,
            dateOn = { year -> LiturgicalCalendar.date(year, 12, 10) },
        ),
        feast(
            id = "guadalupe",
            name = BilingualText("Our Lady of Guadalupe", "Sancta María de Guadalupe"),
            summary = "Mary appears to St. Juan Diego. Patroness of the Americas.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.Feast,
            dateOn = { year -> LiturgicalCalendar.date(year, 12, 12) },
        ),
        feast(
            id = "christmas",
            name = BilingualText("The Nativity of the Lord", "Natívitas Dómini"),
            summary = "The Word is made flesh and dwells among us. The Joyful Mysteries are especially fitting.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.date(year, 12, 25) },
        ),
        feast(
            id = "holy-family",
            name = BilingualText("The Holy Family of Jesus, Mary and Joseph", "Sancta Família Iesu, Maríæ et Ioseph"),
            summary = "The Sunday within the Octave of Christmas, or December 30 when Christmas falls on a Sunday.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.Feast,
            dateOn = { year -> LiturgicalCalendar.holyFamily(year) },
        ),
        feast(
            id = "ash-wednesday",
            name = BilingualText("Ash Wednesday", "Feria IV Cínerum"),
            summary = "Lent begins. The Sorrowful Mysteries accompany this season of conversion.",
            suggestedMysterySet = MysterySetKind.Sorrowful,
            isMarian = false,
            rank = FeastRank.Seasonal,
            dateOn = { year -> LiturgicalCalendar.addingDays(-46, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "palm-sunday",
            name = BilingualText("Palm Sunday of the Passion of the Lord", "Dóminica in Palmis"),
            summary = "Holy Week begins. The Sorrowful Mysteries trace the road from the garden to the Cross.",
            suggestedMysterySet = MysterySetKind.Sorrowful,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.addingDays(-7, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "holy-thursday",
            name = BilingualText("Thursday of the Lord’s Supper", "Feria V in Cena Dómini"),
            summary = "The Triduum opens with the Eucharist and the washing of feet. The fifth Luminous Mystery is especially fitting.",
            suggestedMysterySet = MysterySetKind.Luminous,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.addingDays(-3, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "good-friday",
            name = BilingualText("Friday of the Passion of the Lord", "Feria VI in Passióne Dómini"),
            summary = "Christ is crucified. Pray the Sorrowful Mysteries slowly.",
            suggestedMysterySet = MysterySetKind.Sorrowful,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.addingDays(-2, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "holy-saturday",
            name = BilingualText("Holy Saturday", "Sábbatum Sanctum"),
            summary = "The Church keeps silence at the tomb. The Sorrowful Mysteries still belong to this day; the Vigil already tastes Easter.",
            suggestedMysterySet = MysterySetKind.Sorrowful,
            isMarian = false,
            rank = FeastRank.Seasonal,
            dateOn = { year -> LiturgicalCalendar.addingDays(-1, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "easter",
            name = BilingualText("Easter Sunday of the Resurrection of the Lord", "Dóminica Resurrectiónis"),
            summary = "Christ is risen. The Glorious Mysteries are the prayer of this day and of the whole Easter season.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.easter(year) },
        ),
        feast(
            id = "divine-mercy",
            name = BilingualText("Second Sunday of Easter (Divine Mercy)", "Dóminica in Albis"),
            summary = "The octave of Easter. From the wounds of the Risen Lord flow mercy.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.addingDays(7, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "ascension",
            name = BilingualText("The Ascension of the Lord", "Ascénsio Dómini"),
            summary = "In the United States this solemnity is commonly observed on the Sunday after the traditional Thursday (forty days after Easter). The second Glorious Mystery.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.addingDays(42, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "pentecost",
            name = BilingualText("Pentecost Sunday", "Dóminica Pentecóstes"),
            summary = "The Holy Spirit is poured out. The third Glorious Mystery. Easter Time ends at this vespers.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.addingDays(49, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "mother-of-the-church",
            name = BilingualText("The Blessed Virgin Mary, Mother of the Church", "Beáta María Virgo, Ecclésiæ Mater"),
            summary = "Obligatory memorial on the Monday after Pentecost. Mary, present with the disciples at the Spirit’s coming, is honored as Mother of the Church.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = true,
            rank = FeastRank.Memorial,
            dateOn = { year -> LiturgicalCalendar.addingDays(50, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "trinity",
            name = BilingualText("The Most Holy Trinity", "Sanctíssima Trínitas"),
            summary = "The Sunday after Pentecost.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.addingDays(56, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "corpus-christi",
            name = BilingualText("The Most Holy Body and Blood of Christ", "Sanctíssimum Corpus et Sanguis Christi"),
            summary = "In the United States this solemnity is commonly observed on the Sunday after Trinity Sunday. The fifth Luminous Mystery.",
            suggestedMysterySet = MysterySetKind.Luminous,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.addingDays(63, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "sacred-heart",
            name = BilingualText("The Most Sacred Heart of Jesus", "Sacratíssimum Cor Iesu"),
            summary = "Friday after the second Sunday after Pentecost.",
            suggestedMysterySet = MysterySetKind.Sorrowful,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.sacredHeart(year) },
        ),
        feast(
            id = "immaculate-heart",
            name = BilingualText("The Immaculate Heart of the Blessed Virgin Mary", "Cor Immaculátum Beátæ Maríæ Vírginis"),
            summary = "Saturday after the Sacred Heart.",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = true,
            rank = FeastRank.Memorial,
            dateOn = { year -> LiturgicalCalendar.addingDays(69, LiturgicalCalendar.easter(year)) },
        ),
        feast(
            id = "christ-the-king",
            name = BilingualText("Our Lord Jesus Christ, King of the Universe", "Dóminus Noster Iesus Christus Univérsorum Rex"),
            summary = "The last Sunday of Ordinary Time, immediately before Advent.",
            suggestedMysterySet = MysterySetKind.Glorious,
            isMarian = false,
            rank = FeastRank.Solemnity,
            dateOn = { year -> LiturgicalCalendar.addingDays(-7, LiturgicalCalendar.firstSundayOfAdvent(year)) },
        ),
        feast(
            id = "advent-1",
            name = BilingualText("First Sunday of Advent", "Dóminica I Advéntus"),
            summary = "The liturgical year begins",
            suggestedMysterySet = MysterySetKind.Joyful,
            isMarian = false,
            rank = FeastRank.Seasonal,
            dateOn = { year -> LiturgicalCalendar.firstSundayOfAdvent(year) },
        ),
        feast(
            id = "baptism-movable",
            name = BilingualText("The Baptism of the Lord", "Baptísma Dómini"),
            summary = "Christmas Time ends. The first Luminous Mystery.",
            suggestedMysterySet = MysterySetKind.Luminous,
            isMarian = false,
            rank = FeastRank.Feast,
            dateOn = { year -> LiturgicalCalendar.baptismOfTheLord(year) },
        )
    )

    fun feasts(date: LocalDate): List<DatedFeast> {
        val year = LiturgicalCalendar.yearOf(date)
        return dated(year).filter { it.date == date }
    }

    fun upcoming(date: LocalDate, limit: Int = 12): List<DatedFeast> {
        val year = LiturgicalCalendar.yearOf(date)
        val combined = dated(year) + dated(year + 1)
        return combined
            .filter { it.date >= date }
            .sortedBy { it.date }
            .take(limit)
    }

    fun dated(year: Int): List<DatedFeast> {
        return all.mapNotNull { feast ->
            feast.dateOn(year)?.let { DatedFeast(feast, it) }
        }.sortedWith(compareBy<DatedFeast> { it.date }.thenByDescending { it.feast.rank.precedence })
    }

    fun matchesSearch(feast: Feast, query: String): Boolean {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return false
        val fields = listOf(feast.name.english, feast.name.latin, feast.shortTitle) + (searchAliases[feast.id] ?: emptyList())
        return fields.any { it.localizedStandardContains(trimmed) }
    }

    /**
     * Feasts whose name, Latin title, short title, or known alias matches [query],
     * each paired with its next celebration on or after [date].
     */
    fun searchResults(query: String, date: LocalDate): List<DatedFeast> {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return emptyList()
        val year = LiturgicalCalendar.yearOf(date)
        val upcoming = (year..(year + 1)).flatMap { dated(it) }.filter { it.date >= date }
        val seen = mutableSetOf<String>()
        return upcoming.filter { item ->
            seen.add(item.feast.id) && matchesSearch(item.feast, trimmed)
        }
    }
}

val Feast.resolvedTagline: String
    get() = tagline.ifEmpty { FeastCatalog.taglines[id] ?: "" }
