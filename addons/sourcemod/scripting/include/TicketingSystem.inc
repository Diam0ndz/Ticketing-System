/*
**
*/
#if defined _INCLUDE_included
 #endinput
#endif
#define _INCLUDE_included

enum DeviceInfo
{
	iDeviceId,
	String:szDeviceName[32],
	String:szOwnerName[64],
	String:szOwnerId[32],
	iDeviceTicketOpened,
}

enum TicketInfo
{
	iTicketId,
	iTicketDeviceId,
	String:szOpenedByName[64],
	String:szOpenedById[32],
	iOpenDate,
	iCloseDate,
	String:szOpenReason[2000],
	String:szCloseReason[2000],
	String:szClosedByName[64],
	String:szClosedById[32],
}