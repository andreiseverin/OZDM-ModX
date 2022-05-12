#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fakemeta_util>
#include <xs>
#include <hlstocks>
#include <fun>



#define PLUGIN "RO OZDM"
#define VERSION "1.0"
#define AUTHOR "teylo"

#define HLFW_CROWBAR "fly_crowbar"
#define HLFW_HANDGRENADE "fly_handgrenade"


const WEAPON_CROWBAR = 1
const WEAPON_SNARK = 15
const LINUX_OFF_SET_5 = 5
const LINUX_OFF_SET_4 = 4
const MAX_ITEM_TYPES = 6
const m_pPlayer = 28
const m_pNext = 29
const m_iId = 30
const m_fInSpecialReload = 34
//const m_flNextPrimaryAttack = 35
//const m_flNextSecondaryAttack = 36
//const m_flTimeWeaponIdle = 37
const m_iClip = 40
const m_iDefaultAmmo = 44
//const m_flNextAttack = 148
const m_iFOV = 298
const m_rgpPlayerItems_Slot0 = 300
const m_pActiveItem = 306
const m_rgAmmo_Slot0 = 311
const GRENADE_AMMO = 319

// add new weapon equip

// =========== WEAPON OFFSET CLASS ============ //
static const _HLW_to_rgAmmoIdx[] =
{
	0, 	// bos
	0,	// crowbar
	2, 	// 9mmhandgun
	4, 	// 357
	2, 	// 9mmAR
	3, 	// m203
	7, 	// crossbow
	1, 	// shotgun
	6, 	// rpg
	5, 	// gauss
	5, 	// egon
	12,	// hornetgun
	10, 	// handgrenade
	8, 	// tripmine
	9, 	// satchel
	11  	// snark
};


const DMG_CROSSBOW  = ( DMG_BULLET | DMG_NEVERGIB )

static D_color, D_x, D_y, D_effect, D_fxtime, D_holdtime, D_fadeintime, D_fadeouttime, D_reliable

new Float:origin[3], Float:angles[3], Float:vec[3], Float:v_forward[3], Float:v_right[3], Float:v_up[3], Float:viewOfs[3], 
game_description[20], old_clip[33], zoom[33], alive[33], Float: fov, 
glock[33], BlockSound, maxplayers, r_ent, 
damage, speed, lifetime, blood_drop, blood_spray

new pos_start, pos_end, g_length, g_scrollMsg[512], g_displayMsg[512], Float:g_xPos

#define SPEED 0.10
#define is_player(%1) (1 <= %1 <= maxplayers)
#define refill_weapon(%1,%2) set_pdata_int(%1, m_iClip, %2, LINUX_OFF_SET_4)
#define InZoom(%1) (get_pdata_int(%1, m_iFOV) != 0)

new const SATCHEL_MOD_SKIN_LIST[2][]=
{
	"models/w_medkit.mdl", 
	"models/w_battery.mdl"
}


new const Remove_Entity[][] = 
{
	"weapon_hornetgun", 
	"weapon_python", 
	"weapon_357", 
	"weapon_snark", 
	"weapon_tripmine", 
	"weapon_handgrenade", 
	"weapon_9mmAR", 
	"weapon_mp5", 
	"weapon_rpg", 
	"weapon_egon", 
	"weapon_crossbow", 
	"weapon_shotgun", 
	"weapon_gauss", 
	"weapon_satchel", 
	"ammo_357", 
	"ammo_9mmAR", 
	"ammo_9mmbox", 
	"ammo_9mmclip", 
	"ammo_ARgrenades", 
	"ammo_buckshot", 
	"ammo_crossbow", 
	"ammo_glockclip", 
	"ammo_mp5clip", 
	"ammo_mp5grenades", 
	"ammo_rpgclip", 
	"ammo_gaussclip", 
	"item_longjump",
	"item_battery",
	"item_healthkit"
}

new const _weapon[][] = 
{
	"weapon_crowbar", 
	"weapon_handgrenade"
}

// parachute entity
new para_ent[33];


// ===== Cvars defines   =======
new cvar_enable;
new cvar_Wcrowbar;
new cvar_W9mmhandgun;
new cvar_Wgauss;
new cvar_Wegon;
new cvar_Wcrossbow;
new cvar_Wrpg;
new cvar_Wsatchel;
new cvar_Whornetgun;
new cvar_W357;
new cvar_Wshotgun;
new cvar_W9mmAR;
new cvar_Whandgrenade;
new cvar_Wsnark;
new cvar_Wtripmine;
new cvar_ammo_crossbow;
new cvar_ammo_buckshot;
new cvar_ammo_gaussclip;
new cvar_ammo_rpgclip;
new cvar_ammo_9mmAR;
new cvar_ammo_ARgrenades;
new cvar_ammo_357;
new cvar_ammo_glock;
new cvar_ammo_satchel;
new cvar_ammo_tripmine;
new cvar_ammo_hgrenade;
new cvar_ammo_snark;
new cvar_ammo_hornetgun;
new cvar_start_ammo_crossbow;
new cvar_start_ammo_buckshot;
new cvar_start_ammo_rpgclip;
new cvar_start_ammo_9mmAR;
new cvar_start_ammo_357;
new cvar_start_ammo_glock;
new cvar_ihealth;
new cvar_iarmour;
new cvar_ilongjump;
new cvar_remove_entities;
new cvar_deceptive_satchel;
new cvar_remove_game_equip;
new cvar_wings;
new cvar_dmg_crowbar;
new cvar_dmg_9mmhandgun;
new cvar_dmg_gauss;
new cvar_dmg_egon;
new cvar_dmg_crossbow;
new cvar_dmg_rpg;
new cvar_dmg_satchel;
new cvar_dmg_hornetgun;
new cvar_dmg_357;
new cvar_dmg_shotgun;
new cvar_dmg_9mmAR;
new cvar_dmg_handgrenade;
new cvar_dmg_snark;
new cvar_dmg_tripmine;

// ====== Entities =============
new const entGameEquip[]		= "game_player_equip";


new const COLORLIST[9][] = 
{
	{255,0,0},
	{255,128,0},
	{255,255,0},
	{255,0,255},
	{0,255,0},
	{0,255,255},
	{0,150,255},
	{0,0,255},
	{255,255,255}
}

new const COLORLIST2[3][] = 
{
	{255,0,0},
	{0,255,0},
	{0,150,255}
}

new g_Colors[5][3] =
{
	{0, 0, 0},
	{80, 80, 255},		// color for team 1
	{255, 80, 80},		// color for team 2
	{200, 200, 80},		// color for team 3
	{80, 200, 80}		// color for team 4
}

new cv_clor

