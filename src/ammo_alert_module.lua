-- ============================================================================
-- Project: HuntersAllinOneForever
-- File: src/ammo_alert_module.lua
-- Description: Triggers screen alert warnings and sounds when ammo supply drops.
-- ============================================================================

HAOF = HAOF or {}
HAOF.AmmoAlertModule = {}
local AmmoAlertModule = HAOF.AmmoAlertModule
local function T(text)
    return HAOF.T and HAOF.T(text) or text
end

local DEFAULT_CRITICAL_THRESHOLD = 50
local DEFAULT_WARNING_THRESHOLD = 200
local FLASH_INTERVAL = 1.0
local lastFlashTime = 0

function AmmoAlertModule:GetThresholds()
    local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
    local ammoSettings = settings and settings.AmmoAlert
    local criticalThreshold = tonumber(ammoSettings and ammoSettings.CriticalThreshold)
        or DEFAULT_CRITICAL_THRESHOLD
    local warningThreshold = tonumber(ammoSettings and ammoSettings.WarningThreshold)
        or DEFAULT_WARNING_THRESHOLD
    return math.max(0, criticalThreshold), math.max(criticalThreshold, warningThreshold)
end

function AmmoAlertModule:CreateAlertFrame()
    local frame = CreateFrame("Frame", "HAOF_AmmoAlertFrame", UIParent)
    frame:SetSize(400, 70)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -250)

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetScale(1.3)

    frame.Text = text
    frame:Hide()
    return frame
end

function AmmoAlertModule:GetAmmoCount()
    if not GetInventorySlotInfo then return nil end
    local ammoSlotID = GetInventorySlotInfo("AmmoSlot")
    if not ammoSlotID then return nil end
    local ammoID = GetInventoryItemID("player", ammoSlotID)
    if not ammoID then return nil end

    if type(GetItemCount) == "function" then
        return GetItemCount(ammoID, false)
    end
    if C_Item and type(C_Item.GetItemCount) == "function" then
        return C_Item.GetItemCount(ammoID, false)
    end
    return nil
end
function AmmoAlertModule:OnUpdateHandler(frame, elapsed)
    lastFlashTime = lastFlashTime + elapsed
    if lastFlashTime < FLASH_INTERVAL then return end
    lastFlashTime = 0

    local count = self:GetAmmoCount()
    if not count then frame:Hide() return end
    local criticalThreshold, warningThreshold = self:GetThresholds()

    if count <= criticalThreshold then
        frame:Show()
        frame.Text:SetText("|cFFFF0000" .. string.format(T("CRITICAL AMMO SUPPLY: %d"), count) .. "|r")
        PlaySound(826, "Master")
        frame.Text:SetScale(frame.pulsed and 1.4 or 1.2)
        frame.pulsed = not frame.pulsed
    elseif count <= warningThreshold then
        frame:Show()
        frame.Text:SetText("|cFFFFCC00" .. string.format(T("Ammo Count Caution: %d"), count) .. "|r")
        frame.Text:SetScale(1.0)
    else
        frame:Hide()
    end
end

function AmmoAlertModule:Initialize()
    if self.EventFrame then
        return
    end
    local alertFrame = self:CreateAlertFrame()
    local eventFrame = CreateFrame("Frame")

    eventFrame:RegisterEvent("BAG_UPDATE")
    eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.AlertFrame = alertFrame
    self.EventFrame = eventFrame

    eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then return end

        local settings = HAOF.SettingsManager and HAOF.SettingsManager:GetOptions()
        if not (settings and settings.AmmoAlert and settings.AmmoAlert.Enabled) then
            eventFrame:SetScript("OnUpdate", nil)
            alertFrame:Hide()
            return
        end

        local count = self:GetAmmoCount()
        local _, warningThreshold = self:GetThresholds()
        if count and count <= warningThreshold then
            eventFrame:SetScript("OnUpdate", function(_, elapsed)
                self:OnUpdateHandler(alertFrame, elapsed)
            end)
        else
            eventFrame:SetScript("OnUpdate", nil)
            alertFrame:Hide()
        end
    end)
    eventFrame:GetScript("OnEvent")(eventFrame, "PLAYER_ENTERING_WORLD")
end

function AmmoAlertModule:Refresh()
    if not self.EventFrame then
        self:Initialize()
        return
    end
    self.EventFrame:GetScript("OnEvent")(self.EventFrame, "PLAYER_ENTERING_WORLD")
end
