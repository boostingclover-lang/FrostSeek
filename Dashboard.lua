local FrostSeek = _G.FrostSeek

local Dashboard = {}

function Dashboard:Initialize(parentFrame)
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)
    
    -- Title
    self.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.title:SetPoint("TOP", self.frame, "TOP", 0, -15)
    self.title:SetText("|cff88ccffSystem Dashboard|r")
    
    -- ===== REAL-TIME CLOCK =====
    self.clockFrame = CreateFrame("Frame", nil, self.frame)
    self.clockFrame:SetSize(250, 80)
    self.clockFrame:SetPoint("TOP", self.frame, "TOP", 0, -60)
    
    local clockBg = self.clockFrame:CreateTexture(nil, "BACKGROUND")
    clockBg:SetAllPoints()
    clockBg:SetColorTexture(0.1, 0.1, 0.1, 0.7)
    
    self.timeText = self.clockFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    self.timeText:SetPoint("TOP", self.clockFrame, "TOP", 0, -15)
    self.timeText:SetText("00:00:00")
    self.timeText:SetTextColor(0.6, 0.8, 1)
    
    self.dateText = self.clockFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.dateText:SetPoint("TOP", self.timeText, "BOTTOM", 0, -5)
    self.dateText:SetText("Loading...")
    self.dateText:SetTextColor(0.8, 0.8, 0.8)
    
    -- ===== SYSTEM STATUS =====
    self.statusFrame = CreateFrame("Frame", nil, self.frame)
    self.statusFrame:SetSize(550, 100)
    self.statusFrame:SetPoint("TOP", self.clockFrame, "BOTTOM", 0, -20)
    
    local statusBg = self.statusFrame:CreateTexture(nil, "BACKGROUND")
    statusBg:SetAllPoints()
    statusBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
    
    local statusTitle = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusTitle:SetPoint("TOP", self.statusFrame, "TOP", 0, -10)
    statusTitle:SetText("|cFFFFFF00System Status|r")
    
    -- LFG Status
    self.lfgStatusLabel = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.lfgStatusLabel:SetPoint("TOPLEFT", self.statusFrame, "TOPLEFT", 30, -40)
    self.lfgStatusLabel:SetText("LFG System:")
    self.lfgStatusLabel:SetTextColor(1, 1, 1)
    
    self.lfgStatusValue = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.lfgStatusValue:SetPoint("LEFT", self.lfgStatusLabel, "RIGHT", 10, 0)
    self.lfgStatusValue:SetText("|cFF00FF00Active|r")
    
    -- LFM Status
    self.lfmStatusLabel = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.lfmStatusLabel:SetPoint("TOPLEFT", self.statusFrame, "TOPLEFT", 30, -60)
    self.lfmStatusLabel:SetText("LFM System:")
    self.lfmStatusLabel:SetTextColor(1, 1, 1)
    
    self.lfmStatusValue = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.lfmStatusValue:SetPoint("LEFT", self.lfmStatusLabel, "RIGHT", 10, 0)
    self.lfmStatusValue:SetText("|cFF00FF00Ready|r")
    
    -- Auto-Open Status
    self.autoOpenLabel = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.autoOpenLabel:SetPoint("TOPLEFT", self.statusFrame, "TOPLEFT", 280, -40)
    self.autoOpenLabel:SetText("Auto-Open:")
    self.autoOpenLabel:SetTextColor(1, 1, 1)
    
    self.autoOpenValue = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.autoOpenValue:SetPoint("LEFT", self.autoOpenLabel, "RIGHT", 10, 0)
    local autoOpenStatus = FrostSeekDB.Settings.autoOpen and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"
    self.autoOpenValue:SetText(autoOpenStatus)
    
    -- Minimap Button Status
    self.minimapLabel = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.minimapLabel:SetPoint("TOPLEFT", self.statusFrame, "TOPLEFT", 280, -60)
    self.minimapLabel:SetText("Minimap Button:")
    self.minimapLabel:SetTextColor(1, 1, 1)
    
    self.minimapValue = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.minimapValue:SetPoint("LEFT", self.minimapLabel, "RIGHT", 10, 0)
    local minimapStatus = FrostSeekDB.Settings.minimapButton and "|cFF00FF00Visible|r" or "|cFFFF0000Hidden|r"
    self.minimapValue:SetText(minimapStatus)
    
    -- ===== QUICK STATISTICS =====
    self.statsFrame = CreateFrame("Frame", nil, self.frame)
    self.statsFrame:SetSize(550, 100)
    self.statsFrame:SetPoint("TOP", self.statusFrame, "BOTTOM", 0, -20)
    
    local statsBg = self.statsFrame:CreateTexture(nil, "BACKGROUND")
    statsBg:SetAllPoints()
    statsBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
    
    local statsTitle = self.statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsTitle:SetPoint("TOP", self.statsFrame, "TOP", 0, -10)
    statsTitle:SetText("|cFFFFFF00Quick Statistics|r")
    
    -- Active recruiters
    self.recruitersLabel = self.statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.recruitersLabel:SetPoint("TOPLEFT", self.statsFrame, "TOPLEFT", 30, -40)
    self.recruitersLabel:SetText("Active Recruiters:")
    self.recruitersLabel:SetTextColor(1, 1, 1)
    
    self.recruitersValue = self.statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.recruitersValue:SetPoint("LEFT", self.recruitersLabel, "RIGHT", 10, 0)
    self.recruitersValue:SetText("0")
    self.recruitersValue:SetTextColor(0.6, 0.8, 1)
    
    -- Version info
    self.versionLabel = self.statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.versionLabel:SetPoint("TOPLEFT", self.statsFrame, "TOPLEFT", 30, -60)
    self.versionLabel:SetText("Version:")
    self.versionLabel:SetTextColor(1, 1, 1)
    
    self.versionValue = self.statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.versionValue:SetPoint("LEFT", self.versionLabel, "RIGHT", 10, 0)
    self.versionValue:SetText("1.0.4")
    self.versionValue:SetTextColor(0.6, 0.8, 1)
    
    -- Uptime
    self.uptimeLabel = self.statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.uptimeLabel:SetPoint("TOPLEFT", self.statsFrame, "TOPLEFT", 280, -40)
    self.uptimeLabel:SetText("Session:")
    self.uptimeLabel:SetTextColor(1, 1, 1)
    
    self.uptimeValue = self.statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.uptimeValue:SetPoint("LEFT", self.uptimeLabel, "RIGHT", 10, 0)
    self.uptimeValue:SetText("00:00:00")
    self.uptimeValue:SetTextColor(0.6, 0.8, 1)
    
    -- ===== FOOTER =====
    self.footer = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.footer:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 10)
    self.footer:SetText("|cFFFFFF00FrostSeek | Made with Love by Ayro|r")
    self.footer:SetTextColor(0.8, 0.8, 0.8)
    
    self.frame:Hide()