stock hl_get_ammo(client, weapon)
{
	return get_ent_data(client, "CBasePlayer", "m_rgAmmo", _HLW_to_rgAmmoIdx[weapon]);
}

stock hl_set_ammo(client, weapon, ammo)
{
	if (weapon <= HLW_CROWBAR)
		return;

	set_ent_data(client, "CBasePlayer", "m_rgAmmo", ammo, _HLW_to_rgAmmoIdx[weapon]);
}

public plugin_precache()
{
	// parachute wings model
	precache_model("models/ozdm_wings.mdl");
	// ===== cvar plugin enable   ======= (1-on 0-off)
	cvar_enable          = create_cvar("sv_ozdm_enable", "1");	
	
// ===== cvars weapons ======= (1-on 0-off)
	cvar_Wcrowbar        = create_cvar("sv_ozdm_crowbar", "1");
	cvar_W9mmhandgun     = create_cvar("sv_ozdm_9mmhandgun", "1");
	cvar_Wgauss          = create_cvar("sv_ozdm_gauss", "1");
	cvar_Wegon           = create_cvar("sv_ozdm_egon", "1");
	cvar_Wcrossbow       = create_cvar("sv_ozdm_crossbow", "1");
	cvar_Wrpg            = create_cvar("sv_ozdm_rpg", "1");
	cvar_Wsatchel        = create_cvar("sv_ozdm_satchel", "1");
	cvar_Whornetgun      = create_cvar("sv_ozdm_hornetgun", "1");
	cvar_W357            = create_cvar("sv_ozdm_357", "1");
	cvar_Wshotgun        = create_cvar("sv_ozdm_shotgun", "1");
	cvar_W9mmAR          = create_cvar("sv_ozdm_9mmAR", "1");
	cvar_Whandgrenade    = create_cvar("sv_ozdm_handgrenade", "1");
	cvar_Wsnark          = create_cvar("sv_ozdm_snark", "1");
	cvar_Wtripmine       = create_cvar("sv_ozdm_tripmine", "1");
	
// ===== cvars ammo ======= (add ammo value)
	cvar_ammo_crossbow   = create_cvar("sv_ozdm_ammo_crossbow", "250");
	cvar_ammo_buckshot   = create_cvar("sv_ozdm_ammo_buckshot", "200");
	cvar_ammo_gaussclip  = create_cvar("sv_ozdm_ammo_gaussclip", "9999");
	cvar_ammo_rpgclip    = create_cvar("sv_ozdm_ammo_rpgclip", "50");
	cvar_ammo_9mmAR      = create_cvar("sv_ozdm_ammo_9mmAR", "250");
	cvar_ammo_ARgrenades = create_cvar("sv_ozdm_ammo_ARgrenades", "20");
	cvar_ammo_357        = create_cvar("sv_ozdm_ammo_357", "250");
	cvar_ammo_glock      = create_cvar("sv_ozdm_ammo_glock", "250");	
	cvar_ammo_satchel    = create_cvar("sv_ozdm_ammo_satchel", "10");
	cvar_ammo_tripmine   = create_cvar("sv_ozdm_ammo_tripmine", "5");
	cvar_ammo_hgrenade   = create_cvar("sv_ozdm_ammo_hgrenade", "20");
	cvar_ammo_snark      = create_cvar("sv_ozdm_ammo_snark", "15");	
	cvar_ammo_hornetgun  = create_cvar("sv_ozdm_ammo_hornetgun", "100");	

// ====== cvars start ammo ===== (add weapon ammo value)
	cvar_start_ammo_crossbow   = create_cvar("sv_ozdm_start_ammo_crossbow", "50");
	cvar_start_ammo_buckshot   = create_cvar("sv_ozdm_start_ammo_buckshot", "100");
	cvar_start_ammo_rpgclip    = create_cvar("sv_ozdm_start_ammo_rpgclip", "50");
	cvar_start_ammo_9mmAR      = create_cvar("sv_ozdm_start_ammo_9mmAR", "50");
	cvar_start_ammo_357        = create_cvar("sv_ozdm_start_ammo_357", "50");
	cvar_start_ammo_glock      = create_cvar("sv_ozdm_start_ammo_glock", "100");
				
// ===== cvars items ======= (add armour and health start value)
	cvar_ihealth               = create_cvar("sv_ozdm_health", "250");
	cvar_iarmour               = create_cvar("sv_ozdm_armour", "250");
	cvar_ilongjump             = create_cvar("sv_ozdm_longjump", "1"); // (1-on 0-off)
	
// ===== cvar game equip ===== 

	cvar_remove_game_equip     = create_cvar("sv_ozdm_remove_game_equip", "1"); // (1-on 0-off)

// ===== cvar remove all entities on map ============
	cvar_remove_entities 	   = create_cvar("sv_ozdm_remove_entity", "0");

// ===== cvar deceptive satchel ====================
	cvar_deceptive_satchel     = register_cvar("sv_ozdm_deceptive_satchel", "1");

// ===== cvar activate wings ==========
	cvar_wings       	       = create_cvar("sv_ozdm_wings", "1"); // (1-on 0-off)

// ===== cvar weapon damage ====== (add weapon damage value)
	cvar_dmg_crowbar           = create_cvar("sv_ozdm_dmg_crowbar", "25");
	cvar_dmg_9mmhandgun        = create_cvar("sv_ozdm_dmg_9mmhandgun", "12");
	cvar_dmg_gauss             = create_cvar("sv_ozdm_dmg_gauss", "20");
	cvar_dmg_egon              = create_cvar("sv_ozdm_dmg_egon", "20");
	cvar_dmg_crossbow          = create_cvar("sv_ozdm_dmg_crossbow", "120");
	cvar_dmg_rpg               = create_cvar("sv_ozdm_dmg_rpg", "120");
	cvar_dmg_satchel           = create_cvar("sv_ozdm_dmg_satchel", "120");
	cvar_dmg_hornetgun         = create_cvar("sv_ozdm_dmg_hornetgun", "10");
	cvar_dmg_357               = create_cvar("sv_ozdm_dmg_357", "40");
	cvar_dmg_shotgun           = create_cvar("sv_ozdm_dmg_shotgun", "20");
	cvar_dmg_9mmAR             = create_cvar("sv_ozdm_dmg_9mmAR", "12");
	cvar_dmg_handgrenade       = create_cvar("sv_ozdm_dmg_handgrenade", "100");
	cvar_dmg_snark             = create_cvar("sv_ozdm_dmg_snark", "1");
	cvar_dmg_tripmine          = create_cvar("sv_ozdm_dmg_tripmine", "150");

	blood_drop                 = precache_model("sprites/blood.spr");
	blood_spray                = precache_model("sprites/bloodspray.spr");
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)


	maxplayers = get_maxplayers()

	game_description = get_cvar_num("mp_teamplay") ? "RO OZDM (TEAM)" : "RO OZDM"
	register_forward(FM_GetGameDescription, "Game")

	register_forward(FM_CmdStart, "CmdStart")

	RegisterHam(Ham_Spawn, "player", "spawn_player", 1)
	RegisterHam(Ham_Spawn, "monster_satchel", "FUN_MODS", 1)
	RegisterHam(Ham_Spawn, "weaponbox", "kill_weaponbox")


	RegisterHam(Ham_TraceAttack, "player", "Weapons_Damages")
	RegisterHam(Ham_TraceAttack, "player", "Forward_TraceAttack")

	RegisterHam(Ham_Item_Deploy, "weapon_9mmhandgun", "item_deploy", 1)
	RegisterHam(Ham_Item_Holster, "weapon_9mmhandgun", "item_holster", 1)

	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_snark", "snark_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_crowbar", "crowbar_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_9mmhandgun", "glock_primary_attack_pre" , 0)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_9mmhandgun", "glock_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_shotgun", "shotgun_primary_attack_pre" , 0)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_shotgun", "shotgun_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_crossbow", "crossbow_primary_attack_pre", 0)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_crossbow", "crossbow_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_9mmAR", "mp5_primary_attack_pre", 0)	//to check
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_9mmAR", "mp5_primary_attack_post", 1) //to check
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_rpg", "rpg_primary_attack_pre", 0)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_rpg", "rpg_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_357", "colt_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_357", "colt_primary_attack_pre", 0)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_gauss", "gauss_primary_attack_pre", 0)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_hornetgun", "hornet_primary_attack_pre", 0)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_9mmhandgun", "glock_secondary_attack")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_shotgun", "shotgun_secondary_attack_pre" , 0)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_shotgun", "shotgun_secondary_attack_post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_crossbow", "crossbow_secondary_attack_post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_satchel", "satchel_secondary_attack_post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_9mmAR", "grenades_secondary_attack_post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_357", "colt_secondary_attack_post", 1)	

	//RegisterHam(Ham_Weapon_Reload, "weapon_shotgun", "shotgun_reload_pre" , 0)
	//RegisterHam(Ham_Weapon_Reload, "weapon_shotgun", "shotgun_reload_post", 1)
	RegisterHam(Ham_Weapon_Reload, "weapon_crossbow" , "crossbow_reload_post", 1)
	//RegisterHam(Ham_Weapon_Reload, "weapon_rpg" , "rpg_reload_post", 1)
	RegisterHam(Ham_Weapon_Reload, "weapon_9mmhandgun", "glock_reload")

	register_event("ItemPickup", "LongJump_Sound", "b", "1=item_longjump")
	
	// COLOR for RPG and Hornetgun
	register_message(SVC_TEMPENTITY, "MessageTempEntity");
	cv_clor = register_cvar("rpg_trail_color","")  // if empty then default
	
	RemoveEntity()  

	register_message(get_user_msgid("DeathMsg"), "DeathMsg")
	register_event("ResetHUD", "newSpawn", "be")
	
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_crowbar", "SecondaryAttack_Crowbar")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_handgrenade", "Grenade_SecondaryAttack_Post", 1)

	for(new a = 0; a <sizeof _weapon; a++)
	{
		RegisterHam(Ham_Item_AddToPlayer, _weapon[a], "ItemAdd")
		RegisterHam(Ham_Item_AddDuplicate, _weapon[a], "ItemAdd")
	}

	register_think(HLFW_CROWBAR, "Weapon_think")

	register_touch(HLFW_CROWBAR, "*", "hlfw_crowbar_touch")



	lifetime = register_cvar("fly_time", "15.0")
	speed = register_cvar("fly_speed", "1500")
	damage = register_cvar("fly_damage", "150.0")

	// remove game player equip entities
	removeGequip()

	set_task(15.0, "welcome_message")
	set_task(30.0, "remove_")
}

