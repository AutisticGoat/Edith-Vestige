

---@diagnostic disable: undefined-global, param-type-mismatch, inject-field
local mod = EdithVestige

local GLOWING_HOURGLASS_DATA = {}
local TEMPORARY_DATA = {}

local function copyTable(sourceTab)
	local targetTab = {}
	sourceTab = sourceTab or {}
	
	if type(sourceTab) ~= "table" then
		error("[ERROR] - cucco_helper.copyTable - invalid argument #1, table expected, got " .. type(sourceTab), 2)
	end

	for i, v in pairs(sourceTab) do
		if type(v) == "table" then
			targetTab[i] = copyTable(sourceTab[i])
		else
			targetTab[i] = sourceTab[i]
		end
	end
	
	return targetTab
end

function mod:postGlowingHourglassSave(slot)
	slot = slot + 1
	GLOWING_HOURGLASS_DATA[slot] = GLOWING_HOURGLASS_DATA[slot] or {}

    GLOWING_HOURGLASS_DATA[slot].TEMPORARY_DATA = copyTable(TEMPORARY_DATA)
	-- Custom Health API automatically handles Glowing Hourglass
end

function mod:preGlowingHourglassLoad(slot)
	slot = slot + 1
	GLOWING_HOURGLASS_DATA[slot] = GLOWING_HOURGLASS_DATA[slot] or {}
    TEMPORARY_DATA = copyTable(GLOWING_HOURGLASS_DATA[slot].TEMPORARY_DATA)
	-- Custom Health API automatically handles Glowing Hourglass
end

function mod:resetTemporaryData(entity)
	local hash = tostring(GetPtrHash(entity))
	TEMPORARY_DATA[hash] = nil
end

mod:AddPriorityCallback(ModCallbacks.MC_POST_GLOWING_HOURGLASS_SAVE, -200, mod.postGlowingHourglassSave)
mod:AddPriorityCallback(ModCallbacks.MC_PRE_GLOWING_HOURGLASS_LOAD, -200, mod.preGlowingHourglassLoad)
mod:AddPriorityCallback(ModCallbacks.MC_FAMILIAR_INIT, -200, mod.resetTemporaryData)
mod:AddPriorityCallback(ModCallbacks.MC_POST_NPC_INIT, -200, mod.resetTemporaryData)
mod:AddPriorityCallback(ModCallbacks.MC_POST_TEAR_INIT, -200, mod.resetTemporaryData)
mod:AddPriorityCallback(ModCallbacks.MC_POST_BOMB_INIT, -200, mod.resetTemporaryData)
mod:AddPriorityCallback(ModCallbacks.MC_POST_SLOT_INIT, -200, mod.resetTemporaryData)
mod:AddPriorityCallback(ModCallbacks.MC_POST_LASER_INIT, -200, mod.resetTemporaryData)
mod:AddPriorityCallback(ModCallbacks.MC_POST_KNIFE_INIT, -200, mod.resetTemporaryData)
mod:AddPriorityCallback(ModCallbacks.MC_POST_PLAYER_INIT, -200, mod.resetTemporaryData)
mod:AddPriorityCallback(ModCallbacks.MC_POST_PICKUP_INIT, -200, mod.resetTemporaryData)
mod:AddPriorityCallback(ModCallbacks.MC_POST_EFFECT_INIT, -200, mod.resetTemporaryData)
mod:AddPriorityCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, -200, mod.resetTemporaryData)

--- Alternative to Entity::GetData()
---
--- Acts as a localized version to avoid incompatibilities with
--- other mods.
---@param entity Entity
---@return table
function EdithVestige.getData(entity)
	local hash = GetPtrHash(entity)
	TEMPORARY_DATA[hash] = TEMPORARY_DATA[hash] or {}

	return TEMPORARY_DATA[hash]
end

local enums = mod.Enums
local effectVariant = enums.EffectVariant
local utils = enums.Utils
local game = utils.Game
local level = utils.Level
local sfx = utils.SFX
local tables = enums.Tables
local jumpTags = tables.JumpTags
local jumpFlags = tables.JumpFlags
local misc = enums.Misc
local players = enums.PlayerType
local sounds = enums.SoundEffect
local data = mod.getData

local MortisBackdrop = {
	FLESH = 1,
	MOIST = 2,
	MORGUE = 3
}

---Checks if player is Edith
---@param player EntityPlayer
---@return boolean
function EdithVestige.IsEdith(player)
	return player:GetPlayerType() == (players.PLAYER_EDITH)
end

---Checks if Edith's target is moving
---@param player EntityPlayer
---@return boolean
function EdithVestige.IsEdithTargetMoving(player)
	local k_up = Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex)
    local k_down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex)
    local k_left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex)
    local k_right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex)
	
    return (k_down or k_right or k_left or k_up) or false
end

