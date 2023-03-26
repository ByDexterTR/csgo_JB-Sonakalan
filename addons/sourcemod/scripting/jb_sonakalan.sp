#include <sourcemod>
#include <cstrike>
#include <warden>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <store>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Sona Kalan Menu", 
	author = "ByDexter", 
	description = "", 
	version = "1.1", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

ConVar kredi = null, cmenu = null, krediserver = null;
bool bStore;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegConsoleCmd("sm_sonakalan", Command_Sonakalan, "");
	
	RegAdminCmd("sonakalan_flag", Command_Sonakalan, ADMFLAG_ROOT, "");
	
	HookEvent("player_death", OnClientDead);
	
	cmenu = CreateConVar("sm_sonakalan_menu", "1", "Sona kalan menü? [ 0 = Kapalı | 1 = Aktif ]", 0, true, 0.0, true, 1.0);
	kredi = CreateConVar("sm_sonakalan_kredi", "31", "Sona kalan kişi kaç kredi alsın?", 0, true, 1.0);
	krediserver = CreateConVar("sm_sonakalan_kredi_player", "9", "Sunucu kaç kişi olunca kredi alma aktif olsun? [ 0 = Özelliği kapar ]", 0, true, 0.0);
	
	AutoExecConfig(true, "Sonakalan", "ByDexter");
	
	bStore = LibraryExists("store_zephyrus");
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "store_zephyrus"))
	{
		bStore = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "store_zephyrus"))
	{
		bStore = false;
	}
}

public void OnMapStart()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	char Filename[256];
	GetPluginFilename(INVALID_HANDLE, Filename, 256);
	if (strncmp(map, "workshop/", 9, false) == 0)
	{
		if (StrContains(map, "/jb_", false) == -1 && StrContains(map, "/jail_", false) == -1 && StrContains(map, "/ba_jail", false) == -1)
			ServerCommand("sm plugins unload %s", Filename);
	}
	else if (strncmp(map, "jb_", 3, false) != 0 && strncmp(map, "jail_", 5, false) != 0 && strncmp(map, "ba_jail", 7, false) != 0)
		ServerCommand("sm plugins unload %s", Filename);
}

public Action Command_Sonakalan(int client, int args)
{
	if (!warden_iswarden(client) && !CheckCommandAccess(client, "sonakalanmenu_flag", ADMFLAG_ROOT))
	{
		ReplyToCommand(client, "[SM] Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
	
	char arg1[128];
	GetCmdArg(1, arg1, 128);
	int Hedef = FindTarget(client, arg1, true, false);
	if (Hedef <= 0)
	{
		return Plugin_Handled;
	}
	
	if (GetClientTeam(Hedef) != 2)
	{
		ReplyToCommand(client, "[SM] Sadece terörist takımını hedefleyebilirsin.");
		return Plugin_Handled;
	}
	
	bool Sonakalan[65] = { false, ... };
	Sonakalan[Hedef] = true;
	if (!IsPlayerAlive(Hedef))
	{
		CS_RespawnPlayer(Hedef);
	}
	
	int Olen = 0;
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && !Sonakalan[i])
	{
		Olen++;
		ForcePlayerSuicide(i);
	}
	
	if (Olen == 0)
	{
		for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && IsPlayerAlive(i) && Sonakalan[i])
		{
			PrintToChatAll("[SM] \x10%N\x01: sonakalan menüsü verildi.", i);
			Sonakalanmenu(i);
			break;
		}
	}
	return Plugin_Handled;
}

public Action OnClientDead(Event event, const char[] name, bool db)
{
	if (cmenu.BoolValue)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
			int Alive = 0;
			for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				Alive++;
			}
			if (Alive == 1)
			{
				for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && warden_iswarden(i))
				{
					SorMenu(i);
					break;
				}
			}
		}
	}
}

void SorMenu(int client)
{
	if (cmenu.BoolValue)
	{
		Menu menu = new Menu(Menu_Callback);
		menu.SetTitle("★ Sonakalan Menü Gönderilsin Mi ? ★\n ");
		menu.AddItem("0", "Evet");
		menu.AddItem("1", "Hayır\n ");
		menu.ExitBackButton = false;
		menu.ExitButton = false;
		menu.Display(client, 7);
	}
}

public int Menu_Callback(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		if (cmenu.BoolValue)
		{
			char item[2];
			menu.GetItem(position, item, 2);
			if (StringToInt(item) == 0)
			{
				int Alive = 0;
				for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					Alive++;
				}
				if (Alive == 1)
				{
					for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
					{
						PrintToChatAll("[SM] \x10%N\x01: sonakalan menüsü verildi.", i);
						Sonakalanmenu(i);
						break;
					}
				}
				else
				{
					PrintToChatAll("[SM] Sonakalan menü verilmedi, 1den fazla yaşayan mahkûm var");
				}
			}
			else
			{
				PrintToChatAll("[SM] \x10%N\x01: sonakalan menüyü vermedi.", client);
			}
		}
		else
		{
			PrintToChatAll("[SM] \x10%N\x01: sonakalan menüyü veremedi, menü devre dışı bırakıldı.", client);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToChatAll("[SM] \x10%N\x01: sonakalan menüyü veremedi, menü iptal oldu.", client);
	}
}

