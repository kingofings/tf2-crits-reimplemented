#include <tf2_stocks>
#include <json>
#include <tf2attributes>
#include <stocksoup/tf/entity_prop_stocks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "0.5.4"

#define TF_WEAPON_ID_MAX 110

enum struct WeaponInfo
{
	int Damage;
	int BulletsPerShot;
	bool UseRapidFireCrits;
	float TimeFireDelay;

	void Init(int damage, int bulletsPerShot, bool useRapidFireCrits, float timeFireDelay)
	{
		this.Damage = damage;
		this.BulletsPerShot = bulletsPerShot;
		this.UseRapidFireCrits = useRapidFireCrits;
		this.TimeFireDelay = timeFireDelay;
	}
}

WeaponInfo g_WeaponInfo[TF_WEAPON_ID_MAX];

#include "common/common.sp"
#include "common/convars.sp"
#include "random/random.sp"
#include "weaponinfo/weaponinfo.sp"

public Plugin myinfo =
{
	name = "[TF2] ServerSide Crits",
	author = "kingo",
	description = "",
	version = PLUGIN_VERSION,
	url = "https://github.com/kingofings/serverside_crits"
};

public void OnPluginStart()
{
	GameData gameconf = new GameData("tf2.weaponinfo");
	if (!gameconf)SetFailState("Fail to parse gamedata tf2.weaponinfo.txt!");

	Setup_Common(gameconf);
	delete gameconf;

	FindConvars();
	ParseWeaponInfo();
}

public void OnConfigsExecuted()
{
	LogMessage("Setting tf_weapon_criticals to 0");
	tf_weapon_criticals.IntValue = 0;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
    bool oldResult = result;
	int weaponId = CTFWeaponBase_GetWeaponID(weapon);

	if (weaponId == TF_WEAPON_KNIFE)
	{
		return Plugin_Continue;
	}

	if (g_WeaponInfo[weaponId].BulletsPerShot == -1)
	{
		DoMeleeCrits(client, weapon, result, weaponId);
		return Plugin_Changed;
	}
	
	DoGunCrits(client, weapon, result, weaponId);

	if (oldResult != result)return Plugin_Changed;

    return Plugin_Continue;
}