--[[Perform a Switch/Case-like selection.  
    `value` is used to index `cases`.  
    When `value` is `nil`, returns `default`.  
    **Note:** Type inference on this function is decent, but not perfect.
    You might want to use things such as [casting](https://luals.github.io/wiki/annotations/#as)
    the returned value.
    ]]
---@generic In, Out, Default
---@param value?    In
---@param cases     { [In]: Out }
---@param default?  Default
---@return Out|Default
function EdithVestige.When(value, cases, default)
    return value and cases[value] or default
end

--[[Perform a Switch/Case-like selection, like @{EdithVestige.When}, but takes a
    table of functions and runs the found matching case to return its result.  
    `value` is used to index `cases`.
    When `value` is `nil`, returns `default`, or runs it and returns its value if
    it is a function.  
    **Note:** Type inference on this function is decent, but not perfect.
    You might want to use things such as [casting](https://luals.github.io/wiki/annotations/#as)
    the returned value.
    ]]
---@generic In, Out, Default
---@param value? In
---@param cases { [In]: fun(): Out }
---@param default?  fun(): Default
---@return Out|Default
function EdithVestige.WhenEval(value, cases, default)
    local f = mod.When(value, cases)
    local v = (f and f()) or (default and default())
    return v
end

---@param player EntityPlayer
function EdithVestige.PlayerHasBirthright(player)
	return player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
end

---Helper function for Edith's cooldown color manager
---@param player EntityPlayer
---@param intensity number
---@param duration integer
function EdithVestige.SetColorCooldown(player, intensity, duration)
	local pcolor = player.Color
	local col = pcolor:GetColorize()
	local tint = pcolor:GetTint()
	local off = pcolor:GetOffset()
	local Red = off.R + (intensity + ((col.R + tint.R) * 0.2))
	local Green = off.G + (intensity + ((col.G + tint.G) * 0.2))
	local Blue = off.B + (intensity + ((col.B + tint.B) * 0.2))
		
	pcolor:SetOffset(Red, Green, Blue)
	player:SetColor(pcolor, duration, 100, true, false)
end

---Used to add some interactions to Judas' Birthright effect
---@param player EntityPlayer
function EdithVestige.IsJudasWithBirthright(player)
	return player:GetPlayerType() == PlayerType.PLAYER_JUDAS and mod.PlayerHasBirthright(player)
end

---Checks if player triggered Edith's jump action
---@param player EntityPlayer
---@return boolean
function EdithVestige:IsKeyStompTriggered(player)
	local k_stomp =
		Input.IsButtonTriggered(Keyboard.KEY_Z, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_LEFT_SHIFT, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_RIGHT_SHIFT, player.ControllerIndex) or
		Input.IsButtonTriggered(Keyboard.KEY_RIGHT_CONTROL, player.ControllerIndex) or
        Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex)
		
	return k_stomp
end

---Helper range stat manager function
---@param range number
---@param val number
---@return number
function EdithVestige.rangeUp(range, val)
    local currentRange = range / 40.0
    local newRange = currentRange + val
    return math.max(1.0, newRange) * 40.0
end

---Helper function to directly change `entity`'s color
---@param entity Entity
---@param red? number
---@param green? number
---@param blue? number
---@param alpha? number
function EdithVestige:ChangeColor(entity, red, green, blue, alpha)
	local color = entity.Color
	local Red = red or color.R
	local Green = green or color.G
	local Blue = blue or color.B
	local Alpha = alpha or color.A

	color:SetTint(Red, Green, Blue, Alpha)

	entity.Color = color
end

---Helper grid destroyer function
---@param entity Entity
---@param radius number
function EdithVestige:DestroyGrid(entity, radius)
	radius = radius or 10
	local room = game:GetRoom()

	for i = 0, room:GetGridSize() do
		local grid = room:GetGridEntity(i)
		if not grid then goto Break end  
		if entity.Position:Distance(grid.Position) > radius then goto Break end
		grid:Destroy(false)
		::Break::
	end
end

---Helper function for a better management of random floats, allowing to use min and max values, like `math.random()` and `RNG:RandomInt()`
---@param rng? RNG if `nil`, the function will use Mod's `RNG` object instead
---@param min number
---@param max? number if `nil`, returned number will be one between 0 and `min`
function EdithVestige.RandomFloat(rng, min, max)
	if not max then
		max = min
		min = 0
	end

	min = min * 1000
	max = max * 1000

	return (rng or utils.RNG):RandomInt(min, max) / 1000
end

---Manages Edith's Target and Tainted Edith's arrow behavior when going trough doors
---@param effect EntityEffect
---@param player EntityPlayer
---@param triggerDistance number
function EdithVestige:TargetDoorManager(effect, player, triggerDistance)
	local room = game:GetRoom()
	local effectPos = effect.Position
	local roomName = level:GetCurrentRoomDesc().Data.Name
	local MirrorRoomCheck = roomName == "Mirror Room" and player:HasInstantDeathCurse()
	local playerHasPhoto = (player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) or player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE))

	for i = 0, 7 do
		local door = room:GetDoor(i)
		if not door then goto Break end
		local sprite = door:GetSprite()
		local doorSpritePath = sprite:GetLayer(0):GetSpritesheetPath()
		local MausoleumRoomCheck = string.find(doorSpritePath, "mausoleum") ~= nil
		local StrangeDoorCheck = string.find(doorSpritePath, "mausoleum_alt") ~= nil
		local ShouldMoveToStrangeDoorPos = StrangeDoorCheck and sprite:WasEventTriggered("FX")
		local doorPos = room:GetDoorSlotPosition(i)

		if not (doorPos and effectPos:Distance(doorPos) <= triggerDistance) then 	
			if player.Color.A < 1 then
				mod:ChangeColor(player, _, _, _, 1)
			end
			goto Break 
		end

		if door:IsOpen() or MirrorRoomCheck or ShouldMoveToStrangeDoorPos then
			player.Position = doorPos
			mod.RemoveEdithTarget(player)
		elseif StrangeDoorCheck then
			if not playerHasPhoto then goto Break end
			door:TryUnlock(player)
		elseif MausoleumRoomCheck then
			if not sprite:IsPlaying("KeyOpen") then
				sprite:Play("KeyOpen")
			end

			if sprite:IsFinished("KeyOpen") then
				door:TryUnlock(player, true)
			end
		else
			mod:ChangeColor(player, 1, 1, 1, 1)
			door:TryUnlock(player)
		end
		::Break::
	end
