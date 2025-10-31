#include <a_samp>
#include <mxINI>
#include <samp_bcrypt>
#include <sscanf2>
// others
#pragma warning disable 239
//
// colors
#define COLOR_RED 0xFF0000AA
#define COLOR_GREEN 0x00FF00AA
//
// pinfo
enum pInfo {
    pPass[24],
    pMoney
};

new PlayerInfo[MAX_PLAYERS][pInfo];
//
main() {}
public OnGameModeInit()
{
    return 1;
}
public OnGameModeExit()
{
	return 1;
}
public OnPlayerRequestClass(playerid, classid)
{
	return 1;
}
public OnPlayerConnect(playerid)
{
	Account(playerid, 0, "");
	return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
	Account(playerid, 3, "");
	return 1;
}
public OnPlayerSpawn(playerid)
{
	return 1;
}
public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}
public OnVehicleSpawn(vehicleid)
{
	return 1;
}
public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}
public OnPlayerText(playerid, text[])
{
	return 1;
}
public OnPlayerCommandText(playerid, cmdtext[])
{
	return 0;
}
public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}
public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}
public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}
public OnPlayerExitedMenu(playerid)
{
	return 1;
}
public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}
public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}
public OnPlayerUpdate(playerid)
{
	return 1;
}
public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}
public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}
public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}
public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case 0:
	    {
	        if(!response) return Kick(playerid);
	        if(strlen(inputtext) <= 3 || strlen(inputtext) > 24) return ShowPlayerDialog(playerid, 0, 3, "Регистрация", "Пароль должен состоять не меньше 3 и не больше 24 символов.", "Ок", "Отмена");
			new tmp[24];
			format(tmp, sizeof(tmp), "%s", inputtext);
			return Account(playerid, 1, tmp);
	    }
	    case 1:
	    {
	        if(!response) return Kick(playerid);
	        if(strlen(inputtext) <= 3 || strlen(inputtext) > 24) return ShowPlayerDialog(playerid, 1, 3, "Авторизация", "Пароль должен состоять не меньше 3 и не больше 24 символов.", "Ок", "Отмена");
			new tmp[24];
			format(tmp, sizeof(tmp), "%s", inputtext);
			return Account(playerid, 2, tmp);
	    }
	}
	return 1;
}
forward Account(playerid, mode, pass[24]);
public Account(playerid, mode, pass[24])
{
	new fn[MAX_PLAYER_NAME+5];
	GetPlayerName(playerid, fn, sizeof(fn));
	format(fn, sizeof(fn), "users/%s.ini", fn);
	new INI = ini_openFile(fn);
	if(INI == INI_OK)
	{
	    switch(mode)
	    {
	        case 1:
	        {
	            ini_setString(INI, "Password", pass);
	            ini_closeFile(INI);
	            return ShowPlayerDialog(playerid, 1, 3, "Авторизация", "Введите пароль:", "Ок", "Отмена");
	        }
			case 2:
			{
			    new tmp[24];
			    ini_getString(INI, "Password", tmp);
			    if(strcmp(tmp,pass,false,24) == 0)
			    {
           			PlayerInfo[playerid][pPass] = tmp;
			        ini_getInteger(INI, "Money", PlayerInfo[playerid][pMoney]);
			        ini_closeFile(INI);
			        return SpawnPlayer(playerid);
			    }
			    else return ShowPlayerDialog(playerid, 1, 3, "Авторизация", "Введите пароль:", "Ок", "Отмена");
			}
			case 0:
			{
			    ini_closeFile(INI);
			    return ShowPlayerDialog(playerid, 1, 3, "Авторизация", "Введите пароль:", "Ок", "Отмена");
			}
			case 3:
			{
			    ini_setString(INI, "Password", PlayerInfo[playerid][pPass]);
			    ini_setInteger(INI, "Money", PlayerInfo[playerid][pMoney]);
			    ini_closeFile(INI);
			}
	    }
	}
	else
	{
	    INI = ini_createFile(fn);
	    if(INI == INI_OK)
		{
		    ini_setString(INI, "Password", "");
		    ini_setInteger(INI, "Money", 1000);
		    ini_closeFile(INI);
		    return ShowPlayerDialog(playerid, 0, 3, "Регистрация", "Введите пароль:", "Ок", "Отмена");
		}
		else return Account(playerid, 0, "");
	}
	return 1;
}
