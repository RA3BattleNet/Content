class Ra3BattleNet.ConnectionInformationLoader {
    private static var CLASS_NAME = "Ra3BattleNet.ConnectionInformationLoader";
    private static var CONNECTION_INFORMATION_ID: String = "Ra3BattleNet_ConnectionInformation";

    public static function tryLoadForGameSetup(): Void {
        if (!_global.fem_m_gameSetup) {
            return;
        }
        var screen = tryGetUnpatchedScreen();
        if (!instanceOf(screen, _global.fem_m_gameSetup)) {
            return;
        }
        trace("[" + CLASS_NAME + "::tryLoadForGameSetup] loading outgame");
        loadConnectionInformation(screen.m_screen);
    }

    public static function tryLoadForPauseMenu(): Void {
        if (!_global.igm_pauseMenu) {
            return;
        }
        var screen = tryGetUnpatchedScreen();
        if (!instanceOf(screen, _global.igm_pauseMenu)) {
            return;
        }
        trace("[" + CLASS_NAME + "::tryLoadForPauseMenu] loading ingame");
        loadConnectionInformation(screen.m_screen);
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
            target.getNextHighestDepth()
        );
        apt.loadMovie(CONNECTION_INFORMATION_ID + ".swf");
        trace(TRACE_PREFIX + "loaded " + apt);
    }

    // https://github.com/lanyizi/apt-danmaku/blob/23f9e7ea6c6e4b5be84dd8552fdb28902010af03/Data/AptUI/feg_m_mainMenu3d/danmaku/GameObject.as#L148
    private static function instanceOf(self, check): Boolean {
        if (!self) {
            return false;
        }
        self = typeof self === 'function'
            ? self.prototype
            : self.__proto__;
        check = typeof check === 'function'
            ? check.prototype
            : check.__proto__;
        while (self) {
            if (self === check) {
                return true;
            }
            self = self.__proto__;
        }
        return false;
    }
}