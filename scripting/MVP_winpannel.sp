#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <clientprefs>
#pragma newdecls required
#pragma semicolon 1

#define NUM_OF_MVP_STYLE    5 
char szPanelInfo[256] = "";
char szMvpFileName[NUM_OF_MVP_STYLE][128] = {
    "bbscsgocn/winpanel/mvp_1.png",
    "bbscsgocn/winpanel/mvp_2.png",
    "bbscsgocn/winpanel/mvp_3.png",
    "bbscsgocn/winpanel/mvp_4.png",
    "bbscsgocn/winpanel/mvp_5.png",
    };
char szFormatedMvpName[128] = "";
char szMVPName[128];
int iMVPClient;
int iCurMVPClient = -1;
int iLastMVPClient = -1;
int iLastShowWinPanel = -1;
int iCurrentShowWinPanle = -1;
enum eMvpIndex {
    STYLE01,
    STYLE02,
    STYLE03,
    STYLE04,
    STYLE05,
};

// for cookies
Handle g_hMVPanelCookie;
Handle g_hMVPStyleCookie;
bool g_bIsMVPanelEnabled[MAXPLAYERS + 1];           //store cookie data for each client
char szPlayerChoosedMVPStyle[MAXPLAYERS + 1][128];  //store cookie data for each client

// Check If MVP Winpanel has shown ever? 
// If not: fix pic size with <br>, 
// Otherwise: set pic to the normal size
bool g_bMVPanelHasShown[MAXPLAYERS + 1] = {false};

public Plugin myinfo =
{
    name = "MVP_winpannel",
    author = "SenioRchu",
    description = "Special MVP winpannel for Players ",
    version = "1.1.0",
    url = "https://steamcommunity.com/id/niceday_zhu/"
};


public void OnPluginStart()
{
    g_hMVPanelCookie = RegClientCookie("mvp_panel_enable", "save the statement of mvp_panel_enable ", CookieAccess_Protected);
    g_hMVPStyleCookie = RegClientCookie("mvp_panel_style", "save the MVP style choosed by player", CookieAccess_Protected);
    RegConsoleCmd("sm_mvpanel", Command_MVP);
    RegConsoleCmd("sm_mvpset", Command_set_mvpanel);
    for(int i = 1; i <= MaxClients; i++)
    {
        EnableMVPanelIni(i);
    }
    
    //EVENTS
    HookEvent("round_start", OnRoundStart);
    HookEvent("round_end", OnRoundEnd);
    HookEvent("round_mvp", MVP_Verify);
    HookEvent("cs_win_panel_round", WinPanel_Modify, EventHookMode_Pre);
}

public void OnMapStart()
{
	char sBuf[PLATFORM_MAX_PATH];
	
	for(int i = 0; i < 5; i++)
	{
		Format(sBuf, sizeof sBuf, "materials/panorama/images/bbscsgocn/winpanel/mvp_%i.png", 1 + i);
		
		AddFileToDownloadsTable(sBuf);
	}
}

public void OnClientPostAdminCheck(int client)
{
    EnableMVPanelIni(client);
}

public void OnClientCookiesCached(int client)
{
    EnableMVPanelIni(client);
}

public Action Command_MVP(int client, int args)
{
    Show_MVPMenu(client);
}

public void OnRoundStart(Handle hEvent, const char[] sName, bool bDontBroadcast)
{
    PrintToServer("hook round_start");
    if (IsWarmup())
    {
        return;
    }
}

public void OnRoundEnd(Handle hEvent, const char[] sName, bool bDontBroadcast)
{
    // char szCurInfo[128];
    PrintToServer("hook round_end");
    if (IsWarmup())
    {
        return;
    }
    // GetEventString(hEvent, "message", szCurInfo, sizeof(szCurInfo));
    // PrintToChatAll(szCurInfo);
}

