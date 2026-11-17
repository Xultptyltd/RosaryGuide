package app.rosaryguide.core.data.catalog

import app.rosaryguide.core.model.BilingualText
import app.rosaryguide.core.model.Prayer
import app.rosaryguide.core.model.RosaryStepKind

/**
 * Prayer texts ported as-is from iOS `PrayerCatalog`.
 */
object PrayerCatalog {
    val all: List<Prayer> = listOf(
        Prayer(
            id = "sign-of-the-cross",
            title = BilingualText("Sign of the Cross", "Signum Crucis"),
            text = BilingualText("In the name of the Father, and of the Son, and of the Holy Spirit. Amen.", "In nomine Patris, et Filii, et Spiritus Sancti. Amen."),
        ),
        Prayer(
            id = "apostles-creed",
            title = BilingualText("Apostles' Creed", "Symbolum Apostolorum"),
            text = BilingualText("I believe in God, the Father almighty, Creator of heaven and earth, and in Jesus Christ, his only Son, our Lord,\n\nwho was conceived by the Holy Spirit, born of the Virgin Mary, suffered under Pontius Pilate, was crucified, died and was buried; he descended into hell; on the third day he rose again from the dead; he ascended into heaven, and is seated at the right hand of God the Father almighty; from there he will come to judge the living and the dead.\n\nI believe in the Holy Spirit, the holy catholic Church, the communion of saints, the forgiveness of sins, the resurrection of the body, and life everlasting. Amen.\n", "Credo in Deum Patrem omnipotentem, Creatorem caeli et terrae. Et in Iesum Christum, Filium eius unicum, Dominum nostrum,\n\nqui conceptus est de Spiritu Sancto, natus ex Maria Virgine, passus sub Pontio Pilato, crucifixus, mortuus, et sepultus; descendit ad inferos; tertia die resurrexit a mortuis; ascendit ad caelos, sedet ad dexteram Dei Patris omnipotentis; inde venturus est iudicare vivos et mortuos.\n\nCredo in Spiritum Sanctum, sanctam Ecclesiam catholicam, sanctorum communionem, remissionem peccatorum, carnis resurrectionem, vitam aeternam. Amen.\n"),
        ),
        Prayer(
            id = "our-father",
            title = BilingualText("Our Father", "Pater Noster"),
            text = BilingualText("Our Father, who art in heaven, hallowed be thy name; thy kingdom come; thy will be done on earth as it is in heaven.\n\nGive us this day our daily bread; and forgive us our trespasses as we forgive those who trespass against us; and lead us not into temptation, but deliver us from evil. Amen.\n", "Pater noster, qui es in caelis, sanctificetur nomen tuum. Adveniat regnum tuum. Fiat voluntas tua, sicut in caelo, et in terra.\n\nPanem nostrum cotidianum da nobis hodie, et dimitte nobis debita nostra, sicut et nos dimittimus debitoribus nostris. Et ne nos inducas in tentationem, sed libera nos a malo. Amen.\n"),
        ),
        Prayer(
            id = "hail-mary",
            title = BilingualText("Hail Mary", "Ave Maria"),
            text = BilingualText("Hail Mary, full of grace, the Lord is with thee; blessed art thou among women, and blessed is the fruit of thy womb, Jesus.\n\nHoly Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.\n", "Ave Maria, gratia plena, Dominus tecum. Benedicta tu in mulieribus, et benedictus fructus ventris tui, Iesus.\n\nSancta Maria, Mater Dei, ora pro nobis peccatoribus, nunc et in hora mortis nostrae. Amen.\n"),
        ),
        Prayer(
            id = "glory-be",
            title = BilingualText("Glory be", "Gloria Patri"),
            text = BilingualText("Glory be to the Father, and to the Son, and to the Holy Spirit.\n\nAs it was in the beginning, is now, and ever shall be, world without end. Amen.\n", "Gloria Patri, et Filio, et Spiritui Sancto.\n\nSicut erat in principio, et nunc, et semper, et in saecula saeculorum. Amen.\n"),
        ),
        Prayer(
            id = "fatima",
            title = BilingualText("Fatima prayer", "O mi Iesu"),
            text = BilingualText("O my Jesus, forgive us our sins, save us from the fires of hell; lead all souls to Heaven, especially those who have most need of your mercy. Amen.", "O mi Iesu, dimitte nobis peccata nostra, libera nos ab igne inferni, perduc omnes animas in caelum, praesertim maxime indigentes misericordia tua. Amen."),
        ),
        Prayer(
            id = "hail-holy-queen",
            title = BilingualText("Hail, holy Queen", "Salve Regina"),
            text = BilingualText("Hail, Holy Queen, Mother of Mercy, our life, our sweetness and our hope. To thee do we cry, poor banished children of Eve. To thee do we send up our sighs, mourning and weeping in this valley of tears.\n\nTurn then, most gracious advocate, thine eyes of mercy toward us, and after this our exile, show unto us the blessed fruit of thy womb, Jesus.\n\nO clement, O loving, O sweet Virgin Mary.\n", "Salve, Regina, mater misericordiae, vita, dulcedo, et spes nostra, salve. Ad te clamamus, exsules filii Hevae. Ad te suspiramus, gementes et flentes in hac lacrimarum valle.\n\nEia ergo, advocata nostra, illos tuos misericordes oculos ad nos converte. Et Iesum, benedictum fructum ventris tui, nobis post hoc exsilium ostende.\n\nO clemens, o pia, o dulcis Virgo Maria.\n"),
        ),
        Prayer(
            id = "versicle",
            title = BilingualText("The versicle", "Versiculum"),
            text = BilingualText("V. Pray for us, O holy Mother of God.\nR. That we may be made worthy of the promises of Christ.\n", "V. Ora pro nobis, sancta Dei Genetrix.\nR. Ut digni efficiamur promissionibus Christi.\n"),
        ),
        Prayer(
            id = "concluding",
            title = BilingualText("Closing prayer", "Oratio"),
            text = BilingualText("O God, whose Only Begotten Son, by his life, Death, and Resurrection, has purchased for us the rewards of eternal life, grant, we beseech thee, that while meditating on these mysteries of the most holy Rosary of the Blessed Virgin Mary, we may imitate what they contain and obtain what they promise, through the same Christ our Lord. Amen.", "Deus, cuius Unigenitus per vitam, mortem et resurrectionem suam nobis salutis aeternae praemia comparavit: concede, quaesumus, ut haec mysteria sacratissimi Rosarii beatae Mariae Virginis recolentes, et imitemur quod continent, et quod promittunt assequamur. Per eundem Christum Dominum nostrum. Amen."),
        ),
        Prayer(
            id = "memorare",
            title = BilingualText("Memorare", "Memorare"),
            text = BilingualText("Remember, O most gracious Virgin Mary, that never was it known that anyone who fled to thy protection, implored thy help, or sought thy intercession, was left unaided. Inspired by this confidence, I fly unto thee, O Virgin of virgins, my Mother. To thee do I come, before thee I stand, sinful and sorrowful. O Mother of the Word Incarnate, despise not my petitions, but in thy mercy hear and answer me. Amen.", "Memoráre, o piíssima Virgo María, non esse audítum a sǽculo, quemquam ad tua curréntem præsídia, tua implorántem auxília, tua peténtem suffrágia, esse derelíctum. Ego tali animátus confidéntia, ad te, Virgo Vírginum, Mater, curro, ad te vénio, coram te gemens peccátor assísto. Noli, Mater Verbi, verba mea despícere; sed audi propítia et exáudi. Amen."),
        ),
        Prayer(
            id = "saint-michael",
            title = BilingualText("Saint Michael the Archangel", "Sancte Michael Archangele"),
            text = BilingualText("Saint Michael the Archangel, defend us in battle. Be our protection against the wickedness and snares of the devil.\n\nMay God rebuke him, we humbly pray; and do thou, O Prince of the heavenly host, by the power of God, cast into hell Satan and all the evil spirits who prowl about the world seeking the ruin of souls. Amen.\n", "Sancte Michael Archangele, defende nos in proelio; contra nequitiam et insidias diaboli esto praesidium.\n\nImperet illi Deus, supplices deprecamur: tuque, Princeps militiae caelestis, Satanam aliosque spiritus malignos, qui ad perditionem animarum pervagantur in mundo, divina virtute in infernum detrude. Amen.\n"),
        ),
        Prayer(
            id = "sacrament-most-holy",
            title = BilingualText("O Sacrament most holy", "O Sacramentum sanctissimum"),
            text = BilingualText("O Sacrament most holy, O Sacrament divine, all praise and all thanksgiving be every moment thine. Amen.", "O Sacraméntum sanctíssimum, o Sacraméntum divínum, omnis laus et omnis gratiárum áctio sit omni moménto tua. Amen."),
        ),
        Prayer(
            id = "litany-of-loreto",
            title = BilingualText("Litany of the Blessed Virgin Mary", ""),
            text = BilingualText("Lord have mercy.\n\nChrist have mercy.\n\nLord have mercy.\n\nChrist hear us.\n\nChrist graciously hear us.\n\nGod, the Father of heaven, have mercy on us.\n\nGod the Son, Redeemer of the world, have mercy on us.\n\nGod the Holy Spirit, have mercy on us.\n\nHoly Trinity, one God, have mercy on us.\n\nHoly Mary, pray for us.\n\nHoly Mother of God, pray for us.\n\nHoly Virgin of virgins, pray for us.\n\nMother of Christ, pray for us.\n\nMother of the Church, pray for us.\n\nMother of Mercy, pray for us.\n\nMother of divine grace, pray for us.\n\nMother of Hope, pray for us.\n\nMother most pure, pray for us.\n\nMother most chaste, pray for us.\n\nMother inviolate, pray for us.\n\nMother undefiled, pray for us.\n\nMother most amiable, pray for us.\n\nMother most admirable, pray for us.\n\nMother of good counsel, pray for us.\n\nMother of our Creator, pray for us.\n\nMother of our Saviour, pray for us.\n\nVirgin most prudent, pray for us.\n\nVirgin most venerable, pray for us.\n\nVirgin most renowned, pray for us.\n\nVirgin most powerful, pray for us.\n\nVirgin most merciful, pray for us.\n\nVirgin most faithful, pray for us.\n\nMirror of justice, pray for us.\n\nSeat of wisdom, pray for us.\n\nCause of our joy, pray for us.\n\nSpiritual vessel, pray for us.\n\nVessel of honour, pray for us.\n\nSingular vessel of devotion, pray for us.\n\nMystical rose, pray for us.\n\nTower of David, pray for us.\n\nTower of ivory, pray for us.\n\nHouse of gold, pray for us.\n\nArk of the covenant, pray for us.\n\nGate of heaven, pray for us.\n\nMorning star, pray for us.\n\nHealth of the sick, pray for us.\n\nRefuge of sinners, pray for us.\n\nSolace of Migrants, pray for us.\n\nComfort of the afflicted, pray for us.\n\nHelp of Christians, pray for us.\n\nQueen of Angels, pray for us.\n\nQueen of Patriarchs, pray for us.\n\nQueen of Prophets, pray for us.\n\nQueen of Apostles, pray for us.\n\nQueen of Martyrs, pray for us.\n\nQueen of Confessors, pray for us.\n\nQueen of Virgins, pray for us.\n\nQueen of all Saints, pray for us.\n\nQueen conceived without original sin, pray for us.\n\nQueen assumed into heaven, pray for us.\n\nQueen of the most holy Rosary, pray for us.\n\nQueen of families, pray for us.\n\nQueen of peace, pray for us.\n\nLamb of God, who takes away the sins of the world, spare us, O Lord.\n\nLamb of God, who takes away the sins of the world, graciously hear us, O Lord.\n\nLamb of God, who takes away the sins of the world, have mercy on us.\n\nV. Pray for us, O holy Mother of God.\n\nR. That we may be made worthy of the promises of Christ.\n\nLet us pray.\n\nGrant, we beseech thee, O Lord God, that we, your servants, may enjoy perpetual health of mind and body; and by the glorious intercession of the Blessed Mary, ever Virgin, may be delivered from present sorrow, and obtain eternal joy. Through Christ our Lord. Amen.", ""),
        ),
        Prayer(
            id = "anima-christi",
            title = BilingualText("Anima Christi", "Anima Christi"),
            text = BilingualText("Soul of Christ, sanctify me.\n\nBody of Christ, save me.\n\nBlood of Christ, embolden me.\n\nWater from the side of Christ, wash me.\n\nPassion of Christ, strengthen me.\n\nO good Jesus, hear me.\n\nWithin your wounds hide me.\n\nNever permit me to be parted from you.\n\nFrom the evil Enemy defend me.\n\nAt the hour of my death call me\n\nand bid me come to you,\n\nthat with your Saints I may praise you\n\nfor age upon age.\n\nAmen.", "Anima Christi, sanctifica me.\n\nCorpus Christi, salva me.\n\nSanguis Christi, inebria me.\n\nAqua lateris Christi, lava me.\n\nPassio Christi, conforta me.\n\nO bone Iesu, exaudi me.\n\nIntra tua vulnera absconde me.\n\nNe permittas me separari a te.\n\nAb hoste maligno defende me.\n\nIn hora mortis meae voca me.\n\nEt iube me venire ad te,\n\nut cum Sanctis tuis laudem te\n\nin saecula saeculorum. Amen."),
        ),
        Prayer(
            id = "grace-before-meals",
            title = BilingualText("Grace Before Meals", ""),
            text = BilingualText("Bless us, O Lord, and these thy gifts, which we are about to receive from thy bounty through Christ our Lord. Amen.", ""),
        ),
        Prayer(
            id = "grace-after-meals",
            title = BilingualText("Grace After Meals", ""),
            text = BilingualText("We give thee thanks, for all thy benefits, Almighty God, who live and reign for ever. Amen.", ""),
        ),
        Prayer(
            id = "morning-offering",
            title = BilingualText("Morning Offering", ""),
            text = BilingualText("O Jesus, through the Immaculate Heart of Mary, I offer you my prayers, works, joys, and sufferings of this day for all the intentions of your Sacred Heart in union with the Holy Sacrifice of the Mass throughout the world,\n\nfor the salvation of souls, the reparation of sins, the reunion of all Christians, and in particular for the intentions of the Holy Father this month.\n\nAmen.", ""),
        ),
        Prayer(
            id = "act-of-contrition",
            title = BilingualText("Act of Contrition", "Actus contritionis"),
            text = BilingualText("O my God, I am heartily sorry for having offended Thee, and I detest all my sins because of thy just punishments, but most of all because they offend Thee, my God, who art all good and deserving of all my love. I firmly resolve with the help of Thy grace to sin no more and to avoid the near occasion of sin. Amen.", "Deus meus, ex toto corde paenitet me omnium meorum peccatorum, eaque detestor, quia peccando, non solum poenas a te iuste statutas promeritus sum, sed praesertim quia offendi te, summum bonum, ac dignum qui super omnia diligaris. Ideo firmiter propono, adiuvante gratia tua, de cetero me non peccaturum peccandique occasiones proximas fugiturum. Amen."),
        ),
        Prayer(
            id = "guardian-angel",
            title = BilingualText("Guardian Angel Prayer", ""),
            text = BilingualText("Angel of God, my guardian dear,\n\nto whom God’s love commits me here,\n\never this day be at my side,\n\nto light and guard, to rule and guide.\n\nAmen.", ""),
        )
    )

