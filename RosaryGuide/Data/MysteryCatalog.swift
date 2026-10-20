import Foundation

enum MysteryCatalog {
    static func mysteries(for set: MysterySetKind) -> [Mystery] {
        all.filter { $0.set == set }.sorted { $0.number < $1.number }
    }

    static let all: [Mystery] = joyful + luminous + sorrowful + glorious

    private static func item(
        _ id: String,
        _ set: MysterySetKind,
        _ n: Int,
        _ en: String,
        _ la: String,
        _ fruitEn: String,
        _ fruitLa: String,
        _ excerpt: String,
        _ ref: String,
        _ slug: String
    ) -> Mystery {
        Mystery(
            id: id,
            set: set,
            number: n,
            title: BilingualText(english: en, latin: la),
            fruit: BilingualText(english: fruitEn, latin: fruitLa),
            scriptureReference: ref,
            // Latin follows the Clementine Vulgate; without one, Latin mode shows the English.
            scriptureExcerpt: BilingualText(english: excerpt, latin: MysteryScripture.vulgate[id] ?? ""),
            artSlug: slug
        )
    }

    static let joyful: [Mystery] = [
        item("joyful-1", .joyful, 1, "The Annunciation", "Annuntiatio",
             "Humility", "Humilitas",
             "Now in the sixth month, the angel Gabriel was sent from God to a city of Galilee named Nazareth, to a virgin pledged to be married to a man whose name was Joseph, of David’s house. The virgin’s name was Mary.",
             "Luke 1:26-27", "01-annunciation"),
        item("joyful-2", .joyful, 2, "The Visitation", "Visitatio",
             "Love of Neighbor", "Caritas erga proximum",
             "When Elizabeth heard Mary’s greeting, the baby leaped in her womb; and Elizabeth was filled with the Holy Spirit. She called out with a loud voice and said, “Blessed are you among women, and blessed is the fruit of your womb!”",
             "Luke 1:41-42", "02-visitation"),
        item("joyful-3", .joyful, 3, "The Nativity", "Nativitas",
             "Poverty", "Paupertas",
             "She gave birth to her firstborn son. She wrapped him in bands of cloth and laid him in a feeding trough, because there was no room for them in the inn.",
             "Luke 2:7", "03-birth-of-jesus"),
        item("joyful-4", .joyful, 4, "The Presentation in the Temple", "Praesentatio",
             "Purity of Heart and Body", "Puritas cordis et corporis",
             "When the days of their purification according to the law of Moses were fulfilled, they brought him up to Jerusalem to present him to the Lord…",
             "Luke 2:22", "04-presentation-of-the-baby-jesus"),
        item("joyful-5", .joyful, 5, "The Finding in the Temple", "Inventio in Templo",
             "Devotion to Jesus", "Devotio erga Iesum",
             "After three days they found him in the temple, sitting in the middle of the teachers, both listening to them and asking them questions.",
             "Luke 2:46", "05-finding-of-the-child-jesus-in-the-temple")
    ]

    static let luminous: [Mystery] = [
        item("luminous-1", .luminous, 1, "The Baptism in the Jordan", "Baptisma in Iordane",
             "Openness to the Holy Spirit", "Docilitas Spiritui Sancto",
             "Jesus, when he was baptized, went up directly from the water: and behold, the heavens were opened to him. He saw the Spirit of God descending as a dove, and coming on him. Behold, a voice out of the heavens said, “This is my beloved Son, with whom I am well pleased.”",
             "Matthew 3:16-17", "01-baptism-of-jesus-in-the-jordan"),
        item("luminous-2", .luminous, 2, "The Wedding at Cana", "Nuptiae in Cana",
             "To Jesus through Mary", "Ad Iesum per Mariam",
             "When the wine ran out, Jesus’ mother said to him, “They have no wine.” … His mother said to the servants, “Whatever he says to you, do it.”",
             "John 2:3, 5", "02-miracle-at-the-wedding-at-cana"),
        item("luminous-3", .luminous, 3, "The Proclamation of the Kingdom", "Proclamatio Regni",
             "Conversion", "Conversio",
             "and saying, “The time is fulfilled, and God’s Kingdom is at hand! Repent, and believe in the Good News.”",
             "Mark 1:15", "03-proclamation-of-the-kingdom-of-god"),
        item("luminous-4", .luminous, 4, "The Transfiguration", "Transfiguratio",
             "Desire for holiness", "Desiderium sanctitatis",
             "After six days, Jesus took with him Peter, James, and John his brother, and brought them up into a high mountain by themselves. He was changed before them. His face shone like the sun, and his garments became as white as the light.",
             "Matthew 17:1-2", "04-transfiguration"),
        item("luminous-5", .luminous, 5, "The Institution of the Eucharist", "Institutio Eucharistiae",
             "Adoration", "Adoratio",
             "As they were eating, Jesus took bread, gave thanks for it, and broke it. He gave to the disciples and said, “Take, eat; this is my body.”",
             "Matthew 26:26", "05-institution-of-the-holy-eucharist")
    ]

