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
//////////////////

#define SCM                         SendClientMessage
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

#define FERMA_BAG_X -322.0230
#define FERMA_BAG_Y -1492.3535
#define FERMA_BAG_Z 12.9880
#define CHECKPOINT_RADIUS 3.0

#define GROVE_INTERIOR 3
#define FRACTION_GROVE 1
#define MAX_GROVE_VEHICLES 10
#define KEY_ENTER_VEHICLE 0x00000100

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
    pAdmin,
    pFraction,
    pfSkin,
    pFractionRank,
    pFractionLeader
}
new PlayerInfo[MAX_PLAYERS][pInfo];

// Временные переменные для работ (замена медленным PVar)
enum pTempJobInfo
{
    bool:tJobGruz,
    tGruzSkin,
    bool:tGruzBagTaken,
    Float:tGruzDrop[3],

    bool:tJobFerma,
    tFermaSkin,
    bool:tFermaBagTaken,
    bool:tFermaInstrument,
    Float:tFermaDrop[3],

    tJobSalary
}
new TempJob[MAX_PLAYERS][pTempJobInfo];

new bool:IsPlayerLoggedIn[MAX_PLAYERS];
new bool:IsPlayerRegistered[MAX_PLAYERS];

////////////////////
new Float:groveEnterX = 2495.5171, Float:groveEnterY = -1691.0331, Float:groveEnterZ = 14.7656;
new Float:groveEnterIX = 2496.05, Float:groveEnterIY = -1695.23, Float:groveEnterIZ = 1014.74;
new Float:groveExitX = 2495.2275, Float:groveExitY = -1688.8795, Float:groveExitZ = 14.0820;
new Float:groveExitIX = 2495.9414, Float:groveExitIY = -1692.0834, Float:groveExitIZ = 1014.7422;

new const Float:VIRTUAL_SPAWN[4] = {1035.9910,1019.4274,11.0000,114.6810};
new const Float:NORMAL_SPAWN[4] = {1479.8516,-1725.2273,13.5469,359.4516};

new infoPickup[2];
new bikePickup;
new Float:BikePickupPos[3] = {1477.6136,-1672.9910,14.0469};

new PlayerBike[MAX_PLAYERS];
new PlayerBikeTimer[MAX_PLAYERS];

new loadergruz;
new Float:GruzDropPoints[3][3] = {
    {2168.1172, -2262.8401, 13.3052},
    {2158.4097, -2232.5789, 13.3071},
    {2144.2583, -2254.5845, 13.2990}
};

new loaderferma, loaderfermai;
new Float:FermaDropPoints[10][3] = {
    {-284.2612, -1477.4885, 6.0660}, {-282.0764, -1494.9863, 6.4665},
    {-281.8070, -1517.5317, 6.3004}, {-280.8591, -1539.6947, 6.0296},
    {-259.9134, -1547.1987, 3.9296}, {-250.7696, -1532.2198, 5.9142},
    {-247.4035, -1510.4563, 6.7786}, {-230.2738, -1499.3269, 7.8300},
    {-220.0731, -1477.5497, 7.2824}, {-233.4813, -1470.4108, 5.0051}
};

new grove[2];
new groveVehicles[MAX_GROVE_VEHICLES];
new Text:LOGO;

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
    Create3DTextLabel("Аренда велосипеда", 0xFFFFFFFF, BikePickupPos[0], BikePickupPos[1], BikePickupPos[2] + 1.0, 20.0, 9999, 0);

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        PlayerBike[i] = INVALID_VEHICLE_ID;
        PlayerBikeTimer[i] = INVALID_TIMER;
    }

    loadergruz = CreatePickup(1275, 2, 2193.7202, -2251.5547, 13.5469, 0);
    loaderferma = CreatePickup(1275, 2, -318.3027,-1517.6577,12.7666, 0);
    loaderfermai = CreatePickup(2228, 2, -318.1532,-1506.5642,12.5356, 0);

    grove[0] = CreatePickup(1279, 23, groveEnterX, groveEnterY, groveEnterZ, 0);
    grove[1] = CreatePickup(1279, 23, groveExitIX, groveExitIY, groveExitIZ, 100);

    groveVehicles[0] = CreateVehicle(492,2505.8438,-1678.9124,13.2429, 320.1924, 229, 229, 100);
    groveVehicles[1] = CreateVehicle(400,2509.5388,-1671.9961,13.4942, 345.3892, 229, 229, 100);
    groveVehicles[2] = CreateVehicle(422,2518.7510,-1666.3563,14.3375, 92.1370, 229, 229, 100);
    groveVehicles[3] = CreateVehicle(492,2474.8933,-1680.5519,13.1374, 53.1496, 229, 229, 100);
    groveVehicles[4] = CreateVehicle(400,2478.1575,-1653.7532,13.4847, 89.8375, 229, 229, 100);
    groveVehicles[5] = CreateVehicle(413,2463.2407,-1677.9370,13.6048, 31.3153, 229, 229, 100);

    LOGO = TextDrawCreate(549.000000, 9.625000, "0.47 Project");
    TextDrawLetterSize(LOGO, 0.321000, 1.109999);
    TextDrawAlignment(LOGO, 1);
    TextDrawSetShadow(LOGO, 1);
    TextDrawSetOutline(LOGO, 0);
    TextDrawBackgroundColor(LOGO, 51);
    TextDrawFont(LOGO, 3);
    TextDrawSetProportional(LOGO, 1);
    SetTimer("ChangeColorEffect", 5000, true);

    return 1;
}

public OnGameModeExit()
{
    foreach(new i : Player) SaveAccount(i);
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

    ResetPlayerJobInfo(playerid); // Сбрасываем временные переменные при коннекте

    TextDrawShowForPlayer(playerid, LOGO);
    SetPlayerVirtualWorld(playerid, 9999);
    SetPlayerPos(playerid, VIRTUAL_SPAWN[0], VIRTUAL_SPAWN[1], VIRTUAL_SPAWN[2]);
    SetPlayerFacingAngle(playerid, VIRTUAL_SPAWN[3]);
    SetPlayerSkin(playerid, 3);

    new player_name[MAX_PLAYER_NAME], query[256];
    GetPlayerName(playerid, player_name, sizeof(player_name));

    // Безопасное форматирование запроса с %e
    mysql_format(sampbd, query, sizeof(query), "SELECT `id` FROM `accounts` WHERE `name` = '%e' LIMIT 1", player_name);
    mysql_tquery(sampbd, query, "find_table", "i", playerid);

    SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Пожалуйста, зарегистрируйтесь (/register) или войдите (/login).");
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

    ResetPlayerJobInfo(playerid); // Очищаем память работ

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
                SCM(playerid, -1, "{808000}[SERVER]:{FF0000} У вас уже есть арендованный велосипед.");
                return 1;
            }
            new vehicle = CreateVehicle(BIKE_MODEL, BikePickupPos[0] + 2.0, BikePickupPos[1] + 1.5, BikePickupPos[2] + 1.0, 0.0, -1, -1, -1, 0);
            if (vehicle == INVALID_VEHICLE_ID)
            {
                SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Не удалось создать велосипед. Попробуйте позже.");
                return 1;
            }
            PlayerBike[playerid] = vehicle;
        }
        else SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Аренда отменена.");
        return 1;
    }
    return 0;
}

