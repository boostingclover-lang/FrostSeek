-- ============================================================
-- FrostSeek - LFG Module
-- ============================================================

local FrostSeek = _G.FrostSeek

local LFG = {}

-- ==================== VARIABILI GLOBALI ====================
local searchExpirationTime = 340
activeSearches = activeSearches or {}
openFrames = openFrames or {}
ignoreList = ignoreList or {}
spammerList = spammerList or {}
local currentScrollOffset = 0
local MAX_DISPLAY_ROWS = 12
local lastPopupTimes = {}
local sessionStartTime = GetTime()

-- ==================== HELPER FUNCTIONS ====================
local function CreateModernButton(parent, text, width, height)
    return nil
end

-- ==================== KEYWORDS ====================
local KEYSTONE_KEYWORDS = {
    "keystone",
}

local RAID_KEYWORDS = {
    "onyxia", "ony", "molten core", "mc", "blackwing lair", "bwl",
    "zul'gurub", "zg", "ruins of ahn'qiraj", "aq20", "temple of ahn'qiraj", "aq40",
    "naxxramas", "naxx", "karazhan", "kara", "gruul", "magtheridon", "mag",
    "serpentshrine cavern", "ssc", "tempest keep", "tk", "the eye", "eye",
    "hyjal", "mount hyjal", "black temple", "bt", "zul'aman", "za", "sunwell plateau", "swp",
    "vault of archavon", "voa", "archavon", "obsidian sanctum", "os", "sarth", "sartharion",
    "eye of eternity", "eoe", "malygos", "ulduar", "uld",
    "trial of the crusader", "toc", "crusader", "icecrown citadel", "icc", "ruby sanctum", "rs", "halion",
}

local PVP_KEYWORDS = {
    "2v2", "2s", "3v3", "3s", "5v5", "5s", "arena", "bg", "battleground", "pvp",
    "wsg", "warsong", "ab", "arathi", "av", "alterac", "eots", "wg", "wintergrasp",
}

local MANASTORM_KEYWORDS = {
    "manastorm", "bonzo", "alva", "ms",
}

local DUNGEON_KEYWORDS = {
    "rfc", "ragefire", "dm", "deadmines", "vc", "wc", "wailing", "sfk", "shadowfang",
    "stocks", "bfd", "gnomer", "rfk", "sm", "scarlet", "gy", "lib", "arm", "cath",
    "rfd", "ulda", "zf", "mara", "st", "brd", "dire", "maul", "dme", "dmn", "dmw",
    "strat", "scholo", "lbrs", "ubrs", "ramps", "bf", "sp", "ub", "mt", "ac", "sh",
    "ohf", "mecha", "bm", "mgt", "shh", "bota", "sl", "sv", "arca", "uk", "up",
    "nexus", "oculus", "an", "ak", "dtk", "vh", "gun", "hos", "hol", "cos", "toc",
    "fos", "pos", "hor", "vault", "roads", "brc", "kc",
}

-- ==================== FUNZIONE PER MATCH PAROLA INTERA ====================
local function wholeWordFind(text, word)
    if not text or not word then return false end
    return string.find(text, "%f[%a]" .. word .. "%f[%A]") or 
           string.find(text, "^" .. word .. "%f[%A]") or
           string.find(text, "%f[%a]" .. word .. "$")
end

-- ==================== IS LFM MESSAGE ====================
function LFG.IsLFMMessage(msg)
    if not msg then return false end
    
    local lowerMsg = string.lower(msg)
    
    if string.find(lowerMsg, "lfm") then return true end
    if string.find(lowerMsg, " lf ") then return true end
    if string.find(lowerMsg, "^lf ") then return true end
    if string.find(lowerMsg, "lf1m") then return true end
    if string.find(lowerMsg, "lf2m") then return true end
    if string.find(lowerMsg, "lf3m") then return true end
    if string.find(lowerMsg, "lf4m") then return true end
    if string.find(lowerMsg, "lf5m") then return true end
    if string.find(lowerMsg, "lf1") then return true end
    if string.find(lowerMsg, "lf2") then return true end
    if string.find(lowerMsg, "lf3") then return true end
    if string.find(lowerMsg, "lf4") then return true end
    if string.find(lowerMsg, "lf5") then return true end
    if string.find(lowerMsg, "lf") and string.find(lowerMsg, "tank") then return true end
    if string.find(lowerMsg, "lf") and string.find(lowerMsg, "heal") then return true end
    if string.find(lowerMsg, "lf") and string.find(lowerMsg, "dps") then return true end
    if string.find(lowerMsg, "recruiting") then return true end
    if string.find(lowerMsg, "need") and string.find(lowerMsg, "tank") then return true end
    if string.find(lowerMsg, "need") and string.find(lowerMsg, "heal") then return true end
    if string.find(lowerMsg, "need") and string.find(lowerMsg, "dps") then return true end
    
    return false
end

-- ==================== CLASSIFICAZIONE ====================
function LFG.ClassifyMessage(msg)
    if not msg then 
        return "DUNGEON", "MISC", false, false, false, false, false
    end
    
    local lowerMsg = string.lower(msg)
    
    -- 1. KEYSTONE
    for _, kw in ipairs(KEYSTONE_KEYWORDS) do
        if wholeWordFind(lowerMsg, kw) then
            if wholeWordFind(lowerMsg, "strath") then
                return "KEYSTONE", "STRAT", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "dire maul") or wholeWordFind(lowerMsg, "dme") or wholeWordFind(lowerMsg, "dmn") or wholeWordFind(lowerMsg, "dmw") then
                return "KEYSTONE", "DM", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "brd") or wholeWordFind(lowerMsg, "blackrock depths") then
                return "KEYSTONE", "BRD", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "scholo") then
                return "KEYSTONE", "SCHOLO", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "lbrs") then
                return "KEYSTONE", "LBRS", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "ubrs") then
                return "KEYSTONE", "UBRS", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "mc") or wholeWordFind(lowerMsg, "molten core") then
                return "KEYSTONE", "MC", false, false, false, true, false
            else
                return "KEYSTONE", "KEYSTONE", false, false, false, true, false
            end
        end
    end
    
    -- 2. RAID
    for _, kw in ipairs(RAID_KEYWORDS) do
        if wholeWordFind(lowerMsg, kw) then
            return "RAID", string.upper(kw), false, false, true, false, false
        end
    end
    
    -- 3. PVP
    for _, kw in ipairs(PVP_KEYWORDS) do
        if wholeWordFind(lowerMsg, kw) then
            return "PVP", "PVP", false, false, false, false, true
        end
    end
    
    -- 4. MANASTORM
    for _, kw in ipairs(MANASTORM_KEYWORDS) do
        if wholeWordFind(lowerMsg, kw) then
            return "MANASTORM", "MANASTORM", false, false, false, false, false
        end
    end
    
    -- 5. DUNGEON
    for _, d in ipairs(DUNGEON_KEYWORDS) do
        if wholeWordFind(lowerMsg, d) then
            local isHeroic = false
            if wholeWordFind(lowerMsg, "hc") or wholeWordFind(lowerMsg, "heroic") or wholeWordFind(lowerMsg, " h ") then
                isHeroic = true
            end
            return "DUNGEON", string.upper(d), isHeroic, false, false, false, false
        end
    end
    
    return "DUNGEON", "MISC", false, false, false, false, false
