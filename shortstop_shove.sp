#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo = {
    name        = "[TF2] Shortstop Shove Animation Fix",
    author      = "FlaminSarge",
    description = "Fixes the Shortstop to have a world shove animation",
    version     = PLUGIN_VERSION,
    url         = "http://github.com/flaminsarge/shortstop_shove"
};

public void OnPluginStart() {
    CreateConVar("shortstop_shove_version", PLUGIN_VERSION, "[TF2] Shortstop Shove Animation Fix version");
    AddTempEntHook("PlayerAnimEvent", PlayerAnimEvent);
}

//These could change in the future, I dunno
#define ACT_MP_PUSH_STAND_SECONDARY     1817
#define ACT_MP_PUSH_CROUCH_SECONDARY    1818
#define ACT_MP_PUSH_SWIM_SECONDARY      1819
#define PLAYERANIMEVENT_ATTACK_SECONDARY    1
#define PLAYERANIMEVENT_CUSTOM_GESTURE      20
public Action PlayerAnimEvent(const char[] te_name, const int[] clients, int numClients, float delay) {
    int client = TE_ReadNum("m_iPlayerIndex");
    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) {
        return Plugin_Continue;
    }

    //if not altfire animation, return
    int event = TE_ReadNum("m_iEvent");
    if (event != PLAYERANIMEVENT_ATTACK_SECONDARY) {
        return Plugin_Continue; 
    }

    //if not shortstop, return
    char weapon[64];
    GetClientWeapon(client, weapon, sizeof(weapon));
    if (!StrEqual(weapon, "tf_weapon_handgun_scout_primary")) {
        return Plugin_Continue;
    }

    //pick activity based on state
    int data = ACT_MP_PUSH_STAND_SECONDARY;
    if (GetEntProp(client, Prop_Send, "m_nWaterLevel") >= 2) {
        data = ACT_MP_PUSH_SWIM_SECONDARY;
    } else if (GetEntProp(client, Prop_Send, "m_bDucked")) {
        data = ACT_MP_PUSH_CROUCH_SECONDARY;
    }

    //add self to tempent recipient list
    int clResult[MAXPLAYERS + 1];
    int numResultClients = numClients+1;
    for (int i = 0; i < numClients; i++) {
        if (clients[i] == client) {
            numResultClients = numClients;
        }
        clResult[i] = clients[i];
    }
    clResult[numClients] = client;

    //send animation event
    TE_Start("PlayerAnimEvent");
    TE_WriteNum("m_iPlayerIndex", client);
    TE_WriteNum("m_iEvent", PLAYERANIMEVENT_CUSTOM_GESTURE);
    TE_WriteNum("m_nData", data);
    TE_Send(clResult, numResultClients, delay);
    //block original event
    return Plugin_Stop;
}
