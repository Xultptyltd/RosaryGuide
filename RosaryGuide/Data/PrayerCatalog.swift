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
        title: BilingualText(english: "Glory be", latin: "Gloria Patri"),
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
        title: BilingualText(english: "Fatima prayer", latin: "O mi Iesu"),
        text: BilingualText(
            english: "O my Jesus, forgive us our sins, save us from the fires of hell; lead all souls to Heaven, especially those who have most need of your mercy. Amen.",
            latin: "O mi Iesu, dimitte nobis peccata nostra, libera nos ab igne inferni, perduc omnes animas in caelum, praesertim maxime indigentes misericordia tua. Amen."
        )
    )

    static let hailHolyQueen = Prayer(
        id: "hail-holy-queen",
        title: BilingualText(english: "Hail, holy Queen", latin: "Salve Regina"),
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
        title: BilingualText(english: "The versicle", latin: "Versiculum"),
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
        title: BilingualText(english: "Closing prayer", latin: "Oratio"),
        text: BilingualText(
            english: "O God, whose Only Begotten Son, by his life, Death, and Resurrection, has purchased for us the rewards of eternal life, grant, we beseech thee, that while meditating on these mysteries of the most holy Rosary of the Blessed Virgin Mary, we may imitate what they contain and obtain what they promise, through the same Christ our Lord. Amen.",
            latin: "Deus, cuius Unigenitus per vitam, mortem et resurrectionem suam nobis salutis aeternae praemia comparavit: concede, quaesumus, ut haec mysteria sacratissimi Rosarii beatae Mariae Virginis recolentes, et imitemur quod continent, et quod promittunt assequamur. Per eundem Christum Dominum nostrum. Amen."
        )
    )

    static let memorare = Prayer(
        id: "memorare",
        title: BilingualText(english: "Memorare", latin: "Memorare"),
        text: BilingualText(
            english: "Remember, O most gracious Virgin Mary, that never was it known that anyone who fled to thy protection, implored thy help, or sought thy intercession, was left unaided. Inspired by this confidence, I fly unto thee, O Virgin of virgins, my Mother. To thee do I come, before thee I stand, sinful and sorrowful. O Mother of the Word Incarnate, despise not my petitions, but in thy mercy hear and answer me. Amen.",
            latin: "Memoráre, o piíssima Virgo María, non esse audítum a sǽculo, quemquam ad tua curréntem præsídia, tua implorántem auxília, tua peténtem suffrágia, esse derelíctum. Ego tali animátus confidéntia, ad te, Virgo Vírginum, Mater, curro, ad te vénio, coram te gemens peccátor assísto. Noli, Mater Verbi, verba mea despícere; sed audi propítia et exáudi. Amen."
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

    static let sacramentMostHoly = Prayer(
        id: "sacrament-most-holy",
        title: BilingualText(english: "O Sacrament most holy", latin: "O Sacramentum sanctissimum"),
        text: BilingualText(
            english: "O Sacrament most holy, O Sacrament divine, all praise and all thanksgiving be every moment thine. Amen.",
            latin: "O Sacraméntum sanctíssimum, o Sacraméntum divínum, omnis laus et omnis gratiárum áctio sit omni moménto tua. Amen."
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
        case .oSacrament: sacramentMostHoly
        case .memorare: memorare
        case .mysteryAnnouncement, .completion: nil
        }
    }
}

// Verified devotional additions. Source URLs identify the specific wording used.
extension PrayerCatalog {
    static let litanyOfLoreto = Prayer(id: "litany-of-loreto", title: BilingualText(english: "Litany of the Blessed Virgin Mary", latin: ""), text: BilingualText(english: "Lord have mercy.\n\nChrist have mercy.\n\nLord have mercy.\n\nChrist hear us.\n\nChrist graciously hear us.\n\nGod, the Father of heaven, have mercy on us.\n\nGod the Son, Redeemer of the world, have mercy on us.\n\nGod the Holy Spirit, have mercy on us.\n\nHoly Trinity, one God, have mercy on us.\n\nHoly Mary, pray for us.\n\nHoly Mother of God, pray for us.\n\nHoly Virgin of virgins, pray for us.\n\nMother of Christ, pray for us.\n\nMother of the Church, pray for us.\n\nMother of Mercy, pray for us.\n\nMother of divine grace, pray for us.\n\nMother of Hope, pray for us.\n\nMother most pure, pray for us.\n\nMother most chaste, pray for us.\n\nMother inviolate, pray for us.\n\nMother undefiled, pray for us.\n\nMother most amiable, pray for us.\n\nMother most admirable, pray for us.\n\nMother of good counsel, pray for us.\n\nMother of our Creator, pray for us.\n\nMother of our Saviour, pray for us.\n\nVirgin most prudent, pray for us.\n\nVirgin most venerable, pray for us.\n\nVirgin most renowned, pray for us.\n\nVirgin most powerful, pray for us.\n\nVirgin most merciful, pray for us.\n\nVirgin most faithful, pray for us.\n\nMirror of justice, pray for us.\n\nSeat of wisdom, pray for us.\n\nCause of our joy, pray for us.\n\nSpiritual vessel, pray for us.\n\nVessel of honour, pray for us.\n\nSingular vessel of devotion, pray for us.\n\nMystical rose, pray for us.\n\nTower of David, pray for us.\n\nTower of ivory, pray for us.\n\nHouse of gold, pray for us.\n\nArk of the covenant, pray for us.\n\nGate of heaven, pray for us.\n\nMorning star, pray for us.\n\nHealth of the sick, pray for us.\n\nRefuge of sinners, pray for us.\n\nSolace of Migrants, pray for us.\n\nComfort of the afflicted, pray for us.\n\nHelp of Christians, pray for us.\n\nQueen of Angels, pray for us.\n\nQueen of Patriarchs, pray for us.\n\nQueen of Prophets, pray for us.\n\nQueen of Apostles, pray for us.\n\nQueen of Martyrs, pray for us.\n\nQueen of Confessors, pray for us.\n\nQueen of Virgins, pray for us.\n\nQueen of all Saints, pray for us.\n\nQueen conceived without original sin, pray for us.\n\nQueen assumed into heaven, pray for us.\n\nQueen of the most holy Rosary, pray for us.\n\nQueen of families, pray for us.\n\nQueen of peace, pray for us.\n\nLamb of God, who takes away the sins of the world, spare us, O Lord.\n\nLamb of God, who takes away the sins of the world, graciously hear us, O Lord.\n\nLamb of God, who takes away the sins of the world, have mercy on us.\n\nV. Pray for us, O holy Mother of God.\n\nR. That we may be made worthy of the promises of Christ.\n\nLet us pray.\n\nGrant, we beseech thee, O Lord God, that we, your servants, may enjoy perpetual health of mind and body; and by the glorious intercession of the Blessed Mary, ever Virgin, may be delivered from present sorrow, and obtain eternal joy. Through Christ our Lord. Amen.", latin: ""))

    static let animaChristi = Prayer(id: "anima-christi", title: BilingualText(english: "Anima Christi", latin: "Anima Christi"), text: BilingualText(english: "Soul of Christ, sanctify me.\n\nBody of Christ, save me.\n\nBlood of Christ, embolden me.\n\nWater from the side of Christ, wash me.\n\nPassion of Christ, strengthen me.\n\nO good Jesus, hear me.\n\nWithin your wounds hide me.\n\nNever permit me to be parted from you.\n\nFrom the evil Enemy defend me.\n\nAt the hour of my death call me\n\nand bid me come to you,\n\nthat with your Saints I may praise you\n\nfor age upon age.\n\nAmen.", latin: "Anima Christi, sanctifica me.\n\nCorpus Christi, salva me.\n\nSanguis Christi, inebria me.\n\nAqua lateris Christi, lava me.\n\nPassio Christi, conforta me.\n\nO bone Iesu, exaudi me.\n\nIntra tua vulnera absconde me.\n\nNe permittas me separari a te.\n\nAb hoste maligno defende me.\n\nIn hora mortis meae voca me.\n\nEt iube me venire ad te,\n\nut cum Sanctis tuis laudem te\n\nin saecula saeculorum. Amen."))

    static let graceBeforeMeals = Prayer(id: "grace-before-meals", title: BilingualText(english: "Grace Before Meals", latin: ""), text: BilingualText(english: "Bless us, O Lord, and these thy gifts, which we are about to receive from thy bounty through Christ our Lord. Amen.", latin: ""))

    static let graceAfterMeals = Prayer(id: "grace-after-meals", title: BilingualText(english: "Grace After Meals", latin: ""), text: BilingualText(english: "We give thee thanks, for all thy benefits, Almighty God, who live and reign for ever. Amen.", latin: ""))

    static let morningOffering = Prayer(id: "morning-offering", title: BilingualText(english: "Morning Offering", latin: ""), text: BilingualText(english: "O Jesus, through the Immaculate Heart of Mary, I offer you my prayers, works, joys, and sufferings of this day for all the intentions of your Sacred Heart in union with the Holy Sacrifice of the Mass throughout the world,\n\nfor the salvation of souls, the reparation of sins, the reunion of all Christians, and in particular for the intentions of the Holy Father this month.\n\nAmen.", latin: ""))

    static let actOfContrition = Prayer(id: "act-of-contrition", title: BilingualText(english: "Act of Contrition", latin: "Actus contritionis"), text: BilingualText(english: "O my God, I am heartily sorry for having offended Thee, and I detest all my sins because of thy just punishments, but most of all because they offend Thee, my God, who art all good and deserving of all my love. I firmly resolve with the help of Thy grace to sin no more and to avoid the near occasion of sin. Amen.", latin: "Deus meus, ex toto corde paenitet me omnium meorum peccatorum, eaque detestor, quia peccando, non solum poenas a te iuste statutas promeritus sum, sed praesertim quia offendi te, summum bonum, ac dignum qui super omnia diligaris. Ideo firmiter propono, adiuvante gratia tua, de cetero me non peccaturum peccandique occasiones proximas fugiturum. Amen."))

    static let guardianAngel = Prayer(id: "guardian-angel", title: BilingualText(english: "Guardian Angel Prayer", latin: ""), text: BilingualText(english: "Angel of God, my guardian dear,\n\nto whom God’s love commits me here,\n\never this day be at my side,\n\nto light and guard, to rule and guide.\n\nAmen.", latin: ""))

    static let additionalLibraryPrayers: [Prayer] = [litanyOfLoreto, animaChristi, graceBeforeMeals, graceAfterMeals, morningOffering, actOfContrition, guardianAngel]

    struct Reference {
        let title: String
        let url: URL
    }
    struct LibraryNotes {
        let history: String
        let purpose: String
        let references: [Reference]
    }

    static func libraryNotes(for id: String) -> LibraryNotes? {
        switch id {
        case "litany-of-loreto": return LibraryNotes(history: "Also called the Litany of Loreto. The text follows the Holy See’s Rosary page, including Mother of Mercy, Mother of Hope and Solace of Migrants, added in 2020. Repeated responses are written out to make the prayer easy to follow.", purpose: "We ask Mary’s intercession through titles that honour her relationship with Christ and the Church.", references: [Reference(title: "Holy See — Litany of Loreto", url: URL(string: "https://www.vatican.va/special/rosary/documents/litanie-lauretane_en.html")!), Reference(title: "Holy See — 2020 additions", url: URL(string: "https://press.vatican.va/content/salastampa/en/bollettino/pubblico/2020/06/20/200620c.html")!)])
        case "anima-christi": return LibraryNotes(history: "A traditional prayer to Christ. The English text follows the USCCB; the Latin follows the Compendium of the Catechism. These are established versions, rather than a new translation.", purpose: "We ask Christ to sanctify, strengthen and protect us, and to keep us close to him.", references: [Reference(title: "USCCB — Anima Christi", url: URL(string: "https://www.usccb.org/prayers/anima-christi")!), Reference(title: "Holy See — Compendium, Common Prayers", url: URL(string: "https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_en.html")!)])
        case "grace-before-meals": return LibraryNotes(history: "Traditional Catholic meal blessing, reproduced in the United States Catholic Catechism for Adults, chapter 22, page 303.", purpose: "Before eating, we ask God to bless us and receive our food with gratitude.", references: [Reference(title: "USCCB — Catechism for Adults, p. 303", url: URL(string: "https://ccc.usccb.org/sites/default/files/flipbooks/uscca/files/assets/basic-html/page-331.html")!)])
        case "grace-after-meals": return LibraryNotes(history: "Traditional thanksgiving after meals, reproduced in the United States Catholic Catechism for Adults, chapter 22, page 303.", purpose: "After eating, we thank God for his gifts.", references: [Reference(title: "USCCB — Catechism for Adults, p. 303", url: URL(string: "https://ccc.usccb.org/sites/default/files/flipbooks/uscca/files/assets/basic-html/page-331.html")!)])
        case "morning-offering": return LibraryNotes(history: "This version is published by the USCCB, which attributes the Morning Offering to Fr François-Xavier Gautrelet in 1844.", purpose: "We offer the whole day to Jesus, uniting ordinary activities and difficulties with the prayer of the Church.", references: [Reference(title: "USCCB — Morning Offering", url: URL(string: "https://www.usccb.org/prayers/morning-offering")!)])
        case "act-of-contrition": return LibraryNotes(history: "The traditional form printed in the Compendium of the Catechism, Appendix A. Other approved forms of an act of contrition also exist. Latin accents and ligatures are normalised for readability.", purpose: "We express sorrow for sin and resolve, with God’s grace, to turn away from it.", references: [Reference(title: "Holy See — Compendium, Act of Contrition", url: URL(string: "https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_en.html")!)])
        case "guardian-angel": return LibraryNotes(history: "Traditional prayer to one’s guardian angel, also known by its Latin opening Angele Dei. The English wording follows the USCCB.", purpose: "We ask our guardian angel for light, protection and guidance.", references: [Reference(title: "USCCB — Prayer to Your Guardian Angel", url: URL(string: "https://www.usccb.org/prayers/prayer-your-guardian-angel")!)])
        case "hail-holy-queen": return LibraryNotes(history: "Salve Regina is the Latin name of Hail Holy Queen, a traditional Marian antiphon. Its English and Latin forms appear among the Common Prayers in the Compendium of the Catechism.", purpose: "We ask Mary to intercede for us and lead us to Jesus.", references: [Reference(title: "Holy See — Compendium, Salve Regina", url: URL(string: "https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_en.html")!)])
        default: return nil
        }
    }

    static func matchesSearch(_ prayer: Prayer, query: String) -> Bool {
        let aliases: String
        switch prayer.id {
        case "litany-of-loreto": aliases = "Litany of Loreto Blessed Virgin Mary"
        case "guardian-angel": aliases = "Angel of God Angele Dei"
        case "grace-before-meals": aliases = "Before meals prayer Bless us O Lord"
        default: aliases = ""
        }
        return [prayer.title.english, prayer.title.latin, aliases]
            .contains { $0.localizedStandardContains(query) }
    }
}

// About copy supplied by the user, combined into readable paragraphs.
extension PrayerCatalog {
    static func information(for id: String) -> String? {
        switch id {
        case "act-of-contrition": return "The traditional form printed in the Compendium of the Catechism, Appendix A. Other approved forms of an act of contrition also exist. Latin accents and ligatures are normalised for readability.\n\nWe express sorrow for sin and resolve, with God’s grace, to turn away from it."
        case "anima-christi": return "A traditional prayer to Christ. The English text follows the USCCB; the Latin follows the Compendium of the Catechism. These are established versions, rather than a new translation.\n\nWe ask Christ to sanctify, strengthen and protect us, and to keep us close to him."
        case "apostles-creed": return "The Creed grew from an early baptismal creed of the Church in Rome, known as the Old Roman Symbol. It reached its present form by the eighth century. Tradition links its twelve articles to the Apostles, though they did not write it.\n\nWe pray the Creed on the crucifix as the Rosary begins. Before we meditate, we stand with the whole Church and profess what we believe. The mysteries that follow unfold this faith."
        case "concluding": return "This prayer is the collect, or opening prayer, of the Mass of Our Lady of the Rosary in the 1962 Roman Missal. The feast is kept each year on 7 October. It sums up the whole Rosary.\n\nThis prayer gathers the whole Rosary into one request. Having meditated on the mysteries, we ask to imitate what they contain and obtain what they promise. We ask this through Christ our Lord."
        case "fatima": return "According to Sister Lúcia, Our Lady taught this prayer to the three children of Fatima on 13 July 1917. She asked that it be said after each decade. The local bishop approved the apparitions in 1930, and the prayer soon spread worldwide.\n\nSaid after each decade, this prayer asks Jesus to forgive our sins and to save all souls. It widens our prayer to the whole world, especially those most in need of mercy."
        case "glory-be": return "The Glory be is an ancient hymn of praise to the Holy Trinity. Its second half, “as it was in the beginning”, was later added in the West, traditionally to answer the Arian heresy, which denied that the Son is eternal.\n\nThe Glory be closes each decade. Every mystery ends where all prayer should end, in praise of the Father, Son and Holy Spirit. It keeps our Rosary centred on God, not ourselves."
        case "grace-after-meals": return "Traditional thanksgiving after meals, reproduced in the United States Catholic Catechism for Adults, chapter 22, page 303.\n\nAfter eating, we thank God for his gifts."
        case "grace-before-meals": return "Traditional Catholic meal blessing, reproduced in the United States Catholic Catechism for Adults, chapter 22, page 303.\n\nBefore eating, we ask God to bless us and receive our food with gratitude."
        case "guardian-angel": return "Traditional prayer to one’s guardian angel, also known by its Latin opening Angele Dei. The English wording follows the USCCB.\n\nWe ask our guardian angel for light, protection and guidance."
        case "hail-mary": return "The first half comes from Scripture: Gabriel’s greeting (Luke 1:28) and Elizabeth’s blessing (Luke 1:42). The name of Jesus was added in the Middle Ages. The full prayer appeared in the Roman Breviary of Pope Pius V in 1568.\n\nWe pray the Hail Mary ten times in each decade. As the words repeat, our hearts rest on Jesus in each mystery. We ask Mary, who knew him best, to pray for us now and at our death."
        case "hail-holy-queen": return "Salve Regina is the Latin name of Hail Holy Queen, a traditional Marian antiphon. Its English and Latin forms appear among the Common Prayers in the Compendium of the Catechism.\n\nWe ask Mary to intercede for us and lead us to Jesus."
        case "litany-of-loreto": return "Also called the Litany of Loreto. The text follows the Holy See’s Rosary page, including Mother of Mercy, Mother of Hope and Solace of Migrants, added in 2020. Repeated responses are written out to make the prayer easy to follow.\n\nWe ask Mary’s intercession through titles that honour her relationship with Christ and the Church."
        case "memorare": return "The Memorare is often linked to Saint Bernard of Clairvaux, but its text comes from the 15th century. In the 1600s Fr Claude Bernard, a Paris priest called “the Poor Priest”, spread it widely among prisoners and the sick.\n\nMany pray the Memorare after the Rosary. It reminds us that no one who turned to Mary has ever been left without help. We bring her our needs with a child’s trust."
        case "morning-offering": return "This version is published by the USCCB, which attributes the Morning Offering to Fr François-Xavier Gautrelet in 1844.\n\nWe offer the whole day to Jesus, uniting ordinary activities and difficulties with the prayer of the Church."
        case "sacrament-most-holy": return "No one knows who wrote this short prayer of praise to Jesus in the Eucharist, or when. It spread through Eucharistic devotion. Many people now add it after the Fatima prayer at each decade.\n\nThough not part of the traditional Rosary, this prayer joins our meditation to adoration. It reminds us that the Jesus we meet in each mystery is truly with us still in the Blessed Sacrament."
        case "our-father": return "Jesus himself gave us this prayer when his disciples asked him to teach them to pray (Matthew 6:9–13; Luke 11:2–4). Christians have prayed it every day since the first centuries.\n\nThe Our Father opens each decade, so every set of Hail Marys begins with the words Jesus taught. We come before God as his children, trusting him as our loving Father."
        case "saint-michael": return "Pope Leo XIII wrote this prayer in 1886 and added it to the prayers said after Low Mass. They were said worldwide until 1965. The prayer draws on Scripture’s picture of Michael as protector of God’s people (Daniel 12:1; Revelation 12:7–9).\n\nMany add this prayer after the Rosary. It reminds us that the spiritual life is a real battle. We ask Saint Michael to defend us, so that we stay faithful to God."
        case "sign-of-the-cross": return "Christians have marked themselves with the cross from the earliest days. Around AD 200, Tertullian wrote that believers traced it on their foreheads throughout the day. Its words echo Jesus’ command to baptise in the name of the Trinity (Matthew 28:19).\n\nWe begin and end the Rosary with the Sign of the Cross. In one simple gesture we profess faith in the Trinity, recall our baptism and place our whole prayer under Christ’s Cross."
        default: return nil
        }
    }
}

// MARK: - Novenas and Rosary types (Learn)

/// A devotion explained on the Learn screen. Text is limited to established
/// prayers and facts, each page carrying the sources it was checked against.
struct Devotion: Identifiable, Hashable, Sendable {
    struct Step: Hashable, Sendable {
        var title: String
        var detail: String
    }

    struct Passage: Hashable, Sendable {
        var heading: String
        var body: String
    }

    struct Station: Hashable, Sendable {
        var title: String
        var reference: String
    }

    var id: String
    var eyebrow: String
    var title: String
    var summary: String
    var about: [String]
    /// Mystery whose artwork represents the devotion.
    var artSet: MysterySetKind
    var artMystery: Int
    var stepsTitle: String
    var steps: [Step]
    var stationsTitle: String? = nil
    var stations: [Station] = []
    var passages: [Passage] = []
    /// Existing prayers from the library, by id.
    var prayerIDs: [String] = []
    /// Shows links to the four sets so each mystery's Scripture is one tap away.
    var linksMysterySets = false
    var references: [PrayerCatalog.Reference]

    static func == (lhs: Devotion, rhs: Devotion) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum DevotionCatalog {
    static let all: [Devotion] = [scripturalRosary, divineMercyChaplet, sevenSorrowsChaplet, novena]

    static func devotion(id: String) -> Devotion? { all.first { $0.id == id } }

    static func matchesSearch(_ devotion: Devotion, query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return false }
        return [devotion.title, devotion.eyebrow, devotion.summary].contains { $0.localizedCaseInsensitiveContains(query) }
    }

    private static let directory = PrayerCatalog.Reference(
        title: "Holy See — Directory on Popular Piety and the Liturgy",
        url: URL(string: "https://www.vatican.va/roman_curia/congregations/ccdds/documents/rc_con_ccdds_doc_20020513_vers-direttorio_en.html")!
    )

    static let scripturalRosary = Devotion(
        id: "scriptural-rosary",
        eyebrow: "Rosary type",
        title: "Scriptural Rosary",
        summary: "The Rosary prayed with a Bible passage for each mystery, so God’s word leads the meditation",
        about: [
            "Saint John Paul II recommended following the announcement of each mystery with a related Bible passage, long or short, and then a moment of silence before the vocal prayers (Rosarium Virginis Mariae, 30–31).",
            "Some also add a short phrase after the name of Jesus in each Hail Mary that recalls the mystery. The Directory on Popular Piety and the Liturgy commends a short Scriptural clause fixed for each decade (201)."
        ],
        artSet: .joyful,
        artMystery: 1,
        stepsTitle: "For each decade",
        steps: [
            Devotion.Step(title: "Announce the mystery", detail: "For example, the Annunciation"),
            Devotion.Step(title: "Read the passage", detail: "Each mystery below has its Scripture"),
            Devotion.Step(title: "Pause in silence", detail: "Let the word settle before you pray"),
            Devotion.Step(title: "Pray the decade", detail: "One Our Father, ten Hail Marys and one Glory be")
        ],
        linksMysterySets: true,
        references: [
            PrayerCatalog.Reference(title: "Holy See — Rosarium Virginis Mariae, 30–31", url: URL(string: "https://www.vatican.va/content/john-paul-ii/en/apost_letters/2002/documents/hf_jp-ii_apl_20021016_rosarium-virginis-mariae.html")!),
            directory
        ]
    )

    static let divineMercyChaplet = Devotion(
        id: "divine-mercy-chaplet",
        eyebrow: "Chaplet",
        title: "Chaplet of Divine Mercy",
        summary: "Prayed on ordinary Rosary beads, asking God’s mercy for us and for the whole world",
        about: [
            "The chaplet comes from the writings of Saint Faustina Kowalska, canonised in 2000. The Directory on Popular Piety and the Liturgy asks that devotion to the Divine Mercy be understood in the light of the Second Sunday of Easter, now called Divine Mercy Sunday (154).",
            "The words below follow the USCCB."
        ],
        artSet: .glorious,
        artMystery: 1,
        stepsTitle: "How to pray",
        steps: [
            Devotion.Step(title: "Begin", detail: "Sign of the Cross, then the optional opening prayer"),
            Devotion.Step(title: "On the first beads", detail: "One Our Father, one Hail Mary and the Apostles’ Creed"),
            Devotion.Step(title: "On each Our Father bead", detail: "Eternal Father, I offer you…"),
            Devotion.Step(title: "On each of the ten Hail Mary beads", detail: "For the sake of his sorrowful Passion…"),
            Devotion.Step(title: "To conclude", detail: "Holy God, three times")
        ],
        passages: [
            Devotion.Passage(heading: "Opening prayer, optional", body: FeastNarratives.divineMercy.english),
            Devotion.Passage(heading: "On each Our Father bead", body: "Eternal Father, I offer you the Body and Blood, soul and divinity of your dearly beloved Son, our Lord Jesus Christ, in atonement for our sins and those of the whole world."),
            Devotion.Passage(heading: "On each Hail Mary bead", body: "For the sake of his sorrowful Passion, have mercy on us and on the whole world."),
            Devotion.Passage(heading: "Three times to conclude", body: "Holy God, Holy Mighty One, Holy Immortal One, have mercy on us and on the whole world.")
        ],
        prayerIDs: ["sign-of-the-cross", "our-father", "hail-mary", "apostles-creed"],
        references: [
            PrayerCatalog.Reference(title: "USCCB — Chaplet of Divine Mercy", url: URL(string: "https://www.usccb.org/prayers/divine-mercy-chaplet")!),
            directory
        ]
    )

    static let sevenSorrowsChaplet = Devotion(
        id: "seven-sorrows-chaplet",
        eyebrow: "Chaplet",
        title: "Chaplet of the Seven Sorrows",
        summary: "Also called the Servite Rosary, it keeps company with Mary in seven sorrows of her life",
        about: [
            "In 1239 the seven founders of the Servite Order took up the sorrows of Mary standing beneath the Cross as their order’s principal devotion. The seven sorrows below are those listed by the Catholic Encyclopedia for the Servite feast.",
            "The Church keeps the memorial of Our Lady of Sorrows on 15 September."
        ],
        artSet: .sorrowful,
        artMystery: 5,
        stepsTitle: "How to pray",
        steps: [
            Devotion.Step(title: "For each sorrow", detail: "Name it and ponder it for a moment"),
            Devotion.Step(title: "Then pray", detail: "One Our Father and seven Hail Marys"),
            Devotion.Step(title: "Many also add", detail: "Three Hail Marys in honour of Our Lady’s tears")
        ],
        stationsTitle: "The seven sorrows",
        stations: [
            Devotion.Station(title: "The prophecy of Simeon", reference: "Luke 2:34–35"),
            Devotion.Station(title: "The flight into Egypt", reference: "Matthew 2:13–14"),
            Devotion.Station(title: "The loss of Jesus in Jerusalem", reference: "Luke 2:43–45"),
            Devotion.Station(title: "Meeting Jesus on the way to Calvary", reference: "Tradition"),
            Devotion.Station(title: "Standing at the foot of the Cross", reference: "John 19:25"),
            Devotion.Station(title: "Jesus is taken down from the Cross", reference: "Matthew 27:57–59"),
            Devotion.Station(title: "The burial of Jesus", reference: "John 19:40–42")
        ],
        prayerIDs: ["our-father", "hail-mary"],
        references: [
            PrayerCatalog.Reference(title: "Catholic Encyclopedia — Feasts of the Seven Sorrows", url: URL(string: "https://www.newadvent.org/cathen/14151b.htm")!),
            PrayerCatalog.Reference(title: "Secular Servites — Rosary of the Seven Sorrows", url: URL(string: "https://secularservites.org/wp-content/uploads/2026/02/Servite_Seven_Sorrows_Rosary_Version_1.pdf")!)
        ]
    )

    static let novena = Devotion(
        id: "novena",
        eyebrow: "Novena",
        title: "Praying a novena",
        summary: "Nine days of prayer for one intention, or to prepare for a feast",
        about: [
            "The word comes from the Latin novem, nine. The model is the first novena: after the Ascension the apostles joined in continuous prayer with Mary, the mother of Jesus, while they waited for the Holy Spirit (Acts 1:14). The Pentecost novena grew from this (Directory on Popular Piety and the Liturgy, 155).",
            "Feasts are often prepared with a novena, such as the novena of the Immaculate Conception and the Christmas novena (Directory, 102–103), and the novena for the dead before 2 November (Directory, 260). Novenas before feasts of Our Lady are commended especially when they lead to Confession and the Eucharist (Directory, 189)."
        ],
        artSet: .glorious,
        artMystery: 3,
        stepsTitle: "With the Rosary",
        steps: [
            Devotion.Step(title: "Choose your intention", detail: "Or the feast you are preparing for"),
            Devotion.Step(title: "Pray for nine days", detail: "Offer the Rosary for it each day, nine days in a row")
        ],
        references: [
            directory,
            PrayerCatalog.Reference(title: "Catholic Encyclopedia — Novena", url: URL(string: "https://www.newadvent.org/cathen/11141b.htm")!)
        ]
    )
}
