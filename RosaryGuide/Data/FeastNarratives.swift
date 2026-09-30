import Foundation

/// Day-specific feast copy: About, History, optional Indulgence, related prayers.
/// Indulgence notes are included only where the Church’s grant is well established;
/// never invent. Prefer PrayerCatalog texts when a related prayer matches.
struct FeastRelatedPrayer: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var english: String
    var latin: String?
    /// Short liturgical note (e.g. Angelus vs Regina Caeli by season).
    var note: String?
}

struct FeastNarrative: Hashable, Sendable {
    var about: String
    var history: String
    var indulgence: String?
    var relatedPrayers: [FeastRelatedPrayer]
}

enum FeastNarratives {
    static func narrative(for id: String) -> FeastNarrative? {
        table[id]
    }

    static var coveredIds: Set<String> { Set(table.keys) }

    // MARK: - Shared prayer snippets (aligned with PrayerCatalog where applicable)

    private static let hailHolyQueen = FeastRelatedPrayer(
        id: "hail-holy-queen",
        title: PrayerCatalog.hailHolyQueen.title.english,
        english: PrayerCatalog.hailHolyQueen.text.english,
        latin: PrayerCatalog.hailHolyQueen.text.latin
    )

    private static let fatimaPrayer = FeastRelatedPrayer(
        id: "fatima",
        title: PrayerCatalog.fatima.title.english,
        english: PrayerCatalog.fatima.text.english,
        latin: PrayerCatalog.fatima.text.latin
    )

    private static let saintMichael = FeastRelatedPrayer(
        id: "saint-michael",
        title: PrayerCatalog.saintMichael.title.english,
        english: PrayerCatalog.saintMichael.text.english,
        latin: PrayerCatalog.saintMichael.text.latin
    )

    private static let memorare = FeastRelatedPrayer(
        id: "memorare",
        title: "Memorare",
        english: """
        Remember, O most gracious Virgin Mary, that never was it known that anyone who fled to thy protection, implored thy help, or sought thy intercession, was left unaided. Inspired by this confidence, I fly unto thee, O Virgin of virgins, my Mother. To thee do I come, before thee I stand, sinful and sorrowful. O Mother of the Word Incarnate, despise not my petitions, but in thy mercy hear and answer me. Amen.
        """,
        latin: """
        Memoráre, o piíssima Virgo María, non esse audítum a sǽculo, quemquam ad tua curréntem præsídia, tua implorántem auxília, tua peténtem suffrágia, esse derelíctum. Ego tali animátus confidéntia, ad te, Virgo Vírginum, Mater, curro, ad te vénio, coram te gemens peccátor assísto. Noli, Mater Verbi, verba mea despícere; sed audi propítia et exáudi. Amen.
        """
    )

    private static let angelus = FeastRelatedPrayer(
        id: "angelus",
        title: "The Angelus",
        english: """
        V. The Angel of the Lord declared unto Mary.
        R. And she conceived of the Holy Spirit.
        Hail Mary…

        V. Behold the handmaid of the Lord.
        R. Be it done unto me according to thy word.
        Hail Mary…

        V. And the Word was made flesh.
        R. And dwelt among us.
        Hail Mary…

        V. Pray for us, O holy Mother of God.
        R. That we may be made worthy of the promises of Christ.

        Let us pray. Pour forth, we beseech thee, O Lord, thy grace into our hearts, that we, to whom the Incarnation of Christ thy Son was made known by the message of an angel, may by his Passion and Cross be brought to the glory of his Resurrection. Through the same Christ our Lord. Amen.
        """,
        latin: nil,
        note: "Customary outside Easter Time. From Easter to Pentecost Saturday, the Church prays the Regina Caeli instead."
    )

    private static let reginaCaeli = FeastRelatedPrayer(
        id: "regina-caeli",
        title: "Regina Caeli",
        english: """
        Queen of Heaven, rejoice, alleluia.
        For He whom you did merit to bear, alleluia.
        Has risen, as He said, alleluia.
        Pray for us to God, alleluia.

        V. Rejoice and be glad, O Virgin Mary, alleluia.
        R. For the Lord has truly risen, alleluia.

        Let us pray. O God, who gave joy to the world through the resurrection of thy Son, our Lord Jesus Christ, grant, we beseech thee, that through the intercession of the Virgin Mary, his Mother, we may obtain the joys of everlasting life. Through the same Christ our Lord. Amen.
        """,
        latin: """
        Regína cæli, lætáre, allelúia.
        Quia quem meruísti portáre, allelúia.
        Resurréxit, sicut dixit, allelúia.
        Ora pro nobis Deum, allelúia.
        """,
        note: "Prayed in place of the Angelus during Easter Time."
    )

    private static let stJoseph = FeastRelatedPrayer(
        id: "st-joseph",
        title: "Prayer to Saint Joseph",
        english: """
        To you, O blessed Joseph, do we come in our afflictions, and having implored the help of your most holy Spouse, we confidently invoke your patronage also. Through that charity which bound you to the Immaculate Virgin Mother of God and through the paternal love with which you embraced the Child Jesus, we humbly beg you to regard kindly the inheritance which Jesus Christ has purchased by his Blood, and with your power and strength to aid us in our necessities.

        O most watchful guardian of the Holy Family, defend the chosen children of Jesus Christ; O most loving father, ward off from us every contagion of error and corrupting influence; O our most mighty protector, be kind to us and from heaven assist us in our struggle with the power of darkness.

        As once you rescued the Child Jesus from deadly peril, so now protect God's Holy Church from the snares of the enemy and from all adversity; shield, each one of us, by your constant protection, so that, supported by your example and your aid, we may be able to live piously, to die in holiness, and to obtain eternal happiness in heaven. Amen.
        """,
        latin: nil
    )