end

-- ==================== FUNZIONE PER ENCHANT LEGGENDARI ====================
function LFG.GetLegendaryEnchant()
    -- Verifica se MysticEnchantUtil
    if not MysticEnchantUtil then 
        return "" 
    end
    
    local legendaryEnchantName = ""
    
    -- Ottieni gli enchant applicati per qualità
    local enchantData = MysticEnchantUtil.GetAppliedEnchantCountByQuality("player")
    
    if enchantData then
        enchantData = enchantData[5]
    end
    
    if enchantData then
        for spellID, _ in pairs(enchantData) do
            legendaryEnchantName = GetSpellInfo(spellID)
            if legendaryEnchantName then
                -- Formatta come link cliccabile con colore
                return string.format("|cff71d5ff|Hspell:%d|h[%s]|h|r", spellID, legendaryEnchantName)
            end
        end
    end
    
    return ""
end

-- ==================== FUNZIONE PER INFO COMPLETE ====================
function LFG.GetFullPlayerInfo()
    local classInfo = LFG.GetClassInfo()
    local ilvl = LFG.GetAverageItemLevel()
    local enchant = LFG.GetLegendaryEnchant()
    
    return classInfo, ilvl, enchant
end

-- ==================== PLAYER INFO ====================
function LFG.GetClassInfo()
    local className, classFile = UnitClass("player")
    local classMap = {
        ["WARRIOR"] = "Warrior",
        ["PALADIN"] = "Paladin", 
        ["HUNTER"] = "Hunter",
        ["ROGUE"] = "Rogue",
        ["PRIEST"] = "Priest",
        ["DEATHKNIGHT"] = "Death Knight",
        ["SHAMAN"] = "Shaman",
        ["MAGE"] = "Mage",
        ["WARLOCK"] = "Warlock",
        ["DRUID"] = "Druid",
        -- Classe Hero di Ascension
        ["HERO"] = "Hero",
        -- Ascension CoA Classes
        ["NECROMANCER"] = "Necromancer",
        ["PYROMANCER"] = "Pyromancer",
        ["CULTIST"] = "Cultist",
        ["STARCALLER"] = "Starcaller",
        ["SUNCLERIC"] = "Suncleric",
        ["TINKER"] = "Tinker",
        ["RUNEMASTER"] = "Runemaster",
        ["PRIMAALIST"] = "Primaalist",
        ["REAPER"] = "Reaper",
        ["VENOMANCER"] = "Venomancer",
        ["CHRONOMANCER"] = "Chronomancer",
        ["BLOODMAGE"] = "Bloodmage",
        ["GUARDIAN"] = "Guardian",
        ["STORMBRINGER"] = "Stormbringer",
        ["FELSWORN"] = "Felsworn",
        ["BARBARIAN"] = "Barbarian",
        ["WITCH_DOCTOR"] = "Witch Doctor",
        ["WITCH_HUNTER"] = "Witch Hunter",
        ["KNIGHT_OF_XOROTH"] = "Knight of Xoroth",
        ["TEMPLAR"] = "Templar",
        ["RANGED"] = "Ranged"
    }

    return classMap[classFile] or className or "Unknown"
end

function LFG.GetAverageItemLevel()
    local sum, count = 0, 0
    for i = 1, 17 do
        if i ~= 4 then
            local itemLink = GetInventoryItemLink("player", i)
            if itemLink then
                local _, _, _, itemLevel = GetItemInfo(itemLink)
                if itemLevel then
                    sum = sum + itemLevel
                    count = count + 1
                end
            end
        end
    end
    return count > 0 and math.floor((sum / count) + 0.5) or 0
end

-- ==================== CREATE WHISPER MESSAGE CON TEMPLATE CUSTOM ====================
function LFG.CreateWhisperMessage()
    local classInfo, ilvl, enchant = LFG.GetFullPlayerInfo()
    local roleText = FrostSeekDB.LFG.myRole ~= "" and FrostSeekDB.LFG.myRole or ""
    
    -- Pulisci l'enchant
    local cleanEnchant = enchant
    if enchant then
        cleanEnchant = string.gsub(enchant, "|c%x%x%x%x%x%x%x%x", "")
        cleanEnchant = string.gsub(cleanEnchant, "|r", "")
        cleanEnchant = string.gsub(cleanEnchant, "|Hspell:%d+|h", "")
        cleanEnchant = string.gsub(cleanEnchant, "|h", "")
        cleanEnchant = string.gsub(cleanEnchant, "%[", "")
        cleanEnchant = string.gsub(cleanEnchant, "%]", "")
    end
    
    -- Se i messaggi custom sono abilitati, usa il template
    if FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.enabled then
        local template = FrostSeekDB.LFG.customMessages.template or "inv {role} {class} {ench} {ilvl} ilvl"
        
        -- Sostituisci le variabili nel template
        local message = template
        
        -- Class
        if FrostSeekDB.LFG.customMessages.showClass then
            message = string.gsub(message, "{class}", classInfo or "")
        else
            message = string.gsub(message, "{class}", "")
        end
        
        -- Item Level
        if FrostSeekDB.LFG.customMessages.showIlvl then
            message = string.gsub(message, "{ilvl}", tostring(ilvl or 0))
        else
            message = string.gsub(message, "{ilvl}", "")
        end
        
        -- Enchant
        if FrostSeekDB.LFG.customMessages.showEnchant then
            message = string.gsub(message, "{ench}", cleanEnchant or "")
        else
            message = string.gsub(message, "{ench}", "")
        end
        
        -- Role
        if FrostSeekDB.LFG.customMessages.showRole then
            message = string.gsub(message, "{role}", roleText or "")
        else
            message = string.gsub(message, "{role}", "")
        end
        
        -- Achievement link
        if FrostSeekDB.LFG.customMessages.showAchievement and FrostSeekDB.LFG.customMessages.achievementLink ~= "" then
            message = string.gsub(message, "{achievement}", FrostSeekDB.LFG.customMessages.achievementLink)
        else
            message = string.gsub(message, "{achievement}", "")
        end
        
        -- Keystone link
        if FrostSeekDB.LFG.customMessages.showKeystone and FrostSeekDB.LFG.customMessages.keystoneLink ~= "" then
            message = string.gsub(message, "{keystone}", FrostSeekDB.LFG.customMessages.keystoneLink)
        else
            message = string.gsub(message, "{keystone}", "")
        end
        
        -- Rimuovi spazi multipli
        message = string.gsub(message, "%s+", " ")
        message = string.gsub(message, "^%s*(.-)%s*$", "%1")
        
        -- Se il messaggio è vuoto, usa il default
        if message == "" then
            message = "inv " .. roleText .. " " .. classInfo .. " " .. ilvl .. " ilvl"
        end
        
        return message
    else
        -- Comportamento originale
        local enchantText = cleanEnchant ~= "" and (" " .. cleanEnchant) or ""
        local rolePrefix = roleText ~= "" and (roleText .. " ") or ""
        
        if classInfo == "Hero" then
            return "inv " .. rolePrefix .. ilvl .. " ilvl" .. enchantText
        else
            return "inv " .. rolePrefix .. classInfo .. enchantText .. " " .. ilvl .. " ilvl"
        end
    end
