-- ============================================================================
-- Project: HuntersAllinOneForever
-- File: src/macro_space_handler.lua
-- Description: Audits macro log restrictions to protect hardware injections.
-- ============================================================================

HAOF = HAOF or {}
HAOF.MacroSpaceHandler = {}
local MacroSpaceHandler = HAOF.MacroSpaceHandler
local function T(text)
    return HAOF.T and HAOF.T(text) or text
end

local MAX_CHARACTER_MACROS = 18

-- Counts remaining free slots available for new macro string assets
function MacroSpaceHandler:GetAvailableCharacterSlots()
    local _, characterCount = GetNumMacros()
    characterCount = characterCount or 0

    local availableSlots = MAX_CHARACTER_MACROS - characterCount
    if availableSlots < 0 then availableSlots = 0 end

    return availableSlots, characterCount
end
-- Safety verification gateway checking if an injection run is safe
function MacroSpaceHandler:CanInjectMacro(macroName)
    local existingIndex = GetMacroIndexByName(macroName)
    if existingIndex and existingIndex > 0 then return true end

    local availableSlots = self:GetAvailableCharacterSlots()
    return availableSlots > 0
end

-- Compiles highly readable indicator messages for the companion frame displays
function MacroSpaceHandler:GetSpaceWarningText()
    local available, currentCount = self:GetAvailableCharacterSlots()

    if available == 0 then
        return string.format("|cFFFF0000%s|r", string.format(T("Macro Space Full (%d/%d)"), currentCount, MAX_CHARACTER_MACROS))
    elseif available <= 2 then
        return string.format("|cFFFFCC00%s|r", string.format(T("Storage Caution: %d open (%d/%d)"), available, currentCount, MAX_CHARACTER_MACROS))
    else
        return string.format("|cFF00FF00%s|r", string.format(T("Macro Storage Safe: %d open (%d/%d)"), available, currentCount, MAX_CHARACTER_MACROS))
    end
end
