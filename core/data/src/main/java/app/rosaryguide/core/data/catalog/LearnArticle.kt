package app.rosaryguide.core.data.catalog

/**
 * Learn-tab articles, ported from iOS `LearnArticle` in `PrayHubView`.
 * [commonQuestions] is the display order on the Learn screen.
 */
enum class LearnArticle(
    val id: String,
    val title: String,
    val eyebrow: String,
    val paragraphs: List<String>,
) {
    WhatIsRosary(
        id = "whatIsRosary",
        title = "What is the Rosary?",
        eyebrow = "Start here",
        paragraphs = listOf(
                "The Rosary is a prayer that helps us reflect on the lives of Jesus and Mary.",
                "It is rooted in centuries of Christian prayer and developed gradually during the Middle Ages. Christians were praying early forms of the Rosary long before the Protestant Reformation.",
                "We repeat prayers such as the Our Father and Hail Mary while thinking about important events in the lives of Jesus and Mary. These events are called mysteries.",
                "A typical Rosary has five sections, called decades. Each decade includes x10 Hail Marys and focuses on one mystery. Rosary beads help us keep track of the prayers.",
        ),
    ),
    HowToPray(
        id = "howToPray",
        title = "How do I pray the Rosary?",
        eyebrow = "Common question",
        paragraphs = listOf(
                "1. Begin with the opening prayers: Sign of the Cross, Apostles’ Creed, x1 Our Father, x3 Hail Marys and x1 Glory Be.",
                "2. Begin the first decade: read the first mystery and take a moment to think about it.",
                "3. Pray x1 Our Father, x10 Hail Marys and x1 Glory Be, reflecting on the mystery as you pray.",
                "4. Repeat for all five mysteries, following the same pattern.",
                "5. Finish with Hail, Holy Queen and Sign of the Cross.",
                "It’s natural for your mind to wander. When you notice, gently return your attention to the prayer or mystery.",
        ),
    ),
    Beads(
        id = "beads",
        title = "Do I need beads?",
        eyebrow = "Common question",
        paragraphs = listOf(
                "Rosary beads help your fingers keep the place so your mind can pray. They are useful, but they are not required.",
                "You can pray with beads, with your fingers, by following the app step by step, or by praying one decade slowly from memory.",
                "The beads are a physical guide: the crucifix begins the prayer, the large beads mark Our Fathers, and the small beads mark Hail Marys.",
        ),
    ),
    OneDecade(
        id = "oneDecade",
        title = "Can I pray one decade?",
        eyebrow = "Common question",
        paragraphs = listOf(
                "Yes. One decade is a real and worthy way to pray, especially when you are beginning or when time is limited.",
                "Choose one mystery, pray one Our Father, ten Hail Marys, and a Glory Be. Stay with that scene from the life of Christ.",
                "A small prayer prayed attentively is better than a long prayer rushed without love.",
        ),
    ),
    LosePlace(
        id = "losePlace",
        title = "What if I lose my place?",
        eyebrow = "Common question",
        paragraphs = listOf(
                "Do not worry. Losing your place is common, especially at the beginning.",
                "Pause, breathe, and return to the next prayer you remember. The point is not perfect counting; the point is faithful attention.",
                "The app can guide each step so you can learn the rhythm without pressure.",
        ),
    ),
    Repetition(
        id = "repetition",
        title = "Why repeat prayers?",
        eyebrow = "Common question",
        paragraphs = listOf(
                "The repetition of the Rosary is meant to become gentle and contemplative.",
                "Like breathing, walking, or listening to a familiar song, repeated words can make space for deeper attention.",
                "The prayers hold you steady while the mysteries invite you to look at Jesus with the Blessed Virgin Mary.",
        ),
    ),
    Meditate(
        id = "meditate",
        title = "How do I meditate on the mysteries?",
        eyebrow = "Common question",
        paragraphs = listOf(
                "Name the mystery at the start of the decade, then recall the Gospel scene in a sentence or two: who is there, and what Our Lord is doing.",
                "Hold that scene in mind through the Our Father, the ten Hail Marys, and the Glory Be. If your thoughts wander, come back to the mystery. There is no need to begin the decade again.",
                "You may read a short reflection once before the prayers begin. The repeated words keep the rhythm. The mystery is what you stay with.",
        ),
    ),
    Mary(
        id = "mary",
        title = "Why pray with Mary?",
        eyebrow = "Common question",
        paragraphs = listOf(
                "Catholics do not pray to the Blessed Virgin Mary as if she were God. We ask her to pray with us and for us.",
                "The Blessed Virgin Mary’s role is always to lead us to Jesus. The Rosary is Marian because it is deeply Christ-centered.",
                "In each mystery, the Blessed Virgin Mary helps the person praying stay close to the life of her Son.",
        ),
    );

    companion object {
        val commonQuestions: List<LearnArticle> = entries
        fun byId(id: String): LearnArticle? = entries.find { it.id == id }
    }
}