public Action Command_set_mvpanel(int client, int args) 
{
    if(g_bIsMVPanelEnabled[client])
    {

        // PrintToChat(client, " ★ \x02client = %d", client);
        PrintToChat(client, " ★ \x02MVP 正在关闭特效"); // Disable the custom winpanel
        g_bIsMVPanelEnabled[client] = false;
        szPlayerChoosedMVPStyle[client] = "";
        SetClientCookie(client, g_hMVPanelCookie, "0");
        SetClientCookie(client, g_hMVPStyleCookie, "");
        PrintToChat(client, " ★ \x02MVP 特效已关闭"); //custom winpanel has been disabled
    }
    else
    {
        if(StrEqual(szPlayerChoosedMVPStyle[client], ""))
        {
            // PrintToChat(client, " ★ \x02client = %d", client);
            PrintToChat(client, "★ \x04MVP 特效开启失败 请先运行 !mvp 选择你想要的特效"); //tell the player to use !mvp firstly
            g_bIsMVPanelEnabled[client] = false;
            SetClientCookie(client, g_hMVPanelCookie, "0");
        } 
        else 
        {
            // PrintToChat(client, " ★ \x02client = %d", client);
            PrintToChat(client, " ★ \x04MVP 正在开启特效");    //Enable custom winpanle
            g_bIsMVPanelEnabled[client] = true;
            SetClientCookie(client, g_hMVPanelCookie, "1");
            SetClientCookie(client, g_hMVPStyleCookie, szPlayerChoosedMVPStyle[client]);
            PrintToChat(client, " ★ \x04MVP 特效已开启");
        }

    }
}

void EnableMVPanelIni(int client)
{
    if(AreClientCookiesCached(client) && IsClientValid(client))
    {
        g_bIsMVPanelEnabled[client] = false;
        g_bMVPanelHasShown[client] = false;
        char buffer_enableed[64];
        char buffer_mvpstyle[128];
        GetClientCookie(client, g_hMVPanelCookie, buffer_enableed, sizeof(buffer_enableed));
        PrintToServer("GET g_hMVPanelCookie buffer_enableed = %s", buffer_enableed);
        GetClientCookie(client, g_hMVPStyleCookie, buffer_mvpstyle, sizeof(buffer_mvpstyle));
        PrintToServer("GET g_hMVPanelCookie buffer_mvpstyle = %s", buffer_mvpstyle);
        if(StrEqual(buffer_enableed,"1"))
        {
            g_bIsMVPanelEnabled[client] = true;
            szPlayerChoosedMVPStyle[client] = buffer_mvpstyle;
            PrintToServer("szPlayerChoosedMVPStyle[client:%d] = %s", client, szPlayerChoosedMVPStyle[client]);
        }
        else
        {
            g_bIsMVPanelEnabled[client] = false;
        }

    }
}

public Action MVP_Verify(Event event, const char[] name, bool dontBroadcast)
{
    // PrintToServer("hook round_mvp");
    if (IsWarmup())
    {
        return;
    }
    
    iMVPClient = GetClientOfUserId(GetEventInt(event, "userid"));
    iCurMVPClient = iMVPClient;
    GetClientName(iMVPClient, szMVPName, sizeof(szMVPName));
    // check whether the Current MVPClient is the same as the preivous one
    // if not, the previous MVP winpanel's pic size must be resized in order to make winpanel looks normal
    if (iLastMVPClient != iMVPClient)
    {
        g_bMVPanelHasShown[iLastMVPClient] =false;
        PrintToServer("iLastMVPClient = %d, iMVPClient = %d", iLastMVPClient, iMVPClient);
        PrintToServer("g_bMVPanelHasShown[%d] = %d", iCurMVPClient, g_bMVPanelHasShown[iCurMVPClient]);
    }
    // PrintToChatAll("MVP 玩家 %s", szMVPName);    
}

