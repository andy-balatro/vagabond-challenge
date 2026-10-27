# Vagabond Challenge

A Balatro challenge where your starting Jokers are the only Jokers you get for the whole run.

## Rules

- Start with either:
  - one **Eternal Vagabond** and **1 Joker slot**, or
  - four **Eternal 8 Balls** and **4 Joker slots**
- Banned: **Ectoplasm**, **Blank**, **Antimatter** (and Multiplayer's Sandbox Ectoplasm when that mod is loaded)
- **Negative Tag** removed from skips
- **Negative Jokers become Polychrome.** Any Joker that would get the Negative edition (shop, packs, spectrals, tags, other mods) gets Polychrome instead. Consumables are unaffected.

Next to the Play button are three selectors:

- **Jokers:** *Vagabond* or *4x 8 Ball*
- **Deck:** *Challenge Deck* (no deck effect) or any other deck. Locked decks are included.
- **Stake:** any stake

Your last choices are remembered.

The challenge's Joker slot count always wins over the deck's. Black Deck keeps its -1 hand but not its
+1 slot, and Painted Deck keeps its +2 hand size without losing a slot.

Shops still show Jokers, but with every slot filled by an eternal Joker you can't buy them. The same goes
for Buffoon packs, Judgement, Wraith, The Soul, Ankh and Top-up Tag, since they all need a free slot.

## Requirements

- [Lovely](https://github.com/ethangreen-dev/lovely-injector) only. Steamodded is **not** required.
- Also works with Steamodded and the [Balatro Multiplayer](https://github.com/Balatro-Multiplayer/BalatroMultiplayer) mod.

## Install

Copy the `vagabond-challenge` folder into `%AppData%\Balatro\Mods\`.
The challenge is listed under **Play → Challenges** (last page) and is always unlocked.
Vanilla still requires Challenge mode to be unlocked first: win with 5 different decks.

## Multiplayer

In a lobby, the host opens **Challenges**, picks *Vagabond*, chooses Jokers, deck and stake, and presses
Play. The choice is synced to the guest: the Joker mode and deck travel inside the challenge id
(e.g. `c_vbc_vagabond_1:eight_ball:b_black`), and the stake travels the same way as for any other
challenge. **Both players need this mod** (v1.1.0 or newer on both sides).
Multiplayer includes it in its mod-mismatch check. Avoid the *Shared Pockets* lobby modifier, since it
replaces slot limits with a shared pool and would allow extra Jokers.

## Files

| File | Purpose |
| --- | --- |
| `lovely.toml` | Appends the mod to `challenges.lua`; makes `unlocked = true` work without Steamodded |
| `vagabond_challenge.lua` | The challenge, Jokers/deck/stake selectors, Multiplayer sync, Negative → Polychrome hook, localization |
| `vagabond-challenge.json`, `smods_entry.lua` | Steamodded metadata; registers the challenge as an `SMODS.Challenge` |