    static let sorrowful: [Mystery] = [
        item("sorrowful-1", .sorrowful, 1, "The Agony in the Garden", "Agonia in Horto",
             "Obedience to God’s Will", "Oboedientia voluntati Dei",
             "Then Jesus said to them, “My soul is exceedingly sorrowful, even to death. Stay here and watch with me.” He went forward a little, fell on his face, and prayed, saying, “My Father, if it is possible, let this cup pass away from me; nevertheless, not what I desire, but what you desire.”",
             "Matthew 26:38-39", "01-agony-in-the-garden"),
        item("sorrowful-2", .sorrowful, 2, "The Scourging at the Pillar", "Flagellatio",
             "Mortification", "Mortificatio",
             "Then he released Barabbas to them, but Jesus he flogged and delivered to be crucified.",
             "Matthew 27:26", "02-scourging-at-the-pillar"),
        item("sorrowful-3", .sorrowful, 3, "The Crowning with Thorns", "Coronatio Spinis",
             "Courage", "Fortitudo",
             "They braided a crown of thorns and put it on his head, and a reed in his right hand; and they kneeled down before him and mocked him, saying, “Hail, King of the Jews!”",
             "Matthew 27:29", "03-crowning-with-thorns"),
        item("sorrowful-4", .sorrowful, 4, "The Carrying of the Cross", "Baiulatio Crucis",
             "Patience", "Patientia",
             "They compelled one passing by, coming from the country, Simon of Cyrene, the father of Alexander and Rufus, to go with them that he might bear his cross. They brought him to the place called Golgotha, which is, being interpreted, “The place of a skull.”",
             "Mark 15:21-22", "04-carrying-of-the-cross"),
        item("sorrowful-5", .sorrowful, 5, "The Crucifixion", "Crucifixio",
             "Sorrow for our Sins", "Dolor peccatorum",
             "When they came to the place that is called “The Skull”, they crucified him there with the criminals, one on the right and the other on the left. … Jesus, crying with a loud voice, said, “Father, into your hands I commit my spirit!” Having said this, he breathed his last.",
             "Luke 23:33, 46", "05-crucifixion")
    ]

    static let glorious: [Mystery] = [
        item("glorious-1", .glorious, 1, "The Resurrection", "Resurrectio",
             "Faith", "Fides",
             "Why do you seek the living among the dead? He isn’t here, but is risen.",
             "Luke 24:5-6", "01-resurrection"),
        item("glorious-2", .glorious, 2, "The Ascension", "Ascensio",
             "Hope", "Spes",
             "So then the Lord, after he had spoken to them, was received up into heaven and sat down at the right hand of God.",
             "Mark 16:19", "02-ascension"),
        item("glorious-3", .glorious, 3, "The Descent of the Holy Spirit", "Descensus Spiritus Sancti",
             "Wisdom", "Sapientia",
             "Tongues like fire appeared and were distributed to them, and one sat on each of them. They were all filled with the Holy Spirit and began to speak with other languages, as the Spirit gave them the ability to speak.",
             "Acts 2:3-4", "03-descent-of-the-holy-spirit"),
        item("glorious-4", .glorious, 4, "The Assumption", "Assumptio",
             "Devotion to Mary", "Devotio erga Mariam",
             "For behold, from now on, all generations will call me blessed. For he who is mighty has done great things for me. Holy is his name.",
             "Luke 1:48-49", "04-assumption"),
        item("glorious-5", .glorious, 5, "The Coronation of Mary", "Coronatio Beatae Mariae Virginis",
             "Grace of a happy death", "Gratia bonae mortis",
             "A great sign was seen in heaven: a woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars.",
             "Revelation 12:1", "05-coronation")
    ]
}

