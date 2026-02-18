-- ============================================================
-- FrostSeek - LFM Module (STILE COMPATTO - COME LFG)
-- ============================================================

local FrostSeek = _G.FrostSeek

local LFM = {}

-- ==================== VARIABILI GLOBALI ====================
local currentCategory = "RAIDS"
local selectedRoles = { Tank = false, Healer = false, DPS = false }
local selectedDifficulty = "Normal"
local searchText = ""
local currentKeystone = nil
local keystoneUpdateTicker = nil

-- ==================== ACTIVITY DATABASE ====================
local LFM_ACTIVITIES = {
    RAIDS = {
        { name = "Molten Core", template = "LFM Molten Core {difficulty} {roles}", keywords = {"mc", "molten core"} },
        { name = "Onyxia", template = "LFM Onyxia {difficulty} {roles}", keywords = {"onyxia", "ony"} },
        { name = "Blackwing Lair", template = "LFM Blackwing Lair {difficulty} {roles}", keywords = {"bwl", "blackwing"} },
        { name = "Zul'Gurub", template = "LFM Zul'Gurub {difficulty} {roles}", keywords = {"zg", "zulgurub"} },
        { name = "Ruins of Ahn'Qiraj", template = "LFM Ruins of AQ {difficulty} {roles}", keywords = {"aq20", "ruins"} },
        { name = "Temple of Ahn'Qiraj", template = "LFM Temple of AQ {difficulty} {roles}", keywords = {"aq40", "temple"} },
        { name = "Naxxramas", template = "LFM Naxxramas {difficulty} {roles}", keywords = {"naxx", "naxxramas"} },
        { name = "Karazhan", template = "LFM Karazhan {difficulty} {roles}", keywords = {"kara", "karazhan"} },
        { name = "Gruul's Lair", template = "LFM Gruul {difficulty} {roles}", keywords = {"gruul"} },
        { name = "Magtheridon", template = "LFM Magtheridon {difficulty} {roles}", keywords = {"mag", "magtheridon"} },
        { name = "Serpentshrine Cavern", template = "LFM SSC {difficulty} {roles}", keywords = {"ssc", "serpentshrine"} },
        { name = "Tempest Keep", template = "LFM TK {difficulty} {roles}", keywords = {"tk", "tempest"} },
        { name = "Hyjal Summit", template = "LFM Hyjal {difficulty} {roles}", keywords = {"hyjal"} },
        { name = "Black Temple", template = "LFM BT {difficulty} {roles}", keywords = {"bt", "black temple"} },
        { name = "Zul'Aman", template = "LFM Zul'Aman {difficulty} {roles}", keywords = {"za", "zulaman"} },
        { name = "Sunwell Plateau", template = "LFM Sunwell {difficulty} {roles}", keywords = {"swp", "sunwell"} },
        { name = "Eye of Eternity", template = "LFM Eye of Eternity {difficulty} {roles}", keywords = {"eye", "eoe", "malygos"} },
        { name = "Obsidian Sanctum", template = "LFM OS {difficulty} {roles}", keywords = {"os", "obsidian", "sarth"} },
        { name = "Vault of Archavon", template = "LFM VoA {difficulty} {roles}", keywords = {"voa", "archavon"} },
        { name = "Ulduar", template = "LFM Ulduar {difficulty} {roles}", keywords = {"ulduar", "uld"} },
        { name = "Trial of the Crusader", template = "LFM ToC {difficulty} {roles}", keywords = {"toc", "crusader"} },
        { name = "Icecrown Citadel", template = "LFM ICC {difficulty} {roles}", keywords = {"icc", "icecrown"} },
        { name = "Ruby Sanctum", template = "LFM Ruby Sanctum {difficulty} {roles}", keywords = {"rs", "ruby", "halion"} },
    },
    
    DUNGEONS = {
        { name = "Deadmines", template = "LFM Deadmines {difficulty} {roles}", keywords = {"deadmines", "dm", "vc"} },
        { name = "Ragefire Chasm", template = "LFM Ragefire Chasm {difficulty} {roles}", keywords = {"rfc", "ragefire"} },
        { name = "Shadowfang Keep", template = "LFM SFK {difficulty} {roles}", keywords = {"sfk", "shadowfang"} },
        { name = "Blackrock Depths", template = "LFM BRD {difficulty} {roles}", keywords = {"brd", "blackrock depths"} },
        { name = "Stratholme", template = "LFM Strat {difficulty} {roles}", keywords = {"strat", "stratholme"} },
        { name = "Scholomance", template = "LFM Scholo {difficulty} {roles}", keywords = {"scholo", "scholomance"} },
        { name = "Lower Blackrock Spire", template = "LFM LBRS {difficulty} {roles}", keywords = {"lbrs", "lower"} },
        { name = "Upper Blackrock Spire", template = "LFM UBRS {difficulty} {roles}", keywords = {"ubrs", "upper"} },
        { name = "Dire Maul East", template = "LFM DME {difficulty} {roles}", keywords = {"dme", "east"} },
        { name = "Dire Maul North", template = "LFM DMN {difficulty} {roles}", keywords = {"dmn", "north"} },
        { name = "Dire Maul West", template = "LFM DMW {difficulty} {roles}", keywords = {"dmw", "west"} },
        { name = "Hellfire Ramparts", template = "LFM Ramparts {difficulty} {roles}", keywords = {"ramps", "ramparts"} },
        { name = "Blood Furnace", template = "LFM Blood Furnace {difficulty} {roles}", keywords = {"bf", "blood furnace"} },
        { name = "Slave Pens", template = "LFM Slave Pens {difficulty} {roles}", keywords = {"sp", "slave pens"} },
        { name = "Underbog", template = "LFM Underbog {difficulty} {roles}", keywords = {"ub", "underbog"} },
        { name = "Mana-Tombs", template = "LFM Mana-Tombs {difficulty} {roles}", keywords = {"mt", "mana-tombs"} },
        { name = "Auchenai Crypts", template = "LFM Auchenai {difficulty} {roles}", keywords = {"ac", "auchenai"} },
        { name = "Sethekk Halls", template = "LFM Sethekk {difficulty} {roles}", keywords = {"sh", "sethekk"} },
        { name = "Shadow Labyrinth", template = "LFM Shadow Laby {difficulty} {roles}", keywords = {"sl", "slabs", "shadow lab"} },
        { name = "Mechanar", template = "LFM Mechanar {difficulty} {roles}", keywords = {"mecha", "mechanar"} },
        { name = "Botanica", template = "LFM Botanica {difficulty} {roles}", keywords = {"bota", "botanica"} },
        { name = "Arcatraz", template = "LFM Arcatraz {difficulty} {roles}", keywords = {"arca", "arcatraz"} },
        { name = "Magister's Terrace", template = "LFM Magister's {difficulty} {roles}", keywords = {"mgt", "magisters"} },
        { name = "Utgarde Keep", template = "LFM UK {difficulty} {roles}", keywords = {"uk", "utgarde keep"} },
        { name = "Utgarde Pinnacle", template = "LFM UP {difficulty} {roles}", keywords = {"up", "pinnacle"} },
        { name = "The Nexus", template = "LFM Nexus {difficulty} {roles}", keywords = {"nexus", "nex"} },
        { name = "The Oculus", template = "LFM Oculus {difficulty} {roles}", keywords = {"oculus", "ocu"} },
        { name = "Azjol-Nerub", template = "LFM AN {difficulty} {roles}", keywords = {"an", "azjol"} },
        { name = "Ahn'kahet", template = "LFM Old Kingdom {difficulty} {roles}", keywords = {"ak", "ahn'kahet"} },
        { name = "Drak'Tharon Keep", template = "LFM DTK {difficulty} {roles}", keywords = {"dtk", "drak'tharon"} },
        { name = "Violet Hold", template = "LFM Violet Hold {difficulty} {roles}", keywords = {"vh", "violet"} },
        { name = "Gundrak", template = "LFM Gundrak {difficulty} {roles}", keywords = {"gun", "gundrak"} },
        { name = "Halls of Stone", template = "LFM HoS {difficulty} {roles}", keywords = {"hos", "halls stone"} },
        { name = "Halls of Lightning", template = "LFM HoL {difficulty} {roles}", keywords = {"hol", "halls lightning"} },
        { name = "Culling of Stratholme", template = "LFM CoS {difficulty} {roles}", keywords = {"cos", "culling"} },
        { name = "Trial of the Champion", template = "LFM ToC Dungeon {difficulty} {roles}", keywords = {"toc", "champion"} },
        { name = "Forge of Souls", template = "LFM Forge of Souls {difficulty} {roles}", keywords = {"fos", "forge"} },
        { name = "Pit of Saron", template = "LFM Pit of Saron {difficulty} {roles}", keywords = {"pos", "pit"} },
        { name = "Halls of Reflection", template = "LFM HoR {difficulty} {roles}", keywords = {"hor", "reflection"} },
        { name = "Vault of the Inquisition", template = "LFM Vault {difficulty} {roles}", keywords = {"vault", "inquisition"} },
        { name = "Blackrock Cavern", template = "LFM BRC {difficulty} {roles}", keywords = {"brc", "blackrock cavern"} },
        { name = "Karazhan Crypts", template = "LFM KC {difficulty} {roles}", keywords = {"kc", "karazhan crypts"} },
    },
    
    MANASTORM = {
        { name = "ALVA Boss", template = "LFM ALVA Boss {roles}", keywords = {"alva", "boss"} },
        { name = "Manastorm Gold Farm", template = "LFM Manastorm Gold {roles}", keywords = {"manastorm", "gold", "farm"} },
        { name = "Manastorm Leveling", template = "LFM Manastorm Level {roles}", keywords = {"manastorm", "level", "xp"} },
        { name = "Manastorm Bonzo Farm", template = "LFM Bonzo {roles}", keywords = {"bonzo", "farm"} },
    },
    
    WORLD_BOSS = {
        { name = "Azuregos", template = "LFM Azuregos {difficulty} {roles}", keywords = {"azuregos", "azure"} },
        { name = "Lord Kazzak", template = "LFM Lord Kazzak {difficulty} {roles}", keywords = {"kazzak"} },
        { name = "Doomwalker", template = "LFM Doomwalker {difficulty} {roles}", keywords = {"doomwalker"} },
        { name = "Setis", template = "LFM Setis {difficulty} {roles}", keywords = {"setis", "settis"} },
        { name = "Emeriss", template = "LFM Emeriss {difficulty} {roles}", keywords = {"emeriss"} },
        { name = "Lethon", template = "LFM Lethon {difficulty} {roles}", keywords = {"lethon"} },
        { name = "Taerar", template = "LFM Taerar {difficulty} {roles}", keywords = {"taerar"} },
        { name = "Ysondre", template = "LFM Ysondre {difficulty} {roles}", keywords = {"ysondre"} },
        -- Ascension Custom WORLD BOSS
        { name = "Soggoth", template = "LFM Soggoth {difficulty} {roles}", keywords = {"soggoth"} },
        { name = "Snowgrave", template = "LFM Snowgrave {difficulty} {roles}", keywords = {"snowgrave"} },
        { name = "Atal’Zul ", template = "LFM Atal’Zul  {difficulty} {roles}", keywords = {"atal’Zul"} },
        { name = "WorldBossTour ", template = "LFM World Boss Tour  {difficulty} {roles}", keywords = {"worldtour"} },
    },
    
    PVP = {
        { name = "Arena 2v2", template = "LFM Arena 2v2 {roles}", keywords = {"2v2", "2s", "twos"} },
        { name = "Arena 3v3", template = "LFM Arena 3v3 {roles}", keywords = {"3v3", "3s", "threes"} },
        { name = "Arena 5v5", template = "LFM Arena 5v5 {roles}", keywords = {"5v5", "5s", "fives"} },
        { name = "Battlegrounds", template = "LFM BG {roles}", keywords = {"bg", "battleground"} },
        { name = "Wintergrasp", template = "LFM Wintergrasp {roles}", keywords = {"wg", "wintergrasp"} },
    },
    
    KEYSTONE = {},
}

