import Foundation

enum FeastCatalog {
    static let all: [Feast] = fixed + movable

    static func feasts(on date: Date, calendar: Calendar = .current) -> [DatedFeast] {
        let year = calendar.component(.year, from: date)
        return dated(in: year, calendar: calendar).filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    static func upcoming(from date: Date = .now, limit: Int = 12, calendar: Calendar = .current) -> [DatedFeast] {
        let year = calendar.component(.year, from: date)
        let nextYear = year + 1
        let combined = dated(in: year, calendar: calendar) + dated(in: nextYear, calendar: calendar)
        return combined
            .filter { $0.date >= calendar.startOfDay(for: date) }
            .sorted { $0.date < $1.date }
            .prefix(limit)
            .map { $0 }
    }

    static func dated(in year: Int, calendar: Calendar = .current) -> [DatedFeast] {
        all.compactMap { feast in
            guard let date = feast.dateProvider(year) else { return nil }
            return DatedFeast(feast: feast, date: calendar.startOfDay(for: date))
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Fixed

    private static let fixed: [Feast] = [
        fixedFeast("mary-mother-of-god", "Mary, Mother of God", "Sancta María, Dei Génitrix", 1, 1, .solemnity, marian: true, set: .joyful,
                   "The octave of Christmas honors Mary as Theotokos, Mother of God."),
        Feast(
            id: "epiphany",
            name: BilingualText(english: "Epiphany of the Lord", latin: "Epiphanía Dómini"),
            summary: "Christ is revealed to the nations. In the United States this solemnity is observed on the Sunday after January 1.",
            suggestedMysterySet: .joyful,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in LiturgicalCalendar.epiphany(year: year) }
        ),
        fixedFeast("presentation", "Presentation of the Lord", "Præsentátio Dómini", 2, 2, .feast, marian: true, set: .joyful,
                   "Candlemas: Jesus is presented in the Temple; Simeon and Anna confess the Light."),
        fixedFeast("lourdes", "Our Lady of Lourdes", "Beáta María Virgo de Lúrdibus", 2, 11, .optionalMemorial, marian: true, set: .joyful,
                   "The Immaculate Virgin appears to St. Bernadette. World Day of the Sick."),
        fixedFeast("joseph", "Saint Joseph, Spouse of the Blessed Virgin Mary", "Sanctus Ioseph", 3, 19, .solemnity, set: .joyful,
                   "Guardian of the Redeemer and chaste spouse of Mary."),
        Feast(
            id: "annunciation",
            name: BilingualText(english: "The Annunciation of the Lord", latin: "Annuntiátio Dómini"),
            summary: "The Word becomes flesh in the womb of the Virgin. If March 25 falls in Holy Week or the Octave of Easter, the Annunciation is transferred to the Monday after Divine Mercy Sunday.",
            suggestedMysterySet: .joyful,
            isMarian: true,
            rank: .solemnity,
            dateProvider: { year in
                guard let mar25 = LiturgicalCalendar.date(year: year, month: 3, day: 25) else { return nil }
                if LiturgicalCalendar.isInHolyWeekOrEasterOctave(mar25, year: year) {
                    return LiturgicalCalendar.mondayAfterDivineMercy(year: year)
                }
                return mar25
            }
        ),
        fixedFeast("fatima", "Our Lady of Fatima", "Beáta María Virgo de Fátima", 5, 13, .optionalMemorial, marian: true, set: .joyful,
                   "Mary asks for daily Rosary and conversion of heart."),
        fixedFeast("visitation", "The Visitation of the Blessed Virgin Mary", "Visitátio Beátæ Maríæ Vírginis", 5, 31, .feast, marian: true, set: .joyful,
                   "Mary carries Christ to Elizabeth; the infant leaps, and the Magnificat is sung."),
        fixedFeast("peter-paul", "Saints Peter and Paul", "Sancti Petrus et Paulus", 6, 29, .solemnity, set: .glorious,
                   "The apostles on whom the Church is built."),
        fixedFeast("carmel", "Our Lady of Mount Carmel", "Beáta María Virgo de Monte Carmélo", 7, 16, .optionalMemorial, marian: true, set: .glorious,
                   "Mary of Carmel, associated with the Brown Scapular."),
        fixedFeast("assumption", "The Assumption of the Blessed Virgin Mary", "Assúmptio Beátæ Maríæ Vírginis", 8, 15, .solemnity, marian: true, set: .glorious,
                   "Mary is taken body and soul into heavenly glory."),
        fixedFeast("queenship", "The Queenship of the Blessed Virgin Mary", "Beáta María Virgo Regína", 8, 22, .memorial, marian: true, set: .glorious,
                   "The octave of the Assumption: Mary is Queen beside her Son."),
        fixedFeast("nativity-mary", "The Nativity of the Blessed Virgin Mary", "Natívitas Beátæ Maríæ Vírginis", 9, 8, .feast, marian: true, set: .joyful,
                   "The birthday of the Mother of God."),
        fixedFeast("holy-name-mary", "The Most Holy Name of Mary", "Sanctíssimum Nomen Maríæ", 9, 12, .optionalMemorial, marian: true, set: .joyful,
                   "The name of Mary is our sweetness and defense."),
        fixedFeast("sorrows", "Our Lady of Sorrows", "Beáta María Virgo Perdolens", 9, 15, .memorial, marian: true, set: .sorrowful,
                   "Mary stands at the Cross. The seven sorrows keep company with the Sorrowful Mysteries."),
        fixedFeast("michael", "Saints Michael, Gabriel, and Raphael, Archangels", "Sancti Míchael, Gábriel et Ráphael", 9, 29, .feast, set: .glorious,
                   "The holy angels who serve the throne of God. Saint Michael is invoked as defender in battle."),
        fixedFeast("guardian-angels", "The Holy Guardian Angels", "Sancti Ángeli Custódes", 10, 2, .memorial, set: .glorious,
                   "Each soul is entrusted to an angel’s care."),
        fixedFeast("rosary", "Our Lady of the Rosary", "Beáta María Virgo a Sacratíssimo Rosário", 10, 7, .memorial, marian: true, set: .glorious,
                   "Instituted after Lepanto. The memorial invites the whole Church to the daily Rosary."),
        fixedFeast("all-saints", "All Saints", "Omnium Sanctórum", 11, 1, .solemnity, set: .glorious,
                   "The Church in glory, with Mary Queen of All Saints."),
        fixedFeast("all-souls", "The Commemoration of All the Faithful Departed", "Commemorátio ómnium fidélium defunctórum", 11, 2, .seasonal, set: .sorrowful,
                   "Pray the Rosary for the holy souls, especially with the Fatima prayer."),
        fixedFeast("presentation-mary", "The Presentation of the Blessed Virgin Mary", "Præsentátio Beátæ Maríæ Vírginis", 11, 21, .memorial, marian: true, set: .joyful,
                   "Mary is offered in the Temple; a feast of consecration."),
        fixedFeast("immaculate-conception", "The Immaculate Conception of the Blessed Virgin Mary", "Immaculáta Conceptio Beátæ Maríæ Vírginis", 12, 8, .solemnity, marian: true, set: .joyful,
                   "Mary is preserved from original sin from the first instant of her conception. Patronal solemnity of the United States."),
        fixedFeast("guadalupe", "Our Lady of Guadalupe", "Sancta María de Guadalupe", 12, 12, .feast, marian: true, set: .joyful,
                   "Mary appears to St. Juan Diego. Patroness of the Americas."),
        fixedFeast("christmas", "The Nativity of the Lord", "Natívitas Dómini", 12, 25, .solemnity, marian: true, set: .joyful,
                   "The Word is made flesh and dwells among us. The Joyful Mysteries are especially fitting.")
    ]

    // MARK: - Movable (depend on Easter / Advent)

    private static let movable: [Feast] = [
        Feast(
            id: "ash-wednesday",
            name: BilingualText(english: "Ash Wednesday", latin: "Feria IV Cínerum"),
            summary: "Lent begins. The Sorrowful Mysteries accompany this season of conversion.",
            suggestedMysterySet: .sorrowful,
            isMarian: false,
            rank: .seasonal,
            dateProvider: { year in
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(-46, to: $0) }
            }
        ),
        Feast(
            id: "palm-sunday",
            name: BilingualText(english: "Palm Sunday of the Passion of the Lord", latin: "Dóminica in Palmis"),
            summary: "Holy Week begins. The Sorrowful Mysteries trace the road from the garden to the Cross.",
            suggestedMysterySet: .sorrowful,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(-7, to: $0) }
            }
        ),
        Feast(
            id: "holy-thursday",
            name: BilingualText(english: "Thursday of the Lord’s Supper", latin: "Feria V in Cena Dómini"),
            summary: "The Triduum opens with the Eucharist and the washing of feet. The fifth Luminous Mystery is especially fitting.",
            suggestedMysterySet: .luminous,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(-3, to: $0) }
            }
        ),
        Feast(
            id: "good-friday",
            name: BilingualText(english: "Friday of the Passion of the Lord", latin: "Feria VI in Passióne Dómini"),
            summary: "Christ is crucified. Pray the Sorrowful Mysteries slowly.",
            suggestedMysterySet: .sorrowful,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(-2, to: $0) }
            }
        ),
        Feast(
            id: "holy-saturday",
            name: BilingualText(english: "Holy Saturday", latin: "Sábbatum Sanctum"),
            summary: "The Church keeps silence at the tomb. The Sorrowful Mysteries still belong to this day; the Vigil already tastes Easter.",
            suggestedMysterySet: .sorrowful,
            isMarian: false,
            rank: .seasonal,
            dateProvider: { year in
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(-1, to: $0) }
            }
        ),
        Feast(
            id: "easter",
            name: BilingualText(english: "Easter Sunday of the Resurrection of the Lord", latin: "Dóminica Resurrectiónis"),
            summary: "Christ is risen. The Glorious Mysteries are the prayer of this day and of the whole Easter season.",
            suggestedMysterySet: .glorious,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in LiturgicalCalendar.easter(year: year) }
        ),
        Feast(
            id: "divine-mercy",
            name: BilingualText(english: "Second Sunday of Easter (Divine Mercy)", latin: "Dóminica in Albis"),
            summary: "The octave of Easter. From the wounds of the Risen Lord flow mercy.",
            suggestedMysterySet: .glorious,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(7, to: $0) }
            }
        ),
        Feast(
            id: "ascension",
            name: BilingualText(english: "The Ascension of the Lord", latin: "Ascénsio Dómini"),
            summary: "In the United States this solemnity is commonly observed on the Sunday after the traditional Thursday (forty days after Easter). The second Glorious Mystery.",
            suggestedMysterySet: .glorious,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in
                // US: many dioceses transfer Ascension to the following Sunday (+42).
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(42, to: $0) }
            }
        ),
        Feast(
            id: "pentecost",
            name: BilingualText(english: "Pentecost Sunday", latin: "Dóminica Pentecóstes"),
            summary: "The Holy Spirit is poured out. The third Glorious Mystery. Easter Time ends at this vespers.",
            suggestedMysterySet: .glorious,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(49, to: $0) }
            }
        ),
        Feast(
            id: "mother-of-the-church",
            name: BilingualText(english: "The Blessed Virgin Mary, Mother of the Church", latin: "Beáta María Virgo, Ecclésiæ Mater"),
            summary: "Obligatory memorial on the Monday after Pentecost. Mary, present with the disciples at the Spirit’s coming, is honored as Mother of the Church.",
            suggestedMysterySet: .glorious,
            isMarian: true,
            rank: .memorial,
            dateProvider: { year in
                // Monday after Pentecost = Easter + 50 (Pentecost is Easter + 49).
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(50, to: $0) }
            }
        ),
        Feast(
            id: "trinity",
            name: BilingualText(english: "The Most Holy Trinity", latin: "Sanctíssima Trínitas"),
            summary: "The Sunday after Pentecost.",
            suggestedMysterySet: .glorious,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(56, to: $0) }
            }
        ),
        Feast(
            id: "corpus-christi",
            name: BilingualText(english: "The Most Holy Body and Blood of Christ", latin: "Sanctíssimum Corpus et Sanguis Christi"),
            summary: "In the United States this solemnity is commonly observed on the Sunday after Trinity Sunday. The fifth Luminous Mystery.",
            suggestedMysterySet: .luminous,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in
                // US: typically the Sunday after Trinity (+63 from Easter) rather than Thursday (+60).
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(63, to: $0) }
            }
        ),
        Feast(
            id: "sacred-heart",
            name: BilingualText(english: "The Most Sacred Heart of Jesus", latin: "Sacratíssimum Cor Iesu"),
            summary: "Friday after the second Sunday after Pentecost.",
            suggestedMysterySet: .sorrowful,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(68, to: $0) }
            }
        ),
        Feast(
            id: "immaculate-heart",
            name: BilingualText(english: "The Immaculate Heart of the Blessed Virgin Mary", latin: "Cor Immaculátum Beátæ Maríæ Vírginis"),
            summary: "Saturday after the Sacred Heart.",
            suggestedMysterySet: .joyful,
            isMarian: true,
            rank: .memorial,
            dateProvider: { year in
                LiturgicalCalendar.easter(year: year).flatMap { LiturgicalCalendar.addingDays(69, to: $0) }
            }
        ),
        Feast(
            id: "christ-the-king",
            name: BilingualText(english: "Our Lord Jesus Christ, King of the Universe", latin: "Dóminus Noster Iesus Christus Univérsorum Rex"),
            summary: "The last Sunday of Ordinary Time, immediately before Advent.",
            suggestedMysterySet: .glorious,
            isMarian: false,
            rank: .solemnity,
            dateProvider: { year in
                guard let advent = LiturgicalCalendar.firstSundayOfAdvent(year: year) else { return nil }
                return LiturgicalCalendar.addingDays(-7, to: advent)
            }
        ),
        Feast(
            id: "advent-1",
            name: BilingualText(english: "First Sunday of Advent", latin: "Dóminica I Advéntus"),
            summary: "The liturgical year begins",
            suggestedMysterySet: .joyful,
            isMarian: false,
            rank: .seasonal,
            dateProvider: { year in LiturgicalCalendar.firstSundayOfAdvent(year: year) }
        ),
        Feast(
            id: "baptism-movable",
            name: BilingualText(english: "The Baptism of the Lord", latin: "Baptísma Dómini"),
            summary: "Christmas Time ends. The first Luminous Mystery.",
            suggestedMysterySet: .luminous,
            isMarian: false,
            rank: .feast,
            dateProvider: { year in LiturgicalCalendar.baptismOfTheLord(year: year) }
        )
    ]

    private static func fixedFeast(
        _ id: String,
        _ en: String,
        _ la: String,
        _ month: Int,
        _ day: Int,
        _ rank: FeastRank,
        marian: Bool = false,
        set: MysterySetKind?,
        _ summary: String
    ) -> Feast {
        Feast(
            id: id,
            name: BilingualText(english: en, latin: la),
            summary: summary,
            suggestedMysterySet: set,
            isMarian: marian,
            rank: rank,
            dateProvider: { year in LiturgicalCalendar.date(year: year, month: month, day: day) }
        )
    }
}