end

-- ==================== ROLE MANAGEMENT ====================
function LFG.SetRole(role)
    FrostSeekDB.LFG.myRole = role
    if LFG.UpdatePlayerInfo then
        LFG.UpdatePlayerInfo()
    end
    print("|cff88ccffFrostSeek LFG:|r Role set to: " .. (role ~= "" and role or "None"))
end

-- ==================== RECORD ACTIVE SEARCH ====================
function LFG.RecordActiveSearch(sender, message, channel)
    local lowerMsg = string.lower(message)
    if string.find(lowerMsg, "boost") or string.find(lowerMsg, "wts") or 
       string.find(lowerMsg, "wtb") or string.find(lowerMsg, "sell") or 
       string.find(lowerMsg, "buy") or string.find(lowerMsg, "gold") or
       string.find(lowerMsg, "account") or string.find(lowerMsg, "gdkp") or 
       string.find(lowerMsg, "lfg") or string.find(lowerMsg, "guild") or
       string.find(lowerMsg, "first realm") or string.find(lowerMsg, "na") or
       string.find(lowerMsg, "join") or string.find(lowerMsg, "social") or
       string.find(lowerMsg, "eu") or string.find(lowerMsg, "opposition") or 
       string.find(lowerMsg, "someone") then
        return
    end
    
    if not activeSearches then activeSearches = {} end
    
    local category, dungeon, isHeroic, isMythic, isRaid, isKeystone, isPvp = LFG.ClassifyMessage(message)
    local isManastorm = (category == "MANASTORM")
    local now = GetTime()
    
    for _, record in ipairs(activeSearches) do
        if record.player == sender then
            record.message = message
            record.lastUpdate = now
            record.dungeon = dungeon
            record.category = category
            record.isHeroic = isHeroic
            record.isRaid = isRaid
            record.isPvp = isPvp
            record.isKeystone = isKeystone
            record.isManastorm = isManastorm
            record.channel = channel
            
            if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
            LFG.CreateLFGPopup(sender, message, dungeon, isHeroic, isRaid, isPvp, isKeystone, isManastorm, category)
            return
        end
    end
    
    table.insert(activeSearches, {
        player = sender,
        message = message,
        dungeon = dungeon,
        category = category,
        isHeroic = isHeroic,
        isRaid = isRaid,
        isPvp = isPvp,
        isKeystone = isKeystone,
        isManastorm = isManastorm,
        channel = channel,
        lastUpdate = now,
        startTime = now,
    })
    
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    LFG.CreateLFGPopup(sender, message, dungeon, isHeroic, isRaid, isPvp, isKeystone, isManastorm, category)
end

-- ==================== CATEGORY MATCHING ====================
function LFG.GroupMatchesCategory(group, category)
    if not group then return false end
    if category == "ALL" then return true end
    
    if category == "KEYSTONE" then
        return group.category == "KEYSTONE"
    elseif category == "RAID" then
        return group.category == "RAID"
    elseif category == "PVP" then
        return group.category == "PVP"
    elseif category == "MANASTORM" then
        return group.category == "MANASTORM"
    elseif category == "DUNGEON" then
        return group.category == "DUNGEON"
    end
    
    return false
end

-- ==================== SHORTEN MESSAGE ====================
function LFG.ShortenMessage(message)
    if not message then return "" end
    local maxLength = FrostSeekDB.LFG.maxMessageLength or 150
    
    if string.len(message) <= maxLength then
        return message
    end
    
    return string.sub(message, 1, maxLength - 3) .. "..."
end

-- ==================== POPUP MANAGEMENT ====================
function LFG.CanShowPopup(sender, message)
    if not sender or not message then return false end
    
    local normalizedMessage = string.lower(message):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    local messageKey = sender .. ":" .. normalizedMessage
    
    local now = GetTime()
    local lastTime = lastPopupTimes[messageKey]
    
    if lastTime and (now - lastTime) < (FrostSeekDB.LFG.popupCooldown or 400) then
        return false
    end
    
    lastPopupTimes[messageKey] = now
    return true
end

function LFG.CountActivePopups()
    local count = 0
    for _, frame in ipairs(openFrames) do
        if frame and frame:IsShown() then
            count = count + 1
        end
    end
    return count
end

function LFG.RemovePopupFrame(frame)
    if frame and frame:IsShown() then
        frame:Hide()
        for i, popup in ipairs(openFrames) do
            if popup == frame then
                table.remove(openFrames, i)
                break
            end
        end
    end
end

