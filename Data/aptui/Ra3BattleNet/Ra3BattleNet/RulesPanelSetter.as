import Ra3BattleNet.Utils;

class Ra3BattleNet.RulesPanelSetter {
    private static var CLASS_NAME = "Ra3BattleNet.RulesPanelSetter";
    private static var inGameSetup: Boolean = false;

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
        if (inGameSetup) {
            return;
        }

        inGameSetup = true;
        var gameSetup = _global.Cafe2_BaseUIScreen.m_screen;
        
        // Check host
        var ret = new Object();
        loadVariables("QueryGameEngine?IsPcGameHost",ret);
        if (ret.IsPcGameHost != "1") {
            return;
        }
        // Turn off VoIP
        fscommand("CallGameFunction", "%ToggleVoipRule");
        if (gameSetup.refreshRulesCheckbox != undefined) {
            gameSetup.refreshRulesCheckbox("ENABLE_VOIP", gameSetup.gameSettings.rulesPanel.enableVoipCheckbox);
        }
        // Check mod
        var ret = new Object();
        loadVariables("QueryGameEngine?DISABLE_BROADCAST_ON_MOD",ret);
        if(ret.DISABLE_BROADCAST_ON_MOD == 1) {
            return;
        }
        // Check the checkbox
        gameSetup.gameSettings.rulesPanel.broadcastCheckbox.check();
        fscommand("CallGameFunction", "%ToggleBroadcastGame");
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
}
