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
const m_flNextPrimaryAttack = 35
const m_flNextSecondaryAttack = 36
const m_flTimeWeaponIdle = 37
const m_iClip = 40
const m_iDefaultAmmo = 44
const m_flNextAttack = 148
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
glock[33], BlockSound, maxplayers, r_ent, pphl_r, pphl_d, 
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

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	pphl_r = register_cvar("pphl_remove_entity", "1")
	pphl_d = register_cvar("pphl_deceptive_satchel", "1")
	maxplayers = get_maxplayers()

	game_description = get_cvar_num("mp_teamplay") ? "RO OZDM (TEAM)" : "RO OZDM"
	register_forward(FM_GetGameDescription, "Game")

	register_forward(FM_CmdStart, "CmdStart")

	RegisterHam(Ham_Spawn, "player", "spawn_player", 1)
	RegisterHam(Ham_Spawn, "monster_satchel", "FUN_MODS", 1)
	RegisterHam(Ham_Spawn, "weaponbox", "kill_weaponbox")


	RegisterHam(Ham_Item_AddToPlayer, "weapon_9mmAR", "fw_MP5_Add")
	RegisterHam(Ham_Item_AddDuplicate, "weapon_9mmAR", "fw_MP5_Add")

	RegisterHam(Ham_TraceAttack, "player", "Weapons_Damages")
	RegisterHam(Ham_TraceAttack, "player", "Forward_TraceAttack")

	RegisterHam(Ham_Item_Deploy, "weapon_9mmhandgun", "item_deploy", 1)
	RegisterHam(Ham_Item_Holster, "weapon_9mmhandgun", "item_holster", 1)

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_tripmine", "ppp", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_snark", "ppp", 1)

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
	
	//RemoveEntity()

	register_message(get_user_msgid("DeathMsg"), "DeathMsg")
	
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

	set_task(15.0, "welcome_message")
	set_task(30.0, "remove_")
}

public Game() 
{
	forward_return(FMV_STRING, game_description)
	return FMRES_SUPERCEDE
}

public client_putinserver(id)
{
	set_task(0.50, "spawn_player", id)
}

public client_disconnected(id)
{
	if(task_exists(id))
	remove_task(id)
}

public spawn_player(id)
{
	alive[id] = is_user_alive(id)

	if(is_user_alive(id))
	{
      give_weapons(id)
	}
}

// ====== SPAWN EQUIP WEAPONS =========
public give_weapons(id) 
{
	if(is_user_alive(id))
	{
			hl_set_user_longjump(id,true);
			hl_set_user_health(id,250);
			hl_set_user_armor(id,250);
			give_item( id, "weapon_crowbar" );	
			give_item( id, "weapon_9mmhandgun" );
			give_item( id, "weapon_gauss" );
			give_item( id, "weapon_egon" );
			give_item( id, "weapon_crossbow" );
			give_item( id, "weapon_rpg" );
			give_item( id, "weapon_satchel" );
			give_item( id, "weapon_snark" );
			give_item( id, "weapon_handgrenade" );		
			give_item( id, "weapon_hornetgun" );
			give_item( id, "weapon_tripmine" );
			give_item( id, "weapon_357" );
			give_item( id, "weapon_9mmAR" );
			give_item( id, "weapon_snark" );
			give_item( id, "weapon_shotgun" );

			restore_ammo(id);
	}
}

// ====== RESTORE AMMO WHEN KILL =========
public restore_ammo(id) 
{
	// 9mmhandgun 

		hl_set_ammo(id,HLW_GLOCK,250); 	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_GLOCK)),100);		

	// gauss 

		hl_set_ammo(id,HLW_GAUSS,999999); 	

	
	// egon 

		hl_set_ammo(id,HLW_EGON,999999);

	
	// crossbow 

		hl_set_ammo(id,HLW_CROSSBOW,250); 	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_CROSSBOW)),50);		

	
	// rpg 
		hl_set_ammo(id,HLW_RPG,50); 	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_RPG)),50);			
	
	//357

		hl_set_ammo(id,HLW_PYTHON,250); 	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_PYTHON)),50);		

	
	//9mmAR

		hl_set_ammo(id,HLW_MP5,250); 	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_MP5)),50);			
	
	// ammo ARgrenades
		hl_set_ammo(id,HLW_CHAINGUN,20); 	
	
	//buckshot - shotgun

		hl_set_ammo(id,HLW_SHOTGUN,200); 	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_SHOTGUN)),100);		
	
	//satchel
		hl_set_ammo(id,HLW_SATCHEL,10); 	

	
	//tripmine
		hl_set_ammo(id,HLW_TRIPMINE,5); 	

	
	//handgrenade

		hl_set_ammo(id,HLW_HANDGRENADE,20); 	
	
	//snark
		hl_set_ammo(id,HLW_SNARK,15); 	
		
	// hornet
	hl_set_ammo(id,HLW_HORNETGUN,100); 	
	
		
}



