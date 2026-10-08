-- ============================================================================
-- Project: HuntersAllinOneForever
-- File: src/pet_ability_matrix.lua
-- Description: Active-pet family guide and current pet-bar ability summary.
-- ============================================================================

HAOF = HAOF or {}
HAOF.PetAbilityMatrix = {}
local PetAbilityMatrix = HAOF.PetAbilityMatrix
local function T(text)
    return HAOF.T and HAOF.T(text) or text
end

PetAbilityMatrix.FamilyProfiles = {
    ["Bat"] = {
        Specialty = "Screech",
        Details = "Screech damages nearby enemies and reduces their attack power. Useful for reducing incoming melee damage.",
        Abilities = { "Bite", "Cower", "Dive", "Growl", "Screech" },
    },
    ["Bear"] = {
        Specialty = "No unique family ability",
        Details = "A durable general-purpose pet with access to Bite, Claw, Growl, and Cower.",
        Abilities = { "Bite", "Claw", "Cower", "Growl" },
    },
    ["Boar"] = {
        Specialty = "Charge",
        Details = "Charge closes distance and briefly immobilizes the target before the boar's next attack.",
        Abilities = { "Bite", "Charge", "Cower", "Dash", "Growl" },
    },
    ["Carrion Bird"] = {
        Specialty = "Screech",
        Details = "Screech damages nearby enemies and reduces their attack power. Useful for reducing incoming melee damage.",
        Abilities = { "Bite", "Claw", "Cower", "Dive", "Growl", "Screech" },
    },
    ["Cat"] = {
        Specialty = "Prowl",
        Details = "Prowl increases the pet's next attack from stealth. Cats are also commonly trained with Claw, Bite, and Dash.",
        Abilities = { "Bite", "Claw", "Cower", "Dash", "Growl", "Prowl" },
    },
    ["Crab"] = {
        Specialty = "No unique family ability",
        Details = "A durable pet option with access to Claw, Growl, and Cower.",
        Abilities = { "Claw", "Cower", "Growl" },
    },
    ["Crocolisk"] = {
        Specialty = "No unique family ability",
        Details = "A durable general-purpose pet with access to Bite, Growl, and Cower.",
        Abilities = { "Bite", "Cower", "Growl" },
    },
    ["Gorilla"] = {
        Specialty = "Thunderstomp",
        Details = "Thunderstomp damages nearby enemies and generates extra threat, helping the pet hold multiple targets.",
        Abilities = { "Bite", "Cower", "Growl", "Thunderstomp" },
    },
    ["Hyena"] = {
        Specialty = "No unique family ability",
        Details = "A general-purpose damage pet with access to Bite, Dash, and Growl.",
        Abilities = { "Bite", "Cower", "Dash", "Growl" },
    },
    ["Owl"] = {
        Specialty = "Screech",
        Details = "Screech damages nearby enemies and reduces their attack power. Useful for reducing incoming melee damage.",
        Abilities = { "Claw", "Cower", "Dive", "Growl", "Screech" },
    },
    ["Raptor"] = {
        Specialty = "No unique family ability",
        Details = "A general-purpose damage pet with access to Bite, Claw, Growl, and Cower.",
        Abilities = { "Bite", "Claw", "Cower", "Growl" },
    },
    ["Scorpid"] = {
        Specialty = "Scorpid Poison",
        Details = "Applies a damage-over-time poison. Its repeated applications can help maintain poison stacks.",
        Abilities = { "Claw", "Cower", "Growl", "Scorpid Poison" },
    },
    ["Spider"] = {
        Specialty = "No unique family ability",
        Details = "A general-purpose pet with access to Bite, Growl, and Cower.",
        Abilities = { "Bite", "Cower", "Growl" },
    },
    ["Tallstrider"] = {
        Specialty = "No unique family ability",
        Details = "A mobile general-purpose pet with access to Bite, Dash, and Growl.",
        Abilities = { "Bite", "Cower", "Dash", "Growl" },
    },
    ["Turtle"] = {
        Specialty = "Shell Shield",
        Details = "Shell Shield reduces damage taken by the pet while also reducing its damage dealt.",
        Abilities = { "Bite", "Cower", "Growl", "Shell Shield" },
    },
    ["Wind Serpent"] = {
        Specialty = "Lightning Breath",
        Details = "A ranged nature-damage attack that lets the pet deal damage without being in melee range.",
        Abilities = { "Bite", "Cower", "Dive", "Growl", "Lightning Breath" },
    },
    ["Wolf"] = {
        Specialty = "Furious Howl",
        Details = "Furious Howl increases the next physical attack damage of the wolf and its nearby party members.",
        Abilities = { "Bite", "Cower", "Dash", "Furious Howl", "Growl" },
    },
}

