package com.halalatune.halalfilter

enum class FilterLevel {
    STRICT,
    MODERATE,
    LIGHT
}

data class HalalFilterConfig(
    val level: FilterLevel = FilterLevel.MODERATE,
    val customKeywords: MutableList<String> = mutableListOf()
)

object HalalFilter {
    private val alcoholKeywords = listOf(
        "alcohol", "alcoholic", "beer", "wine", "vodka", "whiskey", "rum",
        "tequila", "brandy", "cocktail", "drunk", "drinking", "bar", "pub",
        "liquor", "spirits", "booze", "intoxicated", "hangover", "brewery",
        "khamr"
    )

    private val drugKeywords = listOf(
        "drug", "drugs", "cocaine", "heroin", "marijuana", "weed", "high",
        "smoking", "smoke", "cannabis", "meth", "crack", "pill", "xanax",
        "oxycontin", "addict", "addiction", "overdose", "trip", "tripping",
        "hashish", "hash", "narcotic"
    )

    private val gamblingKeywords = listOf(
        "gamble", "gambling", "casino", "poker", "bet", "betting", "wager",
        "lottery", "jackpot", "slot machine", "roulette", "blackjack",
        "baccarat", "dice", "sportsbook", "odds", "horses", "racing bet"
    )

    private val sexualKeywords = listOf(
        "sex", "sexual", "nude", "naked", "porn", "pornography", "explicit",
        "xxx", "erotic", "striptease", "booty", "butt", "thick",
        "booty shake", "twerk", "twink", "bitch", "hoe", "whore", "slut",
        "pussy", "dick", "fuck", "shit", "damn", "hell"
    )

    private val religiousKeywords = listOf(
        "satan", "satanic", "devil worship", "lucifer", "occult", "demon",
        "witch", "witchcraft", "spell", "magic", "pagan", "heathen",
        "blasphemy", "heretic", "anti christ", "antichrist"
    )

    private val violenceKeywords = listOf(
        "kill", "killing", "murder", "death", "die", "die die", "shoot",
        "shooting", "gun", "guns", "violence", "violent", "blood", "bloodshed",
        "gang", "gangsta", "gangster", "thug", "criminal", "crime", "rob",
        "steal", "thief", "rape", "abuse", "torture"
    )

    private val haramGenreKeywords = listOf(
        "gangsta rap", "drill", "trap", "hardcore rap", "mumble rap"
    )

    private val partyKeywords = listOf(
        "party", "partying", "club", "clubbing", "nightclub", "rave", "dj",
        "dancehall", "strip", "strip club", "bottle service", "vip",
        "turnt", "turn up", "lit", "wild", "crazy", "after party"
    )

    private val materialismKeywords = listOf(
        "billionaire", "millionaire", "rich", "wealth", "money", "cash",
        "gold", "diamond", "diamonds", "jewelry", "jewellery", "luxury",
        "designer", "gucci", "prada", "louis vuitton", "rolex", "bentley",
        "lamborghini", "ferrari", "porsche", "mansion", "yacht"
    )

    private val halalPositiveKeywords = listOf(
        "nasheed", "islamic", "quran", "quran recitation", "adhkar", "dua",
        "salah", "prayer", "allah", "muhammad", "prophet", "ramadan",
        "eid", "hajj", "umrah", "mosque", "masjid", "islamic song",
        "halal", "deen", "iman", "taqwa", "barakah", "subhanallah",
        "alhamdulillah", "allahu akbar", "mashaallah", "astaghfirullah",
        "recitation", "tilawah", "adhan", "azan", "call to prayer",
        "arabic", "islam", "muslim", "ummah", "jannah", "surah"
    )

    private var config = HalalFilterConfig()

    fun getConfig(): HalalFilterConfig = config

    fun setLevel(level: FilterLevel) {
        config = config.copy(level = level)
    }

    fun addCustomKeyword(keyword: String) {
        config = config.copy(
            customKeywords = config.customKeywords.toMutableList().apply {
                add(keyword.lowercase())
            }
        )
    }

    fun removeCustomKeyword(keyword: String) {
        config = config.copy(
            customKeywords = config.customKeywords.toMutableList().apply {
                remove(keyword.lowercase())
            }
        )
    }

