-- Ausführbarer Regressionstest für Midnight-Berufsskill und Wissenspunkte.
-- Läuft außerhalb von WoW mit Fengari und echten Activities.lua-Funktionen.

local WAT = {}

local dataChunk, dataLoadError = loadfile("Data.lua")
assert(dataChunk, dataLoadError)
dataChunk("WeeklyAltTracker", WAT)

local knowledge = WAT.Data.MIDNIGHT_KNOWLEDGE_ITEMS
local function AssertKnowledge(itemID, professionID, points)
    local entry = knowledge[itemID]
    assert(type(entry) == "table", "Wissensgegenstand fehlt: " .. itemID)
    assert(entry.professionID == professionID and entry.points == points,
        "falsche Wissensdaten für Gegenstand " .. itemID)
end
AssertKnowledge(245755, 171, 1)  -- Traktat
AssertKnowledge(262645, 171, 10) -- Händlerbuch
AssertKnowledge(238532, 171, 3)  -- offener Schatz
AssertKnowledge(263454, 171, 1)  -- Wochenquest
AssertKnowledge(238465, 182, 1)  -- Sammelberuf
AssertKnowledge(259188, 171, 1)  -- Catch-up
AssertKnowledge(246321, 171, 2)  -- Handwerksauftrag
AssertKnowledge(267655, 333, 4)  -- Verzauberkunst
assert(WAT.Data.MIDNIGHT_PROFESSION_SKILL_LINES[171] == 2906
    and WAT.Data.MIDNIGHT_PROFESSION_SKILL_LINES[197] == 2918,
    "Midnight-Skill-Line-Grenzen fehlen")

WAT.Data.PROFESSION_WEEKLIES = {}
WAT.Data.PROFESSION_TREATISES = {}
knowledge[1001] = { professionID = 171, points = 1 }
knowledge[1002] = { professionID = 171, points = 3 }

function time() return 123456 end

local SECRET_VALUE = {}
function issecretvalue(value) return value == SECRET_VALUE end

function GetProfessions() return 1, 2 end
function GetProfessionInfo(index)
    if index == 1 then return "Alchemie", nil, 0, 0, 0, 0, 171 end
    if index == 2 then return "Schmiedekunst", nil, 0, 0, 0, 0, 164 end
end

C_TradeSkillUI = {
    GetProfessionInfoBySkillLineID = function(skillLineID)
        if skillLineID == 2906 then return { skillLevel = 87, maxSkillLevel = 100 } end
        if skillLineID == 2907 then return { skillLevel = 61, maxSkillLevel = 100 } end
    end,
}

C_ProfSpecs = {
    GetCurrencyInfoForSkillLine = function(skillLineID)
        if skillLineID == 2906 then return { numAvailable = 14, currencyName = "Alchemiewissen" } end
        if skillLineID == 2907 then return { numAvailable = 3, currencyName = "Schmiedewissen" } end
    end,
}

C_Container = {
    GetContainerNumSlots = function(bag)
        if bag == 0 then return 3 end
        return 0
    end,
    GetContainerItemInfo = function(bag, slot)
        if bag ~= 0 then return nil end
        if slot == 1 then return { itemID = 1001, stackCount = 2 } end
        if slot == 2 then return { itemID = 1002, stackCount = 1 } end
        if slot == 3 then return { itemID = 9999, stackCount = 20 } end
    end,
}

local activitiesChunk, loadError = loadfile("Activities.lua")
assert(activitiesChunk, loadError)
activitiesChunk("WeeklyAltTracker", WAT)

local weekly, progress = WAT:ScanProfessions({})
assert(type(weekly) == "table", "Wochen-Berufssnapshot fehlt")
assert(type(progress) == "table", "persistenter Berufsfortschritt fehlt")

local alchemy = progress[1]
assert(alchemy.baseSkillLineID == 171 and alchemy.midnightSkillLineID == 2906,
    "Alchemie-Skill-Line-Zuordnung falsch")
assert(alchemy.skillLevel == 87 and alchemy.maxSkillLevel == 100,
    "Midnight-Berufsskill muss 87/100 sein")
