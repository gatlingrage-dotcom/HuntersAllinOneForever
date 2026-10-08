-- ============================================================================
-- Project: HuntersAllinOneForever
-- File: src/hunter_companion_window.lua
-- Description: Core dashboard companion window handling layout groups,
--              macro injectors, and advanced pet matrix sub-panels.
-- ============================================================================

HAOF = HAOF or {}
HAOF.HunterCompanionWindow = {}
local HunterCompanionWindow = HAOF.HunterCompanionWindow
local BOOK_GOLD = { 0.95, 0.72, 0.34 }
local MAX_PET_LEVEL = 60
local function T(text)
    return HAOF.T and HAOF.T(text) or text
end
local AMMO_RANKS = {
    arrow = {
        { Name = "Rough Arrow", RequiredLevel = 1 },
        { Name = "Sharp Arrow", RequiredLevel = 10 },
        { Name = "Jagged Arrow", RequiredLevel = 20 },
        { Name = "Razor Arrow", RequiredLevel = 30 },
        { Name = "Wicked Arrow", RequiredLevel = 40 },
        { Name = "Thorium Headed Arrow", RequiredLevel = 52 },
    },
    bullet = {
        { Name = "Light Shot", RequiredLevel = 1 },
        { Name = "Heavy Shot", RequiredLevel = 10 },
        { Name = "Solid Shot", RequiredLevel = 20 },
        { Name = "Mithril Gyro-Shot", RequiredLevel = 30 },
        { Name = "Thorium Shells", RequiredLevel = 52 },
    },
}

local function GetPetXP()
    local currentXP, requiredXP
    if type(GetPetExperience) == "function" then
        currentXP, requiredXP = GetPetExperience()
    end
    if (not currentXP or not requiredXP) and UnitXP and UnitXPMax then
        currentXP = UnitXP("pet")
        requiredXP = UnitXPMax("pet")
    end
    return tonumber(currentXP), tonumber(requiredXP)
end

local function IsSecretValue(value)
    if type(issecretvalue) ~= "function" then
        return false
    end
    local ok, isSecret = pcall(issecretvalue, value)
    return ok and isSecret
end

local function IsSafePetStat(value)
    local valueType = type(value)
    return not IsSecretValue(value) and (valueType == "number" or valueType == "string")
end

local function AddPetStatLine(lines, formatString, ...)
    local values = { ... }
    for _, value in ipairs(values) do
        if not IsSafePetStat(value) then
            return false
        end
    end

    local ok, line = pcall(string.format, formatString, ...)
    if not ok or IsSecretValue(line) or type(line) ~= "string" then
        return false
    end

    table.insert(lines, line)
    return true
end

local function GetItemInfoCompat(item)
    if type(GetItemInfo) == "function" then
        return GetItemInfo(item)
    end
    if C_Item and type(C_Item.GetItemInfo) == "function" then
        return C_Item.GetItemInfo(item)
    end
end

local function GetAmmoGuideText()
    local ammoSlot = GetInventorySlotInfo("AmmoSlot")
    local ammoID = ammoSlot and GetInventoryItemID("player", ammoSlot)
    local playerLevel = tonumber(UnitLevel("player")) or 1
    local currentAmmo = ammoID and GetItemInfoCompat(ammoID)

    if not ammoID then
        return "|cFFFFD100" .. T("Ammo:") .. "|r " .. T("No ammunition equipped.")
    elseif type(GetItemInfo) ~= "function"
        and not (C_Item and type(C_Item.GetItemInfo) == "function") then
        return "|cFFFFD100" .. T("Ammo:") .. "|r " .. T("Item details are unavailable on this client.")
    elseif not currentAmmo then
        return "|cFFFFD100" .. T("Ammo:") .. "|r " .. T("Loading ammunition details...")
    end

    local ammoName, _, _, ammoItemLevel, ammoRequiredLevel, _, ammoSubType =
        GetItemInfoCompat(ammoID)
    ammoRequiredLevel = tonumber(ammoRequiredLevel) or 0
    ammoItemLevel = tonumber(ammoItemLevel) or ammoRequiredLevel
    local ammoCount = HAOF.AmmoAlertModule
        and HAOF.AmmoAlertModule.GetAmmoCount
        and HAOF.AmmoAlertModule:GetAmmoCount()
    local levelStatus = playerLevel >= ammoRequiredLevel
        and string.format("|cFF80FF80%s|r", string.format(T("Usable (req. %d)"), ammoRequiredLevel))
        or string.format("|cFFFF4040%s|r", string.format(T("Requires level %d"), ammoRequiredLevel))

    local bestAmmoName
    local bestAmmoRequiredLevel = -1
    local bestAmmoItemLevel = -1
    if ammoSubType and GetContainerNumSlots and GetContainerItemID then
        for bag = 0, 4 do
            local slots = GetContainerNumSlots(bag) or 0
            for slot = 1, slots do
                local itemID = GetContainerItemID(bag, slot)
                if itemID and itemID ~= ammoID then
                    local itemName, _, _, itemLevel, requiredLevel, _, subType =
                        GetItemInfoCompat(itemID)
                    requiredLevel = tonumber(requiredLevel) or 0
                    itemLevel = tonumber(itemLevel) or requiredLevel
                    if itemName and subType == ammoSubType and requiredLevel <= playerLevel
                        and (requiredLevel > bestAmmoRequiredLevel
                            or (requiredLevel == bestAmmoRequiredLevel
                                and itemLevel > bestAmmoItemLevel)) then
                        bestAmmoName = itemName
                        bestAmmoRequiredLevel = requiredLevel
                        bestAmmoItemLevel = itemLevel
                    end
                end
            end
        end
    end

    local ammoLine = string.format(
        "|cFFFFD100%s|r %s%s (%s)",
        T("Ammo:"),
        ammoName,
        ammoCount and string.format(" x%d", ammoCount) or "",
        levelStatus
    )
    local ammoKind = string.lower(ammoSubType or "")
    if ammoKind == "arrows" then
        ammoKind = "arrow"
    elseif ammoKind == "bullets" then
        ammoKind = "bullet"
    end

    local ammoRanks = AMMO_RANKS[ammoKind]
    local currentRankIndex
    if ammoRanks then
        for index, rank in ipairs(ammoRanks) do
            if rank.Name == ammoName or rank.RequiredLevel == ammoRequiredLevel then
                currentRankIndex = index
                break
            end
        end
    end

    local nextRank
    if ammoRanks then
        local firstCandidate = currentRankIndex and (currentRankIndex + 1) or 1
        for index = firstCandidate, #ammoRanks do
            local rank = ammoRanks[index]
            if rank.RequiredLevel <= playerLevel then
                nextRank = rank
            elseif not nextRank then
                nextRank = rank
                break
            else
                break
            end
        end
    end

    local nextRankLine
    if nextRank then
        nextRankLine = string.format(
            "|cFFFFD100%s|r %s (%s)",
            string.format(T("Next %s rank:"), T(ammoKind)),
            T(nextRank.Name),
            playerLevel >= nextRank.RequiredLevel
                and T("usable now")
                or string.format(T("at level %d"), nextRank.RequiredLevel)
        )
    else
        nextRankLine = "|cFFFFD100" .. T("Next ammo rank:") .. "|r " .. T("No higher standard rank listed.")
    end

    if bestAmmoName and (bestAmmoRequiredLevel > ammoRequiredLevel
        or (bestAmmoRequiredLevel == ammoRequiredLevel and bestAmmoItemLevel > ammoItemLevel)) then
        ammoLine = ammoLine .. string.format("  |cFFFFD100%s|r %s", T("Upgrade carried:"), bestAmmoName)
    end

    return nextRankLine .. "\n" .. ammoLine
