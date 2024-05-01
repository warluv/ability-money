#pragma compress 1

#include <amxmodx>
#include <reapi>

#pragma semicolon 1

const ADMIN_FLAGS = ADMIN_LEVEL_A;

new const g_sPrefix[] = "^4[Menu]^1";

enum _:AbilityData
{
    bool:Ability_Speed,
    bool:Ability_BhopEnabled,
    bool:Ability_ExtraJumpEnabled,
    Ability_ExtraJumpCount,
};

new g_iPlayerAbility[MAX_PLAYERS + 1][AbilityData];

new const MAIN_MENU_ID[] = "MainMenu";

public plugin_init() 
{
    register_plugin("Abiltiy Menu", "1.0.0", "WarBans");

    register_clcmd("capabilities", "@Command_Menu");

    register_menucmd(register_menuid(MAIN_MENU_ID), 1023, "@Handle_MainMenu");

    RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", true);
    RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", true);
    RegisterHookChain(RG_CBasePlayer_Jump, "@CBasePlayer_Jump_Pre", false);
    RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "@CBasePlayer_ResetMaxSpeed_Post", true);
}

@Command_Menu(id)
{
    MainMenu_Show(id);
    return PLUGIN_HANDLED;
}

@CSGameRules_RestartRound_Post(id)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        arrayset(g_iPlayerAbility[i], false, AbilityData);
    }
}

@CBasePlayer_Killed_Post(id)
{
    g_iPlayerAbility[id][Ability_Speed] = g_iPlayerAbility[id][Ability_BhopEnabled] = g_iPlayerAbility[id][Ability_ExtraJumpEnabled] = false;
}

@CBasePlayer_Jump_Pre(id)
{
    new flags = get_entvar(id, var_flags);

    if (flags & FL_WATERJUMP)
        return;

    if (get_entvar(id, var_waterlevel) >= 2)
        return;

    new Float:vecVelocity[3];

    if (g_iPlayerAbility[id][Ability_ExtraJumpEnabled])
    {
        if (!(flags & FL_ONGROUND))
        {
            if (!g_iPlayerAbility[id][Ability_ExtraJumpCount] && !(get_member(id, m_afButtonLast) & IN_JUMP))
            {
                get_entvar(id, var_velocity, vecVelocity);

                vecVelocity[2] = 250.0;
                g_iPlayerAbility[id][Ability_ExtraJumpCount]++;

                set_entvar(id, var_velocity, vecVelocity);
            }
        }
        else
            g_iPlayerAbility[id][Ability_ExtraJumpCount] = 0;
    }

    if (g_iPlayerAbility[id][Ability_BhopEnabled])
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

@CBasePlayer_ResetMaxSpeed_Post(id)
{
    if (!g_iPlayerAbility[id][Ability_Speed])
        return;

    set_entvar(id, var_maxspeed, 500.0);
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

    len += formatex(text[len], charsmax(text) - len, "\r2. \wСкорость: %s^n", g_iPlayerAbility[id][Ability_Speed] ? "\yВкл" : "\rВыкл");
    keys |= MENU_KEY_2;

    len += formatex(text[len], charsmax(text) - len, "\r3. \wРаспрыжка: %s^n", g_iPlayerAbility[id][Ability_BhopEnabled] ? "\yВкл" : "\rВыкл");
    keys |= MENU_KEY_3;

    len += formatex(text[len], charsmax(text) - len, "\r4. \wДвойной прыжок: %s^n", g_iPlayerAbility[id][Ability_ExtraJumpEnabled] ? "\yВкл" : "\rВыкл");
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
            g_iPlayerAbility[id][Ability_Speed] = !g_iPlayerAbility[id][Ability_Speed];

            //set_entvar(id, var_maxspeed, g_iPlayerAbility[id][Ability_Speed] ? 500.0 : 250.0);
            rg_reset_maxspeed(id);

            client_print_color(0, print_team_default, "%s ^1Игрок ^3%n^1 %s ^4скорость^1.", g_sPrefix, id, g_iPlayerAbility[id][Ability_Speed] ? "включил" : "выключил");
        }
        case 2:
        {
            g_iPlayerAbility[id][Ability_BhopEnabled] = !g_iPlayerAbility[id][Ability_BhopEnabled];

            client_print_color(0, print_team_default, "%s ^1Игрок ^3%n^1 %s ^4распрыжку^1.", g_sPrefix, id, g_iPlayerAbility[id][Ability_BhopEnabled] ? "включил" : "выключил");
        }
        case 3:
        {
            g_iPlayerAbility[id][Ability_ExtraJumpEnabled] = !g_iPlayerAbility[id][Ability_ExtraJumpEnabled];

            client_print_color(0, print_team_default, "%s ^1Игрок ^3%n^1 %s ^4двойной прыжок^1.", g_sPrefix, id, g_iPlayerAbility[id][Ability_ExtraJumpEnabled] ? "включил" : "выключил");
        }
    }

    MainMenu_Show(id);
    return PLUGIN_HANDLED;
}

public plugin_natives()
{
    register_native("open_ability_menu", "@native_open_ability_menu");
}

@native_open_ability_menu(plugin, argc)
{
    enum { arg_player = 1 };

    new player = get_param(arg_player);

    if (!is_user_connected(player))
        return false;

    MainMenu_Show(player);
    return true;
}
