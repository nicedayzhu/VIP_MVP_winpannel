#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "VIP_MVP_winpannel",
	author = "seniorchu",
	description = "Special MVP winpannel for VIP ",
	version = "1.0.0",
	url = "https://github.com/"
};


public void OnPluginStart()
{
	RegConsoleCmd("sm_mvp", Command_MVP); //bind F3
	//EVENTS
	// HookEvent("round_start", OnRoundStart);
	// HookEvent("round_end", OnRoundEnd);
	// HookEvent("round_mvp", MVP_Verify, EventHookMode_Pre);
}

public Action Command_MVP(int client, int args)
{
	Show_MVPMenu(client);
	return Plugin_Handled;
}

public void Show_MVPMenu(int client)
{
	Menu menu = new Menu(ShowMVPMenuHandler, MENU_ACTIONS_ALL);
	menu.SetTitle("[CSGO资料库] VIP MVP特效菜单");
	menu.AddItem("1", "你到底会不会打CSGO");
	menu.ExitButton = true;
	menu.Display(client, 10);
}

public int ShowMVPMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	char szPanelInfo[256] = "";
	char szMvpFileName[128] = "pwa/winpanel/S7PASS_L1_MVP01.png";
	switch(action)
	{
		case MenuAction_Select:
		{
			char szInfo[16];
			char szMvpName[128];
			char szFormatedMvpName[128];
			GetClientName(client, szMvpName, sizeof(szMvpName));
			FormatEx(szFormatedMvpName, sizeof(szFormatedMvpName), "<font size='35' color='#ffa500'>%s</font>", szMvpName);

			menu.GetItem(itemNum, szInfo, sizeof(szInfo));
			if (StringToInt(szInfo) == 1)
			{
				FormatEx(szPanelInfo, sizeof(szPanelInfo), "<p> MVP玩家 %s </p><img src='file://{images}/%s'/>", szFormatedMvpName, szMvpFileName);
				Event newevent_message = CreateEvent("cs_win_panel_round");
				newevent_message.SetString("funfact_token", szPanelInfo);
				for(int z = 1; z <= MaxClients; z++)
				{
					if(IsClientInGame(z) && !IsFakeClient(z))
					{
						newevent_message.FireToClient(z);
					}
				}
				newevent_message.Cancel();				
				//close the winpanel 5sec later
				CreateTimer(5.0, Timer_StopMvpPaneleDisplay);
			}
			Show_MVPMenu(client);
		}
		case MenuAction_End:
			delete menu;
	}
}

public Action Timer_StopMvpPaneleDisplay(Handle timer)
{
	//send fake cs_win_panel_round event to close the WinPanel
	Event newevent_round = CreateEvent("cs_win_panel_round");
	for(int z = 1; z <= MaxClients; z++)
	{
      if(IsClientInGame(z) && !IsFakeClient(z))
	  {
        newevent_round.FireToClient(z);
	  }
	}
	newevent_round.Cancel();
	return Plugin_Handled;
}