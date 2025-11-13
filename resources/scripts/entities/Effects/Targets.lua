local mod = EdithVestige
local enums = mod.Enums
local Vars = enums.EffectVariant 
local game = enums.Utils.Game

local teleportPoints = {
	Vector(110, 135),
	Vector(595, 385),
	Vector(595, 272),
}

---@param effect EntityEffect
local function IsAnyEdithTarget(effect)
    local var = effect.Variant
    return var == Vars.EFFECT_EDITH_TARGET or var == Vars.EFFECT_EDITH_B_TARGET
end

local function interpolateVector2D(vectorA, vectorB, t)
	local minT = (1 - t)
    return Vector(minT * vectorA.X + t * vectorB.X, minT * vectorA.Y + t * vectorB.Y)
end

---@param effect EntityEffect
---@param player EntityPlayer
local function EdithTargetManagement(effect, player)
	if effect.Variant ~= Vars.EFFECT_EDITH_TARGET then return end

	local playerPos = player.Position
	local effectPos = effect.Position
	local room = game:GetRoom()

	if mod.IsKeyStompPressed(player) then
		effect:GetSprite():Play("Blink")
	end

	room:GetCamera():SetFocusPosition(interpolateVector2D(playerPos, effectPos, 0.6))

	if room:GetType() == RoomType.ROOM_DUNGEON then
		for _, v in pairs(teleportPoints) do
			if (effectPos - v):Length() > 20 then break end
			player.Position = effectPos + effect.Velocity:Normalized():Resized(25)
		end
	end
end

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
	if not IsAnyEdithTarget(effect) then return end
	local player = effect.SpawnerEntity:ToPlayer()

    if not player then return end
	mod:TargetDoorManager(effect, player, effect.Variant == Vars.EFFECT_EDITH_TARGET and 28 or 20)
    EdithTargetManagement(effect, player)
end)

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, function(_, effect)
	effect.Color:SetTint(1, 0, 0, 1)
	if game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return false end
end)