/// A short line for Home on a feast: what today celebrates, then "Many pray the X Mysteries <occasion>"
struct FeastCelebration: Equatable, Sendable {
    /// First sentence, e.g. "Today we celebrate the birth of our Lord."
    var today: String
    /// Ends the second sentence, e.g. "at Christmas".
    var occasion: String
}

extension Feast {
    var celebration: FeastCelebration? { FeastCatalog.celebrations[id] }
}

extension FeastCatalog {
    static let celebrations: [String: FeastCelebration] = [
        "mary-mother-of-god": FeastCelebration(today: "Today we honor Mary as the Holy Mother of God.", occasion: "on the solemnity of Mary, Mother of God"),
        "epiphany": FeastCelebration(today: "Today Christ is revealed to the nations as the Magi come to adore him.", occasion: "at Epiphany"),
        "presentation": FeastCelebration(today: "Today the infant Jesus is presented in the Temple, and Simeon greets him as the light of the nations.", occasion: "on the Presentation of the Lord"),
        "lourdes": FeastCelebration(today: "Today we remember Our Lady appearing to Saint Bernadette at Lourdes in 1858.", occasion: "on the memorial of Our Lady of Lourdes"),
        "joseph": FeastCelebration(today: "Today we honor Saint Joseph, spouse of the Virgin Mary and guardian of the Redeemer.", occasion: "on the solemnity of Saint Joseph"),
        "annunciation": FeastCelebration(today: "Today the angel Gabriel announces to Mary that she will bear the Son of God.", occasion: "on the Annunciation"),
        "fatima": FeastCelebration(today: "Today we remember Our Lady appearing to three shepherd children at Fatima in 1917.", occasion: "on the memorial of Our Lady of Fatima"),
        "visitation": FeastCelebration(today: "Today Mary visits Elizabeth, and John the Baptist leaps for joy in the womb.", occasion: "on the feast of the Visitation"),
        "peter-paul": FeastCelebration(today: "Today we honor the apostles Peter and Paul, who gave their lives for Christ in Rome.", occasion: "on the solemnity of Saints Peter and Paul"),
        "carmel": FeastCelebration(today: "Today we honor Mary as Our Lady of Mount Carmel, patroness of the Carmelite family.", occasion: "on the memorial of Our Lady of Mount Carmel"),
        "assumption": FeastCelebration(today: "Today we celebrate Mary taken up body and soul into the glory of heaven.", occasion: "on the Assumption"),
        "queenship": FeastCelebration(today: "Today we honor Mary, crowned as Queen of heaven and earth.", occasion: "on the memorial of the Queenship of Mary"),
        "nativity-mary": FeastCelebration(today: "Today we celebrate the birth of the Blessed Virgin Mary.", occasion: "on the Nativity of Mary"),
        "holy-name-mary": FeastCelebration(today: "Today we honor the holy name of Mary.", occasion: "on the memorial of the Holy Name of Mary"),
        "sorrows": FeastCelebration(today: "Today we stand with Mary at the foot of the Cross and remember her sorrows.", occasion: "on the memorial of Our Lady of Sorrows"),
        "michael": FeastCelebration(today: "Today we honor the archangels Michael, Gabriel and Raphael.", occasion: "on the feast of the Archangels"),
        "guardian-angels": FeastCelebration(today: "Today we give thanks for the angels God sends to guard us.", occasion: "on the memorial of the Guardian Angels"),
        "rosary": FeastCelebration(today: "Today we honor Our Lady of the Rosary and give thanks for this prayer.", occasion: "on the memorial of Our Lady of the Rosary"),
        "all-saints": FeastCelebration(today: "Today we celebrate all the saints who now see God face to face.", occasion: "on All Saints"),
        "all-souls": FeastCelebration(today: "Today we pray for all the faithful departed.", occasion: "on All Souls Day"),
        "presentation-mary": FeastCelebration(today: "Today we remember the young Mary given wholly to God.", occasion: "on the memorial of the Presentation of Mary"),
        "immaculate-conception": FeastCelebration(today: "Today we celebrate Mary, conceived without original sin.", occasion: "on the Immaculate Conception"),
        "guadalupe": FeastCelebration(today: "Today we remember Our Lady appearing to Saint Juan Diego at Tepeyac in 1531.", occasion: "on the feast of Our Lady of Guadalupe"),
        "christmas": FeastCelebration(today: "Today we celebrate the birth of our Lord.", occasion: "at Christmas"),
        "ash-wednesday": FeastCelebration(today: "Today we begin Lent with prayer, fasting and repentance.", occasion: "on Ash Wednesday"),
        "palm-sunday": FeastCelebration(today: "Today the Lord enters Jerusalem as his Passion begins.", occasion: "on Palm Sunday"),
        "holy-thursday": FeastCelebration(today: "Today we remember the Last Supper and the gift of the Eucharist.", occasion: "on Holy Thursday"),
        "good-friday": FeastCelebration(today: "Today we remember the Passion and death of our Lord on the Cross.", occasion: "on Good Friday"),
        "holy-saturday": FeastCelebration(today: "Today the Church waits at the tomb in silent hope.", occasion: "on Holy Saturday"),
        "easter": FeastCelebration(today: "Today we celebrate the Resurrection of our Lord.", occasion: "at Easter"),
        "divine-mercy": FeastCelebration(today: "Today we give thanks for the mercy of the risen Lord.", occasion: "on Divine Mercy Sunday"),
        "ascension": FeastCelebration(today: "Today we celebrate the Lord ascending into heaven.", occasion: "on the Ascension"),
        "pentecost": FeastCelebration(today: "Today the Holy Spirit comes down upon Mary and the apostles.", occasion: "at Pentecost"),
        "mother-of-the-church": FeastCelebration(today: "Today we honor Mary as Mother of the Church.", occasion: "on the memorial of Mary, Mother of the Church"),
        "trinity": FeastCelebration(today: "Today we worship one God in three Persons, Father, Son and Holy Spirit.", occasion: "on Trinity Sunday"),
        "corpus-christi": FeastCelebration(today: "Today we adore the Lord truly present in the Eucharist.", occasion: "on Corpus Christi"),
        "sacred-heart": FeastCelebration(today: "Today we honor the Sacred Heart of Jesus, pierced for love of us.", occasion: "on the solemnity of the Sacred Heart"),
        "immaculate-heart": FeastCelebration(today: "Today we honor the Immaculate Heart of Mary, who kept all these things in her heart.", occasion: "on the memorial of the Immaculate Heart of Mary"),
        "christ-the-king": FeastCelebration(today: "Today we proclaim Christ as King of the universe.", occasion: "on Christ the King"),
        "advent-1": FeastCelebration(today: "Today the Church begins Advent, waiting in hope for the Lord's coming.", occasion: "on the First Sunday of Advent"),
        "baptism-movable": FeastCelebration(today: "Today we celebrate the Lord's baptism in the Jordan.", occasion: "on the Baptism of the Lord"),
    ]
}
