local mod = EdithVestige
local enums = mod.Enums
local players = enums.PlayerType
local costumes = enums.NullItemID
local utils = enums.Utils
local tables = enums.Tables
local level = utils.Level
local game = utils.Game 
local JumpParams = tables.JumpParams
local data = mod.getData
local Edith = {}

---@param player EntityPlayer
---@return integer
local function GetNumTears(player)
	return player:GetMultiShotParams(WeaponType.WEAPON_TEARS):GetNumTears()
end
---@param player EntityPlayer
function Edith:EdithInit(player)
	if not mod.IsEdith(player) then return end
	mod.SetNewANM2(player, "gfx/EdithAnim.anm2")
	mod.ForceCharacterCostume(player, players.PLAYER_EDITH, costumes.ID_EDITH_SCARF)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Edith.EdithInit)

local JumpAnims = {
	["BigJumpUp"] = true,
	["BigJumpFinish"] = true,
}

---@param sprite Sprite
---@return boolean
local function IsPlayingJumpAnim(sprite)
	return mod.When(sprite:GetAnimation(), JumpAnims, false)
end

---@param player EntityPlayer
function Edith:EdithJumpHandler(player)
	if not mod.IsEdith(player) then return end

	local playerData = data(player)
	if player:IsDead() then mod.RemoveEdithTarget(player); playerData.isJumping = false return end

	local isMoving = mod.IsEdithTargetMoving(player)
	local isKeyStompPressed = mod:IsKeyStompTriggered(player)
	local hasMarked = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED)
	local isShooting = mod:IsPlayerShooting(player)
	local jumpData = JumpLib:GetData(player)
	local isPitfall = JumpLib:IsPitfalling(player)
	local isJumping = jumpData.Jumping 
	local sprite = player:GetSprite()
	local jumpInternalData = JumpLib.Internal:GetData(player)
	local IsGnawedLeafPetrified = player:GetGnawedLeafTimer() >= 65

	EdithVestige.ManageEdithWeapons(player)
	playerData.isJumping = playerData.isJumping or false

	if player.FrameCount > 0 and (isMoving or isKeyStompPressed or (hasMarked and isShooting)) and not isPitfall then
		mod.SpawnEdithTarget(player)
	end

	if not isJumping and not (game:GetRoom():GetType() == RoomType.ROOM_DUNGEON) then
		player:MultiplyFriction(0.35)
	end

	local target = mod.GetEdithTarget(player)
	if not target then return end

	local targetSprite = target:GetSprite()

	local friction
	if isMoving then
		local input = {
			up = Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex),
			down = Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex),
			left = Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex),
			right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex),
		}

		local VectorX = ((input.left > 0.3 and -input.left) or (input.right > 0.3 and input.right) or 0) * (game:GetRoom():IsMirrorWorld() and -1 or 1)
		local VectorY = ((input.up > 0.3 and -input.up) or (input.down > 0.3 and input.down) or 0)
		friction = targetSprite:IsPlaying("Blink") and 0.6 or 0.775

		target.Velocity = target.Velocity + Vector(VectorX, VectorY):Normalized():Resized(4)
	end

	local newfriction = (friction or 0.8) * ((IsGnawedLeafPetrified and not isJumping) and 0.6 or 1) 

	target:MultiplyFriction(newfriction)

	if isKeyStompPressed and not IsPlayingJumpAnim(sprite) then
		player:PlayExtraAnimation("BigJumpUp")
		player:SetMinDamageCooldown(12)
		targetSprite:Play("Blink")
	end

	if sprite:IsEventTriggered("StartJump") and not isJumping then
        mod.InitVestigeJump(player)
    end

	if jumpInternalData.UpdateFrame and jumpInternalData.UpdateFrame > 6 then
		mod.EdithDash(player, mod.GetEdithTargetDirection(player), mod.GetEdithTargetDistance(player), 50)
	end

	if target and JumpLib:IsFalling(player) then
		player.Position = target.Position
	end
	
	local dir = mod.GetEdithTargetDistance(player) <= 5 and Direction.DOWN or mod.VectorToDirection(mod.GetEdithTargetDirection(player))
	
	if not (isJumping or (not isShooting) or (isKeyStompPressed)) then return end
	player:SetHeadDirection(dir, 1, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Edith.EdithJumpHandler)

---@param player EntityPlayer
local function IsInTrapdoor(player)
	local room = game:GetRoom()
	local grid = room:GetGridEntityFromPos(player.Position)

	return grid and grid:GetType() == GridEntityType.GRID_TRAPDOOR or false
end	

---@param player EntityPlayer
function Edith:OnStartingJump(player)
	local pdata = data(player)

	pdata.JumpStartPos = player.Position
	pdata.JumpStartDist = mod.GetEdithTargetDistance(player)

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then return end
	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_LUMP_OF_COAL)
	pdata.CoalBonus = mod.RandomFloat(rng, 0.5, 0.6) * mod.GetEdithTargetDistance(player) / 40
end
mod:AddCallback(JumpLib.Callbacks.POST_ENTITY_JUMP, Edith.OnStartingJump, JumpParams.EdithJump)

