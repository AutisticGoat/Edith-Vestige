local mod = EdithVestige
local enums = mod.Enums
local subtype = enums.SubTypes

---@param effect EntityEffect 
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, effect)
    if effect.SubType ~= subtype.SALT_CREEP then return end
    effect:GetSprite():Play("SmallBlood0" .. tostring(effect:GetDropRNG():RandomInt(1, 6)), true)
end, EffectVariant.PLAYER_CREEP_RED)

---@param effect EntityEffect
local function SaltCreepUpdate(effect)
    if effect.SubType ~= subtype.SALT_CREEP then return end
    local player = effect.SpawnerEntity:ToPlayer() 

    if not player then return end

    for _, entity in pairs(Isaac.FindInRadius(effect.Position, 20 * effect.SpriteScale.X, EntityPartition.ENEMY)) do
        entity:AddFear(EntityRef(player), 120)
    end
end

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    SaltCreepUpdate(effect)
end, EffectVariant.PLAYER_CREEP_RED)