-- ==================== POPUP CREATION ====================
function LFG.CreateLFGPopup(sender, message, dungeon, isHeroic, isRaid, isPvp, isKeystone, isManastorm, category)
    if FrostSeekDB.LFG.disablePopups then return end
    if FrostSeekDB.LFG.disableLFG then return end
    if FrostSeekDB.LFG.doNotAlertInGroup and IsInGroup() then return end
    if FrostSeekDB.LFG.doNotAlertInCombat and UnitAffectingCombat("player") then return end
    
    local activePopupCount = LFG.CountActivePopups()
    if activePopupCount >= (FrostSeekDB.LFG.maxConcurrentPopups or 3) then return end
    
    if not FrostSeekDB.LFG.popupCategories[category] and not FrostSeekDB.LFG.popupCategories["ALL"] then
        return
    end
    
    if not LFG.CanShowPopup(sender, message) then return end
    
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetSize(340, 140)
    popup:SetFrameStrata("DIALOG")
    
    local screenHeight = GetScreenHeight()
    local yOffset = 50 + (activePopupCount * 145)
    popup:SetPoint("TOP", UIParent, "TOP", 0, -yOffset)
    
    popup:SetAlpha(0)
    UIFrameFadeIn(popup, 0.15, 0, 1)
    
    popup:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    popup:SetBackdropColor(0.08, 0.08, 0.1, 0.98)
    popup:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    local categoryText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryText:SetPoint("TOPLEFT", popup, "TOPLEFT", 15, -12)
    
    if category == "KEYSTONE" then
        categoryText:SetText("|cFFFF88FFKEYSTONE|r")
    elseif category == "PVP" then
        categoryText:SetText("|cFFFF5555PVP|r")
    elseif category == "MANASTORM" then
        categoryText:SetText("|cFFAA88FFMANASTORM|r")
    elseif category == "RAID" then
        categoryText:SetText("|cFFFFAA00RAID|r")
    elseif isHeroic then
        categoryText:SetText("|cFFFF0000HEROIC DUNGEON|r")
    else
        categoryText:SetText("|cFF00FF00DUNGEON|r")
    end
    
    local closeBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -5, -5)
    closeBtn:SetSize(24, 24)
    closeBtn:SetScript("OnClick", function()
        LFG.RemovePopupFrame(popup)
    end)
    
    local _, classFile = UnitClass("player")
    local classColor = RAID_CLASS_COLORS[classFile] or { r = 1, g = 1, b = 1 }
    
    local nameText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", popup, "TOPLEFT", 15, -40)
    nameText:SetText(string.format("|cff%02x%02x%02x%s|r is recruiting:", 
        classColor.r * 255, classColor.g * 255, classColor.b * 255, sender or "Unknown"))
    
    if dungeon and dungeon ~= "MISC" and dungeon ~= "KEYSTONE" and dungeon ~= "PVP" and dungeon ~= "MANASTORM" then
        local dungeonInfo = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dungeonInfo:SetPoint("TOPLEFT", popup, "TOPLEFT", 15, -60)
        
        if isHeroic then
            dungeonInfo:SetText(string.format("|cFFFF0000[H]|r %s", dungeon))
        else
            dungeonInfo:SetText(dungeon)
        end
        dungeonInfo:SetTextColor(0.9, 0.9, 0.9)
    end
    
    local messageText = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    messageText:SetPoint("TOPLEFT", popup, "TOPLEFT", 30, -80)
    messageText:SetPoint("RIGHT", popup, "RIGHT", -15, 0)
    messageText:SetJustifyH("LEFT")
    messageText:SetText(LFG.ShortenMessage(message or ""))
    messageText:SetTextColor(0.9, 0.9, 0.9)
    
    local btnWidth = 85
    local btnHeight = 24
    local btnSpacing = 10
    local totalWidth = (btnWidth * 3) + (btnSpacing * 2)
    local startX = (popup:GetWidth() - totalWidth) / 2
    
    local acceptBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    acceptBtn:SetSize(btnWidth, btnHeight)
    acceptBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", startX, 12)
    acceptBtn:SetText("Accept")
    acceptBtn:SetScript("OnClick", function()
        local whisperMsg = LFG.CreateWhisperMessage()
        SendChatMessage(whisperMsg, "WHISPER", nil, sender)
        LFG.RemovePopupFrame(popup)
        UIErrorsFrame:AddMessage("|cff88ccffWhisper sent to " .. sender, 1, 1, 1, 3)
    end)
    
    local ignoreBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    ignoreBtn:SetSize(btnWidth, btnHeight)
    ignoreBtn:SetPoint("LEFT", acceptBtn, "RIGHT", btnSpacing, 0)
    ignoreBtn:SetText("Ignore")
    ignoreBtn:SetScript("OnClick", function()
        LFG.RemovePopupFrame(popup)
    end)
    
    local declineBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    declineBtn:SetSize(btnWidth, btnHeight)
    declineBtn:SetPoint("LEFT", ignoreBtn, "RIGHT", btnSpacing, 0)
    declineBtn:SetText("Close")
    declineBtn:SetScript("OnClick", function()
        LFG.RemovePopupFrame(popup)
    end)
    
    local duration = FrostSeekDB.LFG.frameDuration or 6
    C_Timer.After(duration, function()
        if popup and popup:IsShown() then
            LFG.RemovePopupFrame(popup)
        end
    end)
    
    if not FrostSeekDB.LFG.silentNotifications then
        PlaySoundFile("Sound\\Interface\\MapPing.wav")
    end
    
    table.insert(openFrames, popup)
end

-- ==================== CLEANUP ====================
function LFG.CleanupActiveSearches()
    if not activeSearches then activeSearches = {} end
    
    local now = GetTime()
    local removedCount = 0
    
    for i = #activeSearches, 1, -1 do
        if activeSearches[i] and activeSearches[i].lastUpdate and 
           (now - activeSearches[i].lastUpdate > searchExpirationTime) then
            table.remove(activeSearches, i)
            removedCount = removedCount + 1
        end
    end
    
    if removedCount > 0 then
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end
end

function LFG.ClearAllSearches()
    activeSearches = {}
    currentScrollOffset = 0
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    print("|cff88ccffFrostSeek LFG:|r All searches cleared")
end

-- ==================== SCROLL FUNCTIONS ====================
function LFG.ScrollRecruitersList(direction)
    if not LFG.recruitersList then return end
    
    local totalFiltered = LFG.CountFilteredSearches()
    
    if direction == "UP" then
        currentScrollOffset = math.max(0, currentScrollOffset - 1)
    elseif direction == "DOWN" then
        if totalFiltered > MAX_DISPLAY_ROWS then
            currentScrollOffset = math.min(totalFiltered - MAX_DISPLAY_ROWS, currentScrollOffset + 1)
        end
    end
    
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
end

