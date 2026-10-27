
--------------------------------------------------------------------------------
-- Vagabond Challenge
--
-- Appended to challenges.lua by Lovely. Needs only Lovely; also works alongside
-- Steamodded and the Balatro Multiplayer mod.
--------------------------------------------------------------------------------

VagabondChallenge = VagabondChallenge or {}
local VBC = VagabondChallenge

VBC.VERSION = '1.1.0'
VBC.CHALLENGE_ID = 'c_vbc_vagabond_1'
VBC.NO_NEGATIVE_RULE = 'vbc_no_negative_jokers'

-- Everything that could give an extra joker slot.
VBC.BANNED_CARDS = {'c_ectoplasm', 'v_blank', 'v_antimatter'}
-- Modded equivalents, banned only when the mod that adds them is loaded.
VBC.OPTIONAL_BANNED_CARDS = {
    'c_mp_ectoplasm_sandbox', -- Multiplayer's Sandbox ruleset Ectoplasm
}

-- Starting jokers. Every copy is eternal and fills a slot, so nothing else fits.
VBC.MODES = {
    {key = 'vagabond', joker = 'j_vagabond', count = 1},
    {key = 'eight_ball', joker = 'j_8_ball', count = 4},
}
VBC.DEFAULT_DECK = 'b_challenge'

VBC.LOC = {
    challenge_names = {
        [VBC.CHALLENGE_ID] = 'Vagabond',
    },
    v_text = {
        ['ch_c_'..VBC.NO_NEGATIVE_RULE] = {'{C:dark_edition}Negative{} Jokers appear as {C:dark_edition}Polychrome{}'},
    },
}

