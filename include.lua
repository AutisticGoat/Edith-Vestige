local scriptsPath = "resources/scripts/"
local col = "collectibles/"
local ent = "entities/"
local stmpSyn = "stompSynergies/"
local parrySyn = "parrySynergies/"
local funcs = "functions/"
local libs = "libs/"

local includeFiles = {
	-- Cosas necesarias
	"definitions",
	funcs .. "functions",
	libs .. "prenpckillcallback",
	libs .. "EdithKotryHudHelper",
	libs .. "status_effect_library",
	libs .. "CustomShockwaveAPI",

	-- Items
	col .. "items/Edith/SaltShaker",

	-- Entidades
	ent .. "Effects/Creeps",
	ent .. "Effects/Targets",
	-- Entidades fin

	-- Personajes
	ent .. "Players/Edith",
	-- Personajes fin

	"challenges/Vestige",

	-- sinergias pisotones
	stmpSyn .. "blackPowder",
	stmpSyn .. "brimstone",
	stmpSyn .. "techX",
	stmpSyn .. "MomsKnife",
	stmpSyn .. "Rockwaves",
	stmpSyn .. "SpiritSword",
	stmpSyn .. "EpicFetus",
	stmpSyn .. "StatusEffects",
	stmpSyn .. "GodHead",
	stmpSyn .. "Technology",

	parrySyn .. "Brimstone",
}

for _, v in ipairs(includeFiles) do
	include(scriptsPath .. v)
end
