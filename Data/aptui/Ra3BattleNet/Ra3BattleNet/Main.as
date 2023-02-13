import Ra3BattleNet.ConnectionInformationLoader;
import Ra3BattleNet.ResourcePatcher;

class Ra3BattleNet.Main {
    public function Main(apt: MovieClip) {
        // Ra3's apt does not have getNextHighestDepth, so we have to implement it ourselves
        if (!MovieClip.prototype.getNextHighestDepth) {
            MovieClip.prototype.getNextHighestDepth = function(): Number {
                return getNextHighestDepth(this);
            };
        }

        trace("LOAD SPLASH");
        var splash = apt.createEmptyMovieClip("Ra3BattleNet_Splash", 1);
        trace("SPLASH " + splash);
        splash.loadMovie("Ra3BattleNet_Splash.swf");
        trace("SPLASH " + splash + " LOADED");

        var virtualList = apt.createEmptyMovieClip("Ra3BattleNet_VirtualList", 2);
        trace("VIRTUAL LIST " + virtualList);
        virtualList.loadMovie("Ra3BattleNet_VirtualList.swf");
        trace("VIRTUAL LIST " + virtualList + " LOADED");
        virtualList._visible = false;

        trace("LOAD CONNECTION INFORMATION");
        var connectionInformation = apt.createEmptyMovieClip("Ra3BattleNet_ConnectionInformation", 3);
        trace("CONNECTION INFORMATION " + connectionInformation);
        connectionInformation.loadMovie("Ra3BattleNet_ConnectionInformation.swf");
        trace("CONNECTION INFORMATION " + connectionInformation + " LOADED");

        trace("ADD MESSAGE HANDLER FOR RESOURCE PATCHER");
        _global.gMH.addPriorityMessageHandler(function(messageCode) {
            switch (messageCode) {
                case _global.MSGCODE.FE_MP_UPDATE_GAME_SETTINGS:
                    ConnectionInformationLoader.tryLoadForGameSetup();
                    ResourcePatcher.tryPatchGameSetupBase();
                    break;
                case _global.MSGCODE.IG_PAUSE_MENU_REFRESH_PLAYER_STATUS:
                    ConnectionInformationLoader.tryLoadForPauseMenu();
                    break;
            }
        }, 1);

        trace("CREATE SEND MESSAGE FUNCTION");
        apt.sendMessage = function(message, chatMode, isHostOnly) {
            if (isHostOnly == "1") {
                var ret = new Object();
                loadVariables("QueryGameEngine?IsPcGameHost", ret);
                if (ret.IsPcGameHost != "1") {
                    return;
                }
            }
            fscommand("CallGameFunction", "%SendChatMessage?ChatText=" + message + "|ChatMode=" + chatMode);
        };
    }

    private static function getNextHighestDepth(parent: MovieClip): Number {
        var TRACE_PREFIX: String = "[Ra3BattleNet::getNextHighestDepth] ";
        var depth: Number = 1;
        for (var k: String in parent) {
            if (parent[k] instanceof MovieClip) {
                trace(TRACE_PREFIX + parent[k] + " has depth " + parent[k].getDepth())
                var mc: MovieClip = parent[k];
                if (mc.getDepth() >= depth) {
                    trace(TRACE_PREFIX + mc + " already has depth " + mc.getDepth());
                    depth = mc.getDepth() + 1;
                }
            }
        }
        trace(TRACE_PREFIX + "next depth available in " + parent + " is " + depth);
        return depth;
    }
}