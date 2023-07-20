import Ra3BattleNet.Utils;

class Ra3BattleNet.DisconnectHelper {
    private static var CLASS_NAME = "Ra3BattleNet.DisconnectHelper";
    private static var DISCONNECT_HELPER_ID: String = "Ra3BattleNet_DisconnectHelper";

    public static function createDisconnectHelper(apt: MovieClip): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::createDisconnectHelper] ";
        trace(TRACE_PREFIX);
        destroyDisconnectHelper(apt);
        var helper: MovieClip = apt.createEmptyMovieClip(
            DISCONNECT_HELPER_ID,
            apt.getNextHighestDepth()
        );
        helper.onEnterFrame = update;
        trace(TRACE_PREFIX + "Helper created: " + helper + ", update: " + helper.onEnterFrame);

        // try to report alive (if possible) so the fair play server can judge
        // the disconnected match as a win for the player who is still alive
        var noResultExpected: Object = new Object();
        loadVariables("Ra3BattleNet_ReportAlive", noResultExpected);
    }

    public static function destroyDisconnectHelper(apt: MovieClip): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::destroyDisconnectHelper] ";
        trace(TRACE_PREFIX);
        if (typeof(apt[DISCONNECT_HELPER_ID]) === "movieclip") {
            apt[DISCONNECT_HELPER_ID].removeMovieClip();
            trace(TRACE_PREFIX + "Helper destroyed -> " + apt[DISCONNECT_HELPER_ID]);
        }
    }

    private static function update(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::update] ";
        trace(TRACE_PREFIX);

        if (!_global.Cafe2_BaseUIScreen) {
            return;
        }
        var screen = _global.Cafe2_BaseUIScreen.m_thisClass;
        if (!screen) {
            return;
        }
        trace(TRACE_PREFIX + "screen: " + screen + ", fem_m_load: " + _global.fem_m_load);
        var isLoading: Boolean = _global.fem_m_load
            && Utils.instanceOf(screen, _global.fem_m_load);
        trace(TRACE_PREFIX + "isLoading: " + isLoading);
        if (!isLoading) {
            return;
        }

        var ret: Object = new Object();
        loadVariables("QueryGameEngine?DISCONNECT_INFO", ret);
        var times: Array = ret.DISCONNECT_INFO_TIMES.split(",");
        for (var i = 0; i < times.length; i++) {
            if (Number(times[i]) < 25) {
                trace(TRACE_PREFIX + "Found less than 25 disconnect counter, disconnect!");
                fscommand("CallGameFunction", "%DisconnectQuitGame");
                break;
            }
        }
    }
}
