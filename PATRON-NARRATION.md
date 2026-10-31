# Dungeon patron captions — 0.11.6

The Unending Dream's host now speaks through original Fa-Nuit-Hen captions. These are invented mod dialogue, not quotations or newly asserted canonical lore. The martial-trial direction is established in DELVE-LORE.md. No voice recordings or external dialogue assets were imported.

The floor scheduler offers descent, buildup, peak, recovery, reinforcement, guardian-approach and guardian-victory cues. Existing promotion and reward events select patron lines while the player is in a generated floor. Ordinary-world pools, including Dagoth Ur, The Dream and named special encounters, remain intact. The refuge receives no wilderness-pressure or dungeon-combat chatter; its existing safe-rest caption also uses the patron. Mechanical travel, broker and quest notices remain separate from flavor captions.

Guardian generation at the far end of a floor is silent; approach offers its introduction once. The scheduler owns its victory announcement, avoiding a second generic boss-victory caption. Other promoted enemies and exceptional rewards retain their existing event chances, with patron text selected contextually.

Each floor saves offered milestone keys. One pending cue expires after 30 seconds; guardian cues take priority over routine chatter. The shared patron cooldown is eight seconds, longer than the seven-second caption. Routine cues honor voice frequency; nonzero settings permit important milestones. Zero mutes captions and drops pending cues. Offers can be superseded, expired or muted rather than replayed as a backlog.

Portal travel, descent, recycling and load discard pending cues while retaining milestone flags. The player clears its caption on teleport/load and rejects payloads tagged for another cell. Actor-specific narration checks its originating cell before emission. Wilderness pressure polling only runs in exteriors and cannot consume pressure milestones indoors. Save/load does not retrospectively narrate completed floors or victories.

Narration uses separate deterministic text selection and saved narration fields. It does not alter spawn selection, phase timing, populations, difficulty, promotion/drop rolls, rewards, spells or camera controls. Existing floors and runs remain usable. Enable or mute captions with the existing **Director voice frequency** setting.

Validation uses isolated profiles and the actual caption event/card interfaces, including protected test players, controlled phase transitions and accelerated voice cooldowns. It covers both Isowind/full-suite and stock/base-content operation, portal/save/load transitions, mute, guardian priority/deduplication and restoration of the world voice. This is automated UI-state verification, not manual visual or audio review.
