# Description
Define a list of view models and let players choose it in-game.

# Features
* Ability to set view models by access groups
* Ability to seet default view models
* Ability to define look-and-feel of menus

# Settings
All mod settings goes inside `configs/skins.json` as follow:

key                         | description
----------------------------|------------
settings.`debug`            | Logs resource loading list on start if `true`.
settings.`showAsCategories` | If `true`, shows menus as weapon-type categories.
settings.`showCollapsed`    | If `true`, shows menus as weapon-like categories.
settings.`closeOnSelect`    | If `true`, menus will close right after player select a skin. Othersiwe, it'll keep open.
settings.`accessByFlags`    | If `true`, access-defined skins will require player to have the whole access pair defined. Otherwise any of the accessess will be valid.
settings.`ignoreAccess`     | If `true`, skips the authentication process.
settings.`defaultSkins`     | If `true`, default view-models will be set for each user. Users can still disable it.

# Examples
`configs/skins.json`, `weapon_deagle`:
```json
"deagle":
[
    {
        "name": "DEAGLE Biohazard",
        "model": "models/AdamRichard21st/deagle_biohazard.mdl",
        "default": true
    },
    {
        "name": "DEAGLE Blaze (Admin Only)",
        "model": "models/AdamRichard21st/deagle_blaze.mdl",
        "admin": "ab"
    }
],
```
`configs/skins.json`, `weapon_m4a1`:
```json
"m4a1":
[
    {
        "name": "M4A1-S Boreal Forest",
        "model": "models/AdamRichard21st/m4a1_bforest.mdl",
        "default": true
    },
    {
        "name": "M4A1-S Flashback",
        "model": "models/AdamRichard21st/m4a1_flashback.mdl"
    },
    {
        "name": "M4A4 Asiimov",
        "model": "models/AdamRichard21st/m4a4_asiimov.mdl"
    },
    {
        "name": "M4A4 Howl (Admin Only)",
        "model": "models/AdamRichard21st/m4a4_howl.mdl",
        "admin": "ab"
    }
],
```

# Commands
command     | description
------------|----------------------
say /skins  | Opens view model menu

# Installation
First and foremost, your server must to have [amxmodx](https://wiki.alliedmods.net/Category:Documentation_(AMX_Mod_X)#Installation) installed & running.

* Copy `skins.json` settings file to `$addons/amxmodx/configs` folder in your server.
* Copy `SkinSelector.amxx` to `$addons/amxmodx/plugins` folder in your server.
* Add `SkinSelector.amxx` line to your `plugins.ini` file located at `addons/amxmodx/configs` folder.

[read more](https://wiki.alliedmods.net/Configuring_AMX_Mod_X#Plugins)

# Compilation details
```
AMX Mod X Compiler 1.9.0.5241
Copyright (c) 1997-2006 ITB CompuPhase
Copyright (c) 2004-2013 AMX Mod X Team

Header size:           1620 bytes
Code size:            12688 bytes
Data size:           279872 bytes
Stack/heap size:      16384 bytes
Total requirements:  310564 bytes
Done.
```

# Want to help?
Feel free to suggest changes or create [pull requests](https://help.github.com/en/articles/about-pull-requests) to this repository, including source changes or dictionary translations improvements/additions.