function LFG.CountFilteredSearches()
    local count = 0
    for _, search in ipairs(activeSearches or {}) do
        if LFG.GroupMatchesCategory(search, LFG.CurrentCategory or "ALL") then
            count = count + 1
        end
    end
    return count
end

-- ==================== UI FUNCTIONS - CON ENCHANT ====================
function LFG.UpdatePlayerInfo()
    if not LFG.playerInfoText then return end
    
    local classInfo, ilvl, enchant = LFG.GetFullPlayerInfo()
    local roleText = FrostSeekDB.LFG.myRole ~= "" and ("Role: " .. FrostSeekDB.LFG.myRole) or "Role: Not Set"
    
    -- Mostra l'enchant nell'interfaccia
    LFG.playerInfoText:SetText(string.format("|cffffffff%s | |cff00ff00%diLvl|r | %s %s", 
        classInfo, ilvl, roleText, enchant))
    
    if LFG.roleDropdown then
        local role = FrostSeekDB.LFG.myRole ~= "" and FrostSeekDB.LFG.myRole or "No Role"
        UIDropDownMenu_SetText(LFG.roleDropdown, role)
    end
end

function LFG.UpdateRecruitersList()
    if not LFG.recruitersList then return end
    
    if not activeSearches then activeSearches = {} end
    
    -- Nascondi tutte le righe esistenti
    if LFG.recruitersList.rows then
        for i, row in ipairs(LFG.recruitersList.rows) do
            if row and row.Hide then
                row:Hide()
            end
        end
    end
    LFG.recruitersList.rows = {}
    
    -- Filtra le ricerche in base alla categoria
    local filteredSearches = {}
    for _, search in ipairs(activeSearches) do
        if LFG.GroupMatchesCategory(search, LFG.CurrentCategory or "ALL") then
            table.insert(filteredSearches, search)
        end
    end
    
    if LFG.lfgCountText then
        LFG.lfgCountText:SetText("Active Recruiters: " .. #filteredSearches)
    end
    
    local totalFiltered = #filteredSearches
    local startIndex = currentScrollOffset + 1
    local endIndex = math.min(startIndex + MAX_DISPLAY_ROWS - 1, totalFiltered)
    
    if LFG.scrollIndicator then
        LFG.scrollIndicator:SetText(string.format("%d-%d/%d", startIndex, endIndex, totalFiltered))
    end
    
    local now = GetTime()
    local rowHeight = 24
    
    for i = startIndex, endIndex do
        local record = filteredSearches[i]
        if record then
            local rowIndex = i - startIndex + 1
            local row = CreateFrame("Frame", nil, LFG.recruitersList)
            row:SetSize(740, rowHeight)
            
            if rowIndex == 1 then
                row:SetPoint("TOP", LFG.recruitersList, "TOP", 0, -2)
            else
                row:SetPoint("TOP", LFG.recruitersList.rows[rowIndex-1], "BOTTOM", 0, -1)
            end
            
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            if rowIndex % 2 == 0 then
                bg:SetColorTexture(0.1, 0.1, 0.12, 0.1)
            else
                bg:SetColorTexture(0.08, 0.08, 0.1, 0.05)
            end
            
            -- Name
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
            nameText:SetWidth(90)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(record.player or "Unknown")
            nameText:SetTextColor(0.6, 0.8, 1)
            
            -- Time
            local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            timeText:SetPoint("LEFT", row, "LEFT", 100, 0)
            timeText:SetWidth(45)
            timeText:SetJustifyH("LEFT")
            local timeSince = now - (record.lastUpdate or 0)
            if timeSince < 60 then
                timeText:SetText(string.format("%ds", timeSince))
            else
                timeText:SetText(string.format("%dm", math.floor(timeSince/60)))
            end
            timeText:SetTextColor(0.6, 0.6, 0.6)
            
            -- Category Icon
            local catText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            catText:SetPoint("LEFT", row, "LEFT", 155, 0)
            catText:SetWidth(30)
            catText:SetJustifyH("LEFT")
            
            if record.category == "KEYSTONE" then
                catText:SetText("|cFFFF88FFK|r")
            elseif record.category == "PVP" then
                catText:SetText("|cFFFF5555P|r")
            elseif record.category == "MANASTORM" then
                catText:SetText("|cFFAA88FFM|r")
            elseif record.category == "RAID" then
                catText:SetText("|cFFFFAA00R|r")
            elseif record.isHeroic then
                catText:SetText("|cFFFF0000H|r")
            else
                catText:SetText("|cFF00FF00D|r")
            end
            
            -- Dungeon
            local dungeonText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            dungeonText:SetPoint("LEFT", row, "LEFT", 195, 0)
            dungeonText:SetWidth(80)
            dungeonText:SetJustifyH("LEFT")
            
            if record.dungeon and record.dungeon ~= "MISC" and record.dungeon ~= "KEYSTONE" and record.dungeon ~= "PVP" and record.dungeon ~= "MANASTORM" then
                dungeonText:SetText(record.dungeon)
            else
                dungeonText:SetText("")
            end
            dungeonText:SetTextColor(0.8, 0.8, 0.8)
            
            -- Message
            local msgText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            msgText:SetPoint("LEFT", row, "LEFT", 285, 0)
            msgText:SetWidth(320)
            msgText:SetJustifyH("LEFT")
            msgText:SetText(LFG.ShortenMessage(record.message) or "")
            msgText:SetTextColor(1, 1, 1)

            -- TOOLTIP - Frame invisibile ma che riceve eventi del mouse
            local tooltipFrame = CreateFrame("Frame", nil, row)
            tooltipFrame:SetPoint("LEFT", row, "LEFT", 285, 0)
            tooltipFrame:SetSize(320, rowHeight)

           -- Aggiungiamo una texture trasparente per far sì che il frame riceva gli eventi del mouse
           local texture = tooltipFrame:CreateTexture(nil, "BACKGROUND")
           texture:SetAllPoints()
           texture:SetColorTexture(0, 0, 0, 0) -- Completamente trasparente
           texture:SetAlpha(0)

           -- Abilita il frame a ricevere eventi del mouse
           tooltipFrame:EnableMouse(true)

           tooltipFrame:SetScript("OnEnter", function(self)
           GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 10)
           GameTooltip:SetText("|cFFFFFF00" .. (record.player or "Unknown") .. "|r", 1, 1, 1)
           GameTooltip:AddLine(" ")
           GameTooltip:AddLine("|cFF00FF00Full Message:|r", 0, 1, 0)
           GameTooltip:AddLine(record.message or "", 1, 1, 1, true)
           GameTooltip:AddLine(" ")
           GameTooltip:AddLine("|cFF88CCFFTime:|r " .. string.format("%ds ago", timeSince), 0.8, 0.8, 0.8)
           if record.dungeon and record.dungeon ~= "MISC" then
            GameTooltip:AddLine("|cFF88CCFFDungeon:|r " .. record.dungeon, 0.8, 0.8, 0.8)
            end
            GameTooltip:AddLine("|cFF88CCFFCategory:|r " .. record.category, 0.8, 0.8, 0.8)
            GameTooltip:Show()
            end)

            tooltipFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            end)
            
            -- Accept button
            local acceptBtn = CreateFrame("Button", nil, row)
            acceptBtn:SetSize(60, 20)
            acceptBtn:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            acceptBtn.bg = acceptBtn:CreateTexture(nil, "BACKGROUND")
            acceptBtn.bg:SetAllPoints()
            acceptBtn.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
            acceptBtn.text = acceptBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            acceptBtn.text:SetPoint("CENTER")
            acceptBtn.text:SetText("Accept")
            acceptBtn.text:SetTextColor(0.4, 1, 0.4)
            acceptBtn:SetScript("OnClick", function()
                local msg = LFG.CreateWhisperMessage()
                SendChatMessage(msg, "WHISPER", nil, record.player)
                print("|cff88ccffFrostSeek LFG:|r Whisper sent to " .. record.player)
            end)
            acceptBtn:SetScript("OnEnter", function(self)
                self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
                self.text:SetTextColor(0.6, 1, 0.6)
            end)
            acceptBtn:SetScript("OnLeave", function(self)
                self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
                self.text:SetTextColor(0.4, 1, 0.4)
            end)
            
            table.insert(LFG.recruitersList.rows, row)
        end
    end
    
    if totalFiltered == 0 then
        local noRecruitersText = LFG.recruitersList:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noRecruitersText:SetPoint("CENTER", LFG.recruitersList, "CENTER", 0, 0)
        noRecruitersText:SetText("No active recruiters found")
        noRecruitersText:SetTextColor(0.5, 0.5, 0.5)
        table.insert(LFG.recruitersList.rows, noRecruitersText)
    end