local DIFFICULTIES = {
    RAIDS = {"Normal", "Heroic", "Mythic", "Ascended", "Trial 1", "Trial 2", "Trial 3", "Trial 4", "Trial 5", "Trial 6", "Trial 7", "Trial 8", "Trial 9", "Trial 10"},
    DUNGEONS = {"Normal", "Heroic", "Mythic"},
    WORLD_BOSS = {"Open World", "Instanced"},
    KEYSTONE = {"Mythic+"},
}

local CHANNELS = {
    "SAY", "YELL", "PARTY", "RAID", "GUILD", "INSTANCE_CHAT",
    "CHANNEL1", "CHANNEL2", "CHANNEL3", "CHANNEL4", "CHANNEL5",
    "CHANNEL6", "CHANNEL7", "CHANNEL8", "CHANNEL9", "CHANNEL10"
}

-- ==================== HELPER FUNCTIONS ====================
local function FindKeystoneInBags()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local itemName = GetItemInfo(itemLink)
                if itemName and string.find(itemName, "Keystone") then
                    return itemLink, itemName, bag, slot
                end
            end
        end
    end
    return nil, nil, nil, nil
end

local function GetKeystoneInfo(itemLink)
    if not itemLink then return nil end
    
    local itemName = GetItemInfo(itemLink)
    if not itemName then return nil end
    
    return {
        link = itemLink,
        name = itemName,
    }
