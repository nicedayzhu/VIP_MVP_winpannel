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
	ShowMVPMenu(client);
	return Plugin_Handled;
}

public void ShowMVPMenu(int client)
{
	Menu menu = new Menu(ShowMVPMenuHandler, MENU_ACTIONS_ALL);
	menu.SetTitle("[CSGO资料库] VIP MVP特效菜单");
	menu.AddItem("1", "你到底会不会打CSGO");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ShowMVPMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	char sTemp[128] = "";
	switch(action)
	{
		case MenuAction_Select:
		{
			char szInfo[32];
			menu.GetItem(itemNum, szInfo, sizeof(szInfo));
			PrintToChat(client, "You pick 测试 %d", StringToInt(szInfo));
			if (StringToInt(szInfo) == 1)
			{
				// Format(sTemp, sizeof(sTemp), "<img src='file://{images}/pwa/winpanel/S7PASS_L1_MVP01.png'/>");
				Format(sTemp, sizeof(sTemp), "<p> 1323 \n\n\n\n <img src='file://{images}/pwa/winpanel/S7PASS_L1_MVP01.png'/> </p> ");
				Event newevent_message = CreateEvent("cs_win_panel_round");
				newevent_message.SetString("funfact_token", sTemp);

				for(int z = 1; z <= MaxClients; z++)
				{
					if(IsClientInGame(z) && !IsFakeClient(z))
					{
						newevent_message.FireToClient(z);
					}
				}				
				newevent_message.Cancel();
				CreateTimer(10.0, Timer_RepeatVoteDisplay);
			}
		}
		case MenuAction_End:
			delete menu;
	}
}

Action Timer_RepeatVoteDisplay(Handle timer)
{
	Event newevent_round = CreateEvent("round_start");
	for(int z = 1; z <= MaxClients; z++)
	{
      if(IsClientInGame(z) && !IsFakeClient(z))
	  {
        newevent_round.FireToClient(z);
	  }
	}
	newevent_round.Cancel();
}