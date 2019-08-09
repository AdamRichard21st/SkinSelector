#include < amxmodx >
#include < amxmisc >
#include < hamsandwich >
#include < fakemeta >
#include < json >

/*
    TODO List:
        - Remove use_valve_fs from file_exists in LoadSkins() function.
        It's enabled just for testing purposes and should not be released as it's.
*/

#define FILE_JSON_LIST  "skins.json"
#define MAX_SKIN_LEN    64
#define MAX_NAME_LEN    42
#define MAX_FLAG_LEN    26

#define m_iLinuxEntity  4
#define m_iLinuxPlayer  5
#define m_pPlayer       41
#define m_iId           43
#define m_pActiveItem   373

#define DEBUG true
#define MENU_CONTENT_STRUCTURE MenuGetWeapon_Category
#define MENU_PACCESS (1 << 26)

enum
{
    WeaponList_jsonKey = 0,
    WeaponList_class,
    WeaponList_name
}

new const WeaponList[][][] =
{   /* WeaponList_jsonKey,  WeaponList_class, WeaponList_name */
    { "",               "",                         ""                  },
    { "p228",           "weapon_p228",              "SIG P228"          },
    { "",               "",                         ""                  },
    { "scout",          "weapon_scout",             "Steyr Scout"       },
    { "hegrenade",      "weapon_hegrenade",         "HE Grenade"        },
    { "xm1014",         "weapon_xm1014",            "Benelli XM1014"    },
    { "c4",             "weapon_c4",                "C4"                },
    { "mac10",          "weapon_mac10",             "MAC-10"            },
    { "aug",            "weapon_aug",               "Steyr Aug"         },
    { "smokegrenade",   "weapon_smokegrenade",      "Smoke Grenade"     },
    { "elite",          "weapon_elite",             "Dual Beretta"      },
    { "fiveseven",      "weapon_fiveseven",         "FN Five-Seven"     },
    { "ump45",          "weapon_ump45",             "UMP .45"           },
    { "sg550",          "weapon_sg550",             "Sig SG-550"        },
    { "galil",          "weapon_galil",             "Galil Defender"    },
    { "famas",          "weapon_famas",             "Famas 5.56"        },
    { "usp",            "weapon_usp",               "USP .45"           },
    { "glock",          "weapon_glock18",           "Glock-18"          },
    { "awp",            "weapon_awp",               "Magnum AWP"        },
    { "mp5",            "weapon_mp5navy",           "MP5-Navy"          },
    { "m249",           "weapon_m249",              "FN M249"           },
    { "m3",             "weapon_m3",                "Benelli M3"        },
    { "m4a1",           "weapon_m4a1",              "Colt M4A1"         },
    { "tmp",            "weapon_tmp",               "Steyr TMP"         },
    { "g3sg1",          "weapon_g3sg1",             "G3/SG-1"           },
    { "flashbang",      "weapon_flashbang",         "Flashbang"         },
    { "deagle",         "weapon_deagle",            "Desert Eagle"      },
    { "sg552",          "weapon_sg552",             "Sig SG-552"        },
    { "ak47",           "weapon_ak47",              "AK-47"             },
    { "knife",          "weapon_knife",             "Knife"             },
    { "p90",            "weapon_p90",               "FN P90"            }
}

enum _:CategoryData
{
    CategoryData_name[ 32 ],
    CategoryData_id
}

new const Categories[][ CategoryData ] =
{
    { "Pistols",        CSW_ALL_PISTOLS     },
    { "Shotguns",       CSW_ALL_SHOTGUNS    },
    { "Sub-Machines",   CSW_ALL_SMGS        },
    { "Rifles",         CSW_ALL_RIFLES | CSW_ALL_SNIPERRIFLES },
    { "Machine Guns",   CSW_ALL_MACHINEGUNS },
    { "Grenades",       CSW_ALL_GRENADES },
    { "Knifes",         (1 << CSW_KNIFE) }
}

enum MenuWeaponContent
{
    MenuGetWeapon_Category,
    MenuGetWeapon_Folder,
    MenuGetWeapon_Items
}

