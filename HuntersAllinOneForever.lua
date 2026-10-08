-- ============================================================================
-- Project: HuntersAllinOneForever
-- File: HuntersAllinOneForever.lua
-- Description: Entry point, chat router commands, and global namespace initializer.
-- ============================================================================

-- Create our global addon namespace container if it doesn't exist yet
HAOF = HAOF or {}
local function T(text)
    return HAOF.T and HAOF.T(text) or text
end

-- Reference placeholder for the visual companion window object
local CompanionFrame = nil

print("|cFF00FF00" .. T("HuntersAllinOneForever Loaded! Type /haof or /hunterjournal to open the Companion.") .. "|r")
-- Define global slash shortcuts for the Blizzard chat box frame
SLASH_HUNTERJOURNAL1 = "/hunterjournal"
SLASH_HUNTERJOURNAL2 = "/haof"

-- Setup execution sequence when slash shortcut commands are fired
SlashCmdList["HUNTERJOURNAL"] = function(msg)
    local command = string.lower(string.match(type(msg) == "string" and msg or "", "^%s*(.-)%s*$") or "")

    -- DATABASE COORDINATES RESET ROUTINE COMMAND
    if command == "reset" then
        if HAOF_Settings then
            HAOF_Settings.WindowPosition = { Point = "CENTER", RelativePoint = "CENTER", X = 0, Y = 0 }
            print("|cFF00FF00[HAOF]: " .. T("Companion window coordinates have been safely reset to center screen.") .. "|r")

            if CompanionFrame then
                CompanionFrame:ClearAllPoints()
                CompanionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            end
        end
        return
    end

    HAOF.ToggleCompanion()
end

function HAOF.ToggleCompanion()
    -- Construct the window frame element via global namespace layout engine
    if not CompanionFrame then
        if HAOF.HunterCompanionWindow and HAOF.HunterCompanionWindow.CreateJournalWindow then
            CompanionFrame = HAOF.HunterCompanionWindow:CreateJournalWindow()
        else
            UIErrorsFrame:AddMessage("HAOF Error: " .. T("Core Objects Missing!"), 1.0, 0.1, 0.1, 1.0)
            print("|cFFFF0000[HAOF Critical Error]: " .. T("The window assembly engine could not be accessed via namespace.") .. "|r")
            return
        end
    end

    if CompanionFrame:IsShown() then
        CompanionFrame:Hide()
    else
        CompanionFrame:Show()
    end
end

if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
    AddonCompartmentFrame:RegisterAddon({
        text = "HuntersAllinOneForever",
        icon = "Interface\\Icons\\Ability_Hunter_Snipershot",
        notCheckable = true,
        func = function()
            HAOF.ToggleCompanion()
        end,
        funcOnEnter = function(button)
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("HuntersAllinOneForever")
            GameTooltip:AddLine(T("Click to open or close the Hunter Companion."), 1, 1, 1)
            GameTooltip:Show()
        end,
        funcOnLeave = function()
            GameTooltip:Hide()
        end,
    })
else
    print("|cFFFF9900[HAOF]: " .. T("AddOn Compartment is unavailable in this client. Use /haof to open the Companion.") .. "|r")
end

-- Auto-execute background monitors once the player settles into the world
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
    if HAOF.HunterCompanionWindow and HAOF.HunterCompanionWindow.InitializePetXPBar then
        HAOF.HunterCompanionWindow:InitializePetXPBar()
    end
    if HAOF.HunterCooldownTracker and HAOF.HunterCooldownTracker.Initialize then
        HAOF.HunterCooldownTracker:Initialize()
    end
    if HAOF.HawkTracker and HAOF.HawkTracker.Initialize then
        HAOF.HawkTracker:Initialize()
    end
    if HAOF.AmmoAlertModule and HAOF.AmmoAlertModule.Initialize then
        HAOF.AmmoAlertModule:Initialize()
    end
    eventFrame:UnregisterAllEvents()
end)
