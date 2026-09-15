import Foundation

enum PrayerCatalog {
    static let signOfTheCross = Prayer(
        id: "sign-of-the-cross",
        title: BilingualText(english: "Sign of the Cross", latin: "Signum Crucis"),
        text: BilingualText(
            english: "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.",
            latin: "In nómine Patris, et Fílii, et Spíritus Sancti. Amen."
        )
    )

    static let apostlesCreed = Prayer(
        id: "apostles-creed",
        title: BilingualText(english: "Apostles’ Creed", latin: "Symbolum Apostolórum"),
        text: BilingualText(
            english: """
            I believe in God, the Father almighty, Creator of heaven and earth, and in Jesus Christ, his only Son, our Lord, who was conceived by the Holy Spirit, born of the Virgin Mary, suffered under Pontius Pilate, was crucified, died and was buried; he descended into hell; on the third day he rose again from the dead; he ascended into heaven, and is seated at the right hand of God the Father almighty; from there he will come to judge the living and the dead.

            I believe in the Holy Spirit, the holy catholic Church, the communion of saints, the forgiveness of sins, the resurrection of the body, and life everlasting. Amen.
            """,
            latin: """
            Credo in Deum Patrem omnipoténtem, Creatórem cæli et terræ. Et in Iesum Christum, Fílium eius únicum, Dóminum nostrum, qui concéptus est de Spíritu Sancto, natus ex María Vírgine, passus sub Póntio Piláto, crucifíxus, mórtuus, et sepúltus, descéndit ad ínferos, tértia die resurréxit a mórtuis, ascéndit ad cælos, sedet ad déxteram Dei Patris omnipoténtis, inde ventúrus est iudicáre vivos et mórtuos.

            Credo in Spíritum Sanctum, sanctam Ecclésiam cathólicam, sanctórum communiónem, remissiónem peccatórum, carnis resurrectiónem, vitam ætérnam. Amen.
            """
        )
    )

    static let ourFather = Prayer(
        id: "our-father",
        title: BilingualText(english: "Our Father", latin: "Pater Noster"),
        text: BilingualText(
            english: """
            Our Father, who art in heaven, hallowed be thy name; thy kingdom come; thy will be done on earth as it is in heaven. Give us this day our daily bread; and forgive us our trespasses, as we forgive those who trespass against us; and lead us not into temptation, but deliver us from evil. Amen.
            """,
            latin: """
            Pater noster, qui es in cælis: sanctificétur nomen tuum; advéniat regnum tuum; fiat volúntas tua, sicut in cælo, et in terra. Panem nostrum cotidiánum da nobis hódie; et dimítte nobis débita nostra, sicut et nos dimíttimus debitóribus nostris; et ne nos indúcas in tentatiónem; sed líbera nos a malo. Amen.
            """
        )
    )

    static let hailMary = Prayer(
        id: "hail-mary",
        title: BilingualText(english: "Hail Mary", latin: "Ave María"),
        text: BilingualText(
            english: """
            Hail Mary, full of grace, the Lord is with thee; blessed art thou among women, and blessed is the fruit of thy womb, Jesus. Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.
            """,
            latin: """
            Ave María, grátia plena, Dóminus tecum; benedícta tu in muliéribus, et benedíctus fructus ventris tui, Iesus. Sancta María, Mater Dei, ora pro nobis peccatóribus, nunc et in hora mortis nostræ. Amen.
            """
        )
    )

    static let gloryBe = Prayer(
        id: "glory-be",
        title: BilingualText(english: "Glory Be", latin: "Glória Patri"),
        text: BilingualText(
            english: "Glory be to the Father, and to the Son, and to the Holy Spirit, as it was in the beginning, is now, and ever shall be, world without end. Amen.",
            latin: "Glória Patri, et Fílio, et Spirítui Sancto. Sicut erat in princípio, et nunc, et semper, et in sǽcula sæculórum. Amen."
        )
    )

    static let fatima = Prayer(
        id: "fatima",
        title: BilingualText(english: "Fatima Prayer", latin: "Orátio Fatiménsis"),
        text: BilingualText(
            english: "O my Jesus, forgive us our sins, save us from the fires of hell; lead all souls to Heaven, especially those who have most need of thy mercy.",
            latin: "Dómine Iesu, dimítte nobis débita nostra, salva nos ab igne inférni, perduc in cælum omnes ánimas, præsértim eas quæ misericórdiæ tuæ máxime indigent."
        )
    )