end

local function UpdateKeystoneList()
    if not LFM_ACTIVITIES.KEYSTONE then
        LFM_ACTIVITIES.KEYSTONE = {}
    else
        wipe(LFM_ACTIVITIES.KEYSTONE)
    end
    
    local keystoneLink, keystoneName = FindKeystoneInBags()
    
    if keystoneLink then
        local keystoneInfo = GetKeystoneInfo(keystoneLink)
        if keystoneInfo then
            table.insert(LFM_ACTIVITIES.KEYSTONE, {
                name = keystoneInfo.name,
                template = "LFM {keystone} {roles}",
                keywords = {"keystone", "mythic", "mythic+"},
                keystoneLink = keystoneLink,
                keystoneInfo = keystoneInfo,
            })
            currentKeystone = keystoneInfo
        end
    else
        currentKeystone = nil
    end
    
    if currentCategory == "KEYSTONE" then
        if #LFM_ACTIVITIES.KEYSTONE > 0 then
            local activity = LFM_ACTIVITIES.KEYSTONE[1]
            UpdateMessagePreview(activity.template, activity)
        else
            UpdateMessagePreview()
        end
    end
    
    return currentKeystone ~= nil
end

local function StartKeystoneAutoUpdate()
    if keystoneUpdateTicker then
        keystoneUpdateTicker:Cancel()
        keystoneUpdateTicker = nil
    end
    
    local interval = FrostSeekDB.LFM.autoUpdateInterval or 60
    
    if interval <= 0 then
        if LFM.autoUpdateText then
            LFM.autoUpdateText:SetText("|cFFFF0000Auto: Off|r")
            LFM.autoUpdateText:Show()
        end
        return
    end
    
    if currentCategory == "KEYSTONE" and LFM.autoUpdateText then
        LFM.autoUpdateText:SetText(string.format("|cFF00FF00Auto: %ds|r", interval))
        LFM.autoUpdateText:Show()
    end
    
    keystoneUpdateTicker = C_Timer.NewTicker(interval, function()
        UpdateKeystoneList()
        if currentCategory ~= "KEYSTONE" then
            if keystoneUpdateTicker then
                keystoneUpdateTicker:Cancel()
                keystoneUpdateTicker = nil
            end
            if LFM.autoUpdateText then
                LFM.autoUpdateText:Hide()
            end
        end
    end)
