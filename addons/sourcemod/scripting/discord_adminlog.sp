#pragma tabsize 0

#include <sourcemod>
#include <discord>
#include <basecomm>
#include <sdktools>

#define DEBUG
#define ADMIN2LOG_MSG "{\"username\":\"{BOTNAME}\", \"content\":\"[{STEAM_ID}] - [Tarih: {TARIH}] - [Saat: {SAAT}] - ``{PLAYER} - {MSG}``\"}"

ConVar g_cWebhook = null;
ConVar g_cBotName = null;

public Plugin myinfo = 
{
	name 	= "[CSGO] Discord > Admin Komut LOG",
	author 	= "Henny!",
	version = "1.0",
	url 	= "pluginadresi.com"
};

public void OnPluginStart()
{
	g_cBotName = CreateConVar("discord_adminlog_botname", "", "Chatlog botu adi. Bot adi Discordda ayarladiginiz kalsin istiyorsaniz bos birakin.");
	g_cWebhook = CreateConVar("discord_adminlog_webhook", "adminlog", "configs/discord.cfg bu dosyaki chatlog kismina webhook linkinizin sonunda /slack koyarak ekleyiniz.");
	
	AddCommandListener(OnSayCmd,"say");
	AddCommandListener(OnSayCmd,"say_team");
	
	AutoExecConfig(true, "discord_adminlog");
}

public Action OnSayCmd(int client, char[] command, int argc)
{
	new AdminId:ID = GetUserAdmin(client);
	if (ID == INVALID_ADMIN_ID)
	{
		return Plugin_Handled;
	}
	
	char sArgs[256];
	GetCmdArg(1, sArgs, sizeof(sArgs));
	
	char sName[(MAX_NAME_LENGTH + 1) * 2];
	char clientAuth[21];
	
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
	
	if (IsChatTrigger())
	{
		char sSaat[512];
		int TimeTmp = GetTime();
		FormatTime(sSaat, sizeof(sSaat), "%I:%M:%S", TimeTmp);
		
		char sTarih[512];
		int TimeTmpt = GetTime();
		FormatTime(sTarih, sizeof(sTarih), "%d/%m/%y", TimeTmpt);
		
		char sBot[512];
		GetConVarString(g_cBotName, sBot, sizeof(sBot));
		
		char sMSG[512] = ADMIN2LOG_MSG;
		ReplaceString(sMSG, sizeof(sMSG), "{BOTNAME}", sBot);
		ReplaceString(sMSG, sizeof(sMSG), "{SAAT}", sSaat);
		ReplaceString(sMSG, sizeof(sMSG), "{TARIH}", sTarih);
		ReplaceString(sMSG, sizeof(sMSG), "{MSG}", sArgs);
		ReplaceString(sMSG, sizeof(sMSG), "{PLAYER}", sName);
		ReplaceString(sMSG, sizeof(sMSG), "{STEAM_ID}", clientAuth);
		
		SendMessage(sMSG);
	}
}

SendMessage(char[] sMessage)
{
	char sWebhook[32];
	GetConVarString(g_cWebhook, sWebhook, sizeof(sWebhook));
	Discord_SendMessage(sWebhook, sMessage);
}