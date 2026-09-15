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
            scriptureExcerpt: BilingualText(english: excerpt, latin: excerpt),
            artSlug: slug
        )
    }

    static let joyful: [Mystery] = [
        item("joyful-1", .joyful, 1, "The Annunciation", "Annuntiatio",
             "Humility", "Humilitas",
             "In the sixth month the angel Gabriel was sent from God to a city of Galilee named Nazareth, to a virgin betrothed to a man whose name was Joseph, of the house of David; and the virgin’s name was Mary.",
             "Luke 1:26-27", "01-annunciation"),
        item("joyful-2", .joyful, 2, "The Visitation", "Visitatio",
             "Love of Neighbor", "Caritas erga proximum",
             "And when Elizabeth heard the greeting of Mary, the baby leaped in her womb; and Elizabeth was filled with the Holy Spirit and she exclaimed with a loud cry, “Blessed are you among women, and blessed is the fruit of your womb!”",
             "Luke 1:41-42", "02-visitation"),
        item("joyful-3", .joyful, 3, "The Nativity", "Nativitas",
             "Poverty", "Paupertas",
             "And she gave birth to her first-born son and wrapped him in swaddling cloths, and laid him in a manger, because there was no place for them in the inn.",
             "Luke 2:7", "03-birth-of-jesus"),
        item("joyful-4", .joyful, 4, "The Presentation in the Temple", "Praesentatio",
             "Purity of Heart and Body", "Puritas cordis et corporis",
             "And when the time came for their purification according to the law of Moses, they brought him up to Jerusalem to present him to the Lord.",
             "Luke 2:22", "04-presentation-of-the-baby-jesus"),
        item("joyful-5", .joyful, 5, "The Finding in the Temple", "Inventio in Templo",
             "Devotion to Jesus", "Devotio erga Iesum",
             "After three days they found him in the temple, sitting among the teachers, listening to them and asking them questions.",
             "Luke 2:46", "05-finding-of-the-child-jesus-in-the-temple")
    ]

    static let luminous: [Mystery] = [
        item("luminous-1", .luminous, 1, "The Baptism in the Jordan", "Baptisma in Iordane",
             "Openness to the Holy Spirit", "Docilitas Spiritui Sancto",
             "And when Jesus was baptized, he went up immediately from the water, and behold, the heavens were opened and he saw the Spirit of God descending like a dove, and alighting on him; and behold, a voice from heaven, saying, “This is my beloved Son, with whom I am well pleased.”",
             "Matthew 3:16-17", "01-baptism-of-jesus-in-the-jordan"),
        item("luminous-2", .luminous, 2, "The Wedding at Cana", "Nuptiae in Cana",
             "To Jesus through Mary", "Ad Iesum per Mariam",
             "When the wine failed, the mother of Jesus said to him, “They have no wine.” His mother said to the servants, “Do whatever he tells you.”",
             "John 2:3, 5", "02-miracle-at-the-wedding-at-cana"),
        item("luminous-3", .luminous, 3, "The Proclamation of the Kingdom", "Proclamatio Regni",
             "Conversion", "Conversio",
             "The time is fulfilled, and the kingdom of God is at hand; repent, and believe in the gospel.",
             "Mark 1:15", "03-proclamation-of-the-kingdom-of-god"),
        item("luminous-4", .luminous, 4, "The Transfiguration", "Transfiguratio",
             "Desire for holiness", "Desiderium sanctitatis",
             "And after six days Jesus took with him Peter and James and John his brother, and led them up a high mountain apart. And he was transfigured before them, and his face shone like the sun, and his garments became white as light.",
             "Matthew 17:1-2", "04-transfiguration"),
        item("luminous-5", .luminous, 5, "The Institution of the Eucharist", "Institutio Eucharistiae",
             "Adoration", "Adoratio",
             "Now as they were eating, Jesus took bread, and blessed, and broke it, and gave it to the disciples and said, “Take, eat; this is my body.”",
             "Matthew 26:26", "05-institution-of-the-holy-eucharist")
    ]

    static let sorrowful: [Mystery] = [
        item("sorrowful-1", .sorrowful, 1, "The Agony in the Garden", "Agonia in Horto",
             "Obedience to God’s Will", "Oboedientia voluntati Dei",
             "Then he said to them, “My soul is very sorrowful, even to death; remain here, and watch with me.” And going a little farther he fell on his face and prayed, “My Father, if it be possible, let this chalice pass from me; nevertheless, not as I will, but as you will.”",
             "Matthew 26:38-39", "01-agony-in-the-garden"),
        item("sorrowful-2", .sorrowful, 2, "The Scourging at the Pillar", "Flagellatio",
             "Mortification", "Mortificatio",
             "Then he released for them Barabbas, and having scourged Jesus, delivered him to be crucified.",
             "Matthew 27:26", "02-scourging-at-the-pillar"),
        item("sorrowful-3", .sorrowful, 3, "The Crowning with Thorns", "Coronatio Spinis",
             "Courage", "Fortitudo",
             "And plaiting a crown of thorns they put it on his head, and put a reed in his right hand. And kneeling before him they mocked him, saying, “Hail, King of the Jews!”",
             "Matthew 27:29", "03-crowning-with-thorns"),
        item("sorrowful-4", .sorrowful, 4, "The Carrying of the Cross", "Baiulatio Crucis",
             "Patience", "Patientia",
             "And they compelled a passer-by, Simon of Cyrene, who was coming in from the country, the father of Alexander and Rufus, to carry his cross. And they brought him to the place called Golgotha (which means the place of a skull).",
             "Mark 15:21-22", "04-carrying-of-the-cross"),
        item("sorrowful-5", .sorrowful, 5, "The Crucifixion", "Crucifixio",
             "Sorrow for our Sins", "Dolor peccatorum",
             "And when they came to the place which is called The Skull, there they crucified him, and the criminals, one on the right and one on the left. Then Jesus, crying with a loud voice, said, “Father, into your hands I commit my spirit!” And having said this he breathed his last.",
             "Luke 23:33, 46", "05-crucifixion")
    ]

    static let glorious: [Mystery] = [
        item("glorious-1", .glorious, 1, "The Resurrection", "Resurrectio",
             "Faith", "Fides",
             "Why do you seek the living among the dead? He is not here, but has risen.",
             "Luke 24:5", "01-resurrection"),
        item("glorious-2", .glorious, 2, "The Ascension", "Ascensio",
             "Hope", "Spes",
             "So then the Lord Jesus, after he had spoken to them, was taken up into heaven, and sat down at the right hand of God.",
             "Mark 16:19", "02-ascension"),
        item("glorious-3", .glorious, 3, "The Descent of the Holy Spirit", "Descensus Spiritus Sancti",
             "Wisdom", "Sapientia",
             "And there appeared to them tongues as of fire, distributed and resting on each one of them. And they were all filled with the Holy Spirit and began to speak in other tongues, as the Spirit gave them utterance.",
             "Acts 2:3-4", "03-descent-of-the-holy-spirit"),
        item("glorious-4", .glorious, 4, "The Assumption", "Assumptio",
             "Devotion to Mary", "Devotio erga Mariam",
             "For behold, henceforth all generations will call me blessed; for he who is mighty has done great things for me, and holy is his name.",
             "Luke 1:48-49", "04-assumption"),
        item("glorious-5", .glorious, 5, "The Coronation of Mary", "Coronatio Beatae Mariae Virginis",
             "Grace of a happy death", "Gratia bonae mortis",
             "And a great portent appeared in heaven, a woman clothed with the sun, with the moon under her feet, and on her head a crown of twelve stars.",
             "Revelation 12:1", "05-coronation")
    ]
}