/// Mystery scripture by translation, for the same verse windows as `Mystery.scriptureReference`.
/// Douay-Rheims: Challoner revision, 1899 American edition (public domain).
/// Latin Vulgate: Clementine Vulgate (public domain). Both checked against bible-api.com's
/// public-domain `dra` and `clementine` texts. The catalog's own excerpt is the World English
/// Bible, Catholic Edition (eBible.org, public domain).
enum MysteryScripture {
    static func excerpt(for mystery: Mystery, translation: BibleTranslation) -> String {
        switch translation {
        case .webCatholic: mystery.scriptureExcerpt.english
        case .douayRheims: douayRheims[mystery.id] ?? mystery.scriptureExcerpt.english
        case .vulgate: vulgate[mystery.id] ?? mystery.scriptureExcerpt.english
        }
    }

    /// Excerpt for display outside the prayer flow (Home, Learn), following the
    /// Bible translation setting live. WEB Catholic keeps the prayer-language choice.
    static func display(for mystery: Mystery, translation: BibleTranslation, language: PrayerLanguage) -> String {
        translation == .webCatholic
            ? mystery.scriptureExcerpt.primary(for: language)
            : excerpt(for: mystery, translation: translation)
    }

    static let douayRheims: [String: String] = [
        "joyful-1": "And in the sixth month, the angel Gabriel was sent from God into a city of Galilee, called Nazareth, to a virgin espoused to a man whose name was Joseph, of the house of David; and the virgin’s name was Mary.",
        "joyful-2": "And it came to pass, that when Elizabeth heard the salutation of Mary, the infant leaped in her womb. And Elizabeth was filled with the Holy Ghost: and she cried out with a loud voice, and said: Blessed art thou among women, and blessed is the fruit of thy womb.",
        "joyful-3": "And she brought forth her firstborn son, and wrapped him up in swaddling clothes, and laid him in a manger; because there was no room for them in the inn.",
        "joyful-4": "And after the days of her purification, according to the law of Moses, were accomplished, they carried him to Jerusalem, to present him to the Lord.",
        "joyful-5": "And it came to pass, that, after three days, they found him in the temple, sitting in the midst of the doctors, hearing them, and asking them questions.",
        "luminous-1": "And Jesus being baptized, forthwith came out of the water: and lo, the heavens were opened to him: and he saw the Spirit of God descending as a dove, and coming upon him. And behold a voice from heaven, saying: This is my beloved Son, in whom I am well pleased.",
        "luminous-2": "And the wine failing, the mother of Jesus saith to him: They have no wine. His mother saith to the waiters: Whatsoever he shall say to you, do ye.",
        "luminous-3": "The time is accomplished, and the kingdom of God is at hand: repent, and believe the gospel.",
        "luminous-4": "And after six days Jesus taketh unto him Peter and James, and John his brother, and bringeth them up into a high mountain apart: and he was transfigured before them. And his face did shine as the sun: and his garments became white as snow.",
        "luminous-5": "And whilst they were at supper, Jesus took bread, and blessed, and broke: and gave to his disciples, and said: Take ye, and eat. This is my body.",
        "sorrowful-1": "Then he saith to them: My soul is sorrowful even unto death: stay you here, and watch with me. And going a little further, he fell upon his face, praying, and saying: My Father, if it be possible, let this chalice pass from me. Nevertheless not as I will, but as thou wilt.",
        "sorrowful-2": "Then he released to them Barabbas, and having scourged Jesus, delivered him unto them to be crucified.",
        "sorrowful-3": "And platting a crown of thorns, they put it upon his head, and a reed in his right hand. And bowing the knee before him, they mocked him, saying: Hail, king of the Jews.",
        "sorrowful-4": "And they forced one Simon a Cyrenian who passed by, coming out of the country, the father of Alexander and of Rufus, to take up his cross. And they bring him into the place called Golgotha, which being interpreted is, The place of Calvary.",
        "sorrowful-5": "And when they were come to the place which is called Calvary, they crucified him there; and the robbers, one on the right hand, and the other on the left. And Jesus crying out with a loud voice, said: Father, into thy hands I commend my spirit. And saying this, he gave up the ghost.",
        "glorious-1": "Why seek you the living with the dead? He is not here, but is risen.",
        "glorious-2": "And the Lord Jesus, after he had spoken to them, was taken up into heaven, and sitteth on the right hand of God.",
        "glorious-3": "And there appeared to them parted tongues as it were of fire, and it sat upon every one of them: and they were all filled with the Holy Ghost, and they began to speak with divers tongues, according as the Holy Ghost gave them to speak.",
        "glorious-4": "For behold from henceforth all generations shall call me blessed. Because he that is mighty, hath done great things to me; and holy is his name.",
        "glorious-5": "And a great sign appeared in heaven: A woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars.",
    ]