enum _:UserData
{
    UserData_Skin[ MAX_SKIN_LEN ],
    UserData_SkinID
}

enum _:WeaponData
{
    WeaponName[ MAX_NAME_LEN ],
    WeaponSkin[ MAX_SKIN_LEN ],
    WeaponFlag[ MAX_FLAG_LEN ],
    bool:WeaponDefault
}

enum _:WeaponArray
{
    Array:WeaponArray_List,
    WeaponArray_count
}

new g_WeaponLists[ CSW_P90 + 1 ][ WeaponArray ];
new g_UserItems[ MAX_PLAYERS + 1 ][ CSW_P90 + 1 ][ UserData ];
new bool:g_Debug;
new bool:g_ShowAsCategories;
new bool:g_ShowCollapsed;
new bool:g_CloseOnSelect;
new bool:g_AccessByFlags;
new bool:g_IgnoreAccess;
new bool:g_DefaultSkins;

public plugin_precache()
{
    new path[ 64 ];
    new list[ 92 ];

    get_configsdir( path, charsmax( path ) );
    formatex( list, charsmax( list ), "%s/%s", path, FILE_JSON_LIST );

    new JSON:file = json_parse( list, .is_file = true );

    if ( file == Invalid_JSON )
    {
        log_amx( "Data could not be loaded. (%s)", list );
        return;
    }

    LoadSettings( file );
    LoadSkins( file );
    json_free( file );

    if ( g_Debug )
    {
        log_amx( "^"settings.showAsCategories^":%s", g_ShowAsCategories ? "true" : "false" );
        log_amx( "^"settings.showCollapsed^":%s", g_ShowCollapsed ? "true" : "false" );
        log_amx( "^"settings.closeOnSelect^":%s", g_CloseOnSelect ? "true" : "false" );
        log_amx( "^"settings.accessByFlags^":%s", g_AccessByFlags ? "true" : "false" );
        log_amx( "^"settings.ignoreAccess^":%s", g_IgnoreAccess ? "true" : "false" );
        log_amx( "^"settings.defaultSkins^":%s", g_DefaultSkins ? "true" : "false" );

        for ( new i = CSW_P228; i <= CSW_P90; i++ )
        {
            if ( g_WeaponLists[ i ][ WeaponArray_count ] )
            {
                for ( new id = 0, item[ WeaponData ]; id < g_WeaponLists[ i ][ WeaponArray_count ]; id++ )
                {
                    ArrayGetArray( g_WeaponLists[ i ][ WeaponArray_List ], id, item, WeaponData );

                    log_amx( "[%s] Item loaded:^n^"name^":^"%s^"^n^"model^":^"%s^"^n^"admin^":^"%s^"^ndefault:%s",
                        WeaponList[ i ][ WeaponList_name ],
                        item[ WeaponName ],
                        item[ WeaponSkin ],
                        item[ WeaponFlag ],
                        item[ WeaponDefault ] ? "true" : "false"
                    );
                }
            }
        }
    }
}

public plugin_init()
{
    register_plugin( "Skin Selector", "0.0.1", "AdamRichard21st" );

    register_clcmd( "say /skins", "OnClientCommand_Skins" );

    for ( new i = CSW_P228; i <= CSW_P90; i++ )
    {
        if ( WeaponList[ i ][ WeaponList_class ][ 0 ] && g_WeaponLists[ i ][ WeaponArray_count ] )
        {
            RegisterHam( Ham_Item_Deploy, WeaponList[ i ][ WeaponList_class ], "Ham_WeaponDeployPost", .Post = true );
        }
    }
}

public plugin_end()
{
    for ( new i = CSW_P228; i <= CSW_P90; i++ )
    {
        ArrayDestroy( g_WeaponLists[ i ][ WeaponArray_List ] );
    }
}

public client_putinserver( id )
{
    UserResetSkins( id );

    if ( g_DefaultSkins )
    {
        SetDefaultSkins( id );
    }
}