end

local function StopKeystoneAutoUpdate()
    if keystoneUpdateTicker then
        keystoneUpdateTicker:Cancel()
        keystoneUpdateTicker = nil
    end
    if LFM.autoUpdateText then
        LFM.autoUpdateText:Hide()
    end
end

local function GenerateRolesText()
    local roles = {}
    if selectedRoles.Tank then table.insert(roles, "Tank") end
    if selectedRoles.Healer then table.insert(roles, "Healer") end
    if selectedRoles.DPS then table.insert(roles, "DPS") end
    
    if #roles == 0 then
        return "All Roles"
    else
        return table.concat(roles, " ")
    end
end

local function ProcessTemplate(template, activity)
    local processed = template:gsub("{roles}", GenerateRolesText())
    processed = processed:gsub("{difficulty}", selectedDifficulty)
    
    if activity and activity.keystoneLink then
        processed = processed:gsub("{keystone}", activity.keystoneLink)
    end
    
    return processed
end

local function FilterActivities(activities)
    if not searchText or searchText == "" then
        return activities
    end
    
    local filtered = {}
    local searchLower = string.lower(searchText)
    
    for _, activity in ipairs(activities) do
        local nameLower = string.lower(activity.name)
        
        if string.find(nameLower, searchLower) then
            table.insert(filtered, activity)
        else
            for _, keyword in ipairs(activity.keywords) do
                if string.find(string.lower(keyword), searchLower) then
                    table.insert(filtered, activity)
                    break
                end
            end
        end
    end
    
    return filtered
end

local function SendLFMMessage(message, channel)
    if not message or message == "" then return end
    
    if currentCategory == "KEYSTONE" and not FindKeystoneInBags() then
        print("|cffff0000FrostSeek LFM:|r No Keystone found!")
        return
    end
    
    if string.match(channel, "CHANNEL%d+") then
        local channelNum = tonumber(string.match(channel, "CHANNEL(%d+)"))
        if channelNum then
            SendChatMessage(message, "CHANNEL", nil, channelNum)
        end
    else
        SendChatMessage(message, channel)
    end
    
    table.insert(FrostSeekDB.LFM.lastMessages, 1, {
        message = message,
        channel = channel,
        timestamp = time()
    })
    
    while #FrostSeekDB.LFM.lastMessages > 10 do
        table.remove(FrostSeekDB.LFM.lastMessages)
    end
    
    print("|cff88ccffFrostSeek LFM:|r Sent to " .. channel)
end

-- ==================== UI FUNCTIONS ====================
function UpdateMessagePreview(template, activity)
    if not LFM.previewText then return end
    
    if template then
        local processed = ProcessTemplate(template, activity)
        LFM.previewText:SetText(processed)
        LFM.previewText:SetTextColor(1, 1, 1)
    else
        LFM.previewText:SetText("Select an activity...")
        LFM.previewText:SetTextColor(0.8, 0.8, 0.8)
    end
end

