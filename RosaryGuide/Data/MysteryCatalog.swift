import Foundation

enum MysteryCatalog {
    static func mysteries(for set: MysterySetKind) -> [Mystery] {
        all.filter { $0.set == set }.sorted { $0.number < $1.number }
    }

    static func mystery(id: String) -> Mystery? {
        all.first { $0.id == id }
    }

    static let all: [Mystery] = joyful + sorrowful + glorious + luminous

    // MARK: - Joyful

    static let joyful: [Mystery] = [
        Mystery(
            id: "joyful-1",
            set: .joyful,
            number: 1,
            title: BilingualText(english: "The Annunciation", latin: "Annuntiátio"),
            fruit: BilingualText(english: "Humility", latin: "Humílitas"),
            scriptureReference: "Luke 1:26–38",
            scriptureExcerpt: BilingualText(
                english: "And in the sixth month, the angel Gabriel was sent from God into a city of Galilee, called Nazareth, to a virgin espoused to a man whose name was Joseph, of the house of David; and the virgin’s name was Mary. And the angel being come in, said unto her: Hail, full of grace, the Lord is with thee: blessed art thou among women.",
                latin: "In mense autem sexto, missus est ángelus Gábriel a Deo in civitátem Galilǽæ, cui nomen Názareth, ad vírginem desponsátam viro, cui nomen erat Ioseph, de domo David, et nomen vírginis María. Et ingréssus ángelus ad eam dixit: Ave, grátia plena, Dóminus tecum: benedícta tu in muliéribus."
            ),
            meditation: BilingualText(
                english: "Mary hears the angel’s greeting and gives her fiat. Ask for a humble heart that says yes to God without reserve.",
                latin: "María audit salutatiónem ángeli et dat suum fiat. Pete cor húmile quod Deo sine reservatióne dicit: fiat."
            )
        ),
        Mystery(
            id: "joyful-2",
            set: .joyful,
            number: 2,
            title: BilingualText(english: "The Visitation", latin: "Visitátio"),
            fruit: BilingualText(english: "Love of Neighbor", latin: "Cáritas erga próximum"),
            scriptureReference: "Luke 1:39–56",
            scriptureExcerpt: BilingualText(
                english: "And Mary rising up in those days, went into the hill country with haste into a city of Juda. And she entered into the house of Zachary, and saluted Elizabeth. And it came to pass, that when Elizabeth heard the salutation of Mary, the infant leaped in her womb.",
                latin: "Exsúrgens autem María in diébus illis ábiit in montána cum festinatióne in civitátem Iuda, et intrávit in domum Zacharíæ, et salutávit Elísabeth. Et factum est, ut audívit salutatiónem Maríæ Elísabeth, exsultávit infans in útero eius."
            ),
            meditation: BilingualText(
                english: "Mary carries Christ to Elizabeth in haste. Ask for charity that seeks the good of others, especially those who wait in hidden places.",
                latin: "María Christum ad Elísabeth festínans portat. Pete caritátem quæ aliórum bona quærit."
            )
        ),
        Mystery(
            id: "joyful-3",
            set: .joyful,
            number: 3,
            title: BilingualText(english: "The Nativity", latin: "Natívitas"),
            fruit: BilingualText(english: "Poverty of Spirit", latin: "Paupértas spíritus"),
            scriptureReference: "Luke 2:1–20",
            scriptureExcerpt: BilingualText(
                english: "And she brought forth her firstborn son, and wrapped him up in swaddling clothes, and laid him in a manger; because there was no room for them in the inn. And the angel said to them: Fear not; for, behold, I bring you good tidings of great joy… For this day is born to you a Saviour, who is Christ the Lord.",
                latin: "Et péperit fílium suum primogénitum, et pannis eum invólvit, et reclinávit eum in præsépio, quia non erat eis locus in diversório. Et dixit illis ángelus: Nolíte timére: ecce enim evangelízo vobis gáudium magnum… quia natus est vobis hódie Salvátor, qui est Christus Dóminus."
            ),
            meditation: BilingualText(
                english: "The Word is made flesh in poverty and quiet. Ask for detachment from comfort so that Christ may be born in you.",
                latin: "Verbum caro factum est in paupertáte et siléntio. Pete abnegatiónem a solátiis, ut Christus in te nascátur."
            )
        ),
        Mystery(
            id: "joyful-4",
            set: .joyful,
            number: 4,
            title: BilingualText(english: "The Presentation", latin: "Præsentátio"),
            fruit: BilingualText(english: "Purity of Heart and Body", latin: "Púritas cordis et córporis"),
            scriptureReference: "Luke 2:22–40",
            scriptureExcerpt: BilingualText(
                english: "And after the days of her purification, according to the law of Moses, were accomplished, they carried him to Jerusalem, to present him to the Lord: As it is written in the law of the Lord: Every male opening the womb shall be called holy to the Lord.",
                latin: "Et postquam impléti sunt dies purgatiónis eius secúndum legem Móysi, tulérunt illum in Ierúsalem, ut sísterent eum Dómino, sicut scriptum est in lege Dómini: Quia omne masculínum adaperiens vulvam sanctum Dómino vocábitur."
            ),
            meditation: BilingualText(
                english: "Jesus is offered in the Temple; Simeon and Anna recognize the Light. Offer your life to the Lord with a pure heart.",
                latin: "Iesus in Templo offértur; Simeon et Anna Lumen agnóscunt. Offers vitam tuam Dómino puro corde."
            )
        ),
        Mystery(
            id: "joyful-5",
            set: .joyful,
            number: 5,
            title: BilingualText(english: "The Finding in the Temple", latin: "Invéntio in Templo"),
            fruit: BilingualText(english: "Devotion to Jesus", latin: "Devótio erga Iesum"),
            scriptureReference: "Luke 2:41–52",
            scriptureExcerpt: BilingualText(
                english: "And it came to pass, that, after three days, they found him in the temple, sitting in the midst of the doctors, hearing them, and asking them questions. And all that heard him were astonished at his wisdom and his answers. And he said to them: How is it that you sought me? did you not know, that I must be about my Father’s business?",
                latin: "Et factum est, post tríduum invenérunt illum in templo sedéntem in médio doctórum, audiéntem illos et interrogántem eos. Stupébant autem omnes qui eum audiébant super prudéntia et respónsis eius. Et ait ad illos: Quid est quod me quærebátis? nesciebátis quia in his quæ Patris mei sunt opórtet me esse?"
            ),
            meditation: BilingualText(
                english: "After anxious searching, Mary and Joseph find Jesus in the Father’s house. Seek him first, even when he seems hidden.",
                latin: "Post ánxiam quæsitiónem, María et Ioseph Iesum in domo Patris invéniunt. Quære eum primum, étiam cum latére videátur."
            )
        )
    ]

