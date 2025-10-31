#include <a_samp>
#include <mxINI>
#include <samp_bcrypt>
#include <sscanf2>
// others
forward SaveAccount(playerid);
#pragma warning disable 239
//
// colors
#define COLOR_RED 0xFF0000AA
#define COLOR_GREEN 0x00FF00AA
//
// pinfo
enum pInfo {
    pMoney,
    pScore
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
    new PlayerNick[500]; // Для админки
    GetPlayerName(playerid,PlayerNick,sizeof(PlayerNick)); // Узнаем ник игрока
    new users[128];
    format(users,sizeof(users),"users/%s.ini",PlayerNick); // Создаем аккаунт
    if(!fexist(users))   // Если такого ника нет,    то выводим окно с регистрацией
	{
		ShowPlayerDialog(playerid,7000,DIALOG_STYLE_INPUT, "Регистрация", "Введите пароль:", "Войти", "");
	}
	else  // Если игрок найден, то авторизация
	{
		ShowPlayerDialog(playerid,7002,DIALOG_STYLE_INPUT, "Авторизация", "Введите свой пароль:", "Войти", "");
	}
	PlayerInfo[playerid][pMoney] = 0; // При регистрации 0 денег
	return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
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
    new PlayerNick[24];
    GetPlayerName(playerid, PlayerNick, sizeof(PlayerNick));
    new userFile[128];
    format(userFile, sizeof(userFile), "users/%s.ini", PlayerNick);

    if(dialogid == 7000) // регистрация
    {
        if(!strlen(inputtext))
        {
            ShowPlayerDialog(playerid, 7000, DIALOG_STYLE_INPUT, "Регистрация", "Введите пароль:", "Войти", "");
            return 1;
        }

        if(response)
        {
            if(fexist(userFile))
            {
                ShowPlayerDialog(playerid, 7002, DIALOG_STYLE_INPUT, "Авторизация", "Введите пароль:", "Войти", "");
                return 1;
            }

            new iniFile = ini_createFile(userFile);

            if(iniFile < 0)
            {
                iniFile = ini_openFile(userFile);
                if(iniFile <= 0)
                {
                    SendClientMessage(playerid, 0xFF0000AA, "Ошибка создания аккаунта.");
                    return 1;
                }
            }

            ini_setString(iniFile, "Password", inputtext);
            ini_setInteger(iniFile, "Money", 5000);
            ini_setInteger(iniFile, "Score", 0);

            ini_closeFile(iniFile);

            SendClientMessage(playerid, 0x21DD00FF, "Вы успешно зарегистрировались.");
            ShowPlayerDialog(playerid, 7002, DIALOG_STYLE_INPUT, "Авторизация", "Введите пароль:", "Войти", "");
        }
        else // отмена регистрации (Esc)
        {
            ShowPlayerDialog(playerid, 7000, DIALOG_STYLE_INPUT, "Регистрация", "Введите пароль:", "Войти", "");
        }
    }

    else if(dialogid == 7002) // авторизация
    {
        if(!strlen(inputtext))
        {
            ShowPlayerDialog(playerid, 7002, DIALOG_STYLE_INPUT, "Авторизация", "Введите пароль:", "Войти", "");
            return 1;
        }

        if(response)
        {
            if(IsPlayerNPC(playerid)) return 1;

            new iniFile = ini_openFile(userFile);
            if(iniFile <= 0)
            {
                SendClientMessage(playerid, 0xFF0000AA, "Ошибка открытия аккаунта.");
                return 1;
            }

            new storedPassword[64];
            ini_getString(iniFile, "Password", storedPassword);
            if(!strcmp(inputtext, storedPassword, true))
            {
                ini_getInteger(iniFile, "Money", PlayerInfo[playerid][pMoney]);
                ini_getInteger(iniFile, "Score", PlayerInfo[playerid][pScore]);

                SetPlayerScore(playerid, PlayerInfo[playerid][pScore]);
                GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);

                SendClientMessage(playerid, 0x21DD00FF, "Вы успешно вошли в свой аккаунт.");
                ini_closeFile(iniFile);
                return 1;
            }
            else
            {
                SendClientMessage(playerid, 0xF60000AA, "Неверный пароль. Попробуйте снова.");
                ShowPlayerDialog(playerid, 7002, DIALOG_STYLE_INPUT, "Авторизация", "Введите пароль:", "Войти", "");
                ini_closeFile(iniFile);
                return 1;
            }
        }
        else // отмена авторизации (Esc)
        {
            ShowPlayerDialog(playerid, 7002, DIALOG_STYLE_INPUT, "Авторизация", "Введите пароль:", "Войти", "");
            return 0;
        }
    }
    return 1;
}

public SaveAccount(playerid)
{
    if(!IsPlayerConnected(playerid)) return 1;

    new PlayerNick[24];
    GetPlayerName(playerid, PlayerNick, sizeof(PlayerNick));

    new userFile[128];
    format(userFile, sizeof(userFile), "users/%s.ini", PlayerNick);

    new iniFile = ini_openFile(userFile);
    if(iniFile <= 0) return 1;

    ini_setInteger(iniFile, "Money", GetPlayerMoney(playerid));
    ini_setInteger(iniFile, "Score", GetPlayerScore(playerid));

    ini_closeFile(iniFile);

    return 1;
}