    fun clearCustomKeywords() {
        config = config.copy(customKeywords = mutableListOf())
    }

    fun isHalal(
        title: String,
        artist: String?,
        album: String?,
        description: String?,
        categories: List<String>?,
        isExplicit: Boolean
    ): Boolean {
        if (isExplicit) return false

        val textToCheck = buildString {
            append(title.lowercase())
            artist?.let { append(" ${it.lowercase()}") }
            album?.let { append(" ${it.lowercase()}") }
            description?.let { append(" ${it.lowercase()}") }
            categories?.let { append(" ${it.joinToString(" ").lowercase()}") }
        }

        return when (config.level) {
            FilterLevel.LIGHT -> lightFilter(textToCheck)
            FilterLevel.MODERATE -> moderateFilter(textToCheck)
            FilterLevel.STRICT -> strictFilter(textToCheck)
        }
    }

    private fun lightFilter(text: String): Boolean {
        val keywords = drugKeywords + sexualKeywords + violenceKeywords.take(5)
        return !containsAny(text, keywords)
    }

    private fun moderateFilter(text: String): Boolean {
        val keywords = alcoholKeywords + drugKeywords + gamblingKeywords +
                       sexualKeywords + religiousKeywords + violenceKeywords
        return !containsAny(text, keywords)
    }

    private fun strictFilter(text: String): Boolean {
        val allBlocked = alcoholKeywords + drugKeywords + gamblingKeywords +
                         sexualKeywords + religiousKeywords + violenceKeywords +
                         partyKeywords + materialismKeywords + haramGenreKeywords +
                         config.customKeywords

        if (containsAny(text, allBlocked)) return false
        return true
    }

    private fun containsAny(text: String, keywords: List<String>): Boolean {
        return keywords.any { text.contains(it) }
    }

    fun getFilterReason(
        title: String,
        artist: String?,
        album: String?,
        description: String?,
        categories: List<String>?,
        isExplicit: Boolean
    ): String {
        if (isExplicit) return "Explicit content"

        val textToCheck = buildString {
            append(title.lowercase())
            artist?.let { append(" ${it.lowercase()}") }
            album?.let { append(" ${it.lowercase()}") }
            description?.let { append(" ${it.lowercase()}") }
            categories?.let { append(" ${it.joinToString(" ").lowercase()}") }
        }

        val checks = listOf(
            "Alcohol-related content" to alcoholKeywords,
            "Drug-related content" to drugKeywords,
            "Gambling-related content" to gamblingKeywords,
            "Sexual/inappropriate content" to sexualKeywords,
            "Occult/anti-religious content" to religiousKeywords,
            "Violence/criminal content" to violenceKeywords
        )

        for ((reason, keywords) in checks) {
            for (keyword in keywords) {
                if (textToCheck.contains(keyword)) {
                    return "$reason (matched: \"$keyword\")"
                }
            }
        }

        if (config.level != FilterLevel.LIGHT) {
            for ((reason, keywords) in listOf("Party/club culture" to partyKeywords)) {
                for (keyword in keywords) {
                    if (textToCheck.contains(keyword)) {
                        return "$reason (matched: \"$keyword\")"
                    }
                }
            }
        }

        if (config.level == FilterLevel.STRICT) {
            for ((reason, keywords) in listOf(
                "Materialism/wealth focus" to materialismKeywords,
                "Haram genre" to haramGenreKeywords
            )) {
                for (keyword in keywords) {
                    if (textToCheck.contains(keyword)) {
                        return "$reason (matched: \"$keyword\")"
                    }
                }
            }
        }

        return "Passed filter"
    }

    fun getBlockedKeywords(): Map<String, List<String>> = mapOf(
        "Alcohol" to alcoholKeywords,
        "Drugs" to drugKeywords,
        "Gambling" to gamblingKeywords,
        "Sexual Content" to sexualKeywords,
        "Anti-Religious" to religiousKeywords,
        "Violence" to violenceKeywords,
        "Party/Club" to partyKeywords,
        "Materialism" to materialismKeywords,
        "Haram Genres" to haramGenreKeywords,
        "Custom" to config.customKeywords
    )

    fun reset() {
        config = HalalFilterConfig()
    }
}