void DoGunCrits(int player, int weapon, bool &result, int weaponId)
{
    if (!player)
    {
        result = false;
        return;
    }

    /*if (CTFPlayerShared_IsCritBoosted(player))
    {
        result = true;
        return;
    }*/

    //we just assume you are critboosted as we run tf_weapon_criticals 0
    if (result)
    {
        return;
    }

    float critChance = 0.0;
    float playerCritMult = GetCritMultiplier(player);

    if (weaponId == TF_WEAPON_SNIPERRIFLE || weaponId == TF_WEAPON_SNIPERRIFLE_CLASSIC || weaponId == TF_WEAPON_SNIPERRIFLE_DECAP)
    {
        result = false;
        return;
    }

    if (weaponId == TF_WEAPON_REVOLVER)
    {
        int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
        if (index == AMBASSADOR || index == FESTIVE_AMBASSADOR)
        {
            result = false;
            return;
        }
    }

    bool rapidFire = g_WeaponInfo[weaponId].UseRapidFireCrits;

    if (rapidFire && CTFWeaponBase_GetCritTime(weapon) > GetGameTime())
    {
        result = true;
        return;
    }

    int projectilesPerShot = g_WeaponInfo[weaponId].BulletsPerShot;


    if (projectilesPerShot >= 1)projectilesPerShot = RoundToCeil(float(projectilesPerShot) * TF2Attrib_HookValueFloat(1.0, "mult_bullets_per_shot", weapon));
    else projectilesPerShot = 1;

    float damage = float(g_WeaponInfo[weaponId].Damage);

    damage *= TF2Attrib_HookValueFloat(1.0, "mult_dmg", weapon);

    damage *= projectilesPerShot;

    CBaseCombatWeapon_AddToCritBucket(weapon, damage);

    bool crit = false;

    CTFWeaponBase_Set_m_bCurrentCritIsRandom(weapon, true);

    int random = 0;

    if (rapidFire)
    {
        if (tf_weapon_criticals_nopred.BoolValue)
        {
            if (GetGameTime() < CTFWeaponBase_Get_m_flLastRapidFireCritCheckTime(weapon) + 1.0)
            {
                result = false;
                return;
            }

            CTFWeaponBase_Set_m_flLastRapidFireCritCheckTime(weapon, GetGameTime());
        }
        else
        {
            if (GetGameTime() < CTFWeaponBase_Get_m_flLastCritCheckTime(weapon) + 1.0)
            {
                result = false;
				return;
            }

            CTFWeaponBase_Set_m_flLastCritCheckTime(weapon, GetGameTime());
        }

        float totalCritChance = ClampFloat(TF_DAMAGE_CRIT_CHANCE_RAPID * playerCritMult, 0.01, 0.99);
        
        float critDuration = TF_DAMAGE_CRIT_DURATION_RAPID;
        float nonCritDuration = ( critDuration / totalCritChance ) - critDuration;
        float startCritChance = 1 / nonCritDuration;

        startCritChance *= TF2Attrib_HookValueFloat(1.0, "mult_crit_chance", weapon);

        random = RandomInt(0, WEAPON_RANDOM_RANGE - 1);

        if (random < startCritChance * WEAPON_RANDOM_RANGE)
        {
            crit = true;
            critChance = startCritChance;
        }
    }
    else
    {
        critChance = TF_DAMAGE_CRIT_CHANCE * playerCritMult;

        critChance *= TF2Attrib_HookValueFloat(1.0, "mult_crit_chance", weapon);

        random = RandomInt(0, WEAPON_RANDOM_RANGE - 1);

        crit = ( random < critChance * WEAPON_RANDOM_RANGE );
    }

    CTFWeaponBase_Set_m_nCritChecks(weapon, CTFWeaponBase_Get_m_nCritChecks(weapon) + 1);

    if (crit)
    {   
        //Server isnt gonna cheat itself
        /*if (!CTFWeaponBase_CanFireRandomCriticalShot(weapon, critChance))
        {
            return;
        }*/

        if (rapidFire)
        {
            damage *= TF_DAMAGE_CRIT_DURATION_RAPID / g_WeaponInfo[weaponId].TimeFireDelay;

            int nBucketCap = tf_weapon_criticals_bucket_cap.IntValue;
            if (damage * TF_DAMAGE_CRIT_MULTIPLIER > nBucketCap)
            {
                damage = float(nBucketCap) / TF_DAMAGE_CRIT_MULTIPLIER;
            }
        }

        crit = CBaseCombatWeapon_IsAllowedToWithDrawFromCritBucket(weapon, damage);

        if (crit && rapidFire)
        {
            CTFWeaponBase_SetCritTime(weapon, GetGameTime() + TF_DAMAGE_CRIT_DURATION_RAPID);
            TF2_AddCondition(player, TFCond_FocusBuff, TF_DAMAGE_CRIT_DURATION_RAPID);
        }
    }

    if (crit && !rapidFire)
    {
        TF2_AddCondition(player, TFCond_FocusBuff, 0.3);
    }

    result = crit;
}

void DoMeleeCrits(int player, int weapon, bool &result, int weaponId)
{
    if (!player)
    {
       	result = false;
        return;
    }

    
    /*if (CTFPlayerShared_IsCritBoosted(player))
    {
        result = true;
        return;
    }*/

    //We can asuume we are critboosted here because the nocrit helper just checks for this and we run with
    //tf_weapon_criticals 0
    if (result)return;

    float playerCritMult = GetCritMultiplier(player);
    float critChance = TF_DAMAGE_CRIT_CHANCE_MELEE * playerCritMult;
    critChance *= TF2Attrib_HookValueFloat(1.0, "mult_crit_chance", weapon);

    CTFWeaponBase_Set_m_bCurrentAttackIsDuringDemoCharge(weapon, GetNextMeleeCrit(player) != MELEE_NOCRIT);

    if (GetNextMeleeCrit(player) == MELEE_CRIT)
    {
        result = true;
        return;
    }

    float damage = float(g_WeaponInfo[weaponId].Damage);
    damage *= TF2Attrib_HookValueFloat(1.0, "mult_dmg", weapon);
    CBaseCombatWeapon_AddToCritBucket(weapon, damage);

    CTFWeaponBase_Set_m_nCritChecks(weapon, CTFWeaponBase_Get_m_nCritChecks(weapon) + 1);

    int random = RandomInt(0, WEAPON_RANDOM_RANGE - 1);

    bool crit = ( random < (critChance) * WEAPON_RANDOM_RANGE);

    if (crit)
    {
        crit = CBaseCombatWeapon_IsAllowedToWithDrawFromCritBucket(weapon, damage);
    }

    if (crit)
    {
        TF2_AddCondition(player, TFCond_CritOnDamage, 0.015);
        TF2_AddCondition(player, TFCond_FocusBuff, 0.3);
    }

	result = crit;
}