function UpdateDifficultyDropdown()
    local difficulties = DIFFICULTIES[currentCategory] or {"Normal"}
    
    if not LFM.difficultyDropdown then return end
    
    UIDropDownMenu_Initialize(LFM.difficultyDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, difficulty in ipairs(difficulties) do
            info.text = difficulty
            info.value = difficulty
            info.func = function()
                selectedDifficulty = difficulty
                UIDropDownMenu_SetText(LFM.difficultyDropdown, difficulty)
                UpdateMessagePreview()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    selectedDifficulty = difficulties[1] or "Normal"
    UIDropDownMenu_SetText(LFM.difficultyDropdown, selectedDifficulty)
end

function UpdateActivityList()
    if not LFM.activitiesContent then return end
    
    if LFM.activitiesContent.buttons then
        for i, btn in ipairs(LFM.activitiesContent.buttons) do
            if btn then
                btn:Hide()
                btn:SetParent(nil)
            end
        end
    end
    
    LFM.activitiesContent.buttons = {}
    
    local activities = LFM_ACTIVITIES[currentCategory] or {}
    local filteredActivities = FilterActivities(activities)
    local yOffset = -5
    
    for i, activity in ipairs(filteredActivities) do
        local btn = CreateFrame("Button", nil, LFM.activitiesContent)
        btn:SetSize(540, 24)
        btn:SetPoint("TOPLEFT", LFM.activitiesContent, "TOPLEFT", 5, yOffset)
        
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        if i % 2 == 0 then
            bg:SetColorTexture(0.1, 0.1, 0.12, 0.1)
        else
            bg:SetColorTexture(0.08, 0.08, 0.1, 0.05)
        end
        
        local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", btn, "LEFT", 10, 0)
        
        if currentCategory == "KEYSTONE" and activity.keystoneLink then
            nameText:SetText(activity.keystoneLink)
        else
            nameText:SetText(activity.name)
        end
        nameText:SetTextColor(1, 1, 1)
        
        local templateText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        templateText:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
        templateText:SetText(activity.template)
        templateText:SetTextColor(0.7, 0.7, 0.7)
        
        btn:SetScript("OnClick", function()
            UpdateMessagePreview(activity.template, activity)
        end)
        
        btn:SetScript("OnEnter", function(self)
            bg:SetColorTexture(0.2, 0.3, 0.4, 0.2)
        end)
        
        btn:SetScript("OnLeave", function(self)
            if i % 2 == 0 then
                bg:SetColorTexture(0.1, 0.1, 0.12, 0.1)
            else
                bg:SetColorTexture(0.08, 0.08, 0.1, 0.05)
            end
        end)
        
        LFM.activitiesContent.buttons[i] = btn
        yOffset = yOffset - 25
    end
    
    LFM.activitiesContent:SetHeight(math.max(math.abs(yOffset) + 10, 300))
end

function UpdateTabsAppearance()
    local categoryTabs = {
        { key = "RAIDS", name = "Raid" },
        { key = "DUNGEONS", name = "Dungeon" },
        { key = "MANASTORM", name = "Manastorm" },
        { key = "WORLD_BOSS", name = "WBoss" },
        { key = "PVP", name = "PvP" },
        { key = "KEYSTONE", name = "Key" }
    }
    
    for i, tabInfo in ipairs(categoryTabs) do
        local tab = _G["LFM_Tab_" .. tabInfo.key]
        if tab then
            if tabInfo.key == currentCategory then
                tab.bg:SetColorTexture(0.3, 0.5, 0.7, 0.4)
                tab.text:SetTextColor(1, 1, 1)
            else
                tab.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
                tab.text:SetTextColor(0.8, 0.8, 0.8)
            end
        end
    end
end

function LFM:UpdateAutoUpdateInterval()
    if keystoneUpdateTicker and currentCategory == "KEYSTONE" then
        StartKeystoneAutoUpdate()
    end
end

-- ==================== MODULE INITIALIZATION ====================
function LFM:Initialize(parentFrame)
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)
    
    -- ===== MAIN CONTAINER - LARGHEZZA MASSIMA =====
    self.mainContainer = CreateFrame("Frame", nil, self.frame)
    self.mainContainer:SetSize(760, 500)
    self.mainContainer:SetPoint("TOP", self.frame, "TOP", 0, -5)
    
    -- ===== TITLE =====
    self.title = self.mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.title:SetPoint("TOP", self.mainContainer, "TOP", 0, -8)
    self.title:SetText("|cff88ccffLooking For Members|r")
    self.title:SetTextColor(0.8, 0.9, 1)
    
    -- ===== DESCRIPTION =====
    self.desc = self.mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.desc:SetPoint("TOP", self.title, "BOTTOM", 0, -4)
    self.desc:SetText("Create and send LFM messages")
    self.desc:SetTextColor(0.7, 0.7, 0.7)
    
    -- ===== ROLES FRAME - CORRETTO =====
self.rolesFrame = CreateFrame("Frame", nil, self.mainContainer)
self.rolesFrame:SetSize(740, 30)
self.rolesFrame:SetPoint("TOP", self.desc, "BOTTOM", 0, -10)

local rolesLabel = self.rolesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
rolesLabel:SetPoint("LEFT", self.rolesFrame, "LEFT", 10, 0)
rolesLabel:SetText("Need:")
rolesLabel:SetTextColor(0.8, 0.8, 0.8)