    // MARK: - Sorrowful

    static let sorrowful: [Mystery] = [
        Mystery(
            id: "sorrowful-1",
            set: .sorrowful,
            number: 1,
            title: BilingualText(english: "The Agony in the Garden", latin: "Agonía in Horto"),
            fruit: BilingualText(english: "Obedience to God’s Will", latin: "Obœdiéntia voluntáti Dei"),
            scriptureReference: "Matthew 26:36–46",
            scriptureExcerpt: BilingualText(
                english: "Then Jesus came with them into a country place which is called Gethsemani; and he said to his disciples: Sit you here, till I go yonder and pray. And taking with him Peter and the two sons of Zebedee, he began to grow sorrowful and to be sad. Then he saith to them: My soul is sorrowful even unto death: stay you here, and watch with me. And going a little further, he fell upon his face, praying, and saying: My Father, if it be possible, let this chalice pass from me. Nevertheless not as I will, but as thou wilt.",
                latin: "Tunc venit Iesus cum illis in prædium quod dícitur Gethsémani, et dixit discípulis suis: Sedéte hic, donec vadam illuc et orem. Et assúmpto Petro et duóbus fíliis Zebedǽi, cœpit contristári et mæstus esse. Tunc ait illis: Tristis est ánima mea usque ad mortem; sustinéte hic, et vigiláte mecum. Et progréssus pusíllum, prócidit in fáciem suam, orans et dicens: Pater mi, si possíbile est, tránseat a me calix iste; verúmtamen non sicut ego volo, sed sicut tu."
            ),
            meditation: BilingualText(
                english: "Christ sweats blood and still consents to the Father’s cup. Watch with him, and ask for the grace to will what God wills.",
                latin: "Christus sánguinem sudat et tamen calicem Patris accípit. Vigila cum eo, et pete grátiam voléndi quod Deus vult."
            )
        ),
        Mystery(
            id: "sorrowful-2",
            set: .sorrowful,
            number: 2,
            title: BilingualText(english: "The Scourging at the Pillar", latin: "Flagellátio"),
            fruit: BilingualText(english: "Mortification", latin: "Mortificátio"),
            scriptureReference: "John 19:1; Matthew 27:26",
            scriptureExcerpt: BilingualText(
                english: "Then therefore, Pilate took Jesus, and scourged him. Then he released to them Barabbas, and having scourged Jesus, delivered him unto them to be crucified.",
                latin: "Tunc ergo apprehéndit Pilátus Iesum, et flagellávit. Tunc dimísit illis Barábbam: Iesum autem flagellátum trádidit eis ut crucifigerétur."
            ),
            meditation: BilingualText(
                english: "The innocent Lamb is struck for our sins. Ask for the courage to discipline disordered loves.",
                latin: "Agnus ínnocens pro peccátis nostris percutítur. Pete fortitúdinem ad ordinándas cupiditátes."
            )
        ),
        Mystery(
            id: "sorrowful-3",
            set: .sorrowful,
            number: 3,
            title: BilingualText(english: "The Crowning with Thorns", latin: "Coronátio Spinis"),
            fruit: BilingualText(english: "Courage", latin: "Fortitúdo"),
            scriptureReference: "Matthew 27:27–31",
            scriptureExcerpt: BilingualText(
                english: "Then the soldiers of the governor taking Jesus into the hall, gathered together unto him the whole band; and stripping him, they put a scarlet cloak about him. And platting a crown of thorns, they put it upon his head, and a reed in his right hand. And bowing the knee before him, they mocked him, saying: Hail, king of the Jews.",
                latin: "Tunc mílites prǽsidis suscipiéntes Iesum in prætórium, congregavérunt ad eum univérsam cohórtem; et eum exuéntes, chlámydem coccíneam circumdedérunt ei, et plecténtes corónam de spinis, posuérunt super caput eius, et arúndinem in déxtera eius. Et genu flexo ante eum, illudébant ei, dicéntes: Ave, rex Iudæórum."
            ),
            meditation: BilingualText(
                english: "The true King is mocked so that pride may be unmasked. Ask for moral courage when the world crowns what is false.",
                latin: "Verus Rex irridétur ut supérbia denudétur. Pete fortitúdinem morálem quando mundus falsa corónat."
            )
        ),
        Mystery(
            id: "sorrowful-4",
            set: .sorrowful,
            number: 4,
            title: BilingualText(english: "The Carrying of the Cross", latin: "Baiulátio Crucis"),
            fruit: BilingualText(english: "Patience", latin: "Patiéntia"),
            scriptureReference: "John 19:17; Luke 23:26–32",
            scriptureExcerpt: BilingualText(
                english: "And bearing his own cross, he went forth to that place which is called Calvary, but in Hebrew Golgotha. And as they led him away, they laid hold of one Simon of Cyrene, coming from the country; and they laid the cross on him to carry after Jesus.",
                latin: "Et báiulans sibi crucem exívit in eum qui dícitur Calváriæ locum, hebráice Gólgotha. Et cum dúcerent eum, apprehendérunt Simónem quemdam Cyrenénsem veniéntem de villa, et imposuérunt illi crucem portáre post Iesum."
            ),
            meditation: BilingualText(
                english: "Jesus walks the road of suffering and lets Simon help. Carry your cross with patience, and help others carry theirs.",
                latin: "Iesus viam passiónis ámbulat et Simónem ádiuvat. Porta crucem tuam cum patiéntia."
            )
        ),
        Mystery(
            id: "sorrowful-5",
            set: .sorrowful,
            number: 5,
            title: BilingualText(english: "The Crucifixion and Death of Our Lord", latin: "Crucifíxio"),
            fruit: BilingualText(english: "Sorrow for Sin", latin: "Dolor peccatórum"),
            scriptureReference: "John 19:18–30; Luke 23:33–46",
            scriptureExcerpt: BilingualText(
                english: "And when they were come to the place which is called Calvary, they crucified him there; and the robbers, one on the right hand, and the other on the left. And Jesus said: Father, forgive them, for they know not what they do. And Jesus crying with a loud voice, said: Father, into thy hands I commend my spirit. And saying this, he gave up the ghost.",
                latin: "Et postquam venérunt in locum qui vocátur Calváriæ, ibi crucifixérunt eum, et latrónes, unum a dextris et álterum a sinístris. Iesus autem dicébat: Pater, dimítte illis: non enim sciunt quid fáciunt. Et clamans voce magna Iesus ait: Pater, in manus tuas comméndo spíritum meum. Et hæc dicens, exspirávit."
            ),
            meditation: BilingualText(
                english: "From the Cross, Jesus forgives, promises Paradise, and gives his Mother to us. Look on him whom we have pierced, and ask for true contrition.",
                latin: "E cruce Iesus dimíttit, paradísum promíttit, Matrem nobis dat. Áspice in eum quem transfixérunt, et pete veram contritiónem."
            )
        )
    ]

