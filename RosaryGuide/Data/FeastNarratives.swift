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

    // MARK: - Catalog

    private static let table: [String: FeastNarrative] = [
        "mary-mother-of-god": FeastNarrative(
            about: "On the octave of Christmas the Church honors Mary under her greatest title: Mother of God (Theotokos). The feast keeps Christmas close—Christ is truly God, and Mary is truly his Mother—while turning our eyes to her maternal care for the Church.",
            history: "The Council of Ephesus (431) defended the title Theotokos against those who would separate Christ’s natures. In the Roman calendar the solemnity falls on 1 January, the Octave of the Nativity. It is also the World Day of Peace.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare, angelus]
        ),
        "epiphany": FeastNarrative(
            about: "Epiphany means manifestation. The Church celebrates Christ revealed to the nations in the Magi, and traditionally also recalls his Baptism and the miracle at Cana—the light of the Gentiles made visible.",
            history: "The feast is ancient in East and West. In the United States it is commonly observed on the Sunday between 2 and 8 January. The Magi’s gifts and journey have long shaped Christian devotion and art.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen]
        ),
        "baptism-movable": FeastNarrative(
            about: "The Baptism of the Lord closes Christmas Time. Jesus enters the Jordan; the Spirit descends; the Father’s voice names him beloved Son. The first Luminous Mystery belongs especially to this day.",
            history: "Celebrated after Epiphany in the Roman calendar, the feast marks the beginning of Christ’s public ministry. It replaced an older octave emphasis and invites contemplation of our own baptismal life.",
            indulgence: nil,
            relatedPrayers: [comeHolySpirit]
        ),
        "presentation": FeastNarrative(
            about: "Candlemas: Mary and Joseph present the Child in the Temple according to the Law. Simeon and Anna recognize the Light of the nations. The day is Marian and Christological at once—the fourth Joyful Mystery.",
            history: "Known in the East as the Meeting (Hypapante), the feast entered the West with candle processions symbolizing Christ the light. It falls forty days after Christmas, completing the Christmas cycle in older reckoning.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare]
        ),
        "lourdes": FeastNarrative(
            about: "Our Lady of Lourdes recalls Mary’s appearances to St Bernadette in 1858. Mary named herself the Immaculate Conception and called for prayer and penance. The Church keeps this day as the World Day of the Sick.",
            history: "From a grotto in the Pyrenees, Lourdes became a place of pilgrimage, healing, and Marian devotion. The optional memorial invites trust in Mary’s maternal care for the suffering.",
            indulgence: nil,
            relatedPrayers: [memorare, hailHolyQueen]
        ),
        "ash-wednesday": FeastNarrative(
            about: "Lent begins with ashes and a call to convert: prayer, fasting, and almsgiving. The Sorrowful Mysteries accompany this season as we walk toward the Cross with Christ.",
            history: "Ashes mark mortality and repentance—“remember that you are dust.” The day opens the forty days that prepare the Church for the Paschal Triduum and Easter.",
            indulgence: nil,
            relatedPrayers: [animaChristi]
        ),
        "joseph": FeastNarrative(
            about: "Saint Joseph, spouse of the Blessed Virgin and guardian of the Redeemer, is patron of the universal Church. Silent, just, and obedient, he protects the Holy Family and still watches over Christian homes.",
            history: "Devotion to Joseph grew strongly in the late Middle Ages and modern era. His solemnity on 19 March honors him as husband of Mary. A separate memorial (1 May) honors Joseph the Worker.",
            indulgence: nil,
            relatedPrayers: [stJoseph, hailHolyQueen]
        ),
        "annunciation": FeastNarrative(
            about: "The Annunciation is the first Joyful Mystery: the angel Gabriel greets Mary, and by her fiat the Word becomes flesh. Nine months before Christmas, the Church rejoices in the Incarnation begun in her womb.",
            history: "Kept on 25 March from early centuries, the solemnity is transferred when it falls in Holy Week or the Easter Octave. It is a hinge of salvation history—God’s initiative meeting Mary’s free consent.",
            indulgence: nil,
            relatedPrayers: [angelus, memorare, hailHolyQueen]
        ),
        "palm-sunday": FeastNarrative(
            about: "Palm Sunday opens Holy Week. The Church blesses palms and hears the Passion: the same crowd that cries “Hosanna” will soon cry “Crucify.” The Sorrowful Mysteries fit this road from entry to Cross.",
            history: "The day’s liturgy unites triumph and suffering. Processions with palms are ancient; the long Passion Gospel places the whole week under the shadow of the Cross.",
            indulgence: nil,
            relatedPrayers: [animaChristi]
        ),
        "holy-thursday": FeastNarrative(
            about: "The Mass of the Lord’s Supper opens the Paschal Triduum. Christ gives the Eucharist and the priesthood, washes feet, and enters the agony. The fifth Luminous Mystery—the Institution of the Eucharist—belongs here.",
            history: "From the Upper Room the Church receives her deepest treasures. After Mass the Blessed Sacrament is carried to the altar of repose; the Church watches with Christ into the night.",
            indulgence: nil,
            relatedPrayers: [animaChristi]
        ),
        "good-friday": FeastNarrative(
            about: "On Good Friday the Church keeps the Passion of the Lord: the Cross is unveiled, the Passion is proclaimed, and Communion is received from the reserved Sacrament. Pray the Sorrowful Mysteries slowly.",
            history: "This is not a Mass day but a solemn Celebration of the Passion. Veneration of the Cross and the Reproaches mark a liturgy of mourning and adoration before the Crucified.",
            indulgence: nil,
            relatedPrayers: [animaChristi, fatimaPrayer]
        ),
        "holy-saturday": FeastNarrative(
            about: "Holy Saturday is a day of silence at the tomb. The Church waits; the Sorrowful Mysteries still belong to this quiet. After nightfall the Easter Vigil already tastes the Resurrection.",
            history: "The ancient Vigil—light, word, water, Eucharist—is the mother of all vigils. Until then the altar is bare and the Church keeps watch with Mary and the disciples.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, fatimaPrayer]
        ),
        "easter": FeastNarrative(
            about: "Christ is risen. Easter is the feast of feasts: the tomb is empty, death is conquered, and the Glorious Mysteries become the prayer of this day and of the whole Easter season.",
            history: "From apostolic times Sunday celebration of the Resurrection shaped Christian time. The Easter Octave and the fifty days to Pentecost unfold the joy begun at the Vigil and morning Masses of Easter.",
            indulgence: nil,
            relatedPrayers: [reginaCaeli, hailHolyQueen]
        ),
        "divine-mercy": FeastNarrative(
            about: "The Second Sunday of Easter closes the Easter Octave. From the wounds of the Risen Lord flow mercy. The Church, following St Faustina’s witness and St John Paul II’s institution, keeps Divine Mercy Sunday.",
            history: "In 2000 St John Paul II inscribed Divine Mercy Sunday in the universal calendar on the Octave of Easter. The day’s liturgy of peace and forgiveness meets the devotion of trust in Jesus’ merciful Heart.",
            indulgence: "A plenary indulgence is granted on Divine Mercy Sunday under the usual conditions (sacramental Confession, Eucharistic Communion, and prayer for the intentions of the Roman Pontiff), to the faithful who take part in the prayers and devotions held in honor of Divine Mercy, or who before the Blessed Sacrament recite the Our Father and Creed, adding a devout prayer to the merciful Lord Jesus (e.g. “Merciful Jesus, I trust in you”). Partial indulgence is granted for devout invocation of the merciful Lord Jesus. (Apostolic Penitentiary, decree of 29 June 2002.)",
            relatedPrayers: [divineMercy, reginaCaeli]
        ),
        "fatima": FeastNarrative(
            about: "Our Lady of Fatima appeared to three shepherd children in 1917, asking for the daily Rosary, conversion, and reparation. The optional memorial keeps her maternal call before the Church.",
            history: "The Fatima events, approved by the Church, shaped twentieth-century Marian devotion. The prayer taught by Our Lady after each decade is now prayed by millions with the Rosary.",
            indulgence: nil,
            relatedPrayers: [fatimaPrayer, hailHolyQueen, memorare]
        ),
        "ascension": FeastNarrative(
            about: "Forty days after Easter, Christ ascends to the Father and takes our humanity into heaven. The second Glorious Mystery. Where the Ascension is transferred, many places keep it on the following Sunday.",
            history: "Scripture and the creeds confess the Ascension. The solemnity looks toward Pentecost: the Lord goes so that the Spirit may be given, and the Church’s mission begins in hope.",
            indulgence: nil,
            relatedPrayers: [reginaCaeli, hailHolyQueen]
        ),
        "pentecost": FeastNarrative(
            about: "At Pentecost the Holy Spirit is poured out on the Apostles. The third Glorious Mystery. Easter Time ends with this solemnity; the Church is sent in every tongue to proclaim the Risen Lord.",
            history: "The Jewish feast of Weeks becomes, for Christians, the birthday of the Church’s public mission. Red vestments and the Sequence Veni Sancte Spiritus mark the day’s joy.",
            indulgence: nil,
            relatedPrayers: [comeHolySpirit, hailHolyQueen]
        ),
        "visitation": FeastNarrative(
            about: "Mary, carrying Christ, visits Elizabeth. The child leaps in the womb; Elizabeth blesses Mary; Mary sings the Magnificat. The second Joyful Mystery is a feast of charity and praise.",
            history: "The Visitation feast (31 May in the current calendar) recalls Luke 1. It closes May’s Marian month in many places and sends the Church into ordinary time with Mary’s song.",
            indulgence: nil,
            relatedPrayers: [magnificatShort, hailHolyQueen, memorare]
        ),
        "trinity": FeastNarrative(
            about: "On the Sunday after Pentecost the Church contemplates the Most Holy Trinity—Father, Son, and Holy Spirit, one God. Every Sign of the Cross and Glory Be is already a Trinitarian prayer.",
            history: "The solemnity grew in the Middle Ages and was extended to the universal Church. It gathers Easter’s revelation: the Son sent, the Spirit given, the Father glorified.",
            indulgence: nil,
            relatedPrayers: [comeHolySpirit]
        ),
        "corpus-christi": FeastNarrative(
            about: "Corpus Christi honors the Most Holy Body and Blood of Christ. Processions and adoration proclaim the Real Presence. The fifth Luminous Mystery—the Institution of the Eucharist—shines here.",
            history: "Promoted by St Juliana of Liège and established in the thirteenth century, the solemnity is often transferred to Sunday in the United States. Hymns of St Thomas Aquinas still mark the liturgy.",
            indulgence: nil,
            relatedPrayers: [animaChristi]
        ),
        "sacred-heart": FeastNarrative(
            about: "The Most Sacred Heart of Jesus reveals divine love wounded for sinners. The solemnity invites reparation, trust, and consecration to the Heart that was pierced on the Cross.",
            history: "Devotion flowered through St Margaret Mary Alacoque and was extended to the universal Church. The feast falls on the Friday after the second Sunday after Pentecost.",
            indulgence: nil,
            relatedPrayers: [animaChristi]
        ),
        "immaculate-heart": FeastNarrative(
            about: "The Immaculate Heart of Mary—pure, sorrowful, and faithful—shares in the work of her Son. The memorial follows the Sacred Heart and invites consecration to Mary’s maternal love.",
            history: "Linked to Fatima and to older Marian heart devotion, the memorial was placed on the Saturday after the Sacred Heart. It pairs Jesus’ Heart with the Heart that kept all things and stood at the Cross.",
            indulgence: nil,
            relatedPrayers: [memorare, hailHolyQueen, fatimaPrayer]
        ),
        "peter-paul": FeastNarrative(
            about: "Saints Peter and Paul, pillars of the apostolic Church, are honored together: Peter the rock and shepherd, Paul the apostle to the nations. Their blood watered the Church of Rome.",
            history: "June 29 is an ancient Roman feast of the two apostles. Pilgrims still visit their basilicas; the day celebrates the unity and mission of the Church built on the apostles.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen]
        ),
        "carmel": FeastNarrative(
            about: "Our Lady of Mount Carmel is patroness of the Carmelite family and is closely associated with the Brown Scapular. The memorial invites clothing ourselves in Mary’s protection and living her contemplative spirit.",
            history: "Carmelite tradition looks to Mount Carmel and to Mary’s care for the Order. The scapular devotion, encouraged by the Church, is a sacramental sign of belonging to Mary and following Christ.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare, subTuum]
        ),
        "assumption": FeastNarrative(
            about: "The Assumption: Mary is taken body and soul into heavenly glory. The fourth Glorious Mystery. Where she has gone, we hope to follow—the first fruits of the Resurrection in a creature full of grace.",
            history: "Defined as dogma by Pius XII in 1950, the Assumption was already an ancient feast (Dormition in the East). August 15 is a holy day of obligation in many places.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare]
        ),
        "queenship": FeastNarrative(
            about: "One week after the Assumption, the Church honors Mary as Queen. She reigns by serving; her Queenship is maternal, close to the Kingship of her Son.",
            history: "Established by Pius XII in 1954 and later moved to 22 August, the memorial completes the Assumption octave theme: Mary exalted beside Christ the King.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare]
        ),
        "nativity-mary": FeastNarrative(
            about: "The Nativity of Mary is the birthday of the Mother of God. The Church rejoices that the dawn of salvation has appeared in the child of Joachim and Anne.",
            history: "The feast is ancient in the East and entered the West early. September 8 stands nine months after the Immaculate Conception (8 December).",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare]
        ),
        "holy-name-mary": FeastNarrative(
            about: "The Most Holy Name of Mary is sweetness and defense for the faithful. To speak her name in faith is already a prayer of trust.",
            history: "The optional memorial (12 September) grew from devotion to the Holy Name and from thanksgiving after victories entrusted to Mary’s intercession, including the relief of Vienna in 1683.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare]
        ),
        "sorrows": FeastNarrative(
            about: "Our Lady of Sorrows stands at the Cross. The seven sorrows keep company with the Sorrowful Mysteries: Mary’s pierced heart teaches compassion and fidelity in suffering.",
            history: "The memorial follows the Exaltation of the Holy Cross (14 September). Servite devotion to the seven dolors shaped the feast’s popular piety and sequence Stabat Mater.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, fatimaPrayer, animaChristi]
        ),
        "michael": FeastNarrative(
            about: "Michaelmas honors the archangels Michael, Gabriel, and Raphael. Saint Michael, prince of the heavenly host, is invoked as defender against the wickedness and snares of the devil.",
            history: "September 29 was long dedicated to Michael; the present feast gathers the three archangels named in Scripture. Dedication of the Roman basilica of St Michael shaped the date.",
            indulgence: nil,
            relatedPrayers: [saintMichael]
        ),
        "guardian-angels": FeastNarrative(
            about: "The Holy Guardian Angels: each soul is entrusted to an angel’s care. The memorial invites gratitude and confidence in God’s providence through these invisible companions.",
            history: "Local angel feasts existed for centuries; the memorial on 2 October became universal. Scripture and Tradition affirm angelic guardianship over the faithful.",
            indulgence: nil,
            relatedPrayers: [saintMichael]
        ),
        "rosary": FeastNarrative(
            about: "Our Lady of the Rosary invites the whole Church to the daily beads. The memorial recalls Mary’s help and the contemplative path of the Mysteries through Christ’s life.",
            history: "Instituted after the victory of Lepanto (1571) and long associated with the Rosary’s spread by the Dominicans, the memorial falls on 7 October. It is a feast of gratitude and perseverance in prayer.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, fatimaPrayer, memorare]
        ),
        "all-saints": FeastNarrative(
            about: "All Saints gathers the countless holy ones—known and unknown—who see God face to face. Mary, Queen of All Saints, leads the communion of saints in praise.",
            history: "The solemnity on 1 November crowns the harvest of holiness. It balances All Souls on 2 November: glory first, then prayer for those being purified.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen]
        ),
        "all-souls": FeastNarrative(
            about: "All Souls Day commemorates all the faithful departed. The Church prays that those being purified may enter the joy of heaven. The Rosary and the Fatima prayer are especially fitting.",
            history: "St Odilo of Cluny helped spread the Commemoration of All the Faithful Departed on 2 November. November becomes a month of suffrage for the holy souls.",
            indulgence: "A plenary indulgence, applicable only to the souls in purgatory, is granted to the faithful who on All Souls Day (or, with permission of the Ordinary, on the Sunday before or after, or on All Saints) devoutly visit a church or oratory and there recite the Our Father and the Creed, under the usual conditions. From 1 to 8 November, a plenary indulgence (also applicable only to the departed) is granted each day for those who visit a cemetery and pray, even mentally, for the dead, under the usual conditions. (Enchiridion Indulgentiarum; Apostolic Penitentiary norms.)",
            relatedPrayers: [eternalRest, fatimaPrayer, hailHolyQueen]
        ),
        "presentation-mary": FeastNarrative(
            about: "The Presentation of Mary recalls her being offered to God in the Temple—a feast of consecration and readiness for her vocation as Mother of the Redeemer.",
            history: "Rooted in early tradition and the Protoevangelium of James, the memorial (21 November) is shared with the East. It invites the faithful to offer their lives as Mary did.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare, subTuum]
        ),
        "christ-the-king": FeastNarrative(
            about: "Our Lord Jesus Christ, King of the Universe, reigns from the Cross and in glory. The solemnity closes Ordinary Time and looks toward Advent’s hope for his return.",
            history: "Instituted by Pius XI in 1925 and later moved to the last Sunday of Ordinary Time, the feast proclaims Christ’s kingship over every people and over every heart.",
            indulgence: nil,
            relatedPrayers: [animaChristi]
        ),
        "advent-1": FeastNarrative(
            about: "The First Sunday of Advent begins the liturgical year. The Church watches for Christ’s coming—in history, in mystery, and in glory. Sundays of Advent take the Joyful Mysteries.",
            history: "Advent’s four Sundays prepare for Christmas while keeping an eye on the Last Day. Violet (or blue in some places) and the Advent wreath mark the season’s holy longing.",
            indulgence: nil,
            relatedPrayers: [angelus, hailHolyQueen]
        ),
        "immaculate-conception": FeastNarrative(
            about: "The Immaculate Conception: from the first instant of her conception Mary was preserved from original sin by the merits of Christ. Patronal solemnity of the United States; a holy day of obligation there.",
            history: "Defined by Pius IX in 1854 (Ineffabilis Deus), the dogma crowns centuries of devotion. The solemnity on 8 December is nine months before Mary’s Nativity.",
            indulgence: nil,
            relatedPrayers: [memorare, hailHolyQueen, angelus]
        ),
        "guadalupe": FeastNarrative(
            about: "Our Lady of Guadalupe appeared to St Juan Diego in 1531. Her image on the tilma and her maternal words—“Am I not here, I who am your Mother?”—made her Patroness of the Americas.",
            history: "The feast on 12 December is central to Mexican and American Catholic life. Millions pilgrimage to Tepeyac; the event is a foundational chapter of evangelization in the New World.",
            indulgence: nil,
            relatedPrayers: [hailHolyQueen, memorare, subTuum]
        ),
        "christmas": FeastNarrative(
            about: "Christmas: the Nativity of the Lord. The Word is made flesh and dwells among us. The Joyful Mysteries—especially the Nativity—are the prayer of this holy night and day.",
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