    private static let animaChristi = FeastRelatedPrayer(
        id: "anima-christi",
        title: "Anima Christi",
        english: """
        Soul of Christ, sanctify me. Body of Christ, save me. Blood of Christ, inebriate me. Water from the side of Christ, wash me. Passion of Christ, strengthen me. O good Jesus, hear me. Within thy wounds hide me. Separated from thee let me never be. From the malicious enemy defend me. In the hour of my death call me. And bid me come unto thee, that with thy saints I may praise thee forever and ever. Amen.
        """,
        latin: """
        Ánima Christi, sanctífica me. Corpus Christi, salva me. Sanguis Christi, inébria me. Aqua láteris Christi, lava me. Pássio Christi, confórta me. O bone Iesu, exáudi me. Intra tua vúlnera abscónde me. Ne permíttas me separári a te. Ab hoste malígno defénde me. In hora mortis meæ voca me. Et iube me veníre ad te, ut cum Sanctis tuis laudem te in sǽcula sæculórum. Amen.
        """
    )

    private static let comeHolySpirit = FeastRelatedPrayer(
        id: "come-holy-spirit",
        title: "Come, Holy Spirit",
        english: """
        Come, Holy Spirit, fill the hearts of your faithful and kindle in them the fire of your love. Send forth your Spirit and they shall be created, and you shall renew the face of the earth.

        O God, who have taught the hearts of the faithful by the light of the Holy Spirit, grant that in the same Spirit we may be truly wise and ever rejoice in his consolation. Through Christ our Lord. Amen.
        """,
        latin: nil
    )

    private static let divineMercy = FeastRelatedPrayer(
        id: "divine-mercy",
        title: "Divine Mercy Chaplet (opening)",
        english: """
        You expired, Jesus, but the source of life gushed forth for souls, and the ocean of mercy opened up for the whole world. O Fount of Life, unfathomable Divine Mercy, envelop the whole world and empty Yourself out upon us.

        O Blood and Water, which gushed forth from the Heart of Jesus as a fountain of Mercy for us, I trust in You.
        """,
        latin: nil,
        note: "The chaplet is prayed on ordinary Rosary beads. On Divine Mercy Sunday many also pray before the image of the Merciful Jesus."
    )

    private static let eternalRest = FeastRelatedPrayer(
        id: "eternal-rest",
        title: "Eternal Rest",
        english: "Eternal rest grant unto them, O Lord, and let perpetual light shine upon them. May they rest in peace. Amen.",
        latin: "Réquiem ætérnam dona eis, Dómine, et lux perpétua lúceat eis. Requiéscant in pace. Amen."
    )

    private static let magnificatShort = FeastRelatedPrayer(
        id: "magnificat",
        title: "The Magnificat",
        english: """
        My soul proclaims the greatness of the Lord, my spirit rejoices in God my Savior, for he has looked with favor on his lowly servant. From this day all generations will call me blessed: the Almighty has done great things for me, and holy is his Name. He has mercy on those who fear him in every generation. He has shown the strength of his arm, he has scattered the proud in their conceit. He has cast down the mighty from their thrones, and has lifted up the lowly. He has filled the hungry with good things, and the rich he has sent away empty. He has come to the help of his servant Israel for he has remembered his promise of mercy, the promise he made to our fathers, to Abraham and his children forever. Glory to the Father…
        """,
        latin: nil
    )

    private static let subTuum = FeastRelatedPrayer(
        id: "sub-tuum",
        title: "Sub Tuum Præsidium",
        english: "We fly to thy protection, O holy Mother of God; despise not our petitions in our necessities, but deliver us always from all dangers, O glorious and blessed Virgin.",
        latin: "Sub tuum præsídium confúgimus, sancta Dei Génitrix; nostras deprecatiónes ne despícias in necessitátibus, sed a perículis cunctis líbera nos semper, Virgo gloriósa et benedícta."
    )


    private static let angelOfGod = FeastRelatedPrayer(
        id: "angel-of-god",
        title: PrayerCatalog.angelOfGod.title.english,
        english: PrayerCatalog.angelOfGod.text.english,
        latin: PrayerCatalog.angelOfGod.text.latin
    )

    private static let gloryBe = FeastRelatedPrayer(
        id: "glory-be",
        title: PrayerCatalog.gloryBe.title.english,
        english: PrayerCatalog.gloryBe.text.english,
        latin: PrayerCatalog.gloryBe.text.latin
    )

    private static let apostlesCreed = FeastRelatedPrayer(
        id: "apostles-creed",
        title: PrayerCatalog.apostlesCreed.title.english,
        english: PrayerCatalog.apostlesCreed.text.english,
        latin: PrayerCatalog.apostlesCreed.text.latin
    )

    private static let ourFather = FeastRelatedPrayer(
        id: "our-father",
        title: PrayerCatalog.ourFather.title.english,
        english: PrayerCatalog.ourFather.text.english,
        latin: PrayerCatalog.ourFather.text.latin
    )

    private static let flosCarmeli = FeastRelatedPrayer(
        id: "flos-carmeli",
        title: "Flos Carmeli",
        english: """
        Flower of Carmel, tall vine blossom laden; splendor of heaven, childless and maiden. None equals thee.

        Mother so tender, who all men befriendest, make for us mercy, and strength thou dost sendest. Let it avail us.

        Star of the Sea.
        """,
        latin: """
        Flos Carméli, vitis florigera, splendor cæli, virgo puérpera, singularis.

        Mater mitis, sed viri nescia, Carmélitis esto propitia, stella maris.
        """,
        note: "Traditional Carmelite prayer associated with Our Lady of Mount Carmel."
    )