public plugin_natives()
{
	set_native_filter("native_filter")
}

public native_filter(const name[], index, trap)
{
	if (!trap) return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public Game() 
{
	forward_return(FMV_STRING, game_description)
	return FMRES_SUPERCEDE
}

public client_putinserver(id)
{
	set_task(0.50, "spawn_player", id)
	parachute_reset(id)
}

public client_disconnected(id)
{
	if(task_exists(id))
	remove_task(id)
	parachute_reset(id)
}

public spawn_player(id)
{
	alive[id] = is_user_alive(id)

	if(is_user_alive(id))
	{
      give_weapons(id)
	}
}

// ====== remove game player equip entities (like on bootbox) ============

removeGequip()
{
	if(get_pcvar_num(cvar_remove_game_equip))
	{
		remove_entity_name(entGameEquip);
	}
}

// ====== SPAWN EQUIP WEAPONS =========
public give_weapons(id) 
{
	if(is_user_alive(id))
	{
		if(get_pcvar_num(cvar_ilongjump))
		{
			hl_set_user_longjump(id,true);
		}
		if(get_pcvar_num(cvar_ihealth) > 0)
		{
			hl_set_user_health(id,get_pcvar_num(cvar_ihealth));
		}
		if(get_pcvar_num(cvar_iarmour) > 0 )
		{
			hl_set_user_armor(id,get_pcvar_num(cvar_iarmour));
		}
		if(get_pcvar_num(cvar_Wcrowbar))
		{
			give_item( id, "weapon_crowbar" );
		}
		if(get_pcvar_num(cvar_W9mmhandgun))
		{		
			give_item( id, "weapon_9mmhandgun" );
		}
		if(get_pcvar_num(cvar_Wgauss))	
		{
			give_item( id, "weapon_gauss" );
		}
		if(get_pcvar_num(cvar_Wegon))
		{
			give_item( id, "weapon_egon" );
		}
		if(get_pcvar_num(cvar_Wcrossbow))
		{
			give_item( id, "weapon_crossbow" );
		}
		if(get_pcvar_num(cvar_Wrpg))
		{
			give_item( id, "weapon_rpg" );
		}
		if(get_pcvar_num(cvar_Wsatchel))
		{
			give_item( id, "weapon_satchel" );
		}
		if(get_pcvar_num(cvar_Wsnark))
		{
			give_item( id, "weapon_snark" );
		}
		if(get_pcvar_num(cvar_Whandgrenade))
		{
			give_item( id, "weapon_handgrenade" );		
		}	
		if(get_pcvar_num(cvar_Whornetgun))
		{
			give_item( id, "weapon_hornetgun" );
		}	
		if(get_pcvar_num(cvar_Wtripmine))
		{
			give_item( id, "weapon_tripmine" );
		}		
		if(get_pcvar_num(cvar_W357))
		{
			give_item( id, "weapon_357" );
		}
		if(get_pcvar_num(cvar_W9mmAR))
		{
			give_item( id, "weapon_9mmAR" );
		}		
		if(get_pcvar_num(cvar_Wsnark))
		{
			give_item( id, "weapon_snark" );
		}	
		if(get_pcvar_num(cvar_Wshotgun))
		{
			give_item( id, "weapon_shotgun" );
		}		
		give_ammo(id);
	}
}

// ====== GIVE AMMO ON SPAWN =========
public give_ammo(id) 
{
	// 9mmhandgun 

		hl_set_ammo(id,HLW_GLOCK,get_pcvar_num(cvar_ammo_glock)); 		
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_GLOCK)),get_pcvar_num(cvar_start_ammo_glock));		

	// gauss + egon

		hl_set_ammo(id,HLW_GAUSS,get_pcvar_num(cvar_ammo_gaussclip));  	
	
	// crossbow 
		hl_set_ammo(id,HLW_CROSSBOW,get_pcvar_num(cvar_ammo_crossbow)); 	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_CROSSBOW)),get_pcvar_num(cvar_start_ammo_crossbow));		

	// rpg 

		hl_set_ammo(id,HLW_RPG,get_pcvar_num(cvar_ammo_rpgclip)); 	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_RPG)),get_pcvar_num(cvar_start_ammo_rpgclip));			
	
	//357

		hl_set_ammo(id,HLW_PYTHON,get_pcvar_num(cvar_ammo_357)); 	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_PYTHON)),get_pcvar_num(cvar_start_ammo_357));		

	//9mmAR

		hl_set_ammo(id,HLW_MP5,get_pcvar_num(cvar_ammo_9mmAR));  	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_MP5)),get_pcvar_num(cvar_start_ammo_9mmAR));			
	
	// ammo ARgrenades

		hl_set_ammo(id,HLW_CHAINGUN,get_pcvar_num(cvar_ammo_ARgrenades));	
	
	//buckshot - shotgun

		hl_set_ammo(id,HLW_SHOTGUN,get_pcvar_num(cvar_ammo_buckshot)); 	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_SHOTGUN)),get_pcvar_num(cvar_start_ammo_buckshot));		
	
	//satchel

		hl_set_ammo(id,HLW_SATCHEL,get_pcvar_num(cvar_ammo_satchel)); 	

	//tripmine

		hl_set_ammo(id,HLW_TRIPMINE,get_pcvar_num(cvar_ammo_tripmine));	

	//handgrenade

		hl_set_ammo(id,HLW_HANDGRENADE,get_pcvar_num(cvar_ammo_hgrenade)); 	
	
	//snark

		hl_set_ammo(id,HLW_SNARK,get_pcvar_num(cvar_ammo_snark)); 	
		
	// hornet
		hl_set_ammo(id,HLW_HORNETGUN,get_pcvar_num(cvar_ammo_hornetgun));	
}



