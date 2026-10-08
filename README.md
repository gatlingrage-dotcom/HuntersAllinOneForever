# 🏹 HuntersAllinOneForever

[![WoW Version](https://img.shields.io/badge/WoW%20Forever-Classic-blue.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#)
[![Class](https://img.shields.io/badge/Class-Hunter-orange.svg)](#)

An all-in-one interface and reference addon for **Hunters in WoW Forever**, combining a companion journal, pet guidance, cooldown and Hawk trackers, macro management, and ammunition alerts.

The interface includes English, Portuguese (Portugal), French, German, Italian, and Japanese translations. By default it follows the game language when supported and falls back to English otherwise. Choose a language or restore automatic selection in the Options tab; changing the selection reloads the UI.

---

## ✨ Key Features

### 🐾 Pet helpers
* **Pet training summary:** Calculates a pet's training-point estimate from its level and loyalty.
* **Optional WeakAura snippets:** `src/pet_matrix_logic.lua` contains custom-text helpers; it is not loaded by the addon TOC.

### Pet Ability Guide (`src/pet_ability_matrix.lua`)
* **Family Ability Guidance:** Lists abilities supported by the active pet's family and ranks available at its current level.
* **Rank Progression:** Shows pet-level unlocks and known tame sources, locations, and hunter-level tame requirements.
* **Classic Reference Data:** Recommendations follow the current standard Classic baseline and are clearly distinguished from checks of abilities the pet has already learned; WoW Forever data can be updated separately.
* **Companion Record:** Shows pet identity, live health, armor, melee damage, attack speed, and estimated hit/critical chance, plus loyalty/training points, happiness, and XP. Hit chance assumes an equal-level target; critical chance uses a rough Classic level-60 agility reference and may differ at other levels or on WoW Forever. XP displays hide at level 60.
* **Ammo Footer:** Shows the next standard arrow or bullet rank, equipped ammunition and count, required-level suitability, and higher-level ammunition carried in your bags.

### Hunter Options and Cooldowns
* **Configurable alerts:** The Options page toggles low-ammo alerts and adjusts critical and caution thresholds.
* **Hunter macros:** The Macros page offers commonly used Hunter utilities for auto shot, pet control, marking, aspects, traps, interrupts, and melee auto-attacks. Existing HAOF macros can be updated to the current versions or removed from the page.
* **Cooldown tracking:** Tracks selected traps, Feign Death, Rapid Fire, Bestial Wrath, and Concussive Shot in a movable icon-grid window with cooldown sweeps. Each trap has its own estimated 30-second fallback after a detected cast when the client protects spell cooldown data; Feign Death also has its own estimated 30-second fallback. Unlearned abilities are grayed out and marked in Options, where their checkboxes are disabled.
* **Position lock:** Lock or unlock the cooldown window from Options; its position and lock state are saved between sessions. Shift-drag an ability icon to move it while locked.
* **Cooldown window opacity:** Adjust the cooldown window background and border opacity from Options without fading its ability icons; 0% leaves the icons visible against a transparent window.
* **Multi-Hawk status:** Show current hawk summon status in its own movable window, with an option to show it only in combat. Adjust its background and border opacity from Options (0% leaves the text visible); lock it there and Shift-drag to move while locked.

### 🦅 Hawk tracker
* Reads the active count from the client's native totem display, with combat-only visibility, configurable opacity, and locking. The native totem icons display each Hawk's individual timer; the addon avoids reading protected timer values.

### ⚔️ Gear Guide
* The journal provides player-level-aware leveling or level-60 priorities. It avoids hard-coded item lists because WoW Forever may customize itemization.

---

## 🚀 Installation & Setup

1. Copy the `HuntersAllinOneForever` folder into `World of Warcraft\_classic_\Interface\AddOns\`.
2. Enable the addon at the character-select AddOns screen.
3. Use `/haof` or `/hunterjournal` to open the journal. The Macros tab lets you add, update, or remove the listed macros.

---

## 🛠️ Code Structure

```text
HuntersAllinOneForever/
├── HuntersAllinOneForever.toc
├── HuntersAllinOneForever.lua
└── src/                       # Addon services, trackers, and companion UI
```

---

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.
