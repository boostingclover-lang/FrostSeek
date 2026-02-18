-- ============================================================
-- FrostSeek - Options Module
-- ============================================================

local FrostSeek = _G.FrostSeek

local Options = {}

-- ==================== LOCAL VARIABLES ====================
local settingsWindow = nil
local categoryFrames = {}
local currentCategory = "general"

-- ==================== VARIABILI PER CUSTOM MESSAGE ====================
local keystoneUpdateTicker = nil

-- ==================== FUNZIONE PER GARANTIRE LA STRUTTURA DATI ====================
local function EnsureSettingsStructure()
    if not FrostSeekDB then
        FrostSeekDB = {}
    end
    if not FrostSeekDB.Settings then
        FrostSeekDB.Settings = {}
    end
    -- Imposta il valore predefinito se non esiste
    if FrostSeekDB.Settings.uiScale == nil then
        FrostSeekDB.Settings.uiScale = 1.0
    end
    if FrostSeekDB.Settings.autoOpen == nil then
        FrostSeekDB.Settings.autoOpen = false
    end
    if FrostSeekDB.Settings.minimapButton == nil then
        FrostSeekDB.Settings.minimapButton = true
    end
    if FrostSeekDB.Settings.savePosition == nil then
        FrostSeekDB.Settings.savePosition = true
    end
    if FrostSeekDB.Settings.debugMode == nil then
        FrostSeekDB.Settings.debugMode = false
    end
end

-- ==================== SETUP DATABASE SAVE ====================
local function SetupDatabaseSave()
    local saveFrame = CreateFrame("Frame")
    saveFrame:RegisterEvent("PLAYER_LOGOUT")
    saveFrame:RegisterEvent("PLAYER_QUIT")
    saveFrame:SetScript("OnEvent", function()
        -- Forza il salvataggio prima di uscire
        if FrostSeekDB and FrostSeekDB.Settings then
            FrostSeekDB.Settings._lastSaved = time()
        end
    end)
end

-- ==================== FUNZIONE PER TROVARE KEYSTONE NELLE BORSE ====================
local function FindKeystoneInBags()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                -- In 3.3.5 controlliamo direttamente il testo del link
                if string.find(itemLink, "Keystone") or string.find(itemLink, "keystone") then
                    return itemLink
                end
            end
        end
    end
    return nil
end

-- ==================== OTTIENI IL NOME DELL'OGGETTO DAL LINK ====================
local function GetItemNameFromLink(itemLink)
    if not itemLink then return nil end
    
    -- Estrai il nome dal link dell'oggetto (formato: |cff...|Hitem:...|h[Nome Oggetto]|h|r)
    local _, _, itemName = string.find(itemLink, "|h%[(.-)%]|h")
    return itemName or "Keystone"
end

-- ==================== OTTIENI DATI GIOCATORE ====================
local function GetPlayerData()
    local classInfo = "Unknown"
    local ilvl = 0
    local enchant = ""
    local roleText = ""
    
    -- Ottieni classe
    local _, classFile = UnitClass("player")
    if classFile then
        local classMap = {
            ["WARRIOR"] = "Warrior", ["PALADIN"] = "Paladin", ["HUNTER"] = "Hunter",
            ["ROGUE"] = "Rogue", ["PRIEST"] = "Priest", ["DEATHKNIGHT"] = "Death Knight",
            ["SHAMAN"] = "Shaman", ["MAGE"] = "Mage", ["WARLOCK"] = "Warlock",
            ["DRUID"] = "Druid", ["HERO"] = "Hero"
        }
        classInfo = classMap[classFile] or classFile
    end
    
    -- Ottieni item level
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
    ilvl = count > 0 and math.floor((sum / count) + 0.5) or 0
    
    -- Ottieni enchant
    if MysticEnchantUtil then
        local enchantData = MysticEnchantUtil.GetAppliedEnchantCountByQuality("player")
        if enchantData and enchantData[5] then
            for spellID, _ in pairs(enchantData[5]) do
                local spellName = GetSpellInfo(spellID)
                if spellName then
                    enchant = "[" .. spellName .. "]"
                    break
                end
            end
        end
    end
    
    -- Ottieni ruolo
    roleText = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.myRole or ""
    
    return classInfo, ilvl, enchant, roleText
end

-- ==================== FUNZIONI UI ====================
local function CreateModernButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width)
    btn:SetHeight(height)
    
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetTexture(0.2, 0.2, 0.2, 0.9)
    
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetAllPoints()
    btn.border:SetTexture(0.4, 0.4, 0.4, 0.8)
    
    btn.hoverTex = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.hoverTex:SetAllPoints()
    btn.hoverTex:SetTexture(0.3, 0.5, 0.7, 0.4)
    btn.hoverTex:Hide()
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(1, 1, 1)
    
    btn:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        self.text:SetTextColor(0.6, 0.8, 1)
        self.border:SetTexture(0.6, 0.8, 1, 0.8)
    end)
    
    btn:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        self.text:SetTextColor(1, 1, 1)
        self.border:SetTexture(0.4, 0.4, 0.4, 0.8)
    end)
    
    return btn
end

-- ==================== FUNZIONE PER CREARE EDITBOX TRASPARENTE ====================
local function CreateCleanEditBox(parent, width, height, isMultiLine)
    local editBox = CreateFrame("EditBox", nil, parent)
    editBox:SetWidth(width)
    editBox:SetHeight(height)
    editBox:SetAutoFocus(false)
    editBox:SetTextInsets(5, 5, 2, 2)
    editBox:SetFontObject("GameFontNormal")
    
    if isMultiLine then
        editBox:SetMultiLine(true)
    end
    
    -- Rimuovi backdrop default
    editBox:SetBackdrop(nil)
    
    -- Nascondi texture default
    for i = 1, #editBox:GetRegions() do
        local region = select(i, editBox:GetRegions())
        if region and region:GetObjectType() == "Texture" then
            region:SetTexture(nil)
            region:Hide()
        end
    end
    
    -- Sfondo trasparente
    local bg = editBox:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(0.05, 0.05, 0.05, 0.15)
    bg:SetAllPoints()
    
    -- Bordo leggero
    local border = editBox:CreateTexture(nil, "BORDER")
    border:SetTexture(0.3, 0.3, 0.3, 0.2)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    
    return editBox
end

