# Vagabond Challenge

A Balatro challenge where an **Eternal Vagabond** is the only Joker you get for the whole run.

## Rules

- Start with an **Eternal Vagabond**
- **1 Joker slot**
- Banned: **Ectoplasm**, **Blank**, **Antimatter** (and Multiplayer's Sandbox Ectoplasm when that mod is loaded)
- **Negative Tag** removed from skips
- **Negative Jokers become Polychrome.** Any Joker that would get the Negative edition (shop, packs, spectrals, tags, other mods) gets Polychrome instead. Consumables are unaffected.
- **Choose your stake.** A stake selector sits next to the Play button. Your last choice is remembered.

Shops still show Jokers, but with Vagabond filling the single slot you can't buy them. The same goes for
Buffoon packs, Judgement, Wraith, The Soul, Top-up Tag and Ankh, since they all need a free slot.

## Requirements

- [Lovely](https://github.com/ethangreen-dev/lovely-injector) only. Steamodded is **not** required.
- Also works with Steamodded and the [Balatro Multiplayer](https://github.com/Balatro-Multiplayer/BalatroMultiplayer) mod.

## Install

Copy the `vagabond-challenge` folder into `%AppData%\Balatro\Mods\`.
The challenge is listed under **Play → Challenges** (last page) and is always unlocked.
Vanilla still requires Challenge mode to be unlocked first: win with 5 different decks.

## Multiplayer

In a lobby, the host opens **Challenges**, picks *Vagabond*, chooses a stake and presses Play. The
challenge and stake are sent to the lobby like any other challenge deck. **Both players need this mod.**
Multiplayer includes it in its mod-mismatch check. Avoid the *Shared Pockets* lobby modifier, since it
replaces slot limits with a shared pool and would allow extra Jokers.

## Files

| File | Purpose |
| --- | --- |
| `lovely.toml` | Appends the mod to `challenges.lua`; makes `unlocked = true` work without Steamodded |
| `vagabond_challenge.lua` | The challenge, stake selector, Negative → Polychrome hook, localization |
| `vagabond-challenge.json`, `smods_entry.lua` | Steamodded metadata; registers the challenge as an `SMODS.Challenge` |
