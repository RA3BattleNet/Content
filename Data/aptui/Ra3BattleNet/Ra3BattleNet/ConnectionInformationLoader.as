import Ra3BattleNet.Utils;

class Ra3BattleNet.ConnectionInformationLoader {
    private static var CLASS_NAME = "Ra3BattleNet.ConnectionInformationLoader";
    private static var CONNECTION_INFORMATION_ID: String = "Ra3BattleNet_ConnectionInformation";

    public static function tryLoadForGameSetup(): Void {
        if (!_global.fem_m_gameSetup) {
            return;
        }
        var screen = tryGetUnpatchedScreen();
        if (!Utils.instanceOf(screen, _global.fem_m_gameSetup)) {
            return;
        }
        trace("[" + CLASS_NAME + "::tryLoadForGameSetup] loading outgame");
        loadConnectionInformation(_global.Cafe2_BaseUIScreen.m_screen);
    }

    public static function tryLoadForPauseMenu(): Void {    
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::tryLoadForPauseMenu] ";
        // igm_pauseMenu has no suitable message handlers to reliably detect when it is shown
        // so we have to check every frame
        // we check for 10 frames and then give up
        var intervalId: Number;
        var deadline: Number = 10;
        intervalId = setInterval(function() {
            --deadline;
            if (deadline <= 0) {
                clearInterval(intervalId);
                trace(TRACE_PREFIX + "gave up");
                return;
            }
            if (!_global.igm_pauseMenu) {
                trace(TRACE_PREFIX + "no pause menu");
                return;
            }
            var screen = tryGetUnpatchedScreen();
            if (!Utils.instanceOf(screen, _global.igm_pauseMenu)) {
                trace(TRACE_PREFIX + "not pause menu");
                return;
            }
            trace(TRACE_PREFIX + "loading ingame");
            loadConnectionInformation(_global.Cafe2_BaseUIScreen.m_screen);
            clearInterval(intervalId);
        }, 1000 / 30);
        trace(TRACE_PREFIX + "waiting for pause menu");
    }

    private static function tryGetUnpatchedScreen() {
        if (!_global.Cafe2_BaseUIScreen) {
            return undefined;
        }
        var screenInstance = _global.Cafe2_BaseUIScreen.m_thisClass;
        if (!screenInstance) {
            return undefined;
        }
        if (screenInstance[CONNECTION_INFORMATION_ID] instanceof MovieClip) {
            // Already patched
            return undefined;
        }
        return screenInstance;
    }

    private static function loadConnectionInformation(target: MovieClip): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::loadConnectionInformation] ";
        var apt: MovieClip = target.createEmptyMovieClip(
            CONNECTION_INFORMATION_ID,
            Utils.getNextHighestDepth(target)
        );
        apt.loadMovie(CONNECTION_INFORMATION_ID + ".swf");
        trace(TRACE_PREFIX + "loaded " + apt + " on " + target);
    }
}