assert(alchemy.unspentKnowledge == 14, "freie Wissenspunkte müssen 14 sein")
assert(alchemy.bagKnowledgePoints == 5 and alchemy.bagKnowledgeItems == 3,
    "Taschenwissen muss 5 Punkte aus 3 Gegenständen ergeben")
assert(type(alchemy.bagKnowledgeDetails) == "table" and #alchemy.bagKnowledgeDetails == 2,
    "Taschenwissen-Details fehlen")

local blacksmithing = progress[2]
assert(blacksmithing.skillLevel == 61 and blacksmithing.maxSkillLevel == 100,
    "Midnight-Schmiedeskill muss 61/100 sein")
assert(blacksmithing.unspentKnowledge == 3, "freie Schmiedekunst-Wissenspunkte müssen 3 sein")
assert(blacksmithing.bagKnowledgePoints == 0 and blacksmithing.bagKnowledgeItems == 0,
    "leere Wissensgegenstände müssen sicher als 0 gespeichert werden")

C_TradeSkillUI.GetProfessionInfoBySkillLineID = function() return {
    skillLevel = SECRET_VALUE,
    maxSkillLevel = 100,
} end
C_ProfSpecs.GetCurrencyInfoForSkillLine = function()
    return { numAvailable = SECRET_VALUE, currencyName = "geschützt" }
end
C_Container.GetContainerNumSlots = function() return SECRET_VALUE end

local _, preserved = WAT:ScanProfessions(progress)
local preservedAlchemy = preserved[1]
assert(preservedAlchemy.skillLevel == 87 and preservedAlchemy.maxSkillLevel == 100,
    "Secret-Skillantwort darf sicheren Skill nicht überschreiben")
assert(preservedAlchemy.unspentKnowledge == 14,
    "Secret-Wissensantwort darf sichere freie Punkte nicht überschreiben")
assert(preservedAlchemy.bagKnowledgePoints == 5 and preservedAlchemy.bagKnowledgeItems == 3,
    "Secret-Taschenantwort darf sicheren Taschen-Snapshot nicht überschreiben")

GetProfessions = function() return 1, nil end
local preservedWeekly, temporaryMissing = WAT:ScanProfessions(progress, weekly, false)
assert(type(temporaryMissing[2]) == "table" and temporaryMissing[2].baseSkillLineID == 164,
    "temporär fehlender Berufsslot darf sicheren Offline-Snapshot nicht löschen")
assert(type(preservedWeekly[2]) == "table" and preservedWeekly[2].baseSkillLineID == 164,
    "temporär fehlender Berufsslot darf sicheren Wochenstatus nicht löschen")

local removedWeekly, removed = WAT:ScanProfessions(progress, weekly, true)
assert(removed[2] == nil and removedWeekly[2] == nil,
    "bestätigtes SKILL_LINES_CHANGED muss einen abgelegten zweiten Beruf entfernen")

-- Sichere false-Zustände in Activities.lua: QuestOnLog, Midnight/Ritual und heroToMyth.
-- Kein GetLogIndexForQuestID: der Fallback darf ein sicheres false nicht ersetzen.
local onQuest = {}
local questCompleted = {}
C_QuestLog = {
    IsOnQuest = function(questID) return onQuest[questID] == true end,
    IsQuestFlaggedCompleted = function(questID) return questCompleted[questID] == true end,
    GetQuestObjectives = function() return nil end,
    GetQuestProgressBarPercent = function(questID)
        if onQuest[questID] == true then return 40 end
        return nil
    end,
}

-- Echter Berufs-Wochenquest-Pool über den realen ScanProfessions-Pfad (Alchemie, 171).
local ALCHEMY_WEEKLY_QUEST = 90001
WAT.Data.PROFESSION_WEEKLIES[171] = { ALCHEMY_WEEKLY_QUEST }

local poolWeekly = WAT:ScanProfessions(progress, weekly, false)
assert(type(poolWeekly) == "table" and type(poolWeekly[1]) == "table",
    "Berufs-Wochenstatus mit echtem Quest-Pool fehlt")
assert(poolWeekly[1].weeklyDone == false,
    "sicheres false der Berufs-Wochenquest darf nicht zu unbekannt kollabieren, erhalten "
        .. tostring(poolWeekly[1].weeklyDone))