-- ==================== FUNZIONE PER CREARE CHECKBOX MODERNO ====================
local function CreateModernCheckbox(parent, text, x, y)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(200)
    frame:SetHeight(25)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    
    -- Checkbox button
    local checkbox = CreateFrame("Button", nil, frame)
    checkbox:SetWidth(20)
    checkbox:SetHeight(20)
    checkbox:SetPoint("LEFT", frame, "LEFT", 0, 0)
    
    -- Background
    checkbox.bg = checkbox:CreateTexture(nil, "BACKGROUND")
    checkbox.bg:SetAllPoints()
    checkbox.bg:SetTexture(0.1, 0.1, 0.1, 0.5)
    
    -- Border
    checkbox.border = checkbox:CreateTexture(nil, "BORDER")
    checkbox.border:SetAllPoints()
    checkbox.border:SetTexture(0.4, 0.4, 0.4, 0.8)
    
    -- Check mark
    checkbox.check = checkbox:CreateTexture(nil, "OVERLAY")
    checkbox.check:SetWidth(14)
    checkbox.check:SetHeight(14)
    checkbox.check:SetPoint("CENTER")
    checkbox.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkbox.check:SetVertexColor(0.2, 0.8, 1, 1)
    checkbox.check:Hide()
    
    -- Highlight
    checkbox.highlight = checkbox:CreateTexture(nil, "HIGHLIGHT")
    checkbox.highlight:SetAllPoints()
    checkbox.highlight:SetTexture(0.2, 0.3, 0.4, 0.5)
    checkbox.highlight:Hide()
    
    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
    label:SetText(text)
    label:SetTextColor(1, 1, 1)
    
    -- Scripts
    checkbox:SetScript("OnEnter", function(self)
        self.highlight:Show()
        self.border:SetTexture(0.6, 0.8, 1, 1)
    end)
    
    checkbox:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        self.border:SetTexture(0.4, 0.4, 0.4, 0.8)
    end)
    
    checkbox:SetScript("OnClick", function(self)
        self.checked = not self.checked
        if self.checked then
            self.check:Show()
        else
            self.check:Hide()
        end
    end)
    
    checkbox.checked = false
    frame.checkbox = checkbox
    frame.label = label
    
    return frame
end

-- ==================== FUNZIONE PER CREARE BOTTONI STILE ====================
local function CreateStyledButton(parent, text, x, y, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetWidth(width or 75)
    btn:SetHeight(height or 22)
    
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetTexture(0.1, 0.1, 0.12, 0.3)
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(0.8, 0.8, 0.8)
    
    btn:SetScript("OnEnter", function(self)
        self.bg:SetTexture(0.2, 0.3, 0.4, 0.5)
        self.text:SetTextColor(1, 1, 1)
    end)
    
    btn:SetScript("OnLeave", function(self)
        self.bg:SetTexture(0.1, 0.1, 0.12, 0.3)
        self.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    
    return btn
end

-- ==================== FUNZIONE CHECKBOX ====================
local function CreateModernCheckboxOld(parent)
    local checkbox = CreateFrame("Button", nil, parent)
    checkbox:SetSize(24, 24)
    
    local bg = checkbox:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 1)
    checkbox.bg = bg  
    
    local border = checkbox:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(0.4, 0.4, 0.4, 1)
    checkbox.border = border
    
    local check = checkbox:CreateTexture(nil, "OVERLAY")
    check:SetSize(16, 16)
    check:SetPoint("CENTER")
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetVertexColor(0.2, 0.8, 1, 1)
    checkbox.check = check
    
    local highlight = checkbox:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.3, 0.5, 0.7, 0.3)
    highlight:Hide()
    checkbox.highlight = highlight
    
    checkbox.checked = false
    
    checkbox:SetScript("OnEnter", function(self)
        self.highlight:Show()
        self.border:SetColorTexture(0.6, 0.8, 1, 1)
    end)
    
    checkbox:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        self.border:SetColorTexture(0.4, 0.4, 0.4, 1)
    end)
    
    check:Hide()
    
    return checkbox
end

-- ==================== UPDATE PREVIEW PER CUSTOM MESSAGE ====================
local function UpdateCustomPreview(previewText, templateBox, checkboxes)
    if not previewText then return end
    
    -- Ottieni dati giocatore
    local classInfo, ilvl, enchant, roleText = GetPlayerData()
    
    -- Assicurati che la struttura dati esista
    if not FrostSeekDB.LFG.customMessages then
        FrostSeekDB.LFG.customMessages = {
            enabled = false,
            template = "hello {class} {ilvl} {ench} dps or healer {keystone}",
            showClass = true,
            showIlvl = true,
            showEnchant = true,
            showRole = true,
            showKeystone = false,
            keystoneLink = ""
        }
    end
    
    local customMessages = FrostSeekDB.LFG.customMessages
    
    if customMessages and customMessages.enabled then
        local template = customMessages.template or "hello {class} {ilvl} {ench} dps or healer {keystone}"
        
        -- Sostituisci le variabili
        local message = template
        
        -- Classe
        if customMessages.showClass then
            message = string.gsub(message, "{class}", classInfo)
        else
            message = string.gsub(message, "{class}", "")
        end
        
        -- Item Level
        if customMessages.showIlvl then
            message = string.gsub(message, "{ilvl}", tostring(ilvl))
        else
            message = string.gsub(message, "{ilvl}", "")
        end
        
        -- Enchant
        if customMessages.showEnchant then
            message = string.gsub(message, "{ench}", enchant)
        else
            message = string.gsub(message, "{ench}", "")
        end
        
        -- Role
        if customMessages.showRole then
            message = string.gsub(message, "{role}", roleText)
        else
            message = string.gsub(message, "{role}", "")
        end
        
        -- Keystone
        if customMessages.showKeystone then
            local keystoneLink = FindKeystoneInBags()
            if keystoneLink then
                local keystoneName = GetItemNameFromLink(keystoneLink) or "Keystone"
                local keystoneText = "[" .. keystoneName .. "]"
                message = string.gsub(message, "{keystone}", keystoneText)
                customMessages.keystoneLink = keystoneLink
            else
                message = string.gsub(message, "{keystone}", "[No Keystone]")
            end
        else
            message = string.gsub(message, "{keystone}", "")
        end
        
        -- Pulizia spazi multipli e trim
        message = string.gsub(message, "%s+", " ")
        message = string.gsub(message, "^%s*(.-)%s*$", "%1")
        
        if message == "" then
            message = "No content selected"
        end
        
        previewText:SetText(message)
        previewText:SetTextColor(0.6, 0.8, 1)
    else
        previewText:SetText("Custom messages disabled - Enable the checkbox above")
        previewText:SetTextColor(0.8, 0.8, 0.8)
    end
end

-- ==================== FUNZIONE PER FORZARE L'AGGIORNAMENTO DELLA PREVIEW ====================
local function ForcePreviewUpdate()
    if settingsWindow and settingsWindow:IsShown() and currentCategory == "custommessage" then
        local customFrame = categoryFrames["custommessage"]
        if customFrame and customFrame.previewText then
            UpdateCustomPreview(customFrame.previewText, customFrame.templateBox, customFrame.checkboxes)
        end
    end
end

-- ==================== SETUP EVENTI PER AGGIORNAMENTO AUTOMATICO ====================
local function SetupPreviewEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("BAG_UPDATE")
    eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
    eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    
    eventFrame:SetScript("OnEvent", function()
        ForcePreviewUpdate()
    end)
end

-- ==================== START KEYSTONE AUTO UPDATE ====================
local function StartKeystoneAutoUpdate(previewText, templateBox, checkboxes)
    if keystoneUpdateTicker then
        keystoneUpdateTicker:Cancel()
        keystoneUpdateTicker = nil
    end
    
    -- Aggiornamento ogni 2 secondi per maggiore reattività
    keystoneUpdateTicker = C_Timer.NewTicker(2, function()
        if settingsWindow and settingsWindow:IsShown() and currentCategory == "custommessage" then
            if FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.customMessages then
                if previewText then
                    UpdateCustomPreview(previewText, templateBox, checkboxes)
                end
            end
        end
    end)