public OnClientCommand_Skins( id )
{
    new MenuWeaponContent:content = g_ShowAsCategories ? MenuGetWeapon_Category : g_ShowCollapsed ? MenuGetWeapon_Folder : MenuGetWeapon_Items;
    new menu = MenuGetWeaponsContent( id, content );

    if ( menu != INVALID_HANDLE )
    {
        menu_display( id, menu );
    }
}

public MenuSkins_OnCategorySelect( id, menu, item )
{
    new info[ 3 ], access;

    if ( menu_item_getinfo( menu, item, access, info, charsmax( info ), .callback = access ) )
    {
        if ( info[ 0 ] )
        {
            new categoryMenu = MenuGetWeaponsContent( id, MenuGetWeapon_Folder, str_to_num( info ) );

            if ( categoryMenu != INVALID_HANDLE )
            {
                menu_display( id, categoryMenu );
            }
        }
        else
        {
            UserResetSkins( id );
        }
    }
    menu_destroy( menu );

    return PLUGIN_HANDLED;
}

public MenuSkins_OnFolderSelect( id, menu, item )
{
    new info[ 3 ], access;

    if ( menu_item_getinfo( menu, item, access, info, charsmax( info ), .callback = access ) )
    {
        if ( info[ 0 ] )
        {
            new folderMenu = MenuGetWeaponsContent( id, MenuGetWeapon_Items, str_to_num( info ) );

            if ( folderMenu != INVALID_HANDLE )
            {
                menu_display( id, folderMenu );
            }
        }
        else
        {
            UserResetSkins( id );
        }
    }
    menu_destroy( menu );

    return PLUGIN_HANDLED;
}

public MenuSkins_OnSelect( id, menu, item )
{
    new info[ 92 ], access;

    if ( menu_item_getinfo( menu, item, access, info, charsmax( info ), .callback = access ) )
    {
        if ( info[ 0 ] )
        {
            #define stringit(%0)    %0, charsmax(%0)

            new infoWeaponID[ 3 ];
            new infoSkinID[ 3 ];
            new infoSkin[ 64 ];

            parse( info, stringit( infoWeaponID ), stringit( infoSkinID ), stringit( infoSkin ) );

            new weaponID = str_to_num( infoWeaponID );
            new skinID = str_to_num( infoSkinID );

            g_UserItems[ id ][ weaponID ][ UserData_SkinID ] = skinID;
            copy( g_UserItems[ id ][ weaponID ][ UserData_Skin ], charsmax( g_UserItems[][][ UserData_Skin ] ), infoSkin );

            WeaponTryToDeploy( id, weaponID );

            if ( !g_CloseOnSelect )
            {
                menu = MenuGetWeaponsContent( id, MenuGetWeapon_Items, g_ShowCollapsed ? weaponID : INVALID_HANDLE );

                if ( menu != INVALID_HANDLE )
                {
                    menu_display( id, menu );
                }

                return PLUGIN_HANDLED;
            }
        }
        else
        {
            UserResetSkins( id );
        }
    }
    menu_destroy( menu );

    return PLUGIN_HANDLED;
}

public Ham_WeaponDeployPost( ent )
{
    if ( pev_valid( ent ) == 2 )
    {
        new id = get_pdata_cbase( ent, m_pPlayer, m_iLinuxEntity );
        new iId = get_pdata_int( ent, m_iId, m_iLinuxEntity );

        if ( g_UserItems[ id ][ iId ][ UserData_SkinID ] != INVALID_HANDLE )
        {
            set_pev( id, pev_viewmodel2, g_UserItems[ id ][ iId ][ UserData_Skin ] );
        }
    }
}