end

---@param player EntityPlayer
function EdithVestige.ManageEdithWeapons(player)
	local weapon = player:GetWeapon(1)

	if not weapon then return end
	if not mod.When(weapon:GetWeaponType(), tables.OverrideWeapons, false) then return end
	local newWeapon = Isaac.CreateWeapon(WeaponType.WEAPON_TEARS, player)
	Isaac.DestroyWeapon(weapon)
	player:EnableWeaponType(WeaponType.WEAPON_TEARS, true)
	player:SetWeapon(newWeapon, 1)	
end

local backdropColors = tables.BackdropColors

---@param player EntityPlayer
function EdithVestige.InitVestigeJump(player)
	local jumpSpeed = 3.75 + (player.MoveSpeed - 1)
	local jumpHeight = 40
	local room = game:GetRoom()
	local isChap4 = mod:isChap4()
	local BackDrop = room:GetBackdropType()
	local hasWater = room:HasWater()
	local variant = hasWater and EffectVariant.BIG_SPLASH or (isChap4 and EffectVariant.POOF02 or EffectVariant.POOF01)
	local subType = hasWater and 1 or (isChap4 and 66 or 1)
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		variant, 
		subType, 
		player.Position, 
		Vector.Zero, 
		player
	)

	local color = Color(1, 1, 1)
	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = backdropColors[BackDrop] or Color(0.7, 0.75, 1)
			if IsMortis then
				color = Color(0, 0.8, 0.76, 1, 0, 0, 0)
			end
		end,
		[EffectVariant.POOF02] = function()
			color = backdropColors[BackDrop] or Color(1, 0, 0)

			if IsMortis then
				local Colors = {
					[MortisBackdrop.MORGUE] = Color(0, 0, 0, 1, 0.45, 0.5, 0.575),
					[MortisBackdrop.MOIST] = Color(0, 0.8, 0.76, 1, 0, 0, 0),
					[MortisBackdrop.FLESH] = Color(0, 0, 0, 1, 0.55, 0.5, 0.55),
				}
				local newcolor = mod.When(EdithVestige.GetMortisDrop(), Colors, Color.Default)
				color = newcolor
			end
		end,
		[EffectVariant.POOF01] = function()
			if hasWater then
				color = backdropColors[BackDrop]
			end
		end
	}
	mod.WhenEval(variant, switch)

	DustCloud.SpriteScale = DustCloud.SpriteScale * player.SpriteScale.X
	DustCloud.DepthOffset = -100
	DustCloud:SetColor(color, -1, 100, false, false)
	DustCloud:GetSprite().PlaybackSpeed = hasWater and 1.3 or 2	

	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTags.EdithJump,
		Flags = jumpFlags.EdithJump,
	}

	JumpLib:Jump(player, config)
end

---Returns `true` if Dogma's appear cutscene is playing
---@return boolean
function EdithVestige.IsDogmaAppearCutscene()
	local TV = Isaac.FindByType(EntityType.ENTITY_GENERIC_PROP, 4)[1]
	local Dogma = Isaac.FindByType(EntityType.ENTITY_DOGMA)[1]

	if not TV then return false end
	return TV:GetSprite():IsPlaying("Idle2") and Dogma ~= nil
end

---@param tear EntityTear
local function tearCol(_, tear)
	local tearData = data(tear)
	if not tearData.IsEdithVestigeSaltTear then return end

	local var, sprite, Path

	for _, ent in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT)) do
		var = ent.Variant
		sprite = ent:GetSprite()
		
		if not (var == EffectVariant.ROCK_POOF or var == EffectVariant.TOOTH_PARTICLE) then goto Break end
		if ent.Position:Distance(tear.Position) > 10 then goto Break end

		Path = var == EffectVariant.ROCK_POOF and tearData.ShatterSprite or tearData.SaltGibsSprite

		if var == EffectVariant.TOOTH_PARTICLE then
			if ent.SpawnerEntity then goto Break end
			ent.Color = tear.Color
		end

		sprite:ReplaceSpritesheet(0, misc.TearPath .. Path .. ".png", true)
		::Break::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, tearCol)