public FUN_MODS(ent)
{
	if(get_pcvar_num(cvar_deceptive_satchel) == 1 && pev_valid(ent))
	{
		engfunc(EngFunc_SetModel, ent, SATCHEL_MOD_SKIN_LIST[random_num(0, 2-1)])  
	}
}

public kill_weaponbox(ent)
{
	return HAM_SUPERCEDE
}


// Shotgun firing speed (MOUSE1) -1
public shotgun_primary_attack_pre(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, LINUX_OFF_SET_4)
	old_clip[player] = get_pdata_int(this, m_iClip, LINUX_OFF_SET_4)
	
	//restore shotgun ammo - only 1 bullet left is need to verify
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_SHOTGUN))) == 1) 
	 set_task(1.0, "restore_shotgun_ammo", player)
}
// Shotgun firing speed (MOUSE1) -2
public shotgun_primary_attack_post(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, LINUX_OFF_SET_4)

	if(old_clip[player] <= 0)
		return

	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.12)

	if(get_pdata_int(this, m_iClip, LINUX_OFF_SET_4) != 0)
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 2.0)
	else
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.3)
}

// Shotgun firing speed (MOUSE2) -1
public shotgun_secondary_attack_pre(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, LINUX_OFF_SET_4)
	old_clip[player] = get_pdata_int(this, m_iClip, LINUX_OFF_SET_4)
		//restore shotgun ammo - they can have 1 or 2 bullets left before reloading
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_SHOTGUN))) == 1 || hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_SHOTGUN))) == 2 )
	 set_task(1.0, "restore_shotgun_ammo", player)
}
// Shotgun firing speed (MOUSE2) -2
public shotgun_secondary_attack_post(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, LINUX_OFF_SET_4)

	if(old_clip[player] <= 1)
		return

	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.12)

	if(get_pdata_int(this, m_iClip, LINUX_OFF_SET_4) != 0)
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 3.0)
	else
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.85)
}


public restore_shotgun_ammo(id)
{
	// shotgun 
	if(hl_get_ammo(id,HLW_SHOTGUN) <= get_pcvar_num(cvar_ammo_buckshot) && hl_get_ammo(id,HLW_SHOTGUN) != 0 )
		{
			if (hl_get_ammo(id,HLW_SHOTGUN) <= get_pcvar_num(cvar_start_ammo_buckshot))
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_SHOTGUN)),hl_get_ammo(id,HLW_SHOTGUN)+1); // +1 bullet cuz its wasted when reloading
				hl_set_ammo(id,HLW_SHOTGUN,0);
			}
			else
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_SHOTGUN)),get_pcvar_num(cvar_start_ammo_buckshot));
				hl_set_ammo(id,HLW_SHOTGUN,hl_get_ammo(id,HLW_SHOTGUN)-get_pcvar_num(cvar_start_ammo_buckshot)+1); // +1 bullet cuz its wasted when reloading 	
			}
		}
}

// Temporary disabled - reload will be made in classic speed by overwriting the weapon ammo
/*
// Shotgun reload speed (R) -1
public shotgun_reload_pre(const shotgun)
{
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFF_SET_4)
	old_special_reload[player] = get_pdata_int(shotgun, m_fInSpecialReload, LINUX_OFF_SET_4)
}
// Shotgun reload speed (R) -2
public shotgun_reload_post(const shotgun)
{
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFF_SET_4)
	
	switch(old_special_reload[player])
	{
		case 0 :
		{
			if(get_pdata_int(shotgun, m_fInSpecialReload, LINUX_OFF_SET_4) == 1)
			{
				set_pdata_float(player , m_flNextAttack, 0.3)
				set_pdata_float(shotgun, m_flTimeWeaponIdle, 0.1, LINUX_OFF_SET_4)
				set_pdata_float(shotgun, m_flNextPrimaryAttack, 0.60, LINUX_OFF_SET_4)
				set_pdata_float(shotgun, m_flNextSecondaryAttack, 0.80, LINUX_OFF_SET_4)
			}
		}
		case 1 :
		{
			if(get_pdata_int(shotgun, m_fInSpecialReload, LINUX_OFF_SET_4) == 2)
			{
				set_pdata_float(shotgun, m_flTimeWeaponIdle, 0.1, LINUX_OFF_SET_4)
			}
		}
	}
}

*/