void Sonakalanmenu(int client)
{
	if (cmenu.BoolValue)
	{
		int Alive = 0;
		for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			Alive++;
		}
		if (Alive == 1)
		{
			Menu menu = new Menu(Menu2_Callback);
			menu.SetTitle("★ Sonakalan Menü★\n ");
			menu.AddItem("0", "LR");
			menu.AddItem("1", "İsyan");
			if (bStore)
			{
				if (krediserver.IntValue != 0)
				{
					int Server = 0;
					for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i))
					{
						Server++;
					}
					if (Server < krediserver.IntValue)
					{
						menu.AddItem("X", "Kredi ( Sunucu az olduğu için kapalı )", ITEMDRAW_DISABLED);
					}
					else
					{
						char format[256];
						Format(format, 256, "%d Kredi", kredi.IntValue);
						menu.AddItem("2", format);
					}
				}
				else
				{
					char format[256];
					Format(format, 256, "%d Kredi", kredi.IntValue);
					menu.AddItem("2", format);
				}
			}
			else
			{
				menu.AddItem("X", "Kredi ( Market eklentisi bulunamadı )", ITEMDRAW_DISABLED);
			}
			menu.ExitBackButton = false;
			menu.ExitButton = false;
			menu.Display(client, 7);
		}
	}
}

public int Menu2_Callback(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		if (cmenu.BoolValue)
		{
			int Alive = 0;
			for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				Alive++;
			}
			if (Alive == 1)
			{
				char item[2];
				menu.GetItem(position, item, 2);
				if (StringToInt(item) == 0)
				{
					for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && GetClientTeam(i) == 3 && !IsPlayerAlive(i))
					{
						CS_RespawnPlayer(i);
					}
					PrintToChatAll("[SM] \x10%N\x01: \x05LR \x01seçti.", client);
					FakeClientCommand(client, "sm_lr");
				}
				else if (StringToInt(item) == 1)
				{
					for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && GetClientTeam(i) == 3)
					{
						if (!IsPlayerAlive(i))
							CS_RespawnPlayer(i);
						
						DealDamage(i, 1000, client, 0, "weapon_taser");
					}
					PrintToChatAll("[SM] \x10%N\x01: \x05İsyan \x01seçti.", client);
				}
				else if (StringToInt(item) == 2)
				{
					if (bStore)
					{
						ForcePlayerSuicide(client);
						Store_SetClientCredits(client, Store_GetClientCredits(client) + kredi.IntValue);
						PrintToChatAll("[SM] \x10%N\x01: \x05Kredi\x01(\x05%d\x01) \x01seçti.", client, kredi.IntValue);
					}
					else
					{
						PrintToChatAll("[SM] \x10%N\x01: kredisi verilmedi, market eklentisi bulunamadı.", client);
					}
				}
			}
			else
			{
				PrintToChatAll("[SM] Sonakalan menü verilmedi, 1den fazla yaşayan mahkûm var.");
			}
		}
		else
		{
			PrintToChatAll("[SM] \x10%N\x01: sonakalan isteğini seçemedi, menü devre dışı bırakıldı.", client);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToChatAll("[SM] \x10%N\x01: sonakalan isteğini seçemedi, menü iptal oldu.", client);
	}
}

void DealDamage(int nClientVictim, int nDamage = 1, int nClientAttacker = 0, int nDamageType = 0, char sWeapon[] = "")
{
	if (IsValidClient(nClientVictim) && IsPlayerAlive(nClientVictim))
	{
		int EntityPointHurt = CreateEntityByName("point_hurt");
		if (EntityPointHurt != 0)
		{
			char sDamage[16];
			FormatEx(sDamage, sizeof(sDamage), "%d", nDamage);
			
			char sDamageType[32];
			FormatEx(sDamageType, sizeof(sDamageType), "%d", nDamageType);
			
			DispatchKeyValue(nClientVictim, "targetname", "war3_hurtme");
			DispatchKeyValue(EntityPointHurt, "DamageTarget", "war3_hurtme");
			DispatchKeyValue(EntityPointHurt, "Damage", sDamage);
			DispatchKeyValue(EntityPointHurt, "DamageType", sDamageType);
			if (!StrEqual(sWeapon, ""))
				DispatchKeyValue(EntityPointHurt, "classname", sWeapon);
			DispatchSpawn(EntityPointHurt);
			AcceptEntityInput(EntityPointHurt, "Hurt", (nClientAttacker != 0) ? nClientAttacker : -1);
			DispatchKeyValue(EntityPointHurt, "classname", "point_hurt");
			DispatchKeyValue(nClientVictim, "targetname", "war3_donthurtme");
			RemoveEntity(EntityPointHurt);
		}
	}
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
} 