end

-- ==================== STOP KEYSTONE AUTO UPDATE ====================
local function StopKeystoneAutoUpdate()
    if keystoneUpdateTicker then
        keystoneUpdateTicker:Cancel()
        keystoneUpdateTicker = nil
    end
end

-- ==================== CREATE CUSTOM MESSAGE TAB ====================
local function CreateCustomMessageTab(parent, scrollContent)
    local frame = CreateFrame("Frame", nil, scrollContent)
    frame:SetSize(500, 800)
    frame:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, 0)
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Custom Whisper Messages")
    title:SetTextColor(0.6, 0.8, 1)
    
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
    desc:SetText("Customize the message sent when you click Accept in LFG")
    desc:SetTextColor(0.7, 0.7, 0.7)
    
    local yOffset = -50
    
    -- ===== ENABLE CHECKBOX MODERNO =====
    local enableFrame = CreateModernCheckbox(frame, "Enable Custom Messages", 20, yOffset)
    local enableCheck = enableFrame.checkbox
    enableCheck.checked = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.enabled or false
    if enableCheck.checked then
        enableCheck.check:Show()
    end
    
    enableCheck:SetScript("OnClick", function(self)
        self.checked = not self.checked
        if self.checked then
            self.check:Show()
        else
            self.check:Hide()
        end
        FrostSeekDB.LFG.customMessages.enabled = self.checked
        UpdateCustomPreview(previewText, templateBox, checkboxes)
    end)
    
    yOffset = yOffset - 40
    
    -- ===== MESSAGE TEMPLATE =====
    local templateLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    templateLabel:SetPoint("TOPLEFT", 20, yOffset)
    templateLabel:SetText("Message Template:")
    templateLabel:SetTextColor(0.8, 0.8, 0.8)
    
    yOffset = yOffset - 25
    
    local templateBox = CreateCleanEditBox(frame, 460, 60, true)
    templateBox:SetPoint("TOPLEFT", 20, yOffset)
    templateBox:SetText(FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.template or "hello {class} {ilvl} {ench} dps or healer {keystone}")
    
    templateBox:SetScript("OnTextChanged", function(self)
        FrostSeekDB.LFG.customMessages.template = self:GetText()
        UpdateCustomPreview(previewText, templateBox, checkboxes)
    end)
    
    yOffset = yOffset - 70
    
    -- ===== VARIABLE BUTTONS =====
    local varsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    varsLabel:SetPoint("TOPLEFT", 20, yOffset)
    varsLabel:SetText("Insert Variable:")
    varsLabel:SetTextColor(0.8, 0.8, 0.8)
    
    yOffset = yOffset - 25
    
    local variables = {
        { name = "class", display = "{class}" },
        { name = "ilvl", display = "{ilvl}" },
        { name = "ench", display = "{ench}" },
        { name = "role", display = "{role}" },
        { name = "keystone", display = "{keystone}" },
    }
    
    local function InsertVariable(varName)
        local currentText = templateBox:GetText() or ""
        if currentText ~= "" and not string.find(currentText, " $") then
            currentText = currentText .. " "
        end
        local newText = currentText .. "{" .. varName .. "}"
        templateBox:SetText(newText)
        templateBox:SetCursorPosition(string.len(newText))
        FrostSeekDB.LFG.customMessages.template = newText
        UpdateCustomPreview(previewText, templateBox, checkboxes)
    end
    
    for i, var in ipairs(variables) do
        local btn = CreateStyledButton(frame, var.display, 20 + ((i-1) * 80), yOffset, 75, 22)
        
        btn:SetScript("OnClick", function()
            InsertVariable(var.name)
        end)
        
        btn:SetScript("OnEnter", function(self)
            self.bg:SetTexture(0.2, 0.3, 0.4, 0.5)
            self.text:SetTextColor(1, 1, 1)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(var.display, 1, 1, 1)
            GameTooltip:AddLine("Click to insert", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function(self)
            self.bg:SetTexture(0.1, 0.1, 0.12, 0.3)
            self.text:SetTextColor(0.8, 0.8, 0.8)
            GameTooltip:Hide()
        end)
    end
    
    yOffset = yOffset - 35
    
    -- ===== COMPONENTS CHECKBOXES =====
    local componentsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    componentsLabel:SetPoint("TOPLEFT", 20, yOffset)
    componentsLabel:SetText("Include in message:")
    componentsLabel:SetTextColor(0.8, 0.8, 0.8)
    
    yOffset = yOffset - 30
    
    -- Riga 1
    local classFrame = CreateModernCheckbox(frame, "Class", 30, yOffset)
    classFrame.checkbox.checked = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.showClass or true
    if classFrame.checkbox.checked then
        classFrame.checkbox.check:Show()
    end
    classFrame.checkbox:SetScript("OnClick", function(self)
        self.checked = not self.checked
        if self.checked then
            self.check:Show()
        else
            self.check:Hide()
        end
        FrostSeekDB.LFG.customMessages.showClass = self.checked
        UpdateCustomPreview(previewText, templateBox, checkboxes)
    end)
    
    local ilvlFrame = CreateModernCheckbox(frame, "Item Level", 150, yOffset)
    ilvlFrame.checkbox.checked = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.showIlvl or true
    if ilvlFrame.checkbox.checked then
        ilvlFrame.checkbox.check:Show()
    end
    ilvlFrame.checkbox:SetScript("OnClick", function(self)
        self.checked = not self.checked
        if self.checked then
            self.check:Show()
        else
            self.check:Hide()
        end
        FrostSeekDB.LFG.customMessages.showIlvl = self.checked
        UpdateCustomPreview(previewText, templateBox, checkboxes)
    end)
    
    local enchantFrame = CreateModernCheckbox(frame, "Enchant", 270, yOffset)
    enchantFrame.checkbox.checked = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.showEnchant or true
    if enchantFrame.checkbox.checked then
        enchantFrame.checkbox.check:Show()
    end
    enchantFrame.checkbox:SetScript("OnClick", function(self)
        self.checked = not self.checked
        if self.checked then
            self.check:Show()
        else
            self.check:Hide()
        end
        FrostSeekDB.LFG.customMessages.showEnchant = self.checked
        UpdateCustomPreview(previewText, templateBox, checkboxes)
    end)
    
    yOffset = yOffset - 30
    
    -- Riga 2
    local roleFrame = CreateModernCheckbox(frame, "Role", 30, yOffset)
    roleFrame.checkbox.checked = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.showRole or true
    if roleFrame.checkbox.checked then
        roleFrame.checkbox.check:Show()
    end
    roleFrame.checkbox:SetScript("OnClick", function(self)
        self.checked = not self.checked
        if self.checked then
            self.check:Show()
        else
            self.check:Hide()
        end
        FrostSeekDB.LFG.customMessages.showRole = self.checked
        UpdateCustomPreview(previewText, templateBox, checkboxes)
    end)
    
    local keystoneFrame = CreateModernCheckbox(frame, "Keystone (auto)", 150, yOffset)
    keystoneFrame.checkbox.checked = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.showKeystone or false
    if keystoneFrame.checkbox.checked then
        keystoneFrame.checkbox.check:Show()
    end
    keystoneFrame.checkbox:SetScript("OnClick", function(self)
        self.checked = not self.checked
        if self.checked then
            self.check:Show()
        else
            self.check:Hide()
        end
        FrostSeekDB.LFG.customMessages.showKeystone = self.checked
        UpdateCustomPreview(previewText, templateBox, checkboxes)
    end)
    
    yOffset = yOffset - 50
    
    -- ===== PREVIEW =====
    local previewLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewLabel:SetPoint("TOPLEFT", 20, yOffset)
    previewLabel:SetText("Preview:")
    previewLabel:SetTextColor(0.8, 0.8, 0.8)
    
    yOffset = yOffset - 25
    
    local previewFrame = CreateFrame("Frame", nil, frame)
    previewFrame:SetPoint("TOPLEFT", 20, yOffset)
    previewFrame:SetSize(460, 60)
    
    local previewBg = previewFrame:CreateTexture(nil, "BACKGROUND")
    previewBg:SetAllPoints()
    previewBg:SetTexture(0.08, 0.08, 0.1, 0.2)
    
    local previewText = previewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewText:SetPoint("TOPLEFT", 10, -8)
    previewText:SetPoint("RIGHT", previewFrame, "RIGHT", -10, 0)
    previewText:SetPoint("BOTTOM", previewFrame, "BOTTOM", 0, -10)
    previewText:SetJustifyH("LEFT")
    previewText:SetJustifyV("TOP")
    
    yOffset = yOffset - 75
    
    -- ===== RESET BUTTON =====
    local resetBtn = CreateModernButton(frame, "Reset to Default", 150, 30)
    resetBtn:SetPoint("TOPLEFT", 20, yOffset)
    
    resetBtn:SetScript("OnClick", function()
        FrostSeekDB.LFG.customMessages.template = "hello {class} {ilvl} {ench} dps or healer {keystone}"
        templateBox:SetText(FrostSeekDB.LFG.customMessages.template)
        
        FrostSeekDB.LFG.customMessages.showClass = true
        FrostSeekDB.LFG.customMessages.showIlvl = true
        FrostSeekDB.LFG.customMessages.showEnchant = true
        FrostSeekDB.LFG.customMessages.showRole = true
        FrostSeekDB.LFG.customMessages.showKeystone = false
        
        -- Reset checkbox stati
        classFrame.checkbox.checked = true
        classFrame.checkbox.check:Show()
        ilvlFrame.checkbox.checked = true
        ilvlFrame.checkbox.check:Show()
        enchantFrame.checkbox.checked = true
        enchantFrame.checkbox.check:Show()
        roleFrame.checkbox.checked = true
        roleFrame.checkbox.check:Show()
        keystoneFrame.checkbox.checked = false
        keystoneFrame.checkbox.check:Hide()
        
        UpdateCustomPreview(previewText, templateBox, checkboxes)
    end)
    
    -- Inizializza preview
    local checkboxes = {
        class = classFrame.checkbox,
        ilvl = ilvlFrame.checkbox,
        enchant = enchantFrame.checkbox,
        role = roleFrame.checkbox,
        keystone = keystoneFrame.checkbox
    }
    UpdateCustomPreview(previewText, templateBox, checkboxes)
    
    -- Salva riferimenti per l'auto-update
    frame.previewText = previewText
    frame.templateBox = templateBox
    frame.checkboxes = checkboxes
    frame.enableCheck = enableCheck
    
    return frame
end

-- ==================== SETTINGS STRUCTURE ====================
local SETTINGS_CATEGORIES = {
    {
        id = "general",
        name = "General",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        settings = {
            {
                type = "header",
                id = "generalHeader",
                name = "",
                desc = "Basic addon configuration"
            },
            {
                type = "checkbox",
                id = "autoOpen",
                name = "Auto-Open on Login",
                desc = "Automatically open FrostSeek window when you log in",
                default = false,
                getter = function() 
                    EnsureSettingsStructure()
                    return FrostSeekDB.Settings.autoOpen or false 
                end,
                setter = function(value) 
                    EnsureSettingsStructure()
                    FrostSeekDB.Settings.autoOpen = value 
                    print("|cff88ccffFrostSeek:|r Auto-open " .. (value and "enabled" or "disabled"))
                end
            },
            {
                type = "checkbox",
                id = "minimapButton",
                name = "Show Minimap Button",
                desc = "Show the FrostSeek minimap button",
                default = true,
                getter = function() 
                    EnsureSettingsStructure()
                    return FrostSeekDB.Settings.minimapButton 
                end,
                setter = function(value) 
                    EnsureSettingsStructure()
                    FrostSeekDB.Settings.minimapButton = value 
                    local miniButton = _G["FrostSeekMiniMapButton"]
                    if miniButton then
                        if value then miniButton:Show() else miniButton:Hide() end
                    end
                end
            },
            {
                type = "checkbox",
                id = "savePosition",
                name = "Save Window Position",
                desc = "Remember window positions between sessions",
                default = true,
                getter = function() 
                    EnsureSettingsStructure()
                    return FrostSeekDB.Settings.savePosition or true 
                end,
                setter = function(value) 
                    EnsureSettingsStructure()
                    FrostSeekDB.Settings.savePosition = value 
                end
            },
            {
                type = "checkbox",
                id = "debugMode",
                name = "Debug Mode",
                desc = "Enable debug messages in chat",
                default = false,
                getter = function() 
                    EnsureSettingsStructure()
                    return FrostSeekDB.Settings.debugMode or false 
                end,
                setter = function(value) 
                    EnsureSettingsStructure()
                    FrostSeekDB.Settings.debugMode = value 
                end
            },
            {
                type = "slider",
                id = "uiScale",
                name = "UI Scale",
                desc = "Adjust the scale of the FrostSeek interface (0.5 - 1.5)",
                min = 0.5,
                max = 1.5,
                step = 0.05,
                default = 1.0,
                getter = function() 
                    EnsureSettingsStructure()
                    -- Assicurati che il valore esista nel DB
                    if FrostSeekDB.Settings.uiScale == nil then
                        FrostSeekDB.Settings.uiScale = 1.0
                    end
                    return FrostSeekDB.Settings.uiScale
                end,
                setter = function(value) 
                    EnsureSettingsStructure()
                    -- Salva esplicitamente nel DB
                    FrostSeekDB.Settings.uiScale = value
                    print("|cff88ccffFrostSeek:|r UI Scale saved: " .. value) -- Debug
                    if FrostSeek.MainFrame then
                        FrostSeek.MainFrame:SetScale(value)
                    end
                end
            }
        }
    },
    
    {
        id = "lfg",
        name = "LFG System",
        icon = "Interface\\Icons\\Ability_DualWield",
        settings = {
            {
                type = "header",
                id = "lfgHeader",
                name = "",
                desc = "Configure the Looking For Group radar"
            },
            {
                type = "checkbox",
                id = "disableLFG",
                name = "Disable LFG System",
                desc = "Completely disable the LFG radar",
                default = false,
                getter = function() return FrostSeekDB.LFG.disableLFG or false end,
                setter = function(value) FrostSeekDB.LFG.disableLFG = value end
            },
            {
                type = "checkbox",
                id = "disablePopups",
                name = "Disable Popups",
                desc = "Disable LFM alert popups",
                default = false,
                getter = function() return FrostSeekDB.LFG.disablePopups or false end,
                setter = function(value) FrostSeekDB.LFG.disablePopups = value end
            },
            {
                type = "checkbox",
                id = "silentNotifications",
                name = "Silent Notifications",
                desc = "Disable sound for LFG notifications",
                default = false,
                getter = function() return FrostSeekDB.LFG.silentNotifications or false end,
                setter = function(value) FrostSeekDB.LFG.silentNotifications = value end
            },
            {
                type = "checkbox",
                id = "doNotAlertInGroup",
                name = "No Alerts in Group",
                desc = "Don't show alerts when in a group",
                default = true,
                getter = function() return FrostSeekDB.LFG.doNotAlertInGroup or true end,
                setter = function(value) FrostSeekDB.LFG.doNotAlertInGroup = value end
            },
            {
                type = "checkbox",
                id = "doNotAlertInCombat",
                name = "No Alerts in Combat",
                desc = "Don't show alerts when in combat",
                default = true,
                getter = function() return FrostSeekDB.LFG.doNotAlertInCombat or true end,
                setter = function(value) FrostSeekDB.LFG.doNotAlertInCombat = value end
            },
            {
                type = "slider",
                id = "frameDuration",
                name = "Popup Duration",
                desc = "How long popups stay visible (seconds)",
                min = 2,
                max = 10,
                step = 1,
                default = 5,
                getter = function() return FrostSeekDB.LFG.frameDuration or 5 end,
                setter = function(value) FrostSeekDB.LFG.frameDuration = value end
            },
            {
                type = "slider",
                id = "popupCooldown",
                name = "Popup Cooldown",
                desc = "Time between identical popups (seconds)",
                min = 60,
                max = 600,
                step = 10,
                default = 370,
                getter = function() return FrostSeekDB.LFG.popupCooldown or 370 end,
                setter = function(value) FrostSeekDB.LFG.popupCooldown = value end
            },
            {
                type = "slider",
                id = "maxConcurrentPopups",
                name = "Max Popups",
                desc = "Maximum number of popups shown at once",
                min = 1,
                max = 5,
                step = 1,
                default = 2,
                getter = function() return FrostSeekDB.LFG.maxConcurrentPopups or 2 end,
                setter = function(value) FrostSeekDB.LFG.maxConcurrentPopups = value end
            }
        }
    },
    
    {
        id = "custommessage",
        name = "Custom Message",
        icon = "Interface\\Icons\\INV_Misc_Note_01",
        settings = {} -- Vuoto perché usiamo una tab personalizzata
    },
    
    {
        id = "lfm",
        name = "LFM System",
        icon = "Interface\\Icons\\Ability_Creature_Cursed_02",
        settings = {
            {
                type = "header",
                id = "lfmHeader",
                name = "",
                desc = "Configure the Looking For Members system"
            },
            {
                type = "slider",
                id = "autoUpdateInterval",
                name = "Auto-update Interval",
                desc = "Seconds between keystone list updates (0 = disable)",
                min = 0,
                max = 300,
                step = 10,
                default = 60,
                getter = function() return FrostSeekDB.LFM.autoUpdateInterval or 60 end,
                setter = function(value) 
                    FrostSeekDB.LFM.autoUpdateInterval = value
                    if FrostSeek.Modules and FrostSeek.Modules.lfm then
                        local lfmModule = FrostSeek.Modules.lfm
                        if lfmModule.UpdateAutoUpdateInterval then
                            lfmModule:UpdateAutoUpdateInterval()
                        end
                    end
                end
            }
        }
    },
    
    {
        id = "advanced",
        name = "Advanced",
        icon = "Interface\\Icons\\INV_Misc_EngGizmos_01",
        settings = {
            {
                type = "header",
                id = "advancedHeader",
                name = "",
                desc = "Advanced configuration options"
            },
            {
                type = "button",
                id = "resetPosition",
                name = "Reset Window Position",
                desc = "Reset all windows to default positions",
                onClick = function()
                    FrostSeekDB.Settings.windowPosition = nil
                    FrostSeekDB.LFG.activeWindowPosition = nil
                    if FrostSeek.MainFrame then
                        FrostSeek.MainFrame:ClearAllPoints()
                        FrostSeek.MainFrame:SetPoint("CENTER")
                    end
                    print("|cff88ccffFrostSeek:|r Window positions reset")
                end
            },
            {
                type = "button",
                id = "clearAllData",
                name = "Clear All Data",
                desc = "Clear all saved data (LFG, LFM, settings)",
                warning = "This cannot be undone!",
                onClick = function()
                    StaticPopup_Show("FROSTSEEK_CONFIRM_CLEAR_DATA")
                end
            }
        }
    }
}

-- ==================== SETTING CONTROL CREATION ====================
local function CreateSettingControl(parent, setting, yOffset)
    if setting.id == "debugMode" and FrostSeekDB and FrostSeekDB.Settings and not FrostSeekDB.Settings.debugMode then
        return nil, 0
    end
    
    local controlFrame = CreateFrame("Frame", nil, parent)
    controlFrame:SetSize(500, 50)
    controlFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    
    local nameLabel = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", controlFrame, "LEFT", 0, 0)
    nameLabel:SetText(setting.name or "")
    nameLabel:SetTextColor(1, 1, 1)
    
    controlFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(setting.name or "", 1, 1, 1)
        GameTooltip:AddLine(setting.desc or "", 0.8, 0.8, 0.8, true)
        if setting.warning then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Warning: " .. setting.warning, 1, 0.2, 0.2, true)
        end
        GameTooltip:Show()
    end)
    
    controlFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    if setting.type == "checkbox" then
        local checkbox = CreateModernCheckboxOld(controlFrame)
        checkbox:SetPoint("RIGHT", controlFrame, "RIGHT", -10, 0)
        
        nameLabel:ClearAllPoints()
        nameLabel:SetPoint("LEFT", controlFrame, "LEFT", 0, 0)
        nameLabel:SetPoint("RIGHT", checkbox, "LEFT", -5, 0)
        nameLabel:SetJustifyH("LEFT")
        nameLabel:SetWordWrap(false)
        
        local function UpdateCheckboxFromDB()
            local value = false
            if setting.getter then
                value = setting.getter() or false
            elseif setting.id and FrostSeekDB and FrostSeekDB.Settings then
                value = FrostSeekDB.Settings[setting.id]
                if value == nil then
                    value = setting.default or false
                end
            end
            checkbox.checked = value
            if value then
                checkbox.check:Show()
            else
                checkbox.check:Hide()
            end
        end
        
        UpdateCheckboxFromDB()
        
        checkbox:SetScript("OnClick", function(self)
            self.checked = not self.checked
            if self.checked then
                self.check:Show()
            else
                self.check:Hide()
            end
            
            if setting.setter then
                setting.setter(self.checked)
            elseif setting.id and FrostSeekDB and FrostSeekDB.Settings then
                FrostSeekDB.Settings[setting.id] = self.checked
            end
            
            if setting.id == "autoOpen" then
                if self.checked then
                    print("|cff88ccffFrostSeek:|r Auto-open will be enabled next login")
                else
                    print("|cff88ccffFrostSeek:|r Auto-open disabled")
                end
            end
        end)
        
        checkbox.UpdateFromDB = UpdateCheckboxFromDB
        
        return controlFrame, -40, checkbox

    elseif setting.type == "slider" then
        local valueText = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        valueText:SetPoint("RIGHT", controlFrame, "RIGHT", -40, 0)
        valueText:SetTextColor(0.6, 0.8, 1)
        
        local slider = CreateFrame("Slider", nil, controlFrame)
        slider:SetPoint("RIGHT", controlFrame, "RIGHT", -80, 0)
        slider:SetSize(150, 15)
        slider:SetMinMaxValues(setting.min or 0, setting.max or 100)
        slider:SetValueStep(setting.step or 1)
        slider:SetOrientation("HORIZONTAL")
        slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        
        local background = slider:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        local function UpdateSliderFromDB()
            local currentValue = setting.default or 1
            if setting.getter then
                currentValue = setting.getter() or currentValue
            elseif setting.id and FrostSeekDB and FrostSeekDB.Settings then
                currentValue = FrostSeekDB.Settings[setting.id] or setting.default or 1
            end
            valueText:SetText(string.format("%.2f", currentValue))
            slider:SetValue(currentValue)
        end
        
        UpdateSliderFromDB()
        
        slider:SetScript("OnValueChanged", function(self, value)
            local step = setting.step or 1
            local roundedValue = math.floor(value / step + 0.5) * step
            self:SetValue(roundedValue)
            valueText:SetText(string.format("%.2f", roundedValue))
            
            if setting.setter then
                setting.setter(roundedValue)
            elseif setting.id and FrostSeekDB and FrostSeekDB.Settings then
                FrostSeekDB.Settings[setting.id] = roundedValue
            end
        end)
        
        slider.UpdateFromDB = UpdateSliderFromDB
        
        return controlFrame, -50, slider
    
    elseif setting.type == "editbox" then
        local editBox = CreateFrame("EditBox", nil, controlFrame, "InputBoxTemplate")
        editBox:SetPoint("RIGHT", controlFrame, "RIGHT", 0, 0)
        editBox:SetSize(setting.width or 200, 20)
        editBox:SetAutoFocus(false)
        
        local function UpdateEditBoxFromDB()
            local currentText = ""
            if setting.getter then
                currentText = setting.getter() or ""
            elseif setting.id and FrostSeekDB and FrostSeekDB.Settings then
                currentText = FrostSeekDB.Settings[setting.id] or ""
            end
            editBox:SetText(currentText)
        end
        
        UpdateEditBoxFromDB()
        
        editBox:SetScript("OnTextChanged", function(self)
            if setting.setter then
                setting.setter(self:GetText())
            elseif setting.id and FrostSeekDB and FrostSeekDB.Settings then
                FrostSeekDB.Settings[setting.id] = self:GetText()
            end
        end)
        
        editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
        
        editBox:SetScript("OnEscapePressed", function(self)
            UpdateEditBoxFromDB()
            self:ClearFocus()
        end)
        
        editBox.UpdateFromDB = UpdateEditBoxFromDB
        
        return controlFrame, -50, editBox
    
    elseif setting.type == "category" then
        local categoriesFrame = CreateFrame("Frame", nil, parent)
        categoriesFrame:SetSize(540, 200)
        categoriesFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset - 20)
        
        local title = categoriesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", categoriesFrame, "TOPLEFT", 0, 0)
        title:SetText(setting.name or "")
        title:SetTextColor(1, 1, 1)
        
        local catYOffset = -30
        local checkboxes = {}
        
        for i, category in ipairs(setting.categories or {}) do
            local catFrame = CreateFrame("Frame", nil, categoriesFrame)
            catFrame:SetSize(540, 30)
            catFrame:SetPoint("TOPLEFT", categoriesFrame, "TOPLEFT", 20, catYOffset)
            
            local checkbox = CreateModernCheckboxOld(catFrame)
            checkbox:SetPoint("LEFT", catFrame, "LEFT", 0, 0)
            
            local label = catFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
            label:SetText(category.name or "")
            label:SetTextColor(0.8, 0.8, 0.8)
            
            local function UpdateCategoryFromDB()
                local isChecked = false
                if setting.getter then
                    isChecked = setting.getter(category.id) or false
                end
                checkbox.checked = isChecked
                if isChecked then
                    checkbox.check:Show()
                else
                    checkbox.check:Hide()
                end
            end
            
            UpdateCategoryFromDB()
            
            checkbox:SetScript("OnClick", function(self)
                if self.checked then
                    self.checked = false
                    self.check:Hide()
                else
                    self.checked = true
                    self.check:Show()
                end
                
                if setting.setter then
                    setting.setter(category.id, self.checked)
                    
                    if category.id == "ALL" and self.checked then
                        for j, otherCat in ipairs(setting.categories or {}) do
                            if otherCat.id ~= "ALL" then
                                setting.setter(otherCat.id, false)
                            end
                        end
                        for _, cb in ipairs(checkboxes) do
                            if cb.categoryId ~= "ALL" then
                                cb.checked = false
                                cb.check:Hide()
                            end
                        end
                    elseif category.id ~= "ALL" and self.checked then
                        setting.setter("ALL", false)
                        for _, cb in ipairs(checkboxes) do
                            if cb.categoryId == "ALL" then
                                cb.checked = false
                                cb.check:Hide()
                            end
                        end
                    end
                end
            end)
            
            checkbox.categoryId = category.id
            checkbox.UpdateFromDB = UpdateCategoryFromDB
            table.insert(checkboxes, checkbox)
            
            catFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(category.name or "", 1, 1, 1)
                GameTooltip:AddLine(category.desc or "", 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
            
            catFrame:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            
            catYOffset = catYOffset - 32
        end
        
        return categoriesFrame, catYOffset - 20, checkboxes
    
    elseif setting.type == "button" then
        local button = CreateModernButton(controlFrame, setting.name or "", 180, 25)
        button:SetPoint("RIGHT", controlFrame, "RIGHT", 0, 0)
        button:SetScript("OnClick", function()
            if setting.onClick then
                setting.onClick()
            end
        end)
        return controlFrame, -45, button
    
    elseif setting.type == "header" then
        local headerFrame = CreateFrame("Frame", nil, parent)
        headerFrame:SetSize(540, 40)
        headerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
        
        local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerText:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
        headerText:SetText(setting.name or "")
        headerText:SetTextColor(0.6, 0.8, 1)
        
        local headerDesc = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        headerDesc:SetPoint("TOPLEFT", headerText, "BOTTOMLEFT", 0, -5)
        headerDesc:SetText(setting.desc or "")
        headerDesc:SetTextColor(0.7, 0.7, 0.7)
        
        return headerFrame, -60
    end
    
    return controlFrame, -40
end

-- ==================== FUNZIONE PER AGGIORNARE TUTTI I CONTROLLI ====================
local function RefreshAllControls()
    if not settingsWindow or not settingsWindow.controls then return end
    
    for _, control in ipairs(settingsWindow.controls) do
        if control and control.UpdateFromDB then
            control.UpdateFromDB()
        end
    end
end

-- ==================== OPTIONS WINDOW ====================
function CreateOptionsWindow()
    EnsureSettingsStructure()
    SetupDatabaseSave()
    
    if settingsWindow then
        RefreshAllControls()
        settingsWindow:Show()
        return
    end
    
    settingsWindow = CreateFrame("Frame", "FrostSeekOptionsWindow", UIParent, "BackdropTemplate")
    settingsWindow:SetSize(800, 700)
    settingsWindow:SetPoint("CENTER")
    settingsWindow:SetFrameStrata("DIALOG")
    
    settingsWindow:EnableMouse(true)
    settingsWindow:SetMovable(true)
    settingsWindow:RegisterForDrag("LeftButton")
    settingsWindow:SetScript("OnDragStart", function(self) self:StartMoving() end)
    settingsWindow:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    settingsWindow:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    settingsWindow:SetBackdropColor(0.1, 0.1, 0.15, 0.95)
    settingsWindow:SetBackdropBorderColor(0.4, 0.4, 0.6, 1)
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, settingsWindow)
    titleBar:SetPoint("TOPLEFT", settingsWindow, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", settingsWindow, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(35)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function(self) settingsWindow:StartMoving() end)
    titleBar:SetScript("OnDragStop", function(self) settingsWindow:StopMovingOrSizing() end)
    
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER")
    title:SetText("|cff88ccffFrostSeek Settings|r")
    
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() 
        settingsWindow:Hide()
        StopKeystoneAutoUpdate()
    end)
    
    -- Sidebar
    local sidebar = CreateFrame("Frame", nil, settingsWindow)
    sidebar:SetSize(180, 500)
    sidebar:SetPoint("TOPLEFT", settingsWindow, "TOPLEFT", 15, -50)
    
    local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
    sidebarBg:SetAllPoints()
    sidebarBg:SetTexture(0.15, 0.15, 0.2, 0.8)
    
    local sidebarTitle = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sidebarTitle:SetPoint("TOP", sidebar, "TOP", 0, -10)
    sidebarTitle:SetText("Categories")
    sidebarTitle:SetTextColor(0.8, 0.8, 0.8)
    
    local catYOffset = -40
    for i, category in ipairs(SETTINGS_CATEGORIES) do
        local btn = CreateModernButton(sidebar, category.name, 160, 32)
        btn:SetPoint("TOP", sidebar, "TOP", 0, catYOffset)
        if category.icon then
            local icon = btn:CreateTexture(nil, "OVERLAY")
            icon:SetSize(16, 16)
            icon:SetPoint("LEFT", btn, "LEFT", 10, 0)
            icon:SetTexture(category.icon)
        end
        btn:SetScript("OnClick", function() 
            SwitchSettingsCategory(category.id)
            RefreshAllControls()
            
            -- Avvia/ferma auto-update per custom message
            if category.id == "custommessage" then
                if FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.showKeystone then
                    local customFrame = categoryFrames["custommessage"]
                    if customFrame then
                        StartKeystoneAutoUpdate(customFrame.previewText, customFrame.templateBox, customFrame.checkboxes)
                    end
                end
            else
                StopKeystoneAutoUpdate()
            end
        end)
        catYOffset = catYOffset - 38
    end
    
    -- Content
    local contentFrame = CreateFrame("Frame", nil, settingsWindow)
    contentFrame:SetSize(550, 420)
    contentFrame:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 20, 0)
    
    local contentBg = contentFrame:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetTexture(0.1, 0.1, 0.15, 0.8)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -25, 10)
    
    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(500, 900)
    scrollFrame:SetScrollChild(scrollContent)
    
    settingsWindow.scrollContent = scrollContent
    settingsWindow.scrollFrame = scrollFrame
    settingsWindow.controls = {}
    
    -- Create category frames
    for _, category in ipairs(SETTINGS_CATEGORIES) do
        local frame
        if category.id == "custommessage" then
            frame = CreateCustomMessageTab(category, scrollContent)
        else
            frame = CreateFrame("Frame", nil, scrollContent)
            frame:SetSize(500, 900)
            frame:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, 0)
            
            local frameTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            frameTitle:SetPoint("TOP", frame, "TOP", 0, -15)
            frameTitle:SetText(category.name)
            frameTitle:SetTextColor(0.6, 0.8, 1)
            
            local yOffset = -50
            for _, setting in ipairs(category.settings) do
                local control, height, controlObj = CreateSettingControl(frame, setting, yOffset)
                yOffset = yOffset + (height or -45)
                
                if controlObj then
                    table.insert(settingsWindow.controls, controlObj)
                end
            end
        end
        frame:Hide()
        categoryFrames[category.id] = frame
    end
    
    -- Footer
    local footer = CreateFrame("Frame", nil, settingsWindow)
    footer:SetPoint("BOTTOMLEFT", settingsWindow, "BOTTOMLEFT", 15, 10)
    footer:SetPoint("BOTTOMRIGHT", settingsWindow, "BOTTOMRIGHT", -15, 10)
    footer:SetHeight(35)
    
    local footerText = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footerText:SetPoint("LEFT", footer, "LEFT", 0, 0)
    footerText:SetText("|cff888888FrostSeek |r")
    
    local closeButton = CreateModernButton(footer, "Close", 80, 28)
    closeButton:SetPoint("RIGHT", footer, "RIGHT", 0, 0)
    closeButton:SetScript("OnClick", function() 
        settingsWindow:Hide()
        StopKeystoneAutoUpdate()
    end)
    
    -- Setup eventi per aggiornamento automatico
    SetupPreviewEvents()