public OnPlayerText(playerid, text[])
{
    if (!IsPlayerLoggedIn[playerid])
    {
        SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Вы не можете писать в чат, пока не войдёте в аккаунт.");
        return 0;
    }

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new msg[144], player_name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, player_name, sizeof(player_name));
    format(msg, sizeof(msg), "%s: %s", player_name, text);

    // Оптимизированный цикл локального чата
    foreach(new target : Player)
    {
        if (!IsPlayerLoggedIn[target]) continue;

        // Быстрая проверка на виртуальный мир/интерьер (опционально, но хорошая практика)
        if (GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(target)) continue;

        if (GetPlayerDistanceFromPoint(target, x, y, z) <= LOCAL_CHAT_RADIUS)
        {
            SendClientMessage(target, 0xFFFFFFFF, msg);
        }
    }
    return 0;
}

// ПЕРЕХВАТЧИК КОМАНД (Pawn.CMD). Заменяет OnPlayerCommandText.
public PC_OnPlayerCommandReceived(playerid, cmd[], params[])
{
    if (!IsPlayerLoggedIn[playerid])
    {
        // Разрешаем только логин и регу
        if (strcmp(cmd, "login", true) == 0 || strcmp(cmd, "register", true) == 0) return 1;

        SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Сначала зарегистрируйтесь или войдите.");
        return 0; // Блокируем выполнение остальных команд
    }
    return 1; // Разрешаем выполнение
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
    foreach(new i : Player)
    {
        if (i == playerid) continue;
        if (PlayerBike[i] == vehicleid)
        {
            RemovePlayerFromVehicle(playerid);
            return 0;
        }
    }
    if (PlayerBike[playerid] == vehicleid && PlayerBikeTimer[playerid] != INVALID_TIMER)
    {
        KillTimer(PlayerBikeTimer[playerid]);
        PlayerBikeTimer[playerid] = INVALID_TIMER;
    }
    if (IsFractionVehicle(vehicleid, FRACTION_GROVE) && PlayerInfo[playerid][pFraction] != FRACTION_GROVE)
    {
        SCM(playerid, 0xFF0000FF, "Вы не можете садиться в эту машину, она принадлежит Grove Street.");
        RemovePlayerFromVehicle(playerid);
        return 0;
    }
    return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
    if (PlayerBike[playerid] == vehicleid && PlayerBikeTimer[playerid] == INVALID_TIMER)
    {
        PlayerBikeTimer[playerid] = SetTimerEx("ReturnBike", RENT_DURATION, false, "i", playerid);
    }
    return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
    // ГРУЗЧИК - ВЗЯТИЕ
    if (IsPlayerInRangeOfPoint(playerid, 2.0, GRUZ_BAG_X, GRUZ_BAG_Y, GRUZ_BAG_Z) && TempJob[playerid][tJobGruz] && !TempJob[playerid][tGruzBagTaken])
    {
        if (!IsPlayerInAnyVehicle(playerid))
        {
            TempJob[playerid][tGruzBagTaken] = true;
            GruzRand(playerid);
            ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.1, 0, 1, 1, 1, 1);
            SetPlayerAttachedObject(playerid, 2, 2060, 5, 0.01, 0.1, 0.2, 100, 10, 85);
            SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Вы взяли мешок. Отнесите его на склад.");
            SetPlayerCheckpoint(playerid, TempJob[playerid][tGruzDrop][0], TempJob[playerid][tGruzDrop][1], TempJob[playerid][tGruzDrop][2], 2.0);
        }
        else SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Нельзя брать мешок в транспорте!");
    }
    // ГРУЗЧИК - СДАЧА
    else if (IsPlayerInRangeOfPoint(playerid, 2.0, TempJob[playerid][tGruzDrop][0], TempJob[playerid][tGruzDrop][1], TempJob[playerid][tGruzDrop][2]) && TempJob[playerid][tGruzBagTaken])
    {
        if (!IsPlayerInAnyVehicle(playerid))
        {
            TempJob[playerid][tJobSalary] += 50;
            RemovePlayerAttachedObject(playerid, 2);
            TempJob[playerid][tGruzBagTaken] = false;
            SetPlayerCheckpoint(playerid, GRUZ_BAG_X, GRUZ_BAG_Y, GRUZ_BAG_Z, 2.0);
            ApplyAnimation(playerid, "PED", "IDLE_tired", 4.1, 0, 1, 1, 0, 1);
        }
        else SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Нельзя сдавать мешок в транспорте!");
    }
	// ФЕРМЕР - ВЗЯТИЕ
    if (IsPlayerInRangeOfPoint(playerid, 2.0, TempJob[playerid][tFermaDrop][0], TempJob[playerid][tFermaDrop][1], TempJob[playerid][tFermaDrop][2]) && TempJob[playerid][tJobFerma] && TempJob[playerid][tFermaInstrument] && !TempJob[playerid][tFermaBagTaken])
    {
        if (!IsPlayerInAnyVehicle(playerid))
        {
            // Морозим игрока, чтобы он не бегал во время выкапывания куста
            TogglePlayerControllable(playerid, 0);

            // Включаем анимацию посадки/выкапывания
            ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 0, 1);

            // Запускаем таймер на 1.2 секунды
            SetTimerEx("GiveFermaBush", 1200, false, "i", playerid);
        }
        else SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Нельзя собирать урожай в транспорте!");
    }
	// ФЕРМЕР - СДАЧА
    else if (IsPlayerInRangeOfPoint(playerid, 2.0, FERMA_BAG_X, FERMA_BAG_Y, FERMA_BAG_Z) && TempJob[playerid][tFermaBagTaken])
    {
        if (!IsPlayerInAnyVehicle(playerid))
        {
            TempJob[playerid][tJobSalary] += 50;
            TempJob[playerid][tFermaBagTaken] = false;

            RemovePlayerAttachedObject(playerid, 2);
            ClearAnimations(playerid); // <--- ВОЗВРАЩАЕМ РУКИ В НОРМУ

            FermaRand(playerid);
            SetPlayerCheckpoint(playerid, TempJob[playerid][tFermaDrop][0], TempJob[playerid][tFermaDrop][1], TempJob[playerid][tFermaDrop][2], 2.0);
            SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Готово! Идите к следующему кусту.");

            ApplyAnimation(playerid, "PED", "IDLE_tired", 4.1, 0, 1, 1, 0, 1, 1);
        }
        else SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Нельзя сдавать куст в транспорте!");
    }
    return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
    if (pickupid == infoPickup[0])
    {
        ShowPlayerDialog(playerid, DIALOG_INFO, DIALOG_STYLE_MSGBOX, "Информация", "Здравствуйте, вы на проекте 0.47 Project.\r\nИсходный код: https://github.com/GADGETNiK/0.47-projectrnrnНажмите ОК для закрытия.", "ОК", "");
        return 1;
    }
    if (pickupid == infoPickup[1])
    {
        ShowPlayerDialog(playerid, DIALOG_INFO_2, DIALOG_STYLE_MSGBOX, "Информация", "Здравствуйте, вы на проекте 0.47 Project.\r\nВы сейчас находитесь в обычном мире, можете начинать играть.\r\n\r\nНажмите ОК для закрытия.", "ОК", "");
        return 1;
    }
    if (pickupid == bikePickup)
    {
        if (!IsPlayerLoggedIn[playerid]) return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Аренда велосипеда доступна только залогиненным.");
        if (PlayerBike[playerid] != INVALID_VEHICLE_ID) return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Вы уже арендовали велосипед.");
        ShowPlayerDialog(playerid, DIALOG_RENT_BIKE, DIALOG_STYLE_MSGBOX, "Аренда велосипеда", "Хотите арендовать велосипед?\r\nСтоимость: бесплатно", "Арендовать", "Отмена");
        return 1;
    }
    if (pickupid == loadergruz)
    {
        if (!TempJob[playerid][tJobGruz])
        {
            TempJob[playerid][tGruzSkin] = 260;
            SetPlayerSkin(playerid, TempJob[playerid][tGruzSkin]);
            TempJob[playerid][tJobGruz] = true;
            TempJob[playerid][tJobSalary] = 0;
            SetPlayerCheckpoint(playerid, GRUZ_BAG_X, GRUZ_BAG_Y, GRUZ_BAG_Z, 2.0);
            SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Вы устроились грузчиком. Идите на красный маркер.");
        }
        else
        {
            SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Вы уволились.");
            GivePlayerCash(playerid, TempJob[playerid][tJobSalary]);
            DisablePlayerCheckpoint(playerid);
            SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
            ResetPlayerJobInfo(playerid); // Очистка переменных работы
        }
        return 1;
    }
    if (pickupid == loaderferma)
    {
        if (!TempJob[playerid][tJobFerma])
        {
            TempJob[playerid][tFermaSkin] = 158;
            SetPlayerSkin(playerid, TempJob[playerid][tFermaSkin]);
            TempJob[playerid][tJobFerma] = true;
            TempJob[playerid][tJobSalary] = 0;
            SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Вы устроились фермером. Возьмите инструмент.");
        }
        else
        {
            SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Вы уволились.");
            GivePlayerCash(playerid, TempJob[playerid][tJobSalary]);
            DisablePlayerCheckpoint(playerid);
            SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
            ResetPlayerJobInfo(playerid);
        }
        return 1;
    }
    if (pickupid == loaderfermai)
    {
        if (TempJob[playerid][tJobFerma] && !TempJob[playerid][tFermaInstrument])
        {
            TempJob[playerid][tFermaBagTaken] = false;
            TempJob[playerid][tFermaInstrument] = true;
            SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Инструмент взят, идите за кустом.");
            FermaRand(playerid);
            SetPlayerCheckpoint(playerid, TempJob[playerid][tFermaDrop][0], TempJob[playerid][tFermaDrop][1], TempJob[playerid][tFermaDrop][2], 2.0);
        }
        return 1;
    }
    if (pickupid == grove[0])
    {
        SetPlayerPos(playerid, groveEnterIX, groveEnterIY, groveEnterIZ);
        SetPlayerInterior(playerid, GROVE_INTERIOR);
        SetPlayerVirtualWorld(playerid, 100);
    }
    if (pickupid == grove[1])
    {
        SetPlayerPos(playerid, groveExitX, groveExitY, groveExitZ);
        SetPlayerInterior(playerid, 0);
        SetPlayerVirtualWorld(playerid, 0);
    }
    return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    // Если игрок нажал прыжок или удар
    if (((newkeys & KEY_JUMP) && !(oldkeys & KEY_JUMP)) || (newkeys & KEY_FIRE))
    {
        // Если это грузчик
        if (TempJob[playerid][tGruzBagTaken])
        {
            SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Вы уронили мешок!");
            RemovePlayerAttachedObject(playerid, 2);
            TempJob[playerid][tGruzBagTaken] = false;
            SetPlayerCheckpoint(playerid, GRUZ_BAG_X, GRUZ_BAG_Y, GRUZ_BAG_Z, 2.0);
            ApplyAnimation(playerid, "PED", "IDLE_tired", 4.1, 0, 1, 1, 0, 1);
        }
        // Если это фермер
        else if (TempJob[playerid][tFermaBagTaken])
        {
            SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Вы уронили куст!");
            RemovePlayerAttachedObject(playerid, 2);
            TempJob[playerid][tFermaBagTaken] = false;

            // Возвращаем чекпоинт обратно к тому кусту, который он не донес
            SetPlayerCheckpoint(playerid, TempJob[playerid][tFermaDrop][0], TempJob[playerid][tFermaDrop][1], TempJob[playerid][tFermaDrop][2], 2.0);
            ApplyAnimation(playerid, "PED", "IDLE_tired", 4.1, 0, 1, 1, 0, 1);
        }
    }
    return 1;
}

