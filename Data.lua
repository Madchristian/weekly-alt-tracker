local _, WAT = ...

local Data = {}
WAT.Data = Data

-- Currency-IDs der Midnight-Dämmerwappen. Namen kommen zur Laufzeit lokalisiert
-- aus C_CurrencyInfo; labelKey verweist auf das eigene Kurzlabel in
-- Localization.lua. Der Kurzbuchstabe ist in beiden Sprachen identisch und
-- deshalb sprachneutral hier gespeichert.
Data.CRESTS = {
    champion = { currencyID = 3343, short = "C", labelKey = "CREST_CHAMPION" },
    hero = { currencyID = 3345, short = "H", labelKey = "CREST_HERO" },
    myth = { currencyID = 3347, short = "M", labelKey = "CREST_MYTH" },
}

-- Midnight-Meta-Weekly. Der Pool enthält auch die Raid-Variante, damit das Addon
-- eine vom Spieler gewählte Weekly erkennen kann. Es gibt dennoch keinerlei
-- Raid-Vault- oder Raid-Fortschritts-Tracker.
Data.META_QUESTS = {
    93766, 93767, 93769, 93889, 93890,
    93891, 93892, 93909, 93910, 93911,
    93912, 93913, 94457, 95842, 95843,
}
-- Das Label einer Meta-Weekly ist kein gespeicherter Text, sondern entsteht
-- zur Renderzeit aus der questID. Gespeichert wird ausschliesslich die ID,
-- damit in den SavedVariables kein eigener Locale-Text landet und ein
-- Sprachwechsel den Altbestand sofort korrekt anzeigt.
function Data.MetaQuestLabelKey(questID)
    if type(questID) ~= "number" then return nil end
    return "META_QUEST_" .. questID
end

Data.PREY_GOAL = 4
Data.PREY_NORMAL = {
    91095, 91096, 91097, 91098, 91099, 91100, 91101, 91102, 91103, 91104,
    91105, 91106, 91107, 91108, 91109, 91110, 91111, 91112, 91113, 91114,
    91115, 91116, 91117, 91118, 91119, 91120, 91121, 91122, 91123, 91124,
}
Data.PREY_HARD = {
    91210, 91212, 91214, 91216, 91218, 91220, 91222, 91224, 91226, 91228,
    91230, 91232, 91234, 91236, 91238, 91240, 91242, 91243, 91244, 91245,
    91246, 91247, 91248, 91249, 91250, 91251, 91252, 91253, 91254, 91255,
}
Data.PREY_NIGHTMARE = {
    91211, 91213, 91215, 91217, 91219, 91221, 91223, 91225, 91227, 91229,
    91231, 91233, 91235, 91237, 91239, 91241, 91256, 91257, 91258, 91259,
    91260, 91261, 91262, 91263, 91264, 91265, 91266, 91267, 91268, 91269,
}

Data.RITUAL_QUEST_ID = 95843

-- Weitere bestätigte Quellen für Mythische Dämmerwappen (Raid ausgeschlossen).
Data.CRACKED_KEYSTONE_QUEST_ID = 92600
Data.NULLAEUS_T11_ACHIEVEMENT_ID = 61798
Data.HERO_TO_MYTH_ACHIEVEMENT_ID = 42769
Data.GILDED_MYTH_PER_STASH = 5
Data.RITUAL_T6_MYTH_PER_RUN = 5
Data.CRACKED_KEYSTONE_MYTH_REWARD = 20
Data.CRACKED_KEYSTONE_HERO_REWARD = 20
Data.NULLAEUS_T11_MYTH_REWARD = 30
Data.HERO_TO_MYTH_HERO_COST = 30
Data.HERO_TO_MYTH_MYTH_REWARD = 10