---@param tear EntityTear
---@param IsBlood boolean
local function doEdithTear(tear, IsBlood)
	local player = mod:GetPlayerFromTear(tear)

	if not player then return end

	local tearSizeMult = player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) and 1 or 0.85
	local tearData = data(tear)
	local path = (IsBlood and "blood_salt_tears" or "salt_tears")
	local newSprite = misc.TearPath .. path .. ".png"

	tear.Scale = tear.Scale * tearSizeMult

	tear:ChangeVariant(TearVariant.ROCK)
	
	tearData.ShatterSprite = (IsBlood and "blood_salt_shatter" or "salt_shatter")
	tearData.SaltGibsSprite = (IsBlood and "blood_salt_gibs" or "salt_gibs")
	
	tear:GetSprite():ReplaceSpritesheet(0, newSprite, true)
	tear.Color = player.Color
	tearData.IsEdithVestigeSaltTear = true
end

---Forces tears to look like salt tears. `tainted` argument sets tears for Tainted Edith
---@param tear EntityTear
function EdithVestige.ForceSaltTear(tear)
	local IsBloodTear = mod.When(tear.Variant, tables.BloodytearVariants, false)
	doEdithTear(tear, IsBloodTear)
end

---Converts seconds to game update frames
---@param seconds number
---@return number
function EdithVestige:SecondsToFrames(seconds)
	return math.ceil(seconds * 30)
end

---Custom black powder spawn (Used for Edith's black powder stomp synergy)
---@param parent Entity
---@param quantity number
---@param position Vector
---@param distance number
function EdithVestige:SpawnBlackPowder(parent, quantity, position, distance)
	quantity = quantity or 20
	local degrees = 360 / quantity
	local blackPowder
	for i = 1, quantity do
		blackPowder = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.PLAYER_CREEP_BLACKPOWDER, 
			0, 
			position + Vector(0, distance or 60):Rotated(degrees * i),
			Vector.Zero, 
			parent
		)
		if not blackPowder then return end
		data(blackPowder).CustomSpawn = true
	end

	local Pentagram = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.PENTAGRAM_BLACKPOWDER, 
		0, 
		position, 
		Vector.Zero, 
		nil
	):ToEffect() ---@cast Pentagram EntityEffect

	Pentagram.Scale = distance + distance / 2	
end

---@param player EntityPlayer
function EdithVestige.GetNearestEnemy(player)
	local closestDistance = math.huge
    local playerPos = player.Position
	local room = game:GetRoom()
	local closestEnemy, enemyPos, distanceToPlayer, checkline

	for _, enemy in ipairs(mod.GetEnemies()) do
		if enemy:HasEntityFlags(EntityFlag.FLAG_CHARM) then goto Break end
		enemyPos = enemy.Position
		distanceToPlayer = enemyPos:Distance(playerPos)
		checkline = room:CheckLine(playerPos, enemyPos, LineCheckMode.PROJECTILE, 0, false, false)
		if not checkline then goto Break end
        if distanceToPlayer >= closestDistance then goto Break end
        closestEnemy = enemy
        closestDistance = distanceToPlayer
        ::Break::
	end
    return closestEnemy
end

---Expontential function
---@param number number
---@param coeffcient number
---@param power number
---@return integer
function EdithVestige.exp(number, coeffcient, power)
    return number ~= 0 and coeffcient * number ^ (power - 1) or 0
end

---Changes `player`'s ANM2 file
---@param player EntityPlayer
---@param FilePath string
function EdithVestige.SetNewANM2(player, FilePath)
	local playerSprite = player:GetSprite()

	if not (playerSprite:GetFilename() ~= FilePath and not player:IsCoopGhost()) then return end
	playerSprite:Load(FilePath, true)
	playerSprite:Update()
end

---Spawns Salt Creep
---@param parent Entity
---@param position Vector
---@param damage number
---@param timeout number
---@param gibAmount integer
---@param gibSpeed number
---@param inheritParentColor? boolean
---@param inheritParentVel? boolean
---@param color Color? Use this param to override salt's color
function EdithVestige:SpawnSaltCreep(parent, position, damage, timeout, gibAmount, gibSpeed, inheritParentColor, inheritParentVel, color)
	gibAmount = gibAmount or 0

	local salt = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		enums.SubTypes.SALT_CREEP,
		position, 
		Vector.Zero,
		parent
	):ToEffect() ---@cast salt EntityEffect

	local saltColor = inheritParentColor and parent.Color or Color.Default
	local timeOutSeconds = mod:SecondsToFrames(timeout) or 30

	salt.CollisionDamage = damage or 0
	salt.Color = color or saltColor
	salt:SetTimeout(timeOutSeconds)

	if gibAmount > 0 then
		local gibColor = color or (inheritParentColor and Color.Default or nil)
		mod:SpawnSaltGib(parent, gibAmount, gibSpeed, gibColor, inheritParentVel)
	end
end

---Returns distance between Edith and her target
---@param player EntityPlayer
---@return number
function EdithVestige.GetEdithTargetDistance(player)
	local target = mod.GetEdithTarget(player, false)
	if not target then return 0 end
	return player.Position:Distance(target.Position)
end

---Returns a normalized vector that represents direction regarding Edith and her Target, set `tainted` to true to check for Tainted Edith's arrow instead
---@param player EntityPlayer
---@param tainted boolean?
---@return Vector
function EdithVestige.GetEdithTargetDirection(player, tainted)
	local target = mod.GetEdithTarget(player, tainted or false)
	return (target.Position - player.Position):Normalized()