self.roleCheckboxes = {}
local roleTypes = {"Tank", "Healer", "DPS"}
for i, role in ipairs(roleTypes) do
    local checkbox = CreateFrame("CheckButton", "FrostSeekLFM_Role_" .. role, self.rolesFrame, "UICheckButtonTemplate")
    checkbox:SetPoint("LEFT", rolesLabel, "RIGHT", 20 + (i-1) * 70, 0)
    checkbox:SetSize(20, 20)
    
    -- Usa il nome che abbiamo appena impostato
    local text = _G[checkbox:GetName() .. "Text"]
    if text then
        text:SetText(role)
        text:SetFontObject("GameFontNormalSmall")
    end
    
    checkbox:SetScript("OnClick", function(self)
        selectedRoles[role] = self:GetChecked()
        UpdateMessagePreview()
    end)
    
    self.roleCheckboxes[role] = checkbox
end
    
    -- ===== DIFFICULTY FRAME =====
    self.difficultyFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.difficultyFrame:SetSize(740, 30)
    self.difficultyFrame:SetPoint("TOP", self.rolesFrame, "BOTTOM", 0, -5)
    
    local difficultyLabel = self.difficultyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    difficultyLabel:SetPoint("LEFT", self.difficultyFrame, "LEFT", 10, 0)
    difficultyLabel:SetText("Difficulty:")
    difficultyLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.difficultyDropdown = CreateFrame("Frame", "LFM_DifficultyDropdown", self.difficultyFrame, "UIDropDownMenuTemplate")
    self.difficultyDropdown:SetPoint("LEFT", difficultyLabel, "RIGHT", 10, -3)
    UIDropDownMenu_SetWidth(self.difficultyDropdown, 100)
    UIDropDownMenu_SetText(self.difficultyDropdown, selectedDifficulty)
    
    -- ===== SEARCH FRAME =====
    self.searchFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.searchFrame:SetSize(740, 30)
    self.searchFrame:SetPoint("TOP", self.difficultyFrame, "BOTTOM", 0, -5)
    
    local searchLabel = self.searchFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", self.searchFrame, "LEFT", 10, 0)
    searchLabel:SetText("Search:")
    searchLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.searchBox = CreateFrame("EditBox", nil, self.searchFrame, "InputBoxTemplate")
    self.searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    self.searchBox:SetSize(160, 20)
    self.searchBox:SetAutoFocus(false)
    self.searchBox:SetText("")
    self.searchBox:SetFontObject("GameFontNormalSmall")
    
    self.searchBox:SetScript("OnTextChanged", function(self)
        searchText = self:GetText()
        UpdateActivityList()
    end)
    
    local clearSearchBtn = CreateFrame("Button", nil, self.searchFrame)
    clearSearchBtn:SetSize(50, 20)
    clearSearchBtn:SetPoint("LEFT", self.searchBox, "RIGHT", 5, 0)
    clearSearchBtn.bg = clearSearchBtn:CreateTexture(nil, "BACKGROUND")
    clearSearchBtn.bg:SetAllPoints()
    clearSearchBtn.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
    clearSearchBtn.text = clearSearchBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    clearSearchBtn.text:SetPoint("CENTER")
    clearSearchBtn.text:SetText("Clear")
    clearSearchBtn.text:SetTextColor(0.8, 0.8, 0.8)
    clearSearchBtn:SetScript("OnClick", function()
        self.searchBox:SetText("")
        searchText = ""
        UpdateActivityList()
    end)
    clearSearchBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
        self.text:SetTextColor(1, 1, 1)
    end)
    clearSearchBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
        self.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    
    -- ===== CATEGORY TABS =====
    self.categoriesFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.categoriesFrame:SetSize(740, 30)
    self.categoriesFrame:SetPoint("TOP", self.searchFrame, "BOTTOM", 0, -5)
    
    local categoryTabs = {
        { key = "RAIDS", name = "Raid" },
        { key = "DUNGEONS", name = "Dungeon" },
        { key = "MANASTORM", name = "Manastorm" },
        { key = "WORLD_BOSS", name = "WBoss" },
        { key = "PVP", name = "PvP" },
        { key = "KEYSTONE", name = "Key" }
    }
    
    for i, tabInfo in ipairs(categoryTabs) do
        local tab = CreateFrame("Button", nil, self.categoriesFrame)
        tab:SetSize(70, 22)
        tab:SetPoint("LEFT", 10 + ((i-1) * 75), 0)
        
        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        tab.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
        
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(tabInfo.name)
        tab.text:SetTextColor(0.9, 0.9, 0.9)
        
        tab:SetScript("OnClick", function()
            currentCategory = tabInfo.key
            if currentCategory == "KEYSTONE" then
                UpdateKeystoneList()
                StartKeystoneAutoUpdate()
            else
                StopKeystoneAutoUpdate()
            end
            UpdateDifficultyDropdown()
            UpdateActivityList()
            UpdateTabsAppearance()
        end)
        
        tab:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
        end)
        
        tab:SetScript("OnLeave", function(self)
            if tabInfo.key == currentCategory then
                self.bg:SetColorTexture(0.3, 0.5, 0.7, 0.4)
            else
                self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
            end
        end)
        
        _G["LFM_Tab_" .. tabInfo.key] = tab
    end
    
    -- ===== ACTIVITIES LIST =====
    self.activitiesFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.activitiesFrame:SetSize(740, 200)
    self.activitiesFrame:SetPoint("TOP", self.categoriesFrame, "BOTTOM", 0, -10)
    
    local activitiesBg = self.activitiesFrame:CreateTexture(nil, "BACKGROUND")
    activitiesBg:SetAllPoints()
    activitiesBg:SetColorTexture(0.05, 0.05, 0.08, 0.15)
    
    self.activitiesScrollFrame = CreateFrame("ScrollFrame", nil, self.activitiesFrame, "UIPanelScrollFrameTemplate")
    self.activitiesScrollFrame:SetPoint("TOPLEFT", 5, -5)
    self.activitiesScrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)
    
    self.activitiesContent = CreateFrame("Frame", nil, self.activitiesScrollFrame)
    self.activitiesContent:SetSize(700, 300)
    self.activitiesScrollFrame:SetScrollChild(self.activitiesContent)
    
    -- ===== MESSAGE PREVIEW =====
    self.previewFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.previewFrame:SetSize(740, 50)
    self.previewFrame:SetPoint("TOP", self.activitiesFrame, "BOTTOM", 0, -10)
    
    local previewBg = self.previewFrame:CreateTexture(nil, "BACKGROUND")
    previewBg:SetAllPoints()
    previewBg:SetColorTexture(0.08, 0.08, 0.1, 0.2)
    
    local previewLabel = self.previewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewLabel:SetPoint("TOPLEFT", self.previewFrame, "TOPLEFT", 10, -8)
    previewLabel:SetText("Preview:")
    previewLabel:SetTextColor(0.6, 0.8, 1)
    
    self.previewText = self.previewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.previewText:SetPoint("TOPLEFT", previewLabel, "BOTTOMLEFT", 0, -4)
    self.previewText:SetPoint("RIGHT", self.previewFrame, "RIGHT", -10, 0)
    self.previewText:SetJustifyH("LEFT")
    self.previewText:SetText("Select an activity...")
    self.previewText:SetTextColor(0.8, 0.8, 0.8)
    
    -- ===== AUTO UPDATE INDICATOR =====
    self.autoUpdateText = self.previewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.autoUpdateText:SetPoint("BOTTOMLEFT", self.previewFrame, "BOTTOMLEFT", 10, 5)
    self.autoUpdateText:SetText("")
    self.autoUpdateText:Hide()
    
    -- ===== CONTROLS FRAME =====
    self.controlsFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.controlsFrame:SetSize(740, 40)
    self.controlsFrame:SetPoint("BOTTOM", self.mainContainer, "BOTTOM", 0, 10)
    
    -- Channel dropdown
    local channelLabel = self.controlsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    channelLabel:SetPoint("LEFT", self.controlsFrame, "LEFT", 10, 0)
    channelLabel:SetText("Channel:")
    channelLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.channelDropdown = CreateFrame("Frame", "LFM_ChannelDropdown", self.controlsFrame, "UIDropDownMenuTemplate")
    self.channelDropdown:SetPoint("LEFT", channelLabel, "RIGHT", 10, -3)
    UIDropDownMenu_SetWidth(self.channelDropdown, 100)
    UIDropDownMenu_SetText(self.channelDropdown, "SAY")
    
    UIDropDownMenu_Initialize(self.channelDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, channel in ipairs(CHANNELS) do
            info.text = channel
            info.value = channel
            info.func = function()
                UIDropDownMenu_SetText(LFM.channelDropdown, channel)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Send button
    self.sendBtn = CreateFrame("Button", nil, self.controlsFrame)
    self.sendBtn:SetSize(80, 24)
    self.sendBtn:SetPoint("RIGHT", self.controlsFrame, "RIGHT", -10, 0)
    self.sendBtn.bg = self.sendBtn:CreateTexture(nil, "BACKGROUND")
    self.sendBtn.bg:SetAllPoints()
    self.sendBtn.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
    self.sendBtn.text = self.sendBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.sendBtn.text:SetPoint("CENTER")
    self.sendBtn.text:SetText("Send LFM")
    self.sendBtn.text:SetTextColor(0.4, 1, 0.4)
    self.sendBtn:SetScript("OnClick", function()
        local message = self.previewText:GetText()
        if message and message ~= "Select an activity..." then
            SendLFMMessage(message, UIDropDownMenu_GetText(LFM.channelDropdown))
        end
    end)
    self.sendBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
        self.text:SetTextColor(0.6, 1, 0.6)
    end)
    self.sendBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
        self.text:SetTextColor(0.4, 1, 0.4)
    end)
    
    -- Copy button
    self.copyBtn = CreateFrame("Button", nil, self.controlsFrame)
    self.copyBtn:SetSize(60, 24)
    self.copyBtn:SetPoint("RIGHT", self.sendBtn, "LEFT", -5, 0)
    self.copyBtn.bg = self.copyBtn:CreateTexture(nil, "BACKGROUND")
    self.copyBtn.bg:SetAllPoints()
    self.copyBtn.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
    self.copyBtn.text = self.copyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.copyBtn.text:SetPoint("CENTER")
    self.copyBtn.text:SetText("Copy")
    self.copyBtn.text:SetTextColor(0.8, 0.8, 0.8)
    self.copyBtn:SetScript("OnClick", function()
        local message = self.previewText:GetText()
        if message and message ~= "Select an activity..." then
            print("|cff88ccffFrostSeek LFM:|r " .. message)
        end
    end)
    self.copyBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
        self.text:SetTextColor(1, 1, 1)
    end)
    self.copyBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
        self.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    
    -- Refresh Keystone button
    self.refreshKeystoneBtn = CreateFrame("Button", nil, self.controlsFrame)
    self.refreshKeystoneBtn:SetSize(80, 24)
    self.refreshKeystoneBtn:SetPoint("RIGHT", self.copyBtn, "LEFT", -5, 0)
    self.refreshKeystoneBtn.bg = self.refreshKeystoneBtn:CreateTexture(nil, "BACKGROUND")
    self.refreshKeystoneBtn.bg:SetAllPoints()
    self.refreshKeystoneBtn.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
    self.refreshKeystoneBtn.text = self.refreshKeystoneBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.refreshKeystoneBtn.text:SetPoint("CENTER")
    self.refreshKeystoneBtn.text:SetText("Refresh Key")
    self.refreshKeystoneBtn.text:SetTextColor(0.8, 0.8, 0.8)
    self.refreshKeystoneBtn:SetScript("OnClick", function()
        UpdateKeystoneList()
        print("|cff88ccffFrostSeek LFM:|r Keystone refreshed")
    end)
    self.refreshKeystoneBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
        self.text:SetTextColor(1, 1, 1)
    end)
    self.refreshKeystoneBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
        self.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    
    -- Initialize
    UpdateDifficultyDropdown()
    UpdateTabsAppearance()
    UpdateActivityList()
    
    -- Hide keystone button by default
    self.refreshKeystoneBtn:Hide()
    
    self.frame:Hide()