    // MARK: - Glorious

    static let glorious: [Mystery] = [
        Mystery(
            id: "glorious-1",
            set: .glorious,
            number: 1,
            title: BilingualText(english: "The Resurrection", latin: "Resurréctio"),
            fruit: BilingualText(english: "Faith", latin: "Fides"),
            scriptureReference: "Matthew 28:1–10; Luke 24:1–12",
            scriptureExcerpt: BilingualText(
                english: "And on the first day of the week, very early in the morning, they came to the sepulchre, bringing the spices which they had prepared. And they found the stone rolled back from the sepulchre. And it came to pass, as they were astonished in their mind at this, behold, two men stood by them, in shining apparel. He is not here, but is risen.",
                latin: "Una autem sábbati valde dilúculo venérunt ad monuméntum, portántes quæ paráverant arómata. Et invenérunt lápidem revolútum a monuménto. Et factum est, dum mente consternátæ essent de isto, ecce duo viri stetérunt secus illas in veste fulgénti. Non est hic, sed surréxit."
            ),
            meditation: BilingualText(
                english: "The tomb is empty and death has lost its claim. Ask for living faith in the Risen Lord.",
                latin: "Sepúlcrum ináne est et mors ius perdidit. Pete fidem vivam in Dóminum resurgéntem."
            )
        ),
        Mystery(
            id: "glorious-2",
            set: .glorious,
            number: 2,
            title: BilingualText(english: "The Ascension", latin: "Ascénsio"),
            fruit: BilingualText(english: "Hope", latin: "Spes"),
            scriptureReference: "Acts 1:6–11; Mark 16:19",
            scriptureExcerpt: BilingualText(
                english: "And when he had said these things, while they looked on, he was raised up: and a cloud received him out of their sight. And while they were beholding him going up to heaven, behold two men stood by them in white garments, who also said: This Jesus who is taken up from you into heaven, shall so come, as you have seen him going into heaven.",
                latin: "Et cum hæc dixísset, vidéntibus illis, elevátus est, et nubes suscépit eum ab óculis eórum. Cumque intueréntur in cælum eúntem illum, ecce duo viri astitérunt iuxta illos in véstibus albis, qui et dixérunt: Hic Iesus, qui assúmptus est a vobis in cælum, sic véniet quemádmodum vidístis eum eúntem in cælum."
            ),
            meditation: BilingualText(
                english: "Christ takes our humanity into heaven and promises to return. Set your hope where he is seated.",
                latin: "Christus humanitátem nostram in cælum fert et redítum promíttit. Spem tuam ibi pono ubi sedet."
            )
        ),
        Mystery(
            id: "glorious-3",
            set: .glorious,
            number: 3,
            title: BilingualText(english: "The Descent of the Holy Spirit", latin: "Descénsus Spíritus Sancti"),
            fruit: BilingualText(english: "Wisdom", latin: "Sapiéntia"),
            scriptureReference: "Acts 2:1–13",
            scriptureExcerpt: BilingualText(
                english: "And when the days of the Pentecost were accomplished, they were all together in one place: And suddenly there came a sound from heaven, as of a mighty wind coming, and it filled the whole house where they were sitting. And there appeared to them parted tongues as it were of fire, and it sat upon every one of them: And they were all filled with the Holy Ghost.",
                latin: "Et cum compleréntur dies Pentecóstes, erant omnes páriter in eódem loco: et factus est repénte de cælo sonus tamquam adveniéntis spíritus veheméntis, et replévit totam domum ubi erant sedéntes. Et apparuérunt illis dispertítæ linguæ tamquam ignis, sedítque supra síngulos eórum: et repléti sunt omnes Spíritu Sancto."
            ),
            meditation: BilingualText(
                english: "Fire and wind fill the Upper Room; the Church is sent to every tongue. Ask for wisdom and the gifts of the Spirit.",
                latin: "Ignis et ventus Cenáculum implent; Ecclésia ad omnem linguam míttitur. Pete sapiéntiam et dona Spíritus."
            )
        ),
        Mystery(
            id: "glorious-4",
            set: .glorious,
            number: 4,
            title: BilingualText(english: "The Assumption", latin: "Assúmptio"),
            fruit: BilingualText(english: "Devotion to Mary", latin: "Devótio erga Maríam"),
            scriptureReference: "Luke 1:46–55; Revelation 12:1 (typological)",
            scriptureExcerpt: BilingualText(
                english: "And Mary said: My soul doth magnify the Lord. And my spirit hath rejoiced in God my Saviour. Because he hath regarded the humility of his handmaid; for behold from henceforth all generations shall call me blessed. Because he that is mighty, hath done great things to me; and holy is his name.",
                latin: "Et ait María: Magníficat ánima mea Dóminum: et exsultávit spíritus meus in Deo salutári meo. Quia respéxit humilitátem ancíllæ suæ: ecce enim ex hoc beátam me dicent omnes generatiónes. Quia fecit mihi magna qui potens est: et sanctum nomen eius."
            ),
            meditation: BilingualText(
                english: "Mary is taken body and soul into heaven, the first fruits of the Resurrection among the redeemed. Love her as Mother, and ask her to keep you faithful to the end.",
                latin: "María córpore et ánima in cælum assúmitur. Ama eam ut Matrem, et pete ut te fidélem usque in finem custódiat."
            )
        ),
        Mystery(
            id: "glorious-5",
            set: .glorious,
            number: 5,
            title: BilingualText(english: "The Coronation of Mary", latin: "Coronátio Beátæ Maríæ Vírginis"),
            fruit: BilingualText(english: "Grace of a Happy Death", latin: "Grátia bonæ mortis"),
            scriptureReference: "Revelation 12:1",
            scriptureExcerpt: BilingualText(
                english: "And a great sign appeared in heaven: A woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars.",
                latin: "Et signum magnum appáruit in cælo: múlier amícta sole, et luna sub pédibus eius, et in cápite eius coróna stellárum duódecim."
            ),
            meditation: BilingualText(
                english: "The Queen of Heaven is crowned beside her Son. Entrust your last hour to her, that you may die in the friendship of God.",
                latin: "Regína cæli iuxta Fílium coronátur. Novíssimam horam ei commítte, ut in amicítia Dei moriáris."
            )
        )
    ]

