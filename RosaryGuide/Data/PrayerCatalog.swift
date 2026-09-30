import Foundation

enum PrayerCatalog {
    static let signOfTheCross = Prayer(
        id: "sign-of-the-cross",
        title: BilingualText(english: "Sign of the Cross", latin: "Signum Crucis"),
        text: BilingualText(
            english: "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.",
            latin: "In nomine Patris, et Filii, et Spiritus Sancti. Amen."
        )
    )

    static let apostlesCreed = Prayer(
        id: "apostles-creed",
        title: BilingualText(english: "Apostles' Creed", latin: "Symbolum Apostolorum"),
        text: BilingualText(
            english: """
            I believe in God, the Father almighty, Creator of heaven and earth, and in Jesus Christ, his only Son, our Lord,

            who was conceived by the Holy Spirit, born of the Virgin Mary, suffered under Pontius Pilate, was crucified, died and was buried; he descended into hell; on the third day he rose again from the dead; he ascended into heaven, and is seated at the right hand of God the Father almighty; from there he will come to judge the living and the dead.

            I believe in the Holy Spirit, the holy catholic Church, the communion of saints, the forgiveness of sins, the resurrection of the body, and life everlasting. Amen.
            """,
            latin: """
            Credo in Deum Patrem omnipotentem, Creatorem caeli et terrae. Et in Iesum Christum, Filium eius unicum, Dominum nostrum,

            qui conceptus est de Spiritu Sancto, natus ex Maria Virgine, passus sub Pontio Pilato, crucifixus, mortuus, et sepultus; descendit ad inferos; tertia die resurrexit a mortuis; ascendit ad caelos, sedet ad dexteram Dei Patris omnipotentis; inde venturus est iudicare vivos et mortuos.

            Credo in Spiritum Sanctum, sanctam Ecclesiam catholicam, sanctorum communionem, remissionem peccatorum, carnis resurrectionem, vitam aeternam. Amen.
            """
        )
    )

    static let ourFather = Prayer(
        id: "our-father",
        title: BilingualText(english: "Our Father", latin: "Pater Noster"),
        text: BilingualText(
            english: """
            Our Father, who art in heaven, hallowed be thy name; thy kingdom come; thy will be done on earth as it is in heaven.

            Give us this day our daily bread; and forgive us our trespasses as we forgive those who trespass against us; and lead us not into temptation, but deliver us from evil. Amen.
            """,
            latin: """
            Pater noster, qui es in caelis, sanctificetur nomen tuum. Adveniat regnum tuum. Fiat voluntas tua, sicut in caelo, et in terra.

            Panem nostrum cotidianum da nobis hodie, et dimitte nobis debita nostra, sicut et nos dimittimus debitoribus nostris. Et ne nos inducas in tentationem, sed libera nos a malo. Amen.
            """
        )
    )

    static let hailMary = Prayer(
        id: "hail-mary",
        title: BilingualText(english: "Hail Mary", latin: "Ave Maria"),
        text: BilingualText(
            english: """
            Hail Mary, full of grace, the Lord is with thee; blessed art thou among women, and blessed is the fruit of thy womb, Jesus.

            Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.
            """,
            latin: """
            Ave Maria, gratia plena, Dominus tecum. Benedicta tu in mulieribus, et benedictus fructus ventris tui, Iesus.

            Sancta Maria, Mater Dei, ora pro nobis peccatoribus, nunc et in hora mortis nostrae. Amen.
            """
        )
    )

    static let gloryBe = Prayer(
        id: "glory-be",
        title: BilingualText(english: "Glory Be", latin: "Gloria Patri"),
        text: BilingualText(
            english: """
            Glory be to the Father, and to the Son, and to the Holy Spirit.

            As it was in the beginning, is now, and ever shall be, world without end. Amen.
            """,
            latin: """
            Gloria Patri, et Filio, et Spiritui Sancto.

            Sicut erat in principio, et nunc, et semper, et in saecula saeculorum. Amen.
            """
        )
    )

    static let fatima = Prayer(
        id: "fatima",
        title: BilingualText(english: "Fatima Prayer", latin: "O mi Iesu"),
        text: BilingualText(
            english: "O my Jesus, forgive us our sins, save us from the fires of hell; lead all souls to Heaven, especially those who have most need of your mercy. Amen.",
            latin: "O mi Iesu, dimitte nobis peccata nostra, libera nos ab igne inferni, perduc omnes animas in caelum, praesertim maxime indigentes misericordia tua. Amen."
        )
    )