end

function LFM:Show()
    if currentCategory == "KEYSTONE" then
        UpdateKeystoneList()
        StartKeystoneAutoUpdate()
        if self.refreshKeystoneBtn then
            self.refreshKeystoneBtn:Show()
        end
    else
        if self.refreshKeystoneBtn then
            self.refreshKeystoneBtn:Hide()
        end
    end
    
    self.frame:Show()
end

function LFM:Hide()
    self.frame:Hide()
    StopKeystoneAutoUpdate()
end

function LFM:RefreshData()
    UpdateActivityList()
    UpdateMessagePreview()
end

-- ==================== BAG UPDATE HANDLER ====================
local bagUpdateHandler = CreateFrame("Frame")
bagUpdateHandler:RegisterEvent("BAG_UPDATE_DELAYED")
bagUpdateHandler:SetScript("OnEvent", function(self, event)
    if event == "BAG_UPDATE_DELAYED" and currentCategory == "KEYSTONE" then
        C_Timer.After(0.5, function()
            UpdateKeystoneList()
        end)
    end
end)

-- ==================== INITIALIZATION ====================
local function InitializeLFMSystem()
    FrostSeekDB.LFM = FrostSeekDB.LFM or {
        lastMessages = {},
        favoriteTemplates = {},
        channelPresets = {},
        autoUpdateInterval = 60
    }
    
    if not LFM_ACTIVITIES.KEYSTONE then
        LFM_ACTIVITIES.KEYSTONE = {}
    end
    
    UpdateKeystoneList()
    
    print("|cff88ccffFrostSeek LFM:|r System initialized")
end

C_Timer.After(2, InitializeLFMSystem)

-- ==================== CLEANUP ====================
local cleanupFrame = CreateFrame("Frame")
cleanupFrame:RegisterEvent("PLAYER_LOGOUT")
cleanupFrame:SetScript("OnEvent", function()
    StopKeystoneAutoUpdate()
end)

-- ==================== MODULE REGISTRATION ====================
local function RegisterLFMModule()
    if not _G.FrostSeek then
        C_Timer.After(0.5, RegisterLFMModule)
        return
    end
    
    if _G.FrostSeek.RegisterModule then
        _G.FrostSeek:RegisterModule("lfm", LFM)
        print("|cff88ccffFrostSeek LFM:|r Module registered")
    end
end

RegisterLFMModule()