    private static let stabatMater = FeastRelatedPrayer(
        id: "stabat-mater",
        title: "Stabat Mater",
        english: """
        At the Cross her station keeping, stood the mournful Mother weeping, close to Jesus to the last.

        Through her heart, his sorrow sharing, all his bitter anguish bearing, now at length the sword has passed.

        O how sad and sore distressed was that Mother highly blest of the sole-begotten One.

        Christ above in torment hangs; she beneath beholds the pangs of her dying glorious Son.

        Is there one who would not weep, whelmed in miseries so deep, Christ's dear Mother to behold?

        Can the human heart refrain from partaking in her pain, in that Mother's pain untold?

        Holy Mother, pierce me through; in my heart each wound renew of my Savior crucified.

        Let me share with thee his pain, who for all my sins was slain, who for me in torments died.

        Christ, when thou shalt call me hence, be thy Mother my defense, be thy Cross my victory.
        """,
        latin: """
        Stabat Mater dolorósa iuxta Crucem lacrimósa, dum pendébat Fílius.

        Cuius ánimam geméntem, contristátam et doléntem pertransívit gládius.

        O quam tristis et afflícta fuit illa benedícta Mater Unigéniti!
        """,
        note: "Traditional sequence for Our Lady of Sorrows; English is the classic Caswall translation (public domain)."
    )

    // MARK: - Catalog