public FUN_MODS(ent)
{
	if(get_pcvar_num(pphl_d) == 1 && pev_valid(ent))
	{
		engfunc(EngFunc_SetModel, ent, SATCHEL_MOD_SKIN_LIST[random_num(0, 2-1)])  
	}
}

public kill_weaponbox(ent)
{
	return HAM_SUPERCEDE
}


// Shotgun firing speed (MOUSE1) -1
public shotgun_primary_attack_pre(const shotgun)
{
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFF_SET_4)
	old_clip[player] = get_pdata_int(shotgun, m_iClip, LINUX_OFF_SET_4)
	
	//restore shotgun ammo - only 1 bullet left is need to verify
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_SHOTGUN))) == 1) 
	 set_task(1.0, "restore_shotgun_ammo", player)
}
// Shotgun firing speed (MOUSE1) -2
public shotgun_primary_attack_post(const shotgun)
{
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFF_SET_4)
	

	if(old_clip[player] <= 0)
		return

	set_pdata_float(shotgun, m_flNextPrimaryAttack  , 0.12, LINUX_OFF_SET_4)

	if(get_pdata_int(shotgun, m_iClip, LINUX_OFF_SET_4) != 0)
		set_pdata_float(shotgun, m_flTimeWeaponIdle, 2.0, LINUX_OFF_SET_4)
	else
		set_pdata_float(shotgun, m_flTimeWeaponIdle, 0.3, LINUX_OFF_SET_4)
}

// Shotgun firing speed (MOUSE2) -1
public shotgun_secondary_attack_pre(const shotgun)
{
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFF_SET_4)
	old_clip[player] = get_pdata_int(shotgun, m_iClip, LINUX_OFF_SET_4)
		//restore shotgun ammo - they can have 1 or 2 bullets left before reloading
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_SHOTGUN))) == 1 || hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_SHOTGUN))) == 2 )
	 set_task(1.0, "restore_shotgun_ammo", player)
}
// Shotgun firing speed (MOUSE2) -2
public shotgun_secondary_attack_post(const shotgun)
{
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFF_SET_4)

	if(old_clip[player] <= 1)
		return

	set_pdata_float(shotgun, m_flNextSecondaryAttack, 0.12, LINUX_OFF_SET_4)

	if(get_pdata_int(shotgun, m_iClip, LINUX_OFF_SET_4) != 0)
		set_pdata_float(shotgun, m_flTimeWeaponIdle, 3.0, LINUX_OFF_SET_4)
	else
		set_pdata_float(shotgun, m_flTimeWeaponIdle, 0.85, LINUX_OFF_SET_4)
}


public restore_shotgun_ammo(id){
	// shotgun 
	if(hl_get_ammo(id,HLW_SHOTGUN) <= 200 && hl_get_ammo(id,HLW_SHOTGUN) != 0 )
		{
			if (hl_get_ammo(id,HLW_SHOTGUN) <= 100)
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_SHOTGUN)),hl_get_ammo(id,HLW_SHOTGUN)+1); // +1 bullet cuz its wasted when reload
				hl_set_ammo(id,HLW_SHOTGUN,0);
			}
			else
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_SHOTGUN)),100);
				hl_set_ammo(id,HLW_SHOTGUN,hl_get_ammo(id,HLW_SHOTGUN)-100); 	
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

// 9mmAR firing speed (MOUSE1) -1
public mp5_primary_attack_pre(const mp5)
{
	new player = get_pdata_cbase(mp5, m_pPlayer, LINUX_OFF_SET_4)
	old_clip[player] = get_pdata_int(mp5, m_iClip, LINUX_OFF_SET_4)
	
	
}
// 9mmAR firing speed (MOUSE1) -2
public mp5_primary_attack_post(const mp5)
{
	set_pdata_float(mp5, m_flNextPrimaryAttack, 0.03, LINUX_OFF_SET_4)
}



// 9mmAR grenade firing speed (MOUSE2) 
public grenades_secondary_attack_post(const secondary)
{
	set_pdata_float(secondary, m_flNextSecondaryAttack, 0.15, LINUX_OFF_SET_4)
}

// rpg firing speed (MOUSE1) -1
public rpg_primary_attack_post(const rpg)
{
	set_pdata_float(rpg, m_flNextPrimaryAttack, 0.12, LINUX_OFF_SET_4)

}

