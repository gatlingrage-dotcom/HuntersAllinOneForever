-- ============================================================================
-- Project: HuntersAllinOneForever
-- File: src/pet_matrix_logic.lua
-- Description: Custom Lua scripts for WeakAuras text and progress displays.
-- ============================================================================

local HuntersAllinOneForever = {}

-- 1. DYNAMIC PET LOYALTY & FEEDING COUNTDOWN TEXT
-- Paste this into the "Custom Text" function of your Pet Text WeakAura.
-- Triggers: Status -> Pet Info & Aura -> Buff (Feed Pet Effect)
function HuntersAllinOneForever.GetPetStatusText()
    local petName = UnitName("pet")
    if not petName then return "" end

    -- Fetch current loyalty level index (returns 1-6)
    local loyaltyIndex, loyaltyName = GetPetLoyalty()
    if not loyaltyIndex then return "No Pet" end

    -- Check for the "Feed Pet Effect" buff on the pet
    local feedBuffName = "Feed Pet Effect"
    local name, _, _, _, _, duration, expirationTime = UnitBuff("pet", feedBuffName)

    local loyaltyString = string.format("Rank %d (%s)", loyaltyIndex, loyaltyName or "Unknown")

    if name and expirationTime then
        local timeLeft = expirationTime - GetTime()
        if timeLeft > 0 then
            -- Appends a precise, friendly countdown for the feeding window
            return string.format("%s |cFF00FF00[Feeding: %ds]|r", loyaltyString, math.ceil(timeLeft))
        end
    end

    return loyaltyString
end

-- 2. DYNAMIC AMMO WARNING SCRIPT
-- Paste this into the "Custom Text" trigger for your Ammo Counter.
-- Triggers: Status -> Item Count -> Choose Ammo Category
function HuntersAllinOneForever.GetAmmoWarningColor(count)
    if not count or count == 0 then
        return "|cFFFF0000NO AMMO|r"
    elseif count < 50 then
        -- Flashing-alert color formatting for critical levels
        return string.format("|cFFFF0000LOW AMMO: %d|r", count)
    elseif count < 200 then
        -- Alert warning color for low bags
        return string.format("|cFFFFCC00Warning: %d|r", count)
    else
        -- Clean, healthy count indicator
        return string.format("|cFF00FF00Ammo: %d|r", count)
    end
end

-- 3. PET FOCUS SPENDING MONITOR
-- Returns true if pet has enough focus to prioritize its high-impact abilities
function HuntersAllinOneForever.IsPetFocusHealthy()
    if not HasPetUI() then return false end
    local currentFocus = UnitPower("pet")

    -- WoW Forever pets require padding to prevent focus starvation on auto-casts
    if currentFocus >= 40 then
        return true
    end
    return false
end

return HuntersAllinOneForever
