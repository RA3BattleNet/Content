import Ra3BattleNet.AutoMatchHelperLoader;
import Ra3BattleNet.BroadcastSetter;
import Ra3BattleNet.ConnectionInformationLoader;
import Ra3BattleNet.DisconnectHelper;
import Ra3BattleNet.ResourcePatcher;
import Ra3BattleNet.Utils;

class Ra3BattleNet.Main {
    public function Main(apt: MovieClip) {
        // Ra3's apt does not have getNextHighestDepth, so we have to implement it ourselves
        if (!apt.getNextHighestDepth) {
            MovieClip.prototype.getNextHighestDepth = getNextHighestDepth;
            trace("ADDED GET NEXT HIGHEST DEPTH TO APT: " + apt.getNextHighestDepth);
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

        trace("CREATE AUTO MATCH HELPER");
        AutoMatchHelperLoader.startWatch();

        trace("ADD MESSAGE HANDLERS");
        _global.gMH.addPriorityMessageHandler(function(messageCode) {
            switch (messageCode) {
                case _global.MSGCODE.FE_MP_UPDATE_GAME_SETTINGS:
                    ConnectionInformationLoader.tryLoadForGameSetup();
                    ResourcePatcher.tryPatchGameSetupBase();
                    BroadcastSetter.update();
                    break;
                case _global.MSGCODE.FE_SHOW_MP_DISCONNECT:
                    DisconnectHelper.createDisconnectHelper(apt);
                    break;
                case _global.MSGCODE.FE_HIDE_MP_DISCONNECT:
                    DisconnectHelper.destroyDisconnectHelper(apt);
                    break;
                case _global.MSGCODE.IGM_OPEN_SHELL_ROOT:
                    ConnectionInformationLoader.tryLoadForPauseMenu();
                    break;
            }
            return false;
        }, -1);

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

    private function getNextHighestDepth(): Number {
        var TRACE_PREFIX: String = "[Ra3BattleNet::getNextHighestDepth] ";
        var depth: Number = 1;
        for (var k: String in this) {
            if (k === "_parent") {
                trace(TRACE_PREFIX + "skipping _parent");
                continue;
            }
            if (this[k].getDepth) {
                var existingDepth: Number = Number(this[k].getDepth());
                if (isNaN(existingDepth)) {
                    trace(TRACE_PREFIX + k + " -> " + this[k] + " depth is NaN, skipping");
                    continue;
                }
                if (existingDepth >= depth) {
                    trace(TRACE_PREFIX + this[k] + " already has depth " + depth);
                    depth = existingDepth + 1;
                }
            }
        }
        trace(TRACE_PREFIX + "next depth available in " + this + " is " + depth);
        return depth;
    }
}