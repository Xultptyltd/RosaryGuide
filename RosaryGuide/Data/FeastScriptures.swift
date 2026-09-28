import Foundation

/// A short Scripture passage associated with a feast: Mass reading or classic traditional text.
/// Excerpts follow the app’s RSV-2CE style used in MysteryCatalog (brief liturgical windows).
struct FeastScripturePassage: Identifiable, Hashable, Sendable {
    var id: String
    var reference: String
    /// Liturgical or thematic label (e.g. "Gospel", "First Reading").
    var title: String
    var excerpt: String
}

enum FeastScriptures {
    static func passages(for id: String) -> [FeastScripturePassage] {
        table[id] ?? []
    }

    static var coveredIds: Set<String> { Set(table.keys) }

    private static func p(_ id: String, _ reference: String, _ title: String, _ excerpt: String) -> FeastScripturePassage {
        FeastScripturePassage(id: id, reference: reference, title: title, excerpt: excerpt)
    }

    // MARK: - Catalog (Mass readings / classic associated passages)

    private static let table: [String: [FeastScripturePassage]] = [
        "mary-mother-of-god": [
            p("mmog-1", "Galatians 4:4-5", "Second Reading",
              "But when the time had fully come, God sent forth his Son, born of woman, born under the law, to redeem those who were under the law, so that we might receive adoption as sons."),
            p("mmog-2", "Luke 2:16-19", "Gospel",
              "And they went with haste, and found Mary and Joseph, and the babe lying in a manger. And when they saw it they made known the saying which had been told them concerning this child; and all who heard it wondered at what the shepherds told them. But Mary kept all these things, pondering them in her heart.")
        ],
        "epiphany": [
            p("eph-1", "Isaiah 60:1-3", "First Reading",
              "Arise, shine; for your light has come, and the glory of the Lord has risen upon you. For behold, darkness shall cover the earth, and thick darkness the peoples; but the Lord will arise upon you, and his glory will be seen upon you. And nations shall come to your light, and kings to the brightness of your rising."),
            p("eph-2", "Matthew 2:1-2, 11", "Gospel",
              "Now when Jesus was born in Bethlehem of Judea in the days of Herod the king, behold, wise men from the East came to Jerusalem, saying, “Where is he who has been born king of the Jews? For we have seen his star in the East, and have come to worship him.” … and going into the house they saw the child with Mary his mother, and they fell down and worshiped him.")
        ],
        "baptism-movable": [
            p("bap-1", "Isaiah 42:1", "First Reading",
              "Behold my servant, whom I uphold, my chosen, in whom my soul delights; I have put my Spirit upon him, he will bring forth justice to the nations."),
            p("bap-2", "Matthew 3:16-17", "Gospel",
              "And when Jesus was baptized, he went up immediately from the water, and behold, the heavens were opened and he saw the Spirit of God descending like a dove, and alighting on him; and behold, a voice from heaven, saying, “This is my beloved Son, with whom I am well pleased.”")
        ],
        "presentation": [
            p("pres-1", "Malachi 3:1", "First Reading",
              "Behold, I send my messenger to prepare the way before me, and the Lord whom you seek will suddenly come to his temple; the messenger of the covenant in whom you delight, behold, he is coming, says the Lord of hosts."),
            p("pres-2", "Luke 2:22, 29-32", "Gospel",
              "And when the time came for their purification according to the law of Moses, they brought him up to Jerusalem to present him to the Lord. … “Lord, now let your servant depart in peace, according to your word; for my eyes have seen your salvation which you have prepared in the presence of all peoples, a light for revelation to the Gentiles, and for glory to your people Israel.”")
        ],
        "lourdes": [
            p("lou-1", "Genesis 3:15", "First Reading (associated)",
              "I will put enmity between you and the woman, and between your seed and her seed; he shall bruise your head, and you shall bruise his heel."),
            p("lou-2", "Luke 1:28, 30-31", "Gospel (Common of the BVM)",
              "And he came to her and said, “Hail, full of grace, the Lord is with you!” … And the angel said to her, “Do not be afraid, Mary, for you have found favor with God. And behold, you will conceive in your womb and bear a son, and you shall call his name Jesus.”")
        ],
        "ash-wednesday": [
            p("ash-1", "Joel 2:12-13", "First Reading",
              "“Yet even now,” says the Lord, “return to me with all your heart, with fasting, with weeping, and with mourning; and rend your hearts and not your garments.” Return to the Lord, your God, for he is gracious and merciful, slow to anger, and abounding in steadfast love, and repents of evil."),
            p("ash-2", "Matthew 6:16-18", "Gospel",
              "And when you fast, do not look dismal, like the hypocrites, for they disfigure their faces that their fasting may be seen by men. Truly, I say to you, they have their reward. But when you fast, anoint your head and wash your face, that your fasting may not be seen by men but by your Father who is in secret; and your Father who sees in secret will reward you.")
        ],
        "joseph": [
            p("jos-1", "2 Samuel 7:12, 16", "First Reading",
              "When your days are fulfilled and you lie down with your fathers, I will raise up your offspring after you, who shall come forth from your body, and I will establish his kingdom. … And your house and your kingdom shall be made sure for ever before me; your throne shall be established for ever."),
            p("jos-2", "Matthew 1:20-21, 24", "Gospel",
              "Behold, an angel of the Lord appeared to him in a dream, saying, “Joseph, son of David, do not fear to take Mary your wife, for that which is conceived in her is of the Holy Spirit; she will bear a son, and you shall call his name Jesus, for he will save his people from their sins.” … When Joseph woke from sleep, he did as the angel of the Lord commanded him.")
        ],
        "annunciation": [
            p("ann-1", "Isaiah 7:14", "First Reading",
              "Therefore the Lord himself will give you a sign. Behold, a virgin shall conceive and bear a son, and shall call his name Immanuel."),
            p("ann-2", "Luke 1:26-28, 38", "Gospel",
              "In the sixth month the angel Gabriel was sent from God to a city of Galilee named Nazareth, to a virgin betrothed to a man whose name was Joseph, of the house of David; and the virgin’s name was Mary. And he came to her and said, “Hail, full of grace, the Lord is with you!” … And Mary said, “Behold, I am the handmaid of the Lord; let it be to me according to your word.”")
        ],
        "palm-sunday": [
            p("palm-1", "Philippians 2:6-8", "Second Reading",
              "Who, though he was in the form of God, did not count equality with God a thing to be grasped, but emptied himself, taking the form of a servant, being born in the likeness of men. And being found in human form he humbled himself and became obedient unto death, even death on a cross."),
            p("palm-2", "Matthew 21:9", "Gospel at the Procession",
              "And the crowds that went before him and that followed him shouted, “Hosanna to the Son of David! Blessed is he who comes in the name of the Lord! Hosanna in the highest!”")
        ],
        "holy-thursday": [
            p("ht-1", "1 Corinthians 11:23-25", "Second Reading",
              "For I received from the Lord what I also delivered to you, that the Lord Jesus on the night when he was betrayed took bread, and when he had given thanks, he broke it, and said, “This is my body which is for you. Do this in remembrance of me.” In the same way also the chalice, after supper, saying, “This chalice is the new covenant in my blood. Do this, as often as you drink it, in remembrance of me.”"),
            p("ht-2", "John 13:14-15", "Gospel",
              "If I then, your Lord and Teacher, have washed your feet, you also ought to wash one another’s feet. For I have given you an example, that you also should do as I have done to you.")
        ],
        "good-friday": [
            p("gf-1", "Isaiah 53:4-5", "First Reading",
              "Surely he has borne our griefs and carried our sorrows; yet we esteemed him stricken, struck down by God, and afflicted. But he was wounded for our transgressions, he was bruised for our iniquities; upon him was the chastisement that made us whole, and with his stripes we are healed."),
            p("gf-2", "John 19:26-27, 30", "Gospel",
              "When Jesus saw his mother, and the disciple whom he loved standing near, he said to his mother, “Woman, behold, your son!” Then he said to the disciple, “Behold, your mother!” And from that hour the disciple took her to his own home. … When Jesus had received the vinegar, he said, “It is finished”; and he bowed his head and gave up his spirit.")
        ],
        "holy-saturday": [
            p("hs-1", "Romans 6:3-4", "Epistle of the Vigil",
              "Do you not know that all of us who have been baptized into Christ Jesus were baptized into his death? We were buried therefore with him by baptism into death, so that as Christ was raised from the dead by the glory of the Father, we too might walk in newness of life."),
            p("hs-2", "Matthew 28:5-6", "Gospel of the Vigil",
              "But the angel said to the women, “Do not be afraid; for I know that you seek Jesus who was crucified. He is not here; for he has risen, as he said. Come, see the place where he lay.”")
        ],
        "easter": [
            p("eas-1", "Colossians 3:1-4", "Second Reading",
              "If then you have been raised with Christ, seek the things that are above, where Christ is, seated at the right hand of God. Set your minds on things that are above, not on things that are on earth. For you have died, and your life is hidden with Christ in God. When Christ who is our life appears, then you also will appear with him in glory."),
            p("eas-2", "John 20:1, 6-8", "Gospel",
              "Now on the first day of the week Mary Magdalene came to the tomb early, while it was still dark, and saw that the stone had been taken away from the tomb. … Then Simon Peter came, following him, and went into the tomb; he saw the linen cloths lying, and the napkin, which had been on his head, not lying with the linen cloths but rolled up in a place by itself. Then the other disciple, who reached the tomb first, also went in, and he saw and believed.")
        ],
        "divine-mercy": [
            p("dm-1", "1 John 5:4-6", "Second Reading (associated)",
              "For whatever is born of God overcomes the world; and this is the victory that overcomes the world, our faith. Who is it that overcomes the world but he who believes that Jesus is the Son of God? This is he who came by water and blood, Jesus Christ, not with the water only but with the water and the blood."),
            p("dm-2", "John 20:19-22, 27-28", "Gospel",
              "On the evening of that day, the first day of the week, the doors being shut where the disciples were, for fear of the Jews, Jesus came and stood among them and said to them, “Peace be with you.” … And when he had said this, he breathed on them, and said to them, “Receive the Holy Spirit.” … Then he said to Thomas, “Put your finger here, and see my hands; and put out your hand, and place it in my side; do not be faithless, but believing.” Thomas answered him, “My Lord and my God!”")
        ],
        "fatima": [
            p("fat-1", "Revelation 12:1", "First Reading (associated)",
              "And a great sign appeared in heaven, a woman clothed with the sun, with the moon under her feet, and on her head a crown of twelve stars."),
            p("fat-2", "Luke 1:38", "Gospel (Common of the BVM)",
              "And Mary said, “Behold, I am the handmaid of the Lord; let it be to me according to your word.” And the angel departed from her.")
        ],
        "ascension": [
            p("asc-1", "Acts 1:8-11", "First Reading",
              "“But you shall receive power when the Holy Spirit has come upon you; and you shall be my witnesses in Jerusalem and in all Judea and Samaria and to the end of the earth.” And when he had said this, as they were looking on, he was lifted up, and a cloud took him out of their sight. And while they were gazing into heaven as he went, behold, two men stood by them in white robes, and said, “Men of Galilee, why do you stand looking into heaven? This Jesus, who was taken up from you into heaven, will come in the same way as you saw him go into heaven.”"),
            p("asc-2", "Mark 16:15, 19", "Gospel",
              "And he said to them, “Go into all the world and preach the gospel to the whole creation.” … So then the Lord Jesus, after he had spoken to them, was taken up into heaven, and sat down at the right hand of God.")
        ],
        "pentecost": [
            p("pen-1", "Acts 2:1-4", "First Reading",
              "When the day of Pentecost had come, they were all together in one place. And suddenly a sound came from heaven like the rush of a mighty wind, and it filled all the house where they were sitting. And there appeared to them tongues as of fire, distributed and resting on each one of them. And they were all filled with the Holy Spirit and began to speak in other tongues, as the Spirit gave them utterance."),
            p("pen-2", "John 20:21-22", "Gospel",
              "Jesus said to them again, “Peace be with you. As the Father has sent me, even so I send you.” And when he had said this, he breathed on them, and said to them, “Receive the Holy Spirit.”")
        ],
        "visitation": [
            p("vis-1", "Zephaniah 3:14, 17", "First Reading",
              "Sing aloud, O daughter of Zion; shout, O Israel! Rejoice and exult with all your heart, O daughter of Jerusalem! … The Lord your God is in your midst, a warrior who gives victory; he will rejoice over you with gladness, he will renew you in his love."),
            p("vis-2", "Luke 1:39-42, 46-47", "Gospel",
              "In those days Mary arose and went with haste into the hill country, to a city of Judah, and she entered the house of Zechariah and greeted Elizabeth. And when Elizabeth heard the greeting of Mary, the baby leaped in her womb; and Elizabeth was filled with the Holy Spirit and she exclaimed with a loud cry, “Blessed are you among women, and blessed is the fruit of your womb!” … And Mary said, “My soul magnifies the Lord, and my spirit rejoices in God my Savior.”")
        ],
        "trinity": [
            p("tri-1", "Romans 5:1-2, 5", "Second Reading",
              "Therefore, since we are justified by faith, we have peace with God through our Lord Jesus Christ. Through him we have obtained access to this grace in which we stand, and we rejoice in our hope of sharing the glory of God. … and hope does not disappoint us, because God’s love has been poured into our hearts through the Holy Spirit who has been given to us."),
            p("tri-2", "Matthew 28:18-20", "Gospel",
              "And Jesus came and said to them, “All authority in heaven and on earth has been given to me. Go therefore and make disciples of all nations, baptizing them in the name of the Father and of the Son and of the Holy Spirit, teaching them to observe all that I have commanded you; and behold, I am with you always, to the close of the age.”")
        ],
        "corpus-christi": [
            p("cc-1", "1 Corinthians 10:16-17", "Second Reading",
              "The chalice of blessing which we bless, is it not a participation in the blood of Christ? The bread which we break, is it not a participation in the body of Christ? Because there is one bread, we who are many are one body, for we all partake of the one bread."),
            p("cc-2", "John 6:51", "Gospel",
              "I am the living bread which came down from heaven; if any one eats of this bread, he will live for ever; and the bread which I shall give for the life of the world is my flesh.")
        ],
        "sacred-heart": [
            p("sh-1", "Hosea 11:3-4", "First Reading",
              "Yet it was I who taught Ephraim to walk, I took them up in my arms; but they did not know that I healed them. I led them with cords of compassion, with the bands of love, and I became to them as one who eases the yoke on their jaws, and I bent down to them and fed them."),
            p("sh-2", "John 19:34-37", "Gospel",
              "But one of the soldiers pierced his side with a spear, and at once there came out blood and water. He who saw it has borne witness—his testimony is true, and he knows that he tells the truth—that you also may believe. For these things took place that the scripture might be fulfilled, “Not a bone of him shall be broken.” And again another scripture says, “They shall look on him whom they have pierced.”")
        ],
        "immaculate-heart": [
            p("ih-1", "Isaiah 61:9-10", "First Reading (associated)",
              "Their descendants shall be known among the nations, and their offspring in the midst of the peoples; all who see them shall acknowledge them, that they are a people whom the Lord has blessed. I will greatly rejoice in the Lord, my soul shall exult in my God."),
            p("ih-2", "Luke 2:51", "Gospel",
              "And he went down with them and came to Nazareth, and was obedient to them; and his mother kept all these things in her heart.")
        ],
        "peter-paul": [
            p("pp-1", "Acts 12:5-7, 11", "First Reading",
              "So Peter was kept in prison; but earnest prayer for him was made to God by the Church. The very night when Herod was about to bring him out, Peter was sleeping between two soldiers, bound with two chains, and sentries before the door were guarding the prison; and behold, an angel of the Lord appeared, and a light shone in the cell; and he struck Peter on the side and woke him, saying, “Get up quickly.” And the chains fell off his hands. … And Peter came to himself, and said, “Now I am sure that the Lord has sent his angel and rescued me.”"),
            p("pp-2", "Matthew 16:16-18", "Gospel",
              "Simon Peter replied, “You are the Christ, the Son of the living God.” And Jesus answered him, “Blessed are you, Simon Bar-Jona! For flesh and blood has not revealed this to you, but my Father who is in heaven. And I tell you, you are Peter, and on this rock I will build my Church, and the gates of Hades shall not prevail against it.”")
        ],
        "carmel": [
            p("car-1", "1 Kings 18:36-39", "Classic associated (Elijah on Carmel)",
              "And at the time of the offering of the oblation, Elijah the prophet came near and said, “O Lord, God of Abraham, Isaac, and Israel, let it be known this day that you are God in Israel, and that I am your servant, and that I have done all these things at your word.” … Then the fire of the Lord fell, and consumed the burnt offering, and the wood, and the stones, and the dust, and licked up the water that was in the trench. And when all the people saw it, they fell on their faces; and they said, “The Lord, he is God; the Lord, he is God.”"),
            p("car-2", "Luke 11:27-28", "Gospel (Common of the BVM)",
              "As he said this, a woman in the crowd raised her voice and said to him, “Blessed is the womb that bore you, and the breasts that you sucked!” But he said, “Blessed rather are those who hear the word of God and keep it!”")
        ],
        "assumption": [
            p("ass-1", "Revelation 11:19a; 12:1", "First Reading",
              "Then God’s temple in heaven was opened, and the ark of his covenant was seen within his temple. … And a great sign appeared in heaven, a woman clothed with the sun, with the moon under her feet, and on her head a crown of twelve stars."),
            p("ass-2", "Luke 1:46-49", "Gospel",
              "And Mary said, “My soul magnifies the Lord, and my spirit rejoices in God my Savior, for he has regarded the low estate of his handmaiden. For behold, henceforth all generations will call me blessed; for he who is mighty has done great things for me, and holy is his name.”")
        ],
        "queenship": [
            p("que-1", "Revelation 12:1, 5", "First Reading (associated)",
              "And a great sign appeared in heaven, a woman clothed with the sun, with the moon under her feet, and on her head a crown of twelve stars. … She brought forth a male child, one who is to rule all the nations with a rod of iron, but her child was caught up to God and to his throne."),
            p("que-2", "Luke 1:30-33", "Gospel",
              "And the angel said to her, “Do not be afraid, Mary, for you have found favor with God. And behold, you will conceive in your womb and bear a son, and you shall call his name Jesus. He will be great, and will be called the Son of the Most High; and the Lord God will give to him the throne of his father David, and he will reign over the house of Jacob for ever; and of his kingdom there will be no end.”")
        ],
        "nativity-mary": [
            p("nm-1", "Micah 5:2-4a", "First Reading",
              "But you, O Bethlehem Ephrathah, who are little to be among the clans of Judah, from you shall come forth for me one who is to be ruler in Israel, whose origin is from of old, from ancient days. Therefore he shall give them up until the time when she who is in travail has brought forth; then the rest of his brethren shall return to the people of Israel. And he shall stand and feed his flock in the strength of the Lord."),
            p("nm-2", "Matthew 1:16, 18", "Gospel",
              "And Jacob the father of Joseph the husband of Mary, of whom Jesus was born, who is called Christ. … Now the birth of Jesus Christ took place in this way. When his mother Mary had been betrothed to Joseph, before they came together she was found to be with child of the Holy Spirit.")
        ],
        "holy-name-mary": [
            p("hnm-1", "Sirach 24:18-20", "First Reading (associated)",
              "I am the mother of fair love, and of fear, and of knowledge, and of holy hope. In me is all grace of the way and of the truth, in me is all hope of life and of virtue. Come over to me, all you that desire me, and be filled with my fruits."),
            p("hnm-2", "Luke 1:26-27, 30-31", "Gospel",
              "In the sixth month the angel Gabriel was sent from God to a city of Galilee named Nazareth, to a virgin betrothed to a man whose name was Joseph, of the house of David; and the virgin’s name was Mary. … And the angel said to her, “Do not be afraid, Mary, for you have found favor with God. And behold, you will conceive in your womb and bear a son, and you shall call his name Jesus.”")
        ],
        "sorrows": [
            p("sor-1", "Hebrews 5:7-9", "First Reading",
              "In the days of his flesh, Jesus offered up prayers and supplications, with loud cries and tears, to him who was able to save him from death, and he was heard for his godly fear. Although he was a Son, he learned obedience through what he suffered; and being made perfect he became the source of eternal salvation to all who obey him."),
            p("sor-2", "John 19:25-27", "Gospel",
              "Standing by the cross of Jesus were his mother, and his mother’s sister, Mary the wife of Clopas, and Mary Magdalene. When Jesus saw his mother, and the disciple whom he loved standing near, he said to his mother, “Woman, behold, your son!” Then he said to the disciple, “Behold, your mother!” And from that hour the disciple took her to his own home."),
            p("sor-3", "Luke 2:34-35", "Classic associated",
              "And Simeon blessed them and said to Mary his mother, “Behold, this child is set for the fall and rising of many in Israel, and for a sign that is spoken against (and a sword will pierce through your own soul also), that thoughts out of many hearts may be revealed.”")
        ],
        "michael": [
            p("mic-1", "Revelation 12:7-9", "First Reading",
              "Now war arose in heaven, Michael and his angels fighting against the dragon; and the dragon and his angels fought, but they were defeated and there was no longer any place for them in heaven. And the great dragon was thrown down, that ancient serpent, who is called the Devil and Satan, the deceiver of the whole world—he was thrown down to the earth, and his angels were thrown down with him."),
            p("mic-2", "John 1:51", "Gospel",
              "And he said to him, “Truly, truly, I say to you, you will see heaven opened, and the angels of God ascending and descending upon the Son of man.”"),
            p("mic-3", "Luke 1:26, 28", "Gabriel (classic associated)",
              "In the sixth month the angel Gabriel was sent from God to a city of Galilee named Nazareth… And he came to her and said, “Hail, full of grace, the Lord is with you!”"),
            p("mic-4", "Tobit 12:15", "Raphael (classic associated)",
              "I am Raphael, one of the seven holy angels who present the prayers of the saints and enter into the presence of the glory of the Holy One.")
        ],
        "guardian-angels": [
            p("ga-1", "Exodus 23:20-21", "First Reading",
              "Behold, I send an angel before you, to guard you on the way and to bring you to the place which I have prepared. Give heed to him and listen to his voice, do not rebel against him, for he will not pardon your transgression; for my name is in him."),
            p("ga-2", "Matthew 18:1-5, 10", "Gospel",
              "At that time the disciples came to Jesus, saying, “Who is the greatest in the kingdom of heaven?” And calling to him a child, he put him in the midst of them, and said, “Truly, I say to you, unless you turn and become like children, you will never enter the kingdom of heaven. Whoever humbles himself like this child, he is the greatest in the kingdom of heaven. Whoever receives one such child in my name receives me.” … “See that you do not despise one of these little ones; for I tell you that in heaven their angels always behold the face of my Father who is in heaven.”")
        ],
        "rosary": [
            p("ros-1", "Acts 1:12, 14", "First Reading (associated)",
              "Then they returned to Jerusalem from the mount called Olivet, which is near Jerusalem, a sabbath day’s journey away. … All these with one accord devoted themselves to prayer, together with the women and Mary the mother of Jesus, and with his brethren."),
            p("ros-2", "Luke 1:28, 42", "Gospel roots of the Hail Mary",
              "And he came to her and said, “Hail, full of grace, the Lord is with you!” … and she exclaimed with a loud cry, “Blessed are you among women, and blessed is the fruit of your womb!”")
        ],
        "all-saints": [
            p("as-1", "Revelation 7:9-10", "First Reading",
              "After this I looked, and behold, a great multitude which no man could number, from every nation, from all tribes and peoples and tongues, standing before the throne and before the Lamb, clothed in white robes, with palm branches in their hands, and crying out with a loud voice, “Salvation belongs to our God who sits upon the throne, and to the Lamb!”"),
            p("as-2", "Matthew 5:3-10", "Gospel",
              "Blessed are the poor in spirit, for theirs is the kingdom of heaven. Blessed are those who mourn, for they shall be comforted. Blessed are the meek, for they shall inherit the earth. Blessed are those who hunger and thirst for righteousness, for they shall be satisfied. Blessed are the merciful, for they shall obtain mercy. Blessed are the pure in heart, for they shall see God. Blessed are the peacemakers, for they shall be called sons of God. Blessed are those who are persecuted for righteousness’ sake, for theirs is the kingdom of heaven.")
        ],
        "all-souls": [
            p("aso-1", "Wisdom 3:1-3", "First Reading",
              "But the souls of the righteous are in the hand of God, and no torment will ever touch them. In the eyes of the foolish they seemed to have died, and their departure was thought to be an affliction, and their going from us to be their destruction; but they are at peace."),
            p("aso-2", "John 6:37-40", "Gospel",
              "All that the Father gives me will come to me; and him who comes to me I will not cast out. For I have come down from heaven, not to do my own will, but the will of him who sent me; and this is the will of him who sent me, that I should lose nothing of all that he has given me, but raise it up at the last day. For this is the will of my Father, that every one who sees the Son and believes in him should have eternal life; and I will raise him up at the last day.")
        ],
        "presentation-mary": [
            p("pm-1", "Zechariah 2:10-11", "First Reading (associated)",
              "Sing and rejoice, O daughter of Zion; for behold, I come and I will dwell in the midst of you, says the Lord. And many nations shall join themselves to the Lord in that day, and shall be my people; and I will dwell in the midst of you."),
            p("pm-2", "Matthew 12:50", "Gospel (associated)",
              "For whoever does the will of my Father in heaven is my brother, and sister, and mother.")
        ],
        "christ-the-king": [
            p("ctk-1", "Daniel 7:13-14", "First Reading",
              "I saw in the night visions, and behold, with the clouds of heaven there came one like a son of man, and he came to the Ancient of Days and was presented before him. And to him was given dominion and glory and kingdom, that all peoples, nations, and languages should serve him; his dominion is an everlasting dominion, which shall not pass away, and his kingdom one that shall not be destroyed."),
            p("ctk-2", "John 18:36-37", "Gospel",
              "Jesus answered, “My kingship is not of this world; if my kingship were of this world, my servants would fight, that I might not be handed over to the Jews; but my kingship is not from the world.” Pilate said to him, “So you are a king?” Jesus answered, “You say that I am a king. For this I was born, and for this I have come into the world, to bear witness to the truth. Every one who is of the truth hears my voice.”")
        ],
        "advent-1": [
            p("adv-1", "Isaiah 2:3-5", "First Reading",
              "Come, let us go up to the mountain of the Lord, to the house of the God of Jacob; that he may teach us his ways and that we may walk in his paths. For out of Zion shall go forth the law, and the word of the Lord from Jerusalem. He shall judge between the nations, and shall decide for many peoples; and they shall beat their swords into plowshares, and their spears into pruning hooks; nation shall not lift up sword against nation, neither shall they learn war any more. O house of Jacob, come, let us walk in the light of the Lord."),
            p("adv-2", "Matthew 24:42-44", "Gospel",
              "Watch therefore, for you do not know on what day your Lord is coming. But know this, that if the householder had known in what part of the night the thief was coming, he would have watched and would not have let his house be broken into. Therefore you also must be ready; for the Son of man is coming at an hour you do not expect.")
        ],
        "immaculate-conception": [
            p("ic-1", "Genesis 3:9, 14-15", "First Reading",
              "But the Lord God called to the man, and said to him, “Where are you?” … The Lord God said to the serpent, “Because you have done this, cursed are you above all cattle, and above all wild animals; upon your belly you shall go, and dust you shall eat all the days of your life. I will put enmity between you and the woman, and between your seed and her seed; he shall bruise your head, and you shall bruise his heel.”"),
            p("ic-2", "Luke 1:26-28, 30-31", "Gospel",
              "In the sixth month the angel Gabriel was sent from God to a city of Galilee named Nazareth, to a virgin betrothed to a man whose name was Joseph, of the house of David; and the virgin’s name was Mary. And he came to her and said, “Hail, full of grace, the Lord is with you!” … And the angel said to her, “Do not be afraid, Mary, for you have found favor with God. And behold, you will conceive in your womb and bear a son, and you shall call his name Jesus.”")
        ],
        "guadalupe": [
            p("gua-1", "Revelation 12:1", "First Reading (associated)",
              "And a great sign appeared in heaven, a woman clothed with the sun, with the moon under her feet, and on her head a crown of twelve stars."),
            p("gua-2", "Luke 1:39-45", "Gospel",
              "In those days Mary arose and went with haste into the hill country, to a city of Judah, and she entered the house of Zechariah and greeted Elizabeth. And when Elizabeth heard the greeting of Mary, the baby leaped in her womb; and Elizabeth was filled with the Holy Spirit and she exclaimed with a loud cry, “Blessed are you among women, and blessed is the fruit of your womb! And why is this granted me, that the mother of my Lord should come to me? For behold, when the voice of your greeting came to my ears, the baby in my womb leaped for joy. And blessed is she who believed that there would be a fulfilment of what was spoken to her from the Lord.”")
        ],
        "christmas": [
            p("xmas-1", "Isaiah 9:6", "First Reading",
              "For to us a child is born, to us a son is given; and the government will be upon his shoulder, and his name will be called “Wonderful Counselor, Mighty God, Everlasting Father, Prince of Peace.”"),
            p("xmas-2", "Luke 2:7-14", "Gospel",
              "And she gave birth to her first-born son and wrapped him in swaddling cloths, and laid him in a manger, because there was no place for them in the inn. And in that region there were shepherds out in the field, keeping watch over their flock by night. And an angel of the Lord appeared to them, and the glory of the Lord shone around them, and they were filled with fear. And the angel said to them, “Be not afraid; for behold, I bring you good news of a great joy which will come to all the people; for to you is born this day in the city of David a Savior, who is Christ the Lord. And this will be a sign for you: you will find a baby wrapped in swaddling cloths and lying in a manger.” And suddenly there was with the angel a multitude of the heavenly host praising God and saying, “Glory to God in the highest, and on earth peace among men with whom he is pleased!”")
        ]
    ]
}

extension Feast {
    /// Feast-specific Mass / classic associated Scripture (not the weekday mystery set).
    var scripturePassages: [FeastScripturePassage] {
        FeastScriptures.passages(for: id)
    }
}
