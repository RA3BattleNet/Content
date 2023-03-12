import Ra3BattleNet.Utils;

class Ra3BattleNet.AutoMatchHelperLoader {
    private static var CLASS_NAME: String = "Ra3BattleNet.AutoMatchHelperLoader";
    private static var HELPER_ID: String = "Ra3BattleNet_AutoMatchHelper";
    private static var _intervalId: Number;

    public static function startWatch(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::startWatch] ";
        if (_intervalId) {
            trace(TRACE_PREFIX + "already watching: " + _intervalId);
            return;
        }
        trace(TRACE_PREFIX + "setting interval");
        _intervalId = setInterval(watch, 500);
    }

    public static function stopWatch(): Void {
        trace("[" + CLASS_NAME + "::stopWatch] clearing interval");
        clearInterval(_intervalId);
        delete _intervalId;
    }

    private static function watch(): Void {
        if (!_global.fem_m_onlineMultiplayer) {
            return;
        }
        // online multiplayer constructor exists
        // try to load helper if not already loaded
        tryLoad();
    }

    private static function tryLoad(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::tryLoad] ";
        if (!Utils.instanceOf(_global.Cafe2_BaseUIScreen.m_thisClass, _global.fem_m_onlineMultiplayer)) {
            trace(TRACE_PREFIX + "online multiplayer constructor exists but screen is not online multiplayer");
            return;
        }
        var screen: MovieClip = _global.Cafe2_BaseUIScreen.m_screen;
        if (typeof screen !== "movieclip") {
            trace(TRACE_PREFIX + "screen is not a movieclip");
            return;
        }
        var autoMatchPanel: MovieClip = screen.autoMatchPanel;
        if (typeof autoMatchPanel !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchPanel is not a movieclip");
            return;
        }
        var autoMatchSetup: MovieClip = autoMatchPanel.autoMatchSetup;
        if (typeof autoMatchSetup !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchSetup is not a movieclip");
            return;
        }
        var helper: MovieClip = autoMatchSetup[HELPER_ID];
        if (typeof helper === "movieclip") {
            // already exists
            return;
        }

        trace(TRACE_PREFIX + "creating helper");
        autoMatchSetup.createEmptyMovieClip(HELPER_ID, autoMatchSetup.getNextHighestDepth());
        helper = autoMatchSetup[HELPER_ID];
        if (typeof helper !== "movieclip") {
            trace(TRACE_PREFIX + "failed to create helper");
            return;
        }
        helper.loadMovie(HELPER_ID + ".swf");
        trace(TRACE_PREFIX + "helper loaded");
    }
}
