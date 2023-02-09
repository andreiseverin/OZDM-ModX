# OZDM - ModX

![OZDM ModX](https://repository-images.githubusercontent.com/491540429/07c20528-70e2-4dc9-a30d-2f274ad42112)

Oz Deathmatch has been a faithful standby for deathmatch players for well over 13 years. 

In its original form simply added a grappling hook and allowed the server to play around with the weapon value for deathmatch, including clip size, damage, ammunition pickups and maximums, etc. Since that first release, more options have been added, along with one major alteration to the gameplay beyond whatever the administrator sets with the configuration files. The rune system started with just a few special power-ups and then slowly grew in number. Each player can carry one rune at a time, and can discard it if they're so inclined. Available runes include regeneration, vampire, low gravity and haste.


This plugin wants to replicate as good as possible the real mod which was server sided and aims to bring back good memories.

All credit for the ideas go the the authors


## Author of the plugin

- [@teylo](https://github.com/andreiseverin)

## Author of the original mod 
- [@OZ Deathmatch team](www.ozdeathmatch.com)



## Installation

Copy all the files in your valve folder. Then go to `valve\addons\amxmodx\configs\plugins.ini` and add a new line with : 

```bash
  ozdm.amxx
```
In the `ozdm_maps.ini` file you need to add all the maps where do you want the plugin to work.

You can set up the following cvars in the `server.cfg` file :

```bash

//////////////////////////////////////////////////////////////////
/////////////////////////// OZDM /////////////////////////////////
//////////////////////////////////////////////////////////////////

// ===== cvars weapons ======= (1-on 0-off)
sv_ozdm_crowbar 1
sv_ozdm_9mmhandgun 1
sv_ozdm_gauss 1
sv_ozdm_egon 0
sv_ozdm_crossbow 1
sv_ozdm_rpg 1
sv_ozdm_satchel 1
sv_ozdm_hornetgun 1
sv_ozdm_357 1
sv_ozdm_shotgun 1
sv_ozdm_9mmAR 1
sv_ozdm_handgrenade 1
sv_ozdm_snark 1
sv_ozdm_tripmine 1
// ===== cvars ammo ======= (add ammo value)
sv_ozdm_ammo_crossbow 250
sv_ozdm_ammo_buckshot 200
sv_ozdm_ammo_gaussclip 9999
sv_ozdm_ammo_rpgclip 50
sv_ozdm_ammo_9mmAR 250
sv_ozdm_ammo_ARgrenades 20
sv_ozdm_ammo_357 250
sv_ozdm_ammo_glock 250	
sv_ozdm_ammo_satchel 10
sv_ozdm_ammo_tripmine 5
sv_ozdm_ammo_hgrenade 20
sv_ozdm_ammo_snark 15	
sv_ozdm_ammo_hornetgun 100	
// ====== cvars start ammo ===== (add weapon ammo value)
sv_ozdm_start_ammo_crossbow 50
sv_ozdm_start_ammo_buckshot 100
sv_ozdm_start_ammo_rpgclip 5
sv_ozdm_start_ammo_9mmAR 50
sv_ozdm_start_ammo_357 50
sv_ozdm_start_ammo_glock 100
// ===== cvars items ======= (add armour and health start value)
sv_ozdm_health 100
sv_ozdm_armour 0
sv_ozdm_longjump 1 
sv_ozdm_remove_game_equip 1
sv_ozdm_remove_entity 0
sv_ozdm_deceptive_satchel 1
sv_ozdm_wings 1 

```

## To do

Add the rune system