public OnPlayerSpawn(playerid)
{
    PreloadAnimLib(playerid, "CARRY");
    PreloadAnimLib(playerid, "BOMBER");
	if (!IsPlayerLoggedIn[playerid])
    {
        SetPlayerVirtualWorld(playerid, 9999);
        SetPlayerPos(playerid, VIRTUAL_SPAWN[0], VIRTUAL_SPAWN[1], VIRTUAL_SPAWN[2]);
        SetPlayerFacingAngle(playerid, VIRTUAL_SPAWN[3]);
        SetPlayerSkin(playerid, 3);
        SetCameraBehindPlayer(playerid);
    }
    else
    {
        SetPlayerVirtualWorld(playerid, 0);
        SetPlayerPos(playerid, NORMAL_SPAWN[0], NORMAL_SPAWN[1], NORMAL_SPAWN[2]);
        SetPlayerFacingAngle(playerid, NORMAL_SPAWN[3]);
        SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
        SetCameraBehindPlayer(playerid);
    }
    return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    if (newstate == PLAYER_STATE_DRIVER)
    {
        new vehicleid = GetPlayerVehicleID(playerid);
        foreach(new i : Player)
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
		if (TempJob[playerid][tGruzBagTaken] || TempJob[playerid][tFermaBagTaken])
        {
            SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Вас уволили.{FF0000} Причина: Попытка сесть в транспорт с грузом/кустом.");
            RemovePlayerAttachedObject(playerid, 2); // Убираем объект из рук
            DisablePlayerCheckpoint(playerid);
            SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
            ResetPlayerJobInfo(playerid); // Очищаем данные о работе
            return 0;
        }

        new vehicleid = GetPlayerVehicleID(playerid);
        if (IsFractionVehicle(vehicleid, FRACTION_GROVE) && PlayerInfo[playerid][pFraction] != FRACTION_GROVE)
        {
            SCM(playerid, 0xFF0000FF, "Вы не можете садиться в эту машину, она принадлежит Grove Street.");
            RemovePlayerFromVehicle(playerid);
            return 0;
        }
    }
    return 1;
}

///////////////////// СТОКИ И ФУНКЦИИ /////////////////////
forward GiveFermaBush(playerid);
public GiveFermaBush(playerid)
{
    // Размораживаем игрока
    TogglePlayerControllable(playerid, 1);

    TempJob[playerid][tFermaBagTaken] = true;
    SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Вы собрали куст, отнесите его на склад.");
    SetPlayerCheckpoint(playerid, FERMA_BAG_X, FERMA_BAG_Y, FERMA_BAG_Z, 2.0);

    // Выдаем объект в левую руку
    SetPlayerAttachedObject(playerid, 2, 19473, 5, 0.15, 0.05, 0.0, -90.0, 0.0, 0.0);

    // Применяем хак с анимацией CARRY.
    // time = 1 (в конце) замораживает руки, но позволяет ногам бегать!
    ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.1, 0, 1, 1, 1, 1, 1);
}
forward DelayedKick(playerid);
public DelayedKick(playerid)
{
    Kick(playerid);
    return 1;
}
forward PC_OnPlayerCommandReceived(playerid, cmd[], params[]);
stock ResetPlayerJobInfo(playerid)
{
    TempJob[playerid][tJobGruz] = false;
    TempJob[playerid][tGruzBagTaken] = false;
    TempJob[playerid][tGruzSkin] = 0;

    TempJob[playerid][tJobFerma] = false;
    TempJob[playerid][tFermaBagTaken] = false;
    TempJob[playerid][tFermaInstrument] = false;
    TempJob[playerid][tFermaSkin] = 0;

    TempJob[playerid][tJobSalary] = 0;
}