// 9mmAR firing speed (MOUSE1) -1  // to check what it does
public mp5_primary_attack_pre(const mp5)
{
	new player = get_pdata_cbase(mp5, m_pPlayer, LINUX_OFF_SET_4)
	old_clip[player] = get_pdata_int(mp5, m_iClip, LINUX_OFF_SET_4)
}
// 9mmAR firing speed (MOUSE1) -2
public mp5_primary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.03)
}


// 9mmAR grenade firing speed (MOUSE2) 
public grenades_secondary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.15)
}

// rpg firing speed (MOUSE1) -1
public rpg_primary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.12)
}

// rpg ammo verification when rockets = 1 + call restore ammo
public rpg_primary_attack_pre(this)
{
	new id = get_pdata_cbase(this, m_pPlayer, LINUX_OFF_SET_4)
	// restore rpg ammo when 1 rocket left - couldnt be done in reload function because it loops several times.
	if (hl_get_weapon_ammo((hl_user_has_weapon(id,HLW_RPG))) == 1) 
	 set_task(4.5, "restore_rpg_ammo", id)
}

public restore_rpg_ammo(id){
	// rpg 
	if(hl_get_ammo(id,HLW_RPG) <= get_pcvar_num(cvar_ammo_rpgclip) && hl_get_ammo(id,HLW_RPG) != 0 )
		{
			if (hl_get_ammo(id,HLW_RPG) <= get_pcvar_num(cvar_start_ammo_rpgclip))
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_RPG)),hl_get_ammo(id,HLW_RPG)+1); // +1 rocket cuz its wasted when reload
				hl_set_ammo(id,HLW_RPG,0); 	
			}
			else 
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_RPG)),get_pcvar_num(cvar_start_ammo_rpgclip));
				hl_set_ammo(id,HLW_RPG,hl_get_ammo(id,HLW_RPG)-get_pcvar_num(cvar_start_ammo_rpgclip)+1); // +1 rocket cuz its wasted when reload	
			}
		}
}

/*
// rpg reload speed (R) 
public rpg_reload_post(const rpg)
{
	server_cmd("say reloading rpg")
}
*/

// Crossbow verify ammo on reload
public crossbow_primary_attack_pre(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, LINUX_OFF_SET_4)
    //restore crossbow ammo 
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_CROSSBOW))) == 1)
	 set_task(4.0, "restore_crossbow_ammo", player)
}

 //restore crossbow ammo 
public restore_crossbow_ammo(id){
		
		if(hl_get_ammo(id,HLW_CROSSBOW) <= get_pcvar_num(cvar_ammo_crossbow) && hl_get_ammo(id,HLW_CROSSBOW) != 0 )
		{
			if (hl_get_ammo(id,HLW_CROSSBOW) <= get_pcvar_num(cvar_start_ammo_crossbow))
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_CROSSBOW)),hl_get_ammo(id,HLW_CROSSBOW)+5); // +5 cuz its wasted when reload
				hl_set_ammo(id,HLW_CROSSBOW,0); 
			}
			else
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_CROSSBOW)),get_pcvar_num(cvar_start_ammo_crossbow));
				hl_set_ammo(id,HLW_CROSSBOW,hl_get_ammo(id,HLW_CROSSBOW)-get_pcvar_num(cvar_start_ammo_crossbow)+5); // +5 cuz its wasted when reload	
			}
		}
}



// Crossbow firing speed (MOUSE1) -1
public crossbow_primary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.30)	
}
// Crossbow firing speed (MOUSE2) -1
public crossbow_secondary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.25)
}
// Crossbow reload speed (R) 
public crossbow_reload_post(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, LINUX_OFF_SET_4)
	
	set_ent_data_float(player, "CBaseMonster", "m_flNextAttack", 1.0);
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 2.1)
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 1.5)
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 1.5)
}


// 357 verify ammo
public colt_primary_attack_pre(this)
{	
	new player = get_pdata_cbase(this, m_pPlayer, LINUX_OFF_SET_4)
    //restore 357 ammo 
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_PYTHON))) == 1)
	 set_task(3.5, "restore_357_ammo", player)
}

//367 restore ammo
public restore_357_ammo(id){
		
			if(hl_get_ammo(id,HLW_PYTHON) <= get_pcvar_num(cvar_ammo_357) && hl_get_ammo(id,HLW_PYTHON) != 0 )
		{
			if (hl_get_ammo(id,HLW_PYTHON) <= get_pcvar_num(cvar_start_ammo_357))
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_PYTHON)),hl_get_ammo(id,HLW_PYTHON)+6); //+6 cuz wasted on reloading 
				hl_set_ammo(id,HLW_PYTHON,0); 
			}
			else
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_PYTHON)),get_pcvar_num(cvar_start_ammo_357));
				hl_set_ammo(id,HLW_PYTHON,hl_get_ammo(id,HLW_PYTHON)-get_pcvar_num(cvar_start_ammo_357)+6); //+6 cuz wasted on reloading	
			}
		}
}


// 357 firing speed (MOUSE1) -1
public colt_primary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.12)
}
// 357 firing speed (MOUSE2) -1
public colt_secondary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.12)
}

// 9mmhandgun firing speed (MOUSE1) -1 + verify ammo
public glock_primary_attack_pre(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, LINUX_OFF_SET_4)
	
    //restore 9mmhandgun ammo 
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_GLOCK))) == 1)
	 set_task(2.0, "restore_glock_ammo", player)
 
	old_clip[player] = get_pdata_int(this, m_iClip, LINUX_OFF_SET_4)

}

 //restore 9mmhandgun ammo 
public restore_glock_ammo(id){
		
			if(hl_get_ammo(id,HLW_GLOCK) <= get_pcvar_num(cvar_ammo_glock) && hl_get_ammo(id,HLW_GLOCK) != 0 )
		{
			if (hl_get_ammo(id,HLW_GLOCK) <= get_pcvar_num(cvar_start_ammo_glock))
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_GLOCK)),hl_get_ammo(id,HLW_GLOCK)+17); // + 17 cuz wasted on reloading
				hl_set_ammo(id,HLW_GLOCK,0); 
			}
			else
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_GLOCK)),get_pcvar_num(cvar_start_ammo_glock));
				hl_set_ammo(id,HLW_GLOCK,hl_get_ammo(id,HLW_GLOCK)-get_pcvar_num(cvar_start_ammo_glock)+17); // + 17 cuz wasted on reloading	
			}
		}
}


