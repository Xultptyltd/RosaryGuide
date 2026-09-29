import Foundation

/// A short verse for Home “Scripture for today”.
/// Feast days use curated Mass-reading excerpts; ordinary days use a rotating
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
    /// Which Mass reading the verse comes from, when known (feast days only).
    var readingLabel: String?
    /// Secondary Home label under the citation.
    /// Feasts: “From today’s liturgy”. Ordinary days: “A verse for today”.
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
        let value = sourceLabel ?? readingLabel
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

        // 1. Feast already modeled in the app with Mass / feast Scripture.
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
            sourceLabel: "From today’s liturgy",
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

    /// Particularly meaningful single verses for feast Mass readings.
    /// Expand freely; unknown feast ids fall through to FeastScriptures.
    private static let byFeastId: [String: LiturgicalVerse] = [
        "michael": LiturgicalVerse(
            id: "feast-michael",
            text: "Now war arose in heaven, Michael and his angels fighting against the dragon; and the dragon and his angels fought, but they were defeated and there was no longer any place for them in heaven.",
            reference: "Revelation 12:7–8",
            readingLabel: "First Reading",
            sourceLabel: "From today’s liturgy",
            homeExcerpt: "Now war arose in heaven, Michael and his angels fighting against the dragon; and the dragon and his angels fought, but they were defeated."
        ),
        "guardian-angels": LiturgicalVerse(
            id: "feast-guardian-angels",
            text: "See that you do not despise one of these little ones; for I tell you that in heaven their angels always behold the face of my Father who is in heaven.",
            reference: "Matthew 18:10",
            readingLabel: "Gospel",
            sourceLabel: "From today’s liturgy"
        ),
        "rosary": LiturgicalVerse(
            id: "feast-rosary",
            text: "And he came to her and said, “Hail, full of grace, the Lord is with you!”",
            reference: "Luke 1:28",
            readingLabel: "Gospel",
            sourceLabel: "From today’s liturgy"
        ),
        "all-saints": LiturgicalVerse(
            id: "feast-all-saints",
            text: "Blessed are the pure in heart, for they shall see God. Blessed are the peacemakers, for they shall be called sons of God.",
            reference: "Matthew 5:8-9",
            readingLabel: "Gospel",
            sourceLabel: "From today’s liturgy"
        ),
        "christmas": LiturgicalVerse(
            id: "feast-christmas",
            text: "And the angel said to them, “Be not afraid; for behold, I bring you good news of a great joy which will come to all the people; for to you is born this day in the city of David a Savior, who is Christ the Lord.”",
            reference: "Luke 2:10-11",
            readingLabel: "Gospel",
            sourceLabel: "From today’s liturgy"
        ),
        "assumption": LiturgicalVerse(
            id: "feast-assumption",
            text: "And Mary said, “My soul magnifies the Lord, and my spirit rejoices in God my Savior, for he has regarded the low estate of his handmaiden. For behold, henceforth all generations will call me blessed.”",
            reference: "Luke 1:46-48",
            readingLabel: "Gospel",
            sourceLabel: "From today’s liturgy"
        ),
        "immaculate-conception": LiturgicalVerse(
            id: "feast-immaculate-conception",
            text: "And he came to her and said, “Hail, full of grace, the Lord is with you!”",
            reference: "Luke 1:28",
            readingLabel: "Gospel",
            sourceLabel: "From today’s liturgy"
        ),
        "annunciation": LiturgicalVerse(
            id: "feast-annunciation",
            text: "And Mary said, “Behold, I am the handmaid of the Lord; let it be to me according to your word.”",
            reference: "Luke 1:38",
            readingLabel: "Gospel",
            sourceLabel: "From today’s liturgy"
        ),
        "easter": LiturgicalVerse(
            id: "feast-easter",
            text: "But the angel said to the women, “Do not be afraid; for I know that you seek Jesus who was crucified. He is not here; for he has risen, as he said.”",
            reference: "Matthew 28:5-6",
            readingLabel: "Gospel",
            sourceLabel: "From today’s liturgy"
        ),
        "pentecost": LiturgicalVerse(
            id: "feast-pentecost",
            text: "And they were all filled with the Holy Spirit and began to speak in other tongues, as the Spirit gave them utterance.",
            reference: "Acts 2:4",
            readingLabel: "First Reading",
            sourceLabel: "From today’s liturgy"
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
    /// trust, incarnation, and the life of Christ. Wording matches the app’s
    /// existing Scripture style (brief liturgical windows already used in
    /// FeastScriptures / mysteries). Rotates deterministically by day-of-year.
    private static let dailyVerses: [(id: String, reference: String, full: String, excerpt: String?)] = [
        ("v01", "Luke 1:38",
         "And Mary said, “Behold, I am the handmaid of the Lord; let it be to me according to your word.”", nil),
        ("v02", "Luke 1:46-47",
         "And Mary said, “My soul magnifies the Lord, and my spirit rejoices in God my Savior.”", nil),
        ("v03", "Luke 1:28",
         "And he came to her and said, “Hail, full of grace, the Lord is with you!”", nil),
        ("v04", "Luke 1:42",
         "And she exclaimed with a loud cry, “Blessed are you among women, and blessed is the fruit of your womb!”", nil),
        ("v05", "Luke 2:19",
         "But Mary kept all these things, pondering them in her heart.", nil),
        ("v06", "Luke 11:28",
         "But he said, “Blessed rather are those who hear the word of God and keep it!”", nil),
        ("v07", "John 19:26-27",
         "When Jesus saw his mother, and the disciple whom he loved standing near, he said to his mother, “Woman, behold, your son!” Then he said to the disciple, “Behold, your mother!”",
         "When Jesus saw his mother, and the disciple whom he loved standing near, he said to his mother, “Woman, behold, your son!”"),
        ("v08", "Matthew 11:28",
         "Come to me, all who labor and are heavy laden, and I will give you rest.", nil),
        ("v09", "Matthew 11:29",
         "Take my yoke upon you, and learn from me; for I am gentle and lowly in heart, and you will find rest for your souls.", nil),
        ("v10", "John 14:27",
         "Peace I leave with you; my peace I give to you; not as the world gives do I give to you. Let not your hearts be troubled, neither let them be afraid.",
         "Peace I leave with you; my peace I give to you; not as the world gives do I give to you."),
        ("v11", "John 15:5",
         "I am the vine, you are the branches. He who abides in me, and I in him, he it is that bears much fruit, for apart from me you can do nothing.",
         "I am the vine, you are the branches. He who abides in me, and I in him, he it is that bears much fruit."),
        ("v12", "John 15:9",
         "As the Father has loved me, so have I loved you; abide in my love.", nil),
        ("v13", "John 10:14-15",
         "I am the good shepherd; I know my own and my own know me, as the Father knows me and I know the Father; and I lay down my life for the sheep.",
         "I am the good shepherd; I know my own and my own know me."),
        ("v14", "Matthew 6:33",
         "But seek first his kingdom and his righteousness, and all these things shall be yours as well.", nil),
        ("v15", "Matthew 5:8",
         "Blessed are the pure in heart, for they shall see God.", nil),
        ("v16", "Matthew 5:9",
         "Blessed are the peacemakers, for they shall be called sons of God.", nil),
        ("v17", "Matthew 5:3",
         "Blessed are the poor in spirit, for theirs is the kingdom of heaven.", nil),
        ("v18", "Matthew 5:7",
         "Blessed are the merciful, for they shall obtain mercy.", nil),
        ("v19", "Luke 1:49",
         "For he who is mighty has done great things for me, and holy is his name.", nil),
        ("v20", "Psalm 23:1-3",
         "The Lord is my shepherd, I shall not want; he makes me lie down in green pastures. He leads me beside still waters; he restores my soul.",
         "The Lord is my shepherd, I shall not want; he makes me lie down in green pastures."),
        ("v21", "Psalm 27:1",
         "The Lord is my light and my salvation; whom shall I fear? The Lord is the stronghold of my life; of whom shall I be afraid?",
         "The Lord is my light and my salvation; whom shall I fear?"),
        ("v22", "Psalm 46:10",
         "Be still, and know that I am God. I am exalted among the nations, I am exalted in the earth!",
         "Be still, and know that I am God."),
        ("v23", "Psalm 51:10",
         "Create in me a clean heart, O God, and put a new and right spirit within me.", nil),
        ("v24", "Psalm 130:5",
         "I wait for the Lord, my soul waits, and in his word I hope.", nil),
        ("v25", "Psalm 34:8",
         "O taste and see that the Lord is good! Happy is the man who takes refuge in him!", nil),
        ("v26", "Psalm 91:11",
         "For he will give his angels charge of you to guard you in all your ways.", nil),
        ("v27", "Isaiah 7:14",
         "Therefore the Lord himself will give you a sign. Behold, a virgin shall conceive and bear a son, and shall call his name Immanuel.",
         "Behold, a virgin shall conceive and bear a son, and shall call his name Immanuel."),
        ("v28", "Isaiah 9:6",
         "For to us a child is born, to us a son is given; and the government will be upon his shoulder, and his name will be called “Wonderful Counselor, Mighty God, Everlasting Father, Prince of Peace.”",
         "For to us a child is born, to us a son is given."),
        ("v29", "Isaiah 40:31",
         "But they who wait for the Lord shall renew their strength, they shall mount up with wings like eagles, they shall run and not be weary, they shall walk and not faint.",
         "But they who wait for the Lord shall renew their strength."),
        ("v30", "Isaiah 41:10",
         "Fear not, for I am with you, be not dismayed, for I am your God; I will strengthen you, I will help you, I will uphold you with my victorious right hand.",
         "Fear not, for I am with you, be not dismayed, for I am your God."),
        ("v31", "Isaiah 43:1",
         "Fear not, for I have redeemed you; I have called you by name, you are mine.", nil),
        ("v32", "Isaiah 55:6",
         "Seek the Lord while he may be found, call upon him while he is near.", nil),
        ("v33", "Micah 6:8",
         "He has showed you, O man, what is good; and what does the Lord require of you but to do justice, and to love kindness, and to walk humbly with your God?",
         "What does the Lord require of you but to do justice, and to love kindness, and to walk humbly with your God?"),
        ("v34", "Jeremiah 29:11",
         "For I know the plans I have for you, says the Lord, plans for welfare and not for evil, to give you a future and a hope.", nil),
        ("v35", "Lamentations 3:22-23",
         "The steadfast love of the Lord never ceases, his mercies never come to an end; they are new every morning; great is thy faithfulness.",
         "The steadfast love of the Lord never ceases, his mercies never come to an end."),
        ("v36", "Matthew 1:23",
         "Behold, a virgin shall conceive and bear a son, and his name shall be called Emmanuel (which means, God with us).",
         "Behold, a virgin shall conceive and bear a son, and his name shall be called Emmanuel."),
        ("v37", "Matthew 6:9-10",
         "Pray then like this: Our Father who art in heaven, Hallowed be thy name. Thy kingdom come. Thy will be done, On earth as it is in heaven.",
         "Our Father who art in heaven, Hallowed be thy name. Thy kingdom come."),
        ("v38", "Matthew 7:7",
         "Ask, and it will be given you; seek, and you will find; knock, and it will be opened to you.", nil),
        ("v39", "Matthew 18:20",
         "For where two or three are gathered in my name, there am I in the midst of them.", nil),
        ("v40", "Matthew 28:20",
         "And lo, I am with you always, to the close of the age.", nil),
        ("v41", "Mark 10:15",
         "Truly, I say to you, whoever does not receive the kingdom of God like a child shall not enter it.", nil),
        ("v42", "Luke 2:29-32",
         "Lord, now let your servant depart in peace, according to your word; for my eyes have seen your salvation which you have prepared in the presence of all peoples, a light for revelation to the Gentiles, and for glory to your people Israel.",
         "Lord, now let your servant depart in peace, according to your word; for my eyes have seen your salvation."),
        ("v43", "Luke 12:32",
         "Fear not, little flock, for it is your Father’s good pleasure to give you the kingdom.", nil),
        ("v44", "Luke 18:13",
         "But the tax collector, standing far off, would not even lift up his eyes to heaven, but beat his breast, saying, “God, be merciful to me a sinner!”",
         "God, be merciful to me a sinner!"),
        ("v45", "John 1:14",
         "And the Word became flesh and dwelt among us, full of grace and truth; we have beheld his glory, glory as of the only Son from the Father.",
         "And the Word became flesh and dwelt among us, full of grace and truth."),
        ("v46", "John 3:16",
         "For God so loved the world that he gave his only Son, that whoever believes in him should not perish but have eternal life.", nil),
        ("v47", "John 6:35",
         "Jesus said to them, “I am the bread of life; he who comes to me shall not hunger, and he who believes in me shall never thirst.”",
         "I am the bread of life; he who comes to me shall not hunger, and he who believes in me shall never thirst."),
        ("v48", "John 8:12",
         "Again Jesus spoke to them, saying, “I am the light of the world; he who follows me will not walk in darkness, but will have the light of life.”",
         "I am the light of the world; he who follows me will not walk in darkness, but will have the light of life."),
        ("v49", "John 11:25-26",
         "Jesus said to her, “I am the resurrection and the life; he who believes in me, though he die, yet shall he live, and whoever lives and believes in me shall never die.”",
         "I am the resurrection and the life; he who believes in me, though he die, yet shall he live."),
        ("v50", "John 13:34",
         "A new commandment I give to you, that you love one another; even as I have loved you, that you also love one another.", nil),
        ("v51", "John 16:33",
         "I have said this to you, that in me you may have peace. In the world you have tribulation; but be of good cheer, I have overcome the world.",
         "In the world you have tribulation; but be of good cheer, I have overcome the world."),
        ("v52", "John 20:29",
         "Jesus said to him, “Have you believed because you have seen me? Blessed are those who have not seen and yet believe.”",
         "Blessed are those who have not seen and yet believe."),
        ("v53", "Acts 2:42",
         "And they devoted themselves to the apostles’ teaching and fellowship, to the breaking of bread and the prayers.", nil),
        ("v54", "Romans 8:28",
         "We know that in everything God works for good with those who love him, who are called according to his purpose.", nil),
        ("v55", "Romans 8:38-39",
         "For I am sure that neither death, nor life, nor angels, nor principalities, nor things present, nor things to come, nor powers, nor height, nor depth, nor anything else in all creation, will be able to separate us from the love of God in Christ Jesus our Lord.",
         "Nothing in all creation will be able to separate us from the love of God in Christ Jesus our Lord."),
        ("v56", "Romans 12:12",
         "Rejoice in your hope, be patient in tribulation, be constant in prayer.", nil),
        ("v57", "1 Corinthians 13:13",
         "So faith, hope, love abide, these three; but the greatest of these is love.", nil),
        ("v58", "2 Corinthians 12:9",
         "But he said to me, “My grace is sufficient for you, for my power is made perfect in weakness.”", nil),
        ("v59", "Galatians 2:20",
         "I have been crucified with Christ; it is no longer I who live, but Christ who lives in me; and the life I now live in the flesh I live by faith in the Son of God, who loved me and gave himself for me.",
         "It is no longer I who live, but Christ who lives in me."),
        ("v60", "Ephesians 3:17-19",
         "That Christ may dwell in your hearts through faith; that you, being rooted and grounded in love, may have power to comprehend with all the saints what is the breadth and length and height and depth, and to know the love of Christ which surpasses knowledge, that you may be filled with all the fullness of God.",
         "That Christ may dwell in your hearts through faith; that you, being rooted and grounded in love."),
        ("v61", "Philippians 4:6-7",
         "Have no anxiety about anything, but in everything by prayer and supplication with thanksgiving let your requests be made known to God. And the peace of God, which passes all understanding, will keep your hearts and your minds in Christ Jesus.",
         "Have no anxiety about anything, but in everything by prayer and supplication with thanksgiving let your requests be made known to God."),
        ("v62", "Philippians 4:13",
         "I can do all things in him who strengthens me.", nil),
        ("v63", "Colossians 3:15",
         "And let the peace of Christ rule in your hearts, to which indeed you were called in the one body. And be thankful.",
         "And let the peace of Christ rule in your hearts."),
        ("v64", "1 Thessalonians 5:16-18",
         "Rejoice always, pray constantly, give thanks in all circumstances; for this is the will of God in Christ Jesus for you.",
         "Rejoice always, pray constantly, give thanks in all circumstances."),
        ("v65", "Hebrews 11:1",
         "Now faith is the assurance of things hoped for, the conviction of things not seen.", nil),
        ("v66", "Hebrews 12:1-2",
         "Therefore, since we are surrounded by so great a cloud of witnesses, let us also lay aside every weight, and sin which clings so closely, and let us run with perseverance the race that is set before us, looking to Jesus the pioneer and perfecter of our faith.",
         "Let us run with perseverance the race that is set before us, looking to Jesus the pioneer and perfecter of our faith."),
        ("v67", "James 1:5",
         "If any of you lacks wisdom, let him ask God, who gives to all men generously and without reproaching, and it will be given him.",
         "If any of you lacks wisdom, let him ask God, who gives to all men generously and without reproaching."),
        ("v68", "1 Peter 5:7",
         "Cast all your anxieties on him, for he cares about you.", nil),
        ("v69", "1 John 4:7",
         "Beloved, let us love one another; for love is of God, and he who loves is born of God and knows God.", nil),
        ("v70", "1 John 4:16",
         "So we know and believe the love God has for us. God is love, and he who abides in love abides in God, and God abides in him.",
         "God is love, and he who abides in love abides in God, and God abides in him."),
        ("v71", "Revelation 21:4",
         "He will wipe away every tear from their eyes, and death shall be no more, neither shall there be mourning nor crying nor pain any more, for the former things have passed away.",
         "He will wipe away every tear from their eyes, and death shall be no more."),
        ("v72", "Revelation 3:20",
         "Behold, I stand at the door and knock; if any one hears my voice and opens the door, I will come in to him and eat with him, and he with me.",
         "Behold, I stand at the door and knock."),
        ("v73", "Tobit 12:15",
         "I am Raphael, one of the seven holy angels who present the prayers of the saints and enter into the presence of the glory of the Holy One.", nil),
        ("v74", "Sirach 2:1",
         "My son, if you come forward to serve the Lord, prepare yourself for temptation.", nil),
        ("v75", "Wisdom 3:1",
         "But the souls of the righteous are in the hand of God, and no torment will ever touch them.", nil),
        ("v76", "Matthew 16:24",
         "Then Jesus told his disciples, “If any man would come after me, let him deny himself and take up his cross and follow me.”",
         "If any man would come after me, let him deny himself and take up his cross and follow me."),
        ("v77", "Luke 1:30-31",
         "And the angel said to her, “Do not be afraid, Mary, for you have found favor with God. And behold, you will conceive in your womb and bear a son, and you shall call his name Jesus.”",
         "Do not be afraid, Mary, for you have found favor with God."),
        ("v78", "John 2:5",
         "His mother said to the servants, “Do whatever he tells you.”", nil),
        ("v79", "Acts 1:14",
         "All these with one accord devoted themselves to prayer, together with the women and Mary the mother of Jesus, and with his brethren.", nil),
        ("v80", "Romans 5:5",
         "And hope does not disappoint us, because God’s love has been poured into our hearts through the Holy Spirit who has been given to us.", nil),
        ("v81", "2 Timothy 1:7",
         "For God did not give us a spirit of timidity but a spirit of power and love and self-control.", nil),
        ("v82", "Jude 1:24-25",
         "Now to him who is able to keep you from falling and to present you without blemish before the presence of his glory with rejoicing, to the only God, our Savior through Jesus Christ our Lord, be glory, majesty, dominion, and authority, before all time and now and for ever. Amen.",
         "Now to him who is able to keep you from falling and to present you without blemish before the presence of his glory with rejoicing."),
    ]
}
