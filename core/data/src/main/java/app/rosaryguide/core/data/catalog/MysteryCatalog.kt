package app.rosaryguide.core.data.catalog

import app.rosaryguide.core.model.BilingualText
import app.rosaryguide.core.model.BibleTranslation
import app.rosaryguide.core.model.Mystery
import app.rosaryguide.core.model.MysterySetKind

/**
 * The twenty mysteries, ported as-is from iOS `MysteryCatalog` / `MysteryScripture`.
 */
object MysteryCatalog {
    val all: List<Mystery> = listOf(
        Mystery(
            id = "joyful-1",
            set = MysterySetKind.Joyful,
            number = 1,
            title = BilingualText("The Annunciation", "Annuntiatio"),
            fruit = BilingualText("Humility", "Humilitas"),
            scriptureReference = "Luke 1:26-27",
            scriptureExcerpt = BilingualText("Now in the sixth month, the angel Gabriel was sent from God to a city of Galilee named Nazareth, to a virgin pledged to be married to a man whose name was Joseph, of David’s house. The virgin’s name was Mary.", "In mense autem sexto, missus est angelus Gabriel a Deo in civitatem Galilææ, cui nomen Nazareth, ad virginem desponsatam viro, cui nomen erat Joseph, de domo David: et nomen virginis Maria."),
            artSlug = "01-annunciation",
            summary = "Mary says yes to God.",
        ),
        Mystery(
            id = "joyful-2",
            set = MysterySetKind.Joyful,
            number = 2,
            title = BilingualText("The Visitation", "Visitatio"),
            fruit = BilingualText("Love of Neighbor", "Caritas erga proximum"),
            scriptureReference = "Luke 1:41-42",
            scriptureExcerpt = BilingualText("When Elizabeth heard Mary’s greeting, the baby leaped in her womb; and Elizabeth was filled with the Holy Spirit. She called out with a loud voice and said, “Blessed are you among women, and blessed is the fruit of your womb!”", "Et factum est, ut audivit salutationem Mariæ Elisabeth, exsultavit infans in utero ejus: et repleta est Spiritu Sancto Elisabeth: et exclamavit voce magna, et dixit: Benedicta tu inter mulieres, et benedictus fructus ventris tui."),
            artSlug = "02-visitation",
            summary = "Mary visits Elizabeth.",
        ),
        Mystery(
            id = "joyful-3",
            set = MysterySetKind.Joyful,
            number = 3,
            title = BilingualText("The Nativity", "Nativitas"),
            fruit = BilingualText("Poverty", "Paupertas"),
            scriptureReference = "Luke 2:7",
            scriptureExcerpt = BilingualText("She gave birth to her firstborn son. She wrapped him in bands of cloth and laid him in a feeding trough, because there was no room for them in the inn.", "Et peperit filium suum primogenitum, et pannis eum involvit, et reclinavit eum in præsepio: quia non erat eis locus in diversorio."),
            artSlug = "03-birth-of-jesus",
            summary = "Jesus is born in Bethlehem.",
        ),
        Mystery(
            id = "joyful-4",
            set = MysterySetKind.Joyful,
            number = 4,
            title = BilingualText("The Presentation in the Temple", "Praesentatio"),
            fruit = BilingualText("Purity of Heart and Body", "Puritas cordis et corporis"),
            scriptureReference = "Luke 2:22",
            scriptureExcerpt = BilingualText("When the days of their purification according to the law of Moses were fulfilled, they brought him up to Jerusalem to present him to the Lord…", "Et postquam impleti sunt dies purgationis ejus secundum legem Moysi, tulerunt illum in Jerusalem, ut sisterent eum Domino."),
            artSlug = "04-presentation-of-the-baby-jesus",
            summary = "Jesus is presented in the Temple.",
        ),
        Mystery(
            id = "joyful-5",
            set = MysterySetKind.Joyful,
            number = 5,
            title = BilingualText("The Finding in the Temple", "Inventio in Templo"),
            fruit = BilingualText("Devotion to Jesus", "Devotio erga Iesum"),
            scriptureReference = "Luke 2:46",
            scriptureExcerpt = BilingualText("After three days they found him in the temple, sitting in the middle of the teachers, both listening to them and asking them questions.", "Et factum est, post triduum invenerunt illum in templo sedentem in medio doctorum, audientem illos, et interrogantem eos."),
            artSlug = "05-finding-of-the-child-jesus-in-the-temple",
            summary = "Jesus is found in the Temple.",
        ),
        Mystery(
            id = "luminous-1",
            set = MysterySetKind.Luminous,
            number = 1,
            title = BilingualText("The Baptism in the Jordan", "Baptisma in Iordane"),
            fruit = BilingualText("Openness to the Holy Spirit", "Docilitas Spiritui Sancto"),
            scriptureReference = "Matthew 3:16-17",
            scriptureExcerpt = BilingualText("Jesus, when he was baptized, went up directly from the water: and behold, the heavens were opened to him. He saw the Spirit of God descending as a dove, and coming on him. Behold, a voice out of the heavens said, “This is my beloved Son, with whom I am well pleased.”", "Baptizatus autem Jesus, confestim ascendit de aqua, et ecce aperti sunt ei cæli: et vidit Spiritum Dei descendentem sicut columbam, et venientem super se. Et ecce vox de cælis dicens: Hic est Filius meus dilectus, in quo mihi complacui."),
            artSlug = "01-baptism-of-jesus-in-the-jordan",
            summary = "Jesus is baptized in the Jordan.",
        ),
        Mystery(
            id = "luminous-2",
            set = MysterySetKind.Luminous,
            number = 2,
            title = BilingualText("The Wedding at Cana", "Nuptiae in Cana"),
            fruit = BilingualText("To Jesus through Mary", "Ad Iesum per Mariam"),
            scriptureReference = "John 2:3, 5",
            scriptureExcerpt = BilingualText("When the wine ran out, Jesus’ mother said to him, “They have no wine.” … His mother said to the servants, “Whatever he says to you, do it.”", "Et deficiente vino, dicit mater Jesu ad eum: Vinum non habent. Dicit mater ejus ministris: Quodcumque dixerit vobis, facite."),
            artSlug = "02-miracle-at-the-wedding-at-cana",
            summary = "Jesus turns water into wine.",
        ),
        Mystery(
            id = "luminous-3",
            set = MysterySetKind.Luminous,
            number = 3,
            title = BilingualText("The Proclamation of the Kingdom", "Proclamatio Regni"),
            fruit = BilingualText("Conversion", "Conversio"),
            scriptureReference = "Mark 1:15",
            scriptureExcerpt = BilingualText("and saying, “The time is fulfilled, and God’s Kingdom is at hand! Repent, and believe in the Good News.”", "Impletum est tempus, et appropinquavit regnum Dei: pœnitemini, et credite Evangelio."),
            artSlug = "03-proclamation-of-the-kingdom-of-god",
            summary = "Jesus proclaims the Kingdom of God.",
        ),
        Mystery(
            id = "luminous-4",
            set = MysterySetKind.Luminous,
            number = 4,
            title = BilingualText("The Transfiguration", "Transfiguratio"),
            fruit = BilingualText("Desire for holiness", "Desiderium sanctitatis"),
            scriptureReference = "Matthew 17:1-2",
            scriptureExcerpt = BilingualText("After six days, Jesus took with him Peter, James, and John his brother, and brought them up into a high mountain by themselves. He was changed before them. His face shone like the sun, and his garments became as white as the light.", "Et post dies sex assumit Jesus Petrum, et Jacobum, et Joannem fratrem ejus, et ducit illos in montem excelsum seorsum: et transfiguratus est ante eos. Et resplenduit facies ejus sicut sol: vestimenta autem ejus facta sunt alba sicut nix."),
            artSlug = "04-transfiguration",
            summary = "Jesus is transfigured in glory.",
        ),
        Mystery(
            id = "luminous-5",
            set = MysterySetKind.Luminous,
            number = 5,
            title = BilingualText("The Institution of the Eucharist", "Institutio Eucharistiae"),
            fruit = BilingualText("Adoration", "Adoratio"),
            scriptureReference = "Matthew 26:26",
            scriptureExcerpt = BilingualText("As they were eating, Jesus took bread, gave thanks for it, and broke it. He gave to the disciples and said, “Take, eat; this is my body.”", "Cœnantibus autem eis, accepit Jesus panem, et benedixit, ac fregit, deditque discipulis suis, et ait: Accipite, et comedite: hoc est corpus meum."),
            artSlug = "05-institution-of-the-holy-eucharist",
            summary = "Jesus gives us the Eucharist.",
        ),
        Mystery(
            id = "sorrowful-1",
            set = MysterySetKind.Sorrowful,
            number = 1,
            title = BilingualText("The Agony in the Garden", "Agonia in Horto"),
            fruit = BilingualText("Obedience to God’s Will", "Oboedientia voluntati Dei"),
            scriptureReference = "Matthew 26:38-39",
            scriptureExcerpt = BilingualText("Then Jesus said to them, “My soul is exceedingly sorrowful, even to death. Stay here and watch with me.” He went forward a little, fell on his face, and prayed, saying, “My Father, if it is possible, let this cup pass away from me; nevertheless, not what I desire, but what you desire.”", "Tunc ait illis: Tristis est anima mea usque ad mortem: sustinete hic, et vigilate mecum. Et progressus pusillum, procidit in faciem suam, orans, et dicens: Pater mi, si possibile est, transeat a me calix iste: verumtamen non sicut ego volo, sed sicut tu."),
            artSlug = "01-agony-in-the-garden",
            summary = "Jesus prays in Gethsemane.",
        ),
        Mystery(
            id = "sorrowful-2",
            set = MysterySetKind.Sorrowful,
            number = 2,
            title = BilingualText("The Scourging at the Pillar", "Flagellatio"),
            fruit = BilingualText("Mortification", "Mortificatio"),
            scriptureReference = "Matthew 27:26",
            scriptureExcerpt = BilingualText("Then he released Barabbas to them, but Jesus he flogged and delivered to be crucified.", "Tunc dimisit illis Barabbam: Jesum autem flagellatum tradidit eis ut crucifigeretur."),
            artSlug = "02-scourging-at-the-pillar",
            summary = "Jesus is scourged at the pillar.",
        ),
        Mystery(
            id = "sorrowful-3",
            set = MysterySetKind.Sorrowful,
            number = 3,
            title = BilingualText("The Crowning with Thorns", "Coronatio Spinis"),
            fruit = BilingualText("Courage", "Fortitudo"),
            scriptureReference = "Matthew 27:29",
            scriptureExcerpt = BilingualText("They braided a crown of thorns and put it on his head, and a reed in his right hand; and they kneeled down before him and mocked him, saying, “Hail, King of the Jews!”", "Et plectentes coronam de spinis, posuerunt super caput ejus, et arundinem in dextera ejus. Et genu flexo ante eum, illudebant ei, dicentes: Ave rex Judæorum."),
            artSlug = "03-crowning-with-thorns",
            summary = "Jesus is crowned with thorns.",
        ),
        Mystery(
            id = "sorrowful-4",
            set = MysterySetKind.Sorrowful,
            number = 4,
            title = BilingualText("The Carrying of the Cross", "Baiulatio Crucis"),
            fruit = BilingualText("Patience", "Patientia"),
            scriptureReference = "Mark 15:21-22",
            scriptureExcerpt = BilingualText("They compelled one passing by, coming from the country, Simon of Cyrene, the father of Alexander and Rufus, to go with them that he might bear his cross. They brought him to the place called Golgotha, which is, being interpreted, “The place of a skull.”", "Et angariaverunt prætereuntem quempiam, Simonem Cyrenæum venientem de villa, patrem Alexandri et Rufi, ut tolleret crucem ejus. Et perducunt illum in Golgotha locum: quod est interpretatum Calvariæ locus."),
            artSlug = "04-carrying-of-the-cross",
            summary = "Jesus carries his cross.",
        ),
        Mystery(
            id = "sorrowful-5",
            set = MysterySetKind.Sorrowful,
            number = 5,
            title = BilingualText("The Crucifixion", "Crucifixio"),
            fruit = BilingualText("Sorrow for our Sins", "Dolor peccatorum"),
            scriptureReference = "Luke 23:33, 46",
            scriptureExcerpt = BilingualText("When they came to the place that is called “The Skull”, they crucified him there with the criminals, one on the right and the other on the left. … Jesus, crying with a loud voice, said, “Father, into your hands I commit my spirit!” Having said this, he breathed his last.", "Et postquam venerunt in locum qui vocatur Calvariæ, ibi crucifixerunt eum: et latrones, unum a dextris, et alterum a sinistris. Et clamans voce magna Jesus ait: Pater, in manus tuas commendo spiritum meum. Et hæc dicens, expiravit."),
            artSlug = "05-crucifixion",
            summary = "Jesus dies on the cross.",
        ),
        Mystery(
            id = "glorious-1",
            set = MysterySetKind.Glorious,
            number = 1,
            title = BilingualText("The Resurrection", "Resurrectio"),
            fruit = BilingualText("Faith", "Fides"),
            scriptureReference = "Luke 24:5-6",
            scriptureExcerpt = BilingualText("Why do you seek the living among the dead? He isn’t here, but is risen.", "Quid quæritis viventem cum mortuis? Non est hic, sed surrexit."),
            artSlug = "01-resurrection",
            summary = "Jesus rises from the dead.",
        ),
        Mystery(
            id = "glorious-2",
            set = MysterySetKind.Glorious,
            number = 2,
            title = BilingualText("The Ascension", "Ascensio"),
            fruit = BilingualText("Hope", "Spes"),
            scriptureReference = "Mark 16:19",
            scriptureExcerpt = BilingualText("So then the Lord, after he had spoken to them, was received up into heaven and sat down at the right hand of God.", "Et Dominus quidem Jesus postquam locutus est eis, assumptus est in cælum, et sedet a dextris Dei."),
            artSlug = "02-ascension",
            summary = "Jesus ascends into heaven.",
        ),
        Mystery(
            id = "glorious-3",
            set = MysterySetKind.Glorious,
            number = 3,
            title = BilingualText("The Descent of the Holy Spirit", "Descensus Spiritus Sancti"),
            fruit = BilingualText("Wisdom", "Sapientia"),
            scriptureReference = "Acts 2:3-4",
            scriptureExcerpt = BilingualText("Tongues like fire appeared and were distributed to them, and one sat on each of them. They were all filled with the Holy Spirit and began to speak with other languages, as the Spirit gave them the ability to speak.", "Et apparuerunt illis dispertitæ linguæ tamquam ignis, seditque supra singulos eorum: et repleti sunt omnes Spiritu Sancto, et cœperunt loqui variis linguis, prout Spiritus Sanctus dabat eloqui illis."),
            artSlug = "03-descent-of-the-holy-spirit",
            summary = "The Holy Spirit comes at Pentecost.",
        ),
        Mystery(
            id = "glorious-4",
            set = MysterySetKind.Glorious,
            number = 4,
            title = BilingualText("The Assumption", "Assumptio"),
            fruit = BilingualText("Devotion to Mary", "Devotio erga Mariam"),
            scriptureReference = "Luke 1:48-49",
            scriptureExcerpt = BilingualText("For behold, from now on, all generations will call me blessed. For he who is mighty has done great things for me. Holy is his name.", "Ecce enim ex hoc beatam me dicent omnes generationes, quia fecit mihi magna qui potens est: et sanctum nomen ejus."),
            artSlug = "04-assumption",
            summary = "Mary is taken up into heaven.",
        ),
        Mystery(
            id = "glorious-5",
            set = MysterySetKind.Glorious,
            number = 5,
            title = BilingualText("The Coronation of Mary", "Coronatio Beatae Mariae Virginis"),
            fruit = BilingualText("Grace of a happy death", "Gratia bonae mortis"),
            scriptureReference = "Revelation 12:1",
            scriptureExcerpt = BilingualText("A great sign was seen in heaven: a woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars.", "Et signum magnum apparuit in cælo: mulier amicta sole, et luna sub pedibus ejus, et in capite ejus corona stellarum duodecim."),
            artSlug = "05-coronation",
            summary = "Mary is crowned Queen of Heaven.",
        )
    )