// gauss firing speed (MOUSE1) -1
public gauss_primary_attack_pre(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.01)
}

// hornetgun firing speed (MOUSE1) -1
public hornet_primary_attack_pre(this)
{
	//set_ent_data_float(this, "CBasePlayerWeapon", "m_flFlySpeed", 600.0);   // to do  - m_flFlySpeed doesnt exist as a class
}


// 9mmhandgun firing speed (MOUSE1) -2
public glock_primary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 9999.0)

	new player = get_pdata_cbase(this, m_pPlayer, LINUX_OFF_SET_4)

	if(old_clip[player] <= 0)
		return

	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.1)

	if(get_pdata_int(this, m_iClip, LINUX_OFF_SET_4) != 0)
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 2.0)
	else
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.3)
}

// Snark firing speed (MOUSE1) 
public snark_primary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.11)
}

// Satchel firing speed (MOUSE1) 
public satchel_secondary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.15)
}

// Crowbar firing speed (MOUSE1) 
public crowbar_primary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.1)
}

// 9mmhandgun secondary attack

public glock_secondary_attack(const entity)
{
	return HAM_SUPERCEDE
} 

public glock_reload(const gloc)
{
	new id = get_pdata_cbase(gloc, m_pPlayer, 4)

	set_pev(id, pev_fov, fov)
}

// crowbar throw on MOUSE 2
public SecondaryAttack_Crowbar(this)
{
	new id = get_pdata_cbase(this, m_pPlayer, LINUX_OFF_SET_4)
	
	if(!crowbar_spawn(id))
	return HAM_IGNORED
	
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.5)
	ExecuteHam(Ham_RemovePlayerItem, id, this)
	user_has_weapon(id, HLW_CROWBAR, 0)
	ExecuteHamB(Ham_Item_Kill, this)
	
	return HAM_IGNORED
}

//handgrenade throw
public Grenade_SecondaryAttack_Post(this)
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.1)


// WEAPON DAMAGES - need to add customizable cvars to it
public Weapons_Damages(victim, inflictor, Float:damage, Float:direction[3], traceresult, damagebits)
{
	if(!(1 <= inflictor <= maxplayers))
	return HAM_IGNORED

	if(get_user_weapon(inflictor) == HLW_GLOCK)
	SetHamParamFloat(3, 50.0)

	if(get_user_weapon(inflictor) == HLW_PYTHON)
	SetHamParamFloat(3, 150.0)

	if(get_user_weapon(inflictor) == HLW_SHOTGUN)
	SetHamParamFloat(3, 60.0)

	if(get_user_weapon(inflictor) == HLW_MP5)
	SetHamParamFloat(3, 40.0)

	return HAM_IGNORED
}

public Forward_TraceAttack(const Victim, const Attacker, Float:Damage, const Float:Direction[3], const TraceResult, const Damagebits)
{
	if(is_player(Attacker) && (Damagebits & DMG_CROSSBOW) && get_user_weapon(Attacker) == HLW_CROSSBOW)
	{
		if(InZoom(Attacker))
		{
			SetHamParamFloat(3, 100.0)
			return HAM_HANDLED
		}
	}
	return HAM_IGNORED
}

public LongJump_Sound()
{
	BlockSound = register_forward(FM_EmitSound, "EmitSound_Block")
}

public EmitSound_Block()
{
	unregister_forward(FM_EmitSound, BlockSound)
	return FMRES_SUPERCEDE
}

// entity remove
public RemoveEntity()
{
	if(get_pcvar_num(cvar_remove_entities))
	{
		for(new i; i < sizeof Remove_Entity; i++)	
		{
			while((r_ent = fm_find_ent_by_class(r_ent, Remove_Entity[i])))
			{
				if(pev_valid(r_ent))
				{
					engfunc(EngFunc_RemoveEntity, r_ent)
				}
			}
		}
	}
}

public Func_RemoveEntity(ent)
{
	if(pev_valid(ent))
	{
		engfunc(EngFunc_RemoveEntity, ent)
	}	
}

// Rainbow effect on rpg and hornet trails

public MessageTempEntity(msg_id,msg_dest){	
	if(msg_dest!=MSG_BROADCAST||get_msg_arg_int(1)!=TE_BEAMFOLLOW)
		return PLUGIN_CONTINUE
		
	static ent;ent = get_msg_arg_int(2)
	static team;team = get_user_team(pev(ent, pev_owner))
	
	if(!team){
		get_trail_color()
	}
	
	set_msg_arg_int(6, ARG_BYTE, g_Colors[team][0])
	set_msg_arg_int(7, ARG_BYTE, g_Colors[team][1])
	set_msg_arg_int(8, ARG_BYTE, g_Colors[team][2])
	set_msg_arg_int(9, ARG_BYTE, 255)
	
	return PLUGIN_CONTINUE
}

get_trail_color(){
	static string[20]
	get_pcvar_string(cv_clor,string,19)
	
	if(!string[0]){
		g_Colors[0][0] = random(256)
		g_Colors[0][1] = random(256)
		g_Colors[0][2] = random(256)
	}else{
		static sclor[3][5]
		parse(string,sclor[0],4,sclor[1],4,sclor[2],4)
		
		g_Colors[0][0] = str_to_num(sclor[0])
		g_Colors[0][1] = str_to_num(sclor[1])
		g_Colors[0][2] = str_to_num(sclor[2])
	}
}

// glock zoom

public CmdStart(id, uc_handle, seed)
{
	if(alive[id] && glock[id] && get_uc(uc_handle, UC_Buttons) & IN_ATTACK2 && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		switch(zoom[id])
		{
			case 0:
			{
				zoom[id] = 1
				set_pev(id, pev_fov, 45.0)
			}
			case 1:
			{
				zoom[id] = 0

				set_pev(id, pev_fov, fov)
			}
		}
		emit_sound(id, CHAN_ITEM, "weapons/xbow_reload1.wav", 0.20, 2.40, 0, 100)
	}
}

public item_holster(const gloc)
{
	new id = get_pdata_cbase(gloc, m_pPlayer, 4)

	set_pev(id, pev_fov, fov)

	glock[id] = false
}

public item_deploy(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 9999.0);

	new id = get_pdata_cbase(this, m_pPlayer, 4)

	glock[id] = true
}


