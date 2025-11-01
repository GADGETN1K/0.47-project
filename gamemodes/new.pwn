#include <a_samp>
#include <mxINI>
#include <foreach>
#include <sscanf2>
#include <streamer>
#include <Pawn.CMD>
// others
#pragma warning disable 239
#define SALT_SIZE 16
#define HASH_SIZE 65
#define MAX_PASS_LENGTH 24
new PlayerSalt[MAX_PLAYERS][SALT_SIZE];
new PlayerPasswordHash[MAX_PLAYERS][HASH_SIZE];
new PlayerMoney[MAX_PLAYERS];
new PlayerLevel[MAX_PLAYERS];
new bool:IsPlayerLoggedIn[MAX_PLAYERS];
new const Float:VIRTUAL_SPAWN[4] = {1043.1250,1016.8333,11.0000,0.0000};
new const Float:NORMAL_SPAWN[4] = {1492.0560,-1837.0934,13.5469,238.1122};
#define INFO_PICKUP_X 1032.4861
#define INFO_PICKUP_Y 1018.0731
#define INFO_PICKUP_Z 11.0000
#define INFO_PICKUP_n_X 1516.9457
#define INFO_PICKUP_n_Y -1834.0599
#define INFO_PICKUP_n_Z 14.0392
new infoPickup[2];
#define DIALOG_INFO 1000
#define DIALOG_INFO_2 1001
// colors
#define COLOR_RED 0xFF0000AA
#define COLOR_GREEN 0x00FF00AA
main() {}
public OnGameModeInit()
{
	SendRconCommand("hostname 0.47 Project v0.0.1a (alpha)");
	SetGameModeText(":: test ::");
    infoPickup[0] = CreatePickup(1274, 3, INFO_PICKUP_X, INFO_PICKUP_Y, INFO_PICKUP_Z, 9999);
    infoPickup[1] = CreatePickup(1274, 3, INFO_PICKUP_n_X, INFO_PICKUP_n_Y, INFO_PICKUP_n_Z, 0);
    Create3DTextLabel("Информация", 0xFFFFFFFF, INFO_PICKUP_X, INFO_PICKUP_Y, INFO_PICKUP_Z + 1.0, 20.0, 9999, 0);
}
public OnGameModeExit()
{
	return 1;
}
public OnPlayerRequestClass(playerid, classid)
{
    new Float:x, Float:y, Float:z, Float:angle;

    if (!IsPlayerLoggedIn[playerid])
    {
        // Спавн для незалогиненных — виртуальный мир, спец-координаты
        x = VIRTUAL_SPAWN[0];
        y = VIRTUAL_SPAWN[1];
        z = VIRTUAL_SPAWN[2];
        angle = VIRTUAL_SPAWN[3];
        SetPlayerVirtualWorld(playerid, 9999); // Виртуальный мир ожидания
    }
    else
    {
        // Спавн для залогиненных — нормальный мир и координаты
        x = NORMAL_SPAWN[0];
        y = NORMAL_SPAWN[1];
        z = NORMAL_SPAWN[2];
        angle = NORMAL_SPAWN[3];
        SetPlayerVirtualWorld(playerid, 0);
    }

    SetSpawnInfo(playerid, classid, 3, x, y, z, angle, -1, -1, -1, -1, -1, -1);
    SpawnPlayer(playerid);

    return 1;
}
public OnPlayerConnect(playerid)
{
    IsPlayerLoggedIn[playerid] = false;
    SendClientMessage(playerid, 0xFFFFFFAA, "Пожалуйста, зарегистрируйтесь (/register) или войдите (/login).");
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
    if (!IsPlayerLoggedIn[playerid])
    {
        SendClientMessage(playerid, 0xFF0000FF, "Вы не можете писать в чат, пока не войдёте в аккаунт.");
        return 0; // блокируем сообщение в чат
    }
    return 1; // разрешаем сообщение
}
public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!IsPlayerLoggedIn[playerid])
    {
        // Разрешаем команду, если начинается с /login или /register
        if (cmdtext[0] == '/' && (
            (cmdtext[1] == 'l' && cmdtext[2] == 'o' && cmdtext[3] == 'g' && cmdtext[4] == 'i' && cmdtext[5] == 'n') ||
            (cmdtext[1] == 'r' && cmdtext[2] == 'e' && cmdtext[3] == 'g' && cmdtext[4] == 'i' && cmdtext[5] == 's' && cmdtext[6] == 't' && cmdtext[7] == 'e' && cmdtext[8] == 'r')
            ))
        {
            return 0; // разрешить команду
        }

        SendClientMessage(playerid, 0xFF0000AA, "Сначала зарегистрируйтесь или войдите.");
        return 1; // заблокировать остальные команды
    }
    return 0; // разрешить все команды для залогиненных
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
    if (pickupid == infoPickup[0])
    {
        ShowPlayerDialog(playerid, DIALOG_INFO, DIALOG_STYLE_MSGBOX, "Информация", "Здравствуйте, вы на проекте 0.47 Project.\r\nПроект является open-source, исходный код и плагины располагаются на GitHub разработчика.\r\nИсходный код: https://github.com/GADGETNiK/0.47-project\r\nИгровой мод сделан с упором на старые времена SAMP Android 0.47 build.\r\nВы сейчас находитесь в виртуальном мире, чтобы выйти, нужно зарегистрироваться или авторизоваться.\r\nЕсли аккаунта нет - /register, если есть - /login\r\n\r\nНажмите ОК для закрытия.", "ОК", "");
        return 1;
    }
    if (pickupid == infoPickup[1])
    {
        ShowPlayerDialog(playerid, DIALOG_INFO_2, DIALOG_STYLE_MSGBOX, "Информация", "Здравствуйте, вы на проекте 0.47 Project.\r\nПроект является open-source, исходный код и плагины располагаются на GitHub разработчика.\r\nИсходный код: https://github.com/GADGETNiK/0.47-project\r\nИгровой мод сделан с упором на старые времена SAMP Android 0.47 build.\r\nВы сейчас находитесь в обычном мире, можете начинать играть.\r\n\r\nНажмите ОК для закрытия.", "ОК", "");
        return 1;
    }
    return 0;
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
    if (dialogid == DIALOG_INFO || dialogid == DIALOG_INFO_2) return 1;
    return 0;
}
stock bool:RegisterPlayer(playerid, password[])
{
    new fn[64], INI;
    GetPlayerName(playerid, fn, sizeof(fn));
    format(fn, sizeof(fn), "users/%s.ini", fn);
    INI = ini_openFile(fn);
    if (INI >= 0)
    {
        ini_closeFile(INI);
        SendClientMessage(playerid, 0xFFFF0000, "Аккаунт уже существует. Используйте /login.");
        return false;
    }
    INI = ini_createFile(fn, "");
    if (INI < 0)
    {
        SendClientMessage(playerid, 0xFF0000FF, "Ошибка создания файла профиля");
        return false;
    }
    new salt[SALT_SIZE];
    format(salt, sizeof(salt), "salt_%d", playerid);
    new hash[HASH_SIZE];
    SHA256_PassHash(password, salt, hash, sizeof(hash));
    ini_setString(INI, "Salt", salt);
    ini_setString(INI, "PasswordHash", hash);
    ini_setInteger(INI, "Money", 1000);
    ini_setInteger(INI, "Level", 1);
    ini_closeFile(INI);
    new i;
    for (i = 0; i < SALT_SIZE - 1 && salt[i] != '\0'; i++) PlayerSalt[playerid][i] = salt[i];
    PlayerSalt[playerid][i] = '\0';
    for (i = 0; i < HASH_SIZE - 1 && hash[i] != '\0'; i++) PlayerPasswordHash[playerid][i] = hash[i];
    PlayerPasswordHash[playerid][i] = '\0';
    PlayerMoney[playerid] = 1000;
    PlayerLevel[playerid] = 1;
    GivePlayerMoney(playerid, PlayerMoney[playerid]);
    SetPlayerScore(playerid, PlayerLevel[playerid]);
    return true;
}
stock bool:AuthenticatePlayer(playerid, password[])
{
    new fn[64], INI;
    GetPlayerName(playerid, fn, sizeof(fn));
    format(fn, sizeof(fn), "users/%s.ini", fn);
    INI = ini_openFile(fn);
    if (INI < 0)
    {
        SendClientMessage(playerid, 0xFF0000FF, "Профиль не найден, зарегистрируйтесь");
        return false;
    }
    if (PlayerSalt[playerid][0]=='\0' || PlayerPasswordHash[playerid][0]=='\0')
    {
        ini_getString(INI, "Salt", PlayerSalt[playerid]);
        ini_getString(INI, "PasswordHash", PlayerPasswordHash[playerid]);
        new moneyVal;
		if (ini_getInteger(INI, "Money", moneyVal) == 0) PlayerMoney[playerid] = moneyVal;
		else PlayerMoney[playerid] = 0;
        new levelVal;
		if (ini_getInteger(INI, "Level", moneyVal) == 0) PlayerLevel[playerid] = levelVal;
		else PlayerLevel[playerid] = 0;
    }
    ini_closeFile(INI);
	GivePlayerMoney(playerid, PlayerMoney[playerid]);
	SetPlayerScore(playerid, PlayerLevel[playerid]);
    new computedHash[HASH_SIZE];
    SHA256_PassHash(password, PlayerSalt[playerid], computedHash, sizeof(computedHash));
    return (strcmp(computedHash, PlayerPasswordHash[playerid], false)==0);
}
CMD:register(playerid, params[])
{
    if (strlen(params) == 0)
    {
        SendClientMessage(playerid, 0xFFFF0000, "Использование: /register <пароль>");
        return 1;
    }
    new password[MAX_PASS_LENGTH + 1];
    strmid(password, params, 0, sizeof(password) - 1);
    if (strlen(password) < 4)
    {
        SendClientMessage(playerid, 0xFFFF0000, "Пароль должен содержать минимум 4 символа.");
        return 1;
    }
    if (!RegisterPlayer(playerid, password)) return 1;
    IsPlayerLoggedIn[playerid] = true;
    SendClientMessage(playerid, 0xFF00FF00, "Регистрация успешна! Вы вошли.");
    OnPlayerRequestClass(playerid, 0);
    return 1;
}