end

function LFG.ChangeCategory(category)
    LFG.CurrentCategory = category
    currentScrollOffset = 0
    
    if LFG.lfgTabs then
        for cat, tab in pairs(LFG.lfgTabs) do
            if tab and tab.text then
                if cat == category then
                    tab.bg:SetColorTexture(0.3, 0.5, 0.7, 0.4)
                    tab.text:SetTextColor(1, 1, 1)
                else
                    tab.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
                    tab.text:SetTextColor(0.8, 0.8, 0.8)
                end
            end
        end
    end
    
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
end

-- ==================== MODULE INITIALIZATION ====================
function LFG:Initialize(parentFrame)
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)
    
    -- ===== MAIN CONTAINER =====
    self.mainContainer = CreateFrame("Frame", nil, self.frame)
    self.mainContainer:SetSize(760, 500)
    self.mainContainer:SetPoint("TOP", self.frame, "TOP", 0, -5)
    
    -- ===== PLAYER INFO =====
    self.playerFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.playerFrame:SetSize(740, 35)
    self.playerFrame:SetPoint("TOP", self.mainContainer, "TOP", 0, -5)
    
    local playerBg = self.playerFrame:CreateTexture(nil, "BACKGROUND")
    playerBg:SetAllPoints()
    playerBg:SetColorTexture(0.08, 0.08, 0.1, 0.2)
    
    self.playerInfoText = self.playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.playerInfoText:SetPoint("LEFT", self.playerFrame, "LEFT", 10, 0)
    self.playerInfoText:SetText("Loading player info...")
    self.playerInfoText:SetTextColor(0.9, 0.9, 0.9)
    
    self.roleFrame = CreateFrame("Frame", nil, self.playerFrame)
    self.roleFrame:SetSize(140, 22)
    self.roleFrame:SetPoint("RIGHT", self.playerFrame, "RIGHT", -10, 0)
    
    local roleLabel = self.roleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    roleLabel:SetPoint("LEFT", self.roleFrame, "LEFT", 0, 0)
    roleLabel:SetText("Role:")
    roleLabel:SetTextColor(0.7, 0.7, 0.7)
    
    self.roleDropdown = CreateFrame("Button", "FrostSeekRoleDropdown", self.roleFrame, "UIDropDownMenuTemplate")
    self.roleDropdown:SetPoint("LEFT", roleLabel, "RIGHT", 5, -2)
    self.roleDropdown:SetWidth(90)
    UIDropDownMenu_SetWidth(self.roleDropdown, 90)
    
    -- ===== TITLE =====
    self.title = self.mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.title:SetPoint("TOP", self.playerFrame, "BOTTOM", 0, -8)
    self.title:SetText("|cff88ccffLooking For Group|r")
    self.title:SetTextColor(0.8, 0.9, 1)
    
    -- ===== ACTIVE RECRUITERS COUNT =====
    self.lfgCountText = self.mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.lfgCountText:SetPoint("TOP", self.title, "BOTTOM", 0, -4)
    self.lfgCountText:SetText("Active Recruiters: 0")
    self.lfgCountText:SetTextColor(0.6, 0.8, 1)
    
    -- ===== RECRUITERS FRAME =====
    self.recruitersFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.recruitersFrame:SetSize(740, 360)
    self.recruitersFrame:SetPoint("TOP", self.lfgCountText, "BOTTOM", 0, -8)
    
    local recruitersBg = self.recruitersFrame:CreateTexture(nil, "BACKGROUND")
    recruitersBg:SetAllPoints()
    recruitersBg:SetColorTexture(0.05, 0.05, 0.08, 0.15)
    
    -- ===== CATEGORY TABS =====
    self.lfgTabs = {}
    local lfgTabTypes = {"ALL", "DUNGEON", "RAID", "PVP", "MANASTORM", "KEYSTONE"}
    local lfgTabNames = {"All", "Dungeon", "Raid", "PvP", "Manastorm", "Key"}
    
    for i, tabName in ipairs(lfgTabNames) do
        local tab = CreateFrame("Button", nil, self.recruitersFrame)
        tab:SetSize(70, 22)
        tab:SetPoint("TOPLEFT", self.recruitersFrame, "TOPLEFT", 5 + ((i-1) * 75), -8)
        
        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        tab.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
        
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(tabName)
        tab.text:SetTextColor(0.9, 0.9, 0.9)
        
        tab:SetScript("OnClick", function()
            LFG.ChangeCategory(lfgTabTypes[i])
        end)
        
        tab:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
        end)
        
        tab:SetScript("OnLeave", function(self)
            if lfgTabTypes[i] == LFG.CurrentCategory then
                self.bg:SetColorTexture(0.3, 0.5, 0.7, 0.4)
            else
                self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
            end
        end)
        
        self.lfgTabs[lfgTabTypes[i]] = tab
    end
    
    -- ===== HEADER COLONNE =====
    local headerFrame = CreateFrame("Frame", nil, self.recruitersFrame)
    headerFrame:SetSize(720, 18)
    headerFrame:SetPoint("TOP", self.recruitersFrame, "TOP", 0, -40)
    
    local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameHeader:SetPoint("LEFT", headerFrame, "LEFT", 5, 0)
    nameHeader:SetText("Player")
    nameHeader:SetTextColor(0.6, 0.8, 1)
    
    local timeHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeHeader:SetPoint("LEFT", headerFrame, "LEFT", 100, 0)
    timeHeader:SetText("Time")
    timeHeader:SetTextColor(0.6, 0.8, 1)
    
    local catHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    catHeader:SetPoint("LEFT", headerFrame, "LEFT", 155, 0)
    catHeader:SetText("Type")
    catHeader:SetTextColor(0.6, 0.8, 1)
    
    local dungeonHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dungeonHeader:SetPoint("LEFT", headerFrame, "LEFT", 195, 0)
    dungeonHeader:SetText("Dungeon")
    dungeonHeader:SetTextColor(0.6, 0.8, 1)
    
    local msgHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msgHeader:SetPoint("LEFT", headerFrame, "LEFT", 285, 0)
    msgHeader:SetText("Message")
    msgHeader:SetTextColor(0.6, 0.8, 1)
    
    local acceptHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    acceptHeader:SetPoint("RIGHT", headerFrame, "RIGHT", -10, 0)
    acceptHeader:SetText("Action")
    acceptHeader:SetTextColor(0.6, 0.8, 1)
    
    -- Linea separatrice
    local separator = self.recruitersFrame:CreateTexture(nil, "BACKGROUND")
    separator:SetPoint("TOP", headerFrame, "BOTTOM", 0, -2)
    separator:SetSize(720, 1)
    separator:SetColorTexture(0.3, 0.3, 0.35, 0.3)
    
    -- ===== LISTA RECRUITERS =====
    self.recruitersList = CreateFrame("Frame", nil, self.recruitersFrame)
    self.recruitersList:SetSize(720, 260)
    self.recruitersList:SetPoint("TOP", headerFrame, "BOTTOM", 0, -8)
    self.recruitersList.rows = {}
    
    -- ===== SCROLL BUTTONS =====
    local scrollFrame = CreateFrame("Frame", nil, self.recruitersFrame)
    scrollFrame:SetPoint("TOP", self.recruitersList, "BOTTOM", 0, -10)
    scrollFrame:SetSize(720, 25)
    
    -- Bottone UP
    local scrollUpBtn = CreateFrame("Button", nil, scrollFrame)
    scrollUpBtn:SetSize(60, 20)
    scrollUpBtn:SetPoint("RIGHT", scrollFrame, "CENTER", -35, 0)
    scrollUpBtn.bg = scrollUpBtn:CreateTexture(nil, "BACKGROUND")
    scrollUpBtn.bg:SetAllPoints()
    scrollUpBtn.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
    scrollUpBtn.text = scrollUpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scrollUpBtn.text:SetPoint("CENTER")
    scrollUpBtn.text:SetText("Up")
    scrollUpBtn.text:SetTextColor(0.7, 0.7, 0.7)
    scrollUpBtn:SetScript("OnClick", function()
        LFG.ScrollRecruitersList("UP")
    end)
    scrollUpBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
        self.text:SetTextColor(1, 1, 1)
    end)
    scrollUpBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
        self.text:SetTextColor(0.7, 0.7, 0.7)
    end)
    
    -- Bottone DOWN
    local scrollDownBtn = CreateFrame("Button", nil, scrollFrame)
    scrollDownBtn:SetSize(60, 20)
    scrollDownBtn:SetPoint("LEFT", scrollFrame, "CENTER", 35, 0)
    scrollDownBtn.bg = scrollDownBtn:CreateTexture(nil, "BACKGROUND")
    scrollDownBtn.bg:SetAllPoints()
    scrollDownBtn.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
    scrollDownBtn.text = scrollDownBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scrollDownBtn.text:SetPoint("CENTER")
    scrollDownBtn.text:SetText("Down")
    scrollDownBtn.text:SetTextColor(0.7, 0.7, 0.7)
    scrollDownBtn:SetScript("OnClick", function()
        LFG.ScrollRecruitersList("DOWN")
    end)
    scrollDownBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
        self.text:SetTextColor(1, 1, 1)
    end)
    scrollDownBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
        self.text:SetTextColor(0.7, 0.7, 0.7)
    end)
    
    -- Scroll indicator
    self.scrollIndicator = scrollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.scrollIndicator:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
    self.scrollIndicator:SetText("")
    self.scrollIndicator:SetTextColor(0.6, 0.6, 0.6)
    
    -- ===== CONTROL BUTTONS =====
    self.controlsFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.controlsFrame:SetSize(740, 30)
    self.controlsFrame:SetPoint("BOTTOM", self.mainContainer, "BOTTOM", 0, 5)
    
    -- Refresh button
    local refreshBtn = CreateFrame("Button", nil, self.controlsFrame)
    refreshBtn:SetSize(70, 22)
    refreshBtn:SetPoint("LEFT", self.controlsFrame, "LEFT", 10, 0)
    refreshBtn.bg = refreshBtn:CreateTexture(nil, "BACKGROUND")
    refreshBtn.bg:SetAllPoints()
    refreshBtn.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
    refreshBtn.text = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    refreshBtn.text:SetPoint("CENTER")
    refreshBtn.text:SetText("Refresh")
    refreshBtn.text:SetTextColor(0.8, 0.8, 0.8)
    refreshBtn:SetScript("OnClick", function()
        currentScrollOffset = 0
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end)
    refreshBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
        self.text:SetTextColor(1, 1, 1)
    end)
    refreshBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
        self.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    
    -- Clear All button
    local clearAllBtn = CreateFrame("Button", nil, self.controlsFrame)
    clearAllBtn:SetSize(70, 22)
    clearAllBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 5, 0)
    clearAllBtn.bg = clearAllBtn:CreateTexture(nil, "BACKGROUND")
    clearAllBtn.bg:SetAllPoints()
    clearAllBtn.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
    clearAllBtn.text = clearAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    clearAllBtn.text:SetPoint("CENTER")
    clearAllBtn.text:SetText("Clear All")
    clearAllBtn.text:SetTextColor(0.8, 0.8, 0.8)
    clearAllBtn:SetScript("OnClick", LFG.ClearAllSearches)
    clearAllBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
        self.text:SetTextColor(1, 1, 1)
    end)
    clearAllBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
        self.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    
    -- Initialize
    LFG.CurrentCategory = "ALL"
    LFG.ChangeCategory("ALL")
    LFG.UpdatePlayerInfo()
    LFG.UpdateRecruitersList()
    
    self.frame:Hide()