    static let hailHolyQueen = Prayer(
        id: "hail-holy-queen",
        title: BilingualText(english: "Hail, Holy Queen", latin: "Salve Regina"),
        text: BilingualText(
            english: """
            Hail, Holy Queen, Mother of Mercy, our life, our sweetness and our hope. To thee do we cry, poor banished children of Eve. To thee do we send up our sighs, mourning and weeping in this valley of tears.

            Turn then, most gracious advocate, thine eyes of mercy toward us, and after this our exile, show unto us the blessed fruit of thy womb, Jesus.

            O clement, O loving, O sweet Virgin Mary.
            """,
            latin: """
            Salve, Regina, mater misericordiae, vita, dulcedo, et spes nostra, salve. Ad te clamamus, exsules filii Hevae. Ad te suspiramus, gementes et flentes in hac lacrimarum valle.

            Eia ergo, advocata nostra, illos tuos misericordes oculos ad nos converte. Et Iesum, benedictum fructum ventris tui, nobis post hoc exsilium ostende.

            O clemens, o pia, o dulcis Virgo Maria.
            """
        )
    )

    static let versicle = Prayer(
        id: "versicle",
        title: BilingualText(english: "The Versicle", latin: "Versiculum"),
        text: BilingualText(
            english: """
            V. Pray for us, O holy Mother of God.
            R. That we may be made worthy of the promises of Christ.
            """,
            latin: """
            V. Ora pro nobis, sancta Dei Genetrix.
            R. Ut digni efficiamur promissionibus Christi.
            """
        )
    )

    static let concluding = Prayer(
        id: "concluding",
        title: BilingualText(english: "Closing Prayer", latin: "Oratio"),
        text: BilingualText(
            english: "O God, whose Only Begotten Son, by his life, Death, and Resurrection, has purchased for us the rewards of eternal life, grant, we beseech thee, that while meditating on these mysteries of the most holy Rosary of the Blessed Virgin Mary, we may imitate what they contain and obtain what they promise, through the same Christ our Lord. Amen.",
            latin: "Deus, cuius Unigenitus per vitam, mortem et resurrectionem suam nobis salutis aeternae praemia comparavit: concede, quaesumus, ut haec mysteria sacratissimi Rosarii beatae Mariae Virginis recolentes, et imitemur quod continent, et quod promittunt assequamur. Per eundem Christum Dominum nostrum. Amen."
        )
    )

    static let saintMichael = Prayer(
        id: "saint-michael",
        title: BilingualText(english: "Saint Michael the Archangel", latin: "Sancte Michael Archangele"),
        text: BilingualText(
            english: """
            Saint Michael the Archangel, defend us in battle. Be our protection against the wickedness and snares of the devil.

            May God rebuke him, we humbly pray; and do thou, O Prince of the heavenly host, by the power of God, cast into hell Satan and all the evil spirits who prowl about the world seeking the ruin of souls. Amen.
            """,
            latin: """
            Sancte Michael Archangele, defende nos in proelio; contra nequitiam et insidias diaboli esto praesidium.

            Imperet illi Deus, supplices deprecamur: tuque, Princeps militiae caelestis, Satanam aliosque spiritus malignos, qui ad perditionem animarum pervagantur in mundo, divina virtute in infernum detrude. Amen.
            """
        )
    )

    static let angelOfGod = Prayer(
        id: "angel-of-god",
        title: BilingualText(english: "Angel of God", latin: "Angele Dei"),
        text: BilingualText(
            english: "Angel of God, my guardian dear, to whom God's love commits me here, ever this day be at my side, to light and guard, to rule and guide. Amen.",
            latin: "Ángele Dei, qui custos es mei, me, tibi commíssum pietáte supérna, illúmina, custódi, rege et gubérna. Amen."
        )
    )

    static let faith = BilingualText(english: "For an increase in faith", latin: "Ad fidei incrementum")
    static let hope = BilingualText(english: "For an increase in hope", latin: "Ad spei incrementum")
    static let charity = BilingualText(english: "For an increase in charity", latin: "Ad caritatis incrementum")
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
        case .versicle: versicle
        case .concludingPrayer: concluding
        case .saintMichael: saintMichael
        case .mysteryAnnouncement, .completion: nil
        }
    }
}
