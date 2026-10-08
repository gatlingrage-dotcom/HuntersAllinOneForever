-- ============================================================================
-- Project: HuntersAllinOneForever
-- File: src/pet_training_calculator.lua
-- Description: Point evaluation matrices matching pet levels and loyalty bounds.
-- ============================================================================

HAOF = HAOF or {}
HAOF.PetTrainingCalculator = {}
local PetTrainingCalculator = HAOF.PetTrainingCalculator
local function T(text)
    return HAOF.T and HAOF.T(text) or text
end

local MAX_PET_LEVEL = 60
local MAX_LOYALTY_RANK = 6

local loyaltyRankLookup = {
    ["best friend"] = 6,
    ["trusted"] = 5,
    ["faithful"] = 4,
    ["loyal"] = 3,
    ["unruly"] = 2,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
}

for englishName, rank in pairs({
    ["best friend"] = 6,
    ["trusted"] = 5,
    ["faithful"] = 4,
    ["loyal"] = 3,
    ["unruly"] = 2,
}) do
    loyaltyRankLookup[string.lower(T(englishName))] = rank
end

local function normalizeLoyaltyName(loyaltyName)
    if type(loyaltyName) ~= "string" then
        return ""
    end

    local trimmed = string.gsub(loyaltyName, '^%s*(.-)%s*$', '%1')
    return string.lower(trimmed)
end

function PetTrainingCalculator:GetLoyaltyIndex(loyaltyName)
    local normalized = normalizeLoyaltyName(loyaltyName)
    if normalized == "" then
        return 2
    end

    local rank = loyaltyRankLookup[normalized]
    if rank then
        return rank
    end

    for token, value in pairs(loyaltyRankLookup) do
        if string.find(normalized, token, 1, true) then
            return value
        end
    end

    return 2
end

-- Core formula: TP = Pet Level * (Loyalty Rank - 1)
function PetTrainingCalculator:CalculateTotalPoints(level, loyaltyRank)
    level = tonumber(level)
    loyaltyRank = tonumber(loyaltyRank)

    if not level or not loyaltyRank then
        return 0
    end

    if level < 1 or level > MAX_PET_LEVEL then
        return 0
    end

    if loyaltyRank < 1 or loyaltyRank > MAX_LOYALTY_RANK then
        return 0
    end

    return level * (loyaltyRank - 1)
end

-- Generates real-time summary text describing active pet statistics.
function PetTrainingCalculator:GetTrainingSummaryText()
    if not HasPetUI() or not UnitName("pet") then
        return "|cFF888888[" .. T("No Active Pet: Max Level 60 Benchmark Shown") .. "]|r\n" ..
            " - " .. T("Max TP Pool Capable (Rank 6):") .. " |cFF00FF00300 " .. T("TP") .. "|r\n" ..
            " - " .. T("Cost Metric Sample: Rank 4 Swipe requires 25 TP values.")
    end

    local petName = UnitName("pet")
    local petLevel = UnitLevel("pet")
    local loyaltyName = ""

    if C_PetInfo and C_PetInfo.GetPetLoyalty then
        loyaltyName = C_PetInfo.GetPetLoyalty() or T("Unknown")
    elseif GetPetLoyalty then
        loyaltyName = GetPetLoyalty() or T("Unknown")
    else
        loyaltyName = T("Loyal Companion")
    end

    local loyaltyIndex = self:GetLoyaltyIndex(loyaltyName)
    local totalTP = self:CalculateTotalPoints(petLevel, loyaltyIndex)
    local maxPossibleTP = self:CalculateTotalPoints(petLevel, MAX_LOYALTY_RANK)

    local text = string.format("|cFFFFD100%s - %s:|r\n", petName, T("Current Matrix Status"))
    text = text .. string.format(" - %s |cFFFFFFFF%d|r | %s: |cFFFFFFFF%s|r\n", T("Level Check:"), petLevel, T("Loyalty Alignment"), loyaltyName)
    text = text .. string.format(" - %s |cFF00FF00%d %s|r\n", T("Realized Training Points:"), totalTP, T("TP"))

    if loyaltyIndex < MAX_LOYALTY_RANK then
        local missingTP = maxPossibleTP - totalTP
        text = text .. string.format(" - %s |cFFFFCC00+%d %s|r\n", T("Deficit to Best Friend Cap:"), missingTP, T("TP Pending"))
    else
        text = text .. " - |cFF00FF00" .. T("Maximum Loyalty Matrix Yield Attained!") .. "|r\n"
    end

    return text
end