public Action WinPanel_Modify(Event event, const char[] name, bool dontBroadcast)
{
    char szCurInfo[256];
    // Get event string before event has been Fired
    GetEventString(event, "funfact_token", szCurInfo, sizeof(szCurInfo));
    // Check custom MVP Winpanel is enabled
    PrintToServer("g_bIsMVPanelEnabled[iMVPClient:%d] = %d", iMVPClient, g_bIsMVPanelEnabled[iMVPClient]);
    if (!g_bIsMVPanelEnabled[iMVPClient])
    {
        iLastMVPClient = iMVPClient;
        PrintToServer("iLastMVPClient = %d", iLastMVPClient);
        return Plugin_Continue;
    } 
    else 
    {
        PrintToServer("iCurMVPClient = %d", iCurMVPClient);
        PrintToServer("iLastMVPClient = %d", iLastMVPClient);
        PrintToServer("g_bMVPanelHasShown[iMVPClient:%d]= %d", iMVPClient, g_bMVPanelHasShown[iMVPClient]);
        if (!g_bMVPanelHasShown[iMVPClient])
        {
            Format(szCurInfo, sizeof(szCurInfo), 
                "<font size='35' color='#ffa500'>%s</font> 成为了最有价值的MVP<br>\
                <img src='file://{images}/%s' height='117' height='514' /><br><br><br>", 
                szMVPName, 
                szPlayerChoosedMVPStyle[iMVPClient]);
            g_bMVPanelHasShown[iMVPClient] = true;    
        }
        // if the currentMVP is not the previous one, fix pic size with <br>
        else if(iCurMVPClient != iLastMVPClient)
        {
            Format(szCurInfo, sizeof(szCurInfo), 
                "<font size='35' color='#ffa500'>%s</font> 成为了最有价值的MVP<br>\
                <img src='file://{images}/%s' height='117' height='514' />", 
                szMVPName, 
                szPlayerChoosedMVPStyle[iMVPClient]);
            // g_bMVPanelHasShown[iMVPClient] = true;
        }
        else 
        {
            // if custom winpanel has shown before
            Format(szCurInfo, sizeof(szCurInfo), 
                "<font size='35' color='#ffa500'>%s</font> 成为了最有价值的MVP<br>\
                <img src='file://{images}/%s' height='117' height='514' />", 
                szMVPName, 
            szPlayerChoosedMVPStyle[iMVPClient]);
        }
        // set the Formated winpanel info for the event
        event.SetString("funfact_token", szCurInfo);
        iLastMVPClient = iMVPClient;
        return Plugin_Continue;
    }
}

stock bool IsWarmup()
{
    return GameRules_GetProp("m_bWarmupPeriod") == 1;
}

