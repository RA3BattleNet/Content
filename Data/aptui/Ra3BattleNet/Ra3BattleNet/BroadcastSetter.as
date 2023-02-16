import Ra3BattleNet.Utils;

class Ra3BattleNet.BroadcastSetter {
    private static var CLASS_NAME = "Ra3BattleNet.BroadcastSetter";
    private static var inGameSetup: Boolean = false;

    public static function update(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::update] ";
        trace(TRACE_PREFIX);

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
        // Check host
        var ret = new Object();
        loadVariables("QueryGameEngine?IsPcGameHost",ret);
        if (ret.IsPcGameHost != "1") {
            return;
        }
        // Check mod
        var ret = new Object();
        loadVariables("QueryGameEngine?DISABLE_BROADCAST_ON_MOD",ret);
        if(ret.DISABLE_BROADCAST_ON_MOD == 1) {
            return;
        }
        _global.Cafe2_BaseUIScreen.m_screen.gameSettings.rulesPanel.broadcastCheckbox.check();
        fscommand("CallGameFunction", "%ToggleBroadcastGame");
    }
}
