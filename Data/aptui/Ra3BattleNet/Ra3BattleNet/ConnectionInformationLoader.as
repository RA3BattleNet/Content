import Ra3BattleNet.Utils;

class Ra3BattleNet.ConnectionInformationLoader {
    private static var CLASS_NAME = "Ra3BattleNet.ConnectionInformationLoader";
    private static var CONNECTION_INFORMATION_ID: String = "Ra3BattleNet_ConnectionInformation";

    public static function tryLoadForGameSetup(): Void {
        var screenApt: MovieClip = tryGetUnpatchedScreenApt(_global.fem_m_gameSetup);
        if (!screenApt) {
            return;
        }
        trace("[" + CLASS_NAME + "::tryLoadForGameSetup] loading outgame");
        loadConnectionInformation(screenApt);
    }

    public static function tryLoadForPauseMenu(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::tryLoadForPauseMenu] ";
        // igm_pauseMenu has no suitable message handlers to reliably detect when it is shown
        // so we have to check every frame
        // we check for 30 frames and then give up
        var intervalId: Number;
        var deadline: Number = 30;
        intervalId = setInterval(function() {
            --deadline;
            if (deadline <= 0) {
                clearInterval(intervalId);
                trace(TRACE_PREFIX + "gave up");
                return;
            }
            var screenApt: MovieClip = tryGetUnpatchedScreenApt(_global.igm_pauseMenu);
            if (!screenApt) {
                trace(TRACE_PREFIX + "pause menu not found");
                return;
            }
            trace(TRACE_PREFIX + "loading ingame");
            loadConnectionInformation(screenApt);
            clearInterval(intervalId);
        }, 30);
        trace(TRACE_PREFIX + "waiting for pause menu");
    }

    private static function tryGetUnpatchedScreenApt(screenConstructor: Function): MovieClip {
        if (typeof screenConstructor !== "function") {
            return undefined;
        }
        if (!_global.Cafe2_BaseUIScreen) {
            return undefined;
        }
        var screenInstance = _global.Cafe2_BaseUIScreen.m_thisClass;
        if (!screenInstance) {
            return undefined;
        }
        if (!Utils.instanceOf(screenInstance, screenConstructor)) {
            return undefined;
        }
        var screenApt: MovieClip = _global.Cafe2_BaseUIScreen.m_screen;
        if (typeof(screenApt[CONNECTION_INFORMATION_ID]) === "movieclip") {
            // Already patched
            return undefined;
        }
        return screenApt;
    }

    private static function loadConnectionInformation(target: MovieClip): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::loadConnectionInformation] ";
        var apt: MovieClip = target.createEmptyMovieClip(
            CONNECTION_INFORMATION_ID,
            target.getNextHighestDepth()
        );
        apt.loadMovie(CONNECTION_INFORMATION_ID + ".swf");
        trace(TRACE_PREFIX + "loaded " + apt + " on " + target);
    }
}