---@param player EntityPlayer
---@param pitfall boolean
function Edith:EdithLanding(player, _, pitfall)
	local playerData = data(player)
	local edithTarget = mod.GetEdithTarget(player)

	if not edithTarget then return end

	if pitfall then
		mod.RemoveEdithTarget(player)
		playerData.isJumping = false
		return
	end

	if not IsInTrapdoor(player) then
		mod.LandFeedbackManager(player, player.Color)
	else
		JumpLib:QuitJump(player)
		mod.RemoveEdithTarget(player)
		return
	end

	local IsGnawedLeafPetrified = player:GetGnawedLeafTimer() >= 65
	local CanFly = player.CanFly
	local flightMult = {
		Damage = CanFly == true and 1.5 or 1,
		Knockback = CanFly == true and 1.2 or 1,
		Radius = CanFly == true and 1.3 or 1,
	}
	local chapter = math.ceil(level:GetStage() / 2)
	local playerDamage = player.Damage
	local radius = math.min((35 + ((player.TearRange / 40) - 9) * 2) * flightMult.Radius, 90)
	local knockbackFormula = (math.min(50, (16 ^ 1.2) * flightMult.Knockback) * player.ShotSpeed) * (IsGnawedLeafPetrified and 1.2 or 1)
	local coalBonus = playerData.CoalBonus or 0
	local damageBase = 15 + (5.75 * (chapter - 1))
	local DamageStat = playerDamage + ((playerDamage / 5.25) - 1)
	local multishotMult = mod.Round(mod.exp(GetNumTears(player), 1, 0.68), 2)
	local birthrightMult = mod.PlayerHasBirthright(player) and 1.25 or 1
	local bloodClotMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_CLOT) and 1.1 or 1
	local RawFormula = (((((damageBase + (DamageStat)) * multishotMult) * birthrightMult) * bloodClotMult) * flightMult.Damage) + coalBonus
	
	local damageFormula = math.max(mod.Round(RawFormula, 2), 1) * (IsGnawedLeafPetrified and 1.35 or 1)

	player:PlayExtraAnimation("BigJumpFinish")

	mod:EdithStomp(player, radius, damageFormula, knockbackFormula, true)
	edithTarget:GetSprite():Play("Idle")

	player:MultiplyFriction(0.05)
	player:SetMinDamageCooldown(18)

	mod.RemoveEdithTarget(player)
	playerData.IsFalling = false	
	playerData.isJumping = false
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, Edith.EdithLanding, JumpParams.EdithJump)

function Edith:EdithOnNewRoom()
	for _, player in pairs(PlayerManager.GetPlayers()) do
		if not mod.IsEdith(player) then goto Break end
		mod:ChangeColor(player, _, _, _, 1)
		mod.RemoveEdithTarget(player)
		::Break::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Edith.EdithOnNewRoom)

---@param player EntityPlayer
function Edith:EdithRender(player)
	local sprite = player:GetSprite()
	
	if not mod.IsEdith(player) then return end
	if not IsInTrapdoor(player) then return end
	if not sprite:IsPlaying("Trapdoor") then return end
	if sprite:GetFrame() ~= 8 then return end

	game:StartStageTransition(false, 0, player)
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, Edith.EdithRender)

---@param damage number
---@param source EntityRef
---@return boolean?
function Edith:DamageStuff(_, damage, _, source)
	if source.Type == 0 then return end
	local ent = source.Entity
	local familiar = ent:ToFamiliar()
	local player = mod.GetPlayerFromRef(source)

	if not player then return end
	if not mod.IsEdith(player) then return end
	if not JumpLib:GetData(player).Jumping then return end  
	local HasHeels = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_HEELS)

	if not (familiar or (HasHeels and damage == 12)) then return end
	return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Edith.DamageStuff)

---@param ID CollectibleType
---@param player EntityPlayer
function Edith:OnActiveItemRemoveTarget(ID, _, player)
	if not mod.When(ID, tables.RemoveTargetItems, false) then return end
	mod.RemoveEdithTarget(player)
end
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, Edith.OnActiveItemRemoveTarget)

---@param entity Entity
---@param input InputHook
---@param action ButtonAction|KeySubType
---@return integer|boolean?
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function (_, entity, input, action)
    if not entity then return end
    local player = entity:ToPlayer()

    if not player then return end
    if not mod.IsEdith(player) then return end
    if input ~= InputHook.GET_ACTION_VALUE then return end

    return tables.OverrideActions[action]
end)

---@param player EntityPlayer
---@param cacheFlag CacheFlag
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cacheFlag)
    if not mod.IsEdith(player) then return end
    if cacheFlag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage * 1.5
    elseif cacheFlag == CacheFlag.CACHE_RANGE then
        player.TearRange = mod.rangeUp(player.TearRange, 4.25)
    end
end)

---@param player EntityPlayer
---@param flags DamageFlag
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function(_, player, _, flags)
    local roomType = game:GetRoom():GetType()

    if not mod.IsEdith(player) then return end
	if mod.HasBitFlags(flags, DamageFlag.DAMAGE_ACID) or (roomType ~= RoomType.ROOM_SACRIFICE and mod.HasBitFlags(flags, DamageFlag.DAMAGE_SPIKES)) then return false end
end)

mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
    local player = mod:GetPlayerFromTear(tear)

	if not player then return end
    if not mod.IsEdith(player) then return end

	mod.ForceSaltTear(tear)

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end	
	local target = mod.GetEdithTarget(player)

	if not target then return end
	tear.Velocity = mod.ChangeVelToTarget(tear, target, player.ShotSpeed * 10)
end)