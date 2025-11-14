local mod = EdithVestige
local enums = mod.Enums
local items = enums.CollectibleType
local sounds = enums.SoundEffect
local misc = enums.Misc
local utils = enums.Utils
local sfx = utils.SFX
local SaltQuantity = 14
local degree = 360 / SaltQuantity
local SaltShaker = {}

---@param rng RNG
---@param player EntityPlayer
---@param flag UseFlag
---@return boolean?
function SaltShaker:UseSaltShaker(_, rng, player, flag)	
	if mod.HasBitFlags(flag, UseFlag.USE_CARBATTERY) then return end
    local hasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) 
	local playerPos = player.Position

	for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, enums.SubTypes.SALT_CREEP)) do
		entity:ToEffect():SetTimeout(1)
	end

	for i = 1, SaltQuantity do	
		mod:SpawnSaltCreep(player, playerPos + misc.SaltShakerDist:Rotated(degree * i), 0, hasCarBattery and 12 or 6, 1, 4.5)
	end

	sfx:Play(sounds.SOUND_SALT_SHAKER, 2, 0, false, mod.RandomFloat(rng, 0.9, 1.1), 0)
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, SaltShaker.UseSaltShaker, items.COLLECTIBLE_SALTSHAKER)