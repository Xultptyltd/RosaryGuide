package app.rosaryguide.core.data.catalog

/**
 * Feast-linked Scripture excerpts, ported from iOS `FeastScriptures`.
 * Mass proper when general, or traditional association. WEB-Catholic wording.
 */
data class FeastScripturePassage(
    val id: String,
    val citation: String,
    val heading: String,
    val text: String,
)

object FeastScriptures {
    fun passages(id: String): List<FeastScripturePassage> = table[id].orEmpty()

    val coveredIds: Set<String> get() = table.keys

    private val table: Map<String, List<FeastScripturePassage>> = mapOf(
        "mary-mother-of-god" to listOf(
            FeastScripturePassage(
                id = "mmog-1",
                citation = "Galatians 4:4-5",
                heading = "From the Second Reading",
                text = """But when the fullness of the time came, God sent out his Son, born to a woman, born under the law, that he might redeem those who were under the law, that we might receive the adoption as children.""",
            ),
            FeastScripturePassage(
                id = "mmog-2",
                citation = "Luke 2:16-19",
                heading = "From the Gospel",
                text = """They came with haste and found both Mary and Joseph, and the baby was lying in the feeding trough. When they saw it, they publicized widely the saying which was spoken to them about this child. All who heard it wondered at the things which were spoken to them by the shepherds. But Mary kept all these sayings, pondering them in her heart.""",
            )
        ),
        "epiphany" to listOf(
            FeastScripturePassage(
                id = "eph-1",
                citation = "Isaiah 60:1-3",
                heading = "From the First Reading",
                text = """“Arise, shine; for your light has come, and the LORD’s glory has risen on you! For behold, darkness will cover the earth, and thick darkness the peoples; but the LORD will arise on you, and his glory shall be seen on you. Nations will come to your light, and kings to the brightness of your rising.”""",
            ),
            FeastScripturePassage(
                id = "eph-2",
                citation = "Matthew 2:1-2, 11",
                heading = "From the Gospel",
                text = """Now when Jesus was born in Bethlehem of Judea in the days of King Herod, behold, wise men from the east came to Jerusalem, saying, “Where is he who is born King of the Jews? For we saw his star in the east, and have come to worship him.” … They came into the house and saw the young child with Mary, his mother, and they fell down and worshiped him.""",
            )
        ),
        "mother-of-the-church" to listOf(
            FeastScripturePassage(
                id = "motc-1",
                citation = "John 19:25-27",
                heading = "From the Gospel",
                text = """But standing by Jesus’ cross were his mother, his mother’s sister, Mary the wife of Clopas, and Mary Magdalene. Therefore when Jesus saw his mother, and the disciple whom he loved standing there, he said to his mother, “Woman, behold, your son!” Then he said to the disciple, “Behold, your mother!” From that hour, the disciple took her to his own home.""",
            ),
            FeastScripturePassage(
                id = "motc-2",
                citation = "Acts 1:14",
                heading = "Associated reading",
                text = """All these with one accord continued steadfastly in prayer and supplication, along with the women and Mary the mother of Jesus, and with his brothers.""",
            )
        ),
        "baptism-movable" to listOf(
            FeastScripturePassage(
                id = "bap-1",
                citation = "Isaiah 42:1",
                heading = "From the First Reading",
                text = """“Behold, my servant, whom I uphold, my chosen, in whom my soul delights: I have put my Spirit on him. He will bring justice to the nations.”""",
            ),
            FeastScripturePassage(
                id = "bap-2",
                citation = "Matthew 3:16-17",
                heading = "From the Gospel",
                text = """Jesus, when he was baptized, went up directly from the water: and behold, the heavens were opened to him. He saw the Spirit of God descending as a dove, and coming on him. Behold, a voice out of the heavens said, “This is my beloved Son, with whom I am well pleased.”""",
            )
        ),
        "presentation" to listOf(
            FeastScripturePassage(
                id = "pres-1",
                citation = "Malachi 3:1",
                heading = "From the First Reading",
                text = """“Behold, I send my messenger, and he will prepare the way before me! The Lord, whom you seek, will suddenly come to his temple. Behold, the messenger of the covenant, whom you desire, is coming!” says the LORD of Armies.""",
            ),
            FeastScripturePassage(
                id = "pres-2",
                citation = "Luke 2:22, 29-32",
                heading = "From the Gospel",
                text = """When the days of their purification according to the law of Moses were fulfilled, they brought him up to Jerusalem to present him to the Lord… “Now you are releasing your servant, Master, according to your word, in peace; for my eyes have seen your salvation, which you have prepared before the face of all peoples; a light for revelation to the nations, and the glory of your people Israel.”""",
            )
        ),
        "lourdes" to listOf(
            FeastScripturePassage(
                id = "lou-1",
                citation = "Genesis 3:15",
                heading = "First Reading (associated)",
                text = """I will put hostility between you and the woman, and between your offspring and her offspring. He will bruise your head, and you will bruise his heel.""",
            ),
            FeastScripturePassage(
                id = "lou-2",
                citation = "Luke 1:28, 30-31",
                heading = "Gospel (Common of the BVM)",
                text = """Having come in, the angel said to her, “Rejoice, you highly favored one! The Lord is with you. Blessed are you among women!” … The angel said to her, “Don’t be afraid, Mary, for you have found favor with God. Behold, you will conceive in your womb and give birth to a son, and shall name him ‘Jesus.’”""",
            )
        ),
        "ash-wednesday" to listOf(
            FeastScripturePassage(
                id = "ash-1",
                citation = "Joel 2:12-13",
                heading = "From the First Reading",
                text = """“Yet even now,” says the LORD, “turn to me with all your heart, and with fasting, and with weeping, and with mourning.” Tear your heart and not your garments, and turn to the LORD, your God; for he is gracious and merciful, slow to anger, and abundant in loving kindness, and relents from sending calamity.""",
            ),
            FeastScripturePassage(
                id = "ash-2",
                citation = "Matthew 6:16-18",
                heading = "From the Gospel",
                text = """“Moreover when you fast, don’t be like the hypocrites, with sad faces. For they disfigure their faces that they may be seen by men to be fasting. Most certainly I tell you, they have received their reward. But you, when you fast, anoint your head and wash your face, so that you are not seen by men to be fasting, but by your Father who is in secret; and your Father, who sees in secret, will reward you.”""",
            )
        ),
        "joseph" to listOf(
            FeastScripturePassage(
                id = "jos-1",
                citation = "2 Samuel 7:12, 16",
                heading = "From the First Reading",
                text = """When your days are fulfilled and you sleep with your fathers, I will set up your offspring after you, who will proceed out of your body, and I will establish his kingdom. … Your house and your kingdom will be made sure forever before you. Your throne will be established forever.""",
            ),
            FeastScripturePassage(
                id = "jos-2",
                citation = "Matthew 1:20-21, 24",
                heading = "From the Gospel",
                text = """But when he thought about these things, behold, an angel of the Lord appeared to him in a dream, saying, “Joseph, son of David, don’t be afraid to take to yourself Mary as your wife, for that which is conceived in her is of the Holy Spirit. She shall give birth to a son. You shall name him Jesus, for it is he who shall save his people from their sins.” … Joseph arose from his sleep, and did as the angel of the Lord commanded him…""",
            )
        ),
        "annunciation" to listOf(
            FeastScripturePassage(
                id = "ann-1",
                citation = "Isaiah 7:14",
                heading = "From the First Reading",
                text = """Therefore the Lord himself will give you a sign. Behold, the virgin will conceive, and bear a son, and shall call his name Immanuel.""",
            ),
            FeastScripturePassage(
                id = "ann-2",
                citation = "Luke 1:26-28, 38",
                heading = "From the Gospel",
                text = """Now in the sixth month, the angel Gabriel was sent from God to a city of Galilee named Nazareth, to a virgin pledged to be married to a man whose name was Joseph, of David’s house. The virgin’s name was Mary. Having come in, the angel said to her, “Rejoice, you highly favored one! The Lord is with you. Blessed are you among women!” … Mary said, “Behold, the servant of the Lord; let it be done to me according to your word.”""",
            )
        ),
        "palm-sunday" to listOf(
            FeastScripturePassage(
                id = "palm-1",
                citation = "Philippians 2:6-8",
                heading = "From the Second Reading",
                text = """who, existing in the form of God, didn’t consider equality with God a thing to be grasped, but emptied himself, taking the form of a servant, being made in the likeness of men. And being found in human form, he humbled himself, becoming obedient to the point of death, yes, the death of the cross.""",
            ),
            FeastScripturePassage(
                id = "palm-2",
                citation = "Matthew 21:9",
                heading = "From the Gospel at the Procession",
                text = """The multitudes who went in front of him, and those who followed, kept shouting, “Hosanna to the son of David! Blessed is he who comes in the name of the Lord! Hosanna in the highest!”""",
            )
        ),
        "holy-thursday" to listOf(
            FeastScripturePassage(
                id = "ht-1",
                citation = "1 Corinthians 11:23-25",
                heading = "From the Second Reading",
                text = """For I received from the Lord that which also I delivered to you, that the Lord Jesus on the night in which he was betrayed took bread. When he had given thanks, he broke it and said, “Take, eat. This is my body, which is broken for you. Do this in memory of me.” In the same way he also took the cup after supper, saying, “This cup is the new covenant in my blood. Do this, as often as you drink, in memory of me.”""",
            ),
            FeastScripturePassage(
                id = "ht-2",
                citation = "John 13:14-15",
                heading = "From the Gospel",
                text = """If I then, the Lord and the Teacher, have washed your feet, you also ought to wash one another’s feet. For I have given you an example, that you should also do as I have done to you.""",
            )
        ),
        "good-friday" to listOf(
            FeastScripturePassage(
                id = "gf-1",
                citation = "Isaiah 53:4-5",
                heading = "From the First Reading",
                text = """Surely he has borne our sickness and carried our suffering; yet we considered him plagued, struck by God, and afflicted. But he was pierced for our transgressions. He was crushed for our iniquities. The punishment that brought our peace was on him; and by his wounds we are healed.""",
            ),
            FeastScripturePassage(
                id = "gf-2",
                citation = "John 19:26-27, 30",
                heading = "From the Gospel",
                text = """Therefore when Jesus saw his mother, and the disciple whom he loved standing there, he said to his mother, “Woman, behold, your son!” Then he said to the disciple, “Behold, your mother!” From that hour, the disciple took her to his own home. … When Jesus therefore had received the vinegar, he said, “It is finished!” Then he bowed his head and gave up his spirit.""",
            )
        ),
        "holy-saturday" to listOf(
            FeastScripturePassage(
                id = "hs-1",
                citation = "Romans 6:3-4",
                heading = "From the Easter Vigil (Epistle)",
                text = """Or don’t you know that all of us who were baptized into Christ Jesus were baptized into his death? We were buried therefore with him through baptism into death, that just as Christ was raised from the dead through the glory of the Father, so we also might walk in newness of life.""",
            ),
            FeastScripturePassage(
                id = "hs-2",
                citation = "Matthew 28:5-6",
                heading = "From the Easter Vigil (Gospel)",
                text = """The angel answered the women, “Don’t be afraid, for I know that you seek Jesus, who has been crucified. He is not here, for he has risen, just like he said. Come, see the place where the Lord was lying.”""",
            )
        ),
        "easter" to listOf(
            FeastScripturePassage(
                id = "eas-1",
                citation = "Colossians 3:1-4",
                heading = "From the Second Reading",
                text = """If then you were raised together with Christ, seek the things that are above, where Christ is, seated on the right hand of God. Set your mind on the things that are above, not on the things that are on the earth. For you died, and your life is hidden with Christ in God. When Christ, our life, is revealed, then you will also be revealed with him in glory.""",
            ),
            FeastScripturePassage(
                id = "eas-2",
                citation = "John 20:1, 6-8",
                heading = "From the Gospel",
                text = """Now on the first day of the week, Mary Magdalene went early, while it was still dark, to the tomb, and saw that the stone had been taken away from the tomb. … Then Simon Peter came, following him, and entered into the tomb. He saw the linen cloths lying, and the cloth that had been on his head, not lying with the linen cloths, but rolled up in a place by itself. So then the other disciple who came first to the tomb also entered in, and he saw and believed.""",
            )
        ),
        "divine-mercy" to listOf(
            FeastScripturePassage(
                id = "dm-1",
                citation = "1 John 5:4-6",
                heading = "Second Reading (associated)",
                text = """For whatever is born of God overcomes the world. This is the victory that has overcome the world: your faith. Who is he who overcomes the world, but he who believes that Jesus is the Son of God? This is he who came by water and blood, Jesus Christ; not with the water only, but with the water and the blood.""",
            ),
            FeastScripturePassage(
                id = "dm-2",
                citation = "John 20:19-22, 27-28",
                heading = "From the Gospel",
                text = """When therefore it was evening on that day, the first day of the week, and when the doors were locked where the disciples were assembled, for fear of the Jews, Jesus came and stood in the middle and said to them, “Peace be to you.” … When he had said this, he breathed on them, and said to them, “Receive the Holy Spirit!” … Then he said to Thomas, “Reach here your finger, and see my hands. Reach here your hand, and put it into my side. Don’t be unbelieving, but believing.” Thomas answered him, “My Lord and my God!”""",
            )
        ),
        "fatima" to listOf(
            FeastScripturePassage(
                id = "fat-1",
                citation = "Revelation 12:1",
                heading = "First Reading (associated)",
                text = """A great sign was seen in heaven: a woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars.""",
            ),
            FeastScripturePassage(
                id = "fat-2",
                citation = "Luke 1:38",
                heading = "Gospel (Common of the BVM)",
                text = """Mary said, “Behold, the servant of the Lord; let it be done to me according to your word.” Then the angel departed from her.""",
            )
        ),
        "ascension" to listOf(
            FeastScripturePassage(
                id = "asc-1",
                citation = "Acts 1:8-11",
                heading = "From the First Reading",
                text = """But you will receive power when the Holy Spirit has come upon you. You will be witnesses to me in Jerusalem, in all Judea and Samaria, and to the uttermost parts of the earth.” When he had said these things, as they were looking, he was taken up, and a cloud received him out of their sight. While they were looking steadfastly into the sky as he went, behold, two men stood by them in white clothing, who also said, “You men of Galilee, why do you stand looking into the sky? This Jesus, who was received up from you into the sky, will come back in the same way as you saw him going into the sky.""",
            ),
            FeastScripturePassage(
                id = "asc-2",
                citation = "Mark 16:15, 19",
                heading = "From the Gospel",
                text = """He said to them, “Go into all the world and preach the Good News to the whole creation.” … So then the Lord, after he had spoken to them, was received up into heaven and sat down at the right hand of God.""",
            )
        ),
        "pentecost" to listOf(
            FeastScripturePassage(
                id = "pen-1",
                citation = "Acts 2:1-4",
                heading = "From the First Reading",
                text = """Now when the day of Pentecost had come, they were all with one accord in one place. Suddenly there came from the sky a sound like the rushing of a mighty wind, and it filled all the house where they were sitting. Tongues like fire appeared and were distributed to them, and one sat on each of them. They were all filled with the Holy Spirit and began to speak with other languages, as the Spirit gave them the ability to speak.""",
            ),
            FeastScripturePassage(
                id = "pen-2",
                citation = "John 20:21-22",
                heading = "From the Gospel",
                text = """Jesus therefore said to them again, “Peace be to you. As the Father has sent me, even so I send you.” When he had said this, he breathed on them, and said to them, “Receive the Holy Spirit!”""",
            )
        ),
        "visitation" to listOf(
            FeastScripturePassage(
                id = "vis-1",
                citation = "Zephaniah 3:14, 17",
                heading = "From the First Reading",
                text = """Sing, daughter of Zion! Shout, Israel! Be glad and rejoice with all your heart, daughter of Jerusalem. … The LORD, your God, is among you, a mighty one who will save. He will rejoice over you with joy. He will calm you in his love.""",
            ),
            FeastScripturePassage(
                id = "vis-2",
                citation = "Luke 1:39-42, 46-47",
                heading = "From the Gospel",
                text = """Mary arose in those days and went into the hill country with haste, into a city of Judah, and entered into the house of Zacharias and greeted Elizabeth. When Elizabeth heard Mary’s greeting, the baby leaped in her womb; and Elizabeth was filled with the Holy Spirit. She called out with a loud voice and said, “Blessed are you among women, and blessed is the fruit of your womb!” … Mary said, “My soul magnifies the Lord. My spirit has rejoiced in God my Savior…”""",
            )
        ),
        "trinity" to listOf(
            FeastScripturePassage(
                id = "tri-1",
                citation = "Romans 5:1-2, 5",
                heading = "From the Second Reading",
                text = """Being therefore justified by faith, we have peace with God through our Lord Jesus Christ; through whom we also have our access by faith into this grace in which we stand. We rejoice in hope of the glory of God. … and hope doesn’t disappoint us, because God’s love has been poured into our hearts through the Holy Spirit who was given to us.""",
            ),
            FeastScripturePassage(
                id = "tri-2",
                citation = "Matthew 28:18-20",
                heading = "From the Gospel",
                text = """Jesus came to them and spoke to them, saying, “All authority has been given to me in heaven and on earth. Go and make disciples of all nations, baptizing them in the name of the Father and of the Son and of the Holy Spirit, teaching them to observe all things that I commanded you. Behold, I am with you always, even to the end of the age.” Amen.""",
            )
        ),
        "corpus-christi" to listOf(
            FeastScripturePassage(
                id = "cc-1",
                citation = "1 Corinthians 10:16-17",
                heading = "From the Second Reading",
                text = """The cup of blessing which we bless, isn’t it a sharing of the blood of Christ? The bread which we break, isn’t it a sharing of the body of Christ? Because there is one loaf of bread, we, who are many, are one body; for we all partake of the one loaf of bread.""",
            ),
            FeastScripturePassage(
                id = "cc-2",
                citation = "John 6:51",
                heading = "From the Gospel",
                text = """I am the living bread which came down out of heaven. If anyone eats of this bread, he will live forever. Yes, the bread which I will give for the life of the world is my flesh.""",
            )
        ),
        "sacred-heart" to listOf(
            FeastScripturePassage(
                id = "sh-1",
                citation = "Hosea 11:3-4",
                heading = "From the First Reading",
                text = """Yet I taught Ephraim to walk. I took them by their arms, but they didn’t know that I healed them. I drew them with cords of a man, with ties of love; and I was to them like those who lift up the yoke on their necks; and I bent down to him and I fed him.""",
            ),
            FeastScripturePassage(
                id = "sh-2",
                citation = "John 19:34-37",
                heading = "From the Gospel",
                text = """However, one of the soldiers pierced his side with a spear, and immediately blood and water came out. He who has seen has testified, and his testimony is true. He knows that he tells the truth, that you may believe. For these things happened that the Scripture might be fulfilled, “A bone of him will not be broken.” Again another Scripture says, “They will look on him whom they pierced.”""",
            )
        ),
        "immaculate-heart" to listOf(
            FeastScripturePassage(
                id = "ih-1",
                citation = "Isaiah 61:9-10",
                heading = "First Reading (associated)",
                text = """Their offspring will be known among the nations, and their offspring among the peoples. All who see them will acknowledge them, that they are the offspring which the LORD has blessed. … I will greatly rejoice in the LORD! My soul will be joyful in my God…""",
            ),
            FeastScripturePassage(
                id = "ih-2",
                citation = "Luke 2:51",
                heading = "From the Gospel",
                text = """And he went down with them and came to Nazareth. He was subject to them, and his mother kept all these sayings in her heart.""",
            )
        ),
        "peter-paul" to listOf(
            FeastScripturePassage(
                id = "pp-1",
                citation = "Acts 12:5-7, 11",
                heading = "From the First Reading",
                text = """Peter therefore was kept in the prison, but constant prayer was made by the assembly to God for him. The same night when Herod was about to bring him out, Peter was sleeping between two soldiers, bound with two chains. Guards in front of the door kept the prison. And behold, an angel of the Lord stood by him, and a light shone in the cell. He struck Peter on the side and woke him up, saying, “Stand up quickly!” His chains fell off his hands. … When Peter had come to himself, he said, “Now I truly know that the Lord has sent out his angel and delivered me…”""",
            ),
            FeastScripturePassage(
                id = "pp-2",
                citation = "Matthew 16:16-18",
                heading = "From the Gospel",
                text = """Simon Peter answered, “You are the Christ, the Son of the living God.” Jesus answered him, “Blessed are you, Simon Bar Jonah, for flesh and blood has not revealed this to you, but my Father who is in heaven. I also tell you that you are Peter, and on this rock I will build my assembly, and the gates of Hades will not prevail against it.”""",
            )
        ),
        "carmel" to listOf(
            FeastScripturePassage(
                id = "car-1",
                citation = "1 Kings 18:36-39",
                heading = "Classic associated (Elijah on Carmel)",
                text = """At the time of the evening offering, Elijah the prophet came near and said, “LORD, the God of Abraham, of Isaac, and of Israel, let it be known today that you are God in Israel and that I am your servant, and that I have done all these things at your word.” … Then the LORD’s fire fell and consumed the burnt offering, the wood, the stones, and the dust; and it licked up the water that was in the trench. When all the people saw it, they fell on their faces. They said, “The LORD, he is God! The LORD, he is God!”""",
            ),
            FeastScripturePassage(
                id = "car-2",
                citation = "Luke 11:27-28",
                heading = "Gospel (Common of the BVM)",
                text = """It came to pass, as he said these things, a certain woman out of the multitude lifted up her voice and said to him, “Blessed is the womb that bore you, and the breasts which nursed you!” But he said, “On the contrary, blessed are those who hear the word of God, and keep it.”""",
            )
        ),
        "assumption" to listOf(
            FeastScripturePassage(
                id = "ass-1",
                citation = "Revelation 11:19a; 12:1",
                heading = "From the First Reading",
                text = """God’s temple that is in heaven was opened, and the ark of the Lord’s covenant was seen in his temple. … A great sign was seen in heaven: a woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars.""",
            ),
            FeastScripturePassage(
                id = "ass-2",
                citation = "Luke 1:46-49",
                heading = "From the Gospel",
                text = """Mary said, “My soul magnifies the Lord. My spirit has rejoiced in God my Savior, for he has looked at the humble state of his servant. For behold, from now on, all generations will call me blessed. For he who is mighty has done great things for me. Holy is his name.”""",
            )
        ),
        "queenship" to listOf(
            FeastScripturePassage(
                id = "que-1",
                citation = "Revelation 12:1, 5",
                heading = "First Reading (associated)",
                text = """A great sign was seen in heaven: a woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars. … She gave birth to a son, a male child, who is to rule all the nations with a rod of iron. Her child was caught up to God and to his throne.""",
            ),
            FeastScripturePassage(
                id = "que-2",
                citation = "Luke 1:30-33",
                heading = "From the Gospel",
                text = """The angel said to her, “Don’t be afraid, Mary, for you have found favor with God. Behold, you will conceive in your womb and give birth to a son, and shall name him ‘Jesus.’ He will be great and will be called the Son of the Most High. The Lord God will give him the throne of his father David, and he will reign over the house of Jacob forever. There will be no end to his Kingdom.”""",
            )
        ),
        "nativity-mary" to listOf(
            FeastScripturePassage(
                id = "nm-1",
                citation = "Micah 5:2-4a",
                heading = "From the First Reading",
                text = """But you, Bethlehem Ephrathah, being small among the clans of Judah, out of you one will come out to me who is to be ruler in Israel; whose goings out are from of old, from ancient times. Therefore he will abandon them until the time that she who is in labor gives birth. Then the rest of his brothers will return to the children of Israel. He shall stand, and shall shepherd in the strength of the LORD…""",
            ),
            FeastScripturePassage(
                id = "nm-2",
                citation = "Matthew 1:16, 18",
                heading = "From the Gospel",
                text = """Jacob became the father of Joseph, the husband of Mary, from whom was born Jesus, who is called Christ. … Now the birth of Jesus Christ was like this: After his mother, Mary, was engaged to Joseph, before they came together, she was found pregnant by the Holy Spirit.""",
            )
        ),
        "holy-name-mary" to listOf(
            FeastScripturePassage(
                id = "hnm-1",
                citation = "Sirach 24:19-20",
                heading = "First Reading (associated)",
                text = """“Come to me, all you who desire me, and be filled with my fruits. For my memory is sweeter than honey, and my inheritance than the honeycomb.”""",
            ),
            FeastScripturePassage(
                id = "hnm-2",
                citation = "Luke 1:26-27, 30-31",
                heading = "From the Gospel",
                text = """Now in the sixth month, the angel Gabriel was sent from God to a city of Galilee named Nazareth, to a virgin pledged to be married to a man whose name was Joseph, of David’s house. The virgin’s name was Mary. … The angel said to her, “Don’t be afraid, Mary, for you have found favor with God. Behold, you will conceive in your womb and give birth to a son, and shall name him ‘Jesus.’”""",
            )
        ),
        "sorrows" to listOf(
            FeastScripturePassage(
                id = "sor-1",
                citation = "Hebrews 5:7-9",
                heading = "From the First Reading",
                text = """He, in the days of his flesh, having offered up prayers and petitions with strong crying and tears to him who was able to save him from death, and having been heard for his godly fear, though he was a Son, yet learned obedience by the things which he suffered. Having been made perfect, he became to all of those who obey him the author of eternal salvation…""",
            ),
            FeastScripturePassage(
                id = "sor-2",
                citation = "John 19:25-27",
                heading = "From the Gospel",
                text = """But standing by Jesus’ cross were his mother, his mother’s sister, Mary the wife of Clopas, and Mary Magdalene. Therefore when Jesus saw his mother, and the disciple whom he loved standing there, he said to his mother, “Woman, behold, your son!” Then he said to the disciple, “Behold, your mother!” From that hour, the disciple took her to his own home.""",
            ),
            FeastScripturePassage(
                id = "sor-3",
                citation = "Luke 2:34-35",
                heading = "Classic associated",
                text = """Simeon blessed them, and said to Mary, his mother, “Behold, this child is appointed for the falling and the rising of many in Israel, and for a sign which is spoken against. Yes, a sword will pierce through your own soul, that the thoughts of many hearts may be revealed.”""",
            )
        ),
        "michael" to listOf(
            FeastScripturePassage(
                id = "mic-1",
                citation = "Revelation 12:7-9",
                heading = "From the First Reading",
                text = """There was war in the sky. Michael and his angels made war on the dragon. The dragon and his angels made war. They didn’t prevail. No place was found for them any more in heaven. The great dragon was thrown down, the old serpent, he who is called the devil and Satan, the deceiver of the whole world. He was thrown down to the earth, and his angels were thrown down with him.""",
            ),
            FeastScripturePassage(
                id = "mic-2",
                citation = "John 1:51",
                heading = "From the Gospel",
                text = """He said to him, “Most certainly, I tell you all, hereafter you will see heaven opened, and the angels of God ascending and descending on the Son of Man.”""",
            ),
            FeastScripturePassage(
                id = "mic-3",
                citation = "Luke 1:26, 28",
                heading = "Gabriel (classic associated)",
                text = """Now in the sixth month, the angel Gabriel was sent from God to a city of Galilee named Nazareth… Having come in, the angel said to her, “Rejoice, you highly favored one! The Lord is with you. Blessed are you among women!”""",
            ),
            FeastScripturePassage(
                id = "mic-4",
                citation = "Tobit 12:15",
                heading = "Raphael (classic associated)",
                text = """I am Raphael, one of the seven holy angels which present the prayers of the saints and go in before the glory of the Holy One.""",
            )
        ),
        "guardian-angels" to listOf(
            FeastScripturePassage(
                id = "ga-1",
                citation = "Exodus 23:20-21",
                heading = "From the First Reading",
                text = """“Behold, I send an angel before you, to keep you by the way, and to bring you into the place which I have prepared. Pay attention to him, and listen to his voice. Don’t provoke him, for he will not pardon your disobedience, for my name is in him.”""",
            ),
            FeastScripturePassage(
                id = "ga-2",
                citation = "Matthew 18:1-5, 10",
                heading = "From the Gospel",
                text = """In that hour the disciples came to Jesus, saying, “Who then is greatest in the Kingdom of Heaven?” Jesus called a little child to himself, and set him in the middle of them and said, “Most certainly I tell you, unless you turn and become as little children, you will in no way enter into the Kingdom of Heaven. Whoever therefore humbles himself as this little child is the greatest in the Kingdom of Heaven. Whoever receives one such little child in my name receives me…” … See that you don’t despise one of these little ones, for I tell you that in heaven their angels always see the face of my Father who is in heaven.""",
            )
        ),
        "rosary" to listOf(
            FeastScripturePassage(
                id = "ros-1",
                citation = "Acts 1:12, 14",
                heading = "First Reading (associated)",
                text = """Then they returned to Jerusalem from the mountain called Olivet, which is near Jerusalem, a Sabbath day’s journey away. … All these with one accord continued steadfastly in prayer and supplication, along with the women and Mary the mother of Jesus, and with his brothers.""",
            ),
            FeastScripturePassage(
                id = "ros-2",
                citation = "Luke 1:28, 42",
                heading = "Gospel roots of the Hail Mary",
                text = """Having come in, the angel said to her, “Rejoice, you highly favored one! The Lord is with you. Blessed are you among women!” … She called out with a loud voice and said, “Blessed are you among women, and blessed is the fruit of your womb!”""",
            )
        ),
        "all-saints" to listOf(
            FeastScripturePassage(
                id = "as-1",
                citation = "Revelation 7:9-10",
                heading = "From the First Reading",
                text = """After these things I looked, and behold, a great multitude which no man could count, out of every nation and of all tribes, peoples, and languages, standing before the throne and before the Lamb, dressed in white robes, with palm branches in their hands. They cried with a loud voice, saying, “Salvation be to our God, who sits on the throne, and to the Lamb!”""",
            ),
            FeastScripturePassage(
                id = "as-2",
                citation = "Matthew 5:3-10",
                heading = "From the Gospel",
                text = """“Blessed are the poor in spirit, for theirs is the Kingdom of Heaven. Blessed are those who mourn, for they shall be comforted. Blessed are the gentle, for they shall inherit the earth. Blessed are those who hunger and thirst for righteousness, for they shall be filled. Blessed are the merciful, for they shall obtain mercy. Blessed are the pure in heart, for they shall see God. Blessed are the peacemakers, for they shall be called children of God. Blessed are those who have been persecuted for righteousness’ sake, for theirs is the Kingdom of Heaven.”""",
            )
        ),
        "all-souls" to listOf(
            FeastScripturePassage(
                id = "aso-1",
                citation = "Wisdom 3:1-3",
                heading = "From the First Reading",
                text = """But the souls of the righteous are in the hand of God, and no torment will touch them. In the eyes of the foolish they seemed to have died. Their departure was considered a disaster, and their travel away from us ruin, but they are in peace.""",
            ),
            FeastScripturePassage(
                id = "aso-2",
                citation = "John 6:37-40",
                heading = "From the Gospel",
                text = """All those whom the Father gives me will come to me. He who comes to me I will in no way throw out. For I have come down from heaven, not to do my own will, but the will of him who sent me. This is the will of my Father who sent me, that of all he has given to me I should lose nothing, but should raise him up at the last day. This is the will of the one who sent me, that everyone who sees the Son and believes in him should have eternal life; and I will raise him up at the last day.""",
            )
        ),
        "presentation-mary" to listOf(
            FeastScripturePassage(
                id = "pm-1",
                citation = "Zechariah 2:10-11",
                heading = "First Reading (associated)",
                text = """Sing and rejoice, daughter of Zion! For behold, I come and I will dwell within you,’ says the LORD. Many nations shall join themselves to the LORD in that day, and shall be my people; and I will dwell among you, and you shall know that the LORD of Armies has sent me to you.""",
            ),
            FeastScripturePassage(
                id = "pm-2",
                citation = "Matthew 12:50",
                heading = "Gospel (associated)",
                text = """For whoever does the will of my Father who is in heaven, he is my brother, and sister, and mother.""",
            )
        ),
        "christ-the-king" to listOf(
            FeastScripturePassage(
                id = "ctk-1",
                citation = "Daniel 7:13-14",
                heading = "From the First Reading",
                text = """“I saw in the night visions, and behold, one like a son of man came with the clouds, and he came to the Ancient of Days, and they brought him near before him. Dominion was given him, with glory and a kingdom, that all the peoples, nations, and languages should serve him. His dominion is an everlasting dominion, which will not pass away, and his kingdom will not be destroyed.”""",
            ),
            FeastScripturePassage(
                id = "ctk-2",
                citation = "John 18:36-37",
                heading = "From the Gospel",
                text = """Jesus answered, “My Kingdom is not of this world. If my Kingdom were of this world, then my servants would fight, that I wouldn’t be delivered to the Jews. But now my Kingdom is not from here.” Pilate therefore said to him, “Are you a king then?” Jesus answered, “You say that I am a king. For this reason I have been born, and for this reason I have come into the world, that I should testify to the truth. Everyone who is of the truth listens to my voice.”""",
            )
        ),
        "advent-1" to listOf(
            FeastScripturePassage(
                id = "adv-1",
                citation = "Isaiah 2:3-5",
                heading = "From the First Reading",
                text = """Many peoples shall go and say, “Come, let’s go up to the mountain of the LORD, to the house of the God of Jacob; and he will teach us of his ways, and we will walk in his paths.” For the law shall go out of Zion, and the LORD’s word from Jerusalem. He will judge between the nations, and will decide concerning many peoples. They shall beat their swords into plowshares, and their spears into pruning hooks. Nation shall not lift up sword against nation, neither shall they learn war any more. House of Jacob, come, and let’s walk in the light of the LORD.""",
            ),
            FeastScripturePassage(
                id = "adv-2",
                citation = "Matthew 24:42-44",
                heading = "From the Gospel",
                text = """Watch therefore, for you don’t know in what hour your Lord comes. But know this, that if the master of the house had known in what watch of the night the thief was coming, he would have watched, and would not have allowed his house to be broken into. Therefore also be ready, for in an hour that you don’t expect, the Son of Man will come.""",
            )
        ),
        "immaculate-conception" to listOf(
            FeastScripturePassage(
                id = "ic-1",
                citation = "Genesis 3:9, 14-15",
                heading = "From the First Reading",
                text = """The LORD God called to the man, and said to him, “Where are you?” … The LORD God said to the serpent, “Because you have done this, you are cursed above all livestock, and above every animal of the field. You shall go on your belly and you shall eat dust all the days of your life. I will put hostility between you and the woman, and between your offspring and her offspring. He will bruise your head, and you will bruise his heel.”""",
            ),
            FeastScripturePassage(
                id = "ic-2",
                citation = "Luke 1:26-28, 30-31",
                heading = "From the Gospel",
                text = """Now in the sixth month, the angel Gabriel was sent from God to a city of Galilee named Nazareth, to a virgin pledged to be married to a man whose name was Joseph, of David’s house. The virgin’s name was Mary. Having come in, the angel said to her, “Rejoice, you highly favored one! The Lord is with you. Blessed are you among women!” … The angel said to her, “Don’t be afraid, Mary, for you have found favor with God. Behold, you will conceive in your womb and give birth to a son, and shall name him ‘Jesus.’”""",
            )
        ),
        "guadalupe" to listOf(
            FeastScripturePassage(
                id = "gua-1",
                citation = "Revelation 12:1",
                heading = "First Reading (associated)",
                text = """A great sign was seen in heaven: a woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars.""",
            ),
            FeastScripturePassage(
                id = "gua-2",
                citation = "Luke 1:39-45",
                heading = "From the Gospel",
                text = """Mary arose in those days and went into the hill country with haste, into a city of Judah, and entered into the house of Zacharias and greeted Elizabeth. When Elizabeth heard Mary’s greeting, the baby leaped in her womb; and Elizabeth was filled with the Holy Spirit. She called out with a loud voice and said, “Blessed are you among women, and blessed is the fruit of your womb! Why am I so favored, that the mother of my Lord should come to me? For behold, when the voice of your greeting came into my ears, the baby leaped in my womb for joy! Blessed is she who believed, for there will be a fulfillment of the things which have been spoken to her from the Lord!”""",
            )
        ),
        "christmas" to listOf(
            FeastScripturePassage(
                id = "xmas-1",
                citation = "Isaiah 9:6",
                heading = "From the First Reading",
                text = """For a child is born to us. A son is given to us; and the government will be on his shoulders. His name will be called Wonderful Counselor, Mighty God, Everlasting Father, Prince of Peace.""",
            ),
            FeastScripturePassage(
                id = "xmas-2",
                citation = "Luke 2:7-14",
                heading = "From the Gospel",
                text = """She gave birth to her firstborn son. She wrapped him in bands of cloth and laid him in a feeding trough, because there was no room for them in the inn. There were shepherds in the same country staying in the field, and keeping watch by night over their flock. Behold, an angel of the Lord stood by them, and the glory of the Lord shone around them, and they were terrified. The angel said to them, “Don’t be afraid, for behold, I bring you good news of great joy which will be to all the people. For there is born to you today, in David’s city, a Savior, who is Christ the Lord. This is the sign to you: you will find a baby wrapped in strips of cloth, lying in a feeding trough.” Suddenly, there was with the angel a multitude of the heavenly army praising God and saying, “Glory to God in the highest, on earth peace, good will toward men.”""",
            )
        ),
    )
}
