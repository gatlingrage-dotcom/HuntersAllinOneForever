-- ============================================================================
-- Project: HuntersAllinOneForever
-- File: src/settings.lua
-- Description: Persistent profile management tracking desktop UI coordinate metrics.
-- ============================================================================

HAOF = HAOF or {}
HAOF.SettingsManager = {}
local SettingsManager = HAOF.SettingsManager

local DEFAULT_SETTINGS = {
    Language = "auto",
    WindowPosition = { Point = "CENTER", RelativePoint = "CENTER", X = 0, Y = 0 },
    AmmoAlert = { Enabled = true, CriticalThreshold = 50, WarningThreshold = 200 },
    HawkTracker = {
        Enabled = true,
        ShowOnlyInCombat = false,
        WindowOpacity = 94,
        WindowLocked = false,
        WindowPosition = { Point = "CENTER", RelativePoint = "CENTER", X = 230, Y = -250 },
    },
    CooldownTracker = {
        ShowOnlyInCombat = false,
        WindowOpacity = 94,
        WindowLocked = false,
        SeparateWindowPosition = { Point = "CENTER", RelativePoint = "CENTER", X = 230, Y = -80 },
        Abilities = {
            FreezingTrap = true,
            ImmolationTrap = true,
            FrostTrap = true,
            ExplosiveTrap = true,
            FeignDeath = true,
            RapidFire = true,
            BestialWrath = true,
            ConcussiveShot = true,
        },
    },
}

local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            ApplyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

-- Validates that the globally mapped hardware data structure exists safely
function SettingsManager:InitializeDatabase()
    if not HAOF_Settings then
        HAOF_Settings = {}
    end

    ApplyDefaults(HAOF_Settings, DEFAULT_SETTINGS)
    return HAOF_Settings
end

function SettingsManager:GetOptions()
    return self:InitializeDatabase()
end
-- Maps previous interface settings onto the layout frame boundaries during startup ticks
function SettingsManager:ApplyWindowPosition(frame)
    if not frame then return end

    local config = self:InitializeDatabase()
    local pos = config.WindowPosition

    frame:ClearAllPoints()
    frame:SetPoint(pos.Point, UIParent, pos.RelativePoint, pos.X, pos.Y)
end

-- Extracts real-time location metrics to overwrite older coordinates upon mouse drops
function SettingsManager:SaveWindowPosition(frame)
    if not frame then return end

    local config = self:InitializeDatabase()
    local point, _, relativePoint, xOffset, yOffset = frame:GetPoint()

    config.WindowPosition.Point = point or "CENTER"
    config.WindowPosition.RelativePoint = relativePoint or "CENTER"
    config.WindowPosition.X = xOffset or 0
    config.WindowPosition.Y = yOffset or 0
end

local settings = SettingsManager:InitializeDatabase()
if HAOF.ApplyLanguage then
    HAOF.ApplyLanguage(settings.Language)
end

local languageInitializer = CreateFrame("Frame")
languageInitializer:RegisterEvent("ADDON_LOADED")
languageInitializer:SetScript("OnEvent", function(self, _, addonName)
    if addonName ~= "HuntersAllinOneForever" then
        return
    end

    local loadedSettings = SettingsManager:InitializeDatabase()
    if HAOF.ApplyLanguage then
        HAOF.ApplyLanguage(loadedSettings.Language)
    end
    self:UnregisterEvent("ADDON_LOADED")
end)