local function ban_list(keys)
    local list = {}
    for _, key in ipairs(keys) do list[#list+1] = {id = key} end
    return list
end

VBC.challenge = {
    name = 'Vagabond',
    id = VBC.CHALLENGE_ID,
    unlocked = true,
    rules = {
        custom = {
            {id = VBC.NO_NEGATIVE_RULE},
        },
        modifiers = {
            {id = 'joker_slots', value = 1},
        },
    },
    jokers = {
        {id = 'j_vagabond', eternal = true},
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = 'Challenge Deck',
    },
    restrictions = {
        banned_cards = ban_list(VBC.BANNED_CARDS),
        banned_tags = {
            {id = 'tag_negative'},
        },
        banned_other = {},
    },
}

G.CHALLENGES[#G.CHALLENGES+1] = VBC.challenge

local function is_vbc_challenge(challenge)
    return type(challenge) == 'table' and challenge.id == VBC.CHALLENGE_ID
end

-- Steamodded expects every challenge in a run to be in SMODS.Challenges (its
-- scoring loop calls SMODS.Challenges[G.GAME.challenge]:calculate) and crashes on
-- plain tables. Adopt ours the same way Steamodded adopts the vanilla challenges.
function VBC.register_with_smods(silent)
    if not (SMODS and SMODS.Challenge and SMODS.Challenges) then return end
    if SMODS.Challenges[VBC.CHALLENGE_ID] then return end
    SMODS.Challenge:take_ownership((VBC.CHALLENGE_ID:gsub('^c_', '')), {}, silent)
end

--------------------------------------------------------------------------------
-- Variants (joker mode + deck)
--
-- The challenge has one entry in G.CHALLENGES; apply_variant rewrites it in
-- place. Multiplayer only syncs the challenge id, so lobbies get the variant
-- encoded into it ('c_vbc_vagabond_1:eight_ball:b_plasma') and every lookup of
-- that id resolves to our entry with the variant applied.
--------------------------------------------------------------------------------

function VBC.get_mode(key)
    for _, mode in ipairs(VBC.MODES) do
        if mode.key == key then return mode end
    end
    return VBC.MODES[1]
end

local function is_deck(key)
    local center = type(key) == 'string' and G.P_CENTERS and G.P_CENTERS[key]
    return center and center.set == 'Back' and true or false
end

-- Challenge Deck (no deck effect) first, then every selectable deck.
function VBC.deck_options()
    local keys = {VBC.DEFAULT_DECK}
    for _, center in ipairs(G.P_CENTER_POOLS and G.P_CENTER_POOLS.Back or {}) do
        if not center.omit and center.key ~= VBC.DEFAULT_DECK then keys[#keys+1] = center.key end
    end
    return keys
end

function VBC.sanitize_variant(variant)
    variant = type(variant) == 'table' and variant or {}
    return {
        mode = VBC.get_mode(variant.mode).key,
        deck = is_deck(variant.deck) and variant.deck or VBC.DEFAULT_DECK,
    }
end

function VBC.variant_id(variant)
    variant = VBC.sanitize_variant(variant)
    return VBC.CHALLENGE_ID..':'..variant.mode..':'..variant.deck
end

function VBC.parse_variant_id(id)
    if type(id) ~= 'string' then return end
    local prefix = VBC.CHALLENGE_ID..':'
    if id:sub(1, #prefix) ~= prefix then return end
    local mode, deck = id:sub(#prefix + 1):match('^([^:]+):(.+)$')
    if not mode then return end
    return VBC.sanitize_variant({mode = mode, deck = deck})
end

function VBC.apply_variant(challenge, variant)
    variant = VBC.sanitize_variant(variant)
    local mode = VBC.get_mode(variant.mode)

    challenge.jokers = {}
    for i = 1, mode.count do challenge.jokers[i] = {id = mode.joker, eternal = true} end

    challenge.rules = challenge.rules or {}
    challenge.rules.modifiers = {{id = 'joker_slots', value = mode.count}}

    challenge.deck = challenge.deck or {}
    challenge.deck.type = G.P_CENTERS[variant.deck] and G.P_CENTERS[variant.deck].name or 'Challenge Deck'

    local keys = {}
    for _, key in ipairs(VBC.BANNED_CARDS) do keys[#keys+1] = key end
    for _, key in ipairs(VBC.OPTIONAL_BANNED_CARDS) do
        if G.P_CENTERS and G.P_CENTERS[key] then keys[#keys+1] = key end
    end
    challenge.restrictions.banned_cards = ban_list(keys)

    VBC.current_variant = variant
    return variant
end

-- G.CHALLENGES[i] can be replaced by Steamodded's copy, so always look it up.
local get_challenge_int_from_id_ref = get_challenge_int_from_id
function VBC.base_challenge()
    local index = get_challenge_int_from_id_ref(VBC.CHALLENGE_ID)
    return G.CHALLENGES[index], index
end

function get_challenge_int_from_id(id, ...)
    local variant = VBC.parse_variant_id(id)
    if not variant then return get_challenge_int_from_id_ref(id, ...) end
    local challenge, index = VBC.base_challenge()
    if challenge then VBC.apply_variant(challenge, variant) end
    return index
end

--------------------------------------------------------------------------------
-- Localization
--------------------------------------------------------------------------------

-- English is the fallback for every language; existing entries (e.g. from a
-- translation mod) win.
function VBC.inject_localization()
    local misc = G.localization and G.localization.misc
    if not misc then return end
    misc.challenge_names = misc.challenge_names or {}
    misc.v_text = misc.v_text or {}
    for k, v in pairs(VBC.LOC.challenge_names) do misc.challenge_names[k] = misc.challenge_names[k] or v end
    for k, v in pairs(VBC.LOC.v_text) do misc.v_text[k] = misc.v_text[k] or v end
end

local init_localization_ref = init_localization
function init_localization(...)
    VBC.inject_localization()
    return init_localization_ref(...)
end

local function center_name(set, key)
    local name = localize{type = 'name_text', set = set, key = key}
    if not name or name == 'ERROR' then
        name = G.P_CENTERS[key] and G.P_CENTERS[key].name or key
    end
    return name
end

--------------------------------------------------------------------------------
-- Run setup selectors (joker mode, deck, stake)
--------------------------------------------------------------------------------

local function stake_pool()
    return G.P_CENTER_POOLS and G.P_CENTER_POOLS.Stake or {}
end

local function profile_memory()
    local profile = G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    if not profile then return nil end
    profile.MEMORY = profile.MEMORY or {}
    return profile.MEMORY
end

local function remember(field, value)
    VBC['selected_'..field] = value
    local memory = profile_memory()
    if memory then memory['vbc_'..field] = value end
end

local function recall(field)
    local memory = profile_memory()
    return VBC['selected_'..field] or (memory and memory['vbc_'..field])
end

function VBC.get_selected_stake()
    local stake = tonumber(recall('stake')) or 1
    return math.max(1, math.min(math.floor(stake), math.max(#stake_pool(), 1)))
end

function VBC.get_local_variant()
    return VBC.sanitize_variant({mode = recall('mode'), deck = recall('deck')})
end

function VBC.stake_name(index)
    local stake = stake_pool()[index]
    if not stake then return tostring(index) end
    local name = localize{type = 'name_text', set = 'Stake', key = stake.key}
    if not name or name == 'ERROR' then name = stake.name or stake.key end
    return name
end

function VBC.mode_name(mode)
    local name = center_name('Joker', mode.joker)
    return mode.count > 1 and (mode.count..'x '..name) or name
end

-- Rebuilds the open challenge description so the joker preview, Rules and
-- Restrictions show the new mode. Deferred: the clicked cycle lives in that box.
local function refresh_description()
    G.E_MANAGER:add_event(Event({blocking = false, blockable = false, func = function()
        local area = G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID('challenge_area')
        local _, index = VBC.base_challenge()
        if area and area.config.oid == index and area.config.object then
            area.config.object:remove()
            area.config.object = UIBox{
                definition = G.UIDEF.challenge_description(index),
                config = {offset = {x = 0, y = 0}, align = 'cm', parent = area},
            }
        end
        return true
    end}))
end

G.FUNCS.vbc_change_mode = function(args)
    remember('mode', VBC.MODES[args.to_key] and VBC.MODES[args.to_key].key)
    refresh_description()
end

G.FUNCS.vbc_change_deck = function(args)
    remember('deck', VBC.deck_options()[args.to_key])
end

G.FUNCS.vbc_change_stake = function(args)
    remember('stake', args.to_key)
end

-- Compact cycles with no label: the option text already reads as a joker,
-- "... Deck" or "... Stake", and one row keeps the panel at its vanilla height.
local function selector(options, current, callback)
    return {n=G.UIT.C, config={align = "cm"}, nodes={
        create_option_cycle({
            options = options,
            current_option = current,
            opt_callback = callback,
            colour = G.C.RED,
            w = 3.35,
            scale = 0.6,
            text_scale = 0.5,
            no_pips = true,
        }),
    }}
end

function VBC.create_selectors()
    local variant = VBC.get_local_variant()

    local modes, current_mode = {}, 1
    for i, mode in ipairs(VBC.MODES) do
        modes[i] = VBC.mode_name(mode)
        if mode.key == variant.mode then current_mode = i end
    end

    local decks, current_deck = {}, 1
    for i, key in ipairs(VBC.deck_options()) do
        decks[i] = center_name('Back', key)
        if key == variant.deck then current_deck = i end
    end

    local stakes = {}
    for i = 1, #stake_pool() do stakes[i] = VBC.stake_name(i) end

    return {
        selector(modes, current_mode, 'vbc_change_mode'),
        selector(decks, current_deck, 'vbc_change_deck'),
        selector(stakes, VBC.get_selected_stake(), 'vbc_change_stake'),
    }
end

-- Finds the node whose `nodes` list contains the start_challenge_run button.
-- Uses table.maxn because UI node lists can contain nil holes.
local function find_play_button(node)
    if type(node) ~= 'table' or type(node.nodes) ~= 'table' then return end
    for i = 1, table.maxn(node.nodes) do
        local child = node.nodes[i]
        if type(child) == 'table' then
            if child.config and child.config.button == 'start_challenge_run' then return node, i end
            local parent, index = find_play_button(child)
            if parent then return parent, index end
        end
    end
end

local function in_vbc_run()
    return G.STAGE == G.STAGES.RUN and G.GAME and G.GAME.challenge == VBC.CHALLENGE_ID
end

local challenge_description_ref = G.UIDEF.challenge_description
function G.UIDEF.challenge_description(_id, daily, is_row)
    local challenge = G.CHALLENGES[_id]
    local is_vbc = is_vbc_challenge(challenge)
    -- In a run, show the run's variant. In the challenge menu, show the player's
    -- choice. Elsewhere (Multiplayer lobby deck view) keep the last resolved one.
    if is_vbc and in_vbc_run() then
        if G.GAME.vbc_variant then VBC.apply_variant(challenge, G.GAME.vbc_variant) end
    elseif is_vbc and not is_row then
        VBC.apply_variant(challenge, VBC.get_local_variant())
    end

    local t = challenge_description_ref(_id, daily, is_row)

    if is_vbc and not is_row then
        local parent, index = find_play_button(t)
        if parent then
            local play_button = parent.nodes[index]
            play_button.config.minw = 2.2
            local row = VBC.create_selectors()
            row[#row+1] = {n=G.UIT.C, config={align = "cm", padding = 0.05}, nodes={play_button}}
            parent.nodes[index] = {n=G.UIT.R, config={align = "cm"}, nodes=row}
        end
    end
    return t
end

-- Vanilla always starts challenges on White Stake. Multiplayer hooks
-- G.FUNCS.start_run, reads args.stake and syncs args.challenge.id to the lobby,
-- so in a lobby the id carries the variant.
local start_challenge_run_ref = G.FUNCS.start_challenge_run
G.FUNCS.start_challenge_run = function(e)
    local challenge = e and e.config and G.CHALLENGES[e.config.id]
    if not is_vbc_challenge(challenge) then return start_challenge_run_ref(e) end

    local variant = VBC.apply_variant(challenge, VBC.get_local_variant())
    local run_challenge = challenge
    if MP and MP.LOBBY and MP.LOBBY.code then
        run_challenge = setmetatable({id = VBC.variant_id(variant)}, {__index = challenge})
    end

    if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
    G.FUNCS.start_run(e, {stake = VBC.get_selected_stake(), challenge = run_challenge})
end

--------------------------------------------------------------------------------
-- Negative jokers -> Polychrome
--------------------------------------------------------------------------------

function VBC.no_negative_jokers()
    return G.GAME and G.GAME.modifiers and G.GAME.modifiers[VBC.NO_NEGATIVE_RULE] and true or false
end

-- Accepts every edition format vanilla and Steamodded pass to set_edition.
local function is_negative_edition(edition)
    if type(edition) == 'string' then return edition == 'e_negative' end
    if type(edition) ~= 'table' then return false end
    if edition.type then return edition.type == 'negative' end
    if edition.key then return edition.key == 'e_negative' end
    return edition.negative and true or false
end

-- Card:set_edition is the one funnel every Negative joker goes through (shop,
-- packs, tags, spectrals, other mods). Steamodded replaces set_edition after this
-- file loads, so the hook goes on at the first run start instead.
function VBC.install_runtime_hooks()
    if VBC.runtime_hooks_installed then return end
    VBC.runtime_hooks_installed = true

    local set_edition_ref = Card.set_edition
    function Card:set_edition(edition, ...)
        if VBC.no_negative_jokers()
        and not self.jimbo -- talking Jimbo characters are UI, not jokers
        and self.ability and self.ability.set == 'Joker'
        and is_negative_edition(edition) then
            edition = {polychrome = true}
        end
        return set_edition_ref(self, edition, ...)
    end
end

local start_run_ref = Game.start_run
function Game:start_run(args)
    VBC.install_runtime_hooks()
    VBC.register_with_smods(true) -- fallback if smods_entry.lua didn't run

    local new_vbc_run = false
    if args and not args.savetext and type(args.challenge) == 'table' then
        local variant = VBC.parse_variant_id(args.challenge.id)
        if variant or is_vbc_challenge(args.challenge) then
            local challenge = VBC.base_challenge()
            if challenge then
                -- A bare id means the variant was already applied by whoever chose it.
                VBC.apply_variant(challenge, variant or VBC.current_variant or VBC.get_local_variant())
                args.challenge = challenge
                new_vbc_run = true
            end
        end
    end

    local ret = start_run_ref(self, args)

    if new_vbc_run then
        self.GAME.vbc_variant = VBC.sanitize_variant(VBC.current_variant)
    elseif args and args.savetext and self.GAME.challenge == VBC.CHALLENGE_ID and self.GAME.vbc_variant then
        local challenge = VBC.base_challenge()
        if challenge then VBC.apply_variant(challenge, self.GAME.vbc_variant) end
    end
    return ret
end