MenuGetWeaponsContent( id, MenuWeaponContent:content = MenuGetWeapon_Folder, contentID = INVALID_HANDLE )
{
    new addded;
    new menu;

    switch ( content )
    {
        case MenuGetWeapon_Category:
        {
            menu = menu_create( "[Skin Selector] Choose a category:", "MenuSkins_OnCategorySelect" );

            for ( new category = 0, name[ 32 ], info[ 2 ], count; category < 7; category++ )
            {
                new skins;

                for ( new i = CSW_P228; i <= CSW_P90; i++ )
                {
                    count = g_WeaponLists[ i ][ WeaponArray_count ];

                    if ( count && Categories[ category ][ CategoryData_id ] & (1 << i) )
                    {
                        skins += count;
                    }
                }

                if ( skins )
                {
                    formatex( name, charsmax( name ), "%s (%d %s)", Categories[ category ][ CategoryData_name ], skins, skins > 1 ? "skins" : "skin" );
                    num_to_str( category, info, charsmax( info ) );
                    menu_additem( menu, name, info );
                    addded++;
                }
            }
        }
        case MenuGetWeapon_Folder:
        {
            menu = menu_create( "[Skin Selector] Choose a gun:", "MenuSkins_OnFolderSelect" );

            for ( new i = CSW_P228, name[ 64 ], info[ 3 ], count; i <= CSW_P90; i++ )
            {
                count = g_WeaponLists[ i ][ WeaponArray_count ];

                if ( count )
                {
                    if ( contentID != INVALID_HANDLE && !( Categories[ contentID ][ CategoryData_id ] & (1 << i) ) )
                    {
                        continue;
                    }

                    formatex( name, charsmax( name ), "%s (%d %s)", WeaponList[ i ][ WeaponList_name ], count, count == 1 ? "skin" : "skins" );
                    num_to_str( i, info, charsmax( info ) );
                    menu_additem( menu, name, info );
                    addded++;
                }
            }
        }
        case MenuGetWeapon_Items:
        {
            menu = menu_create( "[Skin Selector] Choose a skin:", "MenuSkins_OnSelect" );

            new bool:useContent = contentID != INVALID_HANDLE;

            for ( new i = useContent ? contentID : CSW_P228, count, info[ 92 ], name[ 64 ]; i <= CSW_P90; i++ )
            {
                count = g_WeaponLists[ i ][ WeaponArray_count ];

                for ( new d = 0, item[ WeaponData ]; d < count; d++ )
                {
                    ArrayGetArray( g_WeaponLists[ i ][ WeaponArray_List ], d, item, WeaponData );
                    formatex( info, charsmax( info ), "%d %d %s", i, d, item[ WeaponSkin ] );

                    if ( g_UserItems[ id ][ i ][ UserData_SkinID ] == d )
                    {
                        formatex( name, charsmax( name ), "\d%s (\ySelected\d)", item[ WeaponName ] );
                        menu_additem( menu, name, .paccess = MENU_PACCESS );
                    }
                    else
                    {
                        menu_additem( menu, item[ WeaponName ], info, GetAccess( id, item[ WeaponFlag ] ) );
                    }
                    addded++;
                }

                if ( useContent )
                {
                    break;
                }
            }
        }
        default:
        {
            log_error( AMX_ERR_NATIVE, "Expected MenuWeaponContent enumerated value, but, received %d.", content );
            return INVALID_HANDLE;
        }
    }

    if ( addded )
    {
        menu_additem( menu, "\rRemove\w skins" );
    }
    else
    {
        menu_addblank2( menu );
        menu_addtext2( menu, "No skin added to server." );
        menu_addblank2( menu );
    }

    return menu;
}

WeaponTryToDeploy( id, weaponID )
{
    if ( is_user_alive( id ) && user_has_weapon( id, weaponID ) )
    {
        if ( get_user_weapon( id ) == weaponID )
        {
            new ent = get_pdata_cbase( id, m_pActiveItem, m_iLinuxPlayer );

            if ( pev_valid( ent ) == 2 )
            {
                ExecuteHamB( Ham_Item_Deploy, ent );
            }
        }
        else
        {
            client_cmd( id, WeaponList[ weaponID ][ WeaponList_class ] );
        }
    }
}

