HAOF = HAOF or {}
HAOF.HunterCooldownTracker = {}

local HunterCooldownTracker = HAOF.HunterCooldownTracker
local BOOK_GOLD = { 0.95, 0.72, 0.34 }
local function T(text)
    return HAOF.T and HAOF.T(text) or text
end

local function IsSecretValue(value)
    if type(issecretvalue) ~= "function" then
        return false
    end
    local ok, isSecret = pcall(issecretvalue, value)
    return ok and isSecret
end

HunterCooldownTracker.Abilities = {
    { Key = "FreezingTrap", Name = "Freezing Trap", SpellIDs = { 1499, 14310, 14311 }, IconSpellID = 14311, IsTrap = true },
    { Key = "ImmolationTrap", Name = "Immolation Trap", SpellIDs = { 13795, 14302, 14303, 14304, 14305 }, IconSpellID = 14305, IsTrap = true },
    { Key = "FrostTrap", Name = "Frost Trap", SpellIDs = { 13809 }, IconSpellID = 13809, IsTrap = true },
    { Key = "ExplosiveTrap", Name = "Explosive Trap", SpellIDs = { 13813, 14316, 14317 }, IconSpellID = 14317, IsTrap = true },
    { Key = "FeignDeath", Name = "Feign Death", SpellIDs = { 5384 }, IconSpellID = 5384 },
    { Key = "RapidFire", Name = "Rapid Fire", SpellIDs = { 3045 }, IconSpellID = 3045 },
    { Key = "BestialWrath", Name = "Bestial Wrath", SpellIDs = { 19574 }, IconSpellID = 19574 },
    { Key = "ConcussiveShot", Name = "Concussive Shot", SpellIDs = { 5116 }, IconSpellID = 5116 },
}

local ESTIMATED_COOLDOWNS = {
    FeignDeath = 30,
}

local function GetCooldown(spellID)
    if type(GetSpellCooldown) == "function" then
        local startTime, duration, enabled = GetSpellCooldown(spellID)
        if startTime ~= nil then
            return startTime, duration, enabled
        end
    end

    if C_Spell and type(C_Spell.GetSpellCooldown) == "function" then
        local cooldown = C_Spell.GetSpellCooldown(spellID)
        if cooldown then
            return cooldown.startTime, cooldown.duration, cooldown.isEnabled
        end
    end
end

local function GetSpellTexture(spellID)
    if type(_G.GetSpellTexture) == "function" then
        return _G.GetSpellTexture(spellID)
    end
    if type(GetSpellInfo) == "function" then
        local _, _, texture = GetSpellInfo(spellID)
        return texture
    end
    if C_Spell and type(C_Spell.GetSpellTexture) == "function" then
        return C_Spell.GetSpellTexture(spellID)
    end
end

local function IsSpellKnown(spellID)
    if type(IsPlayerSpell) == "function" then
        return IsPlayerSpell(spellID)
    end
    if type(_G.IsSpellKnown) == "function" then
        return _G.IsSpellKnown(spellID)
    end
end

local function GetAbilityCooldown(ability)
    local hasKnownSpellAPI = type(IsPlayerSpell) == "function"
        or type(_G.IsSpellKnown) == "function"
    if hasKnownSpellAPI then
        for index = #ability.SpellIDs, 1, -1 do
            local spellID = ability.SpellIDs[index]
            if IsSpellKnown(spellID) then
                return GetCooldown(spellID)
            end
        end
        return nil, nil, nil, "not-known"
    end

    for index = #ability.SpellIDs, 1, -1 do
        local startTime, duration, enabled = GetCooldown(ability.SpellIDs[index])
        if startTime ~= nil then
            return startTime, duration, enabled
        end
    end
end

function HunterCooldownTracker:GetAbilities()
    return self.Abilities
end

function HunterCooldownTracker:IsAbilityKnown(ability)
    local hasKnownSpellAPI = type(IsPlayerSpell) == "function"
        or type(_G.IsSpellKnown) == "function"
    if not hasKnownSpellAPI then
        return true
    end

    for index = #ability.SpellIDs, 1, -1 do
        if IsSpellKnown(ability.SpellIDs[index]) then
            return true
        end
    end
    return false
