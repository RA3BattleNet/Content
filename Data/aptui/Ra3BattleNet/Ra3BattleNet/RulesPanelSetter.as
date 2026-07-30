import Ra3BattleNet.Utils;

class Ra3BattleNet.RulesPanelSetter {
    private static var CLASS_NAME = "Ra3BattleNet.RulesPanelSetter";
    private static var OUR_GAME_SETUP_KEY_NAME = "Ra3BattleNet_OurGameSetup";
    private static var inGameSetup: Boolean = false;
    private static var coronaBroadcastMaps: Array = null;
    private static var shouldSmartEnableBroadcast: Boolean = false;
    private static var lastMapNameKey: String = null;

    public static function getCoronaEnableBroadcastMaps() {
        if (coronaBroadcastMaps != null) {
            return coronaBroadcastMaps;
        }
        var array: Array = new Array();
        array.push("MAP_MP_2_FEASEL1");
        array.push("MAP_MP_2_BLACK1B");
        array.push("MAP_MP_2_FEASEL5");
        array.push("MAP_MP_2_FEASEL8");
        array.push("MAP_MP_2_RAO1");
        array.push("MAP_MP_2_FEASEL4");
        array.push("MAP_MP_2_FEASEL6");
        array.push("Cabana_Republic");
        array.push("Aquae_Caerulea");
        array.push("Chrysoberyl_Garden");
        array.push("Temple_Legend");
        array.push("Mechanical_Force");
        array.push("Pilgrimages_End");
        array.push("Redemption_Base");
        array.push("Secret_Island");
        array.push("map_mp_4_");
        array.push("cor_archon_2v2_");
        array.push("Sand_Fiery_Today");
        array.push("Stick_To_The_Territory");
        array.push("Volcanic_Citadel");
        array.push("Imperial_Dynasty");
        array.push("map_mp_6_");
        array.push("Hot_Conflict");
        array.push("Pool_March");
        array.push("Paradise_Valley");
        array.push("Isle_of_Outcasts");
        array.push("Snowtop_Conqueror");
        array.push("Spring_Showdown");
        array.push("Vestige_Assault");
        for (var i: Number = 0; i < array.length; ++i) {
            array[i] = array[i].toLowerCase();
        }
        coronaBroadcastMaps = array;
        return coronaBroadcastMaps;
    }

    public static function update(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::update] ";
        trace(TRACE_PREFIX);

        tryPatchOnlineGameSetup();

        // Check if we are in game setup
        if (!_global.Cafe2_BaseUIScreen) {
            inGameSetup = false;
            return;
        }
        var screenInstance = _global.Cafe2_BaseUIScreen.m_thisClass;
        if (!screenInstance) {
            inGameSetup = false;
            return;
        }
        var playerApts: Array = screenInstance.m_playerSlots;
        if (!playerApts || typeof(playerApts[0]) !== "movieclip") {
            inGameSetup = false;
            return;
        }

        // Now we are setting up the game
        // Check if this is the first time of entring game setup
        inGameSetup = true;
        var gameSetup = _global.Cafe2_BaseUIScreen.m_screen;
        var ourValue = gameSetup[OUR_GAME_SETUP_KEY_NAME];
        if (ourValue === true) {
            // already set up, no need to do it again
            // but we can refresh broadcast checkbox visibility
            if (gameSetup.refreshRulesCheckbox != undefined
                && gameSetup.gameSettings.rulesPanel.broadcastCheckbox != undefined) {
                gameSetup.refreshRulesCheckbox("GAME_BROADCASTER", gameSetup.gameSettings.rulesPanel.broadcastCheckbox);
            }
            return;
        }
        trace(TRACE_PREFIX + "First time entering game setup, setting up rules panel");
        gameSetup[OUR_GAME_SETUP_KEY_NAME] = true;
        