    private static let table: [String: FeastNarrative] = [
        "mary-mother-of-god": FeastNarrative(
            about: """
        On the octave of Christmas the Church honors Mary under her greatest title: Mother of God (Theotokos). We keep this day so that Christmas does not fade into sentiment alone—Christ is truly God, and Mary is truly his Mother—and so that her maternal care for the Church stands at the threshold of the year.
        
        For the faithful the solemnity is an invitation to entrust the year to her who first received the Word. By contemplating her motherhood we learn to receive Christ ourselves, to guard what is holy, and to begin again in peace. It is also the World Day of Peace: Mary’s yes opens a path of reconciliation for the world.
        """,
            history: "The Council of Ephesus (431) defended the title Theotokos against those who would separate Christ’s natures. In the Roman calendar the solemnity falls on 1 January, the Octave of the Nativity, binding the mystery of the Incarnation to Mary’s person and to the Church’s prayer for peace.",
            indulgence: nil,
            relatedPrayers: [subTuum, memorare, hailHolyQueen]
        ),
        "epiphany": FeastNarrative(
            about: """
        Epiphany means manifestation. The Church celebrates Christ revealed to the nations in the Magi, and traditionally also recalls his Baptism and the miracle at Cana—the light of the Gentiles made visible. We keep the feast so that Christmas joy may widen into mission: the Child is not for one people only, but for every seeking heart.
        
        Spiritually, Epiphany asks us to become pilgrims like the Magi—to follow the light we are given, to offer our gifts, and to return home by another way, converted. The day strengthens faith that God still draws strangers, seekers, and the far-off into the brightness of Christ.
        """,
            history: "The feast is ancient in East and West. In the United States it is commonly observed on the Sunday between 2 and 8 January. The Magi’s gifts and journey have long shaped Christian devotion, art, and the blessing of homes at Epiphanytide.",
            indulgence: nil,
            relatedPrayers: [angelus]
        ),
        "baptism-movable": FeastNarrative(
            about: """
        The Baptism of the Lord closes Christmas Time. Jesus enters the Jordan; the Spirit descends; the Father’s voice names him beloved Son. We memorialize this day because here the beloved Son stands among sinners and the first Luminous Mystery shines: the public life of mercy begins.
        
        For us the feast renews baptismal identity. We are reminded that we too are named beloved in Christ, anointed by the Spirit, and sent to live as children of the light. Contemplating this mystery deepens gratitude for the grace of Baptism and courage for Christian life.
        """,
            history: "Celebrated after Epiphany in the Roman calendar, the feast marks the beginning of Christ’s public ministry. It replaced an older octave emphasis and invites the Church to reclaim the dignity and mission of her own baptismal life.",
            indulgence: nil,
            relatedPrayers: [comeHolySpirit]
        ),
        "presentation": FeastNarrative(
            about: """
        Candlemas: Mary and Joseph present the Child in the Temple according to the Law. Simeon and Anna recognize the Light of the nations. We keep this Marian and Christological day—the fourth Joyful Mystery—because the Church must always place Christ in the Father’s house and welcome him as the Light who enlightens every people.
        
        Spiritually the feast teaches offering and hope. Like Mary we present our lives; like Simeon we learn to recognize Christ before we die; like Anna we give thanks. The blessing of candles recalls that the grace of this day is to carry Christ’s light into ordinary darkness.
        """,
            history: "Known in the East as the Meeting (Hypapante), the feast entered the West with candle processions symbolizing Christ the light. It falls forty days after Christmas, completing the Christmas cycle in older reckoning.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare]
        ),
        "lourdes": FeastNarrative(
            about: """
        Our Lady of Lourdes recalls Mary’s appearances to St Bernadette in 1858. Mary named herself the Immaculate Conception and called for prayer and penance. The Church keeps this day—also the World Day of the Sick—so that the suffering may know they are not forgotten, and that Marian devotion remains tied to conversion and trust.
        
        For the sick, caregivers, and all who struggle, Lourdes is a spiritual refuge: Mary’s maternal nearness, the call to pray the Rosary, and hope for healing of body and soul according to God’s will. Pilgrimage and the spring speak of grace that washes, consoles, and restores faith.
        """,
            history: "From a grotto in the Pyrenees, Lourdes became a place of pilgrimage, healing, and Marian devotion. The optional memorial invites the faithful to entrust illness and weakness to Mary’s care under the title she herself confirmed.",
            indulgence: nil,
            relatedPrayers: [memorare, hailHolyQueen, subTuum]
        ),
        "ash-wednesday": FeastNarrative(
            about: """
        Lent begins with ashes and a call to convert: prayer, fasting, and almsgiving. We keep this day because the Church will not approach Easter without truthfulness about sin and mortality—“remember that you are dust”—and without a concrete turn toward God.
        
        Spiritually Ash Wednesday offers the grace of a clean beginning. The mark on the forehead is not despair but mercy’s invitation: to walk the Sorrowful Mysteries with Christ, to loosen what binds us, and to prepare the heart for the Cross and the empty tomb.
        """,
            history: "Ashes have marked Christian repentance for centuries. The day opens the forty days that prepare the Church for the Paschal Triduum and Easter, shaping a season of discipline ordered to joy.",
            indulgence: nil,
            relatedPrayers: [animaChristi, fatimaPrayer]
        ),
        "joseph": FeastNarrative(
            about: """
        Saint Joseph, spouse of the Blessed Virgin and guardian of the Redeemer, is patron of the universal Church. We celebrate him because the hidden justice of his life—silence, obedience, and protective love—belongs at the center of the Gospel household, not at its margins.
        
        For families, workers, and the anxious, Joseph is a spiritual father: he teaches trust when plans change, courage in danger, and fidelity in ordinary work. Entrusting homes and the Church to him asks for the grace of steadfast care and a quiet heart before God’s will.
        """,
            history: "Devotion to Joseph grew strongly in the late Middle Ages and modern era. His solemnity on 19 March honors him as husband of Mary; a separate memorial on 1 May honors Joseph the Worker.",
            indulgence: nil,
            relatedPrayers: [stJoseph, hailHolyQueen]
        ),
        "annunciation": FeastNarrative(
            about: """
        The Annunciation is the first Joyful Mystery: the angel Gabriel greets Mary, and by her fiat the Word becomes flesh. We keep this solemnity nine months before Christmas because salvation history turns on God’s initiative meeting a free human yes—and the Church must never forget how the Incarnation began.
        
        Spiritually the day invites our own fiat. Mary’s openness becomes the pattern of discipleship: to listen, to consent, and to carry Christ into the world. The Angelus prayer keeps this grace close—asking that what was begun in her may be brought to maturity in us through the Cross and Resurrection.
        """,
            history: "Kept on 25 March from early centuries, the solemnity is transferred when it falls in Holy Week or the Easter Octave. It remains a hinge of the liturgical year: the mystery of the Word made flesh announced and received.",
            indulgence: nil,
            relatedPrayers: [angelus, memorare, hailHolyQueen]
        ),
        "palm-sunday": FeastNarrative(
            about: """
        Palm Sunday opens Holy Week. The Church blesses palms and hears the Passion: the same voices that cry “Hosanna” will soon cry “Crucify.” We keep this paradoxical day so that triumph and suffering are not separated in our memory of Christ.
        
        Spiritually Palm Sunday examines the heart. It asks whether our praise will endure when discipleship costs, and it places the Sorrowful Mysteries on the road from entry to Cross. The grace of the day is conversion from shallow enthusiasm to faithful love.
        """,
            history: "The day’s liturgy unites royal welcome and the long Passion Gospel. Processions with palms are ancient; the whole week is placed under the shadow of the Cross.",
            indulgence: nil,
            relatedPrayers: [animaChristi]
        ),
        "holy-thursday": FeastNarrative(
            about: """
        The Mass of the Lord’s Supper opens the Paschal Triduum. Christ gives the Eucharist and the priesthood, washes feet, and enters the agony. We memorialize this night because the Church’s deepest treasures—Communion, ministry, and humble charity—flow from the Upper Room.
        
        For the faithful the day is an invitation to adore, to serve, and to watch. The fifth Luminous Mystery belongs here: receiving the Eucharist as Christ’s gift, learning love that kneels, and staying awake with him in the garden of fear and trust.
        """,
            history: "From the Upper Room the Church receives her life. After Mass the Blessed Sacrament is carried to the altar of repose; the Church keeps watch with Christ into the night before the Passion.",
            indulgence: nil,
            relatedPrayers: [animaChristi]
        ),
        "good-friday": FeastNarrative(
            about: """
        On Good Friday the Church keeps the Passion of the Lord: the Cross is unveiled, the Passion is proclaimed, and Communion is received from the reserved Sacrament. We commemorate this day because without the Cross there is no Christianity—only an unfinished story of love.
        
        Spiritually Good Friday teaches adoration in sorrow. Praying the Sorrowful Mysteries slowly, venerating the wood of the Cross, and standing with Mary, we ask for the grace of repentance, compassion, and steadfast hope in the Crucified who saves.
        """,
            history: "This is not a Mass day but a solemn Celebration of the Passion. Veneration of the Cross and the Reproaches mark a liturgy of mourning and adoration before the Lord who loved us to the end.",
            indulgence: nil,
            relatedPrayers: [animaChristi, fatimaPrayer]
        ),
        "holy-saturday": FeastNarrative(
            about: """
        Holy Saturday is a day of silence at the tomb. The Church waits with Mary and the disciples; the altar is bare. We keep this quiet because faith must learn to remain when glory is hidden and hope seems buried.
        
        Spiritually the day forms patience and trust. The Sorrowful Mysteries still belong to this stillness, preparing the heart for the Vigil. The grace of Holy Saturday is to wait without despair until the light of the Resurrection is kindled.
        """,
            history: "The ancient Easter Vigil—light, word, water, Eucharist—is the mother of all vigils. Until nightfall the Church keeps watch; after dark she already tastes the rising of the Lord.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, fatimaPrayer]
        ),
        "easter": FeastNarrative(
            about: """
        Christ is risen. Easter is the feast of feasts: the tomb is empty, death is conquered, and joy is not a mood but a fact of faith. We celebrate this day because the whole Christian life stands or falls with the Resurrection.
        
        For every believer Easter is the wellspring of hope. The Glorious Mysteries become the prayer of this day and season: Christ lives, and in him we are offered the grace of new life, forgiveness, and courage to proclaim that love is stronger than death.
        """,
            history: "From apostolic times Sunday celebration of the Resurrection shaped Christian time. The Easter Octave and the fifty days to Pentecost unfold the joy begun at the Vigil and the morning Masses of Easter.",
            indulgence: nil,
            relatedPrayers: [reginaCaeli, hailHolyQueen]
        ),
        "divine-mercy": FeastNarrative(
            about: """
        The Second Sunday of Easter closes the Easter Octave. From the wounds of the Risen Lord flow mercy. We keep Divine Mercy Sunday so that the Church’s first word after Easter remains what Christ spoke to the fearful disciples: Peace be with you—and so that trust in Jesus’ merciful Heart is not optional piety but Paschal faith.
        
        Spiritually the day invites confession, Communion, and confident prayer: “Jesus, I trust in You.” It is a feast for the wounded, the guilty, and the weary—an offer of reconciliation and the grace of beginning again in the light of the Resurrection.
        """,
            history: "In 2000 St John Paul II inscribed Divine Mercy Sunday in the universal calendar on the Octave of Easter, following St Faustina’s witness. The liturgy of peace and forgiveness meets the devotion of trust in the Merciful Jesus.",
            indulgence: "A plenary indulgence is granted on Divine Mercy Sunday under the usual conditions (sacramental Confession, Eucharistic Communion, and prayer for the intentions of the Roman Pontiff), to the faithful who take part in the prayers and devotions held in honor of Divine Mercy, or who before the Blessed Sacrament recite the Our Father and Creed, adding a devout prayer to the merciful Lord Jesus (e.g. “Merciful Jesus, I trust in you”). Partial indulgence is granted for devout invocation of the merciful Lord Jesus. (Apostolic Penitentiary, decree of 29 June 2002.)",
            relatedPrayers: [divineMercy, reginaCaeli]
        ),
        "fatima": FeastNarrative(
            about: """
        Our Lady of Fatima appeared to three shepherd children in 1917, asking for the daily Rosary, conversion, and reparation. We keep this memorial because Mary’s maternal call—pray, repent, offer sacrifices for sinners—remains urgently needed in every age.
        
        Spiritually Fatima forms a way of life: the Rosary as daily companionship with Christ, penance as love, and hope under Mary’s Immaculate Heart. The prayer taught after each decade asks for the grace of mercy for souls and peace for the world.
        """,
            history: "The Fatima events, approved by the Church, shaped twentieth-century Marian devotion. The optional memorial keeps before the faithful the children’s witness and Our Lady’s enduring request for the Rosary.",
            indulgence: nil,
            relatedPrayers: [fatimaPrayer, hailHolyQueen, memorare]
        ),
        "ascension": FeastNarrative(
            about: """
        Forty days after Easter, Christ ascends to the Father and takes our humanity into heaven. We celebrate the Ascension—the second Glorious Mystery—because the Lord’s going is not abandonment but exaltation: where the Head has gone, the Body is called to follow.
        
        Spiritually the feast lifts the eyes of the heart. It teaches holy longing, confidence in Christ’s intercession, and readiness for mission. Waiting for Pentecost, we ask for the grace to live already as citizens of heaven while serving on earth.
        """,
            history: "Scripture and the creeds confess the Ascension. Where the solemnity is transferred, many places keep it on the following Sunday. The day looks toward Pentecost: the Lord goes so that the Spirit may be given.",
            indulgence: nil,
            relatedPrayers: [reginaCaeli, hailHolyQueen]
        ),
        "pentecost": FeastNarrative(
            about: """
        At Pentecost the Holy Spirit is poured out on the Apostles. We keep this solemnity—the third Glorious Mystery and the close of Easter Time—because the Church cannot live by memory alone; she lives by the Spirit who makes Christ present and sends her to every tongue and nation.
        
        Spiritually Pentecost is a feast of courage, unity, and renewal. We ask to be kindled again with holy fire: the grace to pray, to forgive, to witness, and to let the Spirit renew the face of our own lives and of the earth.
        """,
            history: "The Jewish feast of Weeks becomes, for Christians, the birthday of the Church’s public mission. Red vestments and the Sequence Veni Sancte Spiritus mark the day’s joy and petition.",
            indulgence: nil,
            relatedPrayers: [comeHolySpirit, hailHolyQueen]
        ),
        "mother-of-the-church": FeastNarrative(
            about: """
        On the Monday after Pentecost the Church honors Mary as Mother of the Church. We keep this obligatory memorial because the Woman who stood at the Cross and prayed with the disciples at Pentecost is given to every believer as mother—sharing in the birth of the Church by the Spirit.
        
        Spiritually the day joins Marian trust to Pentecostal fire. We ask Mary to form us as disciples who receive the Spirit, love the Body of Christ, and carry the Gospel with her maternal courage.
        """,
            history: "The title Mother of the Church was solemnly proclaimed by Pope St Paul VI at the close of the Second Vatican Council. In 2018 Pope Francis inscribed the memorial in the General Roman Calendar on the Monday after Pentecost.",
            indulgence: nil,
            relatedPrayers: [comeHolySpirit, memorare, subTuum]
        ),
        "visitation": FeastNarrative(
            about: """
        Mary, carrying Christ, visits Elizabeth. The child leaps in the womb; Elizabeth blesses Mary; Mary sings the Magnificat. We celebrate the second Joyful Mystery as a feast of charity and praise—because faith that is true moves toward others bearing Christ.
        
        Spiritually the Visitation teaches us to go in haste to serve, to recognize grace in another’s life, and to magnify the Lord rather than ourselves. Its grace is joyful charity: Christ hidden in us becoming blessing for our neighbor.
        """,
            history: "The Visitation feast (31 May in the current calendar) recalls Luke 1. It closes May’s Marian month in many places and sends the Church into ordinary time with Mary’s song of praise.",
            indulgence: nil,
            relatedPrayers: [magnificatShort, hailHolyQueen, memorare]
        ),
        "trinity": FeastNarrative(
            about: """
        On the Sunday after Pentecost the Church contemplates the Most Holy Trinity—Father, Son, and Holy Spirit, one God. We keep this solemnity because Christian prayer, Baptism, and the Sign of the Cross are already Trinitarian; the feast simply lets wonder catch up with what we confess.
        
        Spiritually Trinity Sunday draws us into communion. We are made for relationship that mirrors divine love: to live as children of the Father, disciples of the Son, and temples of the Spirit. The grace of the day is deeper worship and a life shaped by that shared love.
        """,
            history: "The solemnity grew in the Middle Ages and was extended to the universal Church. It gathers Easter’s revelation: the Son sent, the Spirit given, the Father glorified.",
            indulgence: nil,
            relatedPrayers: [gloryBe, comeHolySpirit]
        ),
        "corpus-christi": FeastNarrative(
            about: """
        Corpus Christi honors the Most Holy Body and Blood of Christ. Processions and adoration proclaim the Real Presence. We celebrate this solemnity so that the gift of Holy Thursday may be praised in the open light of day—the fifth Luminous Mystery shining in the streets and in the heart.
        
        Spiritually the feast invites hunger for Communion, reverence in worship, and love that becomes bread for others. Adoration is not escape but exposure to Christ’s nearness; its grace is faith strengthened and charity renewed.
        """,
            history: "Promoted by St Juliana of Liège and established in the thirteenth century, the solemnity is often transferred to Sunday in the United States. Hymns of St Thomas Aquinas still mark the liturgy and procession.",
            indulgence: nil,
            relatedPrayers: [animaChristi]
        ),
        "sacred-heart": FeastNarrative(
            about: """
        The Most Sacred Heart of Jesus reveals divine love wounded for sinners. We keep this solemnity to honor not an abstract idea of love but the living Heart that was pierced on the Cross and still burns with mercy for the world.
        
        Spiritually the feast calls for reparation, trust, and consecration. Before the Sacred Heart we bring coldness, indifference, and fear, asking for the grace of a heart made warm, faithful, and courageous in return.
        """,
            history: "Devotion flowered through St Margaret Mary Alacoque and was extended to the universal Church. The feast falls on the Friday after the second Sunday after Pentecost.",
            indulgence: nil,
            relatedPrayers: [animaChristi]
        ),
        "immaculate-heart": FeastNarrative(
            about: """
        The Immaculate Heart of Mary—pure, sorrowful, and faithful—shares in the work of her Son. We memorialize her Heart the day after the Sacred Heart so that Jesus’ love and Mary’s answering love are contemplated together, not apart.
        
        Spiritually the memorial invites consecration to Mary’s maternal care: to keep God’s word as she did, to stand at the Cross, and to hope through tears. Its grace is a heart purified, attentive, and joined to Christ through Mary.
        """,
            history: "Linked to Fatima and to older Marian heart devotion, the memorial was placed on the Saturday after the Sacred Heart. It pairs the Heart of Jesus with the Heart that treasured all things and remained faithful beneath the Cross.",
            indulgence: nil,
            relatedPrayers: [memorare, hailHolyQueen, fatimaPrayer]
        ),
        "peter-paul": FeastNarrative(
            about: """
        Saints Peter and Paul, pillars of the apostolic Church, are honored together: Peter the rock and shepherd, Paul the apostle to the nations. We celebrate them because the Church is built on apostolic witness sealed in blood, and Rome’s faith is still measured by their confession of Christ.
        
        Spiritually their feast strengthens unity and mission. Peter teaches fidelity under weakness forgiven; Paul teaches zeal that spends itself for the Gospel. We ask for the grace of steadfast faith and courageous proclamation.
        """,
            history: "June 29 is an ancient Roman feast of the two apostles. Pilgrims still visit their basilicas; the day celebrates the unity and mission of the Church founded on the apostles.",
            indulgence: nil,
            relatedPrayers: [apostlesCreed]
        ),
        "carmel": FeastNarrative(
            about: """
        Our Lady of Mount Carmel is patroness of the Carmelite family and is closely associated with the Brown Scapular. We keep this memorial because Mary’s protection is not distant patronage but a call to wear her spirit—prayer, purity of heart, and belonging to Christ.
        
        Spiritually Carmel invites contemplative trust. The scapular, a sacramental encouraged by the Church, is a sign of living under Mary’s mantle. Its grace is perseverance in prayer and confidence in her maternal intercession.
        """,
            history: "Carmelite tradition looks to Mount Carmel and to Mary’s care for the Order. The memorial on 16 July keeps that heritage before the whole Church as a path of Marian discipleship.",
            indulgence: nil,
            relatedPrayers: [flosCarmeli, hailHolyQueen, memorare]
        ),
        "assumption": FeastNarrative(
            about: """
        The Assumption: Mary is taken body and soul into heavenly glory. We celebrate this solemnity—the fourth Glorious Mystery—because where she has gone, we hope to follow. She is the first fruits of the Resurrection in a creature full of grace.
        
        Spiritually the Assumption lifts Christian hope beyond death. It consoles the grieving, honors the dignity of the body, and asks for the grace of a holy life that ends in glory with Christ and his Mother.
        """,
            history: "Defined as dogma by Pius XII in 1950, the Assumption was already an ancient feast (Dormition in the East). August 15 is a holy day of obligation in many places.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare]
        ),
        "queenship": FeastNarrative(
            about: """
        One week after the Assumption, the Church honors Mary as Queen. We keep this memorial because her Queenship is not worldly power but maternal reign: she shares the kingship of her Son by serving, interceding, and drawing hearts to him.
        
        Spiritually Mary’s Queenship invites confident prayer. To call her Queen is to trust her nearness to Christ the King and to ask for the grace of belonging to their kingdom of mercy, humility, and peace.
        """,
            history: "Established by Pius XII in 1954 and later moved to 22 August, the memorial completes the Assumption octave theme: Mary exalted beside Christ the King.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare]
        ),
        "nativity-mary": FeastNarrative(
            about: """
        The Nativity of Mary is the birthday of the Mother of God. We celebrate the dawn of salvation appearing in the child of Joachim and Anne—because the story of redemption includes a real birth, a real home, and a girl prepared for an immensity of grace.
        
        Spiritually her birthday is a feast of beginnings and gratitude. It renews joy in Mary’s place in our lives and asks for the grace to welcome God’s work in small, hidden starts.
        """,
            history: "The feast is ancient in the East and entered the West early. September 8 stands nine months after the Immaculate Conception (8 December).",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare]
        ),
        "holy-name-mary": FeastNarrative(
            about: """
        The Most Holy Name of Mary is sweetness and defense for the faithful. We keep this optional memorial because to speak her name in faith is already a prayer of trust—and the Church has long fled to that name in danger and need.
        
        Spiritually the feast teaches reverence and confidence. Invoking Mary’s holy name asks for the grace of protection, purity of speech and heart, and a child’s instinct to call upon his Mother.
        """,
            history: "The memorial on 12 September grew from devotion to the Holy Name and from thanksgiving after victories entrusted to Mary’s intercession, including the relief of Vienna in 1683.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare, subTuum]
        ),
        "sorrows": FeastNarrative(
            about: """
        Our Lady of Sorrows stands at the Cross. The seven sorrows keep company with the Sorrowful Mysteries: we memorialize her pierced heart so that Christian compassion does not look away from suffering, and so that Mary’s fidelity teaches us how to remain.
        
        Spiritually the day forms hearts that can suffer with others without bitterness. Standing with Mary, we ask for the grace of perseverance in trial, tenderness toward the wounded, and hope that does not die at the foot of the Cross.
        """,
            history: "The memorial follows the Exaltation of the Holy Cross (14 September). Servite devotion to the seven dolors shaped the feast’s popular piety and the sequence Stabat Mater.",
            indulgence: nil,
            relatedPrayers: [stabatMater, animaChristi, hailHolyQueen]
        ),
        "michael": FeastNarrative(
            about: """
        Michaelmas honors the archangels Michael, Gabriel, and Raphael. We celebrate them because Scripture reveals God’s messengers and defenders at work—and because the Church still needs heavenly help against evil, for proclamation, and for healing.
        
        Spiritually the feast renews vigilance and trust. Saint Michael especially is invoked as defender against the wickedness and snares of the devil. We ask for the grace of spiritual courage, clarity, and protection for the Church and for our homes.
        """,
            history: "September 29 was long dedicated to Michael; the present feast gathers the three archangels named in Scripture. Dedication of the Roman basilica of St Michael shaped the date.",
            indulgence: nil,
            relatedPrayers: [saintMichael]
        ),
        "guardian-angels": FeastNarrative(
            about: """
        The Holy Guardian Angels: each soul is entrusted to an angel’s care. We keep this memorial to thank God for a providence that is personal—not only cosmic—and to remember that we never walk alone in the spiritual life.
        
        Spiritually the day invites gratitude, reverence, and cooperation with our guardian. Asking their help is asking for the grace of guidance, protection from harm, and perseverance on the path to heaven.
        """,
            history: "Local angel feasts existed for centuries; the memorial on 2 October became universal. Scripture and Tradition affirm angelic guardianship over the faithful.",
            indulgence: nil,
            relatedPrayers: [angelOfGod, saintMichael]
        ),
        "rosary": FeastNarrative(
            about: """
        Our Lady of the Rosary invites the whole Church to the daily beads. We celebrate this memorial because the Rosary is a school of the Gospel: with Mary we contemplate Christ’s life, and through that contemplation we are slowly changed.
        
        Spiritually the feast renews perseverance in prayer. It recalls Mary’s help—famously associated with Lepanto—and asks for the grace of contemplative fidelity. The Church attaches indulgences to devout Rosary prayer under the usual conditions; more than any privilege, the beads themselves are a daily path of peace and conversion.
        """,
            history: "Instituted after the victory of Lepanto (1571) and long associated with the Rosary’s spread by the Dominicans, the memorial falls on 7 October as a feast of gratitude and perseverance in Marian prayer.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, fatimaPrayer, memorare]
        ),
        "all-saints": FeastNarrative(
            about: """
        All Saints gathers the countless holy ones—known and unknown—who see God face to face. We keep this solemnity to remember that holiness is the Church’s true harvest, and that Mary, Queen of All Saints, leads a communion already praising God.
        
        Spiritually the feast widens hope. Ordinary lives can become radiant; the saints are not distant trophies but companions and intercessors. We ask for the grace to desire heaven and to walk the same path of love.
        """,
            history: "The solemnity on 1 November crowns the harvest of holiness. It balances All Souls on 2 November: glory first, then prayer for those being purified.",
            indulgence: nil,
            relatedPrayers: [apostlesCreed, hailHolyQueen]
        ),
        "all-souls": FeastNarrative(
            about: """
        All Souls Day commemorates all the faithful departed. We keep this day because love does not abandon the dead: the Church prays that those being purified may enter the joy of heaven, and that we may live in holy remembrance.
        
        Spiritually November’s suffrage softens grief into charity. The Rosary, the Fatima prayer, and the Eternal Rest petition become works of mercy. The Church grants special indulgences applicable to the holy souls for devout visits and prayers under the usual conditions—an invitation to help them by the grace of Communion and prayer.
        """,
            history: "St Odilo of Cluny helped spread the Commemoration of All the Faithful Departed on 2 November. The month becomes a season of suffrage, linking All Saints’ glory to patient hope for the departed.",
            indulgence: "A plenary indulgence, applicable only to the souls in purgatory, is granted to the faithful who on All Souls Day (or, with permission of the Ordinary, on the Sunday before or after, or on All Saints) devoutly visit a church or oratory and there recite the Our Father and the Creed, under the usual conditions. From 1 to 8 November, a plenary indulgence (also applicable only to the departed) is granted each day for those who visit a cemetery and pray, even mentally, for the dead, under the usual conditions. (Enchiridion Indulgentiarum; Apostolic Penitentiary norms.)",
            relatedPrayers: [eternalRest, fatimaPrayer, hailHolyQueen]
        ),
        "presentation-mary": FeastNarrative(
            about: """
        The Presentation of Mary recalls her being offered to God in the Temple—a feast of consecration and readiness for her vocation as Mother of the Redeemer. We keep it because discipleship begins in dedication: a life set apart for God’s purpose.
        
        Spiritually the memorial invites us to offer ourselves as Mary did—quietly, completely, and with trust. Its grace is a renewed availability to God and a heart prepared for whatever vocation love requires.
        """,
            history: "Rooted in early tradition and the Protoevangelium of James, the memorial on 21 November is shared with the East and keeps Mary’s childhood consecration before the Church.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare, subTuum]
        ),
        "christ-the-king": FeastNarrative(
            about: """
        Our Lord Jesus Christ, King of the Universe, reigns from the Cross and in glory. We celebrate this solemnity at the close of Ordinary Time so that every rival claim on the heart—power, fear, ideology—is measured against his merciful kingship.
        
        Spiritually the feast asks for allegiance. To acclaim Christ as King is to let him rule conscience, culture, and daily choice. We seek the grace of a loyal heart that awaits his return with hope, not dread.
        """,
            history: "Instituted by Pius XI in 1925 and later moved to the last Sunday of Ordinary Time, the feast proclaims Christ’s kingship over every people and over every heart, looking toward Advent.",
            indulgence: nil,
            relatedPrayers: [ourFather, animaChristi]
        ),
        "advent-1": FeastNarrative(
            about: """
        The First Sunday of Advent begins the liturgical year. The Church watches for Christ’s coming—in history, in mystery, and in glory. We keep this threshold Sunday so that Christmas is prepared by longing, not by haste alone.
        
        Spiritually Advent awakens vigilance and desire. The Joyful Mysteries suit these Sundays: Mary’s waiting becomes ours. The grace of the season is a heart made ready—repentant, hopeful, and eager for the Lord who comes.
        """,
            history: "Advent’s four Sundays prepare for Christmas while keeping an eye on the Last Day. Violet (or blue in some places) and the Advent wreath mark the season’s holy longing.",
            indulgence: nil,
            relatedPrayers: [angelus, hailHolyQueen]
        ),
        "immaculate-conception": FeastNarrative(
            about: """
        The Immaculate Conception: from the first instant of her conception Mary was preserved from original sin by the merits of Christ. We celebrate this solemnity—patronal in the United States and a holy day of obligation there—because the Redeemer’s grace is powerful enough to prepare his Mother from the beginning.
        
        Spiritually the feast reveals what grace can do. Mary’s purity is not distance from us but hope for us: we ask for the grace of a clean heart, freedom from sin’s grip, and confidence in Christ who saves even at the root.
        """,
            history: "Defined by Pius IX in 1854 (Ineffabilis Deus), the dogma crowns centuries of devotion. The solemnity on 8 December stands nine months before Mary’s Nativity.",
            indulgence: nil,
            relatedPrayers: [memorare, hailHolyQueen, angelus]
        ),
        "guadalupe": FeastNarrative(
            about: """
        Our Lady of Guadalupe appeared to St Juan Diego in 1531. Her image on the tilma and her maternal words—“Am I not here, I who am your Mother?”—made her Patroness of the Americas. We keep this feast because evangelization in the New World was cradled in Mary’s tenderness toward the poor and the indigenous heart.
        
        Spiritually Guadalupe consoles and sends. She teaches that the Gospel can be planted with dignity, beauty, and maternal nearness. We ask for the grace of trust in her presence and zeal for a faith that uplifts the lowly.
        """,
            history: "The feast on 12 December is central to Mexican and American Catholic life. Millions pilgrimage to Tepeyac; the event remains a foundational chapter of evangelization in the Americas.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare, subTuum]
        ),
        "christmas": FeastNarrative(
            about: """
        Christmas: the Nativity of the Lord. The Word is made flesh and dwells among us. We celebrate this holy night and day because God has not loved us from afar—he has taken our flesh, entered our poverty, and made a manger the doorway of salvation.
        
        Spiritually Christmas is wonder joined to welcome. The Joyful Mysteries, especially the Nativity, teach humility, gratitude, and peace. We ask for the grace to receive Christ anew—in the Eucharist, in the poor, and in the quiet of a heart made room for him.
        """,
            history: "From early centuries 25 December has marked the Nativity in the Roman Church. The Octave, and the season through the Baptism of the Lord, unfold the mystery of the Incarnation.",
            indulgence: nil,
            relatedPrayers: [angelus, hailHolyQueen, memorare]
        )
    ]
}

extension Feast {
    var narrative: FeastNarrative? { FeastNarratives.narrative(for: id) }

    /// Prefer narrative about; fall back to catalog summary.
    var aboutText: String { narrative?.about ?? summary }

    var historyText: String? { narrative?.history }

    /// Only populated for well-established grants; never invented.
    var indulgenceNote: String? { narrative?.indulgence }

    var relatedPrayersForDay: [FeastRelatedPrayer] { narrative?.relatedPrayers ?? [] }
}