-- Schlüssel ist die lokalisierungsunabhängige Basis-Skill-Line-ID aus
-- GetProfessionInfo(...), Rückgabewert 7.
Data.PROFESSION_WEEKLIES = {
    [171] = { 93690 },
    [164] = { 93691 },
    [202] = { 93692 },
    [773] = { 93693 },
    [755] = { 93694 },
    [165] = { 93695 },
    [197] = { 93696 },
    [333] = { 93697, 93698, 93699 },
    [182] = { 93700, 93701, 93702, 93703, 93704 },
    [186] = { 93705, 93706, 93707, 93708, 93709 },
    [393] = { 93710, 93711, 93712, 93713, 93714 },
}
Data.PROFESSION_TREATISES = {
    [171] = { 95127 },
    [164] = { 95128 },
    [202] = { 95138 },
    [773] = { 95131 },
    [755] = { 95133 },
    [165] = { 95134 },
    [197] = { 95137 },
    [333] = { 95129 },
    [182] = { 95130 },
    [186] = { 95135 },
    [393] = { 95136 },
}

-- Erweiterungsspezifische Skill-Line-IDs für Midnight. Die Basis-ID identifiziert
-- den Beruf unabhängig von Sprache und Erweiterung; C_ProfSpecs benötigt dagegen
-- die jeweilige Midnight-Skill-Line.
Data.MIDNIGHT_PROFESSION_SKILL_LINES = {
    [171] = 2906, -- Alchemie
    [164] = 2907, -- Schmiedekunst
    [333] = 2909, -- Verzauberkunst
    [202] = 2910, -- Ingenieurskunst
    [182] = 2912, -- Kräuterkunde
    [773] = 2913, -- Inschriftenkunde
    [755] = 2914, -- Juwelierskunst
    [165] = 2915, -- Lederverarbeitung
    [186] = 2916, -- Bergbau
    [393] = 2917, -- Kürschnerei
    [197] = 2918, -- Schneiderei
}

-- Midnight-Wissensgegenstände: 169 faktische Item-IDs, das sind 169 der 170
-- IDs aus BetterBags_AllCraftingKnowledge 1.0.14 (RaithZ, Data/Midnight.lua).
-- Bewusst ausgelassen ist 255157 ("Abyss Angler's Fish Log"), ein
-- Angel-Wissensgegenstand: Angeln wird hier nicht als Hauptberuf getrackt.
-- Eine unabhängige vollständige Erhebung wird nicht behauptet. Kein fremder
-- Quelltext, Text oder Asset ist übernommen; Struktur und Codeausdruck unten
-- sind eigenständig.
-- Details und Lizenzstatus siehe THIRD_PARTY_NOTICES.md.
-- Gespeichert werden ausschließlich Item-ID, Basisberuf und Wissenswert.
Data.MIDNIGHT_KNOWLEDGE_ITEMS = {}
local function AddKnowledgeItems(professionID, points, itemIDs)
    for _, itemID in ipairs(itemIDs) do
        Data.MIDNIGHT_KNOWLEDGE_ITEMS[itemID] = {
            professionID = professionID,
            points = points,
        }
    end
end

-- Thalassische Traktate (+1).
AddKnowledgeItems(171, 1, { 245755 })
AddKnowledgeItems(164, 1, { 245763 })
AddKnowledgeItems(333, 1, { 245759 })
AddKnowledgeItems(202, 1, { 245809 })
AddKnowledgeItems(182, 1, { 245761 })
AddKnowledgeItems(773, 1, { 245757 })
AddKnowledgeItems(755, 1, { 245760 })
AddKnowledgeItems(165, 1, { 245758 })
AddKnowledgeItems(186, 1, { 245762 })
AddKnowledgeItems(393, 1, { 245828 })
AddKnowledgeItems(197, 1, { 245756 })

-- Einmalige Händlerbücher (+10).
AddKnowledgeItems(171, 10, { 262645 })
AddKnowledgeItems(164, 10, { 262644 })
AddKnowledgeItems(333, 10, { 250445, 257600 })
AddKnowledgeItems(202, 10, { 262646 })
AddKnowledgeItems(182, 10, { 258410, 250443 })
AddKnowledgeItems(773, 10, { 258411 })
AddKnowledgeItems(755, 10, { 257599 })
AddKnowledgeItems(165, 10, { 250922 })
AddKnowledgeItems(186, 10, { 250444, 250924 })
AddKnowledgeItems(393, 10, { 250360, 250923 })
AddKnowledgeItems(197, 10, { 257601 })