public DeathMsg()					
{	
			
	new id = read_data(2)
	parachute_reset(id)	

	static weapon[20]
	get_msg_arg_string(3, weapon, 19)

	if(equal(weapon, HLFW_CROWBAR)) 
		set_msg_arg_string(3, "crowbar")

	if(equal(weapon, HLFW_HANDGRENADE)) 
		set_msg_arg_string(3, "grenade")

}

parachute_reset(id)
{
	if(para_ent[id] > 0) 
	{
		if (is_valid_ent(para_ent[id])) 
		{
			remove_entity(para_ent[id])
		}
	}

	if(is_user_alive(id)) set_user_gravity(id, 1.0)
	para_ent[id] = 0
}

public newSpawn(id)
{
	if(para_ent[id] > 0) 
	{
		remove_entity(para_ent[id])
		set_user_gravity(id, 1.0)
		para_ent[id] = 0
	}
}

public hlfw_crowbar_touch(toucher, touched)
{
	pev(toucher, pev_origin, origin)
	pev(toucher, pev_angles, angles)
	
	if(!is_player(touched))
	{
		emit_sound(toucher, CHAN_WEAPON, "weapons/cbar_hit1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM)
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
		write_byte(TE_SPARKS)
		engfunc(EngFunc_WriteCoord, origin[0])
		engfunc(EngFunc_WriteCoord, origin[1])
		engfunc(EngFunc_WriteCoord, origin[2])
		message_end()
	}
	else
	{
		ExecuteHamB(Ham_TakeDamage, touched, toucher, pev(toucher, pev_owner), get_pcvar_float(damage), DMG_CLUB)	
		emit_sound(toucher, CHAN_WEAPON, "weapons/cbar_hitbod1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM)
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
		write_byte(TE_BLOODSPRITE)
		engfunc(EngFunc_WriteCoord, origin[0]+random_num(-20, 20))
		engfunc(EngFunc_WriteCoord, origin[1]+random_num(-20, 20))
		engfunc(EngFunc_WriteCoord, origin[2]+random_num(-20, 20))
		write_short(blood_spray)
		write_short(blood_drop)
		write_byte(248)
		write_byte(15)
		message_end()
	}
	
	engfunc(EngFunc_RemoveEntity, toucher)
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "weapon_crowbar"))
		
	DispatchSpawn(ent)
	set_pev(ent, pev_spawnflags, SF_NORESPAWN)	
	
	angles[0] = 0.0
	angles[2] = 0.0
	
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_angles, angles)
	
	set_task(get_pcvar_float(lifetime), "Func_RemoveEntity", ent)
}



public ItemAdd(ent, id)
{
	remove_task(ent)
}

public crowbar_spawn(id)
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!pev_valid(ent))
		return 0
	
	set_pev(ent, pev_classname, HLFW_CROWBAR)
	engfunc(EngFunc_SetModel, ent, "models/w_crowbar.mdl")
	engfunc(EngFunc_SetSize, ent, Float:{-4.0, -4.0, -4.0} , Float:{4.0, 4.0, 4.0})
	
	get_projective_pos(id, vec)
	engfunc(EngFunc_SetOrigin, ent, vec)
	
	pev(id, pev_v_angle, vec)
	vec[0] = 90.0
	vec[2] = floatadd(vec[2], -90.0)
	
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_angles, vec)
	
	velocity_by_aim(id, get_pcvar_num(speed)+get_speed(id), vec)
	set_pev(ent, pev_velocity, vec)
	
	set_pev(ent, pev_nextthink, get_gametime()+0.1)
	
	DispatchSpawn(ent)
	
	set_pev(ent, pev_movetype, MOVETYPE_TOSS)
	set_pev(ent, pev_solid, SOLID_BBOX)
	
	emit_sound(id, CHAN_WEAPON, "weapons/cbar_miss1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM)
	set_task(0.1, "Fly_Whizz", ent)
	
	return ent
}


public Weapon_think(ent)
{
	pev(ent, pev_angles, vec)
	vec[0] = floatadd(vec[0], -15.0)
	set_pev(ent, pev_angles, vec)
	
	set_pev(ent, pev_nextthink, get_gametime()+0.1)
}

