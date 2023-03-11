import Ra3BattleNet.Utils;

class Ra3BattleNet.AutoMatchHelper {
    private static var CLASS_NAME: String = "Ra3BattleNet.AutoMatchHelper";
    private static var IDENTIFIER_PREFIX: String = "Ra3BattleNet_AutoMatchHelper_";
    private static var RANKED_CONTAINER: String = IDENTIFIER_PREFIX + "RankedContainer";
    private static var RANKED_CHECKBOX: String = "rankedCheckBox";
    private static var RANKED_CHECKBOX_OFFSET_Y: Number = -30;
    private static var RANKED_LABEL_OFFSET_X: Number = 22.5;
    private static var RANKED_LABEL_OFFSET_Y: Number = -11.5;
    private static var RANKED_DETAILS_OFFSET_X: Number = 0;
    private static var RANKED_DETAILS_OFFSET_Y: Number = -5;
    private static var RANKED_DETAILS_WIDTH: Number = 500;
    private static var RANKED_DETAILS_HEIGHT: Number = 60;
    private static var _internalId: Number;

    public static function startWatch(): Void {
        trace("[" + CLASS_NAME + "::startWatch] setting interval");
        _internalId = setInterval(watch, 500);
    }

    public static function stopWatch(): Void {
        trace("[" + CLASS_NAME + "::stopWatch] clearing interval");
        clearInterval(_internalId);
        delete _internalId;
    }

    private static function watch(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::watch] ";
        if (!_global.fem_m_onlineMultiplayer) {
            return;
        }
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
        var rankedContainer: MovieClip = autoMatchSetup[RANKED_CONTAINER];
        if (typeof rankedContainer !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchSetup found, creating elements");
            createElements(autoMatchPanel, autoMatchSetup);
            rankedContainer = autoMatchSetup[RANKED_CONTAINER];
            if (rankedContainer !== "movieclip") {
                trace(TRACE_PREFIX + "failed to create elements");
                return;
            }
        }

        var inviteButton: MovieClip = autoMatchSetup.inviteButton;
        if (inviteButton.isEnabled()) {
            rankedContainer._visible = false;
            inviteButton._alpha = 100;
        }
        else {
            rankedContainer._visible = true;
            inviteButton._alpha = 0;

            var rankedCheckBox: MovieClip = rankedContainer[RANKED_CHECKBOX];
            if (rankedCheckBox.isEnabled() === false) {
                var result: Object = new Object();
                loadVariables("Ra3BattleNet_InGameHttpRequest", result);
                updateRankedCheckBox(rankedCheckBox, result["isCurrentPlayerRanked"]);
            }
        }
    }

    private static function createElements(autoMatchPanel: MovieClip, autoMatchSetup: MovieClip): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::createElements] ";
        var originalCheckBox: MovieClip = autoMatchSetup.broadcastCheckBox;
        if (typeof originalCheckBox !== "movieclip") {
            trace(TRACE_PREFIX + "original broadcast checkbox is not a movieclip");
            return;
        }
        var autoMatchLobby: MovieClip = autoMatchPanel.autoMatchLobby;
        if (typeof autoMatchLobby !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchLobby is not a movieclip");
            return;
        }
        var autoMatchLobbyCommander: MovieClip = autoMatchLobby.mcCommanderPlayer;
        if (typeof autoMatchLobbyCommander !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchLobbyCommander is not a movieclip");
            return;
        }
        var originalLabel: MovieClip = autoMatchLobbyCommander.tfBroadcast;
        if (typeof originalLabel !== "movieclip") {
            trace(TRACE_PREFIX + "original broadcast label is not a movieclip");
            return;
        }
        var originalDrop: TextField = originalLabel.drop;
        var originalTop: TextField = originalLabel.top;
        if (!originalDrop || !originalTop) {
            trace(TRACE_PREFIX + "original broadcast label does not have drop and top text fields");
            return;
        }

        var container: MovieClip = autoMatchSetup.createEmptyMovieClip(
            RANKED_CONTAINER, 
            autoMatchSetup.getNextHighestDepth()
        );

        var newCheckbox: MovieClip = container.attachMovie(
            "std_MouseCheckBoxSymbol",
            RANKED_CHECKBOX,
            container.getNextHighestDepth(), {
                m_width: 200,
                m_textAlign: false,
                m_labelPosition: "right align",
                m_label_x: 0,
                m_label_y: 0,
                m_focusDirs: "Up/Down",
                m_iconType: "default",
                m_extLabel: "",
                m_nTruncateType: 0,
                m_label: "",
                m_bEnabled: true,
                m_refFM: "_root.gFM",
                m_initiallySelected: false,
                m_tabIndex: 1,
                m_bVisible: true,
                m_contentSymbol: "checkBoxContentClipSymbol"
            }
        );
        newCheckbox._x = originalCheckBox._x;
        newCheckbox._y = originalCheckBox._y + originalCheckBox._height + RANKED_CHECKBOX_OFFSET_Y;
        newCheckbox.disable();
        newCheckbox.setOnMouseDownFunction(function () {
            var parameters: String = "?setCurrentPlayerRanked=" + (newCheckbox.isChecked() ? "1" : "0");
            var result: Object = new Object();
            loadVariables("Ra3BattleNet_InGameHttpRequest" + parameters, result);
            updateRankedCheckBox(newCheckbox, result["isCurrentPlayerRanked"]);
        });

        var label: MovieClip = container.createEmptyMovieClip(
            "rankedCheckBoxLabel", 
            container.getNextHighestDepth()
        );
        label._x = newCheckbox._x + RANKED_LABEL_OFFSET_X;
        label._y = newCheckbox._y + RANKED_LABEL_OFFSET_Y;
        label.createTextField("drop", 1, originalDrop._x, originalDrop._y, originalDrop._width, originalDrop._height);
        label.createTextField("top", 2, originalTop._x, originalTop._y, originalTop._width, originalTop._height);
        var drop: TextField = label.drop;
        var top: TextField = label.top;
        drop.textColor = originalDrop.textColor;
        top.textColor = originalTop.textColor;
        // 红警3没有 setNewTextFormat，只有 setTextFormat
        drop.setTextFormat(originalDrop.getNewTextFormat());
        top.setTextFormat(originalTop.getNewTextFormat());
        drop.text = top.text = "$IsPersonaRankedLabel";
        top.text += "&Outline"

        container.createTextField(
            "rankedCheckBoxDetails", 
            container.getNextHighestDepth(),
            label._x + RANKED_DETAILS_OFFSET_X,
            label._y + label._height + RANKED_DETAILS_OFFSET_Y,
            RANKED_DETAILS_WIDTH,
            RANKED_DETAILS_HEIGHT
        );
        var details: TextField = container["rankedCheckBoxDetails"];
        details.setTextFormat(new TextFormat("Lucida Sans Unicode", 14, top.textColor));
        details.wordWrap = true;
        details.text = "$IsPersonaRankedDetails";
    }

    private static function updateRankedCheckBox(checkBox: MovieClip, isRanked): Void {
        trace("[" + CLASS_NAME + "::updateRankedCheckBox] isRanked = " + isRanked);
        if (isRanked === "1") {
            checkBox.enable();
            checkBox.check();
        }
        else if (isRanked === "0") {
            checkBox.enable();
            checkBox.unCheck();
        }
        else {
            checkBox.disable();
        }
    }
}