end

local function StyleJournalButton(button)
    button:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
    button:GetNormalTexture():SetVertexColor(0.24, 0.14, 0.075, 1)
    button:SetPushedTexture("Interface\\Buttons\\WHITE8X8")
    button:GetPushedTexture():SetVertexColor(0.12, 0.07, 0.035, 1)
    button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8", "ADD")
    button:GetHighlightTexture():SetVertexColor(BOOK_GOLD[1], BOOK_GOLD[2], BOOK_GOLD[3], 0.28)

    local label = button:GetFontString()
    if label then
        label:SetFontObject("GameFontNormalSmall")
        label:SetTextColor(1, 0.91, 0.72)
    end
end

HunterCompanionWindow.MacroData = {
    {
        Name = "HAOF_AutoShot",
        LegacyNames = { "HAOF_AutoShot" },
        Label = "Auto Shot (don't toggle off)",
        Body = "/cast !Auto Shot",
    },
    {
        Name = "HAOF_MarkPet",
        LegacyNames = { "HAOF_MarkPet" },
        Label = "Hunter's Mark + Pet Attack",
        Body = "/cast Hunter's Mark\n/petattack",
    },
    {
        Name = "HAOF_PetShot",
        Label = "Pet Attack + Auto Shot",
        Body = "/petattack\n/cast !Auto Shot",
    },
    {
        Name = "HAOF_PetAttack",
        LegacyNames = { "HAOF_PetAttack" },
        Label = "Pet Attack",
        Body = "/petattack",
    },
    {
        Name = "HAOF_PetFollow",
        LegacyNames = { "HAOF_PetFollow" },
        Label = "Pet Follow",
        Body = "/petfollow",
    },
    {
        Name = "HAOF_PetPassive",
        LegacyNames = { "HAOF_PetPassive" },
        Label = "Pet Passive",
        Body = "/petpassive",
    },
    {
        Name = "HAOF_MendPet",
        LegacyNames = { "HAOF_MendPet" },
        Label = "Mend Pet",
        Body = "/cast Mend Pet",
    },
    {
        Name = "HAOF_Aspect",
        LegacyNames = { "HAOF_AspectHawk", "HAOF_Monkey" },
        Label = "Aspect Switch (Shift for Monkey)",
        Body = "/cast [mod:shift] Aspect of the Monkey; Aspect of the Hawk",
    },
    {
        Name = "HAOF_Trap",
        LegacyNames = { "HAOF_TrapReset" },
        Label = "Freezing Trap Setup",
        Body = "/petpassive\n/petfollow\n/cast Freezing Trap",
    },
    {
        Name = "HAOF_Feign",
        LegacyNames = {},
        Label = "Feign Death",
        Body = "/stopcasting\n/cast Feign Death",
    },
    {
        Name = "HAOF_Concuss",
        LegacyNames = { "HAOF_Concussive" },
        Label = "Concussive Shot",
        Body = "/cast Concussive Shot",
    },
    {
        Name = "HAOF_WingClip",
        LegacyNames = { "HAOF_WingClip" },
        Label = "Wing Clip + Auto Attack",
        Body = "/cast Wing Clip\n/startattack",
    },
    {
        Name = "HAOF_Tranq",
        LegacyNames = { "HAOF_TranqShot" },
        Label = "Tranquilizing Shot",
        Body = "/cast Tranquilizing Shot",
    },
    {
        Name = "HAOF_Disengage",
        LegacyNames = { "HAOF_Disengage" },
        Label = "Disengage",
        Body = "/cast Disengage",
    },
    {
        Name = "HAOF_Flare",
        LegacyNames = { "HAOF_Flare" },
        Label = "Flare",
        Body = "/cast Flare",
    },
    {
        Name = "HAOF_Track",
        LegacyNames = { "HAOF_TrackBeasts" },
        Label = "Track Beasts",
        Body = "/cast Track Beasts",
    },
    {
        Name = "HAOF_Raptor",
        LegacyNames = { "HAOF_Weave" },
        Label = "Raptor Strike + Auto Attack",
        Body = "/cast Raptor Strike\n/startattack",
    },
}

function HunterCompanionWindow:GetMacroIndex(data)
    local index = GetMacroIndexByName(data.Name)
    if index and index > 0 then
        return index
    end
    for _, legacyName in ipairs(data.LegacyNames or {}) do
        index = GetMacroIndexByName(legacyName)
        if index and index > 0 then
            return index
        end
    end
end

function HunterCompanionWindow:RemoveLegacyMacros(data)
    for _, legacyName in ipairs(data.LegacyNames or {}) do
        if legacyName ~= data.Name then
            local index = GetMacroIndexByName(legacyName)
            if index and index > 0 then
                DeleteMacro(index)
            end
        end
    end
end

function HunterCompanionWindow:IsMacroInjected(macroName)
    local index = GetMacroIndexByName(macroName)
    return (index and index > 0)
end
function HunterCompanionWindow:RefreshMacroPage(container)
    if not container or not container:IsShown() then return end

    if container.Elements then
        for _, obj in ipairs(container.Elements) do obj:Hide() end
    end
    container.Elements = {}

    local SpaceHandler = HAOF.MacroSpaceHandler
    local statusText = SpaceHandler and SpaceHandler:GetSpaceWarningText() or "|cFF888888" .. T("[Checking Space...]") .. "|r"

    local storageStatusLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    storageStatusLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    storageStatusLabel:SetText(statusText)
    storageStatusLabel:SetTextColor(1, 0.91, 0.75)
    table.insert(container.Elements, storageStatusLabel)

    for i, data in ipairs(self.MacroData) do
        local macroIndex = self:GetMacroIndex(data)
        local injected = macroIndex ~= nil
        local macroName, _, macroBody
        if macroIndex then
            macroName, _, macroBody = GetMacroInfo(macroIndex)
        end
        local isCurrent = injected and macroName == data.Name and macroBody == data.Body
        local column = math.floor((i - 1) / 9)
        local row = (i - 1) % 9
        local columnOffset = column * 282
        local yOffset = -(row * 35) - 31

        local checkbox = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
        checkbox:SetSize(24, 24)
        checkbox:SetPoint("TOPLEFT", container, "TOPLEFT", columnOffset + 248, yOffset + 1)
        checkbox:SetChecked(isCurrent)

        local lbl = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("TOPLEFT", container, "TOPLEFT", columnOffset, yOffset)
        lbl:SetWidth(240)
        local statusText = not injected and "|cFF888888" .. T("[Not added]") .. "|r"
            or (isCurrent and "|cFF00FF00" .. T("[Added]") .. "|r"
                or "|cFFFFCC00" .. T("[Update available]") .. "|r")
        lbl:SetText(string.format("|cFFFFD100%s|r\n%s", T(data.Label), statusText))
        lbl:SetTextColor(1, 0.91, 0.75)
        table.insert(container.Elements, lbl)

        checkbox:SetScript("OnClick", function(selfButton)
            if InCombatLockdown() then
                print("|cFFFF0000[HAOF]: " .. T("Cannot modify macros while in combat!") .. "|r")
                self:RefreshMacroPage(container)
                return
            end

            if selfButton:GetChecked() then
                if macroIndex then
                    EditMacro(macroIndex, data.Name, "INV_Misc_QuestionMark", data.Body)
                    self:RemoveLegacyMacros(data)
                    print(string.format("|cFF00FF00[HAOF]: %s|r", string.format(T("Updated macro %s."), data.Name)))
                else
                    if SpaceHandler and not SpaceHandler:CanInjectMacro(data.Name) then
                        print("|cFFFF0000[HAOF Error]: " .. T("Cannot append macro, target storage log is full.") .. "|r")
                        UIErrorsFrame:AddMessage("HAOF: " .. T("Macro list is full!"), 1.0, 0.1, 0.1, 1.0)
                        self:RefreshMacroPage(container)
                        return
                    end

                    CreateMacro(data.Name, "INV_Misc_QuestionMark", data.Body, true)
                    print(string.format("|cFF00FF00[HAOF]: %s|r", string.format(T("Successfully added macro %s!"), data.Name)))
                end
                if not InCombatLockdown() and ShowMacroFrame then
                    ShowMacroFrame()
                    if MacroFrame and MacroFrame_SelectTab then
                        MacroFrame_SelectTab(2)
                    end
                end
            elseif isCurrent and macroIndex then
                DeleteMacro(macroIndex)
                self:RemoveLegacyMacros(data)
                print(string.format("|cFFFF3333[HAOF]: %s|r", string.format(T("Removed macro %s from character profile."), data.Name)))
            end
            self:RefreshMacroPage(container)
        end)
        table.insert(container.Elements, checkbox)
    end
