static int g_offset_CTFWeaponBase_m_flCritTime;
static int g_offset_CTFWeaponBase_m_bCurrentCritIsRandom;
static int g_offset_CTFWeaponBase_m_flLastRapidFireCritCheckTime;
static int g_offset_CTFWeaponBase_m_nCritChecks;
static int g_offset_CTFWeaponBase_m_bCurrentAttackIsDuringDemoCharge;

static Handle g_SDKCBaseCombatWeapon_AddToCritBucket;
static Handle g_SDKCBaseCombatWeapon_IsAllowedToWithdrawFromBucket;
static Handle g_SDKCTFWeaponBase_GetWeaponID;

#define TF_DAMAGE_CRIT_CHANCE_RAPID 0.02
#define TF_DAMAGE_CRIT_CHANCE 0.02
#define TF_DAMAGE_CRIT_CHANCE_MELEE 0.15
#define TF_DAMAGE_CRIT_DURATION_RAPID 2.0
#define TF_DAMAGE_CRIT_MULTIPLIER 3.0

#define AMBASSADOR 61
#define FESTIVE_AMBASSADOR 1006

enum
{
	MELEE_NOCRIT = 0,
	MELEE_MINICRIT,
	MELEE_CRIT
}

void Setup_Common(GameData gameConf)
{
	g_offset_CTFWeaponBase_m_flCritTime = GameConfGetOffset(gameConf, "CTFWeaponBase::m_flCritTime");
	g_offset_CTFWeaponBase_m_bCurrentCritIsRandom = GameConfGetOffset(gameConf, "CTFWeaponBase::m_bCurrentCritIsRandom");
	g_offset_CTFWeaponBase_m_flLastRapidFireCritCheckTime = GameConfGetOffset(gameConf, "CTFWeaponBase::m_flLastRapidFireCritCheckTime");
	g_offset_CTFWeaponBase_m_nCritChecks = GameConfGetOffset(gameConf, "CTFWeaponBase::m_nCritChecks");
	g_offset_CTFWeaponBase_m_bCurrentAttackIsDuringDemoCharge = GameConfGetOffset(gameConf, "CTFWeaponBase::m_bCurrentAttackIsDuringDemoCharge");


	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "CBaseCombatWeapon::AddToCritBucket()");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_SDKCBaseCombatWeapon_AddToCritBucket = EndPrepSDKCall();
	if (!g_SDKCBaseCombatWeapon_AddToCritBucket)SetFailState("Could not prep sdkcall CBaseCombatWeapon::AddToCritBucket, signature off?");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "CBaseCombatWeapon::IsAllowedToWithdrawFromCritBucket()");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_SDKCBaseCombatWeapon_IsAllowedToWithdrawFromBucket = EndPrepSDKCall();
	if (!g_SDKCBaseCombatWeapon_IsAllowedToWithdrawFromBucket)SetFailState("Could not prep sdkcall CBaseCombatWeapon::IsAllowedToWithDrawFromCritBucket(), signature off?");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Virtual, "CTFWeaponBase::GetWeaponID()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCTFWeaponBase_GetWeaponID = EndPrepSDKCall();
	if (!g_SDKCTFWeaponBase_GetWeaponID)SetFailState("Could not prep sdkcall CTFWeaponBase::GetWeaponID(), wrong offset?");
}

void CTFWeaponBase_SetCritTime(int weapon, float time)
{
    SetEntDataFloat(weapon, g_offset_CTFWeaponBase_m_flCritTime, time);
}

float CTFWeaponBase_GetCritTime(int weapon)
{
	return GetEntDataFloat(weapon, g_offset_CTFWeaponBase_m_flCritTime);
}

void CTFWeaponBase_Set_m_bCurrentCritIsRandom(int weapon, bool value)
{
	SetEntData(weapon, g_offset_CTFWeaponBase_m_bCurrentCritIsRandom, value);
}

stock bool CTFWeaponBase_Get_m_bCurrentCritIsRandom(int weapon)
{
	return view_as<bool>(GetEntData(weapon, g_offset_CTFWeaponBase_m_bCurrentCritIsRandom));
}

void CTFWeaponBase_Set_m_flLastRapidFireCritCheckTime(int weapon, float time)
{
	SetEntDataFloat(weapon, g_offset_CTFWeaponBase_m_flLastRapidFireCritCheckTime, time);
}

float CTFWeaponBase_Get_m_flLastRapidFireCritCheckTime(int weapon)
{
	return GetEntDataFloat(weapon, g_offset_CTFWeaponBase_m_flLastRapidFireCritCheckTime);
}

void CTFWeaponBase_Set_m_nCritChecks(int weapon, int amount)
{
	SetEntData(weapon, g_offset_CTFWeaponBase_m_nCritChecks, amount);
}

int CTFWeaponBase_Get_m_nCritChecks(int weapon)
{
	return GetEntData(weapon, g_offset_CTFWeaponBase_m_nCritChecks);
}

stock int CTFWeaponBase_Get_m_bCurrentAttackIsDuringDemoCharge(int weapon)
{
	return GetEntData(weapon, g_offset_CTFWeaponBase_m_bCurrentAttackIsDuringDemoCharge);
}

void CTFWeaponBase_Set_m_bCurrentAttackIsDuringDemoCharge(int weapon, bool value)
{
	SetEntData(weapon, g_offset_CTFWeaponBase_m_bCurrentAttackIsDuringDemoCharge, value);
}

int CTFWeaponBase_GetWeaponID(int weapon)
{
	return SDKCall(g_SDKCTFWeaponBase_GetWeaponID, weapon);
}

void CBaseCombatWeapon_AddToCritBucket(int weapon, float amount)
{
	SDKCall(g_SDKCBaseCombatWeapon_AddToCritBucket, weapon, amount);
}

bool CBaseCombatWeapon_IsAllowedToWithDrawFromCritBucket(int weapon, float damage)
{
	return SDKCall(g_SDKCBaseCombatWeapon_IsAllowedToWithdrawFromBucket, weapon, damage);
}

float GetCritMultiplier(int client)
{
	return RemapValClamped(float(GetEntProp(client, Prop_Send, "m_iCritMult")), float(0), float(255), 1.0, 4.0);
}

int GetNextMeleeCrit(int client)
{
	return GetEntProp(client, Prop_Send, "m_iNextMeleeCrit");
}

float RemapValClamped( float val, float A, float B, float C, float D)
{
	if ( A == B )
		return val >= B ? D : C;
	float cVal = (val - A) / (B - A);
	cVal = ClampFloat( cVal, 0.0, 1.0 );

	return C + (D - C) * cVal;
}

float ClampFloat(float value, float min, float max) 
{
	if (value > max) 
	{
		return max;
	} 
	else if (value < min) 
	{
		return min;
	}
	return value;
}
