import Foundation

/// A short verse for Home “Daily scripture”.
/// Feast days use curated feast-linked excerpts; ordinary days use a rotating
/// contemplative catalog that does **not** claim to be today’s liturgy.
struct LiturgicalVerse: Identifiable, Hashable, Sendable {
    var id: String
    /// A deliberate Home-sized excerpt: one meaningful sentence, kept separate
    /// from the fuller passage shown after tapping.
    var homeExcerpt: String
    /// Fuller Scripture context for the Home bottom sheet.
    var fullText: String
    /// Book, chapter, and verse (e.g. "John 1:51").
    var reference: String
    /// Soft reading label when known (e.g. “From the Gospel”), feast days only.
    var readingLabel: String?
    /// Secondary Home label under the citation.
    /// Ordinary days: “A verse for today”. Feast days: “Scripture for this feast”.
    var sourceLabel: String?

    /// Compatibility accessor for callers that treated `text` as the Home copy.
    var text: String { homeExcerpt }

    /// Home presentation: editorial smart quotes, with an ellipsis when this
    /// deliberately shorter copy does not include the full citation passage.
    var homeDisplayExcerpt: String {
        let excerpt = homeExcerpt.trimmingCharacters(in: .whitespacesAndNewlines)
        let full = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isShortened = !full.isEmpty && excerpt != full
        let body = isShortened
            ? excerpt.trimmingCharacters(in: CharacterSet(charactersIn: ".!?… "))
            : excerpt
        return "“\(body)\(isShortened ? "…" : "")”"
    }

    init(
        id: String,
        text: String,
        reference: String,
        readingLabel: String? = nil,
        sourceLabel: String? = nil,
        fullText: String? = nil,
        homeExcerpt: String? = nil
    ) {
        self.id = id
        self.fullText = fullText ?? text
        self.homeExcerpt = homeExcerpt ?? Self.firstSentence(from: text)
        self.reference = reference
        self.readingLabel = readingLabel
        self.sourceLabel = sourceLabel
    }

    var secondaryCitation: String? {
        if let sourceLabel, !sourceLabel.isEmpty {
            return sourceLabel
        }
        let value = readingLabel
        return value?.isEmpty == false ? value : nil
    }

    var citationLine: String {
        if let secondaryCitation {
            return "\(reference) · \(secondaryCitation)"
        }
        return reference
    }