end

---Forcefully adds a costume for a character
---@param player EntityPlayer
---@param playertype PlayerType
---@param costume integer
function EdithVestige.ForceCharacterCostume(player, playertype, costume)
	local playerData = data(player)

	playerData.HasCostume = {}

	local hasCostume = playerData.HasCostume[playertype] or false
	local isCurrentPlayerType = player:GetPlayerType() == playertype

	if isCurrentPlayerType then
		if not hasCostume then
			player:AddNullCostume(costume)
			playerData.HasCostume[playertype] = true
		end
	else
		if hasCostume then
			player:TryRemoveNullCostume(costume)
			playerData.HasCostume[playertype] = false
		end
	end
end

---Checks if player is shooting by checking if shoot inputs are being pressed
---@param player EntityPlayer
---@return boolean
function EdithVestige:IsPlayerShooting(player)
	local shoot = {
        l = Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex),
        r = Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex),
        u = Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex),
        d = Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex)
    }
	return (shoot.l or shoot.r or shoot.u or shoot.d)
end

---@param parent Entity
---@param Number number
---@param speed number?
---@param color Color?
---@param inheritParentVel boolean?
function EdithVestige:SpawnSaltGib(parent, Number, speed, color, inheritParentVel)
    local parentColor = parent.Color
    local parentPos = parent.Position
    local finalColor = Color(1, 1, 1) or parent.Color

    if color then
        local CTint = color:GetTint()
        local COff = color:GetOffset()
		local PTint = parentColor:GetTint()
        local POff = parentColor:GetOffset()
        local PCol = parentColor:GetColorize()

        finalColor:SetTint(CTint.R + PTint.R - 1, CTint.G + PTint.G - 1, CTint.B + PTint.B - 1, 1)
        finalColor:SetOffset(COff.R + POff.R, COff.G + POff.G, COff.B + POff.B)
        finalColor:SetColorize(PCol.R, PCol.G, PCol.B, PCol.A)
    end

    local saltGib

    for _ = 1, Number do    
        saltGib = Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.TOOTH_PARTICLE,
            0,
            parentPos,
            RandomVector():Resized(speed or 3),
            parent
        ):ToEffect() ---@cast saltGib EntityEffect

        saltGib.Color = finalColor
        saltGib.Timeout = 5

		if inheritParentVel then
            saltGib.Velocity = saltGib.Velocity + parent.Velocity
        end
    end
end

---Function to spawn Edith's Target, setting `tainted` to `true` will Spawn Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted? boolean
function EdithVestige.SpawnEdithTarget(player, tainted)
	if mod.IsDogmaAppearCutscene() then return end
	if mod.GetEdithTarget(player, tainted or false) then return end 

	local playerData = data(player)
	local target = Isaac.Spawn(	
		EntityType.ENTITY_EFFECT,
		effectVariant.EFFECT_EDITH_TARGET,
		0,
		player.Position,
		Vector.Zero,
		player
	):ToEffect()

	target.DepthOffset = -100
	target.SortingLayer = SortingLayer.SORTING_NORMAL
	target.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
	playerData.EdithTarget = target
end

---Function to get Edith's Target, setting `tainted` to `true` will return Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted boolean?
---@return EntityEffect
function EdithVestige.GetEdithTarget(player, tainted)
	local playerData = data(player)
	return tainted and playerData.TaintedEdithTarget or playerData.EdithTarget
end

---Function to remove Edith's target
---@param player EntityPlayer
---@param tainted? boolean
function EdithVestige.RemoveEdithTarget(player, tainted)
	local target = mod.GetEdithTarget(player, tainted)

	if not target then return end
	target:Remove()

	local playerData = data(player)
	playerData.EdithTarget = nil
end

function EdithVestige.HasBitFlags(flags, checkFlag)
	return flags & checkFlag == checkFlag
end

---Checks if player is in Last Judgement's Mortis 
---@return boolean
function EdithVestige.IsLJMortis()
	if not StageAPI then return false end
	if not LastJudgement then return false end

	local stage = LastJudgement.STAGE
	local IsMortis = StageAPI and (stage.Mortis:IsStage() or stage.MortisTwo:IsStage() or stage.MortisXL:IsStage())

	return IsMortis
end

---@param ent Entity
---@return boolean
function EdithVestige.IsEnemy(ent)
	return (ent:IsActiveEnemy() and ent:IsVulnerableEnemy()) or
	(ent.Type == EntityType.ENTITY_GEMINI and ent.Variant == 12) -- this for blighted ovum little sperm like shit i hate it fuuuck
end

---Checks if are in Chapter 4 (Womb, Utero, Scarred Womb, Corpse)
---@return boolean
function EdithVestige:isChap4()
	local backdrop = game:GetRoom():GetBackdropType()
	
	if EdithVestige.IsLJMortis() then return true end
	return mod.When(backdrop, tables.Chap4Backdrops, false)
end

