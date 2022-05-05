#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

#define NUM_OF_MVP_STYLE    2 
char szPanelInfo[256] = "";
char szMvpFileName[NUM_OF_MVP_STYLE][128] = {
    "pwa/winpanel/S7PASS_L1_MVP01.png",
    "pwa/winpanel/S7PASS_L2_MVP01.png"
    };
char szFormatedMvpName[128] = "";
int iLastShowWinPanel, iCurrentShowWinPanle;
enum eMvpIndex {
    STYLE01,
    STYLE02,
};

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
    iLastShowWinPanel = -1;
    iCurrentShowWinPanle =-1;

    Show_MVPMenu(client);
}

public void Show_MVPMenu(int client)
{
    Menu menu = new Menu(ShowMVPMenuHandler, MENU_ACTIONS_ALL);
    menu.SetTitle("[CSGO资料库] VIP MVP特效菜单");
    menu.AddItem("1", "你到底会不会打CSGO");
    menu.AddItem("2", "寄");
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int ShowMVPMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char szInfo[16];
            char szMvpName[128];
            GetClientName(client, szMvpName, sizeof(szMvpName));
            FormatEx(szFormatedMvpName, sizeof(szFormatedMvpName), "<font size='35' color='#ffa500'>%s</font>", szMvpName);

            menu.GetItem(itemNum, szInfo, sizeof(szInfo));
            iCurrentShowWinPanle = StringToInt(szInfo);
            PrintToServer("iCurrentShowWinPanle = %d", iCurrentShowWinPanle);
            switch(StringToInt(szInfo)-1) // the first itemNum = 1
            {
                case STYLE01:
                {
                    Fill_Info_Winpanel(szPanelInfo, sizeof(szPanelInfo), STYLE01);
                    Show_Winpanel(szPanelInfo);
                    //close the winpanel 5sec later
                    CreateTimer(1.0, Timer_StopMvpPaneleDisplay, _, TIMER_REPEAT);
                    // CreateTimer(5.0, Timer_StopMvpPaneleDisplay2);

                }
                case STYLE02:
                {
                    Fill_Info_Winpanel(szPanelInfo, sizeof(szPanelInfo), STYLE02);
                    Show_Winpanel(szPanelInfo);
                    //close the winpanel 5sec later
                    CreateTimer(1.0, Timer_StopMvpPaneleDisplay, _, TIMER_REPEAT);
                    // CreateTimer(5.0, Timer_StopMvpPaneleDisplay2);
                }
            }
            iLastShowWinPanel = iCurrentShowWinPanle;
        }
        case MenuAction_End:
            delete menu;
    }
}

public void Fill_Info_Winpanel(char[] info, int size, int style)
{
    if(iLastShowWinPanel !=iCurrentShowWinPanle) 
    {
        PrintToServer("iLastShowWinPanel = %d, iCurrentShowWinPanle = %d", iLastShowWinPanel, iCurrentShowWinPanle);
        FormatEx(info, size, "<p> MVP玩家 %s </p>\n<img src='file://{images}/%s' height='117' height='514' /><br><br>", 
            szFormatedMvpName, szMvpFileName[style]);
    } 
    else 
    {
        PrintToServer("iLastShowWinPanel = %d, iCurrentShowWinPanle = %d", iLastShowWinPanel, iCurrentShowWinPanle);
        FormatEx(info, size, "<p> MVP玩家 %s </p>\n<img src='file://{images}/%s' height='117' height='514' />", 
            szFormatedMvpName, szMvpFileName[style]);
    }
    return;
}

public void Show_Winpanel(char[] info)
{
    Event newevent_message = CreateEvent("cs_win_panel_round");
    newevent_message.SetString("funfact_token", info);
    for(int z = 1; z <= MaxClients; z++)
    {
        if(IsClientInGame(z) && !IsFakeClient(z))
        {
            newevent_message.FireToClient(z);
        }
    }
    newevent_message.Cancel();
}

public Action Timer_StopMvpPaneleDisplay(Handle timer)
{
    // Create a global variable visible only in the local scope (this function).
    static int numPrinted = 0;
    if (numPrinted >= 5) 
    {
        numPrinted = 0;
        //send fake cs_win_panel_round event to close the WinPanel
        Event newevent_clear = CreateEvent("cs_win_panel_round");
        for(int z = 1; z <= MaxClients; z++)
        {
            if(IsClientInGame(z) && !IsFakeClient(z))
            {
                newevent_clear.FireToClient(z);
            }
        }
        newevent_clear.Cancel();
        return Plugin_Stop;
    }
    PrintToServer("numPrinted = %d", numPrinted);
    numPrinted++;
    return Plugin_Continue;
}