        // Check host
        var ret = new Object();
        loadVariables("QueryGameEngine?IsPcGameHost", ret);
        if (ret.IsPcGameHost != "1") {
            return;
        }
        // Turn off VoIP
        fscommand("CallGameFunction", "%ToggleVoipRule");
        if (gameSetup.refreshRulesCheckbox != undefined) {
            gameSetup.refreshRulesCheckbox("ENABLE_VOIP", gameSetup.gameSettings.rulesPanel.enableVoipCheckbox);
        }
        // Select last map on next frame
        selectLastMapOnNextFrame();
        // Play button callback
        if (!gameSetup.playButton.m_mouseDownFunction) {
            gameSetup.playButton.setOnMouseDownFunction(onPlayButtonClick);
        }
        // Check mod
        ret = new Object();
        loadVariables("QueryGameEngine?DISABLE_BROADCAST_ON_MOD", ret);
        if(ret.DISABLE_BROADCAST_ON_MOD == 1) {
            shouldSmartEnableBroadcast = true;
            return;
        }
        // Check the checkbox
        enableBroadcast(gameSetup);
    }

    private static function tryPatchOnlineGameSetup() {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::tryPatchOnlineGameSetup] ";
        trace(TRACE_PREFIX);
        if (_global.fem_m_gameSetup == null) {
            trace(TRACE_PREFIX + "fem_m_gameSetup not loaded yet");
            return;
        }
        var onlineGameSetupPrototype = _global.fem_m_gameSetup.prototype;

        // initBroadcastOption
        if (onlineGameSetupPrototype.originalInitBroadcastOption != undefined) {
            trace(TRACE_PREFIX + "fem_m_gameSetup already patched");
            return;
        }
        onlineGameSetupPrototype.originalInitBroadcastOption = onlineGameSetupPrototype.initBroadcastOption;
        onlineGameSetupPrototype.initBroadcastOption = function() {
            newInitBroadcastOption(this);
        };
        onlineGameSetupPrototype.originalOnToggleBroadcastStatus = onlineGameSetupPrototype.onToggleBroadcastStatus;
        onlineGameSetupPrototype.onToggleBroadcastStatus = function() {
            newOnToggleBroadcastStatus(this);
        };
        trace(TRACE_PREFIX + "fem_m_gameSetup patched");
    }

    private static function newInitBroadcastOption(self) {
        if (self.originalInitBroadcastOption != null) {
            self.originalInitBroadcastOption();
        }
        if (self.setBroadcastCheckboxVisibility != null) {
            self.setBroadcastCheckboxVisibility(true);
        }
    }

    private static function newOnToggleBroadcastStatus(self) {
        if (self.originalOnToggleBroadcastStatus != null) {
            self.originalOnToggleBroadcastStatus();
        }
        shouldSmartEnableBroadcast = false;
    }

    private static function selectLastMapOnNextFrame() {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::selectLastMapOnNextFrame] ";
        if (!lastMapNameKey) {
            trace(TRACE_PREFIX + "No last map name key to select");
            return;
        }
        var intervalId: Number;
        intervalId = setInterval(function() {
            clearInterval(intervalId);

            var mapIds = _global.Cafe2_BaseUIScreen.m_thisClass.m_mapIds;
            if (!mapIds) {
                trace(TRACE_PREFIX + "mapIds not found, cannot select last map");
                return;
            }
            if (!mapIds.length || mapIds.length <= 0) {
                trace(TRACE_PREFIX + "mapIds is empty, cannot select last map");
                return;
            }
            // Check if last map is in the list
            var found = false;
            for (var i: Number = 0; i < mapIds.length; ++i) {
                if (mapIds[i] === lastMapNameKey) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                trace(TRACE_PREFIX + "Last map not found in mapIds, cannot select");
                return;
            }
            trace(TRACE_PREFIX + "Selecting last map: " + lastMapNameKey);
            fscommand("CallGameFunction", "%SetMap?Map=" + lastMapNameKey);
            _global.Cafe2_BaseUIScreen.m_thisClass.refreshMapList();
        }, 40);
    }

    private static function onPlayButtonClick() {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::onPlayButtonClick] ";
        var mapQuery = new Object();
        loadVariables("Ra3BattleNet_Map", mapQuery);
        var nameKey = mapQuery.CURRENT_MAP_NAMEKEY;
        trace(TRACE_PREFIX + "Current map name key: " + nameKey);
        lastMapNameKey = nameKey;

        if (shouldSmartEnableBroadcast) {
            smartEnableBroadcastIfNeeded(decodeCurrentMapToLowerCase(mapQuery.CURRENT_MAP_UNICODE));
        }
    }

    private static function smartEnableBroadcastIfNeeded(currentMapLower: String) {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::smartEnableBroadcastIfNeeded] ";
        var gameSetup = _global.Cafe2_BaseUIScreen.m_screen;
        var ourValue = gameSetup[OUR_GAME_SETUP_KEY_NAME];
        if (ourValue !== true) {
            // for some reason this is not our game setup, we cannot do anything
            trace(TRACE_PREFIX + "Not our game setup, cannot smart enable broadcast");
            return;
        }
        if (isPve()) {
            return;
        }
        if (!isCurrentMapInCoronaBroadcastMaps(currentMapLower)) {
            return;
        }
        trace(TRACE_PREFIX + "Enabling broadcast for map: " + currentMapLower);
        enableBroadcast(gameSetup);
    }

    private static function decodeCurrentMapToLowerCase(unicode: String): String {
        if (!unicode) {
            trace("Ra3BattleNet_Map not set, cannot decode map name");
            return;
        }
        var codes: Array = unicode.split(",");
        var mapName: String = "";
        for (var i: Number = 0; i < codes.length; ++i) {
            mapName += String.fromCharCode(codes[i]);
        }
        return mapName.toLowerCase();
    }

    private static function isCurrentMapInCoronaBroadcastMaps(mapNameLower: String) {
        var broadcastMaps: Array = getCoronaEnableBroadcastMaps();
        for (var i: Number = 0; i < broadcastMaps.length; ++i) {
            if (mapNameLower.indexOf(broadcastMaps[i]) >= 0) {
                return true;
            }
        }
        return false;
    }

    private static function isPve() {
        var playerSlots: Array = _global.Cafe2_BaseUIScreen.m_thisClass.m_playerSlots;
        if (!playerSlots) {
            return false;
        }
        for (var i = 0; i < playerSlots.length; ++i) {
            var personalityOptions = playerSlots[i].personalityOptions;
            if (!personalityOptions) {
                continue;
            }
            var itemValues = personalityOptions.m_itemValues;
            if (!itemValues) {
                continue;
            }
            if (itemValues.length && itemValues.length > 0) {
                return true;
            }
        }
        return false;
    }

    private static function enableBroadcast(gameSetup) {
        shouldSmartEnableBroadcast = false;
        if (!gameSetup.gameSettings.rulesPanel.broadcastCheckbox
            || !gameSetup.gameSettings.rulesPanel.broadcastCheckbox._visible) {
            return;
        }
        // check if broadcast is enabled
        var broadcastQuery = new Object();
        loadVariables("QueryGameEngine?GAME_BROADCASTER", broadcastQuery);
        if (broadcastQuery.GAME_BROADCASTER_VALUE == "1") {
            // already enabled
            return;
        }
        gameSetup.gameSettings.rulesPanel.broadcastCheckbox.check();
        fscommand("CallGameFunction", "%ToggleBroadcastGame");
        if (gameSetup.refreshRulesCheckbox != undefined) {
            gameSetup.refreshRulesCheckbox("GAME_BROADCASTER", gameSetup.gameSettings.rulesPanel.broadcastCheckbox);
        }
    }
}