local KeyRequiredChests = {
	[PickupVariant.PICKUP_LOCKEDCHEST] = true,
	[PickupVariant.PICKUP_ETERNALCHEST] = true,
	[PickupVariant.PICKUP_OLDCHEST] = true,
	[PickupVariant.PICKUP_MEGACHEST] = true,
}

local Chests = {
	[PickupVariant.PICKUP_CHEST] = true,
	[PickupVariant.PICKUP_BOMBCHEST] = true,
	[PickupVariant.PICKUP_SPIKEDCHEST] = true,
	[PickupVariant.PICKUP_ETERNALCHEST] = true,
	[PickupVariant.PICKUP_MIMICCHEST] = true,
	[PickupVariant.PICKUP_OLDCHEST] = true,
	[PickupVariant.PICKUP_WOODENCHEST] = true,
	[PickupVariant.PICKUP_MEGACHEST] = true,
	[PickupVariant.PICKUP_HAUNTEDCHEST] = true,
	[PickupVariant.PICKUP_LOCKEDCHEST] = true,
}

---@param pickup EntityPickup
---@return boolean
function IsKeyRequiredChest(pickup)
	return mod.When(pickup.Variant, KeyRequiredChests, false)
end

---@param pickup EntityPickup
---@return boolean
local function IsChest(pickup)
	return mod.When(pickup.Variant, Chests, false)
end

---@param player EntityPlayer
---@return boolean
local function ShouldConsumeKeys(player)
	return (player:GetNumKeys() > 0 and not player:HasGoldenKey())
end

---@param player EntityPlayer
---@return boolean
local function CanOpenChests(player)
	return(player:GetNumKeys() > 0 or player:HasGoldenKey())
end

local function chestKeyManager(parent, pickup)
	if not IsChest(pickup) then return end
	if not IsKeyRequiredChest(pickup) then  return end
	if not CanOpenChests(parent) then return end
	if pickup:GetSprite():GetAnimation() == "Open" then return end

	if ShouldConsumeKeys(parent) then
		parent:AddKeys(-1)
	end

	if pickup.Variant ~= PickupVariant.PICKUP_MEGACHEST then
		pickup:TryOpenChest(parent)
		return
	end

	local rng = pickup:GetDropRNG()
	local piData = data(pickup)

	piData.OpenAttempts = 0
	piData.OpenAttempts = piData.OpenAttempts + 1

	local attempt = piData.OpenAttempts
	local openRoll = rng:RandomInt(attempt, 7)

	if openRoll == 7 then
		pickup:TryOpenChest(parent)
	else 
		piData.CollOpen = true
		sfx:Play(SoundEffect.SOUND_UNLOCK00)
		pickup:GetSprite():Play("UseKey")
	end
end

---@param ent Entity
---@param parent EntityPlayer
---@param knockback number
function EdithVestige.HandleEntityInteraction(ent, parent, knockback)
	local var = ent.Variant
    local stompBehavior = {
        [EntityType.ENTITY_TEAR] = function()
            local tear = ent:ToTear()
            if not tear then return end
			if mod.IsEdith(parent) then return end

			mod.BoostTear(tear, 25, 1.5)
        end,
        [EntityType.ENTITY_FIREPLACE] = function()
            if var == 4 then return end
            ent:Die()
        end,
        [EntityType.ENTITY_FAMILIAR] = function()
            if not mod.When(var, tables.PhysicsFamiliar, false) then return end
            mod.TriggerPush(ent, parent, knockback, 3, false)
        end,
        [EntityType.ENTITY_BOMB] = function()
			if mod.IsEdith(parent) then return end
            mod.TriggerPush(ent, parent, knockback, 3, false)
        end,
        [EntityType.ENTITY_PICKUP] = function()
            local pickup = ent:ToPickup() ---@cast pickup EntityPickup
            local isFlavorTextPickup = mod.When(var, tables.BlacklistedPickupVariants, false)
            local IsLuckyPenny = var == PickupVariant.PICKUP_COIN and ent.SubType == CoinSubType.COIN_LUCKYPENNY

            if isFlavorTextPickup or IsLuckyPenny then return end
			parent:ForceCollide(pickup, true)

			chestKeyManager(parent, pickup)

            -- if not (var == PickupVariant.PICKUP_BOMBCHEST and mod.IsEdith(parent)) then return end
			-- pickup:TryOpenChest(parent)
        end,
        [EntityType.ENTITY_SHOPKEEPER] = function()
            ent:Kill()
        end,
    }
	mod.WhenEval(ent.Type, stompBehavior)
end

---@param pickup EntityPickup
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, function(_, pickup)
	local piData = data(pickup)
	local sprite = pickup:GetSprite()

	-- print(sprite:GetAnimation())
	-- print(pickup.State)

	if not piData.CollOpen then return end
	if not sprite:IsFinished("UseKey") then return end

	sprite:Play("Idle")
end, PickupVariant.PICKUP_MEGACHEST)

local damageFlags = DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_IGNORE_ARMOR

---comment
---@param ent Entity
---@param dealEnt Entity
---@param damage number
---@param knockback number
function EdithVestige.LandDamage(ent, dealEnt, damage, knockback)	
	if not mod.IsEnemy(ent) then return end

	ent:TakeDamage(damage, damageFlags, EntityRef(dealEnt), 0)
	mod.TriggerPush(ent, dealEnt, knockback, 5, false)
