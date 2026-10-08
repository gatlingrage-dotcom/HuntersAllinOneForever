-- ============================================================================
-- Project: HuntersAllinOneForever
-- File: src/hawk_tracker_logic.lua
-- Description: Custom tracking triggers for Beast Mastery Multi-Hawk management.
-- ============================================================================

HAOF = HAOF or {}
local HawkTracker = {}
HAOF.HawkTracker = HawkTracker
local BOOK_GOLD = { 0.95, 0.72, 0.34 }
local HAWK_ICON_ID = 132158
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

local function GetNativeTotemCount()
    local totemFrame = _G.TotemFrame
    if not totemFrame then
        return nil
    end

    local activeTotems = totemFrame.activeTotems
    if IsSecretValue(activeTotems) or type(activeTotems) ~= "number" then
        return nil
    end
    return math.min(2, math.max(0, activeTotems))
end

local function GetHawkStatus()
    local count = GetNativeTotemCount()
    if count == nil then
        return nil, "|cFFFFCC00" .. T("Hawk count unavailable") .. "|r", ""
    elseif count == 2 then
        return count, "|cFF00FF00" .. T("TWO HAWKS ACTIVE") .. "|r", T("Individual timers are shown on the totem icons.")
    elseif count == 1 then
        return count, "|cFFFFCC00" .. T("ONE HAWK ACTIVE") .. "|r", T("Individual timer is shown on the totem icon.")
    end
    return count, "|cFFFF0000" .. T("NO HAWKS ACTIVE") .. "|r", ""
end

local function SaveWindowPosition(window)
    window:StopMovingOrSizing()
    local point, _, relativePoint, x, y = window:GetPoint()
    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    local position = settings and settings.HawkTracker.WindowPosition
    if position then
        position.Point = point or "CENTER"
        position.RelativePoint = relativePoint or "CENTER"
        position.X = x or 0
        position.Y = y or 0
    end
end

function HawkTracker:CreateWindow()
    if self.Window then
        return self.Window
    end

    local frame = CreateFrame("Frame", "HAOF_HawkStatusWindow", UIParent, "BackdropTemplate")
    frame:SetSize(250, 94)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(52, 52)
    icon:SetPoint("LEFT", frame, "LEFT", 12, 0)
    icon:SetTexture(HAWK_ICON_ID)
    frame.HawkIcon = icon

    local count = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    count:SetPoint("CENTER", icon, "CENTER", 0, 0)
    count:SetTextColor(1, 1, 1)
    count:SetShadowOffset(1, -1)
    frame.Count = count

    local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    status:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -8)
    status:SetWidth(164)
    status:SetJustifyH("LEFT")
    status:SetJustifyV("TOP")
    frame.Status = status
    local timers = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timers:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -3)
    timers:SetWidth(164)
    timers:SetJustifyH("LEFT")
    frame.Timers = timers

    frame:SetScript("OnDragStart", function(window)
        local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
        local locked = settings and settings.HawkTracker.WindowLocked
        local shiftHeld = type(IsShiftKeyDown) == "function" and IsShiftKeyDown()
        if not locked or shiftHeld then
            window:SetMovable(true)
            window:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(window)
        SaveWindowPosition(window)
        local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
        window:SetMovable(not (settings and settings.HawkTracker.WindowLocked))
    end)

    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    local position = settings and settings.HawkTracker.WindowPosition
    if position then
        frame:SetPoint(
            position.Point or "CENTER",
            UIParent,
            position.RelativePoint or "CENTER",
            position.X or 0,
            position.Y or 0
        )
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 230, -250)
    end

    self.Window = frame
    self:ApplyWindowOpacity()
    self:ApplyWindowLockMode()
    return frame
end

function HawkTracker:ApplyWindowOpacity()
    if not self.Window then
        return
    end
    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    local opacity = tonumber(settings and settings.HawkTracker.WindowOpacity) or 94
    opacity = math.max(0, math.min(100, opacity))
    local alpha = opacity / 100
    self.Window:SetBackdropColor(0.08, 0.055, 0.035, 0.94 * alpha)
    self.Window:SetBackdropBorderColor(BOOK_GOLD[1], BOOK_GOLD[2], BOOK_GOLD[3], alpha)
end

function HawkTracker:SetWindowOpacity(opacity)
    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    opacity = math.max(0, math.min(100, math.floor(tonumber(opacity) or 94)))
    if settings then
        settings.HawkTracker.WindowOpacity = opacity
    end
    self:ApplyWindowOpacity()
end

function HawkTracker:ApplyWindowLockMode()
    if not self.Window then
        return
    end
    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    self.Window:SetMovable(not (settings and settings.HawkTracker.WindowLocked))
end

function HawkTracker:SetWindowLocked(locked)
    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    if settings then
        settings.HawkTracker.WindowLocked = locked and true or false
    end
    self:ApplyWindowLockMode()
end

function HawkTracker:RefreshWindow()
    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    if not settings then
        return
    end

    local count, status, timerText = GetHawkStatus()

    local frame = self.Window or self:CreateWindow()
    if settings.HawkTracker.ShowOnlyInCombat
        and (type(UnitAffectingCombat) ~= "function" or not UnitAffectingCombat("player")) then
        frame:Hide()
    else
        frame.Count:SetText(count or "?")
        if count == 2 then
            frame.Count:SetTextColor(0.25, 1, 0.25)
        elseif count == 1 then
            frame.Count:SetTextColor(1, 0.8, 0.2)
        else
            frame.Count:SetTextColor(1, 0.35, 0.3)
        end
        frame.Status:SetText(status)
        frame.Timers:SetText(timerText)
        frame:Show()
    end
end

function HawkTracker:Initialize()
    if not self.VisibilityEvents then
        local visibilityEvents = CreateFrame("Frame")
        visibilityEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
        visibilityEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
        visibilityEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
        visibilityEvents:RegisterEvent("PLAYER_TOTEM_UPDATE")
        visibilityEvents:RegisterEvent("PLAYER_TALENT_UPDATE")
        visibilityEvents:SetScript("OnEvent", function()
            if self.Window then
                self.Window.HawkIcon:SetTexture(
                    HAWK_ICON_ID
                )
            end
            self:RefreshWindow()
        end)
        self.VisibilityEvents = visibilityEvents
    end

    if not self.TotemFrameHooked and _G.TotemFrame and type(hooksecurefunc) == "function" then
        hooksecurefunc(_G.TotemFrame, "Update", function()
            if self.Window then
                self.Window.HawkIcon:SetTexture(
                    HAWK_ICON_ID
                )
            end
            self:RefreshWindow()
        end)
        self.TotemFrameHooked = true
    end

    self:RefreshWindow()
end

return HawkTracker
