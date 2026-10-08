# Changelog

Notable changes to HuntersAllinOneForever are listed here.

## Unreleased

### Added
- Automatic English, Portuguese (Portugal), French, German, Italian, and Japanese interface localization.
- Language selector with automatic game-language detection, English fallback, and saved manual selection.
- Pet combat stats in the Companion Record, including live health, armor, melee damage, attack speed, and estimated hit and critical chance.
- Separate movable cooldown and Hawk status windows, with configurable visibility, opacity, locking, and saved positions.
- Hawk count from the native totem display; individual countdowns remain on the native totem icons.
- Hawk tracker uses icon ID 132158.
- Level-aware Hunter gear guidance and pet ability rank recommendations.
- A macro page for adding, updating, and removing commonly used Hunter macros.
- Ammunition alerts and an ammunition guide in the Companion Record.

### Changed
- Expanded the Companion Journal and content panels to give translated text more room.
- Reworked the Options page with checkboxes for tracker visibility and abilities, plus opacity controls.
- Updated the Companion Record layout and pet XP display.
- Reduced background polling frequency for the cooldown and Hawk trackers.
- Made slash-command parsing independent of a nonstandard string-trimming helper.
- Updated README installation instructions and feature descriptions.

### Fixed
- Prevented protected pet-stat values from being concatenated or formatted directly by Lua.
- Replaced nameplate-based Hawk detection with the native totem display's active count.
- Avoided cooldown arithmetic and widget updates with protected spell cooldown values.
- Added event-based per-ability trap cooldown estimates when spell cooldown values are protected.
- Added an event-based 30-second Feign Death cooldown fallback when spell cooldown data is protected.
- Capture trap casts from both spell-sent and spell-succeeded events for better client compatibility.
- Corrected trap cooldown tracking to keep independent timers for WoW Forever's separate trap cooldowns.
- Improved trap detection across cast-start events and localized spell-name arguments.
- Fixed spellcast argument scanning so nil event fields do not prevent trap cooldown recognition.
- Removed an unsupported movement event that caused journal initialization to fail.
- Removed unused pet power event handling after those stats were taken out of the Companion Record.