// rpg ammo verification when rockets = 1 + call restore ammo
public rpg_primary_attack_pre(const rpg)
{
	new id = get_pdata_cbase(rpg, m_pPlayer, LINUX_OFF_SET_4)
	// restore rpg ammo when 1 rocket left - couldnt be done in reload function because it loops several times.
	if (hl_get_weapon_ammo((hl_user_has_weapon(id,HLW_RPG))) == 1) 
	 set_task(4.5, "restore_rpg_ammo", id)
}

public restore_rpg_ammo(id){
	// rpg 
	if(hl_get_ammo(id,HLW_RPG) <= 50 && hl_get_ammo(id,HLW_RPG) != 0 )
		{
			hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_RPG)),hl_get_ammo(id,HLW_RPG)+1); // +1 rocket cuz its wasted when reload
			hl_set_ammo(id,HLW_RPG,0); 	
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
public crossbow_primary_attack_pre(const crossbow)
{
	new player = get_pdata_cbase(crossbow, m_pPlayer, LINUX_OFF_SET_4)
    //restore crossbow ammo 
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_CROSSBOW))) == 1)
	 set_task(4.0, "restore_crossbow_ammo", player)
}

 //restore crossbow ammo 
public restore_crossbow_ammo(id){
	// rpg 
		
			if(hl_get_ammo(id,HLW_CROSSBOW) <= 250 && hl_get_ammo(id,HLW_CROSSBOW) != 0 )
		{
			if (hl_get_ammo(id,HLW_CROSSBOW) <= 50)
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_CROSSBOW)),hl_get_ammo(id,HLW_CROSSBOW)); 
			}
			else
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_CROSSBOW)),50);
				hl_set_ammo(id,HLW_CROSSBOW,hl_get_ammo(id,HLW_CROSSBOW)-50); 	
			}
		}
}


// Crossbow firing speed (MOUSE1) -1
public crossbow_primary_attack_post(const crossbow)
{
	set_pdata_float(crossbow, m_flNextPrimaryAttack, 0.30, LINUX_OFF_SET_4)
}
// Crossbow firing speed (MOUSE2) -1
public crossbow_secondary_attack_post(const crossbow)
{
	set_pdata_float(crossbow, m_flNextSecondaryAttack, 0.25, LINUX_OFF_SET_4)
}
// Crossbow reload speed (R) 
public crossbow_reload_post(const crossbow)
{
	new player = get_pdata_cbase(crossbow, m_pPlayer, LINUX_OFF_SET_4)
	
	set_pdata_float(player , m_flNextAttack, 1.0)
	set_pdata_float(crossbow, m_flTimeWeaponIdle, 2.1, LINUX_OFF_SET_4)
	set_pdata_float(crossbow, m_flNextPrimaryAttack, 1.5, LINUX_OFF_SET_4)
	set_pdata_float(crossbow, m_flNextSecondaryAttack, 1.5, LINUX_OFF_SET_4)
}


// 357 verify ammo
public colt_primary_attack_pre(const colt)
{	
	new player = get_pdata_cbase(colt, m_pPlayer, LINUX_OFF_SET_4)
    //restore 357 ammo 
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_PYTHON))) == 1)
	 set_task(3.5, "restore_357_ammo", player)
}

//367 restore ammo
public restore_357_ammo(id){
	// rpg 
		
			if(hl_get_ammo(id,HLW_PYTHON) <= 250 && hl_get_ammo(id,HLW_PYTHON) != 0 )
		{
			if (hl_get_ammo(id,HLW_PYTHON) <= 50)
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_PYTHON)),hl_get_ammo(id,HLW_PYTHON)); 
			}
			else
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_PYTHON)),50);
				hl_set_ammo(id,HLW_PYTHON,hl_get_ammo(id,HLW_PYTHON)-50+6); 	
			}
		}
}

// 357 firing speed (MOUSE1) -1
public colt_primary_attack_post(const colt)
{
	set_pdata_float(colt, m_flNextPrimaryAttack, 0.12, LINUX_OFF_SET_4)
}
// 357 firing speed (MOUSE2) -1
public colt_secondary_attack_post(const colt)
{
	set_pdata_float(colt, m_flNextSecondaryAttack, 0.12, LINUX_OFF_SET_4)
}

// 9mmhandgun firing speed (MOUSE1) -1 + verify ammo
public glock_primary_attack_pre(const glock)
{
	new player = get_pdata_cbase(glock, m_pPlayer, LINUX_OFF_SET_4)
	
    //restore 9mmhandgun ammo 
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_GLOCK))) == 1)
	 set_task(2.0, "restore_glock_ammo", player)
 
	old_clip[player] = get_pdata_int(glock, m_iClip, LINUX_OFF_SET_4)

}

 //restore 9mmhandgun ammo 