    private val byId: Map<String, Prayer> = all.associateBy { it.id }

    /**
     * Resolves a prayer by id. The retired "angel-of-god" entry aliases to
     * "guardian-angel" so a saved favourite or deep link does not crash.
     */
    fun prayer(id: String): Prayer? = byId[canonicalId(id)]

    fun canonicalId(id: String): String = when (id) {
        "angel-of-god" -> "guardian-angel"
        else -> id
    }

    fun aliases(id: String): List<String> = when (canonicalId(id)) {
        "guardian-angel" -> listOf("Angel of God", "Angele Dei")
        else -> emptyList()
    }

    fun matchesQuery(prayer: Prayer, term: String): Boolean {
        if (term.isBlank()) return true
        if (prayer.title.english.contains(term, ignoreCase = true)) return true
        if (prayer.title.latin.contains(term, ignoreCase = true)) return true
        return aliases(prayer.id).any { it.contains(term, ignoreCase = true) }
    }

    val signOfTheCross: Prayer get() = byId.getValue("sign-of-the-cross")
    val apostlesCreed: Prayer get() = byId.getValue("apostles-creed")
    val ourFather: Prayer get() = byId.getValue("our-father")
    val hailMary: Prayer get() = byId.getValue("hail-mary")
    val gloryBe: Prayer get() = byId.getValue("glory-be")
    val fatima: Prayer get() = byId.getValue("fatima")
    val hailHolyQueen: Prayer get() = byId.getValue("hail-holy-queen")
    val versicle: Prayer get() = byId.getValue("versicle")
    val concluding: Prayer get() = byId.getValue("concluding")
    val memorare: Prayer get() = byId.getValue("memorare")
    val saintMichael: Prayer get() = byId.getValue("saint-michael")
    val sacramentMostHoly: Prayer get() = byId.getValue("sacrament-most-holy")

    val openingIntentions: List<BilingualText> = listOf(
        BilingualText("For an increase in faith", "Ad fidei incrementum"),
        BilingualText("For an increase in hope", "Ad spei incrementum"),
        BilingualText("For an increase in charity", "Ad caritatis incrementum")
    )

    fun prayer(kind: RosaryStepKind): Prayer? = when (kind) {
        RosaryStepKind.SignOfTheCross -> signOfTheCross
        RosaryStepKind.Creed -> apostlesCreed
        RosaryStepKind.OurFather -> ourFather
        RosaryStepKind.HailMary -> hailMary
        RosaryStepKind.GloryBe -> gloryBe
        RosaryStepKind.Fatima -> fatima
        RosaryStepKind.HailHolyQueen -> hailHolyQueen
        RosaryStepKind.Versicle -> versicle
        RosaryStepKind.ConcludingPrayer -> concluding
        RosaryStepKind.SaintMichael -> saintMichael
        RosaryStepKind.OSacrament -> sacramentMostHoly
        RosaryStepKind.Memorare -> memorare
        RosaryStepKind.MysteryAnnouncement, RosaryStepKind.Completion -> null
    }
}
