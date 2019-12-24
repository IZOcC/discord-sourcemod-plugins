#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <discord>


#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))
#define MAP_MSG "{\"username\":\"{BOTNAME}\", \"content\":\"{MENTION}\",\"attachments\": [{\"color\": \"{COLOR}\",\"title\": \"Sunucuya Bağlan (steam://connect/{SERVER_IP}:{SERVER_PORT})\",\"fields\": [{\"title\": \"Oynana Harita\",\"value\": \"{HARITA}\",\"short\": true},{\"title\": \"Çevrimiçi Oyuncu\",\"value\": \"{PLAYERS}\",\"short\": true}]}]}"

char g_sHostPort[6];
char g_sHostIP[16];

ConVar g_cBotName = null;
ConVar g_cColor = null;
ConVar g_cMention = null;
ConVar g_cWebhook = null;

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_cBotName = CreateConVar("discord_mapbildirimi_botname", "", "Map bildirimi botu adi. Bot adi Discordda ayarladiginiz kalsin istiyorsaniz bos birakin.");
	g_cColor = CreateConVar("discord_mapbildirimi_color", "#ff2222", "Mesajin solundaki renk.");
	g_cMention = CreateConVar("discord_mapbildirimi_mention", "@here", "Mesajdaki etiket. @here yada @everyone kullanabilirsiniz.");
	g_cWebhook = CreateConVar("discord_mapbildirimi_webhook", "mapbildirimi", "configs/discord.cfg bu dosyaki mapbildirimi kismina webhook linkinizin sonunda /slack koyarak ekleyiniz.");
	
	AutoExecConfig(true, "discord_mapbildirimi");
}

public void OnAllPluginsLoaded()
{
	UpdateIPPort();
}

void UpdateIPPort()
{
	GetConVarString(FindConVar("hostport"), g_sHostPort, sizeof(g_sHostPort));
	
	if(FindConVar("net_public_adr") != null)
		GetConVarString(FindConVar("net_public_adr"), g_sHostIP, sizeof(g_sHostIP));
	
	if(strlen(g_sHostIP) == 0 && FindConVar("ip") != null)
		GetConVarString(FindConVar("ip"), g_sHostIP, sizeof(g_sHostIP));
	
	if(strlen(g_sHostIP) == 0 && FindConVar("hostip") != null)
	{
		int ip = GetConVarInt(FindConVar("hostip"));
		FormatEx(g_sHostIP, sizeof(g_sHostIP), "%d.%d.%d.%d", (ip >> 24) & 0x000000FF, (ip >> 16) & 0x000000FF, (ip >> 8) & 0x000000FF, ip & 0x000000FF);
	}
}
public void OnMapStart()
{
    CreateTimer(15.0, bekleme, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action bekleme(Handle bekleme2)
{
	char sMention[512];
	g_cMention.GetString(sMention, sizeof(sMention));
	
	char sColor[8];
	g_cColor.GetString(sColor, sizeof(sColor));
	
	char sMap[32]
	GetCurrentMap(sMap, sizeof(sMap));
	
	int iMax = GetMaxHumanPlayers();
	
	int iPlayers = GetClientCount();
	
	//int iPlayers = 0;
	
	/*LoopValidClients(i)
	{
		iPlayers++;
	}*/
	
	char sPlayers[24];
	Format(sPlayers, sizeof(sPlayers), "%d/%d", iPlayers, iMax);
	
	char sBot[512];
	g_cBotName.GetString(sBot, sizeof(sBot));
	
	char sMSG[512] = MAP_MSG;
	
	ReplaceString(sMSG, sizeof(sMSG), "{BOTNAME}", sBot);
	ReplaceString(sMSG, sizeof(sMSG), "{COLOR}", sColor);
	ReplaceString(sMSG, sizeof(sMSG), "{SERVER_IP}", g_sHostIP);
	ReplaceString(sMSG, sizeof(sMSG), "{SERVER_PORT}", g_sHostPort);
	ReplaceString(sMSG, sizeof(sMSG), "{PLAYERS}", sPlayers);
	ReplaceString(sMSG, sizeof(sMSG), "{HARITA}", sMap);
	ReplaceString(sMSG, sizeof(sMSG), "{MENTION}", sMention);
	
	SendMessage(sMSG);
}
/*public void OnMapEnd()
{
	char sMention[512];
	g_cMention.GetString(sMention, sizeof(sMention));
	
	char sColor[8];
	g_cColor.GetString(sColor, sizeof(sColor));
	
	char sMap[32]
	GetCurrentMap(sMap, sizeof(sMap));
	
	int iMax = GetClientCount();
	
	int iPlayers = 0;
	
	LoopValidClients(i)
	{
		iPlayers++;
	}
	
	char sPlayers[24];
    Format(sPlayers, sizeof(sPlayers), "%d/%d", iPlayers, iMax);
	
	char sBot[512];
	g_cBotName.GetString(sBot, sizeof(sBot));
	
	char sMSG[512] = MAP_MSG;
	
	ReplaceString(sMSG, sizeof(sMSG), "{BOTNAME}", sBot);
	ReplaceString(sMSG, sizeof(sMSG), "{COLOR}", sColor);
	ReplaceString(sMSG, sizeof(sMSG), "{SERVER_IP}", g_sHostIP);
	ReplaceString(sMSG, sizeof(sMSG), "{SERVER_PORT}", g_sHostPort);
	ReplaceString(sMSG, sizeof(sMSG), "{PLAYERS}", sPlayers);
	ReplaceString(sMSG, sizeof(sMSG), "{HARITA}", sMap);
	ReplaceString(sMSG, sizeof(sMSG), "{MENTION}", sMention);
	
	SendMessage(sMSG);
}
*/

SendMessage(char[] sMessage)
{
	char sWebhook[32];
	g_cWebhook.GetString(sWebhook, sizeof(sWebhook));
	Discord_SendMessage(sWebhook, sMessage);
}

/*bool IsClientValid(int client)
{
    if (client > 0 && client <= MaxClients)
    {
        if(IsClientConnected(client) && !IsClientSourceTV(client))
        {
            return true;
        }
    }

    return false;
}*/