#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <discord>
#include <basecomm>
#include <sdktools>

#pragma tabsize 0

#define CHATLOG_MSG "{\"username\":\"{BOTNAME}\", \"content\":\"[{STEAM_ID}] - [Tarih: {TARIH}] - [Saat: {SAAT}] - ``{PLAYER} - {MSG}``\"}"

ConVar g_cWebhook = null;
ConVar g_cBotName = null;

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
	
	g_cBotName = CreateConVar("discord_chatlog_botname", "", "Chatlog botu adi. Bot adi Discordda ayarladiginiz kalsin istiyorsaniz bos birakin.");
	g_cWebhook = CreateConVar("discord_chatlog_webhook", "chatlog", "configs/discord.cfg bu dosyaki chatlog kismina webhook linkinizin sonunda /slack koyarak ekleyiniz.");
	
	AddCommandListener(OnSayCmd,"say");
	AddCommandListener(OnSayCmd,"say_team");
	
	AutoExecConfig(true, "discord_chatlog");
}

public Action OnSayCmd(int client, char[] command, int argc)
{    
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
	
	if (!BaseComm_IsClientGagged(client))
	{
		char sSaat[512];
		int TimeTmp = GetTime();
		FormatTime(sSaat, sizeof(sSaat), "%I:%M:%S", TimeTmp);
		
		char sTarih[512];
		int TimeTmpt = GetTime();
		FormatTime(sTarih, sizeof(sTarih), "%d/%m/%y", TimeTmpt);
		
		char sBot[512];
		g_cBotName.GetString(sBot, sizeof(sBot));
		
		char sMSG[512] = CHATLOG_MSG;
		
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
	g_cWebhook.GetString(sWebhook, sizeof(sWebhook));
	Discord_SendMessage(sWebhook, sMessage);
}