#pragma compress 1

#include <amxmodx>
#include <reapi>

#pragma semicolon 1

const ADMIN_FLAGS = ADMIN_LEVEL_A;

new const g_sPrefix[] = "^4[Menu]^1";

enum JumpsData
{
    bool:Jump_BhopEnabled,
    bool:Jump_ExtraEnabled,
    Jump_ExtraCount,
};

new g_iPlayerJumps[MAX_PLAYERS + 1][JumpsData];

new const MAIN_MENU_ID[] = "MainMenu";

public plugin_init() 
{
    register_plugin("Abiltiy Menu", "1.0.0", "WarBans");

    register_clcmd("capabilities", "@Command_Menu");

    register_menucmd(register_menuid(MAIN_MENU_ID), 1023, "@Handle_MainMenu");

    RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", true);
    RegisterHookChain(RG_CBasePlayer_Jump, "@CBasePlayer_Jump_Pre", false);
}

@Command_Menu(id)
{
    MainMenu_Show(id);
    return PLUGIN_HANDLED;
}

@CBasePlayer_Killed_Post(id)
{
    g_iPlayerJumps[id][Jump_BhopEnabled] = g_iPlayerJumps[id][Jump_ExtraEnabled] = false;
}

@CBasePlayer_Jump_Pre(id)
{
    new flags = get_entvar(id, var_flags);

    if (flags & FL_WATERJUMP)
        return;

    if (get_entvar(id, var_waterlevel) >= 2)
        return;

    new Float:vecVelocity[3];

    if (g_iPlayerJumps[id][Jump_ExtraEnabled])
    {
        if (!(flags & FL_ONGROUND))
        {
            if (!g_iPlayerJumps[id][Jump_ExtraCount] && !(get_member(id, m_afButtonLast) & IN_JUMP))
            {
                get_entvar(id, var_velocity, vecVelocity);

                vecVelocity[2] = 250.0;
                g_iPlayerJumps[id][Jump_ExtraCount]++;

                set_entvar(id, var_velocity, vecVelocity);
            }
        }
        else
            g_iPlayerJumps[id][Jump_ExtraCount] = 0;
    }

    if (g_iPlayerJumps[id][Jump_BhopEnabled])
    {
        if (!(flags & FL_ONGROUND))
            return;

        get_entvar(id, var_velocity, vecVelocity);

        vecVelocity[2] = 250.0;

        set_entvar(id, var_velocity, vecVelocity);
        set_entvar(id, var_gaitsequence, 6);
        set_entvar(id, var_fuser2, 0.0);
    }
}

MainMenu_Show(id)
{
    if (!(get_user_flags(id) & ADMIN_FLAGS))
    {
        client_print_color(id, print_team_default, "%s У вас недостаточно прав.", g_sPrefix);
        return;
    }

    new keys;
    new len;
    new text[MAX_MENU_LENGTH];

    len += formatex(text[len], charsmax(text) - len, "\yМеню способностей^n^n");

    len += formatex(text[len], charsmax(text) - len, "\r1. \wГравитация: %s^n", Float:get_entvar(id, var_gravity) != 1.0 ? "\yВкл" : "\rВыкл");
    keys |= MENU_KEY_1;

    len += formatex(text[len], charsmax(text) - len, "\r2. \wСкорость: %s^n", Float:get_entvar(id, var_maxspeed) > 250.0 ? "\yВкл" : "\rВыкл");
    keys |= MENU_KEY_2;

    len += formatex(text[len], charsmax(text) - len, "\r3. \wРаспрыжка: %s^n", g_iPlayerJumps[id][Jump_BhopEnabled] ? "\yВкл" : "\rВыкл");
    keys |= MENU_KEY_3;

    len += formatex(text[len], charsmax(text) - len, "\r4. \wДвойной прыжок: %s^n", g_iPlayerJumps[id][Jump_ExtraEnabled] ? "\yВкл" : "\rВыкл");
    keys |= MENU_KEY_4;

    len += formatex(text[len], charsmax(text) - len, "^n");
    len += formatex(text[len], charsmax(text) - len, "^n");

    len += formatex(text[len], charsmax(text) - len, "\r0. \wВыход");
    keys |= MENU_KEY_0;
    
    show_menu(id, keys, text, -1, MAIN_MENU_ID);
}

@Handle_MainMenu(id, key)
{
    if (key == 9)
        return PLUGIN_HANDLED;

    if (!is_user_alive(id))
    {
        client_print_color(id, print_team_default, "%s Лишь живые могут использовать данную функцию.", g_sPrefix);
        return PLUGIN_HANDLED;
    }

    switch (key)
    {
        case 0:
        {
            set_entvar(id, var_gravity, Float:get_entvar(id, var_gravity) == 1.0 ? 0.5 : 1.0);

            client_print_color(0, print_team_default, "%s ^1Игрок ^3%n^1 %s ^4гравитацию^1.", g_sPrefix, id, Float:get_entvar(id, var_gravity) != 1.0 ? "включил" : "выключил");
        }
        case 1:
        {
            set_entvar(id, var_maxspeed, Float:get_entvar(id, var_maxspeed) <= 250.0 ? 500.0 : 250.0);

            client_print_color(0, print_team_default, "%s ^1Игрок ^3%n^1 %s ^4скорость^1.", g_sPrefix, id, Float:get_entvar(id, var_maxspeed) != 250.0 ? "включил" : "выключил");
        }
        case 2:
        {
            g_iPlayerJumps[id][Jump_BhopEnabled] = !g_iPlayerJumps[id][Jump_BhopEnabled];

            client_print_color(0, print_team_default, "%s ^1Игрок ^3%n^1 %s ^4распрыжку^1.", g_sPrefix, id, g_iPlayerJumps[id][Jump_BhopEnabled] ? "включил" : "выключил");
        }
        case 3:
        {
            g_iPlayerJumps[id][Jump_ExtraEnabled] = !g_iPlayerJumps[id][Jump_ExtraEnabled];

            client_print_color(0, print_team_default, "%s ^1Игрок ^3%n^1 %s ^4двойной прыжок^1.", g_sPrefix, id, g_iPlayerJumps[id][Jump_ExtraEnabled] ? "включил" : "выключил");
        }
    }

    MainMenu_Show(id);
    return PLUGIN_HANDLED;
}