local function MakeRanks(levels, sources)
    local ranks = {}
    for rank, level in ipairs(levels) do
        ranks[rank] = {
            Level = level,
            Source = sources and sources[rank],
        }
    end
    return ranks
end

local function MobSource(name, levelRange, location)
    local mobLevel = tonumber(string.match(levelRange, "^(%d+)"))
    return {
        Mob = name,
        MobLevel = levelRange,
        HunterLevel = math.max(1, (mobLevel or 1) - 5),
        Location = location,
    }
end

local TRAINER_SOURCE = { Trainer = true }

PetAbilityMatrix.AbilityCatalog = {
    ["Bite"] = {
        Ranks = MakeRanks({ 1, 8, 16, 24, 32, 40, 48, 56 }, {
            MobSource("Ragged Scavenger", "2-3", "Tirisfal Glades"),
            MobSource("Webwood Silkspinner", "8-9", "Teldrassil"),
            MobSource("Deepmoss Creeper", "16-17", "Stonetalon Mountains"),
            MobSource("Black Ravager", "24-25", "Duskwood"),
            MobSource("Plains Creeper", "32-33", "Arathi Highlands"),
            MobSource("Barnabus", "38", "Badlands"),
            MobSource("Rekk'tilac", "48", "Searing Gorge"),
            MobSource("Bloodaxe Worg", "56-57", "Blackrock Spire (Dungeon)"),
        }),
    },
    ["Charge"] = {
        Ranks = MakeRanks({ 1, 12, 24, 36, 48, 60 }, {
            MobSource("Mottled Boar", "1-2", "Durotar"),
            MobSource("Young Goretusk", "12-13", "Westfall"),
            MobSource("Agam'ar", "24-25", "Razorfen Kraul (Dungeon)"),
            false,
            MobSource("Ashmane Boar", "48-49", "Blasted Lands"),
            MobSource("Plagued Swine", "60", "Eastern Plaguelands"),
        }),
    },
    ["Claw"] = {
        Ranks = MakeRanks({ 1, 8, 16, 24, 32, 40, 48, 56 }, {
            MobSource("Scorpid Worker", "3", "Durotar"),
            MobSource("Strigid Hunter", "8-9", "Teldrassil"),
            MobSource("Black Bear Patriarch", "16-17", "Loch Modan"),
            MobSource("Barbed Crustacean", "25-26", "Blackfathom Deeps (Dungeon)"),
            MobSource("Scorpashi Lasher", "34-35", "Desolace"),
            MobSource("Silt Crawler", "40-41", "Swamp of Sorrows"),
            MobSource("Ironfur Patriarch", "48-49", "Feralas"),
            MobSource("Elder Shardtooth", "57-58", "Winterspring"),
        }),
    },
    ["Cower"] = {
        Ranks = MakeRanks({ 5, 15, 25, 35, 45, 55 }, {
            MobSource("Juvenile Snow Leopard", "5-6", "Dun Morogh"),
            MobSource("Savannah Patriarch", "15-16", "The Barrens"),
            MobSource("Crag Stalker", "25-26", "Thousand Needles"),
            MobSource("Ridge Stalker", "36-37", "Badlands"),
            MobSource("Jaguero Stalker", "50", "Stranglethorn Vale"),
            MobSource("Frostsaber Cub", "55-56", "Winterspring"),
        }),
    },
    ["Dash"] = {
        Ranks = MakeRanks({ 30, 40, 50 }, {
            MobSource("Stranglethorn Tiger", "32-33", "Stranglethorn Vale"),
            MobSource("Bhag'thera", "40", "Stranglethorn Vale"),
            MobSource("Grunter", "50", "Blasted Lands"),
        }),
    },
    ["Dive"] = {
        Ranks = MakeRanks({ 30, 40, 50 }, {
            MobSource("Kraul Bat", "30-31", "Razorfen Kraul (Dungeon)"),
            MobSource("Vale Screecher", "41-43", "Feralas"),
            MobSource("Dark Screecher", "50-52", "Blackrock Depths (Dungeon)"),
        }),
    },
    ["Furious Howl"] = {
        Ranks = MakeRanks({ 10, 24, 40, 56 }, {
            MobSource("Prairie Wolf Alpha", "9-10", "Mulgore"),
            MobSource("Black Ravager Mastiff", "25-26", "Duskwood"),
            MobSource("Longtooth Runner", "40-41", "Feralas"),
            MobSource("Bloodaxe Worg", "56-57", "Blackrock Spire (Dungeon)"),
        }),
    },
    ["Growl"] = {
        Ranks = MakeRanks({ 1, 10, 20, 30, 40, 50, 60 }, {
            TRAINER_SOURCE, TRAINER_SOURCE, TRAINER_SOURCE, TRAINER_SOURCE,
            TRAINER_SOURCE, TRAINER_SOURCE, TRAINER_SOURCE,
        }),
    },
    ["Lightning Breath"] = {
        Ranks = MakeRanks({ 1, 12, 24, 36, 48, 60 }, {
            false,
            MobSource("Deviate Coiler", "15-16", "Wailing Caverns (Dungeon)"),
            MobSource("Cloud Serpent", "25-26", "Thousand Needles"),
            MobSource("Vale Screecher", "41-43", "Feralas"),
            MobSource("Arash-ethis", "49", "Feralas"),
            MobSource("Son of Hakkar", "60", "Zul'Gurub (Raid)"),
        }),
    },
    ["Prowl"] = {
        Ranks = MakeRanks({ 30, 40, 50 }, {
            MobSource("Mountain Lion", "32-33", "Alterac Mountains"),
            MobSource("Ridge Stalker Patriarch", "40-41", "Badlands"),
            MobSource("Jaguero Stalker", "50", "Stranglethorn Vale"),
        }),
    },
    ["Scorpid Poison"] = {
        Ranks = MakeRanks({ 8, 24, 40, 56 }, {
            MobSource("Venomtail Scorpid", "9-10", "Durotar"),
            MobSource("Scorpashi Snapper", "30-31", "Desolace"),
            MobSource("Scorpid Hunter", "40-41", "Tanaris"),
            MobSource("Firetail Scorpid", "56-57", "Burning Steppes"),
        }),
    },
    ["Screech"] = {
        Ranks = MakeRanks({ 8, 24, 48, 56 }, {
            MobSource("Greater Fleshripper", "16-17", "Westfall"),
            MobSource("Salt Flats Vulture", "32-34", "Thousand Needles"),
            MobSource("Ironbeak Owl", "48-49", "Felwood"),
            MobSource("Monstrous Plaguebat", "56-58", "Eastern Plaguelands"),
        }),
    },
    ["Shell Shield"] = {
        Ranks = MakeRanks({ 20 }, {
            MobSource("Kresh", "20", "Wailing Caverns (Dungeon)"),
        }),
    },
    ["Thunderstomp"] = {
        Ranks = MakeRanks({ 30, 40, 50 }, {
            MobSource("Mistvale Gorilla", "32-33", "Stranglethorn Vale"),
            MobSource("Elder Mistvale Gorilla", "40-41", "Stranglethorn Vale"),
            MobSource("Un'Goro Thunderer", "52-53", "Un'Goro Crater"),
        }),
    },
}