public Fly_Whizz(ent)
{
	if(pev_valid(ent))
	{
		emit_sound(ent, CHAN_WEAPON, "weapons/cbar_miss1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM)
		
		set_task(0.2, "Fly_Whizz", ent)
	}
}

get_projective_pos(player, Float:oridjin[3])
{
	GetGunPosition(player, oridjin)
	
	global_get(glb_v_forward, v_forward)
	global_get(glb_v_right, v_right)
	global_get(glb_v_up, v_up)
	
	xs_vec_mul_scalar(v_forward, 6.0, v_forward)
	xs_vec_mul_scalar(v_right, 2.0, v_right)
	xs_vec_mul_scalar(v_up, -2.0, v_up)
	
	xs_vec_add(oridjin, v_forward, oridjin)
	xs_vec_add(oridjin, v_right, oridjin)
	xs_vec_add(oridjin, v_up, oridjin)
}

stock GetGunPosition(const player, Float:origin[3])
{
	pev(player, pev_origin, origin)
	pev(player, pev_view_ofs, viewOfs)
	
	xs_vec_add(origin, viewOfs, origin)
}


public welcome_message()
{
	pos_end = 1
	pos_start = 0
	g_xPos = 0.80
	
	g_length = strlen(g_scrollMsg)
	
	set_task(SPEED, "showMsg", 123, "", 0, "a", g_length + 120)
}

public showMsg()
{
	new Colors = random_num(0, 9-1)
	new Colors2 = random_num(0, 3-1)

	new a = pos_start, i = 0

	while (a < pos_end)
		g_displayMsg[i++] = g_scrollMsg[a++]

	g_displayMsg[i] = 0

	if (pos_end < g_length)
		pos_end++

	if (g_xPos > -1.0)
		g_xPos -= 0.0180
	else
	{
		pos_start++
		g_xPos = -1.0
	}

	SET_DMESSAGE(COLORLIST[Colors][0], COLORLIST[Colors][1], COLORLIST[Colors][2], g_xPos, 0.86, 2, 0.01, 0.01, 0.01, 0.01)
	SHOW_DMESSAGE(0, "###################################")

	SET_DMESSAGE(COLORLIST2[Colors2][0], COLORLIST2[Colors2][1], COLORLIST2[Colors2][2], -1.0, 0.89, 1, SPEED, SPEED, 0.05, 0.05)
	SHOW_DMESSAGE(0, "* Server running OZDM Mod by |-RT-| teylo")

	SET_DMESSAGE(COLORLIST[Colors][0], COLORLIST[Colors][1], COLORLIST[Colors][2], g_xPos, 0.92, 2, 0.01, 0.01, 0.01, 0.01)
	SHOW_DMESSAGE(0, "###################################")
}



public client_PreThink(id)
{
	if(!is_user_alive(id)) return
	
	new Float:fallspeed = 100 * -1.0
	new Float:frame
	new button = get_user_button(id)
	new oldbutton = get_user_oldbutton(id)
	new flags = get_entity_flags(id)
	if(para_ent[id] > 0 && (flags & FL_ONGROUND)) 
	{
		if(get_user_gravity(id) == 0.1) set_user_gravity(id, 1.0)
		{
			if(entity_get_int(para_ent[id],EV_INT_sequence) != 2) 
			{
				entity_set_int(para_ent[id], EV_INT_sequence, 2)
				entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
				entity_set_float(para_ent[id], EV_FL_frame, 0.0)
				entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
				entity_set_float(para_ent[id], EV_FL_framerate, 0.0)
				return
			}
			frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 2.0
			entity_set_float(para_ent[id],EV_FL_fuser1,frame)
			entity_set_float(para_ent[id],EV_FL_frame,frame)
			if(frame > 254.0) 
			{
				remove_entity(para_ent[id])
				para_ent[id] = 0
			}
			else 
			{
				remove_entity(para_ent[id])
				set_user_gravity(id, 1.0)
				para_ent[id] = 0
			}
			return
		}
	}
	if (button & IN_USE)  
	{
		if (get_pcvar_num(cvar_wings) == 1)
		{
		new Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)
		if(velocity[2] < 0.0) 
		{
			if(para_ent[id] <= 0) 
			{
				para_ent[id] = create_entity("info_target")
				if(para_ent[id] > 0) 
				{
					entity_set_string(para_ent[id],EV_SZ_classname,"parachute")
					entity_set_edict(para_ent[id], EV_ENT_aiment, id)
					entity_set_edict(para_ent[id], EV_ENT_owner, id)
					entity_set_int(para_ent[id], EV_INT_movetype, MOVETYPE_FOLLOW)
					entity_set_model(para_ent[id], "models/ozdm_wings.mdl")
					entity_set_int(para_ent[id], EV_INT_sequence, 0)
					entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
					entity_set_float(para_ent[id], EV_FL_frame, 0.0)
					entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				}
			}
			if(para_ent[id] > 0) 
			{
				entity_set_int(id, EV_INT_sequence, 3)
				entity_set_int(id, EV_INT_gaitsequence, 1)
				entity_set_float(id, EV_FL_frame, 1.0)
				entity_set_float(id, EV_FL_framerate, 1.0)
				set_user_gravity(id, 0.1)
				velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed
				entity_set_vector(id, EV_VEC_velocity, velocity)
				if(entity_get_int(para_ent[id],EV_INT_sequence) == 0) 
				{
					frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 1.0
					entity_set_float(para_ent[id],EV_FL_fuser1,frame)
					entity_set_float(para_ent[id],EV_FL_frame,frame)
					if (frame > 100.0) 
					{
						entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
						entity_set_float(para_ent[id], EV_FL_framerate, 0.4)
						entity_set_int(para_ent[id], EV_INT_sequence, 1)
						entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
						entity_set_float(para_ent[id], EV_FL_frame, 0.0)
						entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
					}
				}
			}
		}
		else if(para_ent[id] > 0) 
		{
			remove_entity(para_ent[id])
			set_user_gravity(id, 1.0)
			para_ent[id] = 0
		}
	}
	}
	else if((oldbutton & IN_USE) && para_ent[id] > 0 ) 
	{
		remove_entity(para_ent[id])
		set_user_gravity(id, 1.0)
		para_ent[id] = 0
	}
}

public remove_()
{
	remove_task()
}

stock SET_DMESSAGE(red = 0, green = 255, blue = 0, Float:x = -1.0, Float:y = 0.65, effects = 2, Float:fxtime = 6.0, Float:holdtime = 3.0, Float:fadeintime = 0.1, Float:fadeouttime = 1.5, bool:reliable = false)
{
	#define clamp_byte(%1) (clamp(%1,0,255))
	#define pack_color(%1,%2,%3) (%3 + (%2 << 8) + (%1 << 16))

	D_color       	= pack_color(clamp_byte(red),clamp_byte(green),clamp_byte(blue))
	D_x      	= _:x
	D_y      	= _:y
	D_effect  	= effects
	D_fxtime   	= _:fxtime
	D_holdtime  	= _:holdtime
	D_fadeintime 	= _:fadeintime
	D_fadeouttime 	= _:fadeouttime
	D_reliable	= _:reliable

	return 1
}

stock SHOW_DMESSAGE(index, const message[], any:...)
{
	static buffer[128], playersList[32], numPlayers, 
	numArguments, size

	numArguments = numargs()
	new Array:handleArrayML = ArrayCreate()
	size = ArraySize(handleArrayML)


	if(numArguments == 2)
	{
		Send_Director_Hud_Message(index, message)
	}
	else if(index || numArguments == 3)
	{
		vformat(buffer, charsmax(buffer), message, 3)
		Send_Director_Hud_Message(index, buffer)
	}
	else
	{
		get_players(playersList, numPlayers, "ch")

		if(!numPlayers)
		{
			return 0
		}

		for(new i = 2, j; i < numArguments; i++)
		{

			if(getarg(i) == LANG_PLAYER)
			{
				while((buffer[j] = getarg(i + 1, j++))){}
				j = 0

				if(GetLangTransKey(buffer) != TransKey_Bad)
				{
					ArrayPushCell(handleArrayML, i++)
				}
			}
		}
		if(!size)
		{
			vformat(buffer, charsmax(buffer), message, 3)
			Send_Director_Hud_Message(index, buffer)
		}
		else
		{
			for(new i = 0, j; i < numPlayers; i++)
			{
				index = playersList[i]

				for(j = 0; j < size; j++)
				{
					setarg(ArrayGetCell(handleArrayML, j), 0, index)
				}
				vformat(buffer, charsmax(buffer), message, 3)
				Send_Director_Hud_Message(index, buffer)
			}
		}
		ArrayDestroy(handleArrayML)
	}
	return 1
}

stock Send_Director_Hud_Message(const index, const message[])
{
	message_begin(D_reliable ?(index ? MSG_ONE : MSG_ALL) : (index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST), SVC_DIRECTOR, _, index)
	{
		write_byte(strlen(message) + 31)
		write_byte(DRC_CMD_MESSAGE)
		write_byte(D_effect)
		write_long(D_color)
		write_long(D_x)
		write_long(D_y)
		write_long(D_fadeintime)
		write_long(D_fadeouttime)
		write_long(D_holdtime)
		write_long(D_fxtime)
		write_string(message)
	}
	message_end()
}