    fileprivate static func firstSentence(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        guard let end = trimmed.firstIndex(where: { ".!?".contains($0) }) else {
            return trimmed
        }
        return String(trimmed[...end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum LiturgicalVerseCatalog {
    /// Today's Home verse for the user's local calendar date.
    static func verse(for date: Date = .now, calendar: Calendar = .current) -> LiturgicalVerse {
        let day = calendar.startOfDay(for: date)

        // 1. Feast already modeled in the app with feast-linked Scripture.
        if let feastVerse = feastVerse(on: day, calendar: calendar) {
            return feastVerse
        }

        // 2. Ordinary day: curated verse of the day (not claimed as liturgy).
        return verseOfTheDay(on: day, calendar: calendar)
    }

    // MARK: - Feast resolution

    private static func feastVerse(on date: Date, calendar: Calendar) -> LiturgicalVerse? {
        let feasts = FeastCatalog.feasts(on: date, calendar: calendar)
        for item in feasts {
            if let curated = byFeastId[item.feast.id] {
                return curated
            }
            if let fromScripture = highlight(from: FeastScriptures.passages(for: item.feast.id), feastId: item.feast.id) {
                return fromScripture
            }
        }
        return nil
    }

    /// Prefer Gospel, then First Reading; keep a Home-length window of the excerpt.
    private static func highlight(from passages: [FeastScripturePassage], feastId: String) -> LiturgicalVerse? {
        guard !passages.isEmpty else { return nil }
        let preferred = passages.first { $0.title.localizedCaseInsensitiveContains("Gospel") }
            ?? passages.first { $0.title.localizedCaseInsensitiveContains("First") }
            ?? passages[0]
        return LiturgicalVerse(
            id: "feast-\(feastId)-\(preferred.id)",
            text: preferred.excerpt,
            reference: preferred.reference,
            readingLabel: preferred.title,
            sourceLabel: "Scripture for this feast",
            fullText: preferred.excerpt,
            homeExcerpt: homeLength(preferred.excerpt)
        )
    }

    /// Keep Home to one complete sentence; the full reading remains available on tap.
    private static func homeLength(_ excerpt: String, maxChars: Int = 220) -> String {
        let sentence = LiturgicalVerse.firstSentence(from: excerpt)
        // A few liturgical sentences are naturally longer than the Home target;
        // SwiftUI's five-line limit keeps those from becoming a wall of text.
        return sentence.isEmpty ? String(excerpt.prefix(maxChars)) : sentence
    }

    // MARK: - Curated by feast id (short, real Mass-reading verses)

    /// Curated Home excerpts for every FeastCatalog id (Gospel preferred;
    /// First Reading when that is the feast’s distinctive proper). Unknown
    /// ids still fall through to FeastScriptures. Labels are feast-linked,
    /// not a claim of unique daily Mass propers.
    private static let byFeastId: [String: LiturgicalVerse] = [
        // MARK: Fixed calendar
        "mary-mother-of-god": LiturgicalVerse(
            id: "feast-mary-mother-of-god",
            text: "They came with haste and found both Mary and Joseph, and the baby was lying in the feeding trough. … But Mary kept all these sayings, pondering them in her heart.",
            reference: "Luke 2:16, 19",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "But Mary kept all these sayings, pondering them in her heart."
        ),
        "epiphany": LiturgicalVerse(
            id: "feast-epiphany",
            text: "Now when Jesus was born in Bethlehem of Judea in the days of King Herod, behold, wise men from the east came to Jerusalem, saying, “Where is he who is born King of the Jews? For we saw his star in the east, and have come to worship him.” … They came into the house and saw the young child with Mary, his mother, and they fell down and worshiped him.",
            reference: "Matthew 2:1-2, 11",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Where is he who is born King of the Jews? For we saw his star in the east, and have come to worship him."
        ),
        "presentation": LiturgicalVerse(
            id: "feast-presentation",
            text: "“Now you are releasing your servant, Master, according to your word, in peace; for my eyes have seen your salvation, which you have prepared before the face of all peoples; a light for revelation to the nations, and the glory of your people Israel.”",
            reference: "Luke 2:29-32",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Now you are releasing your servant, Master, according to your word, in peace; for my eyes have seen your salvation…"
        ),
        "lourdes": LiturgicalVerse(
            id: "feast-lourdes",
            text: "Having come in, the angel said to her, “Rejoice, you highly favored one! The Lord is with you. Blessed are you among women!”",
            reference: "Luke 1:28",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Rejoice, you highly favored one! The Lord is with you."
        ),
        "joseph": LiturgicalVerse(
            id: "feast-joseph",
            text: "But when he thought about these things, behold, an angel of the Lord appeared to him in a dream, saying, “Joseph, son of David, don’t be afraid to take to yourself Mary as your wife, for that which is conceived in her is of the Holy Spirit. She shall give birth to a son. You shall name him Jesus, for it is he who shall save his people from their sins.”",
            reference: "Matthew 1:20-21",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Joseph, son of David, don’t be afraid to take to yourself Mary as your wife, for that which is conceived in her is of the Holy Spirit."
        ),
        "annunciation": LiturgicalVerse(
            id: "feast-annunciation",
            text: "Mary said, “Behold, the servant of the Lord; let it be done to me according to your word.”",
            reference: "Luke 1:38",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Behold, the servant of the Lord; let it be done to me according to your word."
        ),
        "fatima": LiturgicalVerse(
            id: "feast-fatima",
            text: "Mary said, “Behold, the servant of the Lord; let it be done to me according to your word.” Then the angel departed from her.",
            reference: "Luke 1:38",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Behold, the servant of the Lord; let it be done to me according to your word."
        ),
        "visitation": LiturgicalVerse(
            id: "feast-visitation",
            text: "When Elizabeth heard Mary’s greeting, the baby leaped in her womb; and Elizabeth was filled with the Holy Spirit. She called out with a loud voice and said, “Blessed are you among women, and blessed is the fruit of your womb!”",
            reference: "Luke 1:41-42",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Blessed are you among women, and blessed is the fruit of your womb!"
        ),
        "peter-paul": LiturgicalVerse(
            id: "feast-peter-paul",
            text: "Simon Peter answered, “You are the Christ, the Son of the living God.” Jesus answered him, “Blessed are you, Simon Bar Jonah, for flesh and blood has not revealed this to you, but my Father who is in heaven. I also tell you that you are Peter, and on this rock I will build my assembly, and the gates of Hades will not prevail against it.”",
            reference: "Matthew 16:16-18",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "You are Peter, and on this rock I will build my assembly, and the gates of Hades will not prevail against it."
        ),
        "carmel": LiturgicalVerse(
            id: "feast-carmel",
            text: "It came to pass, as he said these things, a certain woman out of the multitude lifted up her voice and said to him, “Blessed is the womb that bore you, and the breasts which nursed you!” But he said, “On the contrary, blessed are those who hear the word of God, and keep it.”",
            reference: "Luke 11:27-28",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Blessed are those who hear the word of God, and keep it."
        ),
        "assumption": LiturgicalVerse(
            id: "feast-assumption",
            text: "Mary said, “My soul magnifies the Lord. My spirit has rejoiced in God my Savior, for he has looked at the humble state of his servant. For behold, from now on, all generations will call me blessed.”",
            reference: "Luke 1:46-48",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "My soul magnifies the Lord. My spirit has rejoiced in God my Savior…"
        ),
        "queenship": LiturgicalVerse(
            id: "feast-queenship",
            text: "The angel said to her, “Don’t be afraid, Mary, for you have found favor with God. Behold, you will conceive in your womb and give birth to a son, and shall name him ‘Jesus.’ He will be great and will be called the Son of the Most High. The Lord God will give him the throne of his father David, and he will reign over the house of Jacob forever. There will be no end to his Kingdom.”",
            reference: "Luke 1:30-33",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "He will be great and will be called the Son of the Most High. … There will be no end to his Kingdom."
        ),
        "nativity-mary": LiturgicalVerse(
            id: "feast-nativity-mary",
            text: "Jacob became the father of Joseph, the husband of Mary, from whom was born Jesus, who is called Christ. … Now the birth of Jesus Christ was like this: After his mother, Mary, was engaged to Joseph, before they came together, she was found pregnant by the Holy Spirit.",
            reference: "Matthew 1:16, 18",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Mary, from whom was born Jesus, who is called Christ."
        ),
        "holy-name-mary": LiturgicalVerse(
            id: "feast-holy-name-mary",
            text: "The angel said to her, “Don’t be afraid, Mary, for you have found favor with God. Behold, you will conceive in your womb and give birth to a son, and shall name him ‘Jesus.’”",
            reference: "Luke 1:30-31",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Don’t be afraid, Mary, for you have found favor with God."
        ),
        "sorrows": LiturgicalVerse(
            id: "feast-sorrows",
            text: "But standing by Jesus’ cross were his mother, his mother’s sister, Mary the wife of Clopas, and Mary Magdalene. Therefore when Jesus saw his mother, and the disciple whom he loved standing there, he said to his mother, “Woman, behold, your son!” Then he said to the disciple, “Behold, your mother!”",
            reference: "John 19:25-27",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Therefore when Jesus saw his mother, and the disciple whom he loved standing there, he said to his mother, “Woman, behold, your son!”"
        ),
        "michael": LiturgicalVerse(
            id: "feast-michael",
            text: "There was war in the sky. Michael and his angels made war on the dragon. The dragon and his angels made war. They didn’t prevail. No place was found for them any more in heaven.",
            reference: "Revelation 12:7–8",
            readingLabel: "From the First Reading",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "There was war in the sky. Michael and his angels made war on the dragon. The dragon and his angels made war. They didn’t prevail."
        ),
        "guardian-angels": LiturgicalVerse(
            id: "feast-guardian-angels",
            text: "See that you don’t despise one of these little ones, for I tell you that in heaven their angels always see the face of my Father who is in heaven.",
            reference: "Matthew 18:10",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast"
        ),
        "rosary": LiturgicalVerse(
            id: "feast-rosary",
            text: "Having come in, the angel said to her, “Rejoice, you highly favored one! The Lord is with you. Blessed are you among women!”",
            reference: "Luke 1:28",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Rejoice, you highly favored one! The Lord is with you."
        ),
        "all-saints": LiturgicalVerse(
            id: "feast-all-saints",
            text: "Blessed are the pure in heart, for they shall see God. Blessed are the peacemakers, for they shall be called children of God.",
            reference: "Matthew 5:8-9",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast"
        ),
        "all-souls": LiturgicalVerse(
            id: "feast-all-souls",
            text: "All those whom the Father gives me will come to me. He who comes to me I will in no way throw out. … This is the will of the one who sent me, that everyone who sees the Son and believes in him should have eternal life; and I will raise him up at the last day.",
            reference: "John 6:37, 40",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "He who comes to me I will in no way throw out. … I will raise him up at the last day."
        ),
        "presentation-mary": LiturgicalVerse(
            id: "feast-presentation-mary",
            text: "For whoever does the will of my Father who is in heaven, he is my brother, and sister, and mother.",
            reference: "Matthew 12:50",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast"
        ),
        "immaculate-conception": LiturgicalVerse(
            id: "feast-immaculate-conception",
            text: "Having come in, the angel said to her, “Rejoice, you highly favored one! The Lord is with you. Blessed are you among women!”",
            reference: "Luke 1:28",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Rejoice, you highly favored one! The Lord is with you."
        ),
        "guadalupe": LiturgicalVerse(
            id: "feast-guadalupe",
            text: "Why am I so favored, that the mother of my Lord should come to me? For behold, when the voice of your greeting came into my ears, the baby leaped in my womb for joy! Blessed is she who believed, for there will be a fulfillment of the things which have been spoken to her from the Lord!",
            reference: "Luke 1:43-45",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Why am I so favored, that the mother of my Lord should come to me?"
        ),
        "christmas": LiturgicalVerse(
            id: "feast-christmas",
            text: "The angel said to them, “Don’t be afraid, for behold, I bring you good news of great joy which will be to all the people. For there is born to you today, in David’s city, a Savior, who is Christ the Lord.”",
            reference: "Luke 2:10-11",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Don’t be afraid, for behold, I bring you good news of great joy which will be to all the people."
        ),

        // MARK: Movable (Easter / Advent cycle)
        "ash-wednesday": LiturgicalVerse(
            id: "feast-ash-wednesday",
            text: "“Yet even now,” says the LORD, “turn to me with all your heart, and with fasting, and with weeping, and with mourning.” Tear your heart and not your garments, and turn to the LORD, your God; for he is gracious and merciful, slow to anger, and abundant in loving kindness, and relents from sending calamity.",
            reference: "Joel 2:12-13",
            readingLabel: "From the First Reading",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Turn to me with all your heart, and with fasting, and with weeping, and with mourning. … Tear your heart and not your garments…"
        ),
        "palm-sunday": LiturgicalVerse(
            id: "feast-palm-sunday",
            text: "The multitudes who went in front of him, and those who followed, kept shouting, “Hosanna to the son of David! Blessed is he who comes in the name of the Lord! Hosanna in the highest!”",
            reference: "Matthew 21:9",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Hosanna to the son of David! Blessed is he who comes in the name of the Lord!"
        ),
        "holy-thursday": LiturgicalVerse(
            id: "feast-holy-thursday",
            text: "If I then, the Lord and the Teacher, have washed your feet, you also ought to wash one another’s feet. For I have given you an example, that you should also do as I have done to you.",
            reference: "John 13:14-15",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast"
        ),
        "good-friday": LiturgicalVerse(
            id: "feast-good-friday",
            text: "Therefore when Jesus saw his mother, and the disciple whom he loved standing there, he said to his mother, “Woman, behold, your son!” Then he said to the disciple, “Behold, your mother!” … When Jesus therefore had received the vinegar, he said, “It is finished!” Then he bowed his head and gave up his spirit.",
            reference: "John 19:26-27, 30",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "When Jesus therefore had received the vinegar, he said, “It is finished!” Then he bowed his head and gave up his spirit."
        ),
        "holy-saturday": LiturgicalVerse(
            id: "feast-holy-saturday",
            text: "The angel answered the women, “Don’t be afraid, for I know that you seek Jesus, who has been crucified. He is not here, for he has risen, just like he said. Come, see the place where the Lord was lying.”",
            reference: "Matthew 28:5-6",
            readingLabel: "From the Easter Vigil (Gospel)",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "He is not here, for he has risen, just like he said."
        ),
        "easter": LiturgicalVerse(
            id: "feast-easter",
            text: "The angel answered the women, “Don’t be afraid, for I know that you seek Jesus, who has been crucified. He is not here, for he has risen, just like he said.”",
            reference: "Matthew 28:5-6",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Don’t be afraid, for I know that you seek Jesus, who has been crucified."
        ),
        "divine-mercy": LiturgicalVerse(
            id: "feast-divine-mercy",
            text: "When therefore it was evening on that day, the first day of the week, and when the doors were locked where the disciples were assembled, for fear of the Jews, Jesus came and stood in the middle and said to them, “Peace be to you.” … Thomas answered him, “My Lord and my God!”",
            reference: "John 20:19, 28",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Peace be to you. … Thomas answered him, “My Lord and my God!”"
        ),
        "ascension": LiturgicalVerse(
            id: "feast-ascension",
            text: "When he had said these things, as they were looking, he was taken up, and a cloud received him out of their sight. While they were looking steadfastly into the sky as he went, behold, two men stood by them in white clothing, who also said, “You men of Galilee, why do you stand looking into the sky? This Jesus, who was received up from you into the sky, will come back in the same way as you saw him going into the sky.”",
            reference: "Acts 1:9-11",
            readingLabel: "From the First Reading",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "As they were looking, he was taken up, and a cloud received him out of their sight."
        ),
        "pentecost": LiturgicalVerse(
            id: "feast-pentecost",
            text: "They were all filled with the Holy Spirit and began to speak with other languages, as the Spirit gave them the ability to speak.",
            reference: "Acts 2:4",
            readingLabel: "From the First Reading",
            sourceLabel: "Scripture for this feast"
        ),
        "mother-of-the-church": LiturgicalVerse(
            id: "feast-mother-of-the-church",
            text: "Therefore when Jesus saw his mother, and the disciple whom he loved standing there, he said to his mother, “Woman, behold, your son!” Then he said to the disciple, “Behold, your mother!” From that hour, the disciple took her to his own home.",
            reference: "John 19:26-27",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Woman, behold, your son! … Behold, your mother!"
        ),
        "trinity": LiturgicalVerse(
            id: "feast-trinity",
            text: "Go and make disciples of all nations, baptizing them in the name of the Father and of the Son and of the Holy Spirit, teaching them to observe all things that I commanded you. Behold, I am with you always, even to the end of the age.",
            reference: "Matthew 28:19-20",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Baptizing them in the name of the Father and of the Son and of the Holy Spirit… I am with you always, even to the end of the age."
        ),
        "corpus-christi": LiturgicalVerse(
            id: "feast-corpus-christi",
            text: "I am the living bread which came down out of heaven. If anyone eats of this bread, he will live forever. Yes, the bread which I will give for the life of the world is my flesh.",
            reference: "John 6:51",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast"
        ),
        "sacred-heart": LiturgicalVerse(
            id: "feast-sacred-heart",
            text: "However, one of the soldiers pierced his side with a spear, and immediately blood and water came out. … Again another Scripture says, “They will look on him whom they pierced.”",
            reference: "John 19:34, 37",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "One of the soldiers pierced his side with a spear, and immediately blood and water came out."
        ),
        "immaculate-heart": LiturgicalVerse(
            id: "feast-immaculate-heart",
            text: "And he went down with them and came to Nazareth. He was subject to them, and his mother kept all these sayings in her heart.",
            reference: "Luke 2:51",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "His mother kept all these sayings in her heart."
        ),
        "christ-the-king": LiturgicalVerse(
            id: "feast-christ-the-king",
            text: "Jesus answered, “My Kingdom is not of this world.” … You say that I am a king. For this reason I have been born, and for this reason I have come into the world, that I should testify to the truth. Everyone who is of the truth listens to my voice.",
            reference: "John 18:36-37",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "For this reason I have been born, and for this reason I have come into the world, that I should testify to the truth."
        ),
        "advent-1": LiturgicalVerse(
            id: "feast-advent-1",
            text: "Watch therefore, for you don’t know in what hour your Lord comes. … Therefore also be ready, for in an hour that you don’t expect, the Son of Man will come.",
            reference: "Matthew 24:42, 44",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "Watch therefore, for you don’t know in what hour your Lord comes."
        ),
        "baptism-movable": LiturgicalVerse(
            id: "feast-baptism-movable",
            text: "Jesus, when he was baptized, went up directly from the water: and behold, the heavens were opened to him. He saw the Spirit of God descending as a dove, and coming on him. Behold, a voice out of the heavens said, “This is my beloved Son, with whom I am well pleased.”",
            reference: "Matthew 3:16-17",
            readingLabel: "From the Gospel",
            sourceLabel: "Scripture for this feast",
            homeExcerpt: "This is my beloved Son, with whom I am well pleased."
        )
    ]


    // MARK: - Verse of the day (ordinary / non-catalogued feast days)

    private static let verseOfDaySourceLabel = "A verse for today"

    private static func verseOfTheDay(on date: Date, calendar: Calendar) -> LiturgicalVerse {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % dailyVerses.count
        let entry = dailyVerses[index]
        return LiturgicalVerse(
            id: "daily-\(entry.id)",
            text: entry.full,
            reference: entry.reference,
            readingLabel: nil,
            sourceLabel: verseOfDaySourceLabel,
            fullText: entry.full,
            homeExcerpt: entry.excerpt ?? LiturgicalVerse.firstSentence(from: entry.full)
        )
    }

    /// Contemplative excerpts for a rosary home screen: Mary, prayer, mercy,
    /// trust, incarnation, and the life of Christ. Text is the World English
    /// Bible, Catholic Edition, as in FeastScriptures and the mysteries (brief
    /// liturgical windows). Rotates deterministically by day-of-year.
    private static let dailyVerses: [(id: String, reference: String, full: String, excerpt: String?)] = [
        ("v01", "Luke 1:38",
         "Mary said, “Behold, the servant of the Lord; let it be done to me according to your word.”", "Behold, the servant of the Lord; let it be done to me according to your word."),
        ("v02", "Luke 1:46-47",
         "Mary said, “My soul magnifies the Lord. My spirit has rejoiced in God my Savior…”", "My soul magnifies the Lord. My spirit has rejoiced in God my Savior…"),
        ("v03", "Luke 1:28",
         "Having come in, the angel said to her, “Rejoice, you highly favored one! The Lord is with you. Blessed are you among women!”", "Rejoice, you highly favored one! The Lord is with you."),
        ("v04", "Luke 1:42",
         "She called out with a loud voice and said, “Blessed are you among women, and blessed is the fruit of your womb!”", "Blessed are you among women, and blessed is the fruit of your womb!"),
        ("v05", "Luke 2:19",
         "But Mary kept all these sayings, pondering them in her heart.", nil),
        ("v06", "Luke 11:28",
         "But he said, “On the contrary, blessed are those who hear the word of God, and keep it.”", "Blessed are those who hear the word of God, and keep it."),
        ("v07", "John 19:26-27",
         "Therefore when Jesus saw his mother, and the disciple whom he loved standing there, he said to his mother, “Woman, behold, your son!” Then he said to the disciple, “Behold, your mother!”", "Therefore when Jesus saw his mother, and the disciple whom he loved standing there, he said to his mother, “Woman, behold, your son!”"),
        ("v08", "Matthew 11:28",
         "“Come to me, all you who labor and are heavily burdened, and I will give you rest.”", "Come to me, all you who labor and are heavily burdened, and I will give you rest."),
        ("v09", "Matthew 11:29",
         "Take my yoke upon you and learn from me, for I am gentle and humble in heart; and you will find rest for your souls.", nil),
        ("v10", "John 14:27",
         "Peace I leave with you. My peace I give to you; not as the world gives, I give to you. Don’t let your heart be troubled, neither let it be fearful.", "Peace I leave with you. My peace I give to you; not as the world gives, I give to you."),
        ("v11", "John 15:5",
         "I am the vine. You are the branches. He who remains in me and I in him bears much fruit, for apart from me you can do nothing.", "I am the vine. You are the branches. He who remains in me and I in him bears much fruit…"),
        ("v12", "John 15:9",
         "Even as the Father has loved me, I also have loved you. Remain in my love.", nil),
        ("v13", "John 10:14-15",
         "I am the good shepherd. I know my own, and I’m known by my own; even as the Father knows me, and I know the Father. I lay down my life for the sheep.", "I am the good shepherd. I know my own, and I’m known by my own…"),
        ("v14", "Matthew 6:33",
         "But seek first God’s Kingdom and his righteousness; and all these things will be given to you as well.", nil),
        ("v15", "Matthew 5:8",
         "Blessed are the pure in heart, for they shall see God.", nil),
        ("v16", "Matthew 5:9",
         "Blessed are the peacemakers, for they shall be called children of God.", nil),
        ("v17", "Matthew 5:3",
         "“Blessed are the poor in spirit, for theirs is the Kingdom of Heaven.”", "Blessed are the poor in spirit, for theirs is the Kingdom of Heaven."),
        ("v18", "Matthew 5:7",
         "Blessed are the merciful, for they shall obtain mercy.", nil),
        ("v19", "Luke 1:49",
         "For he who is mighty has done great things for me. Holy is his name.", nil),
        ("v20", "Psalm 23:1-3",
         "The LORD is my shepherd; I shall lack nothing. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul.", "The LORD is my shepherd; I shall lack nothing. He makes me lie down in green pastures."),
        ("v21", "Psalm 27:1",
         "The LORD is my light and my salvation. Whom shall I fear? The LORD is the strength of my life. Of whom shall I be afraid?", "The LORD is my light and my salvation. Whom shall I fear?"),
        ("v22", "Psalm 46:10",
         "“Be still, and know that I am God. I will be exalted among the nations. I will be exalted on the earth.”", "Be still, and know that I am God."),
        ("v23", "Psalm 51:10",
         "Create in me a clean heart, O God. Renew a right spirit within me.", nil),
        ("v24", "Psalm 130:5",
         "I wait for the LORD. My soul waits. I hope in his word.", nil),
        ("v25", "Psalm 34:8",
         "Oh taste and see that the LORD is good. Blessed is the man who takes refuge in him.", nil),
        ("v26", "Psalm 91:11",
         "For he will put his angels in charge of you, to guard you in all your ways.", nil),
        ("v27", "Isaiah 7:14",
         "Therefore the Lord himself will give you a sign. Behold, the virgin will conceive, and bear a son, and shall call his name Immanuel.", "Behold, the virgin will conceive, and bear a son, and shall call his name Immanuel."),
        ("v28", "Isaiah 9:6",
         "For a child is born to us. A son is given to us; and the government will be on his shoulders. His name will be called Wonderful Counselor, Mighty God, Everlasting Father, Prince of Peace.", "For a child is born to us. A son is given to us…"),
        ("v29", "Isaiah 40:31",
         "but those who wait for the LORD will renew their strength. They will mount up with wings like eagles. They will run, and not be weary. They will walk, and not faint.", "Those who wait for the LORD will renew their strength."),
        ("v30", "Isaiah 41:10",
         "Don’t you be afraid, for I am with you. Don’t be dismayed, for I am your God. I will strengthen you. Yes, I will help you. Yes, I will uphold you with the right hand of my righteousness.", "Don’t you be afraid, for I am with you. Don’t be dismayed, for I am your God."),
        ("v31", "Isaiah 43:1",
         "Don’t be afraid, for I have redeemed you. I have called you by your name. You are mine.", nil),
        ("v32", "Isaiah 55:6",
         "Seek the LORD while he may be found. Call on him while he is near.", nil),
        ("v33", "Micah 6:8",
         "He has shown you, O man, what is good. What does the LORD require of you, but to act justly, to love mercy, and to walk humbly with your God?", "What does the LORD require of you, but to act justly, to love mercy, and to walk humbly with your God?"),
        ("v34", "Jeremiah 29:11",
         "For I know the thoughts that I think toward you,” says the LORD, “thoughts of peace, and not of evil, to give you hope and a future.", "Thoughts of peace, and not of evil, to give you hope and a future."),
        ("v35", "Lamentations 3:22-23",
         "It is because of the LORD’s loving kindnesses that we are not consumed, because his mercies don’t fail. They are new every morning. Great is your faithfulness.", "It is because of the LORD’s loving kindnesses that we are not consumed, because his mercies don’t fail."),
        ("v36", "Matthew 1:23",
         "“Behold, the virgin shall be with child, and shall give birth to a son. They shall call his name Immanuel,” which is, being interpreted, “God with us.”", "Behold, the virgin shall be with child, and shall give birth to a son. They shall call his name Immanuel…"),
        ("v37", "Matthew 6:9-10",
         "Our Father in heaven, may your name be kept holy. Let your Kingdom come. Let your will be done on earth as it is in heaven.", "Our Father in heaven, may your name be kept holy. Let your Kingdom come."),
        ("v38", "Matthew 7:7",
         "“Ask, and it will be given you. Seek, and you will find. Knock, and it will be opened for you.”", "Ask, and it will be given you…"),
        ("v39", "Matthew 18:20",
         "For where two or three are gathered together in my name, there I am in the middle of them.", nil),
        ("v40", "Matthew 28:20",
         "Behold, I am with you always, even to the end of the age.", nil),
        ("v41", "Mark 10:15",
         "Most certainly I tell you, whoever will not receive God’s Kingdom like a little child, he will in no way enter into it.", nil),
        ("v42", "Luke 2:29-32",
         "“Now you are releasing your servant, Master, according to your word, in peace; for my eyes have seen your salvation, which you have prepared before the face of all peoples; a light for revelation to the nations, and the glory of your people Israel.”", "Now you are releasing your servant, Master, according to your word, in peace; for my eyes have seen your salvation…"),
        ("v43", "Luke 12:32",
         "“Don’t be afraid, little flock, for it is your Father’s good pleasure to give you the Kingdom.”", "Don’t be afraid, little flock, for it is your Father’s good pleasure to give you the Kingdom."),
        ("v44", "Luke 18:13",
         "But the tax collector, standing far away, wouldn’t even lift up his eyes to heaven, but beat his chest, saying, ‘God, be merciful to me, a sinner!’", "God, be merciful to me, a sinner!"),
        ("v45", "John 1:14",
         "The Word became flesh and lived among us. We saw his glory, such glory as of the only born Son of the Father, full of grace and truth.", "The Word became flesh and lived among us. … Full of grace and truth."),
        ("v46", "John 3:16",
         "For God so loved the world, that he gave his only born Son, that whoever believes in him should not perish, but have eternal life.", nil),
        ("v47", "John 6:35",
         "Jesus said to them, “I am the bread of life. Whoever comes to me will not be hungry, and whoever believes in me will never be thirsty.”", "I am the bread of life. Whoever comes to me will not be hungry, and whoever believes in me will never be thirsty."),
        ("v48", "John 8:12",
         "Again, therefore, Jesus spoke to them, saying, “I am the light of the world. He who follows me will not walk in the darkness, but will have the light of life.”", "I am the light of the world. He who follows me will not walk in the darkness, but will have the light of life."),
        ("v49", "John 11:25-26",
         "Jesus said to her, “I am the resurrection and the life. He who believes in me will still live, even if he dies. Whoever lives and believes in me will never die. Do you believe this?”", "I am the resurrection and the life. He who believes in me will still live, even if he dies."),
        ("v50", "John 13:34",
         "A new commandment I give to you, that you love one another. Just as I have loved you, you also love one another.", nil),
        ("v51", "John 16:33",
         "I have told you these things, that in me you may have peace. In the world you have trouble; but cheer up! I have overcome the world.", "In the world you have trouble; but cheer up! I have overcome the world."),
        ("v52", "John 20:29",
         "Jesus said to him, “Because you have seen me, you have believed. Blessed are those who have not seen and have believed.”", "Blessed are those who have not seen and have believed."),
        ("v53", "Acts 2:42",
         "They continued steadfastly in the apostles’ teaching and fellowship, in the breaking of bread, and prayer.", nil),
        ("v54", "Romans 8:28",
         "We know that all things work together for good for those who love God, for those who are called according to his purpose.", nil),
        ("v55", "Romans 8:38-39",
         "For I am persuaded that neither death, nor life, nor angels, nor principalities, nor things present, nor things to come, nor powers, nor height, nor depth, nor any other created thing will be able to separate us from God’s love which is in Christ Jesus our Lord.", "Nor any other created thing will be able to separate us from God’s love which is in Christ Jesus our Lord."),
        ("v56", "Romans 12:12",
         "rejoicing in hope, enduring in troubles, continuing steadfastly in prayer…", "Rejoicing in hope, enduring in troubles, continuing steadfastly in prayer…"),
        ("v57", "1 Corinthians 13:13",
         "But now faith, hope, and love remain—these three. The greatest of these is love.", nil),
        ("v58", "2 Corinthians 12:9",
         "He has said to me, “My grace is sufficient for you, for my power is made perfect in weakness.”", "My grace is sufficient for you, for my power is made perfect in weakness."),
        ("v59", "Galatians 2:20",
         "I have been crucified with Christ, and it is no longer I who live, but Christ lives in me. That life which I now live in the flesh, I live by faith in the Son of God, who loved me and gave himself up for me.", "It is no longer I who live, but Christ lives in me."),
        ("v60", "Ephesians 3:17-19",
         "that Christ may dwell in your hearts through faith, to the end that you, being rooted and grounded in love, may be strengthened to comprehend with all the saints what is the width and length and height and depth, and to know Christ’s love which surpasses knowledge, that you may be filled with all the fullness of God.", "That Christ may dwell in your hearts through faith, to the end that you, being rooted and grounded in love…"),
        ("v61", "Philippians 4:6-7",
         "In nothing be anxious, but in everything, by prayer and petition with thanksgiving, let your requests be made known to God. And the peace of God, which surpasses all understanding, will guard your hearts and your thoughts in Christ Jesus.", "In nothing be anxious, but in everything, by prayer and petition with thanksgiving, let your requests be made known to God."),
        ("v62", "Philippians 4:13",
         "I can do all things through Christ who strengthens me.", nil),
        ("v63", "Colossians 3:15",
         "And let the peace of God rule in your hearts, to which also you were called in one body, and be thankful.", "And let the peace of God rule in your hearts…"),
        ("v64", "1 Thessalonians 5:16-18",
         "Always rejoice. Pray without ceasing. In everything give thanks, for this is the will of God in Christ Jesus toward you.", "Always rejoice. Pray without ceasing. In everything give thanks…"),
        ("v65", "Hebrews 11:1",
         "Now faith is assurance of things hoped for, proof of things not seen.", nil),
        ("v66", "Hebrews 12:1-2",
         "Therefore let’s also, seeing we are surrounded by so great a cloud of witnesses, lay aside every weight and the sin which so easily entangles us, and let’s run with perseverance the race that is set before us, looking to Jesus, the author and perfecter of faith…", "Let’s run with perseverance the race that is set before us, looking to Jesus, the author and perfecter of faith…"),
        ("v67", "James 1:5",
         "But if any of you lacks wisdom, let him ask of God, who gives to all liberally and without reproach, and it will be given to him.", "If any of you lacks wisdom, let him ask of God, who gives to all liberally and without reproach…"),
        ("v68", "1 Peter 5:7",
         "casting all your worries on him, because he cares for you.", "Casting all your worries on him, because he cares for you."),
        ("v69", "1 John 4:7",
         "Beloved, let’s love one another, for love is of God; and everyone who loves has been born of God and knows God.", nil),
        ("v70", "1 John 4:16",
         "We know and have believed the love which God has for us. God is love, and he who remains in love remains in God, and God remains in him.", "God is love, and he who remains in love remains in God, and God remains in him."),
        ("v71", "Revelation 21:4",
         "He will wipe away every tear from their eyes. Death will be no more; neither will there be mourning, nor crying, nor pain any more. The first things have passed away.", "He will wipe away every tear from their eyes. Death will be no more…"),
        ("v72", "Revelation 3:20",
         "Behold, I stand at the door and knock. If anyone hears my voice and opens the door, then I will come in to him and will dine with him, and he with me.", "Behold, I stand at the door and knock."),
        ("v73", "Tobit 12:15",
         "I am Raphael, one of the seven holy angels which present the prayers of the saints and go in before the glory of the Holy One.", nil),
        ("v74", "Sirach 2:1",
         "My son, if you come to serve the Lord, prepare your soul for temptation.", nil),
        ("v75", "Wisdom 3:1",
         "But the souls of the righteous are in the hand of God, and no torment will touch them.", nil),
        ("v76", "Matthew 16:24",
         "Then Jesus said to his disciples, “If anyone desires to come after me, let him deny himself, take up his cross, and follow me.”", "If anyone desires to come after me, let him deny himself, take up his cross, and follow me."),
        ("v77", "Luke 1:30-31",
         "The angel said to her, “Don’t be afraid, Mary, for you have found favor with God. Behold, you will conceive in your womb and give birth to a son, and shall name him ‘Jesus.’”", "Don’t be afraid, Mary, for you have found favor with God."),
        ("v78", "John 2:5",
         "His mother said to the servants, “Whatever he says to you, do it.”", "Whatever he says to you, do it."),
        ("v79", "Acts 1:14",
         "All these with one accord continued steadfastly in prayer and supplication, along with the women and Mary the mother of Jesus, and with his brothers.", nil),
        ("v80", "Romans 5:5",
         "and hope doesn’t disappoint us, because God’s love has been poured into our hearts through the Holy Spirit who was given to us.", "Hope doesn’t disappoint us, because God’s love has been poured into our hearts through the Holy Spirit who was given to us."),
        ("v81", "2 Timothy 1:7",
         "For God didn’t give us a spirit of fear, but of power, love, and self-control.", nil),
        ("v82", "Jude 1:24-25",
         "Now to him who is able to keep them from stumbling, and to present you faultless before the presence of his glory in great joy, to God our Savior, who alone is wise, be glory and majesty, dominion and power, both now and forever. Amen.", "Now to him who is able to keep them from stumbling, and to present you faultless before the presence of his glory in great joy…"),
    ]
}
