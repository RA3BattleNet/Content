import Ra3BattleNet.ConnectionInformationLoader;
import Ra3BattleNet.DisconnectHelper;
import Ra3BattleNet.ResourcePatcher;
import Ra3BattleNet.Utils;

class Ra3BattleNet.Main {
    public function Main(apt: MovieClip) {
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

        trace("ADD MESSAGE HANDLERS");
        _global.gMH.addPriorityMessageHandler(function(messageCode) {
            switch (messageCode) {
                case _global.MSGCODE.FE_MP_UPDATE_GAME_SETTINGS:
                    ConnectionInformationLoader.tryLoadForGameSetup();
                    ResourcePatcher.tryPatchGameSetupBase();
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
}