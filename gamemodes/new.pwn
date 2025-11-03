#include <a_samp>
#include <a_mysql>
#include <foreach>
#include <sscanf2>
#include <streamer>
#include <Pawn.CMD>
///////////////////
new MySQL:sampbd;
#define MYSQL_HOST      "127.0.0.1"
#define MYSQL_USER      "root"
#define MYSQL_PASSWORD  "^Ws1@SJc7JJmtY"
#define MYSQL_DATABASE  "047project"
///////////////////
#define SCM             			SendClientMessage
#define SALT_SIZE 16
#define HASH_SIZE 65
#define MAX_PASS_LENGTH 30
#define LOCAL_CHAT_RADIUS 30.0
#define INFO_PICKUP_X 1032.4861
#define INFO_PICKUP_Y 1018.0731
#define INFO_PICKUP_Z 11.0000
#define INFO_PICKUP_n_X 1516.9457
#define INFO_PICKUP_n_Y -1834.0599
#define INFO_PICKUP_n_Z 14.0392
#define DIALOG_INFO 1000
#define DIALOG_INFO_2 1001
#define DIALOG_RENT_BIKE 2000
#define BIKE_MODEL 509
#define RENT_DURATION 300000
#define INVALID_TIMER -1
#define GRUZ_BAG_X 2225.1597
#define GRUZ_BAG_Y -2278.2952
#define GRUZ_BAG_Z 14.7647
#define CHECKPOINT_RADIUS 3.0
///////////////////
main() {}
#pragma warning disable 239
///////////////////
new LoginPassword[MAX_PLAYERS][MAX_PASS_LENGTH + 1];
enum pInfo
{
	pID,
	pName[MAX_PLAYER_NAME],
	pSalt[16],
	pPasswordHash[65],
	pMoney,
	pLevel,
	pEXP,
	pSkin,
	pAdmin
}
new PlayerInfo[MAX_PLAYERS][pInfo];
new bool:IsPlayerLoggedIn[MAX_PLAYERS];
new bool:IsPlayerRegistered[MAX_PLAYERS];
////////////////////
new const Float:VIRTUAL_SPAWN[4] = {1043.1250,1016.8333,11.0000,0.0000};
new const Float:NORMAL_SPAWN[4] = {1492.0560,-1837.0934,13.5469,238.1122};
new infoPickup[2];
new bikePickup;
new Float:BikePickupPos[3] = {1510.1011,-1849.7041,13.5469};
new PlayerBike[MAX_PLAYERS];
new PlayerBikeTimer[MAX_PLAYERS];
new loadergruz;
new Float:GruzDropPoints[3][3] = {
    {2168.1172, -2262.8401, 13.3052},
    {2158.4097, -2232.5789, 13.3071},
    {2144.2583, -2254.5845, 13.2990}
};
////////////////////
public OnGameModeInit()
{
	sampbd = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE);
	EnableStuntBonusForAll(0);
	DisableInteriorEnterExits();
	SendRconCommand("hostname 0.47 Project v0.0.1c (alpha)");
	SetGameModeText(":: test ::");
    infoPickup[0] = CreatePickup(18631, 2, INFO_PICKUP_X, INFO_PICKUP_Y, INFO_PICKUP_Z, 9999);
    infoPickup[1] = CreatePickup(18631, 2, INFO_PICKUP_n_X, INFO_PICKUP_n_Y, INFO_PICKUP_n_Z, 0);
    Create3DTextLabel("Информация", 0xFFFFFFFF, INFO_PICKUP_X, INFO_PICKUP_Y, INFO_PICKUP_Z + 1.0, 20.0, 9999, 0);
    bikePickup = CreatePickup(19134, 2, BikePickupPos[0], BikePickupPos[1], BikePickupPos[2], 0);
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        PlayerBike[i] = INVALID_VEHICLE_ID;
        PlayerBikeTimer[i] = INVALID_TIMER;
    }
	loadergruz = CreatePickup(1275, 2, 2193.7202, -2251.5547, 13.5469, 0); // Пикап для переодевалки, устройства и увольнения грузчика
}
public OnGameModeExit()
{
	foreach(Player, i) SaveAccount(i);
	mysql_close();
	return 1;
}
public OnPlayerRequestClass(playerid, classid)
{
    SetSpawnInfo(playerid, classid, 0, 0.0, 0.0, 0.0, 0.0, -1, -1, -1, -1, -1, -1);
    SpawnPlayer(playerid);
    return 1;
}
public OnPlayerConnect(playerid)
{
    IsPlayerLoggedIn[playerid] = false;
    IsPlayerRegistered[playerid] = false;
	SetPlayerVirtualWorld(playerid, 9999);
    // Устанавливаем виртуальный спавн и скин бомжа
    SetPlayerPos(playerid, VIRTUAL_SPAWN[0], VIRTUAL_SPAWN[1], VIRTUAL_SPAWN[2]);
    SetPlayerFacingAngle(playerid, VIRTUAL_SPAWN[3]);
    SetPlayerSkin(playerid, 3);
    new player_name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, player_name, sizeof(player_name));
    new query[256];
    format(query, sizeof(query), "SELECT `id` FROM `accounts` WHERE LOWER(`name`) = LOWER('%s')", player_name);
    mysql_tquery(sampbd, query, "find_table", "i", playerid);
    SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Пожалуйста, зарегистрируйтесь (/register) или войдите (/login).");
    removeobj(playerid);
    return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
	if (PlayerBike[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(PlayerBike[playerid]);
        PlayerBike[playerid] = INVALID_VEHICLE_ID;
        if (PlayerBikeTimer[playerid] != INVALID_TIMER)
        {
            KillTimer(PlayerBikeTimer[playerid]);
            PlayerBikeTimer[playerid] = INVALID_TIMER;
        }
    }
    DeletePVar(playerid, "gruzskin");
    DeletePVar(playerid, "gruz_bag_taken");
    DeletePVar(playerid, "loader_gruz");
    LoginPassword[playerid][0] = '\0';
    IsPlayerLoggedIn[playerid] = false;
    IsPlayerRegistered[playerid] = false;
    SaveAccount(playerid);
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (dialogid == DIALOG_INFO || dialogid == DIALOG_INFO_2) return 1;
    if (dialogid == DIALOG_RENT_BIKE)
    {
    	if (response)
        {
            if (PlayerBike[playerid] != INVALID_VEHICLE_ID)
            {
                SendClientMessage(playerid, -1, "{808000}[SERVER]:{FF0000} У вас уже есть арендованный велосипед.");
                return 1;
            }
            new vehicle = CreateVehicle(BIKE_MODEL, BikePickupPos[0] + 2.0, BikePickupPos[1] + 1.5, BikePickupPos[2] + 1.0, 0.0, -1, -1, -1, 0);
            if (vehicle == INVALID_VEHICLE_ID)
            {
                SendClientMessage(playerid, -1, "{808000}[SERVER]:{FF0000} Не удалось создать велосипед. Попробуйте позже.");
                return 1;
            }
            PlayerBike[playerid] = vehicle;
        }
        else
        {
            SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Аренда отменена.");
        }
        return 1;
    }
    return 0;
}
public OnPlayerText(playerid, text[])
{
    if (!IsPlayerLoggedIn[playerid])
    {
        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FF0000} Вы не можете писать в чат, пока не войдёте в аккаунт.");
        return 0; // блокируем сообщение в чат
    }
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    new count = GetMaxPlayers();
    new target;
    new msg[144];
    GetPlayerName(playerid, msg, sizeof(msg));
    format(msg, sizeof(msg), "%s: %s", msg, text);
    for (target = 0; target < count; target++)
    {
        if (!IsPlayerConnected(target) || !IsPlayerLoggedIn[target]) continue;
        new Float:tx, Float:ty, Float:tz;
        GetPlayerPos(target, tx, ty, tz);
        new Float:dist = floatsqroot((x - tx) * (x - tx) + (y - ty) * (y - ty) + (z - tz) * (z - tz));
        if (dist <= LOCAL_CHAT_RADIUS)
        {
            SendClientMessage(target, 0xFFFFFFFF, msg);
        }
    }
    return 0;
}
public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!IsPlayerLoggedIn[playerid])
    {
        if (cmdtext[0] == '/' && (
            (cmdtext[1] == 'l' && cmdtext[2] == 'o' && cmdtext[3] == 'g' && cmdtext[4] == 'i' && cmdtext[5] == 'n') ||
            (cmdtext[1] == 'r' && cmdtext[2] == 'e' && cmdtext[3] == 'g' && cmdtext[4] == 'i' && cmdtext[5] == 's' && cmdtext[6] == 't' && cmdtext[7] == 'e' && cmdtext[8] == 'r')
            ))
        {
            return 0;
        }
        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FF0000} Сначала зарегистрируйтесь или войдите.");
        return 1;
    }
    return 0;
}
public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (i == playerid) continue;
        if (PlayerBike[i] == vehicleid)
        {
            RemovePlayerFromVehicle(playerid);
            return 0;
        }
    }
    if (PlayerBike[playerid] == vehicleid)
    {
        if (PlayerBikeTimer[playerid] != INVALID_TIMER)
        {
            KillTimer(PlayerBikeTimer[playerid]);
            PlayerBikeTimer[playerid] = INVALID_TIMER;
        }
    }
    return 1;
}
public OnPlayerExitVehicle(playerid, vehicleid)
{
    if (PlayerBike[playerid] == vehicleid) if (PlayerBikeTimer[playerid] == INVALID_TIMER) PlayerBikeTimer[playerid] = SetTimerEx("ReturnBike", RENT_DURATION, false, "i", playerid);
    return 1;
}
public OnPlayerEnterCheckpoint(playerid)
{
	if (IsPlayerInRangeOfPoint(playerid, 2.0, GRUZ_BAG_X, GRUZ_BAG_Y, GRUZ_BAG_Z)
	    && !GetPVarInt(playerid, "gruz_bag_taken")
	    && GetPVarInt(playerid, "loader_gruz") == 1)
	{
	    if (!IsPlayerInAnyVehicle(playerid))
	    {
	        SetPVarInt(playerid, "gruz_bag_taken", 1);
	        GruzRand(playerid);
	        ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.1, 0, 1, 1, 1, 1);
	        SetPlayerAttachedObject(playerid, 2, 2060, 5, 0.01, 0.1, 0.2, 100, 10, 85);
	        SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Вы взяли мешок. Отнесите его на склад.");
	        new Float:x = GetPVarFloat(playerid, "gruz_drop_x");
	        new Float:y = GetPVarFloat(playerid, "gruz_drop_y");
	        new Float:z = GetPVarFloat(playerid, "gruz_drop_z");
	        SetPlayerCheckpoint(playerid, x, y, z, 2.0);
	    }
	    else
	    {
	        SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Нельзя брать мешок в транспорте!");
	    }
	}
	if (IsPlayerInRangeOfPoint(playerid, 2.0, GetPVarFloat(playerid, "gruz_drop_x"), GetPVarFloat(playerid, "gruz_drop_y"), GetPVarFloat(playerid, "gruz_drop_z"))
	    && GetPVarInt(playerid, "gruz_bag_taken") == 1)
	{
	    if (!IsPlayerInAnyVehicle(playerid))
	    {
	        SetPVarInt(playerid, "accumulated_salary", GetPVarInt(playerid, "accumulated_salary") + 50);
	        RemovePlayerAttachedObject(playerid, 2);
	        SetPVarInt(playerid, "gruz_bag_taken", 0);
	        SetPlayerCheckpoint(playerid, 2225.15, -2278.29, 14.76, 2.0);
	        ApplyAnimation(playerid, "PED", "IDLE_tired", 4.1, 0, 1, 1, 0, 1);
	    }
	    else
	    {
	        SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Нельзя сдавать мешок в транспорте!");
	    }
	}
    return 0;
}
public OnPlayerPickUpPickup(playerid, pickupid)
{
    if (pickupid == infoPickup[0])
    {
        ShowPlayerDialog(playerid, DIALOG_INFO, DIALOG_STYLE_MSGBOX, "Информация", "Здравствуйте, вы на проекте 0.47 Project.\r\n \
		Проект является open-source, исходный код и плагины располагаются на GitHub разработчика.\r\n \
		Исходный код: https://github.com/GADGETNiK/0.47-project\r\n \
		Игровой мод сделан с упором на старые времена SAMP Android 0.47 build.\r\n \
		Вы сейчас находитесь в виртуальном мире, чтобы выйти, нужно зарегистрироваться или авторизоваться.\r\n \
		Если аккаунта нет - /register, если есть - /login\r\n\r\n \
		Нажмите ОК для закрытия.", "ОК", "");
        return 1;
    }
    if (pickupid == infoPickup[1])
    {
        ShowPlayerDialog(playerid, DIALOG_INFO_2, DIALOG_STYLE_MSGBOX, "Информация", "Здравствуйте, вы на проекте 0.47 Project.\r\n \
		Проект является open-source, исходный код и плагины располагаются на GitHub разработчика.\r\n \
		Исходный код: https://github.com/GADGETNiK/0.47-project\r\n \
		Игровой мод сделан с упором на старые времена SAMP Android 0.47 build.\r\n \
		Вы сейчас находитесь в обычном мире, можете начинать играть.\r\n\r\n \
		Нажмите ОК для закрытия.", "ОК", "");
        return 1;
    }
    if (pickupid == bikePickup)
    {
        if (!IsPlayerLoggedIn[playerid])
        {
            SendClientMessage(playerid, -1, "{808000}[SERVER]:{FF0000} Аренда велосипеда доступна только залогиненным.");
            return 1;
        }
        if (PlayerBike[playerid] != INVALID_VEHICLE_ID)
        {
            SendClientMessage(playerid, -1, "{808000}[SERVER]:{FF0000} Вы уже арендовали велосипед.");
            return 1;
        }
        ShowPlayerDialog(playerid, DIALOG_RENT_BIKE, DIALOG_STYLE_MSGBOX, "Аренда велосипеда", "Хотите арендовать велосипед?\r\nСтоимость: бесплатно\r\n \
		ВНИМАНИЕ: Имеется таймер, если после выхода с велосипеда, вы не сядете за 5 минут простоя, то велосипед пропадёт.", "Арендовать", "Отмена");
        return 1;
    }
	if (pickupid == loadergruz)
	{
	    if (!GetPVarInt(playerid, "loader_gruz"))
	    {
			SetPVarInt(playerid, "gruzskin", 260);
			SetPlayerSkin(playerid, GetPVarInt(playerid, "gruzskin"));
	        SetPVarInt(playerid, "loader_gruz", 1);
	        SetPlayerCheckpoint(playerid, 2225.15, -2278.29, 14.76, 2.0);
	        SetPVarInt(playerid, "accumulated_salary", 0);
	        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Вы устроились грузчиком. Идите на красный маркер (указан на миникарте).");
	    }
	    else
	    {
	        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Вы уволились.");
			GivePlayerCash(playerid, GetPVarInt(playerid, "accumulated_salary"));
	        SetPVarInt(playerid, "loader_gruz", 0);
	        DisablePlayerCheckpoint(playerid);
	        SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
	        DeletePVar(playerid, "loader_gruz");
	        DeletePVar(playerid, "accumulated_salary");
	        DeletePVar(playerid, "gruzskin");
	    }
	    return 1;
	}
    return 0;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if((newkeys & KEY_JUMP) && !(oldkeys & KEY_JUMP) || (newkeys & KEY_FIRE))
	{
		if(GetPVarInt(playerid, "gruz_bag_taken"))
		{
		    SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Вы уронили мешок");
		    RemovePlayerAttachedObject(playerid, 2);
		    SetPVarInt(playerid, "gruz_bag_taken", 0);
		    SetPlayerCheckpoint(playerid, 2225.15, -2278.29, 14.76, 2.0);
		    ApplyAnimation(playerid, "PED", "IDLE_tired", 4.1, 0, 1, 1, 0, 1);
		}
	}
	return 1;
}
public OnPlayerSpawn(playerid)
{
    if (!IsPlayerLoggedIn[playerid])
    {
        SetPlayerVirtualWorld(playerid, 9999);
        SetPlayerPos(playerid, VIRTUAL_SPAWN[0], VIRTUAL_SPAWN[1], VIRTUAL_SPAWN[2]);
        SetPlayerFacingAngle(playerid, VIRTUAL_SPAWN[3]);
        SetPlayerSkin(playerid, 3); // скин бомжа
    }
    else
    {
        SetPlayerVirtualWorld(playerid, 0);
        SetPlayerPos(playerid, NORMAL_SPAWN[0], NORMAL_SPAWN[1], NORMAL_SPAWN[2]);
        SetPlayerFacingAngle(playerid, NORMAL_SPAWN[3]);
        SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
    }
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
public OnPlayerStateChange(playerid, newstate, oldstate)
{
    if (newstate == PLAYER_STATE_DRIVER)
    {
        new vehicleid = GetPlayerVehicleID(playerid);
        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (i == playerid) continue;
            if (PlayerBike[i] == vehicleid)
            {
                RemovePlayerFromVehicle(playerid);
                return 0;
            }
        }
    }
    if (newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER)
    {
        if(GetPVarInt(playerid, "gruz_bag_taken") > 0)
        {
            SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Вас уволили.{FF0000} Причина: Попытка сесть в транспорт с мешком.");
            SCM(playerid, -1, "{808000}Директор завода:{FFFFFF} Зарплаты не будет, за попытки схитрить. {FF0000}Удачи.");
            RemovePlayerAttachedObject(playerid, 2);
            SetPVarInt(playerid, "gruz_bag_taken", 0);
            SetPlayerCheckpoint(playerid, 2225.15, -2278.29, 14.76, 2.0);
            ApplyAnimation(playerid, "PED", "IDLE_tired", 4.1, 0, 1, 1, 0, 1);
            DeletePVar(playerid, "loader_gruz");
        	DeletePVar(playerid, "accumulated_salary");
	        DeletePVar(playerid, "gruzskin");
	        DisablePlayerCheckpoint(playerid);
	        SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
            return 0;
        }
    }
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
/////////////////////
forward ReturnBike(playerid);
public ReturnBike(playerid)
{
    if (PlayerBike[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(PlayerBike[playerid]);
        PlayerBike[playerid] = INVALID_VEHICLE_ID;
        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FF0000} Время аренды велосипеда истекло. Велосипед возвращён.");
        PlayerBikeTimer[playerid] = INVALID_TIMER;
    }
}
forward GivePlayerCash(playerid, amount);
public GivePlayerCash(playerid, amount)
{
    PlayerInfo[playerid][pMoney] += amount;
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);
}
stock GruzRand(playerid)
{
    new idx = random(3); // 0,1,2
    SetPVarFloat(playerid, "gruz_drop_x", GruzDropPoints[idx][0]);
    SetPVarFloat(playerid, "gruz_drop_y", GruzDropPoints[idx][1]);
    SetPVarFloat(playerid, "gruz_drop_z", GruzDropPoints[idx][2]);
}
/////////////////////////////////////////////
forward find_table(playerid);
public find_table(playerid)
{
    new rows;
    cache_get_row_count(rows);
    if (!rows)
    {
        IsPlayerRegistered[playerid] = false;
        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Аккаунт не найден. Пожалуйста, зарегистрируйтесь с помощью /register <пароль>.");
    }
    else
    {
        IsPlayerRegistered[playerid] = true;
        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Аккаунт найден. Пожалуйста, авторизуйтесь с помощью /login <пароль>.");
		new player_name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, player_name, sizeof(player_name));
        new query[256];
        format(query, sizeof(query),
            "SELECT id, name, password_salt, password_hash, money, level, exp, skin, admin FROM accounts WHERE LOWER(name) = LOWER('%s') LIMIT 1",
            player_name);
        mysql_tquery(sampbd, query, "UploadPlayerAccount", "i", playerid);
    }
    return 1;
}
stock bool:CheckLoginPassword(playerid)
{
    if (strlen(LoginPassword[playerid]) == 0) return false;
    new computedHash[65];
    SHA256_PassHash(LoginPassword[playerid], PlayerInfo[playerid][pSalt], computedHash, sizeof(computedHash));
    if (strcmp(computedHash, PlayerInfo[playerid][pPasswordHash], false) != 0)
    {
        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FF0000} Неверный пароль.");
        return false;
    }
    IsPlayerLoggedIn[playerid] = true;
    SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Авторизация прошла успешно. Приятной игры на нашем проекте.");
    LoginPassword[playerid][0] = '\0';
	GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);
    SetPlayerScore(playerid, PlayerInfo[playerid][pLevel]);
    SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
    SpawnPlayer(playerid);
    return true;
}
forward UploadPlayerAccount(playerid);
public UploadPlayerAccount(playerid)
{
    if (cache_num_rows() == 0)
    {
        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Аккаунт не найден.");
        return 0;
    }
    cache_get_value_name_int(0, "id", PlayerInfo[playerid][pID]);
    cache_get_value_name(0, "name", PlayerInfo[playerid][pName]);
    cache_get_value_name(0, "password_salt", PlayerInfo[playerid][pSalt]);
    cache_get_value_name(0, "password_hash", PlayerInfo[playerid][pPasswordHash]);
    cache_get_value_name_int(0, "money", PlayerInfo[playerid][pMoney]);
    cache_get_value_name_int(0, "level", PlayerInfo[playerid][pLevel]);
    cache_get_value_name_int(0, "exp", PlayerInfo[playerid][pEXP]);
    cache_get_value_name_int(0, "skin", PlayerInfo[playerid][pSkin]);
    cache_get_value_name_int(0, "admin", PlayerInfo[playerid][pAdmin]);
    return CheckLoginPassword(playerid);
}
stock SaveAccount(playerid)
{
    new query_string[512];
    format(query_string, sizeof(query_string),
        "UPDATE `accounts` SET `name` = '%s', `password_salt` = '%s', `password_hash` = '%s', `money` = %d, `level` = %d, `exp` = %d, `skin` = %d, `admin` = %d WHERE `name` = '%s'",
        PlayerInfo[playerid][pName], PlayerInfo[playerid][pSalt], PlayerInfo[playerid][pPasswordHash],
        PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pEXP], PlayerInfo[playerid][pSkin], PlayerInfo[playerid][pAdmin], PlayerInfo[playerid][pName]);

    mysql_tquery(sampbd, query_string, "", "");
    return 1;
}
stock CreateNewAccount(playerid, password[])
{
    new salt[16];
    format(salt, sizeof(salt), "salt_%d", playerid);
    new hash[65];
    SHA256_PassHash(password, salt, hash, sizeof(hash));
    strins(PlayerInfo[playerid][pSalt], salt, 0);
    strins(PlayerInfo[playerid][pPasswordHash], hash, 0);
    PlayerInfo[playerid][pLevel] = 1;
    PlayerInfo[playerid][pMoney] = 500;
    PlayerInfo[playerid][pAdmin] = 0;
    PlayerInfo[playerid][pSkin] = 230;
    new query_string[512];
    format(query_string, sizeof(query_string),
        "INSERT INTO `accounts` (`name`, `password_salt`, `password_hash`, `money`, `level`, `exp`, `skin`, `admin`)" \
        "VALUES ('%s', '%s', '%s', '%d', '%d', '%d', '%d', '%d')",
        PlayerInfo[playerid][pName], PlayerInfo[playerid][pSalt], PlayerInfo[playerid][pPasswordHash],
        PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pEXP],
        PlayerInfo[playerid][pSkin], PlayerInfo[playerid][pAdmin]);
    mysql_tquery(sampbd, query_string, "", "");
    GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);
    SetPlayerScore(playerid, PlayerInfo[playerid][pLevel]);
    SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
    SpawnPlayer(playerid);
    return 1;
}
///////////////////////////////////////////////
CMD:register(playerid, params[])
{
    if (IsPlayerLoggedIn[playerid]) return 1;
    if (strlen(params) == 0)
    {
        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Использование: /register <пароль>");
        return 1;
    }
    if (strlen(params) < 4)
    {
        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Пароль должен содержать минимум 4 символа.");
        return 1;
    }
    if (IsPlayerRegistered[playerid])
    {
        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} У вас уже есть аккаунт! Войдите через /login <пароль>.");
        return 1;
    }
    new player_name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, player_name, sizeof(player_name));
    strins(PlayerInfo[playerid][pName], player_name, 0);
    CreateNewAccount(playerid, params);
    IsPlayerRegistered[playerid] = true;
    IsPlayerLoggedIn[playerid] = true;
    SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Регистрация прошла успешно. Приятной игры на нашем проекте.");
    SpawnPlayer(playerid);
    return 1;
}
CMD:login(playerid, params[])
{
    if (IsPlayerLoggedIn[playerid]) return 1;
    if (strlen(params) == 0)
    {
        SendClientMessage(playerid, -1, "{808000}[SERVER]:{FFFFFF} Используйте: /login <пароль>]");
        return 1;
    }
    format(LoginPassword[playerid], MAX_PASS_LENGTH + 1, "%s", params);
    new player_name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, player_name, sizeof(player_name));
    new query[256];
    format(query, sizeof(query),
        "SELECT `id`, `name`, `password_salt`, `password_hash`, `money`, `level`, `exp` FROM `accounts` WHERE LOWER(`name`) = LOWER('%s') LIMIT 1",
        player_name);
    mysql_tquery(sampbd, query, "UploadPlayerAccount", "i", playerid);
    return 1;
}
CMD:givevehid(playerid, params[])
{
    new modelid;
    if (sscanf(params, "d", modelid))
    {
        SendClientMessage(playerid, -1, "Использование: /givevehid [ID модели транспорта]");
        return 0;
    }
    if (modelid < 400 || modelid > 611)
    {
        SendClientMessage(playerid, -1, "Неверный ID модели транспорта.");
        return 0;
    }
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    new vehicleid = CreateVehicle(modelid, x + 2.0, y, z, 0.0, 100, 0, -1);
    if (vehicleid == INVALID_VEHICLE_ID)
    {
        SendClientMessage(playerid, -1, "Ошибка при создании транспорта.");
        return 0;
    }
    PutPlayerInVehicle(playerid, vehicleid, -1);
    SendClientMessage(playerid, -1, "Транспорт создан и выдан вам.");
    return 1;
}
////////////////////////////////////////////////////
stock removeobj(playerid)
{
	RemoveBuildingForPlayer(playerid, 3744, 2193.2578, -2286.2891, 14.8125, 0.25);
	RemoveBuildingForPlayer(playerid, 3747, 2234.3906, -2244.8281, 14.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 3747, 2226.9688, -2252.1406, 14.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 3747, 2219.4219, -2259.5234, 14.8828, 0.25);
	RemoveBuildingForPlayer(playerid, 3747, 2212.0938, -2267.0703, 14.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 3747, 2204.6328, -2274.4141, 14.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 3578, 2165.0703, -2288.9688, 13.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 3574, 2193.2578, -2286.2891, 14.8125, 0.25);
	RemoveBuildingForPlayer(playerid, 3630, 2217.5859, -2284.6641, 15.2344, 0.25);
	RemoveBuildingForPlayer(playerid, 5171, 2124.9453, -2275.4531, 20.1406, 0.25);
	RemoveBuildingForPlayer(playerid, 3569, 2204.6328, -2274.4141, 14.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 3569, 2212.0938, -2267.0703, 14.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 3631, 2149.1406, -2266.9063, 12.8750, 0.25);
	RemoveBuildingForPlayer(playerid, 3569, 2219.4219, -2259.5234, 14.8828, 0.25);
	RemoveBuildingForPlayer(playerid, 3633, 2142.9141, -2256.3359, 13.9297, 0.25);
	RemoveBuildingForPlayer(playerid, 3632, 2144.2969, -2258.1484, 13.9297, 0.25);
	RemoveBuildingForPlayer(playerid, 3631, 2142.3047, -2255.8984, 12.8750, 0.25);
	RemoveBuildingForPlayer(playerid, 5262, 2152.7109, -2256.7813, 15.2109, 0.25);
	RemoveBuildingForPlayer(playerid, 3633, 2158.0078, -2257.2656, 16.2188, 0.25);
	RemoveBuildingForPlayer(playerid, 3633, 2167.6641, -2256.7813, 12.7500, 0.25);
	RemoveBuildingForPlayer(playerid, 3633, 2167.6641, -2256.7813, 13.7109, 0.25);
	RemoveBuildingForPlayer(playerid, 3633, 2167.6641, -2256.7813, 14.6719, 0.25);
	RemoveBuildingForPlayer(playerid, 3632, 2167.8047, -2257.3516, 16.3828, 0.25);
	RemoveBuildingForPlayer(playerid, 3632, 2167.1719, -2257.1250, 16.4063, 0.25);
	RemoveBuildingForPlayer(playerid, 3577, 2170.0781, -2257.6641, 16.0391, 0.25);
	RemoveBuildingForPlayer(playerid, 3632, 2169.3516, -2258.0703, 17.2422, 0.25);
	RemoveBuildingForPlayer(playerid, 3632, 2168.8281, -2257.5234, 17.2500, 0.25);
	RemoveBuildingForPlayer(playerid, 3633, 2140.3828, -2254.1016, 13.9297, 0.25);
	RemoveBuildingForPlayer(playerid, 3632, 2150.6641, -2251.5547, 12.7656, 0.25);
	RemoveBuildingForPlayer(playerid, 3632, 2150.2813, -2250.8516, 12.7656, 0.25);
	RemoveBuildingForPlayer(playerid, 3633, 2150.6953, -2252.9141, 16.2344, 0.25);
	RemoveBuildingForPlayer(playerid, 3632, 2149.8125, -2253.3672, 16.2344, 0.25);
	RemoveBuildingForPlayer(playerid, 3633, 2153.7734, -2253.0859, 14.2031, 0.25);
	RemoveBuildingForPlayer(playerid, 3633, 2154.5078, -2254.4766, 14.2109, 0.25);
	RemoveBuildingForPlayer(playerid, 3632, 2158.5703, -2251.0156, 15.8125, 0.25);
	RemoveBuildingForPlayer(playerid, 3632, 2158.0469, -2250.5078, 15.8125, 0.25);
	RemoveBuildingForPlayer(playerid, 5132, 2163.2891, -2251.6094, 14.1406, 0.25);
	RemoveBuildingForPlayer(playerid, 5259, 2168.8438, -2246.7813, 13.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 3569, 2226.9688, -2252.1406, 14.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 3569, 2234.3906, -2244.8281, 14.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 3578, 2235.1641, -2231.8516, 13.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 3632, 2245.1172, -2260.7031, 15.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 3633, 2243.7344, -2258.8906, 15.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 3633, 2241.2031, -2256.6563, 15.3359, 0.25);
	CreateObject(3585, 2207.70996, -2307.77930, 14.15625,   3.14159, 0.00000, 2.35619);
	CreateObject(3585, 2215.81934, -2306.18359, 14.15625,   3.14159, 0.00000, 2.35619);
	CreateObject(3585, 2215.81934, -2306.18359, 14.15625,   3.14159, 0.00000, 2.35619);
	CreateObject(3585, 2215.81934, -2306.18359, 14.15625,   3.14159, 0.00000, 2.35619);
	CreateObject(3585, 2215.81934, -2306.18359, 14.15625,   3.14159, 0.00000, 2.35619);
	CreateObject(3585, 2215.81934, -2306.18359, 14.15625,   3.14159, 0.00000, 2.35619);
	CreateObject(3585, 2215.81934, -2306.18359, 14.15625,   3.14159, 0.00000, 2.35619);
	CreateObject(3585, 2215.81934, -2306.18359, 14.15625,   3.14159, 0.00000, 2.35619);
	CreateObject(3585, 2215.81934, -2306.18359, 14.15625,   3.14159, 0.00000, 2.35619);
	CreateObject(3585, 2216.26099, -2300.03662, 14.15625,   3.14159, 0.00000, 2.35619);
	CreateObject(3585, 2203.51514, -2318.36328, 14.15625,   3.14159, 0.00000, 2.35619);
	CreateObject(3585, 2180.26367, -2324.03516, 13.80951,   -91.00000, 0.00000, -16.00000);
	CreateObject(5262, 2150.44824, -2243.60107, 15.16190,   0.00000, 0.00000, -45.00000);
	CreateObject(3631, 2155.87402, -2248.42944, 12.84780,   0.00000, 0.00000, 45.00000);
	CreateObject(3631, 2155.87402, -2248.42944, 13.98851,   0.00000, 0.00000, 45.00000);
	CreateObject(3631, 2155.87402, -2248.42944, 15.10469,   0.00000, 0.00000, 45.00000);
	CreateObject(3577, 2157.99561, -2240.36938, 13.00349,   0.00000, 0.00000, 0.00000);
	CreateObject(3577, 2162.76831, -2238.51855, 13.00350,   0.00000, 0.00000, 62.00000);
	CreateObject(3577, 2160.69556, -2244.45435, 13.00350,   0.00000, 0.00000, 33.00000);
	CreateObject(3631, 2144.69556, -2251.72095, 12.87500,   356.85840, 0.00000, -2.35619);
	CreateObject(3577, 2157.99561, -2240.36938, 14.50380,   0.00000, 0.00000, 33.00000);
	CreateObject(3577, 2160.69556, -2244.45435, 14.50310,   0.00000, 0.00000, 35.00000);
	CreateObject(3577, 2162.76831, -2238.51855, 14.50387,   0.00000, 0.00000, 62.00000);
	CreateObject(3577, 2162.76831, -2238.51855, 15.98700,   0.00000, 0.00000, 47.00000);
	CreateObject(5261, 2136.32031, -2254.95239, 14.46520,   0.00000, 0.00000, 45.00000);
	CreateObject(5261, 2138.41187, -2257.11719, 14.46520,   0.00000, 0.00000, 45.00000);
	CreateObject(5261, 2140.52197, -2259.31274, 14.46520,   0.00000, 0.00000, 45.00000);
	CreateObject(3578, 2177.77588, -2271.01587, 13.20700,   0.00000, 0.00000, 45.00000);
	CreateObject(1536, 2118.10791, -2274.58521, 19.65850,   0.00000, 0.00000, -45.00000);
	CreateObject(1998, 2126.42358, -2278.44751, 19.66110,   0.00000, 0.00000, -136.00000);
	CreateObject(2008, 2129.98193, -2276.51147, 19.62546,   0.00000, 0.00000, -136.00000);
	CreateObject(2008, 2128.14502, -2274.66553, 19.62546,   0.00000, 0.00000, -136.00000);
	CreateObject(1998, 2123.76489, -2275.83521, 19.66110,   0.00000, 0.00000, -136.00000);
	CreateObject(2008, 2126.26196, -2272.82544, 19.62546,   0.00000, 0.00000, -136.00000);
	CreateObject(1715, 2128.89111, -2276.25171, 19.64374,   0.00000, 0.00000, 0.00000);
	CreateObject(1715, 2127.22632, -2274.17676, 19.64370,   0.00000, 0.00000, 55.00000);
	CreateObject(1715, 2125.41064, -2273.02124, 19.64370,   0.00000, 0.00000, 55.00000);
	CreateObject(1715, 2125.95044, -2279.41602, 19.64370,   0.00000, 0.00000, 55.00000);
	CreateObject(1715, 2122.98608, -2276.69287, 19.64370,   0.00000, 0.00000, 105.00000);
	CreateObject(1684, 2189.73486, -2252.07373, 13.95973,   0.00000, 0.00000, 45.00000);
	CreateObject(3578, 2193.23145, -2256.62012, 13.20700,   0.00000, 0.00000, 45.00000);
}
