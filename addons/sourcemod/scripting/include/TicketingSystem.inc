    
/*
**
*/
#if defined _TicketingSystem_included
 #endinput
#endif
#define _TicketingSystem_included

/* Plugin Defines */
#define MAX_INFO_LENGTH (100)

enum struct DeviceInfo
{
	int iDeviceId;
	char szDeviceName[32];
	char szOwnerName[64];
	char szOwnerId[32];
	int iDeviceTicketOpened;
}

enum struct TicketInfo
{
	int iTicketId;
	int iTicketDeviceId;
	char szOpenedByName[64];
	char szOpenedById[32];
	int iOpenDate;
	int iCloseDate;
	char szOpenReason[2000];
	char szCloseReason[2000];
	char szClosedByName[64];
	char szClosedById[32];
}

public SharedPlugin __pl_INTERFACE =
{
	name = "TicketingSystem",
	file = "TicketingSystem.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};
