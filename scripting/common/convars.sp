ConVar tf_weapon_criticals_nopred;
ConVar tf_weapon_criticals_bucket_cap;
ConVar tf_weapon_criticals;

void FindConvars()
{
    tf_weapon_criticals_nopred = FindConVar("tf_weapon_criticals_nopred");
    tf_weapon_criticals_bucket_cap = FindConVar("tf_weapon_criticals_bucket_cap");
    tf_weapon_criticals = FindConVar("tf_weapon_criticals");
}