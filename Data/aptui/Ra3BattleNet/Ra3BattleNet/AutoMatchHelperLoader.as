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
        tryUnload();
    }

    private static function watch(): Void {
        if (!_global.fem_m_onlineMultiplayer) {
            // online multiplayer constructor does not exist
            // if automatch helper is loaded, unload it
            tryUnload();
            return;
        }
        if (tryUpdate()) {
            // automatch helper is loaded and updated
            return;
        }
        // automatch helper is not loaded, try to load it
        load();
    }

    private static function tryUpdate(): Boolean {
        var helper = _global.Ra3BattleNet.AutoMatchHelper;
        if (!helper) {
            return false;
        }

        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::tryUpdate] ";
        var apt: MovieClip = helper.apt;
        if (typeof apt !== "movieclip") {
            trace(TRACE_PREFIX + "apt does not exist");
            return false;
        }
        var update: Function = _global.Ra3BattleNet.AutoMatchHelper.update;
        if (typeof update !== "function") {
            trace(TRACE_PREFIX + "update is not a function");
            return false;
        }
        trace(TRACE_PREFIX + "updating");
        update();
        return true;
    }

    private static function load(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::load] ";
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

        var helper: MovieClip = autoMatchPanel[HELPER_ID];
        if (typeof helper === "movieclip") {
            trace(TRACE_PREFIX + "helper already exists");
            return;
        }

        trace(TRACE_PREFIX + "creating helper");
        autoMatchPanel.createEmptyMovieClip(HELPER_ID, autoMatchPanel.getNextHighestDepth());
        autoMatchPanel.loadMovie(HELPER_ID + ".swf");
        helper = autoMatchPanel[HELPER_ID];
        if (typeof helper !== "movieclip") {
            trace(TRACE_PREFIX + "failed to create helper");
            return;
        }
    }

    private static function tryUnload(): Void {
        if (!_global.Ra3BattleNet.AutoMatchHelper) {
            return;
        }

        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::tryUnload] ";
        var apt: MovieClip = _global.Ra3BattleNet.AutoMatchHelper.apt;
        if (apt) {
            trace(TRACE_PREFIX + "apt exists, unloading");
            apt.unloadMovie();
            delete _global.Ra3BattleNet.AutoMatchHelper.apt;
        }
        delete _global.Ra3BattleNet.AutoMatchHelper;
        trace(TRACE_PREFIX + "unloaded class: " + _global.Ra3BattleNet.AutoMatchHelper);
    }
}