assert(poolWeekly[1].weeklyQuestID == nil,
    "offene Berufs-Wochenquest darf keine abgeschlossene Quest-ID melden")

questCompleted[ALCHEMY_WEEKLY_QUEST] = true
local donePoolWeekly = WAT:ScanProfessions(progress, weekly, false)
assert(donePoolWeekly[1].weeklyDone == true
    and donePoolWeekly[1].weeklyQuestID == ALCHEMY_WEEKLY_QUEST,
    "erledigte Berufs-Wochenquest muss mit Quest-ID gemeldet werden")
questCompleted[ALCHEMY_WEEKLY_QUEST] = nil

-- Unlesbare Quest-API darf kein false erfinden, sondern muss unbekannt bleiben.
local safeIsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
C_QuestLog.IsQuestFlaggedCompleted = function() return SECRET_VALUE end
local unknownWeekly = WAT:ScanProfessions(progress, poolWeekly, false)
assert(unknownWeekly == nil,
    "unlesbare Quest-API darf keinen erfundenen Berufs-Wochenstatus liefern")
C_QuestLog.IsQuestFlaggedCompleted = safeIsQuestFlaggedCompleted
WAT.Data.PROFESSION_WEEKLIES[171] = nil

local midnight = WAT:ScanMidnightWeekly()
assert(type(midnight) == "table",
    "sicher nicht geloggte und nicht abgeschlossene Midnight-Weekly muss einen Snapshot liefern, nicht nil")
assert(midnight.completed == false,
    "sicheres false der Midnight-Weekly darf nicht zu unbekannt kollabieren, erhalten "
        .. tostring(midnight.completed))
assert(midnight.active == false, "nicht geloggte Midnight-Weekly darf nicht als aktiv gelten")
assert(midnight.variantKnown == false, "ohne geloggte Quest ist die Variante unbekannt")

local ritual = WAT:ScanRitualSites()
assert(type(ritual) == "table",
    "sicher nicht geloggte Ritualstätten-Quest muss einen Snapshot liefern, nicht nil")
assert(ritual.active == false and ritual.completed == false,
    "sicheres false der Ritualstätten darf nicht zu unbekannt kollabieren")

onQuest[WAT.Data.RITUAL_QUEST_ID] = true
local activeRitual = WAT:ScanRitualSites()
assert(type(activeRitual) == "table" and activeRitual.active == true,
    "geloggte Ritualstätten-Quest muss weiterhin als aktiv erkannt werden")
onQuest[WAT.Data.RITUAL_QUEST_ID] = nil

local exchangeID = WAT.Data.HERO_TO_MYTH_ACHIEVEMENT_ID
local achievementCompleted = false
function GetAchievementInfo(achievementID)
    -- Rückgabeform von GetAchievementInfo: (4) completed, (13) wasEarnedByMe.
    return achievementID, "Erfolg", 10, achievementCompleted, 1, 1, 2026,
        "Beschreibung", 0, "icon", "", false, achievementCompleted, nil
end

local exchangeCharacter = {
    weekly = {
        crestSources = {
            heroToMyth = { achievementID = exchangeID, unlocked = true, heroQuantity = 60 },
        },
    },
}
WAT:ScanCrestSources(exchangeCharacter)
local exchange = exchangeCharacter.weekly.crestSources.heroToMyth
assert(exchange.unlocked == false,
    "sicher nicht erfüllter Tausch-Erfolg muss gesperrt bleiben, erhalten " .. tostring(exchange.unlocked))
assert(exchange.mythPotential == nil,
    "gesperrter Tausch darf kein Mythisch-Potential ausweisen")

local noApiCharacter = {
    weekly = {
        crestSources = {
            heroToMyth = { achievementID = exchangeID, unlocked = false, heroQuantity = 60 },
        },
    },
}
GetAchievementInfo = nil
WAT:ScanCrestSources(noApiCharacter)
assert(noApiCharacter.weekly.crestSources.heroToMyth.unlocked == false,
    "unlesbarer Erfolg darf einen sicheren gesperrt-Snapshot nicht auf unbekannt zurücksetzen")