stock IsFractionVehicle(vehicleid, fractionid)
{
    if (fractionid == FRACTION_GROVE)
    {
        for (new i = 0; i < MAX_GROVE_VEHICLES; i++)
        {
            if (groveVehicles[i] == vehicleid) return 1;
        }
    }
    return 0;
}

forward ReturnBike(playerid);
public ReturnBike(playerid)
{
    if (PlayerBike[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(PlayerBike[playerid]);
        PlayerBike[playerid] = INVALID_VEHICLE_ID;
        SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Время аренды велосипеда истекло. Велосипед возвращён.");
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
    new idx = random(3);
    TempJob[playerid][tGruzDrop][0] = GruzDropPoints[idx][0];
    TempJob[playerid][tGruzDrop][1] = GruzDropPoints[idx][1];
    TempJob[playerid][tGruzDrop][2] = GruzDropPoints[idx][2];
}

stock FermaRand(playerid)
{
    new idx = random(10);
    TempJob[playerid][tFermaDrop][0] = FermaDropPoints[idx][0];
    TempJob[playerid][tFermaDrop][1] = FermaDropPoints[idx][1];
    TempJob[playerid][tFermaDrop][2] = FermaDropPoints[idx][2];
}
stock PreloadAnimLib(playerid, animlib[])
{
    ApplyAnimation(playerid, animlib, "null", 0.0, 0, 0, 0, 0, 0, 1);
}
forward ChangeColorEffect();
public ChangeColorEffect()
{
    new color = (random(256) << 24) | (random(256) << 16) | (random(256) << 8) | 0xFF;
    TextDrawColor(LOGO, color);
    return 1;
}

/////////////////// MYSQL И АВТОРИЗАЦИЯ ///////////////////
forward find_table(playerid);
public find_table(playerid)
{
    new rows;
    cache_get_row_count(rows);
    if (!rows)
    {
        IsPlayerRegistered[playerid] = false;
        SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Аккаунт не найден. Зарегистрируйтесь: /register <пароль>.");
    }
    else
    {
        IsPlayerRegistered[playerid] = true;
        SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Аккаунт найден. Авторизуйтесь: /login <пароль>.");

        new player_name[MAX_PLAYER_NAME], query[256];
        GetPlayerName(playerid, player_name, sizeof(player_name));
        mysql_format(sampbd, query, sizeof(query), "SELECT * FROM `accounts` WHERE `name` = '%e' LIMIT 1", player_name);
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
        SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Неверный пароль.");
        return false;
    }
    IsPlayerLoggedIn[playerid] = true;
    SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Авторизация прошла успешно.");
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
    if (cache_num_rows() == 0) return SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Аккаунт не найден.");

    cache_get_value_name_int(0, "id", PlayerInfo[playerid][pID]);
    cache_get_value_name(0, "name", PlayerInfo[playerid][pName]);
    cache_get_value_name(0, "password_salt", PlayerInfo[playerid][pSalt]);
    cache_get_value_name(0, "password_hash", PlayerInfo[playerid][pPasswordHash]);
    cache_get_value_name_int(0, "money", PlayerInfo[playerid][pMoney]);
    cache_get_value_name_int(0, "level", PlayerInfo[playerid][pLevel]);
    cache_get_value_name_int(0, "exp", PlayerInfo[playerid][pEXP]);
    cache_get_value_name_int(0, "skin", PlayerInfo[playerid][pSkin]);
    cache_get_value_name_int(0, "admin", PlayerInfo[playerid][pAdmin]);
    cache_get_value_name_int(0, "fraction", PlayerInfo[playerid][pFraction]);
    cache_get_value_name_int(0, "fskin", PlayerInfo[playerid][pfSkin]);
    cache_get_value_name_int(0, "frank", PlayerInfo[playerid][pFractionRank]);
    cache_get_value_name_int(0, "fleader", PlayerInfo[playerid][pFractionLeader]);
    return CheckLoginPassword(playerid);
}

stock SaveAccount(playerid)
{
    new query[512];
    mysql_format(sampbd, query, sizeof(query),
        "UPDATE `accounts` SET `password_salt` = '%e', `password_hash` = '%e', `money` = %d, `level` = %d, `exp` = %d, `skin` = %d, `admin` = %d, `fraction` = %d, `fskin` = %d, `frank` = %d, `fleader` = %d WHERE `name` = '%e'",
        PlayerInfo[playerid][pSalt], PlayerInfo[playerid][pPasswordHash],
        PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pEXP], PlayerInfo[playerid][pSkin], PlayerInfo[playerid][pAdmin], PlayerInfo[playerid][pFraction], PlayerInfo[playerid][pfSkin],
        PlayerInfo[playerid][pFractionRank], PlayerInfo[playerid][pFractionLeader], PlayerInfo[playerid][pName]);

    mysql_tquery(sampbd, query, "", "");
    return 1;
}

stock CreateNewAccount(playerid, password[])
{
    new salt[16], hash[65], query[512];
    format(salt, sizeof(salt), "salt_%d", playerid);
    SHA256_PassHash(password, salt, hash, sizeof(hash));

    strins(PlayerInfo[playerid][pSalt], salt, 0);
    strins(PlayerInfo[playerid][pPasswordHash], hash, 0);

    PlayerInfo[playerid][pLevel] = 1;
    PlayerInfo[playerid][pMoney] = 500;
    PlayerInfo[playerid][pAdmin] = 0;
    PlayerInfo[playerid][pSkin] = 230;
    PlayerInfo[playerid][pFraction] = 0;

    mysql_format(sampbd, query, sizeof(query),
        "INSERT INTO `accounts` (`name`, `password_salt`, `password_hash`, `money`, `level`, `exp`, `skin`, `admin`, `fraction`) VALUES ('%e', '%e', '%e', %d, %d, %d, %d, %d, %d)",
        PlayerInfo[playerid][pName], PlayerInfo[playerid][pSalt], PlayerInfo[playerid][pPasswordHash],
        PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pEXP],
        PlayerInfo[playerid][pSkin], PlayerInfo[playerid][pAdmin], PlayerInfo[playerid][pFraction]);

    mysql_tquery(sampbd, query, "", "");

    GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);
    SetPlayerScore(playerid, PlayerInfo[playerid][pLevel]);
    SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
    SpawnPlayer(playerid);
    return 1;
}

///////////////////// КОМАНДЫ /////////////////////

CMD:register(playerid, params[])
{
    if (IsPlayerLoggedIn[playerid]) return 1;
    if (strlen(params) == 0) return SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Использование: /register <пароль>");
    if (strlen(params) < 4) return SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Пароль должен содержать минимум 4 символа.");
    if (IsPlayerRegistered[playerid]) return SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} У вас уже есть аккаунт! /login <пароль>");

    GetPlayerName(playerid, PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
    CreateNewAccount(playerid, params);

    IsPlayerRegistered[playerid] = true;
    IsPlayerLoggedIn[playerid] = true;
    SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Регистрация успешна.");
    return 1;
}