SetDefaultSkins( id )
{
    for ( new i = CSW_P228, count; i <= CSW_P90; i++ )
    {
        count = g_WeaponLists[ i ][ WeaponArray_count ];

        if ( count )
        {
            for ( new d = 0, item[ WeaponData ]; d < count; d++ )
            {
                ArrayGetArray( g_WeaponLists[ i ][ WeaponArray_List ], d, item, WeaponData );

                if ( item[ WeaponDefault ] )
                {
                    g_UserItems[ id ][ i ][ UserData_SkinID ] = d;
                    copy( g_UserItems[ id ][ i ][ UserData_Skin ], charsmax( g_UserItems[][][ UserData_Skin ] ), item[ WeaponSkin ] );
                }
            }
        }
    }
}

UserResetSkins( id )
{
    for ( new i = CSW_P228; i <= CSW_P90; i++ )
    {
        g_UserItems[ id ][ i ][ UserData_SkinID ] = INVALID_HANDLE;
    }
}

GetAccess( id, const flags[] )
{
    if ( !g_IgnoreAccess && flags[ 0 ] )
    {
        if ( g_AccessByFlags )
        {
            return has_all_flags( id, flags ) ? 0 : MENU_PACCESS;
        }
        else
        {
            return has_flag( id, flags ) ? 0 : MENU_PACCESS;
        }
    }
    return 0;
}

LoadSettings( JSON:file )
{
    g_Debug             = json_object_get_bool( file, "settings.debug",             .dot_not = true );
    g_ShowAsCategories  = json_object_get_bool( file, "settings.showAsCategories",  .dot_not = true );
    g_ShowCollapsed     = json_object_get_bool( file, "settings.showCollapsed",     .dot_not = true );
    g_CloseOnSelect     = json_object_get_bool( file, "settings.closeOnSelect",     .dot_not = true );
    g_AccessByFlags     = json_object_get_bool( file, "settings.accessByFlags",     .dot_not = true );
    g_IgnoreAccess      = json_object_get_bool( file, "settings.ignoreAccess",      .dot_not = true );
    g_DefaultSkins      = json_object_get_bool( file, "settings.defaultSkins",      .dot_not = true );
}

LoadSkins( JSON:file )
{
    for ( new i = CSW_P228; i <= CSW_P90; i++ )
    {
        if ( json_object_has_value( file, WeaponList[ i ][ WeaponList_jsonKey ], JSONArray ) )
        {
            g_WeaponLists[ i ][ WeaponArray_List ] = ArrayCreate( WeaponData );

            new JSON:data = json_object_get_value( file, WeaponList[ i ][ WeaponList_jsonKey ] );
            new items = json_array_get_count( data );

            for ( new id = 0; id < items; id++ )
            {
                new JSON:object = json_array_get_value( data, id );

                if ( json_is_object( object ) )
                {
                    new Weapon[ WeaponData ];

                    json_object_get_string( object, "name", Weapon[ WeaponName ], charsmax( Weapon[ WeaponName ] ) );
                    json_object_get_string( object, "model", Weapon[ WeaponSkin ], charsmax( Weapon[ WeaponSkin ] ) );
                    json_object_get_string( object, "admin", Weapon[ WeaponFlag ], charsmax( Weapon[ WeaponFlag ] ) );
                    Weapon[ WeaponDefault ] = json_object_get_bool( object, "default" );

                    if ( !file_exists( Weapon[ WeaponSkin ], true ) )
                    {
                        log_amx( "[ERROR] Missing Skin ^"%s^". Skin skipped.", Weapon[ WeaponSkin ] );
                        continue;
                    }

                    if ( !Weapon[ WeaponName ][ 0 ] )
                    {
                        log_amx( "[ERROR] Missing Skin name of skin ^"%s^". Skin skipped.", Weapon[ WeaponSkin ] );
                        continue;
                    }

                    if ( Weapon[ WeaponFlag ][ 0 ] == 'z' )
                    {
                        Weapon[ WeaponFlag ][ 0 ] = 0;
                    }

                    ArrayPushArray( g_WeaponLists[ i ][ WeaponArray_List ], Weapon, WeaponData );
                    g_WeaponLists[ i ][ WeaponArray_count ]++;

                    precache_model( Weapon[ WeaponSkin ] );
                    json_free( object );
                }
            }
            json_free( data );
        }
    }
}