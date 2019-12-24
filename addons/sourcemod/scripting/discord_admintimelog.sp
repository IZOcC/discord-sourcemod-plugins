#include <sourcemod>
#include <geoip>
#include <steamworks>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "Log Admin Connections"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

ConVar webhook;
new String:g_sFilePath[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "logs/admin-connections/");
	
	if (!DirExists(g_sFilePath))
	{
		CreateDirectory(g_sFilePath, 511);
		
		if (!DirExists(g_sFilePath))
			SetFailState("Failed to create directory at /sourcemod/logs/admin-connections - Please manually create that path and reload this plugin.");
	}
	
	webhook = CreateConVar("discord_adminlog_webhook", "Degistiriniz", "Discord webhook");
	
	RegAdminCmd("admin_logging",Tmp,ADMFLAG_GENERIC);
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Post);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public Action:Tmp(client,args){
}

public OnMapStart()
{
	decl String:FormatedTime[100],
		String:MapName[100];
		
	new CurrentTime = GetTime();
	
	GetCurrentMap(MapName, 100);
	FormatTime(FormatedTime, 100, "%d_%b_%Y", CurrentTime); //name the file 'day month year'
	
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "/logs/admin-connections/%s.txt", FormatedTime);
	
	new Handle:FileHandle = OpenFile(g_sFilePath, "a+");
	
	FormatTime(FormatedTime, 100, "%X", CurrentTime);
	
	WriteFileLine(FileHandle, "");
	WriteFileLine(FileHandle, "%s - ===== Map degistiriliyor =>  %s =====", FormatedTime, MapName);
	WriteFileLine(FileHandle, "");
	
	char mesaj[256];
	Format(mesaj, sizeof(mesaj), "\n%s - ===== Map degistiriliyor =>  %s =====\n", FormatedTime, MapName);
	SendToDiscord(mesaj);
	CloseHandle(FileHandle);
}
		
public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(5.0, LogConnectionInfo, GetEventInt(event, "userid"));
}

public Action:LogConnectionInfo(Handle:timer, any:UserID)
{
	new client = GetClientOfUserId(UserID); //will return 0 if the client quits, even if a new player takes his slot
	
	if (!client)
	{}
	
	else if (IsFakeClient(client))
	{}
	
	else if (!IsClientAuthorized(client))
		CreateTimer(5.0, LogConnectionInfo, UserID);	//client's steamid isn't known yet; retry in 5 seconds
	
	else
	{
		if(CheckCommandAccess(client, "admin_joinsound", 2, false)){
			decl String:PlayerName[64],
				String:Authid[64],
				String:IPAddress[64],
				String:Country[64],
				String:FormatedTime[64];
			
			GetClientName(client, PlayerName, 64);
			GetClientAuthString(client, Authid, 64);
			GetClientIP(client, IPAddress, 64);
			FormatTime(FormatedTime, 64, "%X", GetTime())
			
			if(!GeoipCountry(IPAddress, Country, 64))
				Format(Country, 64, "Ulke Bilinmiyor");
			
			new Handle:FileHandle = OpenFile(g_sFilePath, "a+");
			
			WriteFileLine(FileHandle, "%s - <%s> <%s> <%s> oyuna girdi (%s)",
									FormatedTime,
									PlayerName,
									Authid,
									IPAddress,
									Country);

			char mesaj[256];
			Format(mesaj, sizeof(mesaj), "%s - <%s> <%s> <%s> oyuna girdi (%s)\n",
									FormatedTime,
									PlayerName,
									Authid,
									IPAddress,
									Country);
			SendToDiscord(mesaj);
			
			CloseHandle(FileHandle);
		}
	}
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
	{}
	
	else if (IsFakeClient(client))
	{}
	
	else
	{
		if(CheckCommandAccess(client, "admin_joinsound", 2, false)){
			new ConnectionTime = -1,
				Handle:FileHandle = OpenFile(g_sFilePath, "a+");
			
			decl String:PlayerName[64],
				String:Authid[64],
				String:IPAddress[64],
				String:FormatedTime[64],
				String:Reason[128];
			
			GetClientName(client, PlayerName, 64);
			GetClientIP(client, IPAddress, 64);
			FormatTime(FormatedTime, 64, "%X", GetTime());
			GetEventString(event, "reason", Reason, 128);
			
			if (!GetClientAuthString(client, Authid, 64))
				Format(Authid, 64, "Bilinmeyen STEAM ID");
			
			if (IsClientInGame(client))
				ConnectionTime = RoundToCeil(GetClientTime(client) / 60);
			
			
			WriteFileLine(FileHandle, "%s - <%s> <%s> <%s> %d dakika sonra oyundan cikti. <%s>",
									FormatedTime,
									PlayerName,
									Authid,
									IPAddress,
									ConnectionTime,
									Reason);
			
			char mesaj[256];
			
			
			
			Format(mesaj, sizeof(mesaj), "%s - <%s> <%s> <%s> %d dakika sonra oyundan cikti. <%s>",
									FormatedTime,
									PlayerName,
									Authid,
									IPAddress,
									ConnectionTime,
									Reason);
			SendToDiscord(mesaj);
			CloseHandle(FileHandle);
		}
	}
}


public void SendToDiscord(const char[] message)
{
	char Api[256]; 
	GetConVarString(webhook, Api, sizeof(Api));
	
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, Api);
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "content", message);
	SteamWorks_SetHTTPRequestHeaderValue(request, "Content-Type", "application/x-www-form-urlencoded");
	
	if(request == null || !SteamWorks_SetHTTPCallbacks(request, Callback_SendToDiscord) || !SteamWorks_SendHTTPRequest(request))
	{
		PrintToServer("[DISCORD-AdminLOG] Hata!");
		delete request;
	}else
		PrintToServer("[DISCORD-AdminLOG] Istek gonderme Basarili!");
}

public Callback_SendToDiscord(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	if(!bFailure && bRequestSuccessful)
	{
		if (eStatusCode != k_EHTTPStatusCode200OK && eStatusCode != k_EHTTPStatusCode204NoContent)
		{
			LogError("[DISCORD-AdminLOG] Hata kodu: [%i]", eStatusCode);
			SteamWorks_GetHTTPResponseBodyCallback(hRequest, Callback_Response);
		}
	}
	delete hRequest;
}

public Callback_Response(const char[] sData)
{
	PrintToServer("[DISCORD-AdminLOG] %s", sData);
}