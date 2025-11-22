local mod = EdithVestige
local enums = mod.Enums
local Vars = enums.EffectVariant 
local game = enums.Utils.Game
local level = enums.Utils.Level

local teleportPoints = {
	Vector(110, 135),
	Vector(595, 385),
	Vector(595, 272),
	Vector(595, 415),
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
	local markedTarget = player:GetMarkedTarget()

	room:GetCamera():SetFocusPosition(interpolateVector2D(player.Position, effectPos, 0.6))

	if markedTarget then 
		markedTarget.Position = effectPos
		markedTarget.Velocity = Vector.Zero
		markedTarget.Color = Color(0, 0, 0, 0)
	end

	local gridPos = room:GetGridEntityFromPos(effect.Position)
	local RoomName = level:GetCurrentRoomDesc().Data.Name

	if gridPos then
		if gridPos:GetType() == GridEntityType.GRID_GRAVITY and RoomName ~= "Beast Room" then
			effect.Velocity = effect.Velocity + Vector(0, 8)
		end
	end

	if room:GetType() ~= RoomType.ROOM_DUNGEON then return end

	for _, v in pairs(teleportPoints) do
		if (effectPos - v):Length() > 20 then goto continue end
		if RoomName == "Rotgut Maggot" and (v.X == 110 and v.Y == 135) then goto continue end
		player.Position = effectPos + effect.Velocity:Normalized():Resized(25)
	    ::continue::
	end
end

---@param npc EntityNPC
function mod:OnRotGutPhase2Update(npc)
	if npc.Variant ~= 1 then return end

	for _, ent in ipairs(Isaac.FindInCapsule(npc:GetCollisionCapsule(), EntityPartition.EFFECT)) do
		if ent.Variant ~= Vars.EFFECT_EDITH_TARGET then goto continue end		
		local player = ent.SpawnerEntity:ToPlayer()

		if not player then goto continue end

		ent.Velocity = (player.Position - npc.Position):Resized(20)

		::continue::
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.OnRotGutPhase2Update, EntityType.ENTITY_ROTGUT)

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