end

-- ---@param ent Entity
-- ---@param player EntityPlayer
-- function EdithVestige.AddExtraGore(ent, player)
-- 	local enabledExtraGore

-- 	if mod.IsEdith(player, false) then
-- 		enabledExtraGore = mod.GetConfigData(ConfigDataTypes.EDITH).EnableExtraGore
-- 	elseif mod.IsEdith(player, true) then
-- 		enabledExtraGore = mod.GetConfigData(ConfigDataTypes.TEDITH).EnableExtraGore
-- 	end

-- 	if not enabledExtraGore then return end
-- 	if not ent:ToNPC() then return end

-- 	ent:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
-- 	ent:MakeBloodPoof(ent.Position, nil, 0.5)
-- 	sfx:Play(SoundEffect.SOUND_DEATH_BURST_LARGE)
-- end

---Custom Edith stomp Behavior
---@param parent EntityPlayer
---@param radius number
---@param damage number
---@param knockback number
---@param breakGrid boolean
function EdithVestige:EdithStomp(parent, radius, damage, knockback, breakGrid)
	local HasTerra = parent:HasCollectible(CollectibleType.COLLECTIBLE_TERRA)
	local TerraRNG = parent:GetCollectibleRNG(CollectibleType.COLLECTIBLE_TERRA)
	local TerraMult = HasTerra and mod.RandomFloat(TerraRNG, 0.5, 2) or 1	
	local playerData = data(parent)
	local FrozenMult, BCRRNG
	local capsule = Capsule(parent.Position, Vector.One, 0, radius)
	local isSalted

	playerData.StompedEntities = Isaac.FindInCapsule(capsule)

	for _, ent in ipairs(playerData.StompedEntities) do
		if GetPtrHash(parent) == GetPtrHash(ent) then goto Break end
		mod.HandleEntityInteraction(ent, parent, knockback)

		if ent.Type == EntityType.ENTITY_STONEY then
			ent:ToNPC().State = NpcState.STATE_SPECIAL
		end

		Isaac.RunCallback(mod.Enums.Callbacks.OFFENSIVE_STOMP, parent, ent)	

		if not mod.IsEnemy(ent) then goto Break end

		FrozenMult = ent:HasEntityFlags(EntityFlag.FLAG_FREEZE) and 1.2 or 1 
		damage = (damage * FrozenMult) * TerraMult

		mod.LandDamage(ent, parent, damage, knockback)
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

		if ent.HitPoints > damage then goto Break end
		-- mod.AddExtraGore(ent, parent)
		::Break::
	end

	if breakGrid then
		mod:DestroyGrid(parent, radius)
	end
end

---Helper function that returns `EntityPlayer` from `EntityRef`
---@param EntityRef EntityRef
---@return EntityPlayer?
function EdithVestige.GetPlayerFromRef(EntityRef)
	local ent = EntityRef.Entity

	if not ent then return nil end
	local familiar = ent:ToFamiliar()
	return ent:ToPlayer() or mod:GetPlayerFromTear(ent) or familiar and familiar.Player 
end

---@param player EntityPlayer
---@return Entity[]
function EdithVestige.GetStompedEnemies(player)
	local enemyTable = {}
    for _, ent in ipairs(data(player).StompedEntities) do
        if not mod.IsEnemy(ent) then goto continue end
        table.insert(enemyTable, ent)
		::continue::
    end
    return enemyTable
end

---Triggers a push to `pushed` from `pusher`
---@param pushed Entity
---@param pusher Entity
---@param strength number
---@param duration integer
---@param impactDamage? boolean
function EdithVestige.TriggerPush(pushed, pusher, strength, duration, impactDamage)
	local dir = ((pusher.Position - pushed.Position) * -1):Resized(strength)
	pushed:AddKnockback(EntityRef(pusher), dir, duration, impactDamage or false)
end

---Method used for Edith's dash behavior (Like A Pony/White Pony or Mars usage)
---@param player EntityPlayer
---@param dir Vector
---@param dist number
---@param div number
function EdithVestige.EdithDash(player, dir, dist, div)
	player.Velocity = player.Velocity + dir * dist / div
end

--- Helper function that returns a table containing all existing enemies in room
---@return Entity[]
function EdithVestige.GetEnemies()
    local enemyTable = {}
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if not mod.IsEnemy(ent) then goto continue end
        table.insert(enemyTable, ent)
		::continue::
    end
    return enemyTable
end 

---@return integer
function EdithVestige.GetMortisDrop()
	if not EdithVestige.IsLJMortis() then return 0 end

	if LastJudgement.UsingMorgueisBackdrop then
		return MortisBackdrop.MORGUE
	elseif LastJudgement.UsingMoistisBackdrop then 
		return MortisBackdrop.MOIST
	else
		return MortisBackdrop.FLESH
	end
end

--- Rounds a number to the closest number of decimal places given.
--- Defaults to rounding to the nearest integer. 
--- (from Library of Isaac)
---@param n number
---@param decimalPlaces integer? @Default: 0
---@return number
function EdithVestige.Round(n, decimalPlaces)
	decimalPlaces = decimalPlaces or 0
	local mult = 10^(decimalPlaces or 0)
	return math.floor(n * mult + 0.5) / mult