end

function HunterCompanionWindow:PopulateText(fontString)
    if not fontString then
        return
    end

    local playerLevel = tonumber(UnitLevel("player")) or 1
    local text = string.format("|cFFFFD100%s|r\n%s\n\n", T("HUNTER GEAR GUIDE"), string.format(T("Player Level: %d / 60"), playerLevel))

    if playerLevel < 60 then
        text = text
            .. "|cFFFFD100" .. T("LEVELING PRIORITIES") .. "|r\n"
            .. T("1. Ranged weapon: favor a bow or gun with higher DPS that you can equip now. Keep your ammo current and train its weapon skill.") .. "\n\n"
            .. T("2. Agility: a strong all-around Hunter stat that improves ranged attack power and critical strike.") .. "\n\n"
            .. T("3. Stamina: useful when tougher enemies are making you or your pet less survivable.") .. "\n\n"
            .. T("4. Other upgrades: compare the item you have equipped with the actual replacement. Prefer useful stats without giving up a major weapon upgrade or spending heavily on gear you will replace soon.") .. "\n\n"
            .. "|cFFFFD100" .. T("QUICK CHECK") .. "|r\n"
            .. T("Can you equip it now? Does it improve your weapon DPS or useful stats? If not, save your gold.")
    else
        text = text
            .. "|cFFFFD100" .. T("LEVEL-60 PRIORITIES") .. "|r\n"
            .. T("1. Ranged weapon DPS: compare weapons available to you; keep ammo current.") .. "\n\n"
            .. T("2. Hit: against level-63 raid bosses, the standard ranged hit cap is 9%. Account for hit from your talents and gear; do not keep stacking it past your applicable cap.") .. "\n\n"
            .. T("3. Damage stats: after hit, compare Agility, ranged attack power, and critical strike for your build and content.") .. "\n\n"
            .. T("4. Survivability: Stamina can help in content where you take damage.") .. "\n\n"
            .. "|cFFFFD100" .. T("ITEM CHECK") .. "|r\n"
            .. T("Check equip requirements and compare the in-game item stats. Exact item lists are omitted because WoW Forever may use custom itemization.")
    end

    fontString:SetText(text)
end
function HunterCompanionWindow:InitializePetXPBar()
    if self.PetXPNameplateBar then
        return
    end

    local petFrame = _G.PetFrame
    if not petFrame then
        return
    end

    local xpBar = CreateFrame("StatusBar", "HAOF_PetXPNameplateBar", UIParent)
    xpBar:SetFrameStrata("HIGH")
    xpBar:SetHeight(12)
    local petHealthBar = _G.PetFrameHealthBar
    xpBar:SetPoint("TOPLEFT", petFrame, "BOTTOMLEFT", 0, -3)
    xpBar:SetWidth(math.max(80, petFrame:GetWidth()))
    xpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    xpBar:SetStatusBarColor(0.35, 0.18, 0.62, 1)
    xpBar:SetMinMaxValues(0, 1)
    xpBar:SetValue(0)
    xpBar:EnableMouse(false)

    local background = xpBar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(xpBar)
    background:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    background:SetVertexColor(0.08, 0.06, 0.1, 0.9)

    local text = xpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", xpBar, "LEFT", 3, 0)
    text:SetJustifyH("LEFT")
    text:SetTextColor(1, 1, 1)

    self.PetXPNameplateEnabled = self.PetXPNameplateEnabled ~= false

    local function RefreshPetXP()
        local petLevel = tonumber(UnitLevel("pet"))
        if not self.PetXPNameplateEnabled or not UnitExists("pet")
            or not petLevel or petLevel >= MAX_PET_LEVEL then
            xpBar:Hide()
            return
        end

        local currentXP, requiredXP = GetPetXP()
        if currentXP and requiredXP and requiredXP > 0 then
            xpBar:SetMinMaxValues(0, requiredXP)
            xpBar:SetValue(math.min(currentXP, requiredXP))
            text:SetText(string.format(
                "XP: %d / %d (%d%%)",
                currentXP,
                requiredXP,
                math.floor(currentXP / requiredXP * 100)
            ))
            xpBar:Show()
        else
            xpBar:SetMinMaxValues(0, 1)
            xpBar:SetValue(0)
            text:SetText(T("Pet XP unavailable"))
            xpBar:Show()
        end
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("UNIT_PET")
    events:RegisterEvent("PET_BAR_UPDATE")
    events:RegisterEvent("UNIT_PET_EXPERIENCE")
    events:RegisterEvent("PLAYER_LEVEL_UP")
    events:SetScript("OnEvent", RefreshPetXP)

    self.PetXPNameplateBar = xpBar
    self.PetXPNameplateEvents = events
    self.RefreshPetXPNameplate = RefreshPetXP
    RefreshPetXP()
end

function HunterCompanionWindow:SetPetXPNameplateEnabled(enabled)
    self.PetXPNameplateEnabled = enabled and true or false
    self:InitializePetXPBar()
    if self.RefreshPetXPNameplate then
        self.RefreshPetXPNameplate()
    end
end

