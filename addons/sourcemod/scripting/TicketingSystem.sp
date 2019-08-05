#define PLUGIN_AUTHOR "Diam0ndz / Proobs"
#define PLUGIN_VERSION "0.1"

#include <sourcemod>
#include <TicketingSystem>

#pragma newdecls required
#pragma semicolon 1

DeviceInfo DInfo[MAX_INFO_LENGTH]; 
TicketInfo TInfo[MAX_INFO_LENGTH];

Database g_Database = null;

int g_iTotalDevices = -1;
int g_iTotalTickets = -1;

bool g_bListeningForDeviceName[MAXPLAYERS + 1] =  { false, ... };

public Plugin myinfo = 
{
	name = "Ticketing System",
	author = PLUGIN_AUTHOR,
	description = "Ticketing system made for the r/ProgrammerHumor Hackathon",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/diam0ndz / https://steamcommunity.com/id/proobably"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_ticketing", Command_OpenTicketingMenu, "Opens ticketing menu");
	RegConsoleCmd("sm_ticket", Command_OpenTicketingMenu, "Opens ticketing menu");
	
	ConnectToDatabase();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(!g_bListeningForDeviceName[client])
		return Plugin_Continue;

	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));

	char authId[32];
	GetClientAuthId(client, AuthId_SteamID64, authId, sizeof(authId));

	g_iTotalDevices += 1;

	DInfo[g_iTotalDevices].iDeviceId = g_iTotalDevices;
	Format(DInfo[g_iTotalDevices].szDeviceName, sizeof(DeviceInfo::szDeviceName), "%s", sArgs); 
	Format(DInfo[g_iTotalDevices].szOwnerName, sizeof(DeviceInfo::szOwnerName), "%s", clientName);
	Format(DInfo[g_iTotalDevices].szOwnerId, sizeof(DeviceInfo::szOwnerId), "%s", authId);
	
	char szQuery[4096];
	Format(szQuery, sizeof(szQuery), 	"INSERT INTO `devices` \
										(id, name, owner_name, owner_id, ticket_opened) VALUES \
										(%d, '%s', '%s', '%s', '0')",
										g_iTotalDevices, sArgs, clientName, authId);
										
	g_Database.Query(SQLCallback_Void, szQuery);
		
	Menu menu = new Menu(TicketingMenuHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("Device #%d", g_iTotalDevices);
	char mId[10];
	char mName[32];
	char mCName[64];
	char mCId[32];
	char mTick[10];
	
	Format(mId, sizeof(mId), "ID: %d", g_iTotalDevices);
	Format(mName, sizeof(mName), "Name: %s", sArgs);
	Format(mCName, sizeof(mCName), "Owner: %s", clientName);
	Format(mCId, sizeof(mCId), "Owner ID: %s", authId);
	Format(mTick, sizeof(mTick), "Tickets: %d", DInfo[g_iTotalDevices].iDeviceTicketOpened);
	
	menu.AddItem("id", mId, ITEMDRAW_DISABLED);
	menu.AddItem("name", mName, ITEMDRAW_DISABLED);
	menu.AddItem("owner", mCName, ITEMDRAW_DISABLED);
	menu.AddItem("ownerid", mCId, ITEMDRAW_DISABLED);
	menu.AddItem("ticket", mTick, ITEMDRAW_DISABLED);
	menu.Display(20, client);

	g_bListeningForDeviceName[client] = false;
	PrintToChat(client, " \x0A[\x0CTICKETING\x0A] \x0E Successfully added new device, \x0F%s\x0E.", mId);

	return Plugin_Handled;
}