    val joyful: List<Mystery> get() = mysteries(MysterySetKind.Joyful)
    val sorrowful: List<Mystery> get() = mysteries(MysterySetKind.Sorrowful)
    val glorious: List<Mystery> get() = mysteries(MysterySetKind.Glorious)
    val luminous: List<Mystery> get() = mysteries(MysterySetKind.Luminous)

    fun mysteries(set: MysterySetKind): List<Mystery> =
        all.filter { it.set == set }.sortedBy { it.number }
}

object MysteryScripture {
    val douayRheims: Map<String, String> = mapOf(
        "joyful-1" to "And in the sixth month, the angel Gabriel was sent from God into a city of Galilee, called Nazareth, to a virgin espoused to a man whose name was Joseph, of the house of David; and the virgin’s name was Mary.",
        "joyful-2" to "And it came to pass, that when Elizabeth heard the salutation of Mary, the infant leaped in her womb. And Elizabeth was filled with the Holy Ghost: and she cried out with a loud voice, and said: Blessed art thou among women, and blessed is the fruit of thy womb.",
        "joyful-3" to "And she brought forth her firstborn son, and wrapped him up in swaddling clothes, and laid him in a manger; because there was no room for them in the inn.",
        "joyful-4" to "And after the days of her purification, according to the law of Moses, were accomplished, they carried him to Jerusalem, to present him to the Lord.",
        "joyful-5" to "And it came to pass, that, after three days, they found him in the temple, sitting in the midst of the doctors, hearing them, and asking them questions.",
        "luminous-1" to "And Jesus being baptized, forthwith came out of the water: and lo, the heavens were opened to him: and he saw the Spirit of God descending as a dove, and coming upon him. And behold a voice from heaven, saying: This is my beloved Son, in whom I am well pleased.",
        "luminous-2" to "And the wine failing, the mother of Jesus saith to him: They have no wine. His mother saith to the waiters: Whatsoever he shall say to you, do ye.",
        "luminous-3" to "The time is accomplished, and the kingdom of God is at hand: repent, and believe the gospel.",
        "luminous-4" to "And after six days Jesus taketh unto him Peter and James, and John his brother, and bringeth them up into a high mountain apart: and he was transfigured before them. And his face did shine as the sun: and his garments became white as snow.",
        "luminous-5" to "And whilst they were at supper, Jesus took bread, and blessed, and broke: and gave to his disciples, and said: Take ye, and eat. This is my body.",
        "sorrowful-1" to "Then he saith to them: My soul is sorrowful even unto death: stay you here, and watch with me. And going a little further, he fell upon his face, praying, and saying: My Father, if it be possible, let this chalice pass from me. Nevertheless not as I will, but as thou wilt.",
        "sorrowful-2" to "Then he released to them Barabbas, and having scourged Jesus, delivered him unto them to be crucified.",
        "sorrowful-3" to "And platting a crown of thorns, they put it upon his head, and a reed in his right hand. And bowing the knee before him, they mocked him, saying: Hail, king of the Jews.",
        "sorrowful-4" to "And they forced one Simon a Cyrenian who passed by, coming out of the country, the father of Alexander and of Rufus, to take up his cross. And they bring him into the place called Golgotha, which being interpreted is, The place of Calvary.",
        "sorrowful-5" to "And when they were come to the place which is called Calvary, they crucified him there; and the robbers, one on the right hand, and the other on the left. And Jesus crying out with a loud voice, said: Father, into thy hands I commend my spirit. And saying this, he gave up the ghost.",
        "glorious-1" to "Why seek you the living with the dead? He is not here, but is risen.",
        "glorious-2" to "And the Lord Jesus, after he had spoken to them, was taken up into heaven, and sitteth on the right hand of God.",
        "glorious-3" to "And there appeared to them parted tongues as it were of fire, and it sat upon every one of them: and they were all filled with the Holy Ghost, and they began to speak with divers tongues, according as the Holy Ghost gave them to speak.",
        "glorious-4" to "For behold from henceforth all generations shall call me blessed. Because he that is mighty, hath done great things to me; and holy is his name.",
        "glorious-5" to "And a great sign appeared in heaven: A woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars."
    )

