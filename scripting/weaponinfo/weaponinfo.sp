void ParseWeaponInfo()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/serverside_crits.json");

    if (!FileExists(path))SetFailState("Missing weapon info file %s", path);

    Handle file = OpenFile(path, "r");

    if (!file)SetFailState("Failed to open file in readonly %s", path);

    char buffer[32000];

    ReadFileString(file, buffer, sizeof(buffer));

    JSON_Object obj = json_decode(buffer);

    if (obj == null)SetFailState("Error json obj is null!");

    for (int i = 1; i < TF_WEAPON_ID_MAX; i++)
    {
        char entry[8];
        IntToString(i, entry, sizeof(entry));

        JSON_Object info = obj.GetObject(entry);

        if (info == null)continue;

        int damage = info.GetInt("m_nDamage");
        int bulletsPerShot = info.GetInt("m_nBulletsPerShot");
        bool useRapidFireCrits = info.GetBool("m_bUseRapidFireCrits");
        float timeFireDelay = info.GetFloat("m_flTimeFireDelay");

        g_WeaponInfo[i].Init(damage, bulletsPerShot, useRapidFireCrits, timeFireDelay);
    }

    json_cleanup_and_delete(obj);
}