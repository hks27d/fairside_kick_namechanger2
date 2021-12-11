#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

int Kick_Namechanger_Changes[MAXPLAYERS+1] = 0, Max_Changes, Logging;
char Kick_Namechanger_Reason_Converted[100];
ConVar Kick_Namechanger_Max_Changes;
ConVar Kick_Namechanger_Kick_Reason;
ConVar Kick_Namechanger_Logging;

public Plugin myinfo =
{
	name = "[FAIRSIDE.RO] NameChanger", 
	author = "HKS 27D FAIRSIDE.RO",
	version = "2.0",
	url = "www.fairside.ro"
};

public void OnPluginStart()
{
    Kick_Namechanger_Max_Changes = CreateConVar("fs_kick_namechanger_max_changes", "3", "Changes per round", _);
    Kick_Namechanger_Max_Changes.AddChangeHook(OnConvarsChanged);

    Kick_Namechanger_Kick_Reason = CreateConVar("fs_kick_namechanger_reason", "[FAIRSIDE.RO] Changing your name too many times", "Kick reason", _);
    Kick_Namechanger_Kick_Reason.AddChangeHook(OnConvarsChanged);

    Kick_Namechanger_Logging = CreateConVar("fs_kick_namechanger_logging", "1", "Enabling kick logging", _);
    Kick_Namechanger_Logging.AddChangeHook(OnConvarsChanged);
    AutoExecConfig(true, "fs_kick_namechanger");
    HookEvent("round_end", EndRound);
    HookEvent("player_changename", KickNamechanger);
}


public void OnClientConnected(int client) {
    Kick_Namechanger_Changes[client] = 0;
}

public void EndRound(Handle event, char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
            Kick_Namechanger_Changes[i] = 0;
	}
}

public void OnConfigsExecuted()
{
    Max_Changes = Kick_Namechanger_Max_Changes.IntValue;
    Kick_Namechanger_Kick_Reason.GetString(Kick_Namechanger_Reason_Converted, 100);
    Logging = Kick_Namechanger_Logging.IntValue;
}

void OnConvarsChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if(hConVar == Kick_Namechanger_Max_Changes)
	{
		Max_Changes = Kick_Namechanger_Max_Changes.IntValue;
	}
	if(hConVar == Kick_Namechanger_Kick_Reason)
	{
		Kick_Namechanger_Kick_Reason.GetString(Kick_Namechanger_Reason_Converted, 100);
	}
	if(hConVar == Kick_Namechanger_Logging)
	{
		Logging = Kick_Namechanger_Logging.IntValue;
	}
}

public void KickNamechanger(Event event, const char[] name, bool dontBroadcast)
{
    int userID = event.GetInt("userid");
    int namechanger = GetClientOfUserId(userID);

    if (IsValidClient(namechanger))
	{
        Kick_Namechanger_Changes[namechanger]++;
        if (Kick_Namechanger_Changes[namechanger] >= Max_Changes)
        {
            if (Logging == 1)
            {
                char iName[64], iSteamID[64], iIP[64];
                GetClientName(namechanger, iName, sizeof(iName));
                GetClientAuthId(namechanger, AuthId_Engine, iSteamID, sizeof(iSteamID), true);
                GetClientIP(namechanger, iIP, sizeof(iIP), true);
                LogToFileEx("addons/sourcemod/logs/fs_kick_namechanger_logs.log", "[FAIRSIDE.RO] Player %s, SteamID %s, IP %s", iName, iSteamID, iIP);
            }
            ServerCommand("sm_kick #%d %s;", userID, Kick_Namechanger_Reason_Converted);
        }
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}