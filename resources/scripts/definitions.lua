---@diagnostic disable: inject-field
local EdithPlayer = Isaac.GetPlayerTypeByName("Edith​​​​​​", false)
local edithJumpTag = "edithVestige_EdithJump"
local game = Game()

EdithVestige.Enums = {
	PlayerType = {
		PLAYER_EDITH = EdithPlayer,
	},
	CollectibleType = {
		COLLECTIBLE_SALTSHAKER = Isaac.GetItemIdByName("Salt Shaker​​​​​​"),
	},
	NullItemID = {
		ID_EDITH_SCARF = Isaac.GetCostumeIdByPath("gfx/characters/EdithHood.anm2"),
	},
	EffectVariant = {
		EFFECT_EDITH_TARGET = Isaac.GetEntityVariantByName("Edith Target"),
	},
	Callbacks = {
		-- Called everytime Edith does an offensive stomp and damages at least `One Enemy
		---* player `EntityPlayer`
		---* entity `Entity`
		OFFENSIVE_STOMP = "EdithVestige_OFFENSIVE_STOMP",
	},
	SubTypes = {
		SALT_CREEP = Isaac.GetEntitySubTypeByName("Salt Creep"),
	},
	SoundEffect = {
		SOUND_EDITH_STOMP = Isaac.GetSoundIdByName("Edith Stomp"),
		SOUND_EDITH_STOMP_WATER = Isaac.GetSoundIdByName("Edith Stomp Water"),
		SOUND_SALT_SHAKER = Isaac.GetSoundIdByName("Salt Shaker"),
	},
	Utils = {
		Game = game,
		SFX = SFXManager(),
		RNG = RNG(),
		Level = game:GetLevel(),
	},
	Tables = {
		OverrideActions = {
			[ButtonAction.ACTION_LEFT] = 0,
			[ButtonAction.ACTION_RIGHT] = 0,
			[ButtonAction.ACTION_UP] = 0,
			[ButtonAction.ACTION_DOWN] = 0,
		},
		OverrideWeapons = {
			[WeaponType.WEAPON_BRIMSTONE] = true,
			[WeaponType.WEAPON_KNIFE] = true,
			[WeaponType.WEAPON_LASER] = true,
			[WeaponType.WEAPON_BOMBS] = true,
			[WeaponType.WEAPON_ROCKETS] = true,
			[WeaponType.WEAPON_TECH_X] = true,
			[WeaponType.WEAPON_SPIRIT_SWORD] = true
		},
		BloodytearVariants = {
			[TearVariant.BLOOD] = true,
			[TearVariant.GLAUCOMA_BLOOD] = true,
			[TearVariant.CUPID_BLOOD] = true,
			[TearVariant.PUPULA_BLOOD] = true,
			[TearVariant.GODS_FLESH_BLOOD] = true,
			[TearVariant.NAIL_BLOOD] = true,
		},
		BackdropColors = {
			[BackdropType.CORPSE3] = Color(0.75, 0.2, 0.2),
			[BackdropType.DROSS] = Color(92/255, 81/255, 71/255),
			[BackdropType.BLUE_WOMB] = Color(0, 0, 0, 1, 0.3, 0.4, 0.6),
			[BackdropType.CORPSE] = Color(0, 0, 0, 1, 0.62, 0.65, 0.62),
			[BackdropType.CORPSE2] = Color(0, 0, 0, 1, 0.55, 0.57, 0.55),
		},
		JumpTags = {
			EdithJump = edithJumpTag,

		},
		JumpFlags = {
			EdithJump = (JumpLib.Flags.DISABLE_SHOOTING_INPUT | JumpLib.Flags.DISABLE_LASER_FOLLOW | JumpLib.Flags.DISABLE_BOMB_INPUT | JumpLib.Flags.FAMILIAR_FOLLOW_FOLLOWERS | JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS | JumpLib.Flags.FAMILIAR_FOLLOW_TEARCOPYING),
		},
		MovementBasedActives = {
			[CollectibleType.COLLECTIBLE_SUPLEX] = true,
			[CollectibleType.COLLECTIBLE_PONY] = true,
			[CollectibleType.COLLECTIBLE_WHITE_PONY] = true,
		},
		JumpParams = {
			EdithJump = {
				tag = edithJumpTag,
				type = EntityType.ENTITY_PLAYER,
				player = EdithPlayer,
			},
		},
		GridEntTypes = {
			[GridEntityType.GRID_TRAPDOOR] = true,
			[GridEntityType.GRID_STAIRS] = true,
			[GridEntityType.GRID_GRAVITY] = true,
		},
		Chap4Backdrops = {
			[BackdropType.WOMB] = true,
			[BackdropType.UTERO] = true,
			[BackdropType.SCARRED_WOMB] = true,
			[BackdropType.BLUE_WOMB] = true,
			[BackdropType.CORPSE] = true,
			[BackdropType.CORPSE2] = true,
			[BackdropType.CORPSE3] = true,
			[BackdropType.MORTIS] = true, --- Who knows
		},
		BlacklistedPickupVariants = { -- Pickups blacklisted from use on `Entity:ForceCollide()`
			[PickupVariant.PICKUP_PILL] = true,
			[PickupVariant.PICKUP_TAROTCARD] = true,
			[PickupVariant.PICKUP_TRINKET] = true,
			[PickupVariant.PICKUP_COLLECTIBLE] = true,
			[PickupVariant.PICKUP_BROKEN_SHOVEL] = true,
		},
		PhysicsFamiliar = {
			[FamiliarVariant.SAMSONS_CHAINS] = true,
			[FamiliarVariant.PUNCHING_BAG] = true,
			[FamiliarVariant.CUBE_BABY] = true,
		},
		RemoveTargetItems = {
			[CollectibleType.COLLECTIBLE_ESAU_JR] = true,
			[CollectibleType.COLLECTIBLE_CLICKER] = true,
		},
		DisableLandFeedbackGrids = {
			[GridEntityType.GRID_TRAPDOOR] = true,
			[GridEntityType.GRID_STAIRS] = true,
			[GridEntityType.GRID_GRAVITY] = true,
		},
	},
	Misc = {
		TearPath = "gfx/tears/",
		SaltShakerDist = Vector(0, 60),
		ColorDefault = Color(1, 1, 1, 1),
	},
}