end

function LFG:Show()
    LFG.UpdatePlayerInfo()
    LFG.UpdateRecruitersList()
    self.frame:Show()
end

function LFG:Hide()
    self.frame:Hide()
end

function LFG:RefreshData()
    LFG.UpdateRecruitersList()
end

function LFG:GetActiveRecruiterCount()
    return activeSearches and #activeSearches or 0
end

-- ==================== EVENT HANDLER ====================
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
EventFrame:RegisterEvent("CHAT_MSG_SAY")
EventFrame:RegisterEvent("CHAT_MSG_YELL")
EventFrame:RegisterEvent("CHAT_MSG_GUILD")
EventFrame:RegisterEvent("CHAT_MSG_OFFICER")
EventFrame:RegisterEvent("CHAT_MSG_RAID")
EventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
EventFrame:RegisterEvent("CHAT_MSG_PARTY")
EventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")

EventFrame:SetScript("OnEvent", function(self, event, message, sender, ...)
    if FrostSeekDB.LFG and FrostSeekDB.LFG.disableLFG then return end
    if not message or not sender then return end
    
    sender = string.gsub(sender, "%-[^|]+", "")
    if sender == UnitName("player") then return end
    
    local channel = event
    if event == "CHAT_MSG_CHANNEL" then
        local arg8 = select(8, ...)
        channel = arg8 or "CHANNEL"
    end
    
    if LFG.IsLFMMessage(message) then
        LFG.RecordActiveSearch(sender, message, channel)
    end
end)