    static let hailHolyQueen = Prayer(
        id: "hail-holy-queen",
        title: BilingualText(english: "Hail, Holy Queen", latin: "Salve Regína"),
        text: BilingualText(
            english: """
            Hail, holy Queen, Mother of mercy, our life, our sweetness, and our hope. To thee do we cry, poor banished children of Eve. To thee do we send up our sighs, mourning and weeping in this valley of tears. Turn then, most gracious advocate, thine eyes of mercy toward us, and after this our exile, show unto us the blessed fruit of thy womb, Jesus. O clement, O loving, O sweet Virgin Mary.

            V. Pray for us, O holy Mother of God.
            R. That we may be made worthy of the promises of Christ.
            """,
            latin: """
            Salve, Regína, mater misericórdiæ; vita, dulcédo, et spes nostra, salve. Ad te clamámus, éxsules fílii Hevæ. Ad te suspirámus, geméntes et flentes in hac lacrimárum valle. Eia ergo, advocáta nostra, illos tuos misericórdes óculos ad nos convérte. Et Iesum, benedíctum fructum ventris tui, nobis post hoc exsílium osténde. O clemens, o pia, o dulcis Virgo María.

            V. Ora pro nobis, sancta Dei Génitrix.
            R. Ut digni efficiámur promissiónibus Christi.
            """
        )
    )

    static let concluding = Prayer(
        id: "concluding",
        title: BilingualText(english: "Let Us Pray", latin: "Orémus"),
        text: BilingualText(
            english: """
            O God, whose only begotten Son, by his life, death, and resurrection, has purchased for us the rewards of eternal life, grant, we beseech thee, that meditating upon these mysteries of the Most Holy Rosary of the Blessed Virgin Mary, we may imitate what they contain and obtain what they promise, through the same Christ our Lord. Amen.
            """,
            latin: """
            Deus, cuius Unigénitus per vitam, mortem et resurrectiónem suam nobis salútis ætérnæ prǽmia comparávit: concéde, quǽsumus; ut hæc mystéria sacratíssimo beátæ Maríæ Vírginis Rosário recoléntes, et imitémur quod cóntinent, et quod promíttunt assequámur. Per eúndem Christum Dóminum nostrum. Amen.
            """
        )
    )

    static let saintMichael = Prayer(
        id: "saint-michael",
        title: BilingualText(english: "Prayer to Saint Michael", latin: "Orátio ad Sanctum Míchaëlem"),
        text: BilingualText(
            english: """
            Saint Michael the Archangel, defend us in battle. Be our protection against the wickedness and snares of the devil. May God rebuke him, we humbly pray; and do thou, O Prince of the heavenly host, by the power of God, cast into hell Satan and all the evil spirits who prowl about the world seeking the ruin of souls. Amen.
            """,
            latin: """
            Sancte Míchael Archángele, defénde nos in prœlio; contra nequítiam et insídias diáboli esto præsídium. Imperet illi Deus, súpplices deprecámur: tuque, Princeps milítiæ cæléstis, Sátanam aliósque spíritus malígnos, qui ad perditiónem animárum pervagántur in mundo, divína virtúte in inférnum detrúde. Amen.
            """
        )
    )

    static let faith = BilingualText(english: "For an increase of Faith", latin: "Ad fídei increméntum")
    static let hope = BilingualText(english: "For an increase of Hope", latin: "Ad spei increméntum")
    static let charity = BilingualText(english: "For an increase of Charity", latin: "Ad caritátis increméntum")

    static let openingIntentions = [faith, hope, charity]

    static func prayer(for kind: RosaryStepKind) -> Prayer? {
        switch kind {
        case .signOfTheCross: signOfTheCross
        case .creed: apostlesCreed
        case .ourFather: ourFather
        case .hailMary: hailMary
        case .gloryBe: gloryBe
        case .fatima: fatima
        case .hailHolyQueen: hailHolyQueen
        case .concludingPrayer: concluding
        case .saintMichael: saintMichael
        case .mysteryAnnouncement, .completion: nil
        }
    }
}