public restore_glock_ammo(id){
	// rpg 
		
			if(hl_get_ammo(id,HLW_GLOCK) <= 250 && hl_get_ammo(id,HLW_GLOCK) != 0 )
		{
			if (hl_get_ammo(id,HLW_GLOCK) <= 50)
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_GLOCK)),hl_get_ammo(id,HLW_GLOCK)); 
			}
			else
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_GLOCK)),50);
				hl_set_ammo(id,HLW_GLOCK,hl_get_ammo(id,HLW_GLOCK)-50+17); 	
			}
		}
}

// gauss firing speed (MOUSE1) -1
public gauss_primary_attack_pre(const gauss)
{

	set_pdata_float(gauss, m_flNextPrimaryAttack , 0.01, LINUX_OFF_SET_4)
	
}

// hornetgun firing speed (MOUSE1) -1
public hornet_primary_attack_pre(const hornet)
{

	//set_pdata_float(hornet, m_flFlySpeed , 600, LINUX_OFF_SET_4)
	
}


// 9mmhandgun firing speed (MOUSE1) -2
public glock_primary_attack_post(const glock)
{
	set_pdata_float(glock, m_flNextSecondaryAttack, 9999.0, 4)

	new player = get_pdata_cbase(glock, m_pPlayer, LINUX_OFF_SET_4)

	if(old_clip[player] <= 0)
		return

	set_pdata_float(glock, m_flNextPrimaryAttack  , 0.10, LINUX_OFF_SET_4)

	if(get_pdata_int(glock, m_iClip, LINUX_OFF_SET_4) != 0)
		set_pdata_float(glock, m_flTimeWeaponIdle, 2.0, LINUX_OFF_SET_4)
	else
		set_pdata_float(glock, m_flTimeWeaponIdle, 0.3, LINUX_OFF_SET_4)
}

// Snark firing speed (MOUSE1) 
public ppp(const primary)
{
	set_pdata_float(primary, m_flNextPrimaryAttack, 0.11, LINUX_OFF_SET_4)
}
// Satchel firing speed (MOUSE1) 
public satchel_secondary_attack_post(const secondary)
{
	set_pdata_float(secondary, m_flNextSecondaryAttack, 0.15, LINUX_OFF_SET_4)
}


// Crowbar firing speed (MOUSE1) 
public crowbar_primary_attack_post(const firespeed)
{
	set_pdata_float(firespeed, m_flNextPrimaryAttack, 0.1, LINUX_OFF_SET_4)
}

public fw_MP5_Add(ent)
{
	if(pev_valid(ent) == 2 && get_pdata_int(ent, m_iDefaultAmmo, LINUX_OFF_SET_4))
	{
		set_pdata_int(ent, m_iDefaultAmmo, 50, LINUX_OFF_SET_4)
	}
}

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

public RemoveEntity()
{
	if(get_pcvar_num(pphl_r))
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

public glock_secondary_attack(const entity)
{
	return HAM_SUPERCEDE
} 

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

public item_deploy(const gloc)
{
	set_pdata_float(gloc, m_flNextSecondaryAttack, 9999.0, 4)

	new id = get_pdata_cbase(gloc, m_pPlayer, 4)

	glock[id] = true
}

public glock_reload(const gloc)
{
	new id = get_pdata_cbase(gloc, m_pPlayer, 4)

	set_pev(id, pev_fov, fov)
}

public DeathMsg()					
{	
	static weapon[20]
	get_msg_arg_string(3, weapon, 19)

	if(equal(weapon, HLFW_CROWBAR)) 
		set_msg_arg_string(3, "crowbar")

	if(equal(weapon, HLFW_HANDGRENADE)) 
		set_msg_arg_string(3, "grenade")
}

public SecondaryAttack_Crowbar(ent)
{
	new id = get_pdata_cbase(ent, m_pPlayer, LINUX_OFF_SET_4)
	
	if(!crowbar_spawn(id))
	return HAM_IGNORED
	
	set_pdata_float(ent, m_flNextSecondaryAttack, 0.5, LINUX_OFF_SET_4)
	ExecuteHam(Ham_RemovePlayerItem, id, ent)
	user_has_weapon(id, HLW_CROWBAR, 0)
	ExecuteHamB(Ham_Item_Kill, ent)
	
	return HAM_IGNORED
}


public Grenade_SecondaryAttack_Post(weapon)
	set_pdata_float (weapon, m_flNextSecondaryAttack, 0.1, LINUX_OFF_SET_4)


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

public plugin_precache()
{
	blood_drop = precache_model("sprites/blood.spr")
	blood_spray = precache_model("sprites/bloodspray.spr")
}