end

-- ==================== FUNZIONI DI NAVIGAZIONE ====================
function SwitchSettingsCategory(categoryId)
    currentCategory = categoryId
    for id, frame in pairs(categoryFrames) do
        if frame then
            if id == categoryId then 
                frame:Show() 
            else 
                frame:Hide() 
            end
        end
    end
    if settingsWindow and settingsWindow.scrollFrame then
        settingsWindow.scrollFrame:SetVerticalScroll(0)
    end
end

function ShowOptionsWindow()
    CreateOptionsWindow()
    if settingsWindow then
        settingsWindow:Show()
        SwitchSettingsCategory("general")
        RefreshAllControls()
    end
end

-- ==================== MODULE FUNCTIONS ====================
function Options:Initialize(parentFrame)
    EnsureSettingsStructure()
    
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)
    
    self.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.title:SetPoint("TOP", self.frame, "TOP", 0, -20)
    self.title:SetText("|cff88ccffSystem Settings|r")
    
    self.desc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.desc:SetPoint("TOP", self.title, "BOTTOM", 0, -10)
    self.desc:SetText("Configure all FrostSeek settings")
    self.desc:SetTextColor(0.8, 0.8, 0.8)
    
    -- ==================== BOTTONI PRINCIPALI ====================
    local buttonsFrame = CreateFrame("Frame", nil, self.frame)
    buttonsFrame:SetSize(760, 150)
    buttonsFrame:SetPoint("CENTER", self.frame, "CENTER", 0, -30)
    
    -- Open Settings Button
    self.openBtn = CreateModernButton(buttonsFrame, "Open Settings Window", 220, 45)
    self.openBtn:SetPoint("TOP", buttonsFrame, "TOP", 0, 0)
    self.openBtn:SetScript("OnClick", ShowOptionsWindow)
    
    -- Discord Button
    self.discordBtn = CreateModernButton(buttonsFrame, "Discord", 160, 35)
    self.discordBtn:SetPoint("TOP", self.openBtn, "BOTTOM", 0, -10)
    self.discordBtn:SetScript("OnClick", function()
        local discordLink = "https://discord.gg/T5rtyW9yX4"
        local editBox = ChatEdit_ChooseBoxForSend()
        if not editBox:IsVisible() then
            ChatEdit_ActivateChat(editBox)
        end
        editBox:SetText(discordLink)
        editBox:HighlightText()
        editBox:SetFocus()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF5865F2FrostSeek: |rDiscord link inserted in chat box!")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF5865F2FrostSeek: |rPress Ctrl+A then Ctrl+C to copy, then paste in browser")
    end)
    
    self.discordBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Discord", 0.345, 0.396, 0.949)
        GameTooltip:AddLine("Join our Discord server!", 1, 1, 1, true)
        GameTooltip:Show()
        self.hoverTex:Show()
        self.text:SetTextColor(0.345, 0.396, 0.949)
        self.border:SetColorTexture(0.345, 0.396, 0.949, 1)
    end)
    
    self.discordBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self.hoverTex:Hide()
        self.text:SetTextColor(1, 1, 1)
        self.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    end)
    
    -- CurseForge Button
    self.curseforgeBtn = CreateModernButton(buttonsFrame, "CurseForge", 160, 35)
    self.curseforgeBtn:SetPoint("TOP", self.discordBtn, "BOTTOM", 0, -10)
    self.curseforgeBtn:SetScript("OnClick", function()
        local curseforgeLink = "https://www.curseforge.com/wow/addons/frostseek"
        local editBox = ChatEdit_ChooseBoxForSend()
        if not editBox:IsVisible() then
            ChatEdit_ActivateChat(editBox)
        end
        editBox:SetText(curseforgeLink)
        editBox:HighlightText()
        editBox:SetFocus()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF4169E1FrostSeek: |rCurseForge link inserted in chat box!")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF4169E1FrostSeek: |rPress Ctrl+A then Ctrl+C to copy, then paste in browser")
    end)
    
    self.curseforgeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("CurseForge", 0.937, 0.502, 0.196)
        GameTooltip:AddLine("Download and update addons!", 1, 1, 1, true)
        GameTooltip:Show()
        self.hoverTex:Show()
        self.text:SetTextColor(0.937, 0.502, 0.196)
        self.border:SetColorTexture(0.937, 0.502, 0.196, 1)
    end)
    
    self.curseforgeBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self.hoverTex:Hide()
        self.text:SetTextColor(1, 1, 1)
        self.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    end)
    
    self.statusFrame = CreateFrame("Frame", nil, self.frame)
    self.statusFrame:SetSize(550, 80)
    self.statusFrame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 30)
    
    local statusBg = self.statusFrame:CreateTexture(nil, "BACKGROUND")
    statusBg:SetAllPoints()
    statusBg:SetTexture(0.1, 0.1, 0.1, 0.6)
    
    local statusTitle = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusTitle:SetPoint("TOP", self.statusFrame, "TOP", 0, -10)
    statusTitle:SetText("Current Status")
    statusTitle:SetTextColor(1, 1, 1)
    
    self.statusText = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.statusText:SetPoint("TOP", statusTitle, "BOTTOM", 0, -10)
    
    local lfgStatus = "|cFF00FF00Active|r"
    if FrostSeekDB.LFG and FrostSeekDB.LFG.disableLFG then
        lfgStatus = "|cFFFF0000Disabled|r"
    end
    self.statusText:SetText("LFG: " .. lfgStatus .. "  |  by AYRO")
    self.statusText:SetTextColor(0.9, 0.9, 0.9)
    
    self.frame:Hide()