end

function Dashboard:Show()
    self:UpdateAllData()
    self.frame:Show()
    
    if not self.updateTimer then
        self.updateTimer = C_Timer.NewTicker(1, function()
            self:UpdateRealTimeData()
        end)
    end
end

function Dashboard:Hide()
    self.frame:Hide()
    
    if self.updateTimer then
        self.updateTimer:Cancel()
        self.updateTimer = nil
    end
end

function Dashboard:UpdateAllData()
    self:UpdateSystemStatus()
    self:UpdateQuickStats()
    self:UpdateRealTimeData()
end

function Dashboard:UpdateSystemStatus()
    -- LFG Status
    if FrostSeekDB.LFG and FrostSeekDB.LFG.disableLFG then
        self.lfgStatusValue:SetText("|cFFFF0000Disabled|r")
    else
        self.lfgStatusValue:SetText("|cFF00FF00Active|r")
    end
    
    -- LFM Status (sempre attivo)
    self.lfmStatusValue:SetText("|cFF00FF00Ready|r")
    
    -- Auto-Open Status
    local autoOpenStatus = FrostSeekDB.Settings.autoOpen and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"
    self.autoOpenValue:SetText(autoOpenStatus)
    
    -- Minimap Button Status
    local minimapStatus = FrostSeekDB.Settings.minimapButton and "|cFF00FF00Visible|r" or "|cFFFF0000Hidden|r"
    self.minimapValue:SetText(minimapStatus)
end

function Dashboard:UpdateQuickStats()
    -- Active recruiters count
    local recruiterCount = 0
    if FrostSeek.Modules.lfg and FrostSeek.Modules.lfg.GetActiveRecruiterCount then
        recruiterCount = FrostSeek.Modules.lfg:GetActiveRecruiterCount() or 0
    end
    self.recruitersValue:SetText("|cFF88CCFF" .. recruiterCount .. "|r")
    
    -- Session time (uptime)
    local sessionDuration = GetTime() - (FrostSeek.SessionStartTime or GetTime())
    local hours = math.floor(sessionDuration / 3600)
    local minutes = math.floor((sessionDuration % 3600) / 60)
    local seconds = math.floor(sessionDuration % 60)
    self.uptimeValue:SetText(string.format("|cFF88CCFF%02d:%02d:%02d|r", hours, minutes, seconds))
end

function Dashboard:UpdateRealTimeData()
    -- Update clock
    local hour, minute = GetGameTime()
    local second = GetTime() % 60
    self.timeText:SetText(string.format("|cFF88CCFF%02d:%02d:%02d|r", hour, minute, second))
    
    -- Update date
    local dateTable = date("*t")
    local days = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
    local months = {"January", "February", "March", "April", "May", "June", 
                    "July", "August", "September", "October", "November", "December"}
    
    self.dateText:SetText(string.format("|cFFAAAAAA%s, %d %s|r", 
        days[dateTable.wday], dateTable.day, months[dateTable.month]))
    
    -- Update gold every second (rimane solo questo)
    local currentGold = GetMoney()
    if currentGold ~= self.lastGold then
        self.lastGold = currentGold
    end
end

-- ==================== MODULE REGISTRATION ====================
local function RegisterDashboardModule()
    if not _G.FrostSeek then
        C_Timer.After(0.5, RegisterDashboardModule)
        return
    end
    
    -- Salva il tempo di inizio sessione
    _G.FrostSeek.SessionStartTime = GetTime()
    
    if _G.FrostSeek.RegisterModule then
        _G.FrostSeek:RegisterModule("dashboard", Dashboard)
    end
end

RegisterDashboardModule()