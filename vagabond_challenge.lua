
--------------------------------------------------------------------------------
-- Vagabond Challenge
--
-- Appended to challenges.lua by Lovely. Needs only Lovely; also works alongside
-- Steamodded and the Balatro Multiplayer mod.
--------------------------------------------------------------------------------

VagabondChallenge = VagabondChallenge or {}
local VBC = VagabondChallenge

VBC.VERSION = '1.0.0'
VBC.CHALLENGE_ID = 'c_vbc_vagabond_1'
VBC.NO_NEGATIVE_RULE = 'vbc_no_negative_jokers'

-- Everything that could give a second joker slot.
VBC.BANNED_CARDS = {'c_ectoplasm', 'v_blank', 'v_antimatter'}
-- Modded equivalents, banned only when the mod that adds them is loaded.
VBC.OPTIONAL_BANNED_CARDS = {
    'c_mp_ectoplasm_sandbox', -- Multiplayer's Sandbox ruleset Ectoplasm
}

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

-- Rebuilds the ban list once every mod's cards exist, adding modded equivalents.
function VBC.refresh_bans(challenge)
    local keys = {}
    for _, key in ipairs(VBC.BANNED_CARDS) do keys[#keys+1] = key end
    for _, key in ipairs(VBC.OPTIONAL_BANNED_CARDS) do
        if G.P_CENTERS and G.P_CENTERS[key] then keys[#keys+1] = key end
    end
    challenge.restrictions.banned_cards = ban_list(keys)
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

--------------------------------------------------------------------------------
-- Stake selection
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

function VBC.get_selected_stake()
    local memory = profile_memory()
    local stake = tonumber(VBC.selected_stake or (memory and memory.vbc_stake)) or 1
    return math.max(1, math.min(math.floor(stake), math.max(#stake_pool(), 1)))
end

function VBC.stake_name(index)
    local stake = stake_pool()[index]
    if not stake then return tostring(index) end
    local name = localize{type = 'name_text', set = 'Stake', key = stake.key}
    if not name or name == 'ERROR' then name = stake.name or stake.key end
    return name
end

G.FUNCS.vbc_change_stake = function(args)
    VBC.selected_stake = args.to_key
    local memory = profile_memory()
    if memory then memory.vbc_stake = args.to_key end
end

function VBC.create_stake_selector()
    local options = {}
    for i = 1, #stake_pool() do options[i] = VBC.stake_name(i) end
    return {n=G.UIT.C, config={align = "cm", padding = 0.05}, nodes={
        {n=G.UIT.C, config={align = "cm", padding = 0.05}, nodes={
            {n=G.UIT.T, config={text = localize('k_stake'), scale = 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
        }},
        {n=G.UIT.C, config={align = "cm"}, nodes={
            create_option_cycle({
                options = options,
                current_option = VBC.get_selected_stake(),
                opt_callback = 'vbc_change_stake',
                colour = G.C.RED,
                w = 3.4,
                scale = 0.8,
                no_pips = true,
            }),
        }},
    }}
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

local challenge_description_ref = G.UIDEF.challenge_description
function G.UIDEF.challenge_description(_id, daily, is_row)
    local challenge = G.CHALLENGES[_id]
    if is_vbc_challenge(challenge) then VBC.refresh_bans(challenge) end

    local t = challenge_description_ref(_id, daily, is_row)

    if is_vbc_challenge(challenge) and not is_row then
        local parent, index = find_play_button(t)
        if parent then
            local play_button = parent.nodes[index]
            play_button.config.minw = 5.5
            parent.nodes[index] = {n=G.UIT.R, config={align = "cm"}, nodes={
                VBC.create_stake_selector(),
                {n=G.UIT.C, config={align = "cm", padding = 0.05}, nodes={play_button}},
            }}
        end
    end
    return t
end

-- Vanilla always starts challenges on White Stake. Multiplayer hooks
-- G.FUNCS.start_run and reads args.stake, so the choice reaches lobbies too.
local start_challenge_run_ref = G.FUNCS.start_challenge_run
G.FUNCS.start_challenge_run = function(e)
    local challenge = e and e.config and G.CHALLENGES[e.config.id]
    if not is_vbc_challenge(challenge) then return start_challenge_run_ref(e) end

    if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
    G.FUNCS.start_run(e, {stake = VBC.get_selected_stake(), challenge = challenge})
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
    if args and not args.savetext and is_vbc_challenge(args.challenge) then
        VBC.refresh_bans(args.challenge)
    end
    return start_run_ref(self, args)
end
