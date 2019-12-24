#include <sourcemod>
#include <discord>

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#define ADMINCAGIR_MSG "{\"username\":\"{BOTNAME}\", \"content\":\"{MENTION} {MSG}\",\"attachments\": [{\"color\": \"{COLOR}\",\"title\": \"steam://connect/{SERVER_IP}:{SERVER_PORT} {REFER_ID}\",\"fields\": [{\"title\": \"Oyuncu\",\"value\": \"{PLAYER} ({STEAM_ID})\",\"short\": false}]}]}"

char sSymbols[25][1] = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"};

char g_sHostPort[6];
char g_sHostIP[16];

ConVar g_cBotName = null;
ConVar g_cAdminCagirMsg = null;
ConVar g_cColor = null;
ConVar g_cColor2 = null;
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
	CreateConVar("discord_admincagir_version", PLUGIN_VERSION, "Discord CallAdmin version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cBotName = CreateConVar("discord_admincagir_botname", "", "Admin cagir botu adi. Bot adi Discordda ayarladiginiz kalsin istiyorsaniz bos birakin.");
	g_cAdminCagirMsg = CreateConVar("discord_admincagir_msg", "Oyuncu sunucuya Admin çağırıyor.", "Bot adinin altinda gosterilecek mesaj.");
	g_cColor = CreateConVar("discord_admincagir_color", "#ff2222", "Mesajin solundaki renk.");
	g_cColor2 = CreateConVar("discord_admincagir_color2", "#22ff22", "Mesajin solundaki renk. (admin icin)");
	g_cMention = CreateConVar("discord_admincagir_mention", "@here", "Mesajdaki etiket. @here yada @everyone kullanabilirsiniz.");
	g_cWebhook = CreateConVar("discord_admincagir_webhook", "admincagir", "configs/discord.cfg bu dosyaki admincagir kismina webhook linkinizin sonunda /slack koyarak ekleyiniz.");
	
	AutoExecConfig(true, "discord_admincagir");
	
	RegConsoleCmd("sm_admincagir", Cmd_AdminCagir);
	RegConsoleCmd("sm_yetkilicagir", Cmd_AdminCagir);
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

public Action Cmd_AdminCagir(int client, int args)
{
	char clientAuth[21];
	char sName[(MAX_NAME_LENGTH + 1) * 2];
	
	if (client == 0)
	{
		strcopy(sName, sizeof(sName), "Konsol");
		strcopy(clientAuth, sizeof(clientAuth), "Konsol");
	}
	else
	{
		GetClientAuthId(client, AuthId_Steam2, clientAuth, sizeof(clientAuth));
		GetClientName(client, sName, sizeof(sName));
		Discord_EscapeString(sName, sizeof(sName));
	}
	
	char sMention[512];
	g_cMention.GetString(sMention, sizeof(sMention));
	
	char sAdminCagirMsg[512];
	g_cAdminCagirMsg.GetString(sAdminCagirMsg, sizeof(sAdminCagirMsg));
	
	Discord_EscapeString(sAdminCagirMsg, sizeof(sAdminCagirMsg));
	
	char sBot[512];
	g_cBotName.GetString(sBot, sizeof(sBot));
	
	char sColor[8];
	///g_cColor2.GetString(sColor, sizeof(sColor));
	
	if(!CheckCommandAccess(client, "sm_ban", ADMFLAG_BAN, true))
		g_cColor.GetString(sColor, sizeof(sColor));
	else g_cColor2.GetString(sColor, sizeof(sColor));
	
	char sMSG[512] = ADMINCAGIR_MSG;
	
	ReplaceString(sMSG, sizeof(sMSG), "{BOTNAME}", sBot);
	ReplaceString(sMSG, sizeof(sMSG), "{COLOR}", sColor);
	ReplaceString(sMSG, sizeof(sMSG), "{PLAYER}", sName);
	ReplaceString(sMSG, sizeof(sMSG), "{STEAM_ID}", clientAuth);
	ReplaceString(sMSG, sizeof(sMSG), "{MSG}", sAdminCagirMsg);
	ReplaceString(sMSG, sizeof(sMSG), "{MENTION}", sMention);
	
	ReplaceString(sMSG, sizeof(sMSG), "{SERVER_IP}", g_sHostIP);
	ReplaceString(sMSG, sizeof(sMSG), "{SERVER_PORT}", g_sHostPort);
	
	char sRefer[16];
	Format(sRefer, sizeof(sRefer), " # %s%s-%d%d", sSymbols[GetRandomInt(0, 25-1)], sSymbols[GetRandomInt(0, 25-1)], GetRandomInt(0, 9), GetRandomInt(0, 9));
	ReplaceString(sMSG, sizeof(sMSG), "{REFER_ID}", sRefer);
	
	SendMessage(sMSG);
	
	ReplyToCommand(client, "[SM] Admin cagriniz Discord'a gonderildi.");
	
	return Plugin_Handled;
}

SendMessage(char[] sMessage)
{
	char sWebhook[32];
	g_cWebhook.GetString(sWebhook, sizeof(sWebhook));
	Discord_SendMessage(sWebhook, sMessage);
}