class Ra3BattleNet.DisconnectHelper {
    private static var CLASS_NAME = "Ra3BattleNet.DisconnectHelper";
    private static var DISCONNECT_HELPER_ID: String = "Ra3BattleNet_DisconnectHelper";

    public static function createDisconnectHelper(apt) {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::createDisconnectHelper] ";
        trace(TRACE_PREFIX);
        var helper: MovieClip = apt.createEmptyMovieClip(
            DISCONNECT_HELPER_ID,
            apt.getNextHighestDepth()
        );
        helper.onEnterFrame = function() {
            trace("DISCONNECT_INFO");
            var ret = new Object();
            loadVariables("QueryGameEngine?DISCONNECT_INFO", ret);
            var times = ret.DISCONNECT_INFO_TIMES.split(",");
            var screen = tryGetUnpatchedScreen();
            trace(screen);
            trace(_global.fem_m_load);
            var isLoading = _global.fem_m_load and instanceOf(screen, _global.fem_m_load);
            trace(isLoading);
            for (var i = 0; i < times.length; i++)
            {
                if (Number(times[i]) < 25)
                {
                    trace("FIND LESS THAN 25 DISCONNECT COUNTER");
                    if (isLoading)
                    {
                        trace("DISCONNECT!");
                        fscommand("CallGameFunction", "%DisconnectQuitGame");
                    }
                }
            }
        }
        trace(TRACE_PREFIX + "HELPER CREATED");
    }

    private static function tryGetUnpatchedScreen() {
        if (!_global.Cafe2_BaseUIScreen) {
            return undefined;
        }
        var screenInstance = _global.Cafe2_BaseUIScreen.m_thisClass;
        if (!screenInstance) {
            return undefined;
        }
        return screenInstance;
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