end

function HunterCooldownTracker:RecordAbilityCast(...)
    local argumentCount = select("#", ...)
    for _, ability in ipairs(self.Abilities) do
        local cooldown = ability.IsTrap and 30 or ESTIMATED_COOLDOWNS[ability.Key]
        if cooldown then
            for argumentIndex = 1, argumentCount do
                local candidate = select(argumentIndex, ...)
                if not IsSecretValue(candidate) then
                    for _, knownSpellID in ipairs(ability.SpellIDs) do
                        if candidate == knownSpellID then
                            self.EstimatedCooldowns = self.EstimatedCooldowns or {}
                            self.EstimatedCooldowns[ability.Key] = {
                                Start = GetTime(),
                                Duration = cooldown,
                            }
                            return
                        end
                    end

                    if type(candidate) == "string" then
                        for _, knownSpellID in ipairs(ability.SpellIDs) do
                            if type(GetSpellInfo) == "function" then
                                local knownSpellName = GetSpellInfo(knownSpellID)
                                if knownSpellName and not IsSecretValue(knownSpellName)
                                    and candidate == knownSpellName then
                                    self.EstimatedCooldowns = self.EstimatedCooldowns or {}
                                    self.EstimatedCooldowns[ability.Key] = {
                                        Start = GetTime(),
                                        Duration = cooldown,
                                    }
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function HunterCooldownTracker:CreateSeparateWindow()
    if self.SeparateWindow then
        return self.SeparateWindow
    end

    local frame = CreateFrame("Frame", "HAOF_CooldownWindow", UIParent, "BackdropTemplate")
    frame:SetSize(248, 150)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    local function SavePosition(window)
        window:StopMovingOrSizing()
        local point, _, relativePoint, x, y = window:GetPoint()
        local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
        local position = settings and settings.CooldownTracker.SeparateWindowPosition
        if position then
            position.Point = point or "CENTER"
            position.RelativePoint = relativePoint or "CENTER"
            position.X = x or 0
            position.Y = y or 0
        end
    end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    local emptyStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyStatus:SetPoint("CENTER", frame, "CENTER", 0, -4)
    emptyStatus:SetWidth(220)
    emptyStatus:SetJustifyH("CENTER")
    emptyStatus:SetText(T("Select abilities in Options"))
    frame.EmptyStatus = emptyStatus

    local dragHandle = CreateFrame("Frame", nil, frame)
    dragHandle:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    dragHandle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -58, 0)
    dragHandle:SetHeight(22)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetScript("OnDragStart", function()
        if not frame.IsLocked then
            frame.MoveStartedFromIcon = false
            frame:StartMoving()
        end
    end)
    dragHandle:SetScript("OnDragStop", function()
        if frame.MoveStartedFromIcon == false and not frame.IsLocked then
            SavePosition(frame)
        end
        frame.MoveStartedFromIcon = nil
        frame:SetMovable(not frame.IsLocked)
    end)
    frame.DragHandle = dragHandle

    local cells = {}
    for index, ability in ipairs(self.Abilities) do
        local position = index - 1
        local row = math.floor(position / 4)
        local column = position % 4
        local cell = CreateFrame("Frame", nil, frame)
        cell:SetSize(44, 44)
        cell:SetPoint("TOPLEFT", frame, "TOPLEFT", 15 + column * 54, -26 - row * 48)
        cell.Ability = ability
        cell:EnableMouse(true)
        cell:RegisterForDrag("LeftButton")
        cell:SetScript("OnDragStart", function()
            local shiftHeld = type(IsShiftKeyDown) == "function" and IsShiftKeyDown()
            if not frame.IsLocked or shiftHeld then
                frame.MoveStartedFromIcon = true
                frame:SetMovable(true)
                frame:StartMoving()
            end
        end)
        cell:SetScript("OnDragStop", function()
            if frame.MoveStartedFromIcon then
                SavePosition(frame)
            end
            frame.MoveStartedFromIcon = nil
            frame:SetMovable(not frame.IsLocked)
        end)

        cell.Icon = cell:CreateTexture(nil, "ARTWORK")
        cell.Icon:SetAllPoints(cell)
        cell.Icon:SetTexture(GetSpellTexture(ability.IconSpellID))

        cell.Border = cell:CreateTexture(nil, "OVERLAY")
        cell.Border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        cell.Border:SetBlendMode("ADD")
        cell.Border:SetPoint("CENTER", cell, "CENTER")
        cell.Border:SetSize(58, 58)
        cell.Border:SetVertexColor(0.67, 0.43, 0.16, 0.8)

        cell.Cooldown = CreateFrame("Cooldown", nil, cell, "CooldownFrameTemplate")
        cell.Cooldown:SetAllPoints(cell)
        cell.Cooldown:SetDrawEdge(true)

        cell.Count = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cell.Count:SetPoint("BOTTOM", cell, "BOTTOM", 0, 2)
        cell.Count:SetTextColor(1, 1, 1)

        cell:SetScript("OnEnter", function(button)
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(T(button.Ability.Name), 1, 0.82, 0)
            GameTooltip:Show()
        end)
        cell:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        cells[index] = cell
    end
    frame.Cells = cells

    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    local position = settings and settings.CooldownTracker.SeparateWindowPosition
    frame:ClearAllPoints()
    if position then
        frame:SetPoint(
            position.Point or "CENTER",
            UIParent,
            position.RelativePoint or "CENTER",
            position.X or 0,
            position.Y or 0
        )
    else
        frame:SetPoint("CENTER", UIParent, "CENTER")
    end

    local refreshElapsed = 0
    frame:SetScript("OnUpdate", function(_, elapsed)
        refreshElapsed = refreshElapsed + elapsed
        if refreshElapsed < 0.5 then
            return
        end
        refreshElapsed = 0
        self:RefreshSeparateWindow()
    end)
    self.SeparateWindow = frame
    self:ApplyWindowOpacity()
    self:ApplyWindowLockMode()
    return frame