local function GetAbilitySourceLine(rankInfo, hunterLevel)
    local source = rankInfo and rankInfo.Source
    if not source then
        return T("No known tame source for this rank.")
    end

    if source.Trainer then
        return T("Learn it from a Hunter or pet trainer.")
    end

    local tameRequirement = hunterLevel >= source.HunterLevel
        and T("you can tame it")
        or string.format(T("requires hunter level %d to tame"), source.HunterLevel)

    return string.format(
        T("Tame %s (level %s) in %s; %s."),
        source.Mob,
        source.MobLevel,
        source.Location,
        tameRequirement
    )
end

function PetAbilityMatrix:GetPetFamilyText()
    if not UnitExists("pet") then
        return "|cFFFFD100" .. T("Pet Skills") .. "|r\n\n" .. T("No active pet is summoned. Summon a pet to see its family abilities and level-based rank recommendations.")
    end

    local petName = UnitName("pet") or T("Active pet")
    local petLevel = tonumber(UnitLevel("pet")) or 1
    local hunterLevel = tonumber(UnitLevel("player")) or 1
    local family = UnitCreatureFamily and UnitCreatureFamily("pet") or nil
    local profile
    if family then
        profile = self.FamilyProfiles[family]
        if not profile then
            for englishFamily, candidate in pairs(self.FamilyProfiles) do
                if family == T(englishFamily) then
                    profile = candidate
                    break
                end
            end
        end
    end
    local text = string.format(
        "|cFFFFD100%s|r\n" .. T("Hunter level %d  |  Pet level %d  |  Family: %s") .. "\n\n",
        petName,
        hunterLevel,
        petLevel,
        T(family or "Unknown")
    )

    if profile then
        text = text
            .. string.format("|cFFFFD100%s|r %s\n%s\n\n", T("Family specialty:"), T(profile.Specialty), T(profile.Details))
            .. "|cFFFFD100" .. T("Abilities and ranks by pet level:") .. "|r\n"
    else
        text = text
            .. T("No family guide is available for this pet's family.") .. "\n"
            .. T("The ability list uses the standard Classic baseline and can be expanded when family data is added.")
    end

    if profile then
        local sortedAbilities = {}
        for _, abilityName in ipairs(profile.Abilities) do
            local ability = self.AbilityCatalog[abilityName]
            local sortLevel = math.huge
            if ability and ability.Ranks then
                for _, rankInfo in ipairs(ability.Ranks) do
                    if rankInfo.Level <= petLevel then
                        sortLevel = rankInfo.Level
                    else
                        if sortLevel == math.huge then
                            sortLevel = rankInfo.Level
                        end
                        break
                    end
                end
            end
            table.insert(sortedAbilities, {
                Name = abilityName,
                Level = sortLevel,
            })
        end
        table.sort(sortedAbilities, function(left, right)
            if left.Level == right.Level then
                return left.Name < right.Name
            end
            return left.Level < right.Level
        end)

        local function AppendAbility(abilityName)
            local ability = self.AbilityCatalog[abilityName]
            if not ability or not ability.Ranks then
                text = text
                    .. string.format(T(" - %s: rank data unavailable\n"), T(abilityName))
                    .. "|cFF8C7358------------------------------|r\n"
                return
            end

            local availableRank = 0
            local nextRank
            for rank, rankInfo in ipairs(ability.Ranks) do
                if rankInfo.Level <= petLevel then
                    availableRank = rank
                else
                    nextRank = rank
                    break
                end
            end

            if availableRank > 0 then
                local currentInfo = ability.Ranks[availableRank]
                text = text .. string.format(
                    T(" - %s: Rank %d available at pet level %d.\n   %s\n"),
                    T(abilityName),
                    availableRank,
                    currentInfo.Level,
                    GetAbilitySourceLine(currentInfo, hunterLevel)
                )
            elseif nextRank then
                local firstInfo = ability.Ranks[nextRank]
                text = text .. string.format(
                    T(" - %s: First rank unlocks at pet level %d.\n   %s\n"),
                    T(abilityName),
                    firstInfo.Level,
                    GetAbilitySourceLine(firstInfo, hunterLevel)
                )
            end

            if nextRank then
                local nextInfo = ability.Ranks[nextRank]
                if availableRank > 0 then
                    text = text .. string.format(
                        T("   Next: Rank %d at pet level %d. %s\n"),
                        nextRank,
                        nextInfo.Level,
                        GetAbilitySourceLine(nextInfo, hunterLevel)
                    )
                end
            end
            text = text .. "|cFF8C7358------------------------------|r\n"
        end

        for _, ability in ipairs(sortedAbilities) do
            AppendAbility(ability.Name)
        end
    end

    text = text
        .. "\n" .. T("These are level-based recommendations, not a check of skills already learned.")
        .. "\n" .. T("WoW Forever may change abilities, tame locations, and rank requirements.")
    return text
end

return PetAbilityMatrix