CMD:login(playerid, params[])
{
    if (IsPlayerLoggedIn[playerid])
    {
        SendClientMessage(playerid, 0xFFFF0000, "Вы уже вошли в аккаунт.");
        return 1;
    }
    if (strlen(params) == 0)
    {
        SendClientMessage(playerid, 0xFFFF0000, "Используйте: /login <пароль>");
        return 1;
    }
    new password[MAX_PASS_LENGTH + 1];
    strmid(password, params, 0, sizeof(password) - 1);
    if (AuthenticatePlayer(playerid, password))
    {
        IsPlayerLoggedIn[playerid] = true;
        SendClientMessage(playerid, 0xFF00FF00, "Вы успешно вошли.");
        OnPlayerRequestClass(playerid, 0);
    }
    else
    {
        SendClientMessage(playerid, 0xFFFF0000, "Неверный пароль.");
    }
    return 1;
}
CMD:givevehid(playerid, params[])
{
    new modelid;
    if (sscanf(params, "d", modelid))
    {
        SendClientMessage(playerid, 0xFF0000FF, "Использование: /givevehid [ID модели транспорта]");
        return 0;
    }
    if (modelid < 400 || modelid > 611)
    {
        SendClientMessage(playerid, 0xFF0000FF, "Неверный ID модели транспорта.");
        return 0;
    }
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    new vehicleid = CreateVehicle(modelid, x + 2.0, y, z, 0.0, 100, 0, -1);
    if (vehicleid == INVALID_VEHICLE_ID)
    {
        SendClientMessage(playerid, 0xFF0000FF, "Ошибка при создании транспорта.");
        return 0;
    }
    PutPlayerInVehicle(playerid, vehicleid, -1);
    SendClientMessage(playerid, 0x00FF00FF, "Транспорт создан и выдан вам.");
    return 1;
}