end

--- Helper function to convert a given amount of angle degrees into the corresponding `Direction` enum (From Library of Isaac, tweaked a bit)
---@param angleDegrees number
---@return Direction
function EdithVestige.AngleToDirection(angleDegrees)
    local normalizedDegrees = angleDegrees % 360
    if normalizedDegrees < 45 or normalizedDegrees >= 315 then
        return Direction.RIGHT
    elseif normalizedDegrees < 135 then
        return Direction.DOWN
    elseif normalizedDegrees < 225 then
        return Direction.LEFT
    else
        return Direction.UP
    end
end

--- Returns a direction corresponding to the direction the provided vector is pointing (from Library of Isaac)
---@param vector Vector
---@return Direction
function EdithVestige.VectorToDirection(vector)
	return mod.AngleToDirection(vector:GetAngleDegrees())
end

---Makes the tear to receive a boost, increasing its speed and damage
---@param tear EntityTear	
---@param speed number
---@param dmgMult number
function EdithVestige.BoostTear(tear, speed, dmgMult)
	local player = mod:GetPlayerFromTear(tear) ----@cast player EntityPlayer	
	local nearEnemy = mod.GetNearestEnemy(player)

	if nearEnemy then
		tear.Velocity = (nearEnemy.Position - tear.Position):Normalized()
	end
	
	tear.CollisionDamage = tear.CollisionDamage * dmgMult
	tear.Velocity = tear.Velocity:Resized(speed)
	tear:AddTearFlags(TearFlags.TEAR_KNOCKBACK)
end

---Function for audiovisual feedback of Edith and Tainted Edith landings.
---@param player EntityPlayer
---@param GibColor Color Takes a color for salt gibs spawned on Landing.
function EdithVestige.LandFeedbackManager(player, GibColor)
	local room = game:GetRoom()
	local BackDrop = room:GetBackdropType()
	local hasWater = room:HasWater()
	local IsChap4 = mod:isChap4()
	local Variant = hasWater and EffectVariant.BIG_SPLASH or EffectVariant.POOF02
	local SubType = hasWater and 2 or (IsChap4 and 3 or 1)
	local backColor = tables.BackdropColors
	local soundPick = enums.SoundEffect.SOUND_EDITH_STOMP
	local IsMortis = EdithVestige.IsLJMortis()

	local stompGFX = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		Variant, 
		SubType, 
		player.Position, 
		Vector.Zero, 
		player
	)

	local rng = stompGFX:GetDropRNG()
	
	game:ShakeScreen(15)

	local defColor = Color(1, 1, 1)
	local color = defColor
	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = mod.When(BackDrop, backColor, Color(0.7, 0.75, 1))
		end,
		[EffectVariant.POOF02] = function()
			color = BackDrop == BackdropType.DROSS and defColor or backColor[BackDrop] 
		end,
	}
	
	mod.WhenEval(Variant, switch)
	color = color or defColor

	if IsMortis then
		local Colors = {
			[MortisBackdrop.MORGUE] = Color(0, 0, 0, 1, 0.45, 0.5, 0.575),
			[MortisBackdrop.MOIST] = Color(0, 0.8, 0.76, 1, 0, 0, 0),
			[MortisBackdrop.FLESH] = Color(0, 0, 0, 1, 0.55, 0.5, 0.55),
		}
		local newcolor = mod.When(EdithVestige.GetMortisDrop(), Colors, Color.Default)
		color = newcolor
	end

	local RandSize = {
		X = mod.RandomFloat(rng, 0.9, 1.1),
		Y = mod.RandomFloat(rng, 0.9, 1.1)
	}

	stompGFX:GetSprite().PlaybackSpeed = 1.3 * mod.RandomFloat(rng, 1, 1.5)
	stompGFX.SpriteScale = Vector(0.8 * RandSize.X, 0.7 * RandSize.Y) * player.SpriteScale.X
	stompGFX.Color = color

	GibColor = GibColor or defColor

	mod:SpawnSaltGib(player, 15, 2, GibColor)

	sfx:Play(soundPick, 1, 0, false)

	if IsChap4 then
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 1 - 0.5, 0, false, 1, 0)
	end

	if hasWater then
		sfx:Play(enums.SoundEffect.SOUND_EDITH_STOMP_WATER, 1, 0, false)
	end	
end

---@param entity Entity
---@return EntityPlayer?
function EdithVestige:GetPlayerFromTear(entity)
	local check = entity.Parent or entity.SpawnerEntity

	if not check then return end
	local checkType = check.Type

	if checkType == EntityType.ENTITY_PLAYER then
		return mod:GetPtrHashEntity(check):ToPlayer()
	elseif checkType == EntityType.ENTITY_FAMILIAR then
		return check:ToFamiliar().Player:ToPlayer()
	end

	return nil
end

---@param entity Entity|EntityRef
---@return Entity?
function EdithVestige:GetPtrHashEntity(entity)
	if not entity then return end
	entity = entity.Entity or entity

	for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
		if GetPtrHash(entity) == GetPtrHash(matchEntity) then
			return matchEntity
		end
	end
	return nil
end