local freshCharacter = { weekly = {} }
WAT:ScanCrestSources(freshCharacter)
assert(freshCharacter.weekly.crestSources.heroToMyth.unlocked == nil,
    "ohne Snapshot und ohne API muss der Tauschstatus unbekannt (nil) bleiben")

-- Persistenz-Regression: der Midnight-Weekly-Snapshot speichert die questID,
-- aber niemals ein eigenes uebersetztes Label. Sonst stuende deutscher Text in
-- den accountweiten SavedVariables und ein Sprachwechsel zeigte ihn weiter an.
local META_QUEST = WAT.Data.META_QUESTS[1]
onQuest[META_QUEST] = true
local metaSnapshot = WAT:ScanMidnightWeekly()
assert(type(metaSnapshot) == "table", "Midnight-Weekly-Snapshot fehlt")
assert(metaSnapshot.questID == META_QUEST,
    "Snapshot muss die questID führen, erhalten " .. tostring(metaSnapshot.questID))
assert(metaSnapshot.label == nil,
    "Snapshot darf kein übersetztes Label speichern, erhalten " .. tostring(metaSnapshot.label))
assert(metaSnapshot.variantKnown == true, "geloggte Meta-Weekly muss als bekannte Variante gelten")
onQuest[META_QUEST] = nil

-- Der Labelschluessel ist rein aus der ID ableitbar und sprachneutral.
assert(WAT.Data.MetaQuestLabelKey(META_QUEST) == "META_QUEST_" .. META_QUEST,
    "Labelschlüssel der Meta-Weekly ist nicht aus der questID ableitbar")
assert(WAT.Data.MetaQuestLabelKey("keineZahl") == nil,
    "Labelschlüssel darf nur für Zahlen entstehen")
assert(WAT.Data.META_LABELS == nil,
    "die deutsche META_LABELS-Tabelle darf nicht zurückkehren")

-- Keine Wappen-Datentabelle darf noch einen deutschen Anzeigetext tragen.
for key, definition in pairs(WAT.Data.CRESTS) do
    assert(definition.label == nil,
        "Data.CRESTS." .. key .. " trägt noch ein hartkodiertes Label")
    assert(type(definition.labelKey) == "string",
        "Data.CRESTS." .. key .. " braucht einen labelKey für Localization.lua")
end

-- ---------------------------------------------------------------------------
-- readyToTurnIn / turnedIn: echter Zielfortschritt der Midnight-Weekly.
--
-- Drei Zustaende, die die UI unterscheiden koennen muss: aktiv mit
-- Teilfortschritt, im Log erfuellt aber noch nicht abgegeben, und tatsaechlich
-- abgegeben. Der dritte Zustand darf den zweiten nicht vortaeuschen, auch
-- wenn das Zielobjekt zufaellig ebenfalls "finished" meldet.
-- ---------------------------------------------------------------------------

local function SetMidnightObjective(current, required, finished)
    C_QuestLog.GetQuestObjectives = function(questID)
        if questID ~= META_QUEST then return nil end
        return { { numFulfilled = current, numRequired = required, finished = finished } }
    end
end

onQuest[META_QUEST] = true
questCompleted[META_QUEST] = false
SetMidnightObjective(3, 5, false)
local activeMidnight = WAT:ScanMidnightWeekly()
assert(type(activeMidnight) == "table",
    "aktive Midnight-Weekly mit Zielfortschritt muss einen Snapshot liefern")
assert(activeMidnight.active == true, "3/5-Ziel muss als aktiv gelten")
assert(activeMidnight.current == 3 and activeMidnight.required == 5,
    "3/5-Ziel muss Fortschritt 3 von 5 melden, erhalten "
        .. tostring(activeMidnight.current) .. "/" .. tostring(activeMidnight.required))
assert(activeMidnight.readyToTurnIn == false,
    "3/5-Ziel darf noch nicht abgabebereit sein, erhalten " .. tostring(activeMidnight.readyToTurnIn))
assert(activeMidnight.turnedIn == false,
    "3/5-Ziel darf noch nicht als abgegeben gelten, erhalten " .. tostring(activeMidnight.turnedIn))