-- Einmalige offene Berufsschätze (+3).
AddKnowledgeItems(171, 3, { 238532, 238533, 238534, 238535, 238536, 238537, 238538, 238539 })
AddKnowledgeItems(164, 3, { 238540, 238541, 238542, 238543, 238544, 238545, 238546, 238547 })
AddKnowledgeItems(333, 3, { 238548, 238549, 238550, 238551, 238552, 238553, 238554, 238555 })
AddKnowledgeItems(202, 3, { 238556, 238557, 238558, 238559, 238560, 238561, 238562, 238563 })
AddKnowledgeItems(182, 3, { 238468, 238469, 238470, 238471, 238472, 238473, 238474, 238475 })
AddKnowledgeItems(773, 3, { 238572, 238573, 238574, 238575, 238576, 238577, 238578, 238579 })
AddKnowledgeItems(755, 3, { 238580, 238581, 238582, 238583, 238584, 238585, 238586, 238587 })
AddKnowledgeItems(165, 3, { 238588, 238589, 238590, 238591, 238592, 238593, 238594, 238595 })
AddKnowledgeItems(186, 3, { 238596, 238597, 238598, 238599, 238600, 238601, 238602, 238603 })
AddKnowledgeItems(393, 3, { 238628, 238629, 238630, 238631, 238632, 238633, 238634, 238635 })
AddKnowledgeItems(197, 3, { 238612, 238613, 238614, 238615, 238616, 238617, 238618, 238619 })

-- Wöchentliche Questbelohnungen.
AddKnowledgeItems(171, 1, { 263454 })
AddKnowledgeItems(164, 2, { 263455 })
AddKnowledgeItems(333, 3, { 263464 })
AddKnowledgeItems(202, 1, { 263456 })
AddKnowledgeItems(182, 3, { 263462 })
AddKnowledgeItems(773, 4, { 263457 })
AddKnowledgeItems(755, 3, { 263458 })
AddKnowledgeItems(165, 2, { 263459 })
AddKnowledgeItems(186, 3, { 263463 })
AddKnowledgeItems(393, 3, { 263461 })
AddKnowledgeItems(197, 2, { 263460 })

-- Sammelberuf-Fundstücke und Catch-up-Gegenstände.
AddKnowledgeItems(182, 1, { 238465, 238467 })
AddKnowledgeItems(182, 4, { 238466 })
AddKnowledgeItems(186, 1, { 237496, 237507 })
AddKnowledgeItems(186, 3, { 237506 })
AddKnowledgeItems(393, 1, { 238625, 238627 })
AddKnowledgeItems(393, 3, { 238626 })
AddKnowledgeItems(171, 1, { 259188, 259189 })
AddKnowledgeItems(164, 2, { 259190, 259191 })
AddKnowledgeItems(333, 2, { 259192, 259193 })
AddKnowledgeItems(202, 1, { 259194, 259195 })
AddKnowledgeItems(773, 2, { 259196, 259197 })
AddKnowledgeItems(755, 2, { 259198, 259199 })
AddKnowledgeItems(165, 2, { 259200, 259201 })
AddKnowledgeItems(197, 2, { 259202, 259203 })

-- Handwerksauftrag-Belohnungen.
AddKnowledgeItems(171, 2, { 246321 }); AddKnowledgeItems(171, 1, { 246320 })
AddKnowledgeItems(164, 2, { 246323 }); AddKnowledgeItems(164, 1, { 246322 })
AddKnowledgeItems(333, 2, { 246325 }); AddKnowledgeItems(333, 1, { 246324 })
AddKnowledgeItems(202, 2, { 246327 }); AddKnowledgeItems(202, 1, { 246326 })
AddKnowledgeItems(773, 2, { 246329 }); AddKnowledgeItems(773, 1, { 246328 })
AddKnowledgeItems(755, 2, { 246331 }); AddKnowledgeItems(755, 1, { 246330 })
AddKnowledgeItems(165, 2, { 246333 }); AddKnowledgeItems(165, 1, { 246332 })
AddKnowledgeItems(197, 2, { 246335 }); AddKnowledgeItems(197, 1, { 246334 })

-- Verzauberkunst: Entzauberungs- und Kombinationsgegenstände.
AddKnowledgeItems(333, 1, { 267653, 267654 })
AddKnowledgeItems(333, 4, { 267655 })