CMD:login(playerid, params[])
{
    if (IsPlayerLoggedIn[playerid]) return 1;
    if (strlen(params) == 0) return SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Используйте: /login <пароль>");

    format(LoginPassword[playerid], MAX_PASS_LENGTH + 1, "%s", params);

    new player_name[MAX_PLAYER_NAME], query[256];
    GetPlayerName(playerid, player_name, sizeof(player_name));
    mysql_format(sampbd, query, sizeof(query), "SELECT * FROM `accounts` WHERE `name` = '%e' LIMIT 1", player_name);
    mysql_tquery(sampbd, query, "UploadPlayerAccount", "i", playerid);
    return 1;
}
CMD:killme(playerid)
{
    SetPlayerHealth(playerid, 0);
    return 1;
}
CMD:tpcor(playerid, params[])
{
    new Float:x, Float:y, Float:z, Float:angle;
    if (sscanf(params, "ffff", x, y, z, angle)) return SCM(playerid, 0xFFFF0000, "Использование: /tpcor [x] [y] [z] [angle]");

    SetPlayerPos(playerid, x, y, z);
    SetPlayerFacingAngle(playerid, angle);
    SCM(playerid, 0xFFFFFFFF, "Телепорт выполнен.");
    return 1;
}
// =========================================================
//                   АДМИН - СИСТЕМА
// =========================================================
CMD:veh(playerid, params[])
{
    // Проверка на админку (1 уровень и выше)
    if (PlayerInfo[playerid][pAdmin] < 1)
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Неизвестная команда.");

    new modelid, color1, color2;

    // sscanf: d - обязательное число (модель), I(-1) - необязательное число (цвет), по умолчанию -1 (случайный)
    if (sscanf(params, "dI(-1)I(-1)", modelid, color1, color2))
        return SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Использование: /veh [ID модели] [цвет 1] [цвет 2]");

    if (modelid < 400 || modelid > 611)
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Неверный ID модели (от 400 до 611).");

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    // Создаем транспорт. -1 в конце означает, что машина не будет респавниться сама по себе
    new vehicleid = CreateVehicle(modelid, x, y, z, a, color1, color2, -1);

    if (vehicleid == INVALID_VEHICLE_ID)
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Лимит транспорта на сервере превышен.");

    // Синхронизируем виртуальный мир и интерьер транспорта с миром админа
    SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(playerid));
    LinkVehicleToInterior(vehicleid, GetPlayerInterior(playerid));

    // Сажаем админа сразу на водительское место (seatid = 0)
    PutPlayerInVehicle(playerid, vehicleid, 0);

    new msg[128];
    format(msg, sizeof(msg), "{808000}[SERVER]:{FFFFFF} Транспорт создан (ID: %d | Модель: %d).", vehicleid, modelid);
    SCM(playerid, -1, msg);

    return 1;
}

CMD:delveh(playerid, params[])
{
    // Проверка на админку
    if (PlayerInfo[playerid][pAdmin] < 1)
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Неизвестная команда.");

    // Проверяем, сидит ли админ в машине
    if (!IsPlayerInAnyVehicle(playerid))
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Вы должны находиться в транспорте для его удаления.");

    new vehicleid = GetPlayerVehicleID(playerid);

    // Если это арендованный велосипед кого-то из игроков — очищаем его таймер и переменную
    foreach(new i : Player)
    {
        if (PlayerBike[i] == vehicleid)
        {
            PlayerBike[i] = INVALID_VEHICLE_ID;
            if (PlayerBikeTimer[i] != INVALID_TIMER)
            {
                KillTimer(PlayerBikeTimer[i]);
                PlayerBikeTimer[i] = INVALID_TIMER;
            }
            break;
        }
    }

    DestroyVehicle(vehicleid);
    SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Транспорт успешно удален.");

    return 1;
}
CMD:makeadmin(playerid, params[])
{
    // Проверяем, авторизован ли игрок как RCON администратор
    if (!IsPlayerAdmin(playerid))
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} У вас нет прав для использования этой команды.");

    new targetid, level;
    // sscanf "ud" означает: u - ID или ник игрока, d - целое число (уровень)
    if (sscanf(params, "ud", targetid, level))
        return SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Использование: /makeadmin [ID игрока] [Уровень (0-5)]");

    if (!IsPlayerConnected(targetid) || !IsPlayerLoggedIn[targetid])
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Игрок не найден или не авторизован.");

    if (level < 0 || level > 5)
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Уровень администратора может быть от 0 до 5.");

    // Выдаем уровень и сохраняем аккаунт игрока
    PlayerInfo[targetid][pAdmin] = level;
    SaveAccount(targetid);

    new msg[144], adminName[MAX_PLAYER_NAME], targetName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, adminName, sizeof(adminName));
    GetPlayerName(targetid, targetName, sizeof(targetName));

    if (level == 0)
    {
        format(msg, sizeof(msg), "{808000}[SERVER]:{FF0000} Администратор %s снял с вас права администратора.", adminName);
        SCM(targetid, -1, msg);
        format(msg, sizeof(msg), "{808000}[SERVER]:{FFFFFF} Вы сняли права администратора с %s.", targetName);
        SCM(playerid, -1, msg);
    }
    else
    {
        format(msg, sizeof(msg), "{808000}[SERVER]:{00FF00} Администратор %s назначил вас администратором %d уровня.", adminName, level);
        SCM(targetid, -1, msg);
        format(msg, sizeof(msg), "{808000}[SERVER]:{FFFFFF} Вы назначили %s администратором %d уровня.", targetName, level);
        SCM(playerid, -1, msg);
    }
    return 1;
}

CMD:a(playerid, params[])
{
    if (PlayerInfo[playerid][pAdmin] < 1)
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Неизвестная команда.");

    if (isnull(params)) // isnull - макрос для проверки пустого текста
        return SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Использование: /a [текст]");

    new msg[144], name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    format(msg, sizeof(msg), "[A] [%d lvl] %s: {FFFFFF}%s", PlayerInfo[playerid][pAdmin], name, params);

    // Отправляем сообщение только админам
    foreach(new i : Player)
    {
        if (IsPlayerLoggedIn[i] && PlayerInfo[i][pAdmin] >= 1)
        {
            SCM(i, 0x00FF00FF, msg);
        }
    }
    return 1;
}

CMD:goto(playerid, params[])
{
    if (PlayerInfo[playerid][pAdmin] < 1)
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Неизвестная команда.");

    new targetid;
    if (sscanf(params, "u", targetid))
        return SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Использование: /goto [ID игрока]");

    if (!IsPlayerConnected(targetid) || !IsPlayerLoggedIn[targetid])
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Игрок не найден или не авторизован.");

    if (targetid == playerid)
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Вы не можете телепортироваться сами к себе.");

    new Float:x, Float:y, Float:z;
    GetPlayerPos(targetid, x, y, z);

    // Синхронизируем виртуальный мир и интерьер
    SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
    SetPlayerInterior(playerid, GetPlayerInterior(targetid));

    // Телепортируем чуть в сторону от игрока, чтобы не застрять в нём
    SetPlayerPos(playerid, x + 1.0, y + 1.0, z);

    new msg[128], targetName[MAX_PLAYER_NAME];
    GetPlayerName(targetid, targetName, sizeof(targetName));
    format(msg, sizeof(msg), "{808000}[SERVER]:{FFFFFF} Вы телепортировались к %s.", targetName);
    SCM(playerid, -1, msg);

    return 1;
}