-- ==================== INITIALIZATION ====================
local function InitializeLFGSystem()
    activeSearches = activeSearches or {}
    openFrames = openFrames or {}
    ignoreList = ignoreList or {}
    spammerList = spammerList or {}
    lastPopupTimes = lastPopupTimes or {}
    sessionStartTime = GetTime()
    
    FrostSeekDB.LFG = FrostSeekDB.LFG or {}
    FrostSeekDB.LFG.myRole = FrostSeekDB.LFG.myRole or ""
    FrostSeekDB.LFG.popupCategories = FrostSeekDB.LFG.popupCategories or {
        ALL = true, DUNGEON = true, RAID = true, PVP = true, MANASTORM = true, KEYSTONE = true
    }
    FrostSeekDB.LFG.filterWords = FrostSeekDB.LFG.filterWords or "boost,carry,wts,wtb,buy,sell,gold,account"
    FrostSeekDB.LFG.customFilterWords = FrostSeekDB.LFG.customFilterWords or ""
    FrostSeekDB.LFG.showActiveRecruitersWindow = false
    FrostSeekDB.LFG.maxMessageLength = FrostSeekDB.LFG.maxMessageLength or 150
    FrostSeekDB.LFG.frameDuration = FrostSeekDB.LFG.frameDuration or 6
    FrostSeekDB.LFG.popupCooldown = FrostSeekDB.LFG.popupCooldown or 400
    FrostSeekDB.LFG.maxConcurrentPopups = FrostSeekDB.LFG.maxConcurrentPopups or 3
    
    if LFG.roleDropdown then
        UIDropDownMenu_Initialize(LFG.roleDropdown, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.text = "No Role"; info.value = ""; info.func = function() LFG.SetRole("") end
            UIDropDownMenu_AddButton(info)
            info.text = "Tank"; info.value = "Tank"; info.func = function() LFG.SetRole("Tank") end
            UIDropDownMenu_AddButton(info)
            info.text = "Healer"; info.value = "Healer"; info.func = function() LFG.SetRole("Healer") end
            UIDropDownMenu_AddButton(info)
            info.text = "DPS"; info.value = "DPS"; info.func = function() LFG.SetRole("DPS") end
            UIDropDownMenu_AddButton(info)
        end)
        UIDropDownMenu_SetText(LFG.roleDropdown, FrostSeekDB.LFG.myRole ~= "" and FrostSeekDB.LFG.myRole or "No Role")
    end
    
    C_Timer.NewTicker(10, LFG.CleanupActiveSearches)
    
    print("|cff88ccffFrostSeek LFG:|r System initialized")
end

C_Timer.After(2, InitializeLFGSystem)

-- ==================== SLASH COMMANDS ====================
SLASH_FSDEBUG1 = "/fsdebug"
SlashCmdList["FSDEBUG"] = function()
    FrostSeekDB.Settings.debugMode = not FrostSeekDB.Settings.debugMode
    print("|cff88ccffFrostSeek:|r Debug mode " .. (FrostSeekDB.Settings.debugMode and "enabled" or "disabled"))
end

-- ==================== MODULE REGISTRATION ====================
local function RegisterLFGModule()
    if not _G.FrostSeek then
        C_Timer.After(0.5, RegisterLFGModule)
        return
    end
    if _G.FrostSeek.RegisterModule then
        _G.FrostSeek:RegisterModule("lfg", LFG)
        print("|cff88ccffFrostSeek LFG:|r Module registered")
    end
end

RegisterLFGModule()