    static let vulgate: [String: String] = [
        "joyful-1": "In mense autem sexto, missus est angelus Gabriel a Deo in civitatem Galilææ, cui nomen Nazareth, ad virginem desponsatam viro, cui nomen erat Joseph, de domo David: et nomen virginis Maria.",
        "joyful-2": "Et factum est, ut audivit salutationem Mariæ Elisabeth, exsultavit infans in utero ejus: et repleta est Spiritu Sancto Elisabeth: et exclamavit voce magna, et dixit: Benedicta tu inter mulieres, et benedictus fructus ventris tui.",
        "joyful-3": "Et peperit filium suum primogenitum, et pannis eum involvit, et reclinavit eum in præsepio: quia non erat eis locus in diversorio.",
        "joyful-4": "Et postquam impleti sunt dies purgationis ejus secundum legem Moysi, tulerunt illum in Jerusalem, ut sisterent eum Domino.",
        "joyful-5": "Et factum est, post triduum invenerunt illum in templo sedentem in medio doctorum, audientem illos, et interrogantem eos.",
        "luminous-1": "Baptizatus autem Jesus, confestim ascendit de aqua, et ecce aperti sunt ei cæli: et vidit Spiritum Dei descendentem sicut columbam, et venientem super se. Et ecce vox de cælis dicens: Hic est Filius meus dilectus, in quo mihi complacui.",
        "luminous-2": "Et deficiente vino, dicit mater Jesu ad eum: Vinum non habent. Dicit mater ejus ministris: Quodcumque dixerit vobis, facite.",
        "luminous-3": "Impletum est tempus, et appropinquavit regnum Dei: pœnitemini, et credite Evangelio.",
        "luminous-4": "Et post dies sex assumit Jesus Petrum, et Jacobum, et Joannem fratrem ejus, et ducit illos in montem excelsum seorsum: et transfiguratus est ante eos. Et resplenduit facies ejus sicut sol: vestimenta autem ejus facta sunt alba sicut nix.",
        "luminous-5": "Cœnantibus autem eis, accepit Jesus panem, et benedixit, ac fregit, deditque discipulis suis, et ait: Accipite, et comedite: hoc est corpus meum.",
        "sorrowful-1": "Tunc ait illis: Tristis est anima mea usque ad mortem: sustinete hic, et vigilate mecum. Et progressus pusillum, procidit in faciem suam, orans, et dicens: Pater mi, si possibile est, transeat a me calix iste: verumtamen non sicut ego volo, sed sicut tu.",
        "sorrowful-2": "Tunc dimisit illis Barabbam: Jesum autem flagellatum tradidit eis ut crucifigeretur.",
        "sorrowful-3": "Et plectentes coronam de spinis, posuerunt super caput ejus, et arundinem in dextera ejus. Et genu flexo ante eum, illudebant ei, dicentes: Ave rex Judæorum.",
        "sorrowful-4": "Et angariaverunt prætereuntem quempiam, Simonem Cyrenæum venientem de villa, patrem Alexandri et Rufi, ut tolleret crucem ejus. Et perducunt illum in Golgotha locum: quod est interpretatum Calvariæ locus.",
        "sorrowful-5": "Et postquam venerunt in locum qui vocatur Calvariæ, ibi crucifixerunt eum: et latrones, unum a dextris, et alterum a sinistris. Et clamans voce magna Jesus ait: Pater, in manus tuas commendo spiritum meum. Et hæc dicens, expiravit.",
        "glorious-1": "Quid quæritis viventem cum mortuis? Non est hic, sed surrexit.",
        "glorious-2": "Et Dominus quidem Jesus postquam locutus est eis, assumptus est in cælum, et sedet a dextris Dei.",
        "glorious-3": "Et apparuerunt illis dispertitæ linguæ tamquam ignis, seditque supra singulos eorum: et repleti sunt omnes Spiritu Sancto, et cœperunt loqui variis linguis, prout Spiritus Sanctus dabat eloqui illis.",
        "glorious-4": "Ecce enim ex hoc beatam me dicent omnes generationes, quia fecit mihi magna qui potens est: et sanctum nomen ejus.",
        "glorious-5": "Et signum magnum apparuit in cælo: mulier amicta sole, et luna sub pedibus ejus, et in capite ejus corona stellarum duodecim.",
    ]
}