end

function HunterCooldownTracker:ApplyWindowOpacity()
    local frame = self.SeparateWindow
    if not frame then
        return
    end
    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    local opacity = tonumber(settings and settings.CooldownTracker.WindowOpacity) or 94
    opacity = math.max(0, math.min(100, opacity))
    local alpha = opacity / 100
    frame:SetBackdropColor(0.08, 0.055, 0.035, 0.94 * alpha)
    frame:SetBackdropBorderColor(0.67, 0.43, 0.16, alpha)
end

function HunterCooldownTracker:SetWindowOpacity(opacity)
    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    opacity = math.max(0, math.min(100, math.floor(tonumber(opacity) or 94)))
    if settings then
        settings.CooldownTracker.WindowOpacity = opacity
    end
    self:ApplyWindowOpacity()
end

function HunterCooldownTracker:ApplyWindowLockMode()
    local frame = self.SeparateWindow
    if not frame then
        return
    end
    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    local locked = settings and settings.CooldownTracker.WindowLocked or false
    frame.IsLocked = locked
    frame:SetMovable(not locked)
    frame.DragHandle:EnableMouse(not locked)
end

function HunterCooldownTracker:SetWindowLocked(locked)
    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    if settings then
        settings.CooldownTracker.WindowLocked = locked and true or false
    end
    self:ApplyWindowLockMode()
end