function HunterCompanionWindow:CreateJournalWindow()
    local frame = CreateFrame("Frame", "HuntersAllinOneForever_Journal", UIParent, "BackdropTemplate")
    frame:SetSize(700, 640)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local Settings = HAOF.SettingsManager
        if Settings and Settings.SaveWindowPosition then Settings:SaveWindowPosition(self) end
    end)

    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    frame:SetBackdropColor(0.12, 0.065, 0.035, 1)
    frame:SetBackdropBorderColor(0.67, 0.43, 0.16, 1)

    local pageLeft = frame:CreateTexture(nil, "BACKGROUND")
    pageLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
    pageLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 26, -47)
    pageLeft:SetSize(315, 494)
    pageLeft:SetVertexColor(0.29, 0.20, 0.12, 1)

    local pageRight = frame:CreateTexture(nil, "BACKGROUND")
    pageRight:SetTexture("Interface\\Buttons\\WHITE8X8")
    pageRight:SetPoint("TOPLEFT", pageLeft, "TOPRIGHT", 8, 0)
    pageRight:SetSize(315, 494)
    pageRight:SetVertexColor(0.29, 0.20, 0.12, 1)

    local pageGutter = frame:CreateTexture(nil, "BACKGROUND")
    pageGutter:SetTexture("Interface\\Buttons\\WHITE8X8")
    pageGutter:SetPoint("TOPLEFT", pageLeft, "TOPRIGHT")
    pageGutter:SetSize(8, 494)
    pageGutter:SetVertexColor(0.11, 0.065, 0.035, 0.85)

    local headerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    headerText:SetPoint("TOP", frame, "TOP", 0, -10)
    headerText:SetText(T("Hunter's Field Journal"))
    headerText:SetTextColor(BOOK_GOLD[1], BOOK_GOLD[2], BOOK_GOLD[3])
    headerText:SetShadowColor(0, 0, 0, 1)
    headerText:SetShadowOffset(1, -1)

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", headerText, "BOTTOM", 0, -2)
    subtitle:SetText(T("COMPANION  |  GEAR  |  PET LORE"))
    subtitle:SetTextColor(0.82, 0.68, 0.48)

    local brandIcon = frame:CreateTexture(nil, "ARTWORK")
    brandIcon:SetTexture("Interface\\Icons\\Ability_Hunter_Snipershot")
    brandIcon:SetSize(18, 18)
    brandIcon:SetPoint("RIGHT", headerText, "LEFT", -6, 0)

    local brandIconBorder = frame:CreateTexture(nil, "BACKGROUND")
    brandIconBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    brandIconBorder:SetSize(22, 22)
    brandIconBorder:SetPoint("CENTER", brandIcon, "CENTER", 0, 0)

    local gearContainer = CreateFrame("Frame", nil, frame)
    gearContainer:SetSize(285, 390)
    gearContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -80)
    frame.GearContainer = gearContainer

    local ammoFooter = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ammoFooter:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -540)
    ammoFooter:SetSize(620, 38)
    ammoFooter:SetJustifyH("LEFT")
    ammoFooter:SetJustifyV("TOP")
    ammoFooter:SetTextColor(1, 0.91, 0.75)
    frame.AmmoFooter = ammoFooter

    local function RefreshAmmoFooter()
        frame.AmmoFooter:SetText(GetAmmoGuideText())
    end

    local CooldownTracker = HAOF.HunterCooldownTracker

    local optionsContainer = CreateFrame("Frame", nil, frame)
    optionsContainer:SetSize(620, 475)
    optionsContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -80)
    optionsContainer:Hide()
    frame.OptionsContainer = optionsContainer

    local optionTitle = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optionTitle:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 0, 0)
    optionTitle:SetText("|cFFFFD100" .. T("ADDON OPTIONS") .. "|r")

    local function CreateOptionSection(title, x, y)
        local heading = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        heading:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", x, y)
        heading:SetText("|cFFFFD100" .. title .. "|r")
    end
    CreateOptionSection(T("AMMO ALERTS"), 0, -30)
    CreateOptionSection(T("COOLDOWN TRACKER"), 280, -30)
    CreateOptionSection(T("HAWK TRACKER"), 0, -160)

    local sectionDivider = optionsContainer:CreateTexture(nil, "ARTWORK")
    sectionDivider:SetColorTexture(0.67, 0.43, 0.16, 0.65)
    sectionDivider:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 268, -26)
    sectionDivider:SetSize(1, 435)

    local function CreateOptionToggle(labelText, getValue, setValue, x, y, width, isAvailable)
        local label = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", optionsContainer, "TOPLEFT", x + 28, y - 11)
        label:SetWidth(width - 28)
        label:SetJustifyH("LEFT")

        local checkbox = CreateFrame("CheckButton", nil, optionsContainer, "UICheckButtonTemplate")
        checkbox:SetSize(24, 24)
        checkbox:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", x, y - 3)

        local function Refresh()
            local available = not isAvailable or isAvailable()
            checkbox:SetChecked(getValue() and true or false)
            checkbox:SetEnabled(available)
            label:SetText(available and T(labelText)
                or "|cFF888888" .. string.format(T("Not learned - %s"), T(labelText)) .. "|r")
            label:EnableMouse(available)
        end
        local function SetValue(value)
            if isAvailable and not isAvailable() then
                return
            end
            setValue(value and true or false)
            Refresh()
            RefreshAmmoFooter()
            if CooldownTracker and CooldownTracker.RefreshSeparateWindow then
                CooldownTracker:RefreshSeparateWindow()
            end
        end
        checkbox:SetScript("OnClick", function(self)
            SetValue(self:GetChecked())
        end)
        label:EnableMouse(true)
        label:SetScript("OnMouseUp", function(_, mouseButton)
            if mouseButton == "LeftButton" and (not isAvailable or isAvailable()) then
                SetValue(not getValue())
            end
        end)
        Refresh()
        return checkbox, Refresh
    end

    local function GetAddonOptions()
        local Settings = HAOF.SettingsManager
        return Settings and Settings:GetOptions()
    end

    local function SetAmmoThreshold(key, amount)
        local settings = GetAddonOptions()
        local ammoSettings = settings and settings.AmmoAlert
        if not ammoSettings then
            return
        end
        amount = math.max(0, math.floor(amount))
        if key == "CriticalThreshold" then
            ammoSettings.CriticalThreshold = amount
            ammoSettings.WarningThreshold = math.max(
                tonumber(ammoSettings.WarningThreshold) or 200,
                amount
            )
        else
            ammoSettings.WarningThreshold = math.max(
                tonumber(ammoSettings.CriticalThreshold) or 50,
                amount
            )
        end
        if HAOF.AmmoAlertModule and HAOF.AmmoAlertModule.Refresh then
            HAOF.AmmoAlertModule:Refresh()
        end
        RefreshAmmoFooter()
    end

    local settings = GetAddonOptions()
    CreateOptionToggle("Low-ammo alerts", function()
        return settings.AmmoAlert.Enabled
    end, function(value)
        settings.AmmoAlert.Enabled = value
        if HAOF.AmmoAlertModule and HAOF.AmmoAlertModule.Refresh then
            HAOF.AmmoAlertModule:Refresh()
        end
    end, 0, -55, 260)

    local criticalLabel = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    criticalLabel:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 0, -88)
    criticalLabel:SetText(T("Critical ammo warning:"))
    criticalLabel:SetWidth(190)
    local criticalValue = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    criticalValue:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 166, -88)
    local warningValue = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    warningValue:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 166, -117)
    local function RefreshThresholdLabels()
        local ammoSettings = GetAddonOptions().AmmoAlert
        criticalValue:SetText(tostring(ammoSettings.CriticalThreshold))
        warningValue:SetText(tostring(ammoSettings.WarningThreshold))
    end
    local function CreateThresholdButton(text, x, y, callback)
        local button = CreateFrame("Button", nil, optionsContainer, "UIPanelButtonTemplate")
        button:SetSize(24, 20)
        button:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", x, y)
        button:SetText(text)
        StyleJournalButton(button)
        button:SetScript("OnClick", callback)
    end
    CreateThresholdButton("-", 200, -85, function()
        SetAmmoThreshold("CriticalThreshold", settings.AmmoAlert.CriticalThreshold - 10)
        RefreshThresholdLabels()
    end)
    CreateThresholdButton("+", 229, -85, function()
        SetAmmoThreshold("CriticalThreshold", settings.AmmoAlert.CriticalThreshold + 10)
        RefreshThresholdLabels()
    end)

    local warningLabel = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    warningLabel:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 0, -117)
    warningLabel:SetText(T("Ammo caution threshold:"))
    warningLabel:SetWidth(190)
    CreateThresholdButton("-", 200, -114, function()
        SetAmmoThreshold("WarningThreshold", settings.AmmoAlert.WarningThreshold - 50)
        RefreshThresholdLabels()
    end)
    CreateThresholdButton("+", 229, -114, function()
        SetAmmoThreshold("WarningThreshold", settings.AmmoAlert.WarningThreshold + 50)
        RefreshThresholdLabels()
    end)
    RefreshThresholdLabels()

    CreateOptionToggle("Show only in combat", function()
        return settings.HawkTracker.ShowOnlyInCombat
    end, function(value)
        settings.HawkTracker.ShowOnlyInCombat = value
        if HAOF.HawkTracker and HAOF.HawkTracker.RefreshWindow then
            HAOF.HawkTracker:RefreshWindow()
        end
    end, 0, -188, 260)

    CreateOptionToggle("Lock Hawk status window position", function()
        return settings.HawkTracker.WindowLocked
    end, function(value)
        if HAOF.HawkTracker and HAOF.HawkTracker.SetWindowLocked then
            HAOF.HawkTracker:SetWindowLocked(value)
        else
            settings.HawkTracker.WindowLocked = value
        end
    end, 0, -219, 260)

    local hawkOpacityLabel = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hawkOpacityLabel:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 0, -252)
    hawkOpacityLabel:SetText(T("Hawk window opacity:"))
    hawkOpacityLabel:SetWidth(220)

    local hawkOpacityValue = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hawkOpacityValue:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 175, -252)
    hawkOpacityValue:SetJustifyH("RIGHT")
    hawkOpacityValue:SetWidth(55)

    local hawkOpacitySlider = CreateFrame("Slider", nil, optionsContainer)
    hawkOpacitySlider:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 0, -274)
    hawkOpacitySlider:SetSize(240, 26)
    hawkOpacitySlider:SetOrientation("HORIZONTAL")
    hawkOpacitySlider:SetMinMaxValues(0, 100)
    hawkOpacitySlider:SetValueStep(1)
    hawkOpacitySlider:SetObeyStepOnDrag(true)
    hawkOpacitySlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    hawkOpacitySlider:GetThumbTexture():SetSize(20, 24)
    local sliderTrack = hawkOpacitySlider:CreateTexture(nil, "BACKGROUND")
    sliderTrack:SetColorTexture(0.08, 0.06, 0.04, 1)
    sliderTrack:SetPoint("LEFT", hawkOpacitySlider, "LEFT", 1, 0)
    sliderTrack:SetPoint("RIGHT", hawkOpacitySlider, "RIGHT", -1, 0)
    sliderTrack:SetHeight(10)
    local sliderFill = hawkOpacitySlider:CreateTexture(nil, "ARTWORK")
    sliderFill:SetColorTexture(0.95, 0.72, 0.34, 1)
    sliderFill:SetPoint("LEFT", sliderTrack, "LEFT", 0, 0)
    sliderFill:SetHeight(10)

    local opacityMinimum = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    opacityMinimum:SetPoint("TOPLEFT", hawkOpacitySlider, "BOTTOMLEFT", 0, -3)
    opacityMinimum:SetText("0%")
    local opacityMaximum = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    opacityMaximum:SetPoint("TOPRIGHT", hawkOpacitySlider, "BOTTOMRIGHT", 0, -3)
    opacityMaximum:SetText("100%")

    local function RefreshHawkOpacity()
        local opacity = math.max(0, math.min(100, math.floor(tonumber(settings.HawkTracker.WindowOpacity) or 94)))
        hawkOpacitySlider:SetValue(opacity)
        hawkOpacityValue:SetText(opacity .. "%")
        sliderFill:SetWidth(math.max(1, 238 * opacity / 100))
    end
    hawkOpacitySlider:SetScript("OnValueChanged", function(_, value)
        value = math.max(0, math.min(100, math.floor(value + 0.5)))
        settings.HawkTracker.WindowOpacity = value
        hawkOpacityValue:SetText(value .. "%")
        if HAOF.HawkTracker and HAOF.HawkTracker.SetWindowOpacity then
            HAOF.HawkTracker:SetWindowOpacity(value)
        end
    end)
    RefreshHawkOpacity()

    CreateOptionToggle("Show only in combat", function()
        return settings.CooldownTracker.ShowOnlyInCombat
    end, function(value)
        settings.CooldownTracker.ShowOnlyInCombat = value
        if CooldownTracker and CooldownTracker.RefreshSeparateWindow then
            CooldownTracker:RefreshSeparateWindow()
        end
    end, 280, -55, 260)

    local cooldownOpacityLabel = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cooldownOpacityLabel:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 280, -88)
    cooldownOpacityLabel:SetText(T("Cooldown window opacity:"))
    cooldownOpacityLabel:SetWidth(220)

    local cooldownOpacityValue = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cooldownOpacityValue:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 455, -88)
    cooldownOpacityValue:SetJustifyH("RIGHT")
    cooldownOpacityValue:SetWidth(55)

    local cooldownOpacitySlider = CreateFrame("Slider", nil, optionsContainer)
    cooldownOpacitySlider:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 280, -110)
    cooldownOpacitySlider:SetSize(240, 26)
    cooldownOpacitySlider:SetOrientation("HORIZONTAL")
    cooldownOpacitySlider:SetMinMaxValues(0, 100)
    cooldownOpacitySlider:SetValueStep(1)
    cooldownOpacitySlider:SetObeyStepOnDrag(true)
    cooldownOpacitySlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    cooldownOpacitySlider:GetThumbTexture():SetSize(20, 24)
    local cooldownSliderTrack = cooldownOpacitySlider:CreateTexture(nil, "BACKGROUND")
    cooldownSliderTrack:SetColorTexture(0.08, 0.06, 0.04, 1)
    cooldownSliderTrack:SetPoint("LEFT", cooldownOpacitySlider, "LEFT", 1, 0)
    cooldownSliderTrack:SetPoint("RIGHT", cooldownOpacitySlider, "RIGHT", -1, 0)
    cooldownSliderTrack:SetHeight(10)
    local cooldownSliderFill = cooldownOpacitySlider:CreateTexture(nil, "ARTWORK")
    cooldownSliderFill:SetColorTexture(0.95, 0.72, 0.34, 1)
    cooldownSliderFill:SetPoint("LEFT", cooldownSliderTrack, "LEFT", 0, 0)
    cooldownSliderFill:SetHeight(10)

    local cooldownOpacityMinimum = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    cooldownOpacityMinimum:SetPoint("TOPLEFT", cooldownOpacitySlider, "BOTTOMLEFT", 0, -3)
    cooldownOpacityMinimum:SetText("0%")
    local cooldownOpacityMaximum = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    cooldownOpacityMaximum:SetPoint("TOPRIGHT", cooldownOpacitySlider, "BOTTOMRIGHT", 0, -3)
    cooldownOpacityMaximum:SetText("100%")

    local function RefreshCooldownOpacity()
        local opacity = math.max(0, math.min(100, math.floor(tonumber(settings.CooldownTracker.WindowOpacity) or 94)))
        cooldownOpacitySlider:SetValue(opacity)
        cooldownOpacityValue:SetText(opacity .. "%")
        cooldownSliderFill:SetWidth(math.max(1, 238 * opacity / 100))
    end
    cooldownOpacitySlider:SetScript("OnValueChanged", function(_, value)
        value = math.max(0, math.min(100, math.floor(value + 0.5)))
        settings.CooldownTracker.WindowOpacity = value
        cooldownOpacityValue:SetText(value .. "%")
        cooldownSliderFill:SetWidth(math.max(1, 238 * value / 100))
        if CooldownTracker and CooldownTracker.SetWindowOpacity then
            CooldownTracker:SetWindowOpacity(value)
        end
    end)
    RefreshCooldownOpacity()

    CreateOptionToggle("Lock cooldown window position", function()
        return settings.CooldownTracker.WindowLocked
    end, function(value)
        if CooldownTracker and CooldownTracker.SetWindowLocked then
            CooldownTracker:SetWindowLocked(value)
        else
            settings.CooldownTracker.WindowLocked = value
        end
    end, 280, -153, 260)

    local abilitySettings = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    abilitySettings:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 280, -184)
    abilitySettings:SetText("|cFFFFD100" .. T("TRACKED ABILITIES") .. "|r")
    local refreshAbilityToggles = {}
    if CooldownTracker and CooldownTracker.GetAbilities then
        for index, ability in ipairs(CooldownTracker:GetAbilities()) do
            local _, refresh = CreateOptionToggle(ability.Name, function()
                return settings.CooldownTracker.Abilities[ability.Key]
            end, function(value)
                settings.CooldownTracker.Abilities[ability.Key] = value
                if CooldownTracker and CooldownTracker.RefreshSeparateWindow then
                    CooldownTracker:RefreshSeparateWindow()
                end
            end, 280, -208 - ((index - 1) * 24), 260, function()
                return not CooldownTracker.IsAbilityKnown
                    or CooldownTracker:IsAbilityKnown(ability)
            end)
            table.insert(refreshAbilityToggles, refresh)
        end
    end

    local languageHeading = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    languageHeading:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 0, -382)
    languageHeading:SetText("|cFFFFD100" .. T("LANGUAGE") .. "|r")

    local languageLabel = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    languageLabel:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 0, -410)
    languageLabel:SetText(T("Language:"))

    local languageDropdown = CreateFrame(
        "Frame",
        "HAOF_LanguageDropdown",
        optionsContainer,
        "UIDropDownMenuTemplate"
    )
    languageDropdown:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 80, -395)
    UIDropDownMenu_SetWidth(languageDropdown, 170)

    local languageChoices = { "auto", "enUS", "ptPT", "frFR", "deDE", "itIT", "jaJP" }
    local function RefreshLanguageDropdown()
        local selection = HAOF.GetLanguagePreference()
        UIDropDownMenu_SetSelectedValue(languageDropdown, selection)
        UIDropDownMenu_SetText(languageDropdown, HAOF.GetLanguageName(selection))
    end
    UIDropDownMenu_Initialize(languageDropdown, function(_, level)
        for _, language in ipairs(languageChoices) do
            local selectedLanguage = language
            local info = UIDropDownMenu_CreateInfo()
            info.text = HAOF.GetLanguageName(selectedLanguage)
            info.value = selectedLanguage
            info.checked = HAOF.GetLanguagePreference() == selectedLanguage
            info.func = function()
                if not HAOF.SetLanguagePreference(selectedLanguage) then
                    print("|cFFFF0000" .. T("Unable to save the language selection.") .. "|r")
                    return
                end
                RefreshLanguageDropdown()
                print("|cFFFFCC00" .. T("Language saved. Type /reload to apply it.") .. "|r")
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    RefreshLanguageDropdown()

    local languageHelp = optionsContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    languageHelp:SetPoint("TOPLEFT", optionsContainer, "TOPLEFT", 0, -438)
    languageHelp:SetWidth(520)
    languageHelp:SetJustifyH("LEFT")
    languageHelp:SetText(T("Type /reload after changing the language to apply it."))

    local infoText = gearContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoText:SetPoint("TOPLEFT", gearContainer, "TOPLEFT", 0, 0)
    infoText:SetJustifyH("LEFT")
    infoText:SetJustifyV("TOP")
    infoText:SetWidth(285)
    infoText:SetHeight(390)
    infoText:SetTextColor(1, 0.91, 0.75)
    frame.InfoText = infoText

    local macroContainer = CreateFrame("Frame", nil, frame)
    macroContainer:SetSize(564, 350)
    macroContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -85)
    macroContainer:Hide()
    frame.MacroContainer = macroContainer

    local petMatrixContainer = CreateFrame("Frame", nil, frame)
    petMatrixContainer:SetSize(285, 390)
    petMatrixContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -80)
    petMatrixContainer:Hide()
    frame.PetMatrixContainer = petMatrixContainer

    local petMatrixScrollFrame = CreateFrame(
        "ScrollFrame",
        "HAOF_PetSkillsScrollFrame",
        petMatrixContainer,
        "UIPanelScrollFrameTemplate"
    )
    petMatrixScrollFrame:SetPoint("TOPLEFT", petMatrixContainer, "TOPLEFT", 0, 0)
    petMatrixScrollFrame:SetSize(285, 390)
    frame.PetMatrixScrollFrame = petMatrixScrollFrame

    local petMatrixScrollBar = _G.HAOF_PetSkillsScrollFrameScrollBar
    if petMatrixScrollBar then
        petMatrixScrollBar:ClearAllPoints()
        petMatrixScrollBar:SetPoint("TOPLEFT", petMatrixScrollFrame, "TOPRIGHT", -16, -16)
        petMatrixScrollBar:SetPoint("BOTTOMLEFT", petMatrixScrollFrame, "BOTTOMRIGHT", -16, 16)
    end

    local petMatrixContent = CreateFrame("Frame", nil, petMatrixScrollFrame)
    petMatrixContent:SetSize(259, 390)
    petMatrixScrollFrame:SetScrollChild(petMatrixContent)

    local petMatrixText = petMatrixContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    petMatrixText:SetPoint("TOPLEFT", petMatrixContent, "TOPLEFT", 0, 0)
    petMatrixText:SetJustifyH("LEFT")
    petMatrixText:SetJustifyV("TOP")
    petMatrixText:SetWidth(259)
    petMatrixText:SetSpacing(2)
    petMatrixText:SetTextColor(1, 0.91, 0.75)
    frame.PetMatrixText = petMatrixText
    frame.PetMatrixContent = petMatrixContent

    local leftPageHeading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    leftPageHeading:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -61)
    leftPageHeading:SetText(T("FIELD NOTES"))
    leftPageHeading:SetTextColor(BOOK_GOLD[1], BOOK_GOLD[2], BOOK_GOLD[3])

    local rightPageHeading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rightPageHeading:SetPoint("TOPLEFT", frame, "TOPLEFT", 362, -61)
    rightPageHeading:SetText(T("COMPANION RECORD"))
    rightPageHeading:SetTextColor(BOOK_GOLD[1], BOOK_GOLD[2], BOOK_GOLD[3])

    local petPortrait = frame:CreateTexture(nil, "ARTWORK")
    petPortrait:SetSize(64, 64)
    petPortrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 365, -82)
    petPortrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.PetPortrait = petPortrait

    local petPortraitMask
    if frame.CreateMaskTexture and petPortrait.AddMaskTexture then
        petPortraitMask = frame:CreateMaskTexture(nil, "ARTWORK")
        petPortraitMask:SetAllPoints(petPortrait)
        petPortraitMask:SetTexture(
            "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask",
            "CLAMPTOBLACKADDITIVE",
            "CLAMPTOBLACKADDITIVE"
        )
        petPortrait:AddMaskTexture(petPortraitMask)
    elseif petPortrait.SetMask then
        petPortrait:SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    end

    local petIdentityText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    petIdentityText:SetPoint("TOPLEFT", petPortrait, "TOPRIGHT", 12, -5)
    petIdentityText:SetWidth(190)
    petIdentityText:SetJustifyH("LEFT")
    petIdentityText:SetJustifyV("TOP")
    petIdentityText:SetTextColor(1, 0.91, 0.75)
    frame.PetIdentityText = petIdentityText

    local petXPNameplateToggle = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    petXPNameplateToggle:SetSize(145, 24)
    petXPNameplateToggle:SetPoint("TOPLEFT", frame, "TOPLEFT", 532, -180)
    StyleJournalButton(petXPNameplateToggle)
    frame.PetXPNameplateToggle = petXPNameplateToggle

    local petXPBar = CreateFrame("StatusBar", nil, frame)
    petXPBar:SetSize(285, 16)
    petXPBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 362, -158)
    petXPBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    petXPBar:SetStatusBarColor(0.35, 0.18, 0.62, 1)
    petXPBar:SetMinMaxValues(0, 1)
    petXPBar:SetValue(0)
    petXPBar:EnableMouse(false)
    frame.PetXPBar = petXPBar

    local petXPBackground = petXPBar:CreateTexture(nil, "BACKGROUND")
    petXPBackground:SetAllPoints(petXPBar)
    petXPBackground:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    petXPBackground:SetVertexColor(0.08, 0.06, 0.1, 0.9)

    local petXPText = petXPBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    petXPText:SetPoint("CENTER", petXPBar, "CENTER")
    petXPText:SetTextColor(1, 1, 1)
    frame.PetXPText = petXPText

    local petStatsText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    petStatsText:SetPoint("TOPLEFT", frame, "TOPLEFT", 362, -374)
    petStatsText:SetJustifyH("LEFT")
    petStatsText:SetJustifyV("TOP")
    petStatsText:SetWidth(285)
    petStatsText:SetHeight(152)
    petStatsText:SetTextColor(1, 0.91, 0.75)
    frame.PetStatsText = petStatsText

    local petCalcText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    petCalcText:SetPoint("TOPLEFT", frame, "TOPLEFT", 362, -211)
    petCalcText:SetJustifyH("LEFT")
    petCalcText:SetJustifyV("TOP")
    petCalcText:SetWidth(285)
    petCalcText:SetHeight(156)
    petCalcText:SetTextColor(1, 0.91, 0.75)
    frame.PetCalcText = petCalcText

    local companionRecordElements = {
        rightPageHeading,
        petPortrait,
        petIdentityText,
        petXPNameplateToggle,
        petXPBar,
        petCalcText,
        petStatsText,
    }
    local function UpdatePetXPNameplateToggle(petLevel)
        local isMaxLevel = petLevel and petLevel >= MAX_PET_LEVEL
        local isEnabled = HunterCompanionWindow.PetXPNameplateEnabled ~= false
        if isMaxLevel then
            petXPNameplateToggle:SetText(T("Pet Max Level"))
            petXPNameplateToggle:Disable()
        else
            petXPNameplateToggle:SetText(T(isEnabled and "Hide Frame XP" or "Show Frame XP"))
            petXPNameplateToggle:Enable()
        end
    end

    local function SetCompanionRecordShown(isShown)
        for _, element in ipairs(companionRecordElements) do
            if isShown and (element ~= petXPBar
                or (UnitExists("pet") and (tonumber(UnitLevel("pet")) or 1) < MAX_PET_LEVEL)) then
                element:Show()
            else
                element:Hide()
            end
        end
    end

    petXPNameplateToggle:SetScript("OnClick", function()
        local isEnabled = HunterCompanionWindow.PetXPNameplateEnabled ~= false
        HunterCompanionWindow:SetPetXPNameplateEnabled(not isEnabled)
        UpdatePetXPNameplateToggle(tonumber(UnitLevel("pet")))
    end)

    local function RefreshCompanionRecord()
        local hasPet = UnitExists("pet")
        if hasPet then
            if SetPortraitTexture then
                SetPortraitTexture(frame.PetPortrait, "pet")
            elseif UnitCreatureTexture then
                frame.PetPortrait:SetTexture(UnitCreatureTexture("pet"))
            end

            local petName = UnitName("pet") or T("Active pet")
            local petLevel = tonumber(UnitLevel("pet")) or 1
            local petFamily = UnitCreatureFamily and UnitCreatureFamily("pet") or "Unknown family"
            frame.PetIdentityText:SetText(string.format(
                "|cFFFFD100%s|r\n%s\n%s",
                petName,
                string.format(T("Level %d"), petLevel),
                T(petFamily)
            ))

            local statLines = {}

            if type(UnitArmor) == "function" then
                local _, effectiveArmor = UnitArmor("pet")
                if not AddPetStatLine(statLines, T("Armor: %d"), effectiveArmor) then
                        table.insert(statLines, T("Armor: unavailable"))
                end
            end

            if type(UnitDamage) == "function" then
                local minDamage, maxDamage = UnitDamage("pet")
                if not AddPetStatLine(statLines, T("Melee damage: %.1f - %.1f"), minDamage, maxDamage) then
                    table.insert(statLines, T("Melee damage: unavailable"))
                end
            end

            if type(UnitAttackSpeed) == "function" then
                local mainHandSpeed, offHandSpeed = UnitAttackSpeed("pet")
                if IsSafePetStat(mainHandSpeed) then
                    local speedText
                    if IsSafePetStat(offHandSpeed) and offHandSpeed > 0 then
                        local ok, formatted = pcall(
                            string.format,
                            T("Attack speed: %.2f / %.2f sec"),
                            mainHandSpeed,
                            offHandSpeed
                        )
                        if ok and not IsSecretValue(formatted) then
                            speedText = formatted
                        end
                    else
                        local ok, formatted = pcall(string.format, T("Attack speed: %.2f sec"), mainHandSpeed)
                        if ok and not IsSecretValue(formatted) then
                            speedText = formatted
                        end
                    end
                    table.insert(statLines, speedText or T("Attack speed: unavailable"))
                else
                    table.insert(statLines, T("Attack speed: unavailable"))
                end
            end

            local agility
            if type(UnitStat) == "function" then
                local _, petAgility = UnitStat("pet", 2)
                agility = petAgility
            end

            table.insert(statLines, T("Hit chance (est., equal-level): 95%"))
            if IsSafePetStat(agility) then
                -- Classic level-60 reference: approximately 53 Agility per 1% crit.
                AddPetStatLine(statLines, T("Crit (est., Classic L60 ref.): %.1f%%"), 5 + agility / 53)
            else
                table.insert(statLines, T("Crit (est., Classic L60 ref.): unavailable"))
            end

            local statsOk, statsText = pcall(table.concat, statLines, "\n")
            if not statsOk or IsSecretValue(statsText) then
                statsText = T("Stat values are protected by the client.")
            end
            local health, maxHealth = UnitHealth("pet"), UnitHealthMax("pet")
            frame.PetStatsText:SetFormattedText(
                "|cFFFFD100%s|r\n%s %d / %d\n%s",
                T("PET COMBAT STATS"),
                T("Health:"),
                health,
                maxHealth,
                statsText
            )

            if petLevel >= MAX_PET_LEVEL then
                frame.PetXPBar:Hide()
                frame.PetXPText:SetText(T("Maximum level"))
            else
                local currentXP, requiredXP = GetPetXP()
                if currentXP and requiredXP and requiredXP > 0 then
                    frame.PetXPBar:SetMinMaxValues(0, requiredXP)
                    frame.PetXPBar:SetValue(math.min(currentXP, requiredXP))
                    frame.PetXPText:SetText(string.format(
                        T("XP: %d / %d (%d%%)"),
                        currentXP,
                        requiredXP,
                        math.floor(currentXP / requiredXP * 100)
                    ))
                else
                    frame.PetXPBar:SetMinMaxValues(0, 1)
                    frame.PetXPBar:SetValue(0)
                    frame.PetXPText:SetText(T("Pet XP unavailable"))
                end
            end
            UpdatePetXPNameplateToggle(petLevel)
        else
            frame.PetPortrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            frame.PetIdentityText:SetText(T("No active pet"))
            frame.PetStatsText:SetText("|cFFFFD100" .. T("PET COMBAT STATS") .. "|r\n" .. T("Summon a pet to view its stats."))
            frame.PetXPBar:Hide()
            frame.PetXPBar:SetMinMaxValues(0, 1)
            frame.PetXPBar:SetValue(0)
            frame.PetXPText:SetText(T("Summon a pet to view XP"))
            UpdatePetXPNameplateToggle(nil)
        end

        local FeedManager = HAOF.PetFeedingManager
        local CalcEngine = HAOF.PetTrainingCalculator
        local summaryText = CalcEngine and CalcEngine:GetTrainingSummaryText() or ""
        local _, moodText
        if FeedManager and FeedManager.GetHappinessStatus then
            _, moodText = FeedManager:GetHappinessStatus()
        end
        frame.PetCalcText:SetText(moodText and (summaryText .. "\n" .. moodText) or summaryText)
    end

    local function RefreshPetSkills()
        local MatrixEngine = HAOF.PetAbilityMatrix
        if MatrixEngine and MatrixEngine.GetPetFamilyText then
            frame.PetMatrixText:SetText(MatrixEngine:GetPetFamilyText())
            frame.PetMatrixContent:SetHeight(math.max(340, frame.PetMatrixText:GetStringHeight() + 8))
            frame.PetMatrixScrollFrame:SetVerticalScroll(0)
        end
    end

    CreateFrame("Button", nil, frame, "UIPanelCloseButton"):SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    self:CreateSpecTab(frame, T("Gear Guide"), 103, -593, 110, function()
        frame.MacroContainer:Hide()
        frame.PetMatrixContainer:Hide()
        frame.OptionsContainer:Hide()
        frame.GearContainer:Show()
        SetCompanionRecordShown(true)
        self:PopulateText(frame.InfoText)
    end, "Gear Guidelines", "View level-based Hunter gearing priorities for leveling or max-level content.")

    self:CreateSpecTab(frame, T("Macros"), 231, -593, 110, function()
        frame.GearContainer:Hide()
        frame.PetMatrixContainer:Hide()
        frame.OptionsContainer:Hide()
        frame.MacroContainer:Show()
        SetCompanionRecordShown(false)
        self:RefreshMacroPage(frame.MacroContainer)
    end, "Simple Hunter Macros", "Add or remove practical Classic Hunter macros in your character macro list.")

    self:CreateSpecTab(frame, T("Pet Skills"), 359, -593, 110, function()
        frame.GearContainer:Hide()
        frame.MacroContainer:Hide()
        frame.OptionsContainer:Hide()
        frame.PetMatrixContainer:Show()
        SetCompanionRecordShown(true)
        RefreshPetSkills()
    end, "Pet Ability Guide", "See which family abilities and ranks are available at your pet's level, including where to learn them.")

    self:CreateSpecTab(frame, T("Options"), 487, -593, 110, function()
        frame.GearContainer:Hide()
        frame.MacroContainer:Hide()
        frame.PetMatrixContainer:Hide()
        frame.OptionsContainer:Show()
        SetCompanionRecordShown(false)
    end, "Addon Options", "Configure ammo alerts, Multi-Hawk status, and cooldown tracking.")

    frame:SetScript("OnShow", function()
        for _, refresh in ipairs(refreshAbilityToggles) do
            refresh()
        end
        if frame.GearContainer:IsShown() then
            self:PopulateText(frame.InfoText)
        end
        if frame.PetMatrixContainer:IsShown() then
            RefreshPetSkills()
        end
        RefreshCompanionRecord()
        RefreshAmmoFooter()
        if frame.MacroContainer:IsShown() then self:RefreshMacroPage(frame.MacroContainer) end
    end)

    frame:RegisterEvent("PLAYER_LEVEL_UP")
    frame:RegisterEvent("UNIT_PET")
    frame:RegisterEvent("PET_BAR_UPDATE")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("UNIT_STATS")
    frame:RegisterEvent("UNIT_ATTACK_SPEED")
    frame:RegisterEvent("UNIT_DAMAGE")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("BAG_UPDATE")
    frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    frame:RegisterEvent("SPELLS_CHANGED")
    frame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_LEVEL_UP" or event == "SPELLS_CHANGED" then
            for _, refresh in ipairs(refreshAbilityToggles) do
                refresh()
            end
        end
        if event == "PLAYER_LEVEL_UP" and frame:IsShown() and frame.GearContainer:IsShown() then
            self:PopulateText(frame.InfoText)
        end

        if not frame:IsShown() then
            return
        end

        if event == "BAG_UPDATE" or event == "UNIT_INVENTORY_CHANGED"
            or event == "PLAYER_LEVEL_UP" or event == "GET_ITEM_INFO_RECEIVED" then
            if event ~= "UNIT_INVENTORY_CHANGED" or unit == "player" then
                RefreshAmmoFooter()
            end
        end

        if event == "PLAYER_LEVEL_UP" or event == "UNIT_PET"
            or event == "PET_BAR_UPDATE" or event == "UNIT_HEALTH"
            or event == "UNIT_MAXHEALTH" or event == "UNIT_STATS"
            or event == "UNIT_ATTACK_SPEED" or event == "UNIT_DAMAGE"
            or event == "UNIT_AURA" then
            local isPlayerPetChanged = event == "UNIT_PET" and unit == "player"
            local isPetStatsChanged = event ~= "UNIT_PET" and event ~= "PLAYER_LEVEL_UP"
                and event ~= "PET_BAR_UPDATE" and unit == "pet"
            if event == "PLAYER_LEVEL_UP" or event == "PET_BAR_UPDATE"
                or isPlayerPetChanged or isPetStatsChanged then
                if rightPageHeading:IsShown() then
                    RefreshCompanionRecord()
                end
            end
            if frame.PetMatrixContainer:IsShown()
                and (event == "PET_BAR_UPDATE" or event == "UNIT_PET" or event == "PLAYER_LEVEL_UP") then
                RefreshPetSkills()
            end
        end
    end)

    local Settings = HAOF.SettingsManager
    if Settings and Settings.ApplyWindowPosition then Settings:ApplyWindowPosition(frame) end

    self:PopulateText(frame.InfoText)
    frame:Hide()
    return frame
end
function HunterCompanionWindow:CreateSpecTab(parent, label, xOffset, yOffset, width, onClickFunc, tooltipTitle, tooltipDesc)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 25)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    button:SetText(label)
    StyleJournalButton(button)
    button:SetScript("OnClick", onClickFunc)

    if tooltipTitle and tooltipDesc then
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(tooltipTitle, 1.0, 0.82, 0.0)
            GameTooltip:AddLine(tooltipDesc, 1.0, 1.0, 1.0, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end

return HunterCompanionWindow