public void Show_MVPMenu(int client)
{
    Menu menu = new Menu(ShowMVPMenuHandler, MENU_ACTIONS_ALL);
    menu.SetTitle("[CSGO资料库] MVP特效菜单");
    menu.AddItem("1", "MVP特效一");
    menu.AddItem("2", "MVP特效二");
    menu.AddItem("3", "MVP特效三");
    menu.AddItem("4", "MVP特效四");
    menu.AddItem("5", "MVP特效五");
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
            // enable MVPwinpanel
            g_bIsMVPanelEnabled[client] = true;
            SetClientCookie(client, g_hMVPanelCookie, "1");
            
            GetClientName(client, szMvpName, sizeof(szMvpName));
            FormatEx(szFormatedMvpName, sizeof(szFormatedMvpName), "<font size='35' color='#ffa500'>%s</font>", szMvpName);

            menu.GetItem(itemNum, szInfo, sizeof(szInfo));
            iCurrentShowWinPanle = StringToInt(szInfo);
            PrintToServer("iCurrentShowWinPanle = %d", iCurrentShowWinPanle);
            switch(StringToInt(szInfo)-1) // the first itemNum = 1
            {
                case STYLE01:
                {
                    Format(szPlayerChoosedMVPStyle[client], sizeof(szPlayerChoosedMVPStyle), szMvpFileName[STYLE01]);
                    SetClientCookie(client, g_hMVPStyleCookie, szPlayerChoosedMVPStyle[client]);

                    Fill_Info_Winpanel(szPanelInfo, sizeof(szPanelInfo), STYLE01);
                    Show_Winpanel_For_Preview(szPanelInfo, client);
                    //close the winpanel 5sec later
                    CreateTimer(1.0, Timer_StopMvpPaneleDisplay, _, TIMER_REPEAT);

                }
                case STYLE02:
                {
                    Format(szPlayerChoosedMVPStyle[client], sizeof(szPlayerChoosedMVPStyle), szMvpFileName[STYLE02]);
                    SetClientCookie(client, g_hMVPStyleCookie, szPlayerChoosedMVPStyle[client]);
                    Fill_Info_Winpanel(szPanelInfo, sizeof(szPanelInfo), STYLE02);
                    Show_Winpanel_For_Preview(szPanelInfo, client);
                    //close the winpanel 5sec later
                    CreateTimer(1.0, Timer_StopMvpPaneleDisplay, _, TIMER_REPEAT);
                }
                case STYLE03:
                {
                    Format(szPlayerChoosedMVPStyle[client], sizeof(szPlayerChoosedMVPStyle), szMvpFileName[STYLE03]);
                    SetClientCookie(client, g_hMVPStyleCookie, szPlayerChoosedMVPStyle[client]);
                    Fill_Info_Winpanel(szPanelInfo, sizeof(szPanelInfo), STYLE03);
                    Show_Winpanel_For_Preview(szPanelInfo, client);
                    //close the winpanel 5sec later
                    CreateTimer(1.0, Timer_StopMvpPaneleDisplay, _, TIMER_REPEAT);
                }
                case STYLE04:
                {
                    Format(szPlayerChoosedMVPStyle[client], sizeof(szPlayerChoosedMVPStyle), szMvpFileName[STYLE04]);
                    SetClientCookie(client, g_hMVPStyleCookie, szPlayerChoosedMVPStyle[client]);
                    Fill_Info_Winpanel(szPanelInfo, sizeof(szPanelInfo), STYLE04);
                    Show_Winpanel_For_Preview(szPanelInfo, client);
                    //close the winpanel 5sec later
                    CreateTimer(1.0, Timer_StopMvpPaneleDisplay, _, TIMER_REPEAT);
                }
                case STYLE05:
                {
                    Format(szPlayerChoosedMVPStyle[client], sizeof(szPlayerChoosedMVPStyle), szMvpFileName[STYLE05]);
                    SetClientCookie(client, g_hMVPStyleCookie, szPlayerChoosedMVPStyle[client]);
                    Fill_Info_Winpanel(szPanelInfo, sizeof(szPanelInfo), STYLE05);
                    Show_Winpanel_For_Preview(szPanelInfo, client);
                    //close the winpanel 5sec later
                    CreateTimer(1.0, Timer_StopMvpPaneleDisplay, _, TIMER_REPEAT);
                }
            }
            iLastShowWinPanel = iCurrentShowWinPanle;
        }
        case MenuAction_End:
            delete menu;
    }
}

// TODO
public void ParseAndShowWinpanel(int style)
{

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

public void Show_Winpanel_For_Preview(char[] info, int client)
{
    Event newevent_message = CreateEvent("cs_win_panel_round");
    newevent_message.SetString("funfact_token", info);
    if(IsClientInGame(client) && !IsFakeClient(client))
    {
        newevent_message.FireToClient(client);
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

bool IsClientValid(int client)
{
    return (0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client);
}

// void WriteLogLine(const char[] log, any...)
// {
// 	char szLogLine[1024];
// 	VFormat(szLogLine, sizeof(szLogLine), log, 2);
	
// 	static char szPath[128];
// 	if (strlen(szPath) < 1)
// 	{
// 		char szFileName[64];
// 		GetPluginFilename(INVALID_HANDLE, szFileName, sizeof(szFileName));
// 		ReplaceString(szFileName, sizeof(szFileName), ".smx", "");
		
// 		FormatTime(szPath, sizeof(szPath), "%Y%m%d", GetTime());
// 		BuildPath(Path_SM, szPath, sizeof(szPath), "logs/%s_%s.log", szFileName, szPath);
// 	}
	
// 	LogToFile(szPath, szLogLine);
// }