end

function Options:Show()
    if self.frame then
        if self.statusText then
            local lfgStatus = "|cFF00FF00Active|r"
            if FrostSeekDB.LFG and FrostSeekDB.LFG.disableLFG then
                lfgStatus = "|cFFFF0000Disabled|r"
            end
            self.statusText:SetText("LFG: " .. lfgStatus .. "  |  by AYRO")
        end
        self.frame:Show()
    end
end

function Options:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- ==================== POPUP DIALOGS ====================
StaticPopupDialogs["FROSTSEEK_CONFIRM_CLEAR_DATA"] = {
    text = "Are you sure you want to clear ALL FrostSeek data?\n\nThis includes:\n- LFG search history\n- LFM templates\n- All settings\n- Custom message templates\n\nThis action cannot be undone!",
    button1 = "Yes, Clear All",
    button2 = "Cancel",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function()
        FrostSeekDB = {
            LFG = {
                myRole = "", silentNotifications = false, frameDuration = 5,
                dontDisplayDeclinedDuration = 300, dontDisplaySpammers = 30,
                disablePopups = false, disableLFG = false,
                filterWords = "echo,recruit,lfg,wts,buy,shop,gold,sell,account,boost,carry,guild,pve,eu,na,need,wtt,wtb,bazar,hello,player",
                maxMessageLength = 90, popupCooldown = 370, maxConcurrentPopups = 2,
                doNotAlertInGroup = true, doNotAlertInCombat = true,
                popupCategories = { ALL = true, DUNGEON = true, RAID = true, PVP = true, MANASTORM = true, KEYSTONE = true },
                customFilterWords = "", showActiveRecruitersWindow = false,
                activeWindowPosition = nil, activeWindowCategory = "ALL",
                customMessages = {
                    enabled = false,
                    template = "hello {class} {ilvl} {ench} dps or healer {keystone}",
                    showClass = true,
                    showIlvl = true,
                    showEnchant = true,
                    showRole = true,
                    showKeystone = false,
                    keystoneLink = ""
                }
            },
            LFM = { 
                lastMessages = {}, 
                favoriteTemplates = {}, 
                channelPresets = {},
                autoUpdateInterval = 60
            },
            MPlusScores = {},
            Settings = { 
                uiScale = 1.0, 
                windowPosition = nil, 
                minimapButton = true,
                debugMode = false, 
                savePosition = true,
                autoOpen = false
            }
        }
        print("|cff88ccffFrostSeek:|r All data cleared")
        ReloadUI()
    end
}

-- ==================== MODULE REGISTRATION ====================
if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("options", Options)
    print("|cff88ccffFrostSeek Options:|r Module registered")
end