SetMidnightObjective(5, 5, true)
local readyMidnight = WAT:ScanMidnightWeekly()
assert(type(readyMidnight) == "table", "abgabebereite Midnight-Weekly muss einen Snapshot liefern")
assert(readyMidnight.readyToTurnIn == true,
    "erfuelltes, aber nicht abgegebenes Ziel muss abgabebereit sein, erhalten "
        .. tostring(readyMidnight.readyToTurnIn))
assert(readyMidnight.turnedIn == false,
    "erfuelltes, aber nicht abgegebenes Ziel darf nicht als abgegeben gelten, erhalten "
        .. tostring(readyMidnight.turnedIn))
assert(readyMidnight.completed == true,
    "die bestehende completed-Kompatibilitaet muss ein erfuelltes Ziel weiter als erledigt zeigen")

questCompleted[META_QUEST] = true
local turnedInMidnight = WAT:ScanMidnightWeekly()
assert(type(turnedInMidnight) == "table", "abgegebene Midnight-Weekly muss einen Snapshot liefern")
assert(turnedInMidnight.turnedIn == true,
    "abgegebene Midnight-Weekly muss turnedIn true melden, erhalten " .. tostring(turnedInMidnight.turnedIn))
assert(turnedInMidnight.readyToTurnIn == false,
    "abgegeben und abgabebereit duerfen sich nicht ueberschneiden (finished war weiterhin true), erhalten "
        .. tostring(turnedInMidnight.readyToTurnIn))

questCompleted[META_QUEST] = nil
onQuest[META_QUEST] = nil
C_QuestLog.GetQuestObjectives = function() return nil end

-- ---------------------------------------------------------------------------
-- Strukturierter Berufs-Wochenquest-Status (weeklyQuest) neben den
-- rueckwaertskompatiblen Feldern weeklyDone/weeklyQuestID.
-- ---------------------------------------------------------------------------

local PROF_WEEKLY_QUEST = 90002
WAT.Data.PROFESSION_WEEKLIES[171] = { PROF_WEEKLY_QUEST }
onQuest[PROF_WEEKLY_QUEST] = true
questCompleted[PROF_WEEKLY_QUEST] = false
C_QuestLog.GetQuestObjectives = function(questID)
    if questID ~= PROF_WEEKLY_QUEST then return nil end
    return { { numFulfilled = 3, numRequired = 5, finished = false } }
end

local activeProfWeekly = WAT:ScanProfessions(progress, weekly, false)
assert(type(activeProfWeekly) == "table" and type(activeProfWeekly[1]) == "table",
    "Berufs-Wochenstatus mit aktivem Zielfortschritt fehlt")
local activeState = activeProfWeekly[1].weeklyQuest
assert(type(activeState) == "table", "strukturierter weeklyQuest-Status fehlt")
assert(activeState.active == true and activeState.current == 3 and activeState.required == 5,
    "aktiver Berufs-Wochenquest muss 3/5 als aktiv melden")
assert(activeState.readyToTurnIn == false and activeState.turnedIn == false,
    "3/5 darf weder abgabebereit noch abgegeben sein")
assert(activeProfWeekly[1].weeklyDone == false and activeProfWeekly[1].weeklyQuestID == nil,
    "rueckwaertskompatible Felder muessen bei aktivem Quest erhalten bleiben")

C_QuestLog.GetQuestObjectives = function(questID)
    if questID ~= PROF_WEEKLY_QUEST then return nil end
    return { { numFulfilled = 5, numRequired = 5, finished = true } }
end
local readyProfWeekly = WAT:ScanProfessions(progress, weekly, false)
local readyState = readyProfWeekly[1].weeklyQuest
assert(readyState.readyToTurnIn == true and readyState.turnedIn == false,
    "erfuelltes, nicht abgegebenes Berufsziel muss abgabebereit sein")
assert(readyProfWeekly[1].weeklyDone == false and readyProfWeekly[1].weeklyQuestID == nil,
    "abgabebereit ist nicht dasselbe wie abgegeben - weeklyDone darf nicht vorauseilen")

questCompleted[PROF_WEEKLY_QUEST] = true
local turnedInProfWeekly = WAT:ScanProfessions(progress, weekly, false)
local turnedInState = turnedInProfWeekly[1].weeklyQuest
assert(turnedInState.turnedIn == true and turnedInState.readyToTurnIn == false,
    "abgegebener Berufs-Wochenquest muss turnedIn true und readyToTurnIn false melden")