    val vulgate: Map<String, String> = mapOf(
        "joyful-1" to "In mense autem sexto, missus est angelus Gabriel a Deo in civitatem Galilææ, cui nomen Nazareth, ad virginem desponsatam viro, cui nomen erat Joseph, de domo David: et nomen virginis Maria.",
        "joyful-2" to "Et factum est, ut audivit salutationem Mariæ Elisabeth, exsultavit infans in utero ejus: et repleta est Spiritu Sancto Elisabeth: et exclamavit voce magna, et dixit: Benedicta tu inter mulieres, et benedictus fructus ventris tui.",
        "joyful-3" to "Et peperit filium suum primogenitum, et pannis eum involvit, et reclinavit eum in præsepio: quia non erat eis locus in diversorio.",
        "joyful-4" to "Et postquam impleti sunt dies purgationis ejus secundum legem Moysi, tulerunt illum in Jerusalem, ut sisterent eum Domino.",
        "joyful-5" to "Et factum est, post triduum invenerunt illum in templo sedentem in medio doctorum, audientem illos, et interrogantem eos.",
        "luminous-1" to "Baptizatus autem Jesus, confestim ascendit de aqua, et ecce aperti sunt ei cæli: et vidit Spiritum Dei descendentem sicut columbam, et venientem super se. Et ecce vox de cælis dicens: Hic est Filius meus dilectus, in quo mihi complacui.",
        "luminous-2" to "Et deficiente vino, dicit mater Jesu ad eum: Vinum non habent. Dicit mater ejus ministris: Quodcumque dixerit vobis, facite.",
        "luminous-3" to "Impletum est tempus, et appropinquavit regnum Dei: pœnitemini, et credite Evangelio.",
        "luminous-4" to "Et post dies sex assumit Jesus Petrum, et Jacobum, et Joannem fratrem ejus, et ducit illos in montem excelsum seorsum: et transfiguratus est ante eos. Et resplenduit facies ejus sicut sol: vestimenta autem ejus facta sunt alba sicut nix.",
        "luminous-5" to "Cœnantibus autem eis, accepit Jesus panem, et benedixit, ac fregit, deditque discipulis suis, et ait: Accipite, et comedite: hoc est corpus meum.",
        "sorrowful-1" to "Tunc ait illis: Tristis est anima mea usque ad mortem: sustinete hic, et vigilate mecum. Et progressus pusillum, procidit in faciem suam, orans, et dicens: Pater mi, si possibile est, transeat a me calix iste: verumtamen non sicut ego volo, sed sicut tu.",
        "sorrowful-2" to "Tunc dimisit illis Barabbam: Jesum autem flagellatum tradidit eis ut crucifigeretur.",
        "sorrowful-3" to "Et plectentes coronam de spinis, posuerunt super caput ejus, et arundinem in dextera ejus. Et genu flexo ante eum, illudebant ei, dicentes: Ave rex Judæorum.",
        "sorrowful-4" to "Et angariaverunt prætereuntem quempiam, Simonem Cyrenæum venientem de villa, patrem Alexandri et Rufi, ut tolleret crucem ejus. Et perducunt illum in Golgotha locum: quod est interpretatum Calvariæ locus.",
        "sorrowful-5" to "Et postquam venerunt in locum qui vocatur Calvariæ, ibi crucifixerunt eum: et latrones, unum a dextris, et alterum a sinistris. Et clamans voce magna Jesus ait: Pater, in manus tuas commendo spiritum meum. Et hæc dicens, expiravit.",
        "glorious-1" to "Quid quæritis viventem cum mortuis? Non est hic, sed surrexit.",
        "glorious-2" to "Et Dominus quidem Jesus postquam locutus est eis, assumptus est in cælum, et sedet a dextris Dei.",
        "glorious-3" to "Et apparuerunt illis dispertitæ linguæ tamquam ignis, seditque supra singulos eorum: et repleti sunt omnes Spiritu Sancto, et cœperunt loqui variis linguis, prout Spiritus Sanctus dabat eloqui illis.",
        "glorious-4" to "Ecce enim ex hoc beatam me dicent omnes generationes, quia fecit mihi magna qui potens est: et sanctum nomen ejus.",
        "glorious-5" to "Et signum magnum apparuit in cælo: mulier amicta sole, et luna sub pedibus ejus, et in capite ejus corona stellarum duodecim."
    )

    fun excerpt(mystery: Mystery, translation: BibleTranslation): String {
        return when (translation) {
            BibleTranslation.WebCatholic -> mystery.scriptureExcerpt.english
            BibleTranslation.DouayRheims -> douayRheims.getValue(mystery.id)
            BibleTranslation.Vulgate -> vulgate.getValue(mystery.id)
        }
    }
}
