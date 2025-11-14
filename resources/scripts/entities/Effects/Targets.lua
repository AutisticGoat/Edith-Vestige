local mod = EdithVestige
local enums = mod.Enums
local Vars = enums.EffectVariant 
local game = enums.Utils.Game

local teleportPoints = {
	Vector(110, 135),
	Vector(595, 385),
	Vector(595, 272),
}

local function interpolateVector2D(vectorA, vectorB, t)
	local minT = (1 - t)
    return Vector(minT * vectorA.X + t * vectorB.X, minT * vectorA.Y + t * vectorB.Y)
end

---@param effect EntityEffect
---@param player EntityPlayer
local function EdithTargetManagement(effect, player)
	if effect.Variant ~= Vars.EFFECT_EDITH_TARGET then return end

	local effectPos = effect.Position
	local room = game:GetRoom()

	room:GetCamera():SetFocusPosition(interpolateVector2D(player.Position, effectPos, 0.6))

	local markedTarget = player:GetMarkedTarget()

	if markedTarget then 
		markedTarget.Position = effectPos
		markedTarget.Velocity = Vector.Zero
		markedTarget.Color = Color(0, 0, 0, 0)
	end

	if room:GetType() ~= RoomType.ROOM_DUNGEON then return end
	for _, v in pairs(teleportPoints) do
		if (effectPos - v):Length() > 20 then break end
		player.Position = effectPos + effect.Velocity:Normalized():Resized(25)
	end
end

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
	local player = effect.SpawnerEntity:ToPlayer()

    if not player then return end
	mod:TargetDoorManager(effect, player, 28)
    EdithTargetManagement(effect, player)
end, Vars.EFFECT_EDITH_TARGET)

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, function(_, effect)
	effect.Color = Color(1, 0, 0, 1)
	if game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return false end
end, Vars.EFFECT_EDITH_TARGET)