    // MARK: - Luminous

    static let luminous: [Mystery] = [
        Mystery(
            id: "luminous-1",
            set: .luminous,
            number: 1,
            title: BilingualText(english: "The Baptism in the Jordan", latin: "Baptísma in Iordáne"),
            fruit: BilingualText(english: "Openness to the Holy Spirit", latin: "Docílitas Spíritui Sancto"),
            scriptureReference: "Matthew 3:13–17",
            scriptureExcerpt: BilingualText(
                english: "And Jesus being baptized, forthwith came out of the water: and lo, the heavens were opened to him: and he saw the Spirit of God descending as a dove, and coming upon him. And behold a voice from heaven, saying: This is my beloved Son, in whom I am well pleased.",
                latin: "Baptizátus autem Iesus, conféstim ascéndit de aqua, et ecce apérti sunt ei cæli: et vidit Spíritum Dei descendéntem sicut colúmbam, et veniéntem super se. Et ecce vox de cælis dicens: Hic est Fílius meus diléctus, in quo mihi complacui."
            ),
            meditation: BilingualText(
                english: "The Trinity is revealed at the river. Remember your baptism, and remain open to the Spirit who rests on the Beloved Son.",
                latin: "Trínitas ad flumen revelátur. Memor esto baptísmatis tui, et Spíritui qui super Diléctum quiéscit te áperi."
            )
        ),
        Mystery(
            id: "luminous-2",
            set: .luminous,
            number: 2,
            title: BilingualText(english: "The Wedding at Cana", latin: "Núptiæ in Cana"),
            fruit: BilingualText(english: "To Jesus through Mary", latin: "Ad Iesum per Maríam"),
            scriptureReference: "John 2:1–12",
            scriptureExcerpt: BilingualText(
                english: "And the wine failing, the mother of Jesus saith to him: They have no wine. And Jesus saith to her: Woman, what is that to me and to thee? my hour is not yet come. His mother saith to the waiters: Whatsoever he shall say to you, do ye.",
                latin: "Et deficiénte vino, dicit mater Iesu ad eum: Vinum non habent. Et dicit ei Iesus: Quid mihi et tibi est, múlier? nondum venit hora mea. Dicit mater eius minístris: Quodcúmque díxerit vobis, fácite."
            ),
            meditation: BilingualText(
                english: "Mary notices the lack and points the servants to her Son. Go to Jesus through Mary, and do whatever he tells you.",
                latin: "María defectum conspicit et minístros ad Fílium mittit. I ad Iesum per Maríam, et quodcúmque díxerit tibi, fac."
            )
        ),
        Mystery(
            id: "luminous-3",
            set: .luminous,
            number: 3,
            title: BilingualText(english: "The Proclamation of the Kingdom", latin: "Proclamátio Regni"),
            fruit: BilingualText(english: "Conversion", latin: "Convérsio"),
            scriptureReference: "Mark 1:14–15; Matthew 4:17",
            scriptureExcerpt: BilingualText(
                english: "And after that John was delivered up, Jesus came into Galilee, preaching the gospel of the kingdom of God, and saying: The time is accomplished, and the kingdom of God is at hand: repent, and believe the gospel.",
                latin: "Postquam autem tráditus est Ioánnes, venit Iesus in Galilǽam, prædicans Evangélium regni Dei, et dicens: Quóniam implétum est tempus, et appropinquávit regnum Dei: pænitémini, et crédite Evangélio."
            ),
            meditation: BilingualText(
                english: "Jesus calls every heart to repent and believe. Ask for conversion that is more than a feeling: a turning toward the Kingdom.",
                latin: "Iesus omne cor ad pæniténtiam et fidem vocat. Pete conversiónem quæ ad Regnum se convértit."
            )
        ),
        Mystery(
            id: "luminous-4",
            set: .luminous,
            number: 4,
            title: BilingualText(english: "The Transfiguration", latin: "Transfigurátio"),
            fruit: BilingualText(english: "Desire for Holiness", latin: "Desidérium sanctitátis"),
            scriptureReference: "Matthew 17:1–8",
            scriptureExcerpt: BilingualText(
                english: "And after six days Jesus taketh unto him Peter and James, and John his brother, and bringeth them up into a high mountain apart: And he was transfigured before them. And his face did shine as the sun: and his garments became white as snow.",
                latin: "Et post dies sex assúmit Iesus Petrum, et Iacóbum, et Ioánnem fratrem eius, et ducit illos in montem excélsum seórsum: et transfigurátus est ante eos. Et resplénduit fácies eius sicut sol: vestiménta autem eius facta sunt alba sicut nix."
            ),
            meditation: BilingualText(
                english: "On Tabor the disciples glimpse the glory that waits beyond the Cross. Desire holiness; listen to the Beloved Son.",
                latin: "In Thabor discípuli glóriam ultra Crucem vident. Desidera sanctitátem; audi Fílium diléctum."
            )
        ),
        Mystery(
            id: "luminous-5",
            set: .luminous,
            number: 5,
            title: BilingualText(english: "The Institution of the Eucharist", latin: "Institútio Eucharístiæ"),
            fruit: BilingualText(english: "Adoration", latin: "Adorátio"),
            scriptureReference: "Matthew 26:26–29; Luke 22:14–20",
            scriptureExcerpt: BilingualText(
                english: "And whilst they were at supper, Jesus took bread, and blessed, and broke: and gave to his disciples, and said: Take ye, and eat. This is my body. And taking the chalice, he gave thanks, and gave to them, saying: Drink ye all of this. For this is my blood of the new testament, which shall be shed for many unto remission of sins.",
                latin: "Cœnántibus autem eis, accépit Iesus panem, et benedíxit, ac fregit, dedítque discípulis suis, et ait: Accípite, et comédite: hoc est corpus meum. Et accípiens cálicem, grátias egit, et dedit illis, dicens: Bíbite ex hoc omnes. Hic est enim sanguis meus novi testaménti, qui pro multis effundétur in remissiónem peccatórum."
            ),
            meditation: BilingualText(
                english: "On the night he was betrayed, Jesus gives his Body and Blood. Remain in adoration before the mystery of his abiding love.",
                latin: "In nocte qua tradebátur, Iesus Corpus et Sánguinem dat. Mane in adoratióne ante mystérium amóris manéntis."
            )
        )
    ]
}