assert(turnedInProfWeekly[1].weeklyDone == true
    and turnedInProfWeekly[1].weeklyQuestID == PROF_WEEKLY_QUEST,
    "rueckwaertskompatible Felder muessen den Abgabestatus weiter melden")

questCompleted[PROF_WEEKLY_QUEST] = nil
onQuest[PROF_WEEKLY_QUEST] = nil
C_QuestLog.GetQuestObjectives = function() return nil end
WAT.Data.PROFESSION_WEEKLIES[171] = nil

-- ---------------------------------------------------------------------------
-- ScanActivities darf einen sicheren weeklyQuest-/Midnight-Snapshot nie durch
-- einen anschliessend komplett unlesbaren Scan ersetzen (Merge-Atomaritaet).
-- ---------------------------------------------------------------------------

WAT.Data.PROFESSION_WEEKLIES[171] = { PROF_WEEKLY_QUEST }
onQuest[META_QUEST] = true
questCompleted[META_QUEST] = false
onQuest[PROF_WEEKLY_QUEST] = true
questCompleted[PROF_WEEKLY_QUEST] = false
C_QuestLog.GetQuestObjectives = function(questID)
    if questID == META_QUEST then return { { numFulfilled = 3, numRequired = 5, finished = false } } end
    if questID == PROF_WEEKLY_QUEST then return { { numFulfilled = 2, numRequired = 5, finished = false } } end
    return nil
end

local mergeCharacter = { professions = progress }
WAT:ScanActivities(mergeCharacter, "PLAYER_LOGIN")
local snapshotMidnight = mergeCharacter.weekly.midnightWeekly
local snapshotProfessions = mergeCharacter.weekly.professions
local snapshotWeeklyQuest = type(snapshotProfessions) == "table" and snapshotProfessions[1]
    and snapshotProfessions[1].weeklyQuest or nil
assert(type(snapshotMidnight) == "table" and snapshotMidnight.current == 3,
    "erster Scan muss einen brauchbaren Midnight-Snapshot liefern")
assert(type(snapshotWeeklyQuest) == "table" and snapshotWeeklyQuest.current == 2,
    "erster Scan muss einen brauchbaren Berufs-Wochenquest-Snapshot liefern")

-- Zweiter Scan: die gesamte Quest-API wird unlesbar (Secret Value). Das darf
-- weder einen falschen Fortschritt erfinden noch die sicheren Snapshots aus
-- dem ersten Scan ersetzen.
local safeCQuestLog = C_QuestLog
C_QuestLog = {
    IsOnQuest = function() return SECRET_VALUE end,
    IsQuestFlaggedCompleted = function() return SECRET_VALUE end,
    GetQuestObjectives = function() return SECRET_VALUE end,
    GetQuestProgressBarPercent = function() return SECRET_VALUE end,
}
WAT:ScanActivities(mergeCharacter, "PLAYER_LOGIN")
assert(mergeCharacter.weekly.midnightWeekly == snapshotMidnight,
    "unlesbarer Folge-Scan darf den sicheren Midnight-Snapshot nicht ersetzen")
assert(mergeCharacter.weekly.professions[1].weeklyQuest == snapshotWeeklyQuest,
    "unlesbarer Folge-Scan darf den sicheren Berufs-Wochenquest-Snapshot nicht ersetzen")
C_QuestLog = safeCQuestLog

questCompleted[META_QUEST] = nil
onQuest[META_QUEST] = nil
questCompleted[PROF_WEEKLY_QUEST] = nil
onQuest[PROF_WEEKLY_QUEST] = nil
C_QuestLog.GetQuestObjectives = function() return nil end
WAT.Data.PROFESSION_WEEKLIES[171] = nil

print("LUA PROFESSION RUNTIME OK: echte Wissens-API, Skill 87/100, 14 frei, 5 Taschenpunkte, Slot-Erhalt,"
    .. " QuestOnLog-false, heroToMyth-gesperrt, label-freier Midnight-Snapshot,"
    .. " readyToTurnIn/turnedIn fuer Midnight- und Berufs-Wochenquest und atomarer Merge-Schutz")