CMD:kick(playerid, params[])
{
    if (PlayerInfo[playerid][pAdmin] < 1)
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Неизвестная команда.");

    new targetid, reason[64];
    if (sscanf(params, "us[64]", targetid, reason))
        return SCM(playerid, -1, "{808000}[SERVER]:{FFFFFF} Использование: /kick [ID игрока] [Причина]");

    if (!IsPlayerConnected(targetid) || !IsPlayerLoggedIn[targetid])
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Игрок не найден.");

    if (PlayerInfo[targetid][pAdmin] > PlayerInfo[playerid][pAdmin])
        return SCM(playerid, -1, "{808000}[SERVER]:{FF0000} Вы не можете кикнуть администратора выше вас рангом.");

    new msg[144], adminName[MAX_PLAYER_NAME], targetName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, adminName, sizeof(adminName));
    GetPlayerName(targetid, targetName, sizeof(targetName));

    format(msg, sizeof(msg), "{FF0000}Администратор %s кикнул игрока %s. Причина: %s", adminName, targetName, reason);
    SendClientMessageToAll(-1, msg); // Отправляем всем на сервере

    // Кикаем с задержкой 100 миллисекунд
    SetTimerEx("DelayedKick", 100, false, "i", targetid);
    return 1;
}
// ... Функция removeobj(playerid) остается как была ...
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
	RemoveBuildingForPlayer(playerid, 713, 1457.9375, -1620.6953, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 713, 1496.8672, -1707.8203, 13.4063, 0.25);
	RemoveBuildingForPlayer(playerid, 1226, 1467.9844, -1727.6719, 16.4219, 0.25);
	RemoveBuildingForPlayer(playerid, 1226, 1485.1719, -1727.6719, 16.4219, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1468.9844, -1713.5078, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1231, 1479.6953, -1716.7031, 15.6250, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1488.7656, -1713.7031, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1289, 1504.7500, -1711.8828, 13.5938, 0.25);
	RemoveBuildingForPlayer(playerid, 1258, 1445.0078, -1704.7656, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 1258, 1445.0078, -1692.2344, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 712, 1445.8125, -1650.0234, 22.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 673, 1457.7266, -1710.0625, 12.3984, 0.25);
	RemoveBuildingForPlayer(playerid, 620, 1461.6563, -1707.6875, 11.8359, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1468.9844, -1704.6406, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 700, 1463.0625, -1701.5703, 13.7266, 0.25);
	RemoveBuildingForPlayer(playerid, 1231, 1479.6953, -1702.5313, 15.6250, 0.25);
	RemoveBuildingForPlayer(playerid, 673, 1457.5547, -1697.2891, 12.3984, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1468.9844, -1694.0469, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1231, 1479.3828, -1692.3906, 15.6328, 0.25);
	RemoveBuildingForPlayer(playerid, 620, 1461.1250, -1687.5625, 11.8359, 0.25);
	RemoveBuildingForPlayer(playerid, 700, 1463.0625, -1690.6484, 13.7266, 0.25);
	RemoveBuildingForPlayer(playerid, 641, 1458.6172, -1684.1328, 11.1016, 0.25);
	RemoveBuildingForPlayer(playerid, 625, 1457.2734, -1666.2969, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1468.9844, -1682.7188, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 712, 1471.4063, -1666.1797, 22.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 1231, 1479.3828, -1682.3125, 15.6328, 0.25);
	RemoveBuildingForPlayer(playerid, 625, 1458.2578, -1659.2578, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 712, 1449.8516, -1655.9375, 22.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 1231, 1477.9375, -1652.7266, 15.6328, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1479.6094, -1653.2500, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 625, 1457.3516, -1650.5703, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 625, 1454.4219, -1642.4922, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1467.8516, -1646.5938, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1472.8984, -1651.5078, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1465.9375, -1639.8203, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1231, 1466.4688, -1637.9609, 15.6328, 0.25);
	RemoveBuildingForPlayer(playerid, 625, 1449.5938, -1635.0469, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1467.7109, -1632.8906, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, 1465.8906, -1629.9766, 15.5313, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1472.6641, -1627.8828, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1479.4688, -1626.0234, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, 1465.8359, -1608.3750, 15.3750, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1488.7656, -1704.5938, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 700, 1494.2109, -1694.4375, 13.7266, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1488.7656, -1693.7344, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 620, 1496.9766, -1686.8516, 11.8359, 0.25);
	RemoveBuildingForPlayer(playerid, 641, 1494.1406, -1689.2344, 11.1016, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1488.7656, -1682.6719, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 712, 1480.6094, -1666.1797, 22.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 712, 1488.2266, -1666.1797, 22.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1486.4063, -1651.3906, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1491.3672, -1646.3828, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1493.1328, -1639.4531, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1486.1797, -1627.7656, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1280, 1491.2188, -1632.6797, 13.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, 1494.4141, -1629.9766, 15.5313, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, 1494.3594, -1608.3750, 15.3750, 0.25);
	RemoveBuildingForPlayer(playerid, 1288, 1504.7500, -1705.4063, 13.5938, 0.25);
	RemoveBuildingForPlayer(playerid, 1287, 1504.7500, -1704.4688, 13.5938, 0.25);
	RemoveBuildingForPlayer(playerid, 1286, 1504.7500, -1695.0547, 13.5938, 0.25);
	RemoveBuildingForPlayer(playerid, 1285, 1504.7500, -1694.0391, 13.5938, 0.25);
	RemoveBuildingForPlayer(playerid, 673, 1498.9609, -1684.6094, 12.3984, 0.25);
	RemoveBuildingForPlayer(playerid, 625, 1504.1641, -1662.0156, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 625, 1504.7188, -1670.9219, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 620, 1503.1875, -1621.1250, 11.8359, 0.25);
	RemoveBuildingForPlayer(playerid, 673, 1501.2813, -1624.5781, 12.3984, 0.25);
	RemoveBuildingForPlayer(playerid, 673, 1498.3594, -1616.9688, 12.3984, 0.25);
	RemoveBuildingForPlayer(playerid, 712, 1508.4453, -1668.7422, 22.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 625, 1505.6953, -1654.8359, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 625, 1508.5156, -1647.8594, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 625, 1513.2734, -1642.4922, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 1258, 1510.8906, -1607.3125, 13.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, -419.7500, -1412.9766, 23.1250, 0.25);
	RemoveBuildingForPlayer(playerid, 17000, -406.9141, -1448.9688, 24.6406, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, -378.7734, -1459.0234, 25.4766, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, -384.2344, -1455.8281, 25.4766, 0.25);
	RemoveBuildingForPlayer(playerid, 17005, -391.1406, -1432.9922, 32.4297, 0.25);
	RemoveBuildingForPlayer(playerid, 17006, -394.9609, -1433.9688, 32.4453, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, -396.8047, -1411.5469, 25.3906, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, -408.5625, -1412.2891, 24.8281, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, -368.7813, -1454.3672, 25.4766, 0.25);
	RemoveBuildingForPlayer(playerid, 3425, -370.3750, -1446.9688, 35.9531, 0.25);
	RemoveBuildingForPlayer(playerid, 17298, -366.6719, -1422.6875, 30.3750, 0.25);
	RemoveBuildingForPlayer(playerid, 1454, -372.1797, -1434.6094, 25.5156, 0.25);
	RemoveBuildingForPlayer(playerid, 1454, -369.1953, -1434.6094, 25.5156, 0.25);
	RemoveBuildingForPlayer(playerid, 1454, -366.2031, -1434.6094, 25.4375, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, -362.4844, -1446.1250, 25.4766, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, -361.8125, -1407.5391, 25.4766, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, -360.7188, -1435.2578, 24.8984, 0.25);
	RemoveBuildingForPlayer(playerid, 1454, -363.2109, -1434.6094, 25.3984, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, -358.7578, -1423.8203, 24.7500, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, -356.8594, -1412.5547, 25.2500, 0.25);
	RemoveBuildingForPlayer(playerid, 1454, -333.6953, -1434.8359, 15.4063, 0.25);
	RemoveBuildingForPlayer(playerid, 1454, -328.9688, -1434.8359, 15.1797, 0.25);
	RemoveBuildingForPlayer(playerid, 1454, -323.3828, -1434.8359, 14.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 1454, -315.8438, -1434.8359, 14.7578, 0.25);
	RemoveBuildingForPlayer(playerid, 1454, -307.7344, -1434.8359, 14.1719, 0.25);
	CreateObject(1231, 1481.82080, -1626.61633, 15.80577,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1466.37964, -1639.49255, 15.77894,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1469.30542, -1631.34448, 15.76145,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1477.13879, -1626.75427, 15.78836,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1467.13770, -1644.12012, 15.79691,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1472.84912, -1628.21118, 15.77193,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1469.42993, -1648.00269, 15.79557,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1467.18445, -1634.91479, 15.77575,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1489.67834, -1647.90381, 15.78237,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1491.87830, -1644.06433, 15.76136,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1492.75293, -1639.59888, 15.78118,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1492.03601, -1635.27563, 15.79404,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1489.82898, -1631.22144, 15.80454,   0.00000, 0.00000, 0.00000);
	CreateObject(1231, 1486.26794, -1628.20544, 15.81670,   0.00000, 0.00000, 0.00000);
	CreateObject(2745, 1467.82458, -1706.27441, 14.25244,   0.00000, 0.00000, 91.00000);
	CreateObject(3471, 1488.48840, -1680.77271, 14.40600,   0.00000, 0.00000, 180.00000);
	CreateObject(2745, 1467.89038, -1715.02869, 14.26491,   0.00000, 0.00000, 91.00000);
	CreateObject(2745, 1467.85608, -1698.04443, 14.28371,   0.00000, 0.00000, 91.00000);
	CreateObject(2745, 1467.80505, -1689.86731, 14.27650,   0.00000, 0.00000, 91.00000);
	CreateObject(2745, 1467.80774, -1680.71045, 14.26885,   0.00000, 0.00000, 91.00000);
	CreateObject(3471, 1488.60327, -1689.79102, 14.42130,   0.00000, 0.00000, 180.00000);
	CreateObject(3471, 1488.58484, -1697.98413, 14.31130,   0.00000, 0.00000, 180.00000);
	CreateObject(3471, 1488.49353, -1706.25171, 14.36368,   0.00000, 0.00000, 180.00000);
	CreateObject(3471, 1488.46704, -1714.86572, 14.34500,   0.00000, 0.00000, 180.00000);
	CreateObject(3517, 1467.69812, -1685.63599, 24.36795,   0.00000, 0.00000, 0.00000);
	CreateObject(3517, 1467.43323, -1693.74548, 24.23026,   0.00000, 0.00000, 0.00000);
	CreateObject(3517, 1467.48499, -1701.68896, 24.18734,   0.00000, 0.00000, 0.00000);
	CreateObject(3517, 1467.61475, -1710.56238, 24.24958,   0.00000, 0.00000, 0.00000);
	CreateObject(3517, 1489.08105, -1710.63525, 24.15846,   0.00000, 0.00000, 0.00000);
	CreateObject(3517, 1488.78992, -1685.49097, 23.59942,   0.00000, 0.00000, 0.00000);
	CreateObject(3517, 1488.97083, -1693.90283, 23.85313,   0.00000, 0.00000, 0.00000);
	CreateObject(3517, 1489.03516, -1701.93115, 24.21641,   0.00000, 0.00000, 0.00000);
	CreateObject(1226, 1473.73987, -1727.75830, 16.42540,   0.00000, 0.00000, 90.00000);
	CreateObject(1226, 1481.74719, -1727.83984, 16.45930,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1481.60925, -1716.85498, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1481.61401, -1712.73376, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1481.60962, -1708.61426, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1481.61511, -1704.49292, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1481.62256, -1700.36279, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1481.62939, -1696.26306, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1481.63110, -1692.15088, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1481.63220, -1688.04626, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1481.62463, -1683.93176, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1481.62720, -1679.80640, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1483.69385, -1677.73181, 13.65270,   0.00000, 0.00000, 0.00000);
	CreateObject(970, 1487.81812, -1677.72205, 13.65270,   0.00000, 0.00000, 0.00000);
	CreateObject(970, 1491.93262, -1677.71680, 13.65270,   0.00000, 0.00000, 0.00000);
	CreateObject(970, 1496.04858, -1677.71033, 13.65270,   0.00000, 0.00000, 0.00000);
	CreateObject(970, 1500.19775, -1677.70227, 13.65270,   0.00000, 0.00000, 0.00000);
	CreateObject(970, 1473.54651, -1716.83423, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1473.55835, -1712.70349, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1473.56348, -1708.59399, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1473.57202, -1704.48999, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1473.58130, -1700.38794, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1473.57385, -1696.27441, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1473.57947, -1692.13745, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1473.58484, -1687.99280, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1473.59338, -1683.85205, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1473.57312, -1679.72046, 13.65270,   0.00000, 0.00000, 90.00000);
	CreateObject(970, 1471.51575, -1677.64856, 13.65270,   0.00000, 0.00000, 0.00000);
	CreateObject(970, 1467.37256, -1677.63391, 13.65270,   0.00000, 0.00000, 0.00000);
	CreateObject(970, 1463.23547, -1677.63379, 13.65270,   0.00000, 0.00000, 0.00000);
	CreateObject(970, 1459.10559, -1677.62854, 13.65270,   0.00000, 0.00000, 0.00000);
	CreateObject(970, 1431.70984, -1690.43237, 14.98260,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1463.80505, -1682.60095, 13.63500,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1460.07520, -1682.61426, 13.63772,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1456.36536, -1682.58557, 13.66446,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1456.39087, -1714.33020, 13.60786,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1460.08032, -1714.30164, 13.62162,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1463.77478, -1714.26697, 13.62320,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1455.20837, -1691.03015, 13.62162,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1455.23730, -1698.02100, 13.62733,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1455.24329, -1701.52686, 13.63486,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1455.23633, -1704.96167, 13.61488,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1455.21301, -1708.48657, 13.61508,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1455.19116, -1694.57495, 13.65953,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1455.17859, -1687.50806, 13.66100,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1465.89392, -1708.22473, 13.61443,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1465.85242, -1704.72217, 13.59431,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1465.85632, -1701.17139, 13.62683,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1465.90076, -1693.93896, 13.60561,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1465.87366, -1697.43958, 13.60263,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1465.93140, -1690.41968, 13.62159,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1465.87561, -1686.89758, 13.59270,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1493.18872, -1682.63293, 13.63920,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1500.63135, -1714.25378, 13.59917,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1493.14722, -1714.30273, 13.60399,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1496.90869, -1682.63745, 13.62753,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1500.66858, -1682.64209, 13.61957,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1496.88672, -1714.26099, 13.59405,   0.00000, 0.00000, 0.00000);
	CreateObject(997, 1502.66479, -1708.32690, 13.59539,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1502.67957, -1704.70532, 13.59526,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1502.70154, -1701.20508, 13.63518,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1502.66528, -1697.58521, 13.59526,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1502.70142, -1686.52771, 13.61522,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1502.67383, -1690.29053, 13.63518,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1502.68811, -1693.96899, 13.63519,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1491.99280, -1686.73865, 13.62537,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1492.00684, -1690.33801, 13.64081,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1492.01245, -1693.86230, 13.64081,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1492.01062, -1697.44348, 13.64732,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1492.00989, -1700.97229, 13.64732,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1492.01074, -1704.54797, 13.65434,   0.00000, 0.00000, 90.00000);
	CreateObject(997, 1492.05530, -1708.14575, 13.63957,   0.00000, 0.00000, 90.00000);
	CreateObject(658, 1497.07910, -1686.37451, 13.74151,   0.00000, 0.00000, 0.00000);
	CreateObject(658, 1496.45325, -1698.04395, 13.63011,   0.00000, 0.00000, 0.00000);
	CreateObject(658, 1496.44238, 13.70040, 13.70040,   0.00000, 0.00000, 0.00000);
	CreateObject(658, 1460.19958, -1688.15222, 13.54909,   0.00000, 0.00000, 0.00000);
	CreateObject(658, 1459.65344, -1700.71802, 13.64348,   0.00000, 0.00000, 0.00000);
	CreateObject(658, 1497.17188, -1708.42334, 13.76596,   0.00000, 0.00000, 0.00000);
	CreateObject(658, 1459.54761, -1709.63989, 13.64888,   0.00000, 0.00000, 0.00000);
	CreateObject(1226, 1471.83716, -1710.28662, 16.83700,   0.00000, 0.00000, 180.00000);
	CreateObject(1226, 1471.86084, -1701.50500, 16.89020,   0.00000, 0.00000, 180.00000);
	CreateObject(1226, 1471.83313, -1693.36475, 16.90880,   0.00000, 0.00000, 180.00000);
	CreateObject(1226, 1471.81580, -1685.27783, 16.89530,   0.00000, 0.00000, 180.00000);
	CreateObject(1226, 1484.54309, -1701.85291, 16.93432,   0.00000, 0.00000, 0.00000);
	CreateObject(1226, 1484.52002, -1685.50452, 16.91032,   0.00000, 0.00000, 0.00000);
	CreateObject(1226, 1484.54736, -1710.59875, 16.90081,   0.00000, 0.00000, 0.00000);
	CreateObject(1226, 1484.44629, -1694.28918, 16.97775,   0.00000, 0.00000, 0.00000);
	CreateObject(15038, 1485.53162, -1689.86096, 13.68132,   0.00000, 0.00000, 0.00000);
	CreateObject(15038, 1485.56543, -1698.01721, 13.66698,   0.00000, 0.00000, 0.00000);
	CreateObject(15038, 1485.51111, -1706.18396, 13.68704,   0.00000, 0.00000, 0.00000);
	CreateObject(15038, 1485.59924, -1714.88013, 13.64702,   0.00000, 0.00000, 0.00000);
	CreateObject(15038, 1485.65869, -1680.95020, 13.71475,   0.00000, 0.00000, 0.00000);
	CreateObject(15038, 1470.88733, -1680.68652, 13.74771,   0.00000, 0.00000, 0.00000);
	CreateObject(15038, 1470.75916, -1689.87219, 13.66757,   0.00000, 0.00000, 0.00000);
	CreateObject(15038, 1470.70459, -1697.88562, 13.71723,   0.00000, 0.00000, 0.00000);
	CreateObject(15038, 1470.75806, -1706.19727, 13.64711,   0.00000, 0.00000, 0.00000);
	CreateObject(15038, 1470.57263, -1715.50061, 13.65492,   0.00000, 0.00000, 0.00000);
	CreateObject(12925, -323.07907, -1511.90417, 12.63024,   10.00000, 0.00000, 90.00000);
	CreateObject(5838, -314.88931, -1529.01331, 28.71180,   0.00000, 4.00000, 0.00000);
	CreateObject(1431, -320.11209, -1503.55554, 12.43670,   0.00000, 6.00000, 0.00000);
	CreateObject(1431, -322.24496, -1503.37134, 12.63680,   0.00000, 6.00000, 0.00000);
	CreateObject(1431, -324.28125, -1503.23877, 12.95230,   0.00000, 6.00000, 0.00000);
	CreateObject(1458, -326.84229, -1502.01123, 12.85609,   0.00000, 0.00000, 180.00000);
	CreateObject(17039, -321.63528, -1493.63794, 11.24389,   10.00000, 0.00000, 90.00000);
	CreateObject(14875, -315.01999, -1497.57654, 11.34367,   0.00000, 10.00000, 0.00000);
	CreateObject(14875, -317.74026, -1501.84180, 11.80646,   0.00000, 10.00000, 0.00000);
	CreateObject(1454, -318.22736, -1516.01379, 12.47842,   0.00000, 0.00000, 0.00000);
	CreateObject(1454, -318.25113, -1514.74707, 12.41928,   0.00000, 0.00000, 0.00000);
	CreateObject(1454, -318.32166, -1513.42041, 12.43463,   0.00000, 0.00000, 0.00000);
	CreateObject(1454, -318.30228, -1512.11011, 12.41258,   0.00000, 0.00000, 0.00000);
	CreateObject(1454, -318.39191, -1509.51611, 12.35224,   0.00000, 0.00000, 0.00000);
	CreateObject(1454, -318.35065, -1510.77551, 12.38813,   0.00000, 0.00000, 0.00000);
	CreateObject(1453, -318.40930, -1498.49658, 11.99632,   -5.00000, 0.00000, 0.00000);
	CreateObject(1453, -317.76913, -1498.40857, 11.97000,   -5.00000, 0.00000, 0.00000);
	CreateObject(1453, -318.28763, -1497.82446, 12.09872,   -5.00000, 0.00000, 0.00000);
	CreateObject(1453, -325.31046, -1498.86011, 12.89803,   5.00000, 0.00000, 0.00000);
	CreateObject(1453, -318.51254, -1488.44043, 12.06908,   0.00000, 0.00000, 0.00000);
	CreateObject(1453, -325.06631, -1498.20642, 12.89619,   5.00000, 0.00000, 0.00000);
	CreateObject(1453, -324.54724, -1498.91675, 12.83517,   5.00000, 0.00000, 0.00000);
	CreateObject(1453, -317.64676, -1488.29297, 12.00864,   0.00000, 0.00000, 0.00000);
	CreateObject(1453, -318.18713, -1488.94763, 12.03409,   0.00000, 0.00000, 0.00000);
	CreateObject(1453, -325.16898, -1488.63196, 13.09400,   -15.00000, 0.00000, 0.00000);
	CreateObject(1453, -325.14175, -1489.04016, 13.00553,   -10.00000, 0.00000, 0.00000);
	CreateObject(1453, -324.61313, -1488.56604, 12.89699,   -10.00000, 0.00000, 0.00000);
	CreateObject(1454, -323.54321, -1488.21228, 12.25094,   5.00000, 0.00000, 90.00000);
	CreateObject(1454, -321.88763, -1488.33130, 12.10375,   5.00000, 0.00000, 90.00000);
	CreateObject(1454, -320.09488, -1488.82703, 12.15550,   0.00000, 0.00000, 90.00000);
	CreateObject(1454, -319.74814, -1498.34973, 12.06310,   5.00000, 0.00000, 90.00000);
	CreateObject(1454, -321.40875, -1498.49280, 12.01835,   5.00000, 0.00000, 90.00000);
	CreateObject(1454, -323.05798, -1498.51819, 12.17315,   5.00000, 0.00000, 90.00000);
	CreateObject(17324, -315.88910, -1549.12744, 12.38780,   10.50000, 0.00000, 90.00000);
	CreateObject(3286, -305.79611, -1539.41687, 12.79577,   0.00000, 10.00000, 0.00000);
	CreateObject(3286, -308.12680, -1558.25195, 12.98760,   0.00000, 10.00000, 0.00000);

}