function HunterCooldownTracker:RefreshSeparateWindow()
    local settingsManager = HAOF.SettingsManager
    local settings = settingsManager and settingsManager:GetOptions()
    local cooldownSettings = settings and settings.CooldownTracker
    if not self.SeparateWindow and not cooldownSettings then
        return
    end
    local frame = self.SeparateWindow or self:CreateSeparateWindow()
    frame.EmptyStatus:Hide()
    if not cooldownSettings then
        frame:Hide()
        return
    end
    if cooldownSettings.ShowOnlyInCombat
        and (type(UnitAffectingCombat) ~= "function" or not UnitAffectingCombat("player")) then
        frame:Hide()
        return
    end
    if not frame:IsShown() then
        frame:Show()
    end

    local visibleCount = 0
    for _, cell in ipairs(frame.Cells) do
        local ability = cell.Ability
        if cooldownSettings.Abilities[ability.Key] then
            visibleCount = visibleCount + 1
            cell:Show()
            local startTime, duration, enabled, state = GetAbilityCooldown(ability)
            if self.EstimatedCooldowns and self.EstimatedCooldowns[ability.Key]
                and (startTime == nil or IsSecretValue(startTime)
                    or IsSecretValue(duration) or IsSecretValue(enabled)) then
                local estimate = self.EstimatedCooldowns[ability.Key]
                startTime = estimate.Start
                duration = estimate.Duration
                enabled = 1
                state = nil
            end
            if state == "not-known" then
                cell.Count:SetText("")
                cell.Icon:SetDesaturated(true)
                cell.Cooldown:SetCooldown(0, 0)
                cell.CooldownStart = nil
                cell.CooldownDuration = nil
            elseif startTime == nil then
                cell.Count:SetText("?")
                cell.Icon:SetDesaturated(true)
                cell.Cooldown:SetCooldown(0, 0)
                cell.CooldownStart = nil
                cell.CooldownDuration = nil
            elseif IsSecretValue(startTime) or IsSecretValue(duration) or IsSecretValue(enabled) then
                cell.Count:SetText("?")
                cell.Icon:SetDesaturated(false)
                cell.Cooldown:SetCooldown(0, 0)
                cell.CooldownStart = nil
                cell.CooldownDuration = nil
            else
                local remaining = math.max(0, (startTime + (duration or 0)) - GetTime())
                cell.Icon:SetDesaturated(enabled == 0)
                if remaining > 0 then
                    cell.Count:SetText(remaining >= 60
                        and string.format("%dm", math.ceil(remaining / 60))
                        or string.format("%d", math.ceil(remaining)))
                    if cell.CooldownStart ~= startTime or cell.CooldownDuration ~= duration then
                        cell.Cooldown:SetCooldown(startTime, duration)
                        cell.CooldownStart = startTime
                        cell.CooldownDuration = duration
                    end
                else
                    cell.Count:SetText("")
                    cell.Cooldown:SetCooldown(0, 0)
                    cell.CooldownStart = nil
                    cell.CooldownDuration = nil
                end
            end
        else
            cell:Hide()
        end
    end

    if visibleCount == 0 then
        frame.EmptyStatus:Show()
    end
end

function HunterCooldownTracker:TestTrackability()
    local report = {}
    for _, ability in ipairs(self.Abilities) do
        local startTime, duration, enabled, state = GetAbilityCooldown(ability)
        local result
        if state == "not-known" then
            result = "|cFF888888Not learned|r"
        elseif startTime == nil then
            result = "|cFFFF4040Cooldown data unavailable|r"
        elseif IsSecretValue(startTime) or IsSecretValue(duration) or IsSecretValue(enabled) then
            result = "|cFFFFCC00Cooldown data protected by client|r"
        else
            local remaining = math.max(0, (startTime + (duration or 0)) - GetTime())
            result = remaining > 0
                and string.format("|cFFFFCC00%s|r", string.format(T("Trackable - %.1f sec"), remaining))
                or "|cFF80FF80Trackable - ready|r"
        end
        table.insert(report, string.format("%s: %s", T(ability.Name), result))
    end
    return table.concat(report, "\n")
end

function HunterCooldownTracker:Initialize()
    if not self.VisibilityEvents then
        local visibilityEvents = CreateFrame("Frame")
        visibilityEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
        visibilityEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
        if type(visibilityEvents.RegisterUnitEvent) == "function" then
            visibilityEvents:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
            visibilityEvents:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
            visibilityEvents:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
        else
            visibilityEvents:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            visibilityEvents:RegisterEvent("UNIT_SPELLCAST_SENT")
            visibilityEvents:RegisterEvent("UNIT_SPELLCAST_START")
        end
        visibilityEvents:SetScript("OnEvent", function(_, event, unit, ...)
            if unit == "player" and (event == "UNIT_SPELLCAST_SUCCEEDED"
                or event == "UNIT_SPELLCAST_SENT" or event == "UNIT_SPELLCAST_START") then
                self:RecordAbilityCast(...)
            end
            self:RefreshSeparateWindow()
        end)
        self.VisibilityEvents = visibilityEvents
    end
    self:RefreshSeparateWindow()
end

return HunterCooldownTracker