public void ListDevice(int client, int deviceId)
{
	Menu menu = new Menu(TicketingMenuHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("Device #%d", g_iTotalDevices);
	char mId[10];
	char mName[32];
	char mCName[64];
	char mCId[32];
	char mTick[10];
	
	Format(mId, sizeof(mId), "ID: %d", DInfo[deviceId].iDeviceId);
	Format(mName, sizeof(mName), "Name: %s", DInfo[deviceId].szDeviceName);
	Format(mCName, sizeof(mCName), "Owner: %s", DInfo[deviceId].szOwnerName);
	Format(mCId, sizeof(mCId), "Owner ID: %s", DInfo[deviceId].szOwnerId);
	Format(mTick, sizeof(mTick), "Tickets: %d", DInfo[deviceId].iDeviceTicketOpened);
	
	menu.AddItem("id", mId, ITEMDRAW_DISABLED);
	menu.AddItem("name", mName, ITEMDRAW_DISABLED);
	menu.AddItem("owner", mCName, ITEMDRAW_DISABLED);
	menu.AddItem("ownerid", mCId, ITEMDRAW_DISABLED);
	menu.AddItem("ticket", mTick, ITEMDRAW_DISABLED);
	menu.Display(20, client);
}

public Action Command_OpenTicketingMenu(int client, int args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
		
	Menu menu = new Menu(TicketingMenuHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("Ticketing & Device System");
	menu.AddItem("devices", "Devices");
	menu.AddItem("tickets", "Tickets");
	menu.Display(20, client);
	return Plugin_Handled;
}

public int TicketingMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(StrEqual(info, "devices"))
			{
				DisplayDevices(param1);
			}
			else if(StrEqual(info, "tickets"))
			{
				DisplayTickets(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void DisplayDevices(int client)
{
	Menu menu = new Menu(DevicesMenuHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("Devices");
	menu.AddItem("add", "Add a device");
	for (int i = 0; i < g_iTotalDevices; i++)
	{
		char szId[10];
		IntToString(i, szId, sizeof(szId));
		char szDisplay[32];
		Format(szDisplay, sizeof(szDisplay), "Device #%s", szId);
		menu.AddItem(szId, szDisplay);
	}
	menu.Display(20, client);
}

public int DevicesMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(StrEqual(info, "add"))
			{
				g_bListeningForDeviceName[param1] = true;
				PrintToChat(param1, " \x0A[\x0CTICKETING\x0A] \x0E Type the name of the device to be added in chat. Type 'cancel' to cancel.");
			}
			else
			{
				for (int i = 0; i < g_iTotalDevices; i++)
				{
					char szId[10];
					IntToString(i, szId, sizeof(szId));
					if(StrEqual(info, szId))
					{
						ListDevice(param1, i);
					}
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void DisplayTickets(int client)
{
	Menu menu = new Menu(TicketsMenuHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("Tickets");
	menu.AddItem("add", "Add a ticket");
	for (int i = 0; i < g_iTotalTickets; i++)
	{
		char szId[10];
		IntToString(i, szId, sizeof(szId));
		char szDisplay[32];
		Format(szDisplay, sizeof(szDisplay), "Ticket #%s", szId);
		menu.AddItem(szId, szDisplay);
	}
	menu.Display(20, client);
}

public int TicketsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(StrEqual(info, "add"))
			{
	 			g_bListeningForDeviceName[param1] = true; 
	 			
			}
			else
			{
				for (int i = 0; i < g_iTotalTickets; i++)
				{
					char szId[10];
					IntToString(i, szId, sizeof(szId));
					if(StrEqual(info, szId))
					{
						//Display ticket information about device #'i'
					}
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

stock void CreateTables()
{
	char szQuery[4096];
	//Stats per round
	Format(szQuery, sizeof(szQuery), 	"CREATE TABLE IF NOT EXISTS `devices` ( \
										`id` int(10) NOT NULL AUTO_INCREMENT, \
									  	`name` varchar(32) NOT NULL, \
									  	`owner_name` varchar(64) NOT NULL, \
									  	`owner_id` varchar(32) NOT NULL, \
									  	`ticket_opened` int(3) NOT NULL, \
									  	PRIMARY KEY (`id`) \
										) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 AUTO_INCREMENT=1; \
										CREATE TABLE IF NOT EXISTS `tickets` ( \
										`id` int(10) NOT NULL AUTO_INCREMENT, \
									  	`device_id` int(10) NOT NULL, \
									  	`opened_by_name` varchar(64) NOT NULL, \
									  	`opened_by_id` varchar(32) NOT NULL, \
									  	`open_date` varchar(32) NOT NULL, \
									  	`close_date` varchar(32) NOT NULL, \
									  	`open_reason` varchar(2000) NOT NULL, \
									  	`close_reason` varchar(2000) NOT NULL, \
									  	`closed_by_name` varchar(64) NOT NULL, \
									  	`closed_by_id` varchar(32) NOT NULL, \
									  	PRIMARY KEY (`id`) \
										) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 AUTO_INCREMENT=1;");  
	g_Database.Query(SQLCallback_Void, szQuery);
}

stock void ConnectToDatabase()
{
	g_Database = null;
	Database.Connect(SQLConnection_Callback, "ticketing");
}

public void SQLConnection_Callback(Database db, const char[] error, any data)
{
	if (db == null)
		SetFailState("Could not connect to ticketing database, error: %s", error);
	else
	{
		g_Database = db;
		g_Database.SetCharset("utf8mb4");
		CreateTables();
		GetDevices();
		GetTickets();
	}
}

public void SQLCallback_GetDeviceInfo(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogError(error);
	}
	
	if (results == null)
	{
		LogError(error);
		return;
	}

	if (results.RowCount == 0)
		return;
	
	int id;
	char deviceName[32];
	char ownerName[64];
	char ownerId[32];
	int ticketOpened;
	
	results.FetchRow();
	id = results.FetchInt(0);
	results.FetchString(1, deviceName, sizeof(deviceName));
	results.FetchString(2, ownerName, sizeof(ownerName));
	results.FetchString(3, ownerId, sizeof(ownerId));
	ticketOpened = results.FetchInt(4);
	
	DInfo[id].iDeviceId = id;
	Format(DInfo[id].szDeviceName, sizeof(DeviceInfo::szDeviceName), "%s", deviceName);
	Format(DInfo[id].szOwnerName, sizeof(DeviceInfo::szOwnerName), "%s", ownerName);
	Format(DInfo[id].szOwnerId, sizeof(DeviceInfo::szOwnerId), "%s", ownerId);
	DInfo[id].iDeviceTicketOpened = ticketOpened;
}

public void SQLCallback_GetTicketInfo(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogError(error);
	}
	
	if (results == null)
	{
		LogError(error);
		return;
	}

	if (results.RowCount == 0)
		return;
	
	int id;
	int deviceId;
	char openedByName[64];
	char openedById[32];
	int openDate;
	int closeDate;
	char openReason[2000];
	char closeReason[2000];
	char closedByName[64];
	char closedById[32];
	
	results.FetchRow();
	id = results.FetchInt(0);
	deviceId = results.FetchInt(1);
	results.FetchString(2, openedByName, sizeof(openedByName));
	results.FetchString(3, openedById, sizeof(openedById));
	openDate = results.FetchInt(4);
	closeDate = results.FetchInt(5);
	results.FetchString(6, openReason, sizeof(openReason));
	results.FetchString(7, closeReason, sizeof(closeReason));
	results.FetchString(8, closedByName, sizeof(closedByName));
	results.FetchString(9, closedById, sizeof(closedById));
	
	TInfo[id].iTicketId = id;
	TInfo[id].iTicketDeviceId = deviceId;
	Format(TInfo[id].szOpenedByName, sizeof(TicketInfo::szOpenedByName), "%s", openedByName);
	Format(TInfo[id].szOpenedById, sizeof(TicketInfo::szOpenedById), "%s", openedById);
	TInfo[id].iOpenDate = openDate;
	TInfo[id].iCloseDate = closeDate;
	Format(TInfo[id].szOpenReason, sizeof(TicketInfo::szOpenReason), "%s", openReason);
	Format(TInfo[id].szCloseReason, sizeof(TicketInfo::szCloseReason), "%s", closeReason);
	Format(TInfo[id].szClosedByName, sizeof(TicketInfo::szClosedByName), "%s", closedByName);
	Format(TInfo[id].szClosedById, sizeof(TicketInfo::szClosedById), "%s", closedById);
}

public void SQLCallback_GetDeviceId(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogError(error);
	}
	
	if (results == null)
	{
		LogError(error);
		return;
	}

	if (results.RowCount == 0)
		return;

	results.FetchRow();
	g_iTotalDevices = results.FetchInt(0);
	
	for (int i = 0; i < g_iTotalDevices; i++)
	{
		GetDeviceInfo(i);
	}
}

public void SQLCallback_GetTicketId(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogError(error);
	}
	
	if (results == null)
	{
		LogError(error);
		return;
	}

	if (results.RowCount == 0)
		return;

	results.FetchRow();
	g_iTotalTickets = results.FetchInt(0);
	
	for (int i = 0; i < g_iTotalTickets; i++)
	{
		GetTicketInfo(i);
	}
}

public void SQLCallback_Void(Database db, DBResultSet results, const char[] error, any data)
{
	PrintToServer("ERROR with ticketing system void callback, if any: %s", error);
}

/* Stocks */ 
stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (IsFakeClient(client)) return false;
	if (IsClientSourceTV(client))return false;
	return IsClientInGame(client);
}

stock void GetDeviceInfo(int id)
{
	char szQuery[4096];
	Format(szQuery, sizeof(szQuery), 		"SELECT `id`, `name`, `owner_name`, `owner_id`, `ticket_opened`\
											FROM devices WHERE `id` = '%d'", id);
											
	g_Database.Query(SQLCallback_GetDeviceInfo, szQuery);
}

stock void GetTicketInfo(int id)
{
	char szQuery[4096];
	Format(szQuery, sizeof(szQuery), 		"SELECT `id`, `device_id`, `opened_by_name`, `opened_by_id`, `open_date`, \
											`close_date`, `open_reason`, `close_reason`, `closed_by_name`, `closed_by_id`\
											FROM tickets WHERE `id` = '%d'", id);
											
	g_Database.Query(SQLCallback_GetTicketInfo, szQuery);
}

stock void GetDevices()
{
	char szQuery[4096];
	//Stats per round
	Format(szQuery, sizeof(szQuery), "SELECT MAX(id) FROM `devices`");  
	g_Database.Query(SQLCallback_GetDeviceId, szQuery);
}

stock void GetTickets()
{
	char szQuery[4096];
	//Stats per round
	Format(szQuery, sizeof(szQuery), "SELECT MAX(id) FROM `tickets`");  
	g_Database.Query(SQLCallback_